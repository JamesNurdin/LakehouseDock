#!/usr/bin/env python3
from __future__ import annotations

import os
import subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse

from datetime import datetime

PORT = int(os.environ.get("PROFILE_PORT", "8123"))
PROFILE_SCRIPT = os.environ.get("PROFILE_SCRIPT", "/mnt/primary/Main/profile_cluster/test_profile.py")
MY_POD_NAME = os.environ.get("MY_POD_NAME", "local-pod")
MY_NODE_NAME = os.environ.get("MY_NODE_NAME", "local-node")


def run_profile(phase: str, query_id: str, out_dir: str | None = None) -> int:
    cmd = ["python3", "-u", PROFILE_SCRIPT]

    env = os.environ.copy()
    env["PROFILE_PHASE"] = phase
    env["PROFILE_QUERY_ID"] = query_id
    env["MY_POD_NAME"] = MY_POD_NAME
    env["MY_NODE_NAME"] = MY_NODE_NAME
    env["PROFILE_LAUNCHED_AT"] = datetime.utcnow().isoformat()
    env["PROFILE_OUT_DIR"] = out_dir

    result = subprocess.run(cmd, env=env)
    return result.returncode


class Handler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        if self.path == "/health":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok\n")
            return

        self.send_response(404)
        self.end_headers()
        self.wfile.write(b"not found\n")

    def do_POST(self) -> None:
        parsed = urlparse(self.path)

        if parsed.path != "/profile":
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"not found\n")
            return

        qs = parse_qs(parsed.query)
        print(qs)
        phase = qs.get("phase", ["unspecified"])[0]
        query_id = qs.get("query_id", ["unknown"])[0]
        out_dir = qs.get("out_dir", [None])[0]

        print(
            f"[SERVER] received request: phase={phase}, query_id={query_id}, out_dir={out_dir}",
            flush=True,
        )

        rc = run_profile(phase, query_id, out_dir)

        if rc == 0:
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"profiling complete\n")
        else:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(b"profiling failed\n")

    def log_message(self, format: str, *args) -> None:
        return


if __name__ == "__main__":
    print(f"[SERVER] Listening on 0.0.0.0:{PORT}", flush=True)
    print(f"[SERVER] PROFILE_SCRIPT={PROFILE_SCRIPT}", flush=True)
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()