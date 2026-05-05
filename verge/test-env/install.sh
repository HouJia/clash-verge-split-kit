#!/bin/bash
# Mihomo 安装脚本
# 自动检测架构并下载对应版本的 mihomo

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"

# 创建 bin 目录
mkdir -p "$BIN_DIR"

# 检测系统和架构
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# 确定下载的架构后缀
case "$ARCH" in
    x86_64)
        ARCH_SUFFIX="amd64"
        ;;
    arm64|aarch64)
        ARCH_SUFFIX="arm64"
        ;;
    *)
        echo "不支持的架构: $ARCH"
        exit 1
        ;;
esac

# 确定系统后缀
case "$OS" in
    darwin)
        OS_SUFFIX="darwin"
        ;;
    linux)
        OS_SUFFIX="linux"
        ;;
    *)
        echo "不支持的操作系统: $OS"
        exit 1
        ;;
esac

# mihomo 版本
VERSION="v1.19.24"
FILENAME="mihomo-${OS_SUFFIX}-${ARCH_SUFFIX}-${VERSION}"
URL="https://github.com/MetaCubeX/mihomo/releases/download/${VERSION}/${FILENAME}.gz"

echo "=========================================="
echo "安装 Mihomo ${VERSION}"
echo "系统: ${OS} (${ARCH})"
echo "架构后缀: ${ARCH_SUFFIX}"
echo "下载地址: ${URL}"
echo "=========================================="

# 下载
echo "正在下载..."
cd "$BIN_DIR"
if command -v curl &> /dev/null; then
    curl -sL "$URL" -o mihomo.gz
elif command -v wget &> /dev/null; then
    wget -q "$URL" -O mihomo.gz
else
    echo "错误: 需要 curl 或 wget 来下载"
    exit 1
fi

# 解压
echo "正在解压..."
gunzip -f mihomo.gz

# 设置权限
chmod +x mihomo

# 清理
rm -f mihomo.gz

# 验证
echo "验证安装..."
"$BIN_DIR/mihomo" -v

echo ""
echo "=========================================="
echo "安装完成!"
echo "二进制位置: $BIN_DIR/mihomo"
echo ""
echo "使用方法:"
echo "  ./start.sh          # 启动测试环境"
echo "  ./test.sh           # 运行功能测试"
echo "=========================================="
