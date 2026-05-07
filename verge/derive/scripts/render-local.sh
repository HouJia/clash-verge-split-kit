#!/usr/bin/env bash
# =============================================================================
# 生成本机最终可用的配置文件（INI + YAML 双格式）
# =============================================================================
# 将 template/config-template.ini 中的占位 IP 替换为真实 VPS IP，
# 并在规则列表最前面注入本地私有规则，同时生成 INI 和 YAML 两种格式。
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
DST_INI="${DST_DIR}/config.local.ini"
DST_YAML="${DST_DIR}/config.local.yaml"

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

mkdir -p "${DST_DIR}" "${LOCAL_DIR}"

# 准备临时文件
RULES_TMP="$(mktemp)"
tmp_ip="$(mktemp)"
tmp_out="$(mktemp)"
cleanup() {
  [[ -n "${RULES_TMP}" && -f "${RULES_TMP}" ]] && rm -f "${RULES_TMP}"
  [[ -n "${tmp_ip}" && -f "${tmp_ip}" ]] && rm -f "${tmp_ip}"
  [[ -n "${tmp_out}" && -f "${tmp_out}" ]] && rm -f "${tmp_out}"
}
trap cleanup EXIT

# 提取私有规则
if [[ -f "${OVERRIDE_FILE}" ]]; then
  extract_rules_to_file "${OVERRIDE_FILE}" "${RULES_TMP}"
fi

# 第一步：替换 IP 占位符
sed -e "s|YOUR_VPS_IP|${ip}|g" -e "s|192\.0\.2\.1|${ip}|g" "${TEMPLATE}" >"${tmp_ip}"

# 第二步：注入本地私有规则（在规则注入锚点处）
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

# 第三步：生成 INI 文件
{
  printf '; --- 本机生成元信息（由 render-local.sh 自动生成） ---\n'
  printf '; 生成时间：%s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')"
  printf '; VPS IP：%s\n' "${ip}"
  printf '; 源模板：verge/template/config-template.ini\n'
  printf '; 本机产物：verge/generated/config.local.ini\n'
  printf '; 注意：修改请编辑 derive/parts/rulesets/*.ini 和 generated/local/override.local\n'
  printf '; ---\n\n'
  cat "${tmp_out}"
} >"${DST_INI}"

