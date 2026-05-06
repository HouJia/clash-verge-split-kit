#!/usr/bin/env bash
# Privacy Guard - 隐私信息泄漏扫描工具
# 从 override.local 动态提取敏感信息，扫描提交内容和 commit message
#
# 用法：
#   bash privacy-guard.sh [files|message]
#     files   - 扫描暂存区文件（pre-commit 用）
#     message - 扫描提交信息（post-commit / CI 用）

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OVERRIDE_LOCAL="${ROOT}/verge/generated/local/override.local"
TEMP_DIR=""
SENSITIVE_PATTERNS=()

cleanup() {
  [[ -n "${TEMP_DIR:-}" && -d "${TEMP_DIR}" ]] && rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT

# 提取 IP 地址（支持 IPv4 和 CIDR）
extract_ips() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?' "$file" 2>/dev/null | sort -u || true
}

# 提取域名（DOMAIN-SUFFIX, DOMAIN 等）
extract_domains() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  # 提取 DOMAIN-SUFFIX,xxx.com 或 DOMAIN,xxx.com 中的域名
  grep -oE '(DOMAIN-SUFFIX|DOMAIN),[^,]+' "$file" 2>/dev/null | sed 's/^[^,]*,//' | sort -u || true
  # 也提取 GEOSITE 名称作为可能的敏感信息
  grep -oE 'GEOSITE,[^,]+' "$file" 2>/dev/null | sed 's/GEOSITE,//' | grep -vE '^(aws|azure|aliyun|google|apple|microsoft)$' | sort -u || true
}

