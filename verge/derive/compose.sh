#!/usr/bin/env bash
# 将 parts/ 合并为单份 Mihomo/Verge 扩展 YAML（ stdout 或 -o 路径）。
# 主线机场稿：真值源在 parts/；extend/airport-rule-split-extend.yaml 为合并产物。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARTS="${ROOT}/parts"
OUT_PATH=""

usage() {
  echo "用法: $0 [-o verge/extend/airport-rule-split-extend.yaml]" >&2
  echo "  默认打印到 stdout；-o 原子写入目标文件。" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  -o)
    [[ -n "${2:-}" ]] || usage
    OUT_PATH="$2"
    shift 2
    ;;
  -h|--help) usage ;;
  *) usage ;;
  esac
done

req=(
  "${PARTS}/airport-dochead.txt"
  "${PARTS}/10-runtime-verge-mihomo.yaml"
  "${PARTS}/20-routing-mihomo.yaml"
)
for f in "${req[@]}"; do
  [[ -f "$f" ]] || { echo "error: 缺少 ${f}" >&2; exit 2; }
done

emit() {
  cat "${req[@]}"
}

if [[ -n "${OUT_PATH}" ]]; then
  tmp="$(mktemp)"
  trap 'rm -f "${tmp}"' EXIT
  emit >"${tmp}"
  mv "${tmp}" "${OUT_PATH}"
  trap - EXIT
else
  emit
fi
