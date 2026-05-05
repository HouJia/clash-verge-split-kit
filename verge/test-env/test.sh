#!/bin/bash
# Mihomo 测试环境测试脚本
# 验证配置语法、API 连通性等

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
BIN_DIR="$SCRIPT_DIR/bin"

CONFIG_FILE="${1:-$CONFIG_DIR/config.yaml}"

echo "=========================================="
echo "Mihomo 测试环境 - 测试脚本"
echo "=========================================="

# 测试 1: 配置文件语法检查
echo ""
echo "[1/5] 检查配置文件语法..."
if "$BIN_DIR/mihomo" -t -f "$CONFIG_FILE" 2>&1; then
    echo "  ✓ 配置文件语法正确"
else
    echo "  ✗ 配置文件语法错误"
    exit 1
fi

# 测试 2: 检查端口占用
echo ""
echo "[2/5] 检查端口占用..."
PORT_7890=$(lsof -ti:7890 2>/dev/null || echo "")
PORT_9090=$(lsof -ti:9090 2>/dev/null || echo "")

if [[ -z "$PORT_7890" ]]; then
    echo "  ✓ 端口 7890 空闲"
else
    echo "  ⚠ 端口 7890 被占用 (PID: $PORT_7890)"
fi

if [[ -z "$PORT_9090" ]]; then
    echo "  ✓ 端口 9090 空闲"
else
    echo "  ⚠ 端口 9090 被占用 (PID: $PORT_9090)"
fi

# 测试 3: 检查 mihomo 版本
echo ""
echo "[3/5] 检查 mihomo 版本..."
VERSION=$("$BIN_DIR/mihomo" -v 2>&1 | head -1)
echo "  $VERSION"

# 测试 4: 检查 geo 数据库
echo ""
echo "[4/5] 检查地理数据库..."
GEO_DIR="$SCRIPT_DIR"
if [[ -f "$GEO_DIR/geoip.dat" ]]; then
    echo "  ✓ geoip.dat 存在"
else
    echo "  ℹ geoip.dat 将在首次启动时自动下载"
fi
if [[ -f "$GEO_DIR/geosite.dat" ]]; then
    echo "  ✓ geosite.dat 存在"
else
    echo "  ℹ geosite.dat 将在首次启动时自动下载"
fi

# 测试 5: 配置文件内容预览
echo ""
echo "[5/5] 配置文件概览..."
echo "  配置文件: $CONFIG_FILE"
echo "  端口: 7890 (mixed-port)"
echo "  控制面板: 127.0.0.1:9090"
echo "  Secret: test-env"
echo "  Log Level: debug"

echo ""
echo "=========================================="
echo "测试完成！"
echo ""
echo "启动命令:"
echo "  ./start.sh"
echo ""
echo "启动后测试代理:"
echo "  curl -x http://127.0.0.1:7890 https://ipinfo.io"
echo ""
echo "查看控制面板:"
echo "  浏览器打开 http://127.0.0.1:9090"
echo "  Secret: test-env"
echo ""
echo "或 yacd 面板:"
echo "  docker run -p 1234:80 -e BACKEND_URL=http://127.0.0.1:9090 haishanh/yacd"
echo "=========================================="
