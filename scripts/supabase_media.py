#!/usr/bin/env python3
"""Move the app's media into Supabase Storage so the database is the only source.

The seed ships rows whose image/résumé paths start with ``assets/`` — those
resolve to artwork compiled into the app. Running this script uploads the same
files to the three public buckets and rewrites the rows to object paths, after
which the app renders every image and the CV from Supabase over HTTPS and
nothing comes from the bundle.

Usage
-----
    export SUPABASE_URL=https://<project-ref>.supabase.co
    export SUPABASE_ANON_KEY=<anon key>          # public key, protected by RLS
    export SUPABASE_ADMIN_EMAIL=you@example.com  # must be in public.admin_users
    export SUPABASE_ADMIN_PASSWORD=<password>

    python3 scripts/supabase_media.py plan            # what would change
    python3 scripts/supabase_media.py upload          # upload + rewrite rows
    python3 scripts/supabase_media.py upload --dry-run
    python3 scripts/supabase_media.py upload --resume ~/cv.pdf
    python3 scripts/supabase_media.py verify          # check every path resolves

Only the standard library is used, so no virtualenv or npm install is needed.
The script never writes to a table it cannot see: RLS still applies, because it
signs in as your admin user and uses the anon key like the app does.
"""

from __future__ import annotations

import argparse
import json
import mimetypes
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

BUCKETS = {
    "profile-images": "avatar",
    "project-images": "projects",
    "resume-files": "resume",
}

# Extensions the storage policies accept, per bucket.
ALLOWED = {
    "profile-images": {".jpg", ".jpeg", ".png", ".webp"},
    "project-images": {".jpg", ".jpeg", ".png", ".webp"},
    "resume-files": {".pdf"},
}

MAX_BYTES = {
    "profile-images": 5 * 1024 * 1024,
    "project-images": 5 * 1024 * 1024,
    "resume-files": 10 * 1024 * 1024,
}


class ConfigError(RuntimeError):
    pass


class ApiError(RuntimeError):
    def __init__(self, message: str, status: int | None = None, body: str = ""):
        super().__init__(message)
        self.status = status
        self.body = body


# --------------------------------------------------------------------------- api


class Supabase:
    def __init__(self, url: str, anon_key: str) -> None:
        self.url = url.rstrip("/")
        self.anon_key = anon_key
        self.token: str | None = None

    # -- plumbing -----------------------------------------------------------
    def _request(
        self,
        method: str,
        path: str,
        *,
        body: bytes | None = None,
        headers: dict[str, str] | None = None,
        auth: bool = True,
        absolute: bool = False,
    ) -> tuple[int, bytes]:
        url = path if absolute else f"{self.url}{path}"
        send = {
            "apikey": self.anon_key,
            "Accept": "application/json",
        }
        if auth and self.token:
            send["Authorization"] = f"Bearer {self.token}"
        elif auth:
            send["Authorization"] = f"Bearer {self.anon_key}"
        if headers:
            send.update(headers)
        req = urllib.request.Request(url, data=body, headers=send, method=method)
        try:
            with urllib.request.urlopen(req, timeout=60) as response:
                return response.status, response.read()
        except urllib.error.HTTPError as error:
            payload = error.read().decode("utf-8", "replace")
            raise ApiError(
                f"{method} {path} failed with {error.code}",
                status=error.code,
                body=payload,
            ) from None
        except urllib.error.URLError as error:
            raise ApiError(f"{method} {path} failed: {error.reason}") from None

    @staticmethod
    def _json(raw: bytes):
        if not raw:
            return None
        try:
            return json.loads(raw.decode("utf-8"))
        except json.JSONDecodeError:
            return None

    # -- auth ---------------------------------------------------------------
    def sign_in(self, email: str, password: str) -> str:
        body = json.dumps({"email": email, "password": password}).encode()
        status, raw = self._request(
            "POST",
            "/auth/v1/token?grant_type=password",
            body=body,
            headers={"Content-Type": "application/json"},
            auth=False,
        )
        data = self._json(raw) or {}
        token = data.get("access_token")
        if status >= 300 or not token:
            raise ApiError(
                "Sign-in failed. Check SUPABASE_ADMIN_EMAIL / SUPABASE_ADMIN_PASSWORD "
                "and that the account's email is confirmed.",
                status=status,
                body=raw.decode("utf-8", "replace"),
            )
        self.token = token
        return data.get("user", {}).get("id", "")

    # -- data ---------------------------------------------------------------
    def select(self, table: str, columns: str, order: str | None = None) -> list[dict]:
        query = f"/rest/v1/{table}?select={columns}"
        if order:
            query += f"&order={order}"
        _, raw = self._request("GET", query)
        rows = self._json(raw)
        return rows if isinstance(rows, list) else []

    def patch(self, table: str, row_id: str, values: dict) -> None:
        body = json.dumps(values).encode()
        self._request(
            "PATCH",
            f"/rest/v1/{table}?id=eq.{urllib.parse.quote(row_id)}",
            body=body,
            headers={
                "Content-Type": "application/json",
                "Prefer": "return=minimal",
            },
        )

    # -- storage ------------------------------------------------------------
    def upload(self, bucket: str, object_path: str, payload: bytes, content_type: str) -> None:
        safe = urllib.parse.quote(object_path)
        self._request(
            "POST",
            f"/storage/v1/object/{bucket}/{safe}",
            body=payload,
            headers={
                "Content-Type": content_type,
                "x-upsert": "true",
                "Cache-Control": "max-age=3600",
            },
        )

    def public_url(self, bucket: str, object_path: str) -> str:
        return (
            f"{self.url}/storage/v1/object/public/{bucket}/"
            f"{urllib.parse.quote(object_path)}"
        )

    def head(self, url: str) -> int:
        request = urllib.request.Request(url, method="HEAD")
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                return response.status
        except urllib.error.HTTPError as error:
            return error.code
        except urllib.error.URLError:
            return 0


