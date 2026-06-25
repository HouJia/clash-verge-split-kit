"""CLI：出站 IP 探测；可选本地静态审计页。"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

from outbound_ip.probes import load_default


def resolve_audit_script() -> str:
    env = os.environ.get("OUTBOUND_IP_AUDIT_SCRIPT", "").strip()
    if env:
        p = Path(env).expanduser()
        if p.is_file():
            return str(p.resolve())
        print(f"错误: OUTBOUND_IP_AUDIT_SCRIPT 指向的文件不存在: {p}", file=sys.stderr)
        sys.exit(2)

    candidates = [
        Path(__file__).resolve().parents[2] / "scripts" / "outbound-ip-audit.sh",
        Path.home() / ".cursor/skills/hjs-outbound-ip-audit/scripts/outbound-ip-audit.sh",
    ]
    for p in candidates:
        if p.is_file():
            return str(p.resolve())

    print(
        "错误: 未找到 outbound-ip-audit.sh。请设置 OUTBOUND_IP_AUDIT_SCRIPT，"
        "或安装技能 hjs-outbound-ip-audit（~/.cursor/skills/）。",
        file=sys.stderr,
    )
    sys.exit(2)


def run_serve(argv: list[str]) -> int:
    from outbound_ip.web.server import serve_main

    return serve_main(argv)


def run_audit(argv: list[str] | None = None) -> int:
    base = list(sys.argv[1:] if argv is None else argv)
    if base[:1] == ["serve"]:
        return run_serve(base[1:])

    parser = argparse.ArgumentParser(
        prog="outbound-ip",
        description="出站 IP 探测：默认一键摘要；可选 TSV 与完整矩阵。底层调用 outbound-ip-audit.sh。",
        epilog="可选静态预览：outbound-ip serve [--port 18765]（页面亦可直接打开静态文件）",
    )
    parser.add_argument("--full", action="store_true", help="完整技术矩阵")
    parser.add_argument("--simple-tsv", action="store_true", help="仅输出 TSV（含表头）")
    parser.add_argument("--ipv6-skip", action="store_true", help="仅 --full：跳过 IPv6 场景")
    parser.add_argument("--interface", metavar="IFACE", help="仅 --full：绑定网卡")
    args = parser.parse_args(base)

    if args.full and args.simple_tsv:
        print("错误: --full 与 --simple-tsv 不能同时使用", file=sys.stderr)
        return 2

    load_default()

    if args.full:
        cmd = ["/bin/bash", resolve_audit_script(), "--full"]
        if args.ipv6_skip:
            cmd.append("--ipv6-skip")
        if args.interface:
            cmd.extend(["--interface", args.interface])
    elif args.simple_tsv:
        cmd = ["/bin/bash", resolve_audit_script(), "--simple-tsv"]
    else:
        if args.ipv6_skip or args.interface:
            print(
                "提示: --ipv6-skip / --interface 仅在 --full 模式下生效；一键模式已忽略。",
                file=sys.stderr,
            )
        cmd = ["/bin/bash", resolve_audit_script()]

    env = os.environ.copy()
    proc = subprocess.run(cmd, env=env, cwd=str(Path(resolve_audit_script()).parent))
    return int(proc.returncode)


def main() -> None:
    raise SystemExit(run_audit())


if __name__ == "__main__":
    main()
