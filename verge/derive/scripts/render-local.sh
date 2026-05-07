#!/usr/bin/env bash
# =============================================================================
# 生成本机最终可用的 INI 配置文件
# =============================================================================
# 将 template/config-template.ini 中的占位 IP 替换为真实 VPS IP，
# 并在规则列表最前面注入本地私有规则。
#
# 用法:
#   bash render-local.sh [你的公网IPv4]
#   或配置 override.local 的 [vps] 节，然后直接运行
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TEMPLATE="${ROOT}/verge/template/config-template.ini"
DST_DIR="${ROOT}/verge/generated"
LOCAL_DIR="${DST_DIR}/local"
OVERRIDE_FILE="${LOCAL_DIR}/override.local"
DST="${DST_DIR}/config.local.ini"

# 自 override.local 的 [vps] 段读取第一个非注释非空行作为 IPv4
read_ip_from_override() {
  local f="$1"
  [[ -f "$f" ]] || return 1
  local line ip in_vps=0
  while IFS= read -r line || [[ -n "${line}" ]]; do
    if [[ "${line}" =~ ^[[:space:]]*\[vps\][[:space:]]*$ ]]; then
      in_vps=1
      continue
    fi
    if [[ "${line}" =~ ^[[:space:]]*\[[^]]+\][[:space:]]*$ ]]; then
      in_vps=0
      continue
    fi
    if [[ "${in_vps}" -eq 1 ]]; then
      [[ "${line}" =~ ^[[:space:]]*# ]] && continue
      ip="$(echo "${line}" | tr -d '[:space:]')"
      [[ -n "${ip}" ]] && echo "${ip}" && return 0
    fi
  done <"${f}"
  return 1
}

# 将 [rules] 段内容写入临时文件
extract_rules_to_file() {
  local f="$1" out="$2"
  : >"${out}"
  [[ -f "$f" ]] || return 0
  local line in_rules=0
  while IFS= read -r line || [[ -n "${line}" ]]; do
    if [[ "${line}" =~ ^[[:space:]]*\[rules\][[:space:]]*$ ]]; then
      in_rules=1
      continue
    fi
    if [[ "${in_rules}" -eq 1 ]]; then
      if [[ "${line}" =~ ^[[:space:]]*\[[^]]+\][[:space:]]*$ ]]; then
        break
      fi
      printf '%s\n' "${line}" >>"${out}"
    fi
  done <"${f}"
}

# 检查文件是否有非注释非空内容
has_content() {
  local f="$1"
  [[ -f "$f" ]] || return 1
  local line
  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ "${line}" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    return 0
  done <"${f}"
  return 1
}

# 获取 IP（优先级：命令行参数 > override.local）
ip="${1:-}"
ip="$(echo "${ip}" | tr -d '[:space:]')"
if [[ -z "${ip}" ]] && [[ -f "${OVERRIDE_FILE}" ]]; then
  ip="$(read_ip_from_override "${OVERRIDE_FILE}" 2>/dev/null || true)"
  ip="$(echo "${ip}" | tr -d '[:space:]')"
fi

if [[ -z "${ip}" ]]; then
  echo "用法（任选其一）：" >&2
  echo "  bash verge/derive/scripts/render-local.sh 你的公网IPv4" >&2
  echo "  或在 ${OVERRIDE_FILE} 的 [vps] 节写入 IPv4 后直接运行" >&2
  exit 2
fi

if [[ ! -f "${TEMPLATE}" ]]; then
  echo "error: 缺少模板 ${TEMPLATE}" >&2
  exit 2
fi

# 检查模板中是否有可替换的占位符
if ! grep -qE 'YOUR_VPS_IP|192\.0\.2\.1' "${TEMPLATE}"; then
  echo "warning: 模板中未找到 VPS 占位符（YOUR_VPS_IP 或 192.0.2.1）" >&2
fi

mkdir -p "${DST_DIR}" "${LOCAL_DIR}"

# 准备临时文件
RULES_TMP="$(mktemp)"
cleanup() {
  [[ -n "${RULES_TMP}" && -f "${RULES_TMP}" ]] && rm -f "${RULES_TMP}"
}
trap cleanup EXIT

# 提取私有规则
if [[ -f "${OVERRIDE_FILE}" ]]; then
  extract_rules_to_file "${OVERRIDE_FILE}" "${RULES_TMP}"
fi

# 第一步：替换 IP 占位符
tmp_ip="$(mktemp)"
sed -e "s|YOUR_VPS_IP|${ip}|g" -e "s|192\.0\.2\.1|${ip}|g" "${TEMPLATE}" >"${tmp_ip}"

# 第二步：注入本地私有规则（在规则注入锚点处）
tmp_out="$(mktemp)"
injected=0
while IFS= read -r line || [[ -n "${line}" ]]; do
  # 检测规则注入开始标记
  if [[ "${line}" == "; >>> RULESET_INJECTION_START" ]]; then
    echo "${line}"
    echo "; === 规则片段注入（由 compose-ini.sh 自动组装）==="
    echo "; 片段源：derive/parts/rulesets/*.ini"
    
    # 注入本地私有规则（如果有）
    if has_content "${RULES_TMP}"; then
      echo ""
      echo "; ============================================================================="
      echo "; 📋 本地私有规则（最高优先级，在标准规则之前命中）"
      echo "; 来源：${OVERRIDE_FILE} 的 [rules] 节"
      echo "; ============================================================================="
      cat "${RULES_TMP}"
      echo ""
    fi
    
    injected=1
    continue
  fi

  # 如果在注入标记之间，保留原有的标准规则内容
  if [[ "${injected}" -eq 1 ]]; then
    if [[ "${line}" == "; <<< RULESET_INJECTION_END" ]]; then
      echo "${line}"
      injected=0
      continue
    fi
    printf '%s\n' "${line}"
    continue
  fi

  printf '%s\n' "${line}"
done <"${tmp_ip}" >"${tmp_out}"

rm -f "${tmp_ip}"

# 第三步：添加元信息头并写入最终文件
{
  printf '; --- 本机生成元信息（由 render-local.sh 自动生成） ---\n'
  printf '; 生成时间：%s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')"
  printf '; VPS IP：%s\n' "${ip}"
  printf '; 源模板：verge/template/config-template.ini\n'
  printf '; 本机产物：verge/generated/config.local.ini\n'
  printf '; 注意：修改请编辑 derive/parts/rulesets/*.ini 和 generated/local/override.local\n'
  printf '; ---\n\n'
  cat "${tmp_out}"
} >"${DST}"

rm -f "${tmp_out}"

echo "已生成：${DST}"
echo "VPS IP：${ip}"
if has_content "${RULES_TMP}"; then
  echo "已注入本地私有规则（来自 ${OVERRIDE_FILE}）"
fi
