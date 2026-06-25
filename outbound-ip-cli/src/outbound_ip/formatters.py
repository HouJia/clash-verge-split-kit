"""Parse TSV audit output and build presentation groups (no curl)."""

from __future__ import annotations

import csv
import io
import json
import re
from typing import Any

GROUP_ORDER = ("domestic", "intl_plain", "cdn_trace", "meta")
GROUP_LABELS = {
    "domestic": "国内 / 中文语境站点",
    "intl_plain": "国际通用回显",
    "cdn_trace": "CDN 侧观测",
    "meta": "HTTP 元数据 (JSON)",
}


def parse_tsv_rows(tsv: str) -> list[dict[str, str]]:
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


def build_groups(rows: list[dict[str, str]]) -> list[dict[str, Any]]:
    buckets: dict[str, list[dict[str, str]]] = {k: [] for k in GROUP_ORDER}
    for r in rows:
        cat = r.get("category") or ""
        if cat in buckets:
            buckets[cat].append(r)
    out: list[dict[str, Any]] = []
    for key in GROUP_ORDER:
        if buckets[key]:
            out.append({"key": key, "title": GROUP_LABELS[key], "rows": buckets[key]})
    return out


def extract_httpbin_origin(body: str) -> str:
    body = body.strip()
    if not body:
        return ""
    try:
        d = json.loads(body)
        return str(d.get("origin", ""))[:160]
    except (json.JSONDecodeError, TypeError, ValueError):
        return ""


def extract_cip_cc_ip(html: str) -> str:
    m = re.search(r"IP\s*:\s*([0-9][0-9.]*)", html, flags=re.IGNORECASE)
    if m:
        return m.group(1).strip()
    line = re.sub(r"[\r\n]+", " ", html).strip()
    return line[:160] if line else ""
