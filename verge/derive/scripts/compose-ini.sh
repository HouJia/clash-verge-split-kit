#!/usr/bin/env bash
# =============================================================================
# 合成终版 subconverter INI 配置文件
# =============================================================================
# 将 parts/20-routing.ini 与 parts/rulesets/*.ini 片段合并为单一 INI 文件
# 产物可直接用于 subconverter / Sub-Store 作为模板配置
#
# 用法:
#   bash compose-ini.sh [-o verge/template/config-template.ini]
#   默认打印到 stdout；-o 指定输出路径
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PARTS="${ROOT}/verge/derive/parts"
RULESETS_DIR="${PARTS}/rulesets"
OUT_PATH=""

usage() {
  echo "用法: $0 [-o verge/template/config-template.ini]" >&2
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

# 检查必需文件
REQ_FILE="${PARTS}/20-routing.ini"
[[ -f "$REQ_FILE" ]] || { echo "error: 缺少 ${REQ_FILE}" >&2; exit 2; }

# 读取规则片段并输出为 INI 格式
emit_ruleset_fragments() {
  local fragment file
  # 片段文件列表（按优先级顺序）
  local fragments=(
    "00-private.ini"
    "10-ads.ini"
    "20-cursor.ini"
    "30-ai.ini"
    "35-messaging.ini"
    "40-fcm.ini"
    "45-streaming.ini"
    "50-dev.ini"
    "55-scholar.ini"
    "60-tech-giants.ini"
    "65-gaming.ini"
    "70-domestic.ini"
    "80-geo.ini"
  )

  for fragment in "${fragments[@]}"; do
    file="${RULESETS_DIR}/${fragment}"
    if [[ -f "${file}" ]]; then
      # 读取文件内容，过滤出 ruleset= 行
      while IFS= read -r line || [[ -n "${line}" ]]; do
        # 跳过注释和空行
        [[ -z "${line}" ]] && continue
        [[ "${line}" =~ ^[[:space:]]*\; ]] && continue
        # 只输出 ruleset= 开头的行
        if [[ "${line}" =~ ^ruleset= ]]; then
          echo "${line}"
        fi
      done < "${file}"
    fi
  done
}

# 合并并注入片段
emit() {
  local in_injection_section=0

  while IFS= read -r line || [[ -n "${line}" ]]; do
    # 检测注入开始标记
    if [[ "${line}" == "; >>> RULESET_INJECTION_START" ]]; then
      echo "${line}"
      in_injection_section=1
      # 注入片段内容
      echo "; === 规则片段注入（由 compose-ini.sh 自动组装）==="
      echo "; 片段源：derive/parts/rulesets/*.ini"
      emit_ruleset_fragments
      continue
    fi

    # 检测注入结束标记
    if [[ "${line}" == "; <<< RULESET_INJECTION_END" ]]; then
      echo "${line}"
      in_injection_section=0
      continue
    fi

    # 如果在注入区域内，跳过原有内容（除了标记行）
    if [[ "${in_injection_section}" -eq 1 ]]; then
      continue
    fi

    # 输出其他行
    echo "${line}"
  done < "${REQ_FILE}"
}

# 执行输出
if [[ -n "${OUT_PATH}" ]]; then
  tmp="$(mktemp)"
  trap 'rm -f "${tmp}"' EXIT
  emit >"${tmp}"
  mv "${tmp}" "${OUT_PATH}"
  trap - EXIT
  echo "已生成：${OUT_PATH}"
else
  emit
fi