# ----------------------------------------------------------------------- helpers


def describe(path: str | None) -> str:
    if not path:
        return "—"
    if path.startswith("assets/"):
        return "bundled"
    if path.startswith(("http://", "https://")):
        return "absolute URL"
    return "storage"


def bucket_for(kind: str) -> str:
    return {
        "avatar": "profile-images",
        "project": "project-images",
        "resume": "resume-files",
    }[kind]


def object_path_for(kind: str, asset_path: str) -> str:
    """`assets/images/projects/x.png` -> `projects/x.png` (keeps the file name)."""
    name = Path(asset_path).name
    return f"{BUCKETS[bucket_for(kind)]}/{name}"


def local_file_for(asset_path: str) -> Path:
    return (REPO_ROOT / asset_path).resolve()


def content_type_for(path: Path) -> str:
    guessed, _ = mimetypes.guess_type(path.name)
    return guessed or "application/octet-stream"


def check_uploadable(path: Path, bucket: str) -> str | None:
    """Returns an error string when the file would be rejected by the policy."""
    if not path.is_file():
        return f"missing file: {path}"
    suffix = path.suffix.lower()
    if suffix not in ALLOWED[bucket]:
        allowed = ", ".join(sorted(ALLOWED[bucket]))
        return f"{path.name}: {suffix or 'no extension'} not allowed in {bucket} ({allowed})"
    size = path.stat().st_size
    if size > MAX_BYTES[bucket]:
        limit = MAX_BYTES[bucket] // (1024 * 1024)
        return f"{path.name}: {size / 1_048_576:.1f} MB exceeds the {limit} MB limit"
    return None


# ------------------------------------------------------------------------- flows


def collect(sb: Supabase) -> dict:
    profiles = sb.select("profiles", "id,full_name,avatar_path,resume_path")
    projects = sb.select("projects", "id,slug,title,image_path", order="sort_order")
    return {"profiles": profiles, "projects": projects}


def report(state: dict) -> None:
    print("\nCurrent media references\n")
    print(f"{'row':<44}{'field':<13}{'value':<44}state")
    print("-" * 108)
    rows = 0
    bundled = 0
    for profile in state["profiles"]:
        for field in ("avatar_path", "resume_path"):
            value = profile.get(field)
            if not value:
                continue
            rows += 1
            state_label = describe(value)
            if state_label == "bundled":
                bundled += 1
            label = f"profile · {(profile.get('full_name') or profile['id'])[:34]}"
            print(f"{label:<44}{field:<13}{value[:42]:<44}{state_label}")
    for project in state["projects"]:
        value = project.get("image_path")
        if not value:
            continue
        rows += 1
        state_label = describe(value)
        if state_label == "bundled":
            bundled += 1
        label = f"project · {(project.get('title') or project['slug'])[:34]}"
        print(f"{label:<44}{'image_path':<13}{value[:42]:<44}{state_label}")
    print("-" * 108)
    print(f"{rows} media references · {bundled} still point at bundled assets")


