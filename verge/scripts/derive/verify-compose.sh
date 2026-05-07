#!/usr/bin/env bash
# 校验 extend/airport-rule-split-extend.yaml 与 derive/parts 合并结果一致。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXPECTED="${ROOT}/template/airport-rule-split-extend.yaml"
COMPOSE="${ROOT}/scripts/derive/compose.sh"

[[ -f "${EXPECTED}" ]] || { echo "error: 缺少 ${EXPECTED}" >&2; exit 2; }
[[ -x "${COMPOSE}" ]] || COMPOSE="bash ${COMPOSE}"

got="$(mktemp)"
trap 'rm -f "${got}"' EXIT
bash "${ROOT}/derive/compose.sh" >"${got}"

if ! cmp -s "${got}" "${EXPECTED}"; then
  echo "error: airport-rule-split-extend.yaml 与 derive/parts 不一致。" >&2
  echo "  请执行: bash verge/scripts/derive/compose.sh -o verge/template/airport-rule-split-extend.yaml" >&2
  diff -u "${EXPECTED}" "${got}" | head -80 >&2 || true
  exit 1
fi