# 第四步：生成 YAML 文件
ini_to_yaml() {
  local ini_file="$1"
  local in_custom=0
  local has_providers=0
  local group_def name type filter
  local -a options
  local idx temp_ifs opt clean_opt url interval tolerance
  local ruleset_def group_name rule_def provider_name
  local local_rule rule_type rule_content

  # 输出 proxy-groups
  echo "proxy-groups:"
  while IFS= read -r line || [[ -n "${line}" ]]; do
    if [[ "${line}" == "[custom]" ]]; then
      in_custom=1
      continue
    fi
    if [[ "${line}" =~ ^\[.*\]$ ]]; then
      in_custom=0
      continue
    fi
    [[ "${in_custom}" -eq 0 ]] && continue
    [[ -z "${line}" ]] && continue
    [[ "${line}" =~ ^[[:space:]]*\; ]] && continue
    if [[ "${line}" =~ ^custom_proxy_group=(.+)$ ]]; then
      group_def="${BASH_REMATCH[1]}"
      # 使用 IFS 读取到数组
      IFS='`' read -ra parts <<< "${group_def}"
      name="${parts[0]}"
      type="${parts[1]}"
      filter="${parts[2]:-}"
      options=()
      for ((i=3; i<${#parts[@]}; i++)); do
        options+=("${parts[i]}")
      done
      
      echo "  - name: '${name}'"
      echo "    type: ${type}"
      
      case "${type}" in
      "select")
        if [[ ${#options[@]} -gt 0 ]]; then
          echo "    proxies:"
          for opt in "${options[@]}"; do
            clean_opt="${opt}"
            if [[ "${opt}" =~ ^\[\](.+)$ ]]; then
              clean_opt="${BASH_REMATCH[1]}"
            fi
            echo "      - ${clean_opt}"
          done
        fi
        ;;
      "url-test")
        if [[ -n "${filter}" && "${filter}" != ".*" ]]; then
          echo "    include-all-proxies: true"
          echo "    exclude-filter: '(?i)海外用户专用'"
          echo "    filter: '${filter}'"
        else
          echo "    include-all-proxies: true"
          echo "    exclude-filter: '(?i)海外用户专用'"
        fi
        # 解析测速参数（格式：url`interval,tolerance 或 url`interval``tolerance）
        url="http://www.gstatic.com/generate_204"
        interval=300
        tolerance=50
        if [[ ${#options[@]} -ge 1 ]]; then
          url="${options[0]}"
        fi
        # 处理 interval,tolerance 格式（如 300,,50）
        if [[ ${#options[@]} -ge 2 ]]; then
          local interval_tol="${options[1]}"
          if [[ "${interval_tol}" =~ ^([0-9]+),+([0-9]+)$ ]]; then
            interval="${BASH_REMATCH[1]}"
            tolerance="${BASH_REMATCH[2]}"
          elif [[ -n "${interval_tol}" ]]; then
            interval="${interval_tol}"
          fi
        fi
        # 如果 tolerance 单独存在
        if [[ ${#options[@]} -ge 3 && -n "${options[2]}" ]]; then
          tolerance="${options[2]}"
        fi
        echo "    url: '${url}'"
        echo "    interval: ${interval}"
        echo "    tolerance: ${tolerance}"
        ;;
      esac
    fi
  done <"${ini_file}"
  
  echo ""
  
  # 输出 rule-providers
  has_providers=0
  in_custom=0
  while IFS= read -r line || [[ -n "${line}" ]]; do
    if [[ "${line}" == "[custom]" ]]; then
      in_custom=1
      continue
    fi
    if [[ "${line}" =~ ^\[.*\]$ ]]; then
      in_custom=0
      continue
    fi
    [[ "${in_custom}" -eq 0 ]] && continue
    [[ -z "${line}" ]] && continue
    [[ "${line}" =~ ^[[:space:]]*\; ]] && continue
    if [[ "${line}" =~ ^ruleset=(.+)$ ]]; then
      ruleset_def="${BASH_REMATCH[1]}"
      group_name=""
      rule_def=""
      if [[ "${ruleset_def}" =~ ^([^,]+),(.+)$ ]]; then
        group_name="${BASH_REMATCH[1]}"
        rule_def="${BASH_REMATCH[2]}"
      else
        continue
      fi
      if [[ "${rule_def}" =~ ^https?:// ]]; then
        if [[ "${has_providers}" -eq 0 ]]; then
          echo "rule-providers:"
          has_providers=1
        fi
        provider_name="remote-rules"
        if [[ "${rule_def}" =~ reject ]]; then
          provider_name="reject-loyal"
        fi
        echo "  ${provider_name}:"
        echo "    type: http"
        echo "    behavior: domain"
        echo "    format: text"
        echo "    url: ${rule_def}"
        echo "    path: ./ruleset/${provider_name}.txt"
        echo "    interval: 86400"
        break
      fi
    fi
  done <"${ini_file}"
  
  echo ""
  
  # 输出 rules
  echo "rules:"
  in_custom=0
  while IFS= read -r line || [[ -n "${line}" ]]; do
    if [[ "${line}" == "[custom]" ]]; then
      in_custom=1
      continue
    fi
    if [[ "${line}" =~ ^\[.*\]$ ]]; then
      in_custom=0
      continue
    fi
    [[ "${in_custom}" -eq 0 ]] && continue
    [[ -z "${line}" ]] && continue
    [[ "${line}" =~ ^[[:space:]]*\; ]] && continue
    if [[ "${line}" =~ ^ruleset=(.+)$ ]]; then
      ruleset_def="${BASH_REMATCH[1]}"
      group_name=""
      rule_def=""
      if [[ "${ruleset_def}" =~ ^([^,]+),(.+)$ ]]; then
        group_name="${BASH_REMATCH[1]}"
        rule_def="${BASH_REMATCH[2]}"
      else
        continue
      fi
      if [[ "${rule_def}" =~ ^\[\](.+)$ ]]; then
        local_rule="${BASH_REMATCH[1]}"
        if [[ "${local_rule}" =~ ^([^,]+),(.+)$ ]]; then
          rule_type="${BASH_REMATCH[1]}"
          rule_content="${BASH_REMATCH[2]}"
          if [[ "${rule_content}" =~ ,no-resolve$ ]]; then
            rule_content="${rule_content%,no-resolve}"
            echo "  - ${rule_type},${rule_content},${group_name},no-resolve"
          elif [[ "${rule_type}" == "FINAL" ]]; then
            echo "  - MATCH,${group_name}"
          else
            echo "  - ${rule_type},${rule_content},${group_name}"
          fi
        elif [[ "${local_rule}" == "FINAL" ]]; then
          echo "  - MATCH,${group_name}"
        fi
      fi
    fi
  done <"${ini_file}"
}

# 生成 YAML 文件
{
  printf '# --- 本机生成元信息（由 render-local.sh 自动生成） ---\n'
  printf '# 生成时间：%s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')"
  printf '# VPS IP：%s\n' "${ip}"
  printf '# 源模板：verge/template/config-template.ini\n'
  printf '# 本机产物：verge/generated/config.local.yaml\n'
  printf '# 注意：修改请编辑 derive/parts/rulesets/*.ini 和 generated/local/override.local\n'
  printf '# ---\n\n'
  ini_to_yaml "${tmp_out}"
} >"${DST_YAML}"

echo "已生成："
echo "  INI:  ${DST_INI}"
echo "  YAML: ${DST_YAML}"
echo "VPS IP：${ip}"
if has_content "${RULES_TMP}"; then
  echo "已注入本地私有规则（来自 ${OVERRIDE_FILE}）"
fi
