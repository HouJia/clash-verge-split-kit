#!/usr/bin/env bash
# 将 extend/*.yaml Extend 模板中占位公网 IP（YOUR_VPS_IP 或 192.0.2.1）替换为真实公网 IP，
# 并在规则列表最前面注入本地私有规则。
#
# 原因：模板里的 RFC 5737 测试地址 / 占位符仅便于入库；写入本机产物时必须改为真实 IPv4，
#       IP-CIDR … DIRECT 才指向你的 VPS，而非无效地址。
#
# 本机覆写：`verge/generated/local/override.local`（分节见同目录 override.local.example）。
# [rules] 节包含所有本地私有规则，将被放在最高优先级位置（在标准规则之前）。
#
# 产物：generated/ 下与模板成对：去掉「-extend」再接「.local.yaml」。无大模型：仅 sed 与按行解析。
#
# 模板选择：环境变量 VERGE_EXTEND_FILE（仅文件名，位于 verge/extend/），默认 airport-rule-split-extend.yaml。
# IP 优先级：命令行参数 > 环境变量 VPS_PUBLIC_IP > override.local 的 [vps] 段首行 IPv4
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXT_REL="${VERGE_EXTEND_FILE:-airport-rule-split-extend.yaml}"
SRC="${ROOT}/extend/${EXT_REL}"
DST_DIR="${ROOT}/generated"

if [[ "${EXT_REL}" != *-extend.yaml ]]; then
  echo "error: VERGE_EXTEND_FILE 须以 -extend.yaml 结尾（例：airport-rule-split-extend.yaml），以便生成 airport-rule-split.local.yaml" >&2
  exit 2
fi
DST="${DST_DIR}/${EXT_REL%-extend.yaml}.local.yaml"
LOCAL_DIR="${DST_DIR}/local"
MERGED_FILE="${LOCAL_DIR}/override.local"

# 主线机场稿：先将 derive/parts/ 合并为 extend（策略层与 Verge/Mihomo 运行时壳分层维护）。
# 应急仅想对手改合并稿做 IP 替换：VERGE_SKIP_COMPOSE=1 bash …/render-local.sh
if [[ "${EXT_REL}" == "airport-rule-split-extend.yaml" ]] && [[ -z "${VERGE_SKIP_COMPOSE:-}" ]]; then
  COMPOSE="${ROOT}/derive/compose.sh"
  if [[ -f "${COMPOSE}" ]] && [[ -f "${ROOT}/derive/parts/20-routing-mihomo.yaml" ]]; then
    bash "${COMPOSE}" -o "${SRC}" || exit 2
  fi
fi

