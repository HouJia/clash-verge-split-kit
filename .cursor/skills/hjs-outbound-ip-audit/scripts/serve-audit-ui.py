#!/usr/bin/env python3
"""
本地只读 Web UI：/ 与 POST /api/run，调用 outbound-ip-audit.sh。
默认「一键」模式：--simple-tsv，按站点类型分组返回；可选完整矩阵 --full。
"""
from __future__ import annotations

import csv
import io
import json
import os
import subprocess
import sys
import urllib.parse
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
SKILL_DIR = SCRIPT_DIR.parent
WEB_DIR = SKILL_DIR / "web"
AUDIT_SH = SCRIPT_DIR / "outbound-ip-audit.sh"
DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 18765
MAX_RUN_SECONDS = 600

GROUP_ORDER = ("domestic", "intl_plain", "cdn_trace", "meta")
GROUP_LABELS = {
    "domestic": "国内 / 中文语境站点",
    "intl_plain": "国际通用回显",
    "cdn_trace": "CDN 侧观测",
    "meta": "HTTP 元数据 (JSON)",
}


def parse_rows(tsv: str) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    reader = csv.reader(io.StringIO(tsv), delimiter="\t")
    for i, parts in enumerate(reader):
        if not parts:
            continue
        if i == 0 and parts[0] == "scenario":
            continue
        while len(parts) < 6:
            parts.append("")
        rows.append(
            {
                "scenario": parts[0],
                "category": parts[1],
                "probe_name": parts[2],
                "url": parts[3],
                "http_code": parts[4],
                "snippet": parts[5],
            }
        )
    return rows


def build_groups(rows: list[dict[str, str]]) -> list[dict[str, object]]:
    buckets: dict[str, list[dict[str, str]]] = {k: [] for k in GROUP_ORDER}
    for r in rows:
        cat = r.get("category") or ""
        if cat in buckets:
            buckets[cat].append(r)
    out: list[dict[str, object]] = []
    for key in GROUP_ORDER:
        if buckets[key]:
            out.append({"key": key, "title": GROUP_LABELS[key], "rows": buckets[key]})
    return out


class Handler(BaseHTTPRequestHandler):
    server_version = "outbound-ip-audit-ui/1.1"

    def log_message(self, fmt: str, *args: object) -> None:
        sys.stderr.write("%s - - [%s] %s\n" % (self.address_string(), self.log_date_time_string(), fmt % args))

    def _send(self, code: int, body: bytes, content_type: str) -> None:
        self.send_response(code)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path in ("/", "/index.html"):
            path = WEB_DIR / "index.html"
            if not path.is_file():
                self._send(500, b"web/index.html missing", "text/plain; charset=utf-8")
                return
            self._send(200, path.read_bytes(), "text/html; charset=utf-8")
            return
        if parsed.path == "/health":
            self._send(200, b"ok", "text/plain; charset=utf-8")
            return
        self._send(404, b"not found", "text/plain; charset=utf-8")

    def do_POST(self) -> None:
        if self.path != "/api/run":
            self._send(404, b"not found", "text/plain; charset=utf-8")
            return
        length = int(self.headers.get("Content-Length", "0") or 0)
        raw = self.rfile.read(length) if length else b"{}"
        try:
            payload = json.loads(raw.decode("utf-8") or "{}")
        except json.JSONDecodeError:
            payload = {}

        mode = str(payload.get("mode") or "simple").lower()
        if mode not in ("simple", "full"):
            mode = "simple"

        ipv6_skip = bool(payload.get("ipv6_skip", True))
        iface = str(payload.get("iface") or "").strip()
        if iface and not all(c.isalnum() or c in "._-" for c in iface):
            out = json.dumps({"ok": False, "error": "非法的 interface 名称"}).encode("utf-8")
            self._send(400, out, "application/json; charset=utf-8")
            return

        if not AUDIT_SH.is_file():
            out = json.dumps({"ok": False, "error": "未找到 outbound-ip-audit.sh"}).encode("utf-8")
            self._send(500, out, "application/json; charset=utf-8")
            return

        cmd: list[str] = ["/bin/bash", str(AUDIT_SH)]
        if mode == "simple":
            cmd.append("--simple-tsv")
        else:
            cmd.append("--full")
            if ipv6_skip:
                cmd.append("--ipv6-skip")
            if iface:
                cmd.extend(["--interface", iface])

        env = os.environ.copy()
        try:
            proc = subprocess.run(
                cmd,
                cwd=str(SCRIPT_DIR),
                env=env,
                capture_output=True,
                text=True,
                timeout=MAX_RUN_SECONDS,
            )
        except subprocess.TimeoutExpired:
            out = json.dumps({"ok": False, "error": "脚本执行超时"}).encode("utf-8")
            self._send(504, out, "application/json; charset=utf-8")
            return
        except Exception as e:
            out = json.dumps({"ok": False, "error": str(e)}).encode("utf-8")
            self._send(500, out, "application/json; charset=utf-8")
            return

        tsv = proc.stdout or ""
        stderr = proc.stderr or ""
        if proc.returncode != 0:
            out = json.dumps(
                {
                    "ok": False,
                    "error": "脚本退出码 %s" % proc.returncode,
                    "stderr": stderr[-8000:],
                    "tsv": tsv[-120000:],
                }
            ).encode("utf-8")
            self._send(200, out, "application/json; charset=utf-8")
            return

        rows = parse_rows(tsv)
        groups = build_groups(rows) if mode == "simple" else []
        out = json.dumps(
            {
                "ok": True,
                "mode": mode,
                "tsv": tsv,
                "rows": rows,
                "groups": groups,
                "stderr": stderr[-4000:] if stderr else "",
            },
            ensure_ascii=False,
        ).encode("utf-8")
        self._send(200, out, "application/json; charset=utf-8")


def main() -> int:
    host = os.environ.get("HJS_AUDIT_UI_HOST", DEFAULT_HOST)
    port = int(os.environ.get("HJS_AUDIT_UI_PORT", str(DEFAULT_PORT)))
    no_open = "--no-open" in sys.argv

    if not WEB_DIR.is_dir():
        print("缺少目录: %s" % WEB_DIR, file=sys.stderr)
        return 1

    httpd = HTTPServer((host, port), Handler)
    url = "http://%s:%s/" % (host, port)
    print("审计 UI：%s" % url)
    print("按 Ctrl+C 结束。环境变量：HJS_AUDIT_UI_HOST、HJS_AUDIT_UI_PORT")

    if not no_open:
        try:
            import webbrowser

            webbrowser.open(url)
        except Exception:
            pass

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n已停止。")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
