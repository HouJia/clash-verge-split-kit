#!/bin/bash
# 快捷启动出站 IP 审计服务（包装脚本）
exec "$(dirname "$0")/outbound-ip-cli/start.sh" "$@"
