#!/usr/bin/env bash
# =============================================================================
# 将 houjia.local-template.* 推送到 CONFIG_PAIR_GIST（新增文件名，不覆盖历史 config.local.*）
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ENV="${ROOT}/verge/generated/local/gist-sync.local.env"
INI="${ROOT}/verge/generated/houjia.local-template.ini"
YAML="${ROOT}/verge/generated/houjia.local-template.yaml"
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

gh gist edit "${CONFIG_PAIR_GIST_ID}" --filename houjia.local-template.ini "${INI}" 2>/dev/null \
  || gh gist edit "${CONFIG_PAIR_GIST_ID}" --add houjia.local-template.ini "${INI}"
gh gist edit "${CONFIG_PAIR_GIST_ID}" --filename houjia.local-template.yaml "${YAML}" 2>/dev/null \
  || gh gist edit "${CONFIG_PAIR_GIST_ID}" --add houjia.local-template.yaml "${YAML}"
gh gist edit "${OVERRIDE_GIST_ID}" --filename override.local.ini "${OVERRIDE}"

echo "ok: 已更新 gist 中的 houjia.local-template.*（未改动历史 config.local.*）"

sleep 3
VERIFY="${ROOT}/verge/derive/scripts/verify-native-split.sh"
if [[ -x "${VERIFY}" ]]; then
  bash "${VERIFY}"
else
  bash "${VERIFY}"
fi
