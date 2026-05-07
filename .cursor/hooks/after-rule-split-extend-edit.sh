#!/usr/bin/env bash
# Cursor afterFileEdit：若编辑 verge/extend/*-rule-split-extend.yaml，则刷新 generated/ 下成对本机稿。
set -euo pipefail

INPUT_JSON="$(cat)"
FILE_PATH="$(python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("file_path") or "")' <<<"${INPUT_JSON}")"

NORMALIZED="${FILE_PATH//\\//}"
case "${NORMALIZED}" in
*/verge/derive/parts/*)
  REPO_ROOT="$(git -C "$(dirname "${FILE_PATH}")" rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -z "${REPO_ROOT}" ]]; then
    REPO_ROOT="$(cd "$(dirname "${FILE_PATH}")/../../.." && pwd)"
  fi
  COMPOSE="${REPO_ROOT}/verge/scripts/derive/compose.sh"
  SCRIPT="${REPO_ROOT}/verge/scripts/render-local.sh"
  if [[ -f "${COMPOSE}" ]]; then
    bash "${COMPOSE}" -o "${REPO_ROOT}/verge/template/airport-rule-split-extend.yaml" || exit 0
  fi
  if [[ -f "${SCRIPT}" ]]; then
    VERGE_EXTEND_FILE=airport-rule-split-extend.yaml bash "${SCRIPT}" >/dev/null 2>&1 || true
  fi
  exit 0
  ;;
*/verge/template/*-rule-split-extend.yaml) ;;
*) exit 0 ;;
esac

EXT_BASE="$(basename "${NORMALIZED}")"
EXT_DIR="$(dirname "${FILE_PATH}")"
REPO_ROOT="$(git -C "${EXT_DIR}" rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${REPO_ROOT}" ]]; then
  REPO_ROOT="$(cd "${EXT_DIR}/../.." && pwd)"
fi
SCRIPT="${REPO_ROOT}/verge/scripts/render-local.sh"
# 更新文件路径引用从 extend 到 template
EXT_BASE="${EXT_BASE/extend/template}"

if [[ ! -f "${SCRIPT}" ]]; then
  echo "verge-hook: 缺少 ${SCRIPT}" >&2
  exit 0
fi

if ! VERGE_EXTEND_FILE="${EXT_BASE}" bash "${SCRIPT}" >/dev/null 2>&1; then
  echo "verge-hook: render-local.sh 未生成（请配置 verge/generated/local/override.local 的 [vps]、或 VPS_PUBLIC_IP）。详见 verge/README.md" >&2
fi

exit 0
