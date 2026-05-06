#!/usr/bin/env bash
# 将 rulesets/_anchors/*.yaml 片段同步到 20-routing-mihomo.yaml 的锚点定义区
# 用途：修改片段文件后，运行此脚本更新骨架文件中的锚点内容
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANCHORS_DIR="${ROOT}/rulesets/_anchors"
ROUTING_FILE="${ROOT}/derive/parts/20-routing-mihomo.yaml"

# 检查依赖
if [[ ! -d "${ANCHORS_DIR}" ]]; then
  echo "error: 片段目录不存在 ${ANCHORS_DIR}" >&2
  exit 2
fi

if [[ ! -f "${ROUTING_FILE}" ]]; then
  echo "error: 骨架文件不存在 ${ROUTING_FILE}" >&2
  exit 2
fi

# 验证片段文件列表
fragments=(
  "00-private.yaml:rules-private"
  "10-ads.yaml:rules-ads"
  "20-cursor.yaml:rules-cursor"
  "30-ai.yaml:rules-ai"
  "35-messaging.yaml:rules-messaging"
  "40-fcm.yaml:rules-fcm"
  "45-streaming.yaml:rules-streaming"
  "50-dev.yaml:rules-dev"
  "55-scholar.yaml:rules-scholar"
  "60-tech-giants.yaml:rules-tech-giants"
  "65-gaming.yaml:rules-gaming"
  "70-domestic.yaml:rules-domestic"
  "80-geo.yaml:rules-geo"
)

# 生成新的锚点定义内容
generate_anchor() {
  local file="$1"
  local anchor_name="$2"
  local filepath="${ANCHORS_DIR}/${file}"

  if [[ ! -f "${filepath}" ]]; then
    echo "warning: 片段文件不存在 ${file}" >&2
    return
  fi

  # 输出锚点定义（保留片段文件中的注释，添加缩进）
  echo "# --- ${file%.yaml} ---"
  echo "_${anchor_name}: &${anchor_name}"
  while IFS= read -r line || [[ -n "${line}" ]]; do
    # 跳过空行和以 rules: 开头的行
    [[ -z "${line}" ]] && continue
    [[ "${line}" == "rules:" ]] && continue
    # 添加缩进（4个空格）
    echo "  ${line}"
  done < "${filepath}"
  echo
}

# 创建临时文件存储新的锚点区
tmp_anchors="$(mktemp)"
trap 'rm -f "${tmp_anchors}"' EXIT

# 生成所有锚点定义
echo "# =============================================================================" >> "${tmp_anchors}"
echo "# 规则片段锚点定义区（由 sync-fragments.sh 自动生成，请勿手动编辑）" >> "${tmp_anchors}"
echo "# 源片段：rulesets/_anchors/*.yaml" >> "${tmp_anchors}"
echo "# =============================================================================" >> "${tmp_anchors}"
echo >> "${tmp_anchors}"

for entry in "${fragments[@]}"; do
  file="${entry%%:*}"
  anchor="${entry##*:}"
  generate_anchor "${file}" "${anchor}" >> "${tmp_anchors}"
done

# 读取骨架文件，替换锚点区内容
tmp_output="$(mktemp)"
trap 'rm -f "${tmp_output}" "${tmp_anchors}"' EXIT

in_anchor_section=0
anchor_section_start=0

while IFS= read -r line || [[ -n "${line}" ]]; do
  # 检测锚点区开始标记
  if [[ "${line}" == "# =============================================================================" ]] && \
     [[ "${prev_line}" == "# <<< rulebase:providers" ]] 2>/dev/null; then
    echo "${line}" >> "${tmp_output}"
    anchor_section_start=1
    in_anchor_section=1
    continue
  fi

  # 如果在锚点区内，检测结束标记（rules: 或 主规则列表开始）
  if [[ "${in_anchor_section}" -eq 1 ]]; then
    if [[ "${line}" == "# =============================================================================" ]] && \
       [[ "${prev_line}" == "_rules-geo: &rules-geo"* ]] 2>/dev/null; then
      # 这是锚点区内部的锚点定义标记，不是结束
      echo "${line}" >> "${tmp_output}"
      continue
    fi
    if [[ "${line}" == "# 主规则列表"* ]] || [[ "${line}" == "rules:" ]]; then
      # 锚点区结束，注入新的锚点内容
      cat "${tmp_anchors}" >> "${tmp_output}"
      in_anchor_section=0
      echo >> "${tmp_output}"
      echo "# =============================================================================" >> "${tmp_output}"
      echo "# 主规则列表（通过别名引用锚点，保持命中顺序）" >> "${tmp_output}"
      echo "# =============================================================================" >> "${tmp_output}"
      continue
    fi
    # 跳过旧的锚点区内容
    continue
  fi

  echo "${line}" >> "${tmp_output}"
  prev_line="${line}"
done < "${ROUTING_FILE}"

# 原子替换
mv "${tmp_output}" "${ROUTING_FILE}"

echo "锚点同步完成：${ROUTING_FILE}"
echo "片段源：${ANCHORS_DIR}"
