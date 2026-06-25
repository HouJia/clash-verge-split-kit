"""Serve static audit UI (index.html + audit-core.js)；同源 /__probe 代取（仅允许内置探测 URL），补足无 CORS 响应头的站点。"""

from __future__ import annotations

import argparse
import ipaddress
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
import webbrowser
from functools import cache
from http.server import BaseHTTPRequestHandler, HTTPServer
from importlib import resources


@cache
def _allowed_probe_urls() -> frozenset[str]:
    ref = resources.files("outbound_ip.data") / "probes.packaged.json"
    data = json.loads(ref.read_text(encoding="utf-8"))
    out = {str(p["url"]) for p in data["probes"] if isinstance(p, dict) and "url" in p}
    return frozenset(out)


def _geo_tail_for_ip(ip: str) -> str:
    """返回「来自于：…」后缀；仅用 ip-api 的 zh-CN（不用英文数据源）。"""
    ip = ip.strip()
    try:
        ipaddress.ip_address(ip)
    except ValueError:
        return ""
    ua = "outbound-ip-audit-ui/0.2 (+https://github.com/HouJia/clash-verge-split-kit)"

    def _join_zh(parts: list[str]) -> str:
        parts = [p.strip() for p in parts if p and str(p).strip()]
        return "来自于：" + " ".join(parts) if parts else ""

    try:
        api_u = (
            "http://ip-api.com/json/"
            + urllib.parse.quote(ip, safe="")
            + "?fields=status,message,country,regionName,city&lang=zh-CN"
        )
        req = urllib.request.Request(
            api_u,
            method="GET",
            headers={"User-Agent": ua, "Accept": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=14) as resp:
            data = json.loads(resp.read().decode("utf-8", "replace"))
        if data.get("status") == "success":
            tail = _join_zh(
                [str(data.get("country") or ""), str(data.get("regionName") or ""), str(data.get("city") or "")]
            )
            if tail:
                return tail
    except Exception:
        pass

    return ""


class Handler(BaseHTTPRequestHandler):
    server_version = "outbound-ip/0.2"

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
        path = parsed.path.rstrip("/") or "/"

        if path == "/health":
            self._send(200, b"ok", "text/plain; charset=utf-8")
            return

        static = resources.files("outbound_ip.web") / "static"
        if path in ("/", "/index.html"):
            ref = static / "index.html"
            if not ref.is_file():
                self._send(500, b"static/index.html missing", "text/plain; charset=utf-8")
                return
            self._send(200, ref.read_bytes(), "text/html; charset=utf-8")
            return

        if path == "/audit-core.js":
            ref = static / "audit-core.js"
            if not ref.is_file():
                self._send(500, b"static/audit-core.js missing", "text/plain; charset=utf-8")
                return
            self._send(
                200,
                ref.read_bytes(),
                "text/javascript; charset=utf-8",
            )
            return

        if path == "/__probe":
            qs = urllib.parse.parse_qs(parsed.query or "")
            urls = qs.get("url", [])
            if not urls or not isinstance(urls[0], str):
                self._send(400, b"missing url", "text/plain; charset=utf-8")
                return
            raw = urls[0].strip()
            if raw not in _allowed_probe_urls():
                self._send(403, b"url not in probe allowlist", "text/plain; charset=utf-8")
                return
            parts = urllib.parse.urlparse(raw)
            if parts.scheme != "https" or not parts.netloc:
                self._send(400, b"invalid url", "text/plain; charset=utf-8")
                return
            req = urllib.request.Request(
                raw,
                method="GET",
                headers={
                    "User-Agent": "outbound-ip-audit-ui/0.2 (+https://github.com/HouJia/clash-verge-split-kit)",
                    "Accept": "text/plain,text/html,application/json;q=0.9,*/*;q=0.1",
                    # 与浏览器默认语言对齐，避免 cip.cc 等对脚本/代取返回英文简版而地址栏为中文。
                    "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.7",
                },
            )
            timeout = 22
            try:
                with urllib.request.urlopen(req, timeout=timeout) as resp:
                    body = resp.read()
                    ct = resp.headers.get("Content-Type") or "text/plain; charset=utf-8"
                    self.send_response(resp.status)
                    self.send_header("Content-Type", ct)
                    self.send_header("Content-Length", str(len(body)))
                    self.send_header("Cache-Control", "no-store")
                    self.send_header("Access-Control-Allow-Origin", "*")
                    self.end_headers()
                    self.wfile.write(body)
            except urllib.error.HTTPError as e:
                try:
                    body = e.read()
                except Exception:
                    body = ("%s" % e).encode("utf-8", "replace")
                ctype = e.headers.get("Content-Type") if e.headers else "text/plain; charset=utf-8"
                self._send(e.code, body, ctype)
            except Exception:
                self._send(502, b"upstream fetch failed", "text/plain; charset=utf-8")
            return

        if path == "/__geo":
            qs_g = urllib.parse.parse_qs(parsed.query or "")
            ips_g = qs_g.get("ip", [])
            if not ips_g or not isinstance(ips_g[0], str):
                bod = json.dumps({"ok": False, "tail": "", "error": "missing ip"}, ensure_ascii=False).encode("utf-8")
                self.send_response(400)
                self.send_header("Content-Type", "application/json; charset=utf-8")
                self.send_header("Content-Length", str(len(bod)))
                self.send_header("Cache-Control", "no-store")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(bod)
                return
            try:
                ipaddress.ip_address(ips_g[0].strip())
            except ValueError:
                bod = json.dumps({"ok": False, "tail": "", "error": "invalid ip"}, ensure_ascii=False).encode("utf-8")
                self.send_response(400)
                self.send_header("Content-Type", "application/json; charset=utf-8")
                self.send_header("Content-Length", str(len(bod)))
                self.send_header("Cache-Control", "no-store")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(bod)
                return
            tail = _geo_tail_for_ip(ips_g[0])
            bod = json.dumps({"ok": bool(tail), "tail": tail}, ensure_ascii=False).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(bod)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(bod)
            return

        self._send(404, b"not found", "text/plain; charset=utf-8")


def serve_main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(prog="outbound-ip serve")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=18765)
    parser.add_argument("--no-open", action="store_true")
    args = parser.parse_args(argv)

    host = os.environ.get("HJS_AUDIT_UI_HOST", args.host)
    port = int(os.environ.get("HJS_AUDIT_UI_PORT", str(args.port)))

    httpd = HTTPServer((host, port), Handler)
    url = "http://%s:%s/" % (host, port)
    print("静态审计页：%s" % url)
    print(
        "可直接以 file:// 打开包内 index.html；或通过本命令以 http 同源打开。"
        "同源下提供 /__probe 代取（仅内置探测 URL）、/__geo IP 归属代查。"
    )
    print("按 Ctrl+C 结束。环境变量：HJS_AUDIT_UI_HOST、HJS_AUDIT_UI_PORT")

    if not args.no_open:
        try:
            webbrowser.open(url)
        except Exception:
            pass

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n已停止。")
    return 0
