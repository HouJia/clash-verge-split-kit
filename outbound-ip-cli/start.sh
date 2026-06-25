#!/bin/bash
# 快捷启动出站 IP 审计页（outbound-ip serve）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "${ROOT}"
if [ ! -f ".venv/bin/outbound-ip" ]; then
  echo "正在创建虚拟环境并安装 outbound-ip …" >&2
  python3 -m venv .venv
  .venv/bin/pip install -q -e .
fi
exec ./.venv/bin/outbound-ip serve "$@"
