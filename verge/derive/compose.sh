#!/usr/bin/env bash
# 将 parts/ 合并为单份 Mihomo/Verge 扩展 YAML（ stdout 或 -o 路径）。
# 主线机场稿：真值源在 parts/；extend/airport-rule-split-extend.yaml 为合并产物。
# 本脚本同时将 rulesets/_anchors/*.yaml 片段注入到 rules 部分。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARTS="${ROOT}/parts"
ANCHORS_DIR="${ROOT}/../rulesets/_anchors"
OUT_PATH=""

usage() {
  echo "用法: $0 [-o verge/extend/airport-rule-split-extend.yaml]" >&2
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

req=(
  "${PARTS}/airport-dochead.txt"
  "${PARTS}/10-runtime-verge-mihomo.yaml"
  "${PARTS}/20-routing-mihomo.yaml"
)
for f in "${req[@]}"; do
  [[ -f "$f" ]] || { echo "error: 缺少 ${f}" >&2; exit 2; }
done

# 读取片段文件并输出规则列表（带缩进）
emit_anchor_rules() {
  local fragment file
  # 片段文件列表（按优先级顺序）
  local fragments=(
    "00-private.yaml"
    "10-ads.yaml"
    "20-cursor.yaml"
    "30-ai.yaml"
    "35-messaging.yaml"
    "40-fcm.yaml"
    "45-streaming.yaml"
    "50-dev.yaml"
    "55-scholar.yaml"
    "60-tech-giants.yaml"
    "65-gaming.yaml"
    "70-domestic.yaml"
    "80-geo.yaml"
  )

  for fragment in "${fragments[@]}"; do
    file="${ANCHORS_DIR}/${fragment}"
    if [[ -f "${file}" ]]; then
      # 读取标题和详细说明（前两行注释）
      local title="" desc=""
      local line_num=0
      while IFS= read -r line && [[ ${line_num} -lt 2 ]]; do
        # 去掉开头的 # 和空格
        local clean_line="${line#\# }"
        clean_line="${clean_line#\#}"
        clean_line="${clean_line# }"
        if [[ ${line_num} -eq 0 ]]; then
          title="${clean_line}"
        else
          desc="${clean_line}"
        fi
        ((line_num++))
      done < "${file}"

      # 生成 ================== 格式的详细标题（带编号前缀）
      # 提取编号（如 30）从文件名（30-ai.yaml）
      local fragment_num="${fragment%%-*}"
      if [[ -n "${title}" ]]; then
        # 生成格式：================== 30-🧠 场景 · 境外 AI ==================
        echo "  # ================== ${fragment_num}-${title} =================="
      fi

      # 输出剩余内容（跳过前两行标题注释）
      local skip=0
      while IFS= read -r line || [[ -n "${line}" ]]; do
        ((skip++))
        [[ ${skip} -le 2 ]] && continue
        # 跳过空行，但保留注释作为规则间的说明
        [[ -z "${line}" ]] && continue
        # 输出带缩进的规则（2个空格缩进，保持 YAML 列表格式）
        echo "  ${line}"
      done < "${file}"
      # 每个策略组之间用空行隔开，便于阅读
      echo
    fi
  done
}

# 合并文件并注入片段
emit() {
  local in_rules_section=0
  local injected=0

  while IFS= read -r line || [[ -n "${line}" ]]; do
    # 检测 rules: 开始
    if [[ "${line}" == "rules:" ]]; then
      echo "${line}"
      in_rules_section=1
      continue
    fi

    # 如果在 rules 区内，检测注入标记
    if [[ "${in_rules_section}" -eq 1 ]]; then
      # 检测开始标记
      if [[ "${line}" == "  # __VERGE_INJECT_RULES_START__" ]]; then
        echo "${line}"
        # 本地私有规则锚点说明（由 render-local.sh 从此处注入 override.local 内容）
        echo "  # >>> 本地私有规则注入锚点（由 render-local.sh 从 override.local 注入）"
        echo "  # 作用：放置私有 IP 规则（本机需直连的 IP、机场面板、NAS 等），在标准规则之前最高优先级命中"
        echo "  # 说明：见 verge/generated/local/override.local.example，复制为 override.local 后编辑"
        # 注入片段规则
        echo "  # === 规则片段注入（由 compose.sh 自动组装）==="
        echo "  # 片段源：rulesets/_anchors/*.yaml"
        emit_anchor_rules
        continue
      fi

      # 检测结束标记
      if [[ "${line}" == "  # __VERGE_INJECT_RULES_END__" ]]; then
        echo "${line}"
        in_rules_section=0
        continue
      fi

      # 跳过旧的占位符内容（开始和结束标记之间的所有内容）
      if [[ "${line}" == "  # __VERGE_INJECT_RULES_START__"* ]]; then
        continue
      fi
    fi

    echo "${line}"
  done < "${PARTS}/airport-dochead.txt"

  # 输出运行时壳
  cat "${PARTS}/10-runtime-verge-mihomo.yaml"

  # 输出路由骨架（含片段注入）
  local in_rules=0
  while IFS= read -r line || [[ -n "${line}" ]]; do
    # 检测 rules: 开始
    if [[ "${line}" == "rules:" ]]; then
      echo "${line}"
      in_rules=1
      continue
    fi

    # 如果在 rules 区内
    if [[ "${in_rules}" -eq 1 ]]; then
      # 检测开始标记
      if [[ "${line}" == "  # __VERGE_INJECT_RULES_START__" ]]; then
        echo "${line}"
        # 本地私有规则锚点说明（由 render-local.sh 从此处注入 override.local 内容）
        echo "  # >>> 本地私有规则注入锚点（由 render-local.sh 从 override.local 注入）"
        echo "  # 作用：放置私有 IP 规则（本机需直连的 IP、机场面板、NAS 等），在标准规则之前最高优先级命中"
        echo "  # 说明：见 verge/generated/local/override.local.example，复制为 override.local 后编辑"
        # 注入片段规则
        echo "  # === 规则片段注入（由 compose.sh 自动组装）==="
        echo "  # 片段源：rulesets/_anchors/*.yaml"
        emit_anchor_rules
        continue
      fi

      # 检测结束标记
      if [[ "${line}" == "  # __VERGE_INJECT_RULES_END__" ]]; then
        echo "${line}"
        in_rules=0
        continue
      fi

      # 跳过开始和结束标记之间的占位符内容
      continue
    fi

    echo "${line}"
  done < "${PARTS}/20-routing-mihomo.yaml"
}

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