def plan(state: dict, resume: Path | None) -> list[dict]:
    """Builds the list of uploads + row updates that are still needed."""
    jobs: list[dict] = []
    for profile in state["profiles"]:
        for field, kind in (("avatar_path", "avatar"), ("resume_path", "resume")):
            value = profile.get(field)
            if not value or not value.startswith("assets/"):
                continue
            jobs.append(
                {
                    "table": "profiles",
                    "id": profile["id"],
                    "field": field,
                    "kind": kind,
                    "asset": value,
                }
            )
    for project in state["projects"]:
        value = project.get("image_path")
        if not value or not value.startswith("assets/"):
            continue
        jobs.append(
            {
                "table": "projects",
                "id": project["id"],
                "field": "image_path",
                "kind": "project",
                "asset": value,
            }
        )
    if resume is not None:
        jobs.append(
            {
                "table": "profiles",
                "id": state["profiles"][0]["id"] if state["profiles"] else "",
                "field": "resume_path",
                "kind": "resume",
                "asset": None,
                "local": resume,
            }
        )
    return jobs


def run_upload(sb: Supabase, state: dict, jobs: list[dict], *, dry_run: bool, resume: Path | None) -> int:
    if not jobs:
        print("\nNothing to do: every media reference already points at Storage.")
        return 0

    print(f"\n{'Would upload' if dry_run else 'Uploading'} {len(jobs)} file(s)\n")
    failures = 0
    for job in jobs:
        kind = job["kind"]
        bucket = bucket_for(kind)

        if job.get("local") is not None:  # --resume override
            local = Path(job["local"]).resolve()
            target = f"{BUCKETS['resume-files']}/{local.name}"
        else:
            local = local_file_for(job["asset"])
            target = object_path_for(kind, job["asset"])

        problem = check_uploadable(local, bucket)
        label = local.name
        if problem:
            print(f"  ✗ {label}: {problem}")
            failures += 1
            continue

        if dry_run:
            print(f"  → {local.relative_to(REPO_ROOT) if REPO_ROOT in local.parents else local}")
            print(f"    {bucket}/{target}")
            print(f"    update {job['table']}.{job['field']} = '{target}'")
            continue

        try:
            payload = local.read_bytes()
            sb.upload(bucket, target, payload, content_type_for(local))
            sb.patch(job["table"], job["id"], {job["field"]: target})
        except ApiError as error:
            detail = (error.body or "").strip().replace("\n", " ")[:160]
            print(f"  ✗ {label}: {error.status or 'error'} {detail}")
            failures += 1
            continue
        print(f"  ✓ {label} → {bucket}/{target}")

    if dry_run:
        print("\nDry run: nothing was written. Re-run without --dry-run to apply.")
    else:
        print(f"\nDone: {len(jobs) - failures} uploaded, {failures} failed.")
        if failures == 0:
            print("Run `verify` to confirm every public URL resolves.")
    return 1 if failures else 0


