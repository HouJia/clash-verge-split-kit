#!/usr/bin/env bash
# Privacy Guard：扫描提交说明与已跟踪文件中的常见密钥/令牌样式。
# 用法：
#   privacy-guard.sh message <文件路径>   # 文件内容为 commit message
#   privacy-guard.sh files                  # 扫描 git ls-files 内文本

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${ROOT}" ]]; then
  echo "error: privacy-guard.sh 必须在 Git 仓库内运行" >&2
  exit 2
fi
cd "$ROOT"

# 与 ERE / git grep -E 兼容的常见泄漏样式（收窄或加 path 排除以降低误报）
PATTERNS=(
  '-----BEGIN[A-Za-z0-9[:space:]]*PRIVATE[[:space:]]+KEY-----'
  'ghp_[A-Za-z0-9]{36}'
  'github_pat_[A-Za-z0-9_]{20,}'
  '[xX]ox[baprs]-[A-Za-z0-9-]{10,}'
  'AKIA[0-9A-Z]{16}'
  'sk_live_[0-9a-zA-Z]{20,}'
  'sk-ant-api[0-9]{2}-[A-Za-z0-9_-]{10,}'
  'sk-proj-[A-Za-z0-9_-]{20,}'
  'AIza[0-9A-Za-z_-]{30,}'
)

scan_message() {
  local f="${1:-}"
  if [[ -z "$f" || ! -f "$f" ]]; then
    echo "error: message 模式需要已有文件路径参数" >&2
    return 2
  fi
  local hit=0
  for re in "${PATTERNS[@]}"; do
    if grep -E -n -e "$re" "$f" >&2; then
      hit=1
    fi
  done
  if [[ "$hit" -ne 0 ]]; then
    echo "error: 提交说明中疑似包含密钥或令牌" >&2
    return 1
  fi
  return 0
}

scan_files() {
  local hit=0
  for re in "${PATTERNS[@]}"; do
    if git grep -n -E -I -e "$re" -- . >&2; then
      hit=1
    fi
  done
  if [[ "$hit" -ne 0 ]]; then
    echo "error: 已跟踪文件中检测到疑似密钥或令牌" >&2
    return 1
  fi
  return 0
}

case "${1:-}" in
  message) scan_message "${2:-}" ;;
  files)   scan_files ;;
  *)
    echo "用法: $0 message <文件> | $0 files" >&2
    exit 2
    ;;
esac
