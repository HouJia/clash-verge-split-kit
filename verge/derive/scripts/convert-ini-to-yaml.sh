#!/usr/bin/env bash
# =============================================================================
# 将 subconverter INI 配置转换为 Mihomo YAML 格式
# =============================================================================
# 用于从 INI 真值源生成 Mihomo/Clash Verge 可用的 YAML 配置
#
# 用法:
#   bash convert-ini-to-yaml.sh -i verge/config-template.ini [-o verge/config-template.yaml]
#   -i 指定输入 INI 文件
#   -o 指定输出 YAML 文件（默认 stdout）
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PARTS="${ROOT}/derive/parts"
RUNTIME_FILE="${PARTS}/10-runtime-verge-mihomo.yaml"
INI_PATH=""
OUT_PATH=""

usage() {
  echo "用法: $0 -i verge/template/config-template.ini [-o verge/template/config-template.yaml]" >&2
  echo "  -i  输入 INI 文件路径（必需）" >&2
  echo "  -o  输出 YAML 文件路径（默认 stdout）" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  -i)
    [[ -n "${2:-}" ]] || usage
    INI_PATH="$2"
    shift 2
    ;;
  -o)
    [[ -n "${2:-}" ]] || usage
    OUT_PATH="$2"
    shift 2
    ;;
  -h|--help) usage ;;
  *) usage ;;
  esac
done

[[ -f "${INI_PATH}" ]] || { echo "error: 找不到输入文件 ${INI_PATH}" >&2; exit 2; }
[[ -f "${RUNTIME_FILE}" ]] || { echo "error: 找不到运行时配置文件 ${RUNTIME_FILE}" >&2; exit 2; }

# 解析 INI 的 custom_proxy_group 行，输出 YAML 格式
proxy_group_exclude_filter() {
  local group_name="$1"
  case "${group_name}" in
  "底座 · ♻️ 自动最优")
    echo "(?i)(海外用户专用|原生|isp)"
    ;;
  *)
    echo "(?i)海外用户专用"
    ;;
  esac
}

