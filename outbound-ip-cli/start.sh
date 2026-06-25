#!/bin/bash
# 启动出口 IP 检测服务

cd "$(dirname "$0")" || exit 1

if [ ! -f ".venv/bin/hjs-egress-ip" ]; then
    echo "错误：未找到虚拟环境，请先安装项目"
    echo "运行：pip install -e ."
    exit 1
fi

echo "🚀 启动出口 IP 检测服务..."
./.venv/bin/hjs-egress-ip serve "$@"
