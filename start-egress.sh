#!/bin/bash
# 快捷启动出口 IP 检测服务（包装脚本）
exec "$(dirname "$0")/hjs-egress-ip-cli/start.sh" "$@"
