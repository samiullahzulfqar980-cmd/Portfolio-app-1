# Design preview (browser mock-up)

**This folder is not the app.** It is a single-page HTML mock-up of the Flutter
screens, kept so the design can be reviewed in a browser without a Flutter
toolchain. The shipped product is the compiled Flutter app in the repository
root (`lib/`, `android/`, `ios/`, `web/`).

Everything rendered here is generated from `supabase/seed.sql` — the same rows
the real app reads from Supabase — so the mock-up cannot drift into fictional
content. There is no backend behind it: the inquiry form validates locally and
sends nothing.

## Run it

```bash
python3 preview/serve.py          # http://localhost:8080
python3 preview/serve.py 3000     # any port
```

The server binds `0.0.0.0` so it also works behind a container/proxy preview.
It serves this folder at `/`, and the packaged archives from the repository
root at `/<archive>.zip` with `Content-Disposition: attachment` (so the download
page works without duplicating 18 MB of zips into this folder).

## What is here

| File | Purpose |
| --- | --- |
| `index.html` | The phone mock-up: Home, Projects, About, Contact, Résumé, project case-study sheet |
| `downloads.html` | Download page for the packaged archives |
| `serve.py` | Static server with download headers and `frame-ancestors` for embedding |
| `assets/` | Web-sized copies (JPEG, ~300 KB total) of the bundled artwork |

## Regenerating

`index.html` was produced by a generator that parses `supabase/seed.sql` and
emits the screens, so content changes should be made in the SQL seed (or in the
app's admin area) and then mirrored here. Keep the "Design preview" banner and
the "not the app" wording in place.