# 自 override.local 的 [vps] 段读取第一个非注释非空行作为 IPv4
read_ip_from_merged() {
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

# 将 [rules] 段写入临时文件（可无此段 → 空文件）
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

snippet_non_comment_nonempty() {
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

# 将片段写入 rules 列表：行首无两空格时补全，避免顶格注释破坏 YAML 层级。
emit_normalized_snippet() {
  local f="$1" sline
  while IFS= read -r sline || [[ -n "${sline}" ]]; do
    if [[ -z "${sline// }" ]]; then
      printf '\n'
      continue
    fi
    if [[ "${sline}" =~ ^[[:space:]]{2} ]]; then
      printf '%s\n' "${sline}"
    elif [[ "${sline}" =~ ^# ]]; then
      printf '  %s\n' "${sline}"
    elif [[ "${sline}" =~ ^- ]]; then
      printf '  %s\n' "${sline}"
    else
      printf '  %s\n' "${sline}"
    fi
  done <"${f}"
}

ip="${1:-${VPS_PUBLIC_IP:-}}"
ip="$(echo "${ip}" | tr -d '[:space:]')"
if [[ -z "${ip}" ]] && [[ -f "${MERGED_FILE}" ]]; then
  ip="$(read_ip_from_merged "${MERGED_FILE}" 2>/dev/null || true)"
  ip="$(echo "${ip}" | tr -d '[:space:]')"
fi

if [[ -z "${ip}" ]]; then
  echo "用法（任选其一）：" >&2
  echo "  bash ${ROOT}/scripts/render-local.sh 你的公网IPv4" >&2
  echo "  VPS_PUBLIC_IP='你的公网IPv4' bash ${ROOT}/scripts/render-local.sh" >&2
  echo "  或复制 verge/generated/local/override.local.example 为 ${MERGED_FILE} 并在 [vps] 下写入 IPv4" >&2
  exit 2
fi

if [[ ! -f "${SRC}" ]]; then
  echo "error: 缺少模板 ${SRC}" >&2
  exit 2
fi

if ! grep -qE 'YOUR_VPS_IP|192\.0\.2\.1' "${SRC}"; then
  echo "error: 模板中未找到可替换的 VPS 占位（YOUR_VPS_IP 或 192.0.2.1）" >&2
  exit 2
fi

mkdir -p "${DST_DIR}" "${LOCAL_DIR}"

# 准备临时文件：本地规则（最高优先级，放在标准规则之前）
RULES_TMP="$(mktemp)"
cleanup_rules_tmp() {
  [[ -n "${RULES_TMP}" && -f "${RULES_TMP}" ]] && rm -f "${RULES_TMP}"
}
trap cleanup_rules_tmp EXIT

if [[ -f "${MERGED_FILE}" ]]; then
  extract_rules_to_file "${MERGED_FILE}" "${RULES_TMP}"
else
  : >"${RULES_TMP}"
fi

# 第一步：替换 IP 占位符
tmp_ip="$(mktemp)"
sed -e "s|YOUR_VPS_IP|${ip}|g" -e "s|192.0.2.1|${ip}|g" "${SRC}" >"${tmp_ip}"

# 第二步：注入本地私有规则（在标准规则片段之前）
tmp_out="$(mktemp)"
injected=0
while IFS= read -r line || [[ -n "${line}" ]]; do
  # 检测规则注入开始标记
  if [[ "${line}" == "  # __VERGE_INJECT_RULES_START__" ]]; then
    echo "${line}"
    # 注入本地私有规则（如果有）
    if snippet_non_comment_nonempty "${RULES_TMP}"; then
      echo "  # === 本地私有规则（最高优先级，在标准规则之前）==="
      emit_normalized_snippet "${RULES_TMP}"
      echo
    fi
    echo "  # === 标准规则片段（由 compose.sh 从 rulesets/_anchors/*.yaml 组装）==="
    injected=1
    continue
  fi

  # 如果在注入标记之间，保留原有的标准规则内容
  if [[ "${injected}" -eq 1 ]]; then
    # 检测结束标记，退出注入状态
    if [[ "${line}" == "  # __VERGE_INJECT_RULES_END__" ]]; then
      echo "${line}"
      injected=0
      continue
    fi
    # 保留原有的标准规则内容（从 extend 文件复制）
    printf '%s\n' "${line}"
    continue
  fi

  printf '%s\n' "${line}"
done <"${tmp_ip}" >"${tmp_out}"

rm -f "${tmp_ip}"

# 第三步：添加元信息头
preface="$(mktemp)"
GEN_TS="$(date '+%Y-%m-%d %H:%M:%S %z')"
{
  printf '# --- 自动生成元信息（下次执行 render-local.sh 会覆盖本段） ---\n'
  printf '# 生成时间：%s\n' "${GEN_TS}"
  printf '# 生成工具：bash verge/scripts/render-local.sh\n'
  printf '# 源模板（extend）：%s\n' "${EXT_REL}"
  printf '# 本机产物（generated）：%s\n' "$(basename "${DST}")"
  printf '# 作者：我\n'
  printf '# ---\n'
  cat "${tmp_out}"
} >"${preface}"
rm -f "${tmp_out}"
mv "${preface}" "${DST}"

echo "${DST}"
