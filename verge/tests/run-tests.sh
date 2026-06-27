#!/bin/bash
# =============================================================================
# Clash Verge Split Kit - 配置回归测试运行脚本
# =============================================================================
# 用法:
#   ./tests/run-tests.sh           # 运行测试
#   ./tests/run-tests.sh --ci      # CI 模式，失败时返回非零退出码
#   ./tests/run-tests.sh --verbose # 详细输出
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 路径配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERGE_DIR="$(dirname "$SCRIPT_DIR")"
TESTS_DIR="$SCRIPT_DIR"

# 检查 Python3
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}错误: 需要安装 Python 3${NC}"
    exit 1
fi

# 检查 PyYAML
if ! python3 -c "import yaml" 2>/dev/null; then
    echo -e "${YELLOW}警告: 需要安装 PyYAML${NC}"
    echo -e "运行: ${BLUE}pip3 install pyyaml${NC}"
    exit 1
fi

# 检查配置文件是否存在
INI_FILE="$VERGE_DIR/generated/houjia.local-template.ini"
YAML_FILE="$VERGE_DIR/generated/houjia.local-template.yaml"

if [ ! -f "$INI_FILE" ]; then
    echo -e "${RED}错误: INI 配置文件不存在: $INI_FILE${NC}"
    exit 1
fi

if [ ! -f "$YAML_FILE" ]; then
    echo -e "${RED}错误: YAML 配置文件不存在: $YAML_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Clash Verge Split Kit - 配置回归测试${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${BLUE}配置文件:${NC}"
echo "  INI:  $INI_FILE"
echo "  YAML: $YAML_FILE"
echo ""

# 显示文件生成时间
echo -e "${BLUE}文件生成时间:${NC}"
INI_TIME=$(head -10 "$INI_FILE" | grep "生成时间" | sed 's/.*生成时间：//' || echo "未知")
YAML_TIME=$(head -10 "$YAML_FILE" | grep "生成时间" | sed 's/.*生成时间：//' || echo "未知")
echo "  INI:  $INI_TIME"
echo "  YAML: $YAML_TIME"
echo ""

# 运行测试
echo -e "${BLUE}开始运行测试...${NC}"
echo ""

if [ "$1" == "--verbose" ]; then
    python3 "$TESTS_DIR/test_config.py"
else
    # 简化输出模式
    python3 "$TESTS_DIR/test_config.py" 2>&1 | grep -E "(^test_|OK|FAILED|ERROR|测试|✅|❌|总共)"
fi

TEST_RESULT=${PIPESTATUS[0]}

echo ""

if [ $TEST_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ 所有测试通过！配置验证成功。${NC}"
else
    echo -e "${RED}❌ 测试未通过，请检查配置问题。${NC}"
fi

# 额外统计信息
echo ""
echo -e "${BLUE}配置统计:${NC}"
echo -n "  代理组数量: "
grep -c "^  - name:" "$YAML_FILE" || echo "0"
echo -n "  规则数量: "
grep -c "^- " "$YAML_FILE" 2>/dev/null || echo "0"

exit $TEST_RESULT
