#!/usr/bin/env bash
# Cursor afterFileEdit：编辑 derive/parts、*-rule-split-extend.yaml 或本机 override 后，刷新 generated/ 产物。
set -euo pipefail

INPUT_JSON="$(cat)"
FILE_PATH="$(python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("file_path") or "")' <<<"${INPUT_JSON}")"

NORMALIZED="${FILE_PATH//\\//}"

render_local() {
  local root="$1"
  local script="${root}/verge/derive/scripts/render-local.sh"
  if [[ ! -f "${script}" ]]; then
    script="${root}/verge/scripts/render-local.sh"
  fi
  [[ -f "${script}" ]] || {
    echo "verge-hook: 未找到 render-local.sh（试过 verge/derive/scripts 与 verge/scripts）。详见 verge/README.md" >&2
    return 0
  }
  if ! bash "${script}" >/dev/null 2>&1; then
    echo "verge-hook: render-local.sh 未生成（请配置 verge/generated/local/override.local.ini 的 [vps]、或传入公网 IP）。详见 verge/README.md" >&2
  fi
}

case "${NORMALIZED}" in
*/verge/derive/parts/*)
  REPO_ROOT="$(git -C "$(dirname "${FILE_PATH}")" rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -z "${REPO_ROOT}" ]]; then
    REPO_ROOT="$(cd "$(dirname "${FILE_PATH}")/../../.." && pwd)"
  fi
  COMPOSE="${REPO_ROOT}/verge/derive/scripts/compose-ini.sh"
  if [[ -f "${COMPOSE}" ]]; then
    bash "${COMPOSE}" -o "${REPO_ROOT}/verge/template/config-template.ini" || exit 0
  fi
  render_local "${REPO_ROOT}"
  exit 0
  ;;
*/verge/generated/local/override.local.ini)
  OVR_DIR="$(dirname "${FILE_PATH}")"
  REPO_ROOT="$(git -C "${OVR_DIR}" rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -z "${REPO_ROOT}" ]]; then
    REPO_ROOT="$(cd "${OVR_DIR}/../../.." && pwd)"
  fi
  render_local "${REPO_ROOT}"
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
SCRIPT="${REPO_ROOT}/verge/derive/scripts/render-local.sh"
if [[ ! -f "${SCRIPT}" ]]; then
  SCRIPT="${REPO_ROOT}/verge/scripts/render-local.sh"
fi
# 历史路径：extend → template
EXT_BASE="${EXT_BASE/extend/template}"

if [[ ! -f "${SCRIPT}" ]]; then
  echo "verge-hook: 缺少 ${SCRIPT}" >&2
  exit 0
fi

if ! VERGE_EXTEND_FILE="${EXT_BASE}" bash "${SCRIPT}" >/dev/null 2>&1; then
  echo "verge-hook: render-local.sh 未生成（请配置 verge/generated/local/override.local.ini 的 [vps]、或 VPS_PUBLIC_IP）。详见 verge/README.md" >&2
fi

exit 0