parse_proxy_groups() {
  local ini_file="$1"
  local in_custom_section=0

  echo "proxy-groups:"

  while IFS= read -r line || [[ -n "${line}" ]]; do
    # 检测 [custom] 段落开始
    if [[ "${line}" == "[custom]" ]]; then
      in_custom_section=1
      continue
    fi

    # 检测其他段落开始（结束 custom 段落）
    if [[ "${line}" =~ ^\[.*\]$ ]]; then
      in_custom_section=0
      continue
    fi

    # 只处理 custom 段落内的行
    [[ "${in_custom_section}" -eq 0 ]] && continue

    # 跳过注释和空行
    [[ -z "${line}" ]] && continue
    [[ "${line}" =~ ^[[:space:]]*\; ]] && continue

    # 解析 custom_proxy_group 行
    if [[ "${line}" =~ ^custom_proxy_group=(.+)$ ]]; then
      local group_def="${BASH_REMATCH[1]}"

      # 按反引号分割
      local name="" type="" filter="" options=()
      local idx=0
      local temp_ifs="$IFS"
      IFS='`'
      for part in ${group_def}; do
        case $idx in
        0) name="${part}" ;;
        1) type="${part}" ;;
        2) filter="${part}" ;;
        *) options+=("${part}") ;;
        esac
        ((idx++))
      done
      IFS="${temp_ifs}"

      # 输出 YAML 格式
      echo "  - name: '${name}'"
      echo "    type: ${type}"

      # 根据类型输出不同字段
      case "${type}" in
      "select")
        if [[ "${filter}" == ".*" ]]; then
          echo "    include-all-proxies: true"
          echo "    exclude-filter: '$(proxy_group_exclude_filter "${name}")'"
        elif [[ -n "${filter}" ]]; then
          echo "    include-all-proxies: true"
          echo "    exclude-filter: '$(proxy_group_exclude_filter "${name}")'"
          echo "    filter: '${filter}'"
        fi
        if [[ ${#options[@]} -gt 0 ]]; then
          echo "    proxies:"
          for opt in "${options[@]}"; do
            # 移除 [] 前缀
            local clean_opt="${opt}"
            if [[ "${opt}" =~ ^\[\](.+)$ ]]; then
              clean_opt="${BASH_REMATCH[1]}"
            fi
            echo "      - ${clean_opt}"
          done
        fi
        ;;
      "url-test")
        # url-test 类型输出 filter 和其他参数
        if [[ -n "${filter}" && "${filter}" != ".*" ]]; then
          echo "    include-all-proxies: true"
          echo "    exclude-filter: '$(proxy_group_exclude_filter "${name}")'"
          echo "    filter: '${filter}'"
        else
          echo "    include-all-proxies: true"
          echo "    exclude-filter: '$(proxy_group_exclude_filter "${name}")'"
        fi
        # 输出测速参数
        local url="http://www.gstatic.com/generate_204"
        local interval=300
        local tolerance=50

        # 从 options 中提取参数
        if [[ ${#options[@]} -ge 1 ]]; then
          url="${options[0]}"
        fi
        if [[ ${#options[@]} -ge 2 ]]; then
          interval="${options[1]}"
        fi
        if [[ ${#options[@]} -ge 3 ]]; then
          tolerance="${options[2]}"
        fi

        echo "    url: '${url}'"
        echo "    interval: ${interval}"
        echo "    tolerance: ${tolerance}"
        ;;
      esac
    fi
  done < "${ini_file}"
}

# 解析 INI 的 ruleset 行，输出 YAML 格式
parse_rules() {
  local ini_file="$1"
  local in_custom_section=0

  echo "rules:"

  while IFS= read -r line || [[ -n "${line}" ]]; do
    # 检测 [custom] 段落开始
    if [[ "${line}" == "[custom]" ]]; then
      in_custom_section=1
      continue
    fi

    # 检测其他段落开始
    if [[ "${line}" =~ ^\[.*\]$ ]]; then
      in_custom_section=0
      continue
    fi

    # 只处理 custom 段落内的行
    [[ "${in_custom_section}" -eq 0 ]] && continue

    # 跳过注释和空行
    [[ -z "${line}" ]] && continue
    [[ "${line}" =~ ^[[:space:]]*\; ]] && continue

    # 解析 ruleset 行
    if [[ "${line}" =~ ^ruleset=(.+)$ ]]; then
      local ruleset_def="${BASH_REMATCH[1]}"

      # 分割策略组和规则定义
      local group_name="" rule_def=""
      if [[ "${ruleset_def}" =~ ^([^,]+),(.+)$ ]]; then
        group_name="${BASH_REMATCH[1]}"
        rule_def="${BASH_REMATCH[2]}"
      else
        continue
      fi

      # 判断是本地规则还是远程规则
      if [[ "${rule_def}" =~ ^\[\](.+)$ ]]; then
        # 本地规则: []RULE_TYPE,content
        local local_rule="${BASH_REMATCH[1]}"

        # 解析本地规则
        if [[ "${local_rule}" =~ ^([^,]+),(.+)$ ]]; then
          local rule_type="${BASH_REMATCH[1]}"
          local rule_content="${BASH_REMATCH[2]}"

          # 处理带 no-resolve 的情况
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
      else
        # 远程规则: URL，跳过（在 rule-providers 中处理）
        continue
      fi
    fi
  done < "${ini_file}"
}

# 解析远程 ruleset，输出 rule-providers
parse_rule_providers() {
  local ini_file="$1"
  local in_custom_section=0
  local has_providers=0

  while IFS= read -r line || [[ -n "${line}" ]]; do
    # 检测 [custom] 段落开始
    if [[ "${line}" == "[custom]" ]]; then
      in_custom_section=1
      continue
    fi

    # 检测其他段落开始
    if [[ "${line}" =~ ^\[.*\]$ ]]; then
      in_custom_section=0
      continue
    fi

    # 只处理 custom 段落内的行
    [[ "${in_custom_section}" -eq 0 ]] && continue

    # 跳过注释和空行
    [[ -z "${line}" ]] && continue
    [[ "${line}" =~ ^[[:space:]]*\; ]] && continue

    # 解析 ruleset 行，找远程规则
    if [[ "${line}" =~ ^ruleset=(.+)$ ]]; then
      local ruleset_def="${BASH_REMATCH[1]}"

      # 分割策略组和规则定义
      local group_name="" rule_def=""
      if [[ "${ruleset_def}" =~ ^([^,]+),(.+)$ ]]; then
        group_name="${BASH_REMATCH[1]}"
        rule_def="${BASH_REMATCH[2]}"
      else
        continue
      fi

      # 判断是远程规则（以 http 开头）
      if [[ "${rule_def}" =~ ^https?:// ]]; then
        if [[ "${has_providers}" -eq 0 ]]; then
          echo "rule-providers:"
          has_providers=1
        fi

        # 生成 provider 名称（从 URL 提取）
        local provider_name="remote-rules"
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

        # 只处理第一个远程规则（避免重复）
        break
      fi
    fi
  done < "${ini_file}"
}

# 主生成逻辑
emit() {
  # 输出文档头
  echo "# ============================================================================="
  echo "# Mihomo/Clash Verge 扩展配置"
  echo "# 源文件：由 convert-ini-to-yaml.sh 从 INI 真值源转换生成"
  echo "# 警告：本文件为自动生成产物，修改请编辑 verge/derive/parts/*.ini"
  echo "# ============================================================================="
  echo ""

  # 输出运行时配置
  cat "${RUNTIME_FILE}"
  echo ""

  # 输出 proxy-groups
  parse_proxy_groups "${INI_PATH}"
  echo ""

  # 输出 rule-providers（如果有）
  parse_rule_providers "${INI_PATH}"
  echo ""

  # 输出 rules
  parse_rules "${INI_PATH}"
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
