# Mihomo 测试环境

为当前项目搭建的本地 mihomo 测试环境，用于验证分流规则配置。

## 当前使用的 Mihomo 版本

| 项目 | 信息 |
|------|------|
| **版本** | v1.19.24 |
| **系统** | Darwin (macOS) |
| **架构** | arm64 (Apple Silicon) |
| **下载链接** | https://github.com/MetaCubeX/mihomo/releases/download/v1.19.24/mihomo-darwin-arm64-v1.19.24.gz |

### 其他常用下载链接

| 平台 | 下载链接 |
|------|---------|
| macOS Intel | `https://github.com/MetaCubeX/mihomo/releases/download/v1.19.24/mihomo-darwin-amd64-v1.19.24.gz` |
| Linux 64位 (通用) | `https://github.com/MetaCubeX/mihomo/releases/download/v1.19.24/mihomo-linux-amd64-compatible-v1.19.24.gz` |
| Linux 64位 (v3优化) | `https://github.com/MetaCubeX/mihomo/releases/download/v1.19.24/mihomo-linux-amd64-v3-v1.19.24.gz` |
| Windows 64位 | `https://github.com/MetaCubeX/mihomo/releases/download/v1.19.24/mihomo-windows-amd64-v1.19.24.zip` |

> 版本选择指南见 [`docs/clash-verge/mihomo-version-guide.md`](../../docs/clash-verge/mihomo-version-guide.md)

## 特点

- **独立环境**: 不依赖系统安装的 mihomo/Clash
- **DIRECT 模式**: 测试分流规则，不走真实代理
- **完整功能**: 支持 DNS、sniffer、geo 数据库、外部控制面板
- **调试友好**: debug 级别日志，方便排查规则匹配

## 目录结构

```
verge/test-env/
├── bin/                    # mihomo 二进制
├── config/                 # 配置文件
│   └── config.yaml        # 主配置
├── logs/                   # 运行日志
├── ruleset/               # 规则集缓存
├── start.sh               # 启动脚本
├── install.sh             # 安装脚本
├── test.sh                # 测试脚本
└── README.md              # 本文件
```

## 快速开始

### 1. 安装 mihomo（如未安装）

```bash
cd verge/test-env
./install.sh
```

### 2. 运行测试

```bash
./test.sh
```

### 3. 启动服务

```bash
./start.sh
```

## 配置说明

| 项目 | 值 | 说明 |
|------|-----|------|
| mixed-port | 7890 | HTTP/SOCKS5 代理端口 |
| external-controller | 127.0.0.1:9090 | REST API 控制面板 |
| secret | test-env | 控制面板认证密码 |
| log-level | debug | 日志详细程度 |
| mode | rule | 规则模式 |

## 使用方法

### 作为系统代理

启动后，将系统代理设置为:
- HTTP 代理: `http://127.0.0.1:7890`
- SOCKS5 代理: `socks5://127.0.0.1:7890`

### 命令行测试

```bash
# 测试代理连通性
curl -x http://127.0.0.1:7890 https://ipinfo.io

# 查看分流日志（另一个终端）
tail -f verge/test-env/logs/mihomo-*.log
```

### 控制面板

浏览器访问: http://127.0.0.1:9090

或使用 yacd 面板:
```bash
docker run -p 1234:80 haishanh/yacd
# 然后设置后端地址: http://127.0.0.1:9090
```

## 自定义配置

编辑 `config/config.yaml` 来测试不同的分流规则。

测试项目配置:
- 分流规则匹配
- DNS 解析行为
- Geo 数据库下载
- 规则集加载

## 与项目配置的关系

本项目已有 `verge/derive/parts/` 中的分层配置:
- `10-runtime-verge-mihomo.yaml` - 运行时配置
- `20-routing-mihomo.yaml` - 代理组和路由规则

测试环境的 `config.yaml` 是一个简化版本，专注于规则测试，可直接编辑验证想法。

## 故障排查

### 端口被占用

```bash
# 查找占用 7890 端口的进程
lsof -ti:7890

# 杀掉进程
kill $(lsof -ti:7890)
```

### 日志查看

```bash
ls -la verge/test-env/logs/
tail -f verge/test-env/logs/mihomo-*.log
```

### 配置语法检查

```bash
cd verge/test-env
./bin/mihomo -t -f config/config.yaml
```
