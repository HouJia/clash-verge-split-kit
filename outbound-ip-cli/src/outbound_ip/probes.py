"""Load packaged probe definitions (synced from web/static/audit-core.js)."""

from __future__ import annotations

import json
import sys
from importlib import resources
from typing import Any


def load_default() -> list[dict[str, Any]]:
    ref = resources.files("outbound_ip.data") / "probes.packaged.json"
    if not ref.is_file():
        print(
            "错误: 未找到内置 probes.packaged.json。若在开发环境，请在包根目录执行 node scripts/sync-probes.mjs。",
            file=sys.stderr,
        )
        sys.exit(2)
    raw = ref.read_text(encoding="utf-8")
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"错误: JSON 解析失败: {e}", file=sys.stderr)
        sys.exit(2)
    if not isinstance(data, dict) or "probes" not in data:
        print('错误: probes JSON 必须包含顶级键 "probes"', file=sys.stderr)
        sys.exit(2)
    probes = data["probes"]
    if not isinstance(probes, list) or not probes:
        print("错误: probes 列表为空", file=sys.stderr)
        sys.exit(2)
    for i, p in enumerate(probes):
        if not isinstance(p, dict):
            print(f"错误: probes[{i}] 必须为对象", file=sys.stderr)
            sys.exit(2)
        for k in ("category", "name", "url", "parser"):
            if k not in p:
                print(f"错误: probes[{i}] 缺少字段 {k}", file=sys.stderr)
                sys.exit(2)
    return probes
