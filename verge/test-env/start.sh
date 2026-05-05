#!/bin/bash
# Mihomo 测试环境启动脚本
# 用法: ./start.sh [config-file]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
LOGS_DIR="$SCRIPT_DIR/logs"
BIN_DIR="$SCRIPT_DIR/bin"

# 默认配置或使用指定配置
CONFIG_FILE="${1:-$CONFIG_DIR/config.yaml}"

# 检查配置是否存在
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "错误: 配置文件不存在: $CONFIG_FILE"
    exit 1
fi

# 检查 mihomo 二进制
if [[ ! -x "$BIN_DIR/mihomo" ]]; then
    echo "错误: mihomo 二进制不存在或不可执行: $BIN_DIR/mihomo"
    echo "请运行 install.sh 安装 mihomo"
    exit 1
fi

# 创建日志目录
mkdir -p "$LOGS_DIR"

# 日志文件
LOG_FILE="$LOGS_DIR/mihomo-$(date +%Y%m%d-%H%M%S).log"

echo "=========================================="
echo "Mihomo 测试环境启动"
echo "=========================================="
echo "配置文件: $CONFIG_FILE"
echo "日志文件: $LOG_FILE"
echo "混合端口: 7890 (HTTP/SOCKS5 代理)"
echo "控制面板: http://127.0.0.1:9090 (secret: test-env)"
echo "=========================================="
echo ""
echo "按 Ctrl+C 停止"
echo ""

# 启动 mihomo
cd "$SCRIPT_DIR"
exec "$BIN_DIR/mihomo" -f "$CONFIG_FILE" -d "$SCRIPT_DIR" 2>&1 | tee "$LOG_FILE"
