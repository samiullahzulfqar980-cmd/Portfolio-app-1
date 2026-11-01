#!/usr/bin/env python3
"""Static preview server for the portfolio app mock-up.

Serves /home/user/preview at "/" and the packaged archives in /home/user at
"/<name>.zip" with a Content-Disposition header, so the download page works
without copying 18 MB archives into the preview folder.

Usage:  python3 serve.py [port]        (default 8080, binds 0.0.0.0)
"""
import os
import sys
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PREVIEW_DIR = Path(__file__).resolve().parent
ROOT_DIR = PREVIEW_DIR.parent
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else int(os.environ.get('PORT', 8080))


class PreviewHandler(SimpleHTTPRequestHandler):
    """Routes "/" to the preview folder and top-level zips to the parent dir."""

    # Keep-alive, so an 18 MB archive download is not one connection per chunk.
    protocol_version = 'HTTP/1.1'

    def translate_path(self, path):
        clean = path.split('?', 1)[0].split('#', 1)[0]
        rel = clean.lstrip('/')
        # Archives live one level up; everything else in the preview folder.
        if rel.endswith('.zip') and (ROOT_DIR / rel).is_file():
            return str(ROOT_DIR / rel)
        return super().translate_path(path)

    def end_headers(self):
        if self.path.split('?', 1)[0].endswith('.zip'):
            name = os.path.basename(self.path.split('?', 1)[0])
            self.send_header('Content-Disposition', f'attachment; filename="{name}"')
        # The preview is shown inside an iframe under a proxied host. Omitting
        # X-Frame-Options (it has no "allow all" value) and declaring
        # frame-ancestors keeps embedding working without a broken header.
        self.send_header('Content-Security-Policy', "frame-ancestors *")
        self.send_header('Access-Control-Allow-Origin', '*')
        if self.path.endswith(('.html', '/')):
            self.send_header('Cache-Control', 'no-store')
        else:
            self.send_header('Cache-Control', 'public, max-age=300')
        super().end_headers()

    def log_message(self, fmt, *args):
        sys.stderr.write('%s - %s\n' % (self.address_string(), fmt % args))


def main():
    handler = partial(PreviewHandler, directory=str(PREVIEW_DIR))
    server = ThreadingHTTPServer(('0.0.0.0', PORT), handler)
    print(f'Preview server on http://0.0.0.0:{PORT}  (root: {PREVIEW_DIR})', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == '__main__':
    main()
