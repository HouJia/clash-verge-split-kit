#!/usr/bin/env bash
# =============================================================================
# 将本机生成物推送到已存在的 GitHub Gist（secret gist，由 gh 默认）
# =============================================================================
# 不在仓库中存放 Gist ID：读 verge/generated/local/gist-sync.local.env（gitignore）
# 映射说明：同目录 GIST-SYNC.local.md（gitignore）
#
# 用法（仓库根）:
#   bash verge/derive/scripts/sync-generated-gists.sh
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ENV="${ROOT}/verge/generated/local/gist-sync.local.env"
INI="${ROOT}/verge/generated/config.local.ini"
YAML="${ROOT}/verge/generated/config.local.yaml"
OVERRIDE="${ROOT}/verge/generated/local/override.local.ini"
EXAMPLE="${ROOT}/verge/generated/local/gist-sync.local.env.example"

[[ -f "${ENV}" ]] || {
  echo "error: 缺少 ${ENV}" >&2
  echo "请复制：${EXAMPLE} → gist-sync.local.env 并填写 CONFIG_PAIR_GIST_ID / OVERRIDE_GIST_ID" >&2
  exit 2
}

set -a
# shellcheck disable=SC1090
source "${ENV}"
set +a

[[ -n "${CONFIG_PAIR_GIST_ID:-}" ]] || { echo "error: CONFIG_PAIR_GIST_ID 未设置" >&2; exit 2; }
[[ -n "${OVERRIDE_GIST_ID:-}" ]] || { echo "error: OVERRIDE_GIST_ID 未设置" >&2; exit 2; }

[[ -f "${INI}" ]] && [[ -f "${YAML}" ]] || {
  echo "error: 缺少 ${INI} 或 ${YAML}，请先 bash verge/derive/scripts/render-local.sh" >&2
  exit 2
}
[[ -f "${OVERRIDE}" ]] || {
  echo "error: 缺少 ${OVERRIDE}" >&2
  exit 2
}

command -v gh >/dev/null 2>&1 || { echo "error: 需要 gh（GitHub CLI）" >&2; exit 2; }

gh gist edit "${CONFIG_PAIR_GIST_ID}" --filename config.local.ini "${INI}"
gh gist edit "${CONFIG_PAIR_GIST_ID}" --filename config.local.yaml "${YAML}"
gh gist edit "${OVERRIDE_GIST_ID}" --filename override.local.ini "${OVERRIDE}"

echo "ok: 已用本地文件更新两份 secret gist（对照仅写在 GIST-SYNC.local.md）"