# 构建敏感信息模式列表
build_sensitive_patterns() {
  SENSITIVE_PATTERNS=()
  local patterns_file="${TEMP_DIR}/patterns"
  
  # 从 override.local 提取
  if [[ -f "$OVERRIDE_LOCAL" ]]; then
    # 提取 IP（排除常见示例 IP 如 192.0.2.x, 203.0.113.x 等 RFC 5737 测试地址）
    extract_ips "$OVERRIDE_LOCAL" | grep -vE '^(192\.0\.2\.|198\.51\.100\.|203\.0\.113\.|240\.0\.0\.)' >> "$patterns_file" 2>/dev/null || true
    
    # 提取域名（排除示例域名）
    extract_domains "$OVERRIDE_LOCAL" | grep -vE '^(example|example-airport|my-home-nas|your-nas|localhost)\.?(local|org|com)?$' >> "$patterns_file" 2>/dev/null || true
  fi
  
  # 去重并读取到数组
  if [[ -f "$patterns_file" ]]; then
    while IFS= read -r pattern; do
      [[ -n "$pattern" ]] && SENSITIVE_PATTERNS+=("$pattern")
    done < <(sort -u "$patterns_file")
  fi
  
  # 如果 override.local 不存在，使用保守的默认模式
  if [[ ${#SENSITIVE_PATTERNS[@]} -eq 0 ]]; then
    echo "警告：未找到 override.local，使用保守扫描模式" >&2
    # 保守模式：只扫描明显的私有 IP 段
    SENSITIVE_PATTERNS=("10." "172.16." "192.168." "127.")
  fi
}

# 扫描文件内容
scan_files() {
  local found=0
  local scan_targets=""
  
  # 获取暂存区文件列表
  scan_targets=$(git diff --cached --name-only 2>/dev/null || true)
  [[ -z "$scan_targets" ]] && return 0
  
  echo "🔒 Privacy Guard: 扫描暂存区文件..." >&2
  
  # 创建临时文件存储扫描内容
  local temp_scan="${TEMP_DIR}/scan_content"
  
  for file in $scan_targets; do
    # 跳过二进制文件和特定路径
    [[ "$file" =~ \.(png|jpg|jpeg|gif|ico|woff|woff2|ttf|eot)$ ]] && continue
    [[ "$file" == "verge/generated/local/override.local" ]] && continue
    [[ "$file" == ".gitignore" ]] && continue
    # 跳过扫描脚本自身（避免正则表达式被误认为隐私信息）
    [[ "$file" == "verge/scripts/privacy-guard.sh" ]] && continue
    
    # 获取暂存区文件内容
    if git show ":$file" 2>/dev/null > "$temp_scan" 2>/dev/null; then
      for pattern in "${SENSITIVE_PATTERNS[@]}"; do
        if grep -qF "$pattern" "$temp_scan" 2>/dev/null; then
          local line_nums=$(grep -nF "$pattern" "$temp_scan" 2>/dev/null | head -3 | cut -d: -f1 | tr '\n' ',' | sed 's/,$//')
          echo "❌ 隐私泄漏风险: 文件 '$file' 第 ${line_nums} 行包含敏感信息 '${pattern}'" >&2
          found=1
        fi
      done
    fi
  done
  
  return $found
}

# 扫描 commit message
scan_message() {
  local message="${1:-}"
  local found=0
  
  [[ -z "$message" ]] && return 0
  
  echo "🔒 Privacy Guard: 扫描 commit message..." >&2
  
  for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if echo "$message" | grep -qF "$pattern" 2>/dev/null; then
      echo "❌ 隐私泄漏风险: commit message 包含敏感信息 '${pattern}'" >&2
      found=1
    fi
  done
  
  return $found
}

# 检查提交信息是否泛化
validate_commit_message() {
  local msg_file="${1:-}"
  [[ -f "$msg_file" ]] || return 0
  
  local msg_content=$(cat "$msg_file")
  local issues=()
  
  # 检查是否包含具体 IP
  if echo "$msg_content" | grep -qE '([0-9]{1,3}\.){3}[0-9]{1,3}'; then
    issues+=("commit message 包含具体 IP 地址，请泛化为 <YOUR_IP> 或 '我的 IP'")
  fi
  
  # 检查是否包含具体域名（排除 Co-authored-by 行和公共域名）
  local filtered_content=$(echo "$msg_content" | grep -vE '^Co-authored-by:')
  if echo "$filtered_content" | grep -qE '[a-zA-Z0-9.-]+\.(org|com|net|io|dev|app|cn)\b'; then
    local domain=$(echo "$filtered_content" | grep -oE '[a-zA-Z0-9.-]+\.(org|com|net|io|dev|app|cn)\b' | head -1)
    # 白名单：公共域名、常见服务商
    local whitelist="(example|localhost|test|demo|sample|github|git|cursor|microsoft|google|apple|amazon|facebook|twitter|x\.com|wechat|qq|baidu|aliyun|tencent)"
    if [[ -n "$domain" && ! "$domain" =~ $whitelist ]]; then
      issues+=("commit message 可能包含具体域名 '${domain}'，请泛化处理")
    fi
  fi
  
  if [[ ${#issues[@]} -gt 0 ]]; then
    echo "⚠️  Privacy Guard: commit message 隐私检查未通过" >&2
    for issue in "${issues[@]}"; do
      echo "   - $issue" >&2
    done
    echo "" >&2
    echo "建议修改方式：" >&2
    echo "  ❌ '添加 203.0.113.10 直连规则'  ← 包含具体 IP" >&2
    echo "  ✅ '添加我的 VPS IP 直连规则'     ← 泛化描述" >&2
    echo "  ❌ '支持 example-airport.org 直连' ← 包含具体域名" >&2
    echo "  ✅ '支持机场面板域名直连'         ← 泛化描述" >&2
    return 1
  fi
  
  return 0
}

# 主函数
main() {
  TEMP_DIR=$(mktemp -d)
  local mode="${1:-files}"
  
  # 构建敏感信息模式
  build_sensitive_patterns
  
  if [[ ${#SENSITIVE_PATTERNS[@]} -eq 0 ]]; then
    echo "✅ Privacy Guard: 无敏感信息配置，跳过扫描" >&2
    exit 0
  fi
  
  echo "🔒 Privacy Guard: 已加载 ${#SENSITIVE_PATTERNS[@]} 个隐私模式" >&2
  
  case "$mode" in
    files)
      if ! scan_files; then
        echo "" >&2
        echo "🚫 阻止提交：发现隐私信息泄漏风险！" >&2
        echo "" >&2
        echo "解决方法：" >&2
        echo "  1. 确认泄漏内容是否需要提交" >&2
        echo "  2. 如必须提交，请使用通用占位符（如 <YOUR_IP>、example.com）" >&2
        echo "  3. 私有配置应放入 verge/generated/local/override.local（被 .gitignore 排除）" >&2
        echo "" >&2
        echo "如需强制提交（不推荐），使用：git commit --no-verify" >&2
        exit 1
      fi
      echo "✅ Privacy Guard: 文件扫描通过" >&2
      ;;
    message)
      local msg_file="${2:-}"
      if [[ -n "$msg_file" ]]; then
        if ! validate_commit_message "$msg_file"; then
          echo "🚫 阻止提交：commit message 包含隐私信息！" >&2
          exit 1
        fi
      fi
      ;;
    *)
      echo "用法: $0 [files|message [msg_file]]" >&2
      exit 2
      ;;
  esac
  
  exit 0
}

main "$@"