def run_verify(sb: Supabase, state: dict) -> int:
    print("\nVerifying media\n")
    problems = 0
    bundled = 0
    external = 0
    checked = 0

    def check(bucket: str, value: str, label: str) -> None:
        nonlocal problems, bundled, external, checked
        if not value:
            return
        if value.startswith("assets/"):
            bundled += 1
            print(f"  ~ {label}: still bundled ({value})")
            return
        absolute = value.startswith(("http://", "https://"))
        url = value if absolute else sb.public_url(bucket, value)
        checked += 1
        status = sb.head(url)
        if status != 200:
            problems += 1
            print(f"  ✗ {label}: HTTP {status or 'unreachable'} {url}")
        elif absolute:
            # Reachable, but not served by this project's Storage.
            external += 1
            print(f"  ~ {label}: external URL, not Supabase Storage — {url}")
        else:
            print(f"  ✓ {label}: 200 {url}")

    for profile in state["profiles"]:
        if profile.get("avatar_path"):
            check("profile-images", profile["avatar_path"], "avatar")
        if profile.get("resume_path"):
            check("resume-files", profile["resume_path"], "resume")
    for project in state["projects"]:
        if project.get("image_path"):
            check(
                "project-images",
                project["image_path"],
                f"cover · {(project.get('slug') or project['id'])[:30]}",
            )

    print()
    if problems:
        print(f"{problems} object(s) did not resolve. Re-run `upload` or check the policies.")
        return 1
    if bundled or external:
        parts = []
        if bundled:
            parts.append(f"{bundled} still use bundled assets")
        if external:
            parts.append(f"{external} point at external URLs")
        print(
            f"{checked} object(s) resolved, but {' and '.join(parts)}. "
            "Run `upload` (and edit those rows) so everything is served from Supabase Storage."
        )
        return 0
    print(f"All {checked} media object(s) are served from Supabase Storage.")
    return 0


# -------------------------------------------------------------------------- main


def load_config(args) -> tuple[str, str, str | None, str | None]:
    url = args.url or os.environ.get("SUPABASE_URL", "")
    anon = args.anon_key or os.environ.get("SUPABASE_ANON_KEY", "")
    email = os.environ.get("SUPABASE_ADMIN_EMAIL", "")
    password = os.environ.get("SUPABASE_ADMIN_PASSWORD", "")
    if not url or not anon:
        raise ConfigError(
            "Set SUPABASE_URL and SUPABASE_ANON_KEY (the public key — never the "
            "service_role key)."
        )
    if "YOUR-" in url or "YOUR_" in anon:
        raise ConfigError("SUPABASE_URL / SUPABASE_ANON_KEY still contain placeholders.")
    for command in ("upload", "verify"):
        if args.command == command and (not email or not password):
            raise ConfigError(
                "Set SUPABASE_ADMIN_EMAIL and SUPABASE_ADMIN_PASSWORD so the script "
                "can sign in as your admin user."
            )
    return url, anon, email or None, password or None


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Upload the app's media to Supabase Storage and point the rows at it."
    )
    parser.add_argument(
        "command",
        choices=("plan", "upload", "verify"),
        help="plan = report only, upload = move media + rewrite rows, verify = check URLs",
    )
    parser.add_argument("--dry-run", action="store_true", help="show uploads without writing")
    parser.add_argument("--resume", type=Path, help="PDF to upload as the résumé")
    parser.add_argument("--url", help="override SUPABASE_URL")
    parser.add_argument("--anon-key", help="override SUPABASE_ANON_KEY")
    args = parser.parse_args(argv)

    try:
        url, anon, email, password = load_config(args)
    except ConfigError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2

    sb = Supabase(url, anon)
    if email and password:
        try:
            sb.sign_in(email, password)
        except ApiError as error:
            print(f"error: {error}", file=sys.stderr)
            if error.body:
                print(error.body[:400], file=sys.stderr)
            return 2

    try:
        state = collect(sb)
    except ApiError as error:
        print(f"error: could not read tables — {error}", file=sys.stderr)
        if error.body:
            print(error.body[:400], file=sys.stderr)
        return 2

    if not state["profiles"]:
        print(
            "error: no profile row. Run supabase/seed.sql first.",
            file=sys.stderr,
        )
        return 2

    report(state)

    if args.command == "plan":
        jobs = plan(state, args.resume)
        if not jobs:
            print("\nNothing to move: every reference already points at Storage.")
            return 0
        print(f"\n{len(jobs)} file(s) would be uploaded by `upload`:")
        for job in jobs:
            asset = job.get("asset") or str(job.get("local"))
            print(f"  · {asset} → {bucket_for(job['kind'])}/{BUCKETS[bucket_for(job['kind'])]}/…")
        return 0

    if args.command == "upload":
        jobs = plan(state, args.resume)
        return run_upload(sb, state, jobs, dry_run=args.dry_run, resume=args.resume)

    return run_verify(sb, state)


if __name__ == "__main__":
    raise SystemExit(main())
