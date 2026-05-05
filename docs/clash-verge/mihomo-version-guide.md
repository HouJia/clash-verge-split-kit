# Mihomo 内核版本选择指南

Mihomo（原 Clash Meta）GitHub Releases 页面提供大量预编译版本，初次接触容易困惑。本指南解释各版本区别，帮助你快速选择正确的内核。

> **官方发布页面**: https://github.com/MetaCubeX/mihomo/releases

> **Clash Verge Rev 内核路径** (macOS):  
> `/Applications/Clash Verge.app/Contents/MacOS/verge-mihomo`

---

## 一、版本命名规则拆解

典型文件名：`mihomo-darwin-arm64-v1.19.24.gz`

```
mihomo - {系统}-{架构}-{版本}.gz
  │       │       │       └── 版本号
  │       │       └── CPU 架构
  │       └── 操作系统
  └── 项目名
```

---

## 二、系统选择（第一个字段）

| 系统标识 | 适用平台 | 说明 |
|---------|---------|------|
| **darwin** | macOS | Apple 电脑 |
| **linux** | Linux 发行版 | Ubuntu/Debian/CentOS/Arch 等 |
| **windows** | Windows | Win10/Win11 |
| **android** | 安卓手机/平板 | 需 Root 或配合 APP |
| **freebsd** | FreeBSD 系统 | 服务器/专业用户 |
| **openbsd** | OpenBSD 系统 | 安全导向的服务器 |
| **dragonfly** | DragonFly BSD | BSD 系小众系统 |

**选择建议**：
- macOS 用户 → `darwin`
- 主流 Linux → `linux`
- Windows → `windows`
- 安卓 → `android`

---

## 三、架构选择（第二个字段）

### 3.1 macOS 架构

| 架构标识 | 适用机型 | 如何确认 |
|---------|---------|---------|
| **arm64** | Apple Silicon (M1/M2/M3/M4) | 2020 年后新机 |
| **amd64** | Intel Mac | 2020 年前旧机 |

**终端命令确认**：
```bash
uname -m
# arm64  → 选 arm64
# x86_64 → 选 amd64
```

### 3.2 Linux 架构

| 架构标识 | 说明 |
|---------|------|
| **amd64** | 64 位 x86 处理器（主流 PC/服务器）|
| **amd64-v3** | 支持 x86-64-v3 指令集（较新 CPU）|
| **arm64** | ARM 64 位（树莓派/ARM 服务器）|
| **386** | 32 位 x86（老旧设备）|
| **armv7** | ARM 32 位（老旧嵌入式）|
| **mips** / **mipsle** | MIPS 处理器（路由器）|
| **riscv64** | RISC-V 架构（实验性）|

**终端命令确认**：
```bash
uname -m
# x86_64 → amd64
# aarch64 → arm64
# armv7l → armv7
```

### 3.3 Windows 架构

| 架构标识 | 说明 |
|---------|------|
| **amd64** | 64 位 Windows（绝大多数用户）|
| **386** | 32 位 Windows（老旧系统）|
| **arm64** | ARM 版 Windows（Surface Pro X 等）|

---

## 四、特殊版本后缀解读

### 4.1 架构变体版本

| 后缀 | 说明 | 选择建议 |
|-----|------|---------|
| **-v3** | x86-64-v3 微架构优化 | 2015 年后的 Intel/AMD CPU 可选，性能更好 |
| **compatible** | 兼容旧系统 | 老系统选这个 |
| **cgo** | 使用 CGO 编译 | 某些 DNS 场景需要 |
| **go** | Go 标准库版本 | 一般不需要 |

### 4.2 Windows 专属后缀

| 后缀 | 说明 | 选择建议 |
|-----|------|---------|
| **-wintun** | 集成 WinTun 驱动 | 需要 TUN 模式（透明代理）必选 |
| **-no_wintun** | 不带 WinTun | 不需要 TUN 模式可选 |
| **-siden** | Siden 特定版本 | 特殊设备专用 |

### 4.3 源码版本

| 名称 | 说明 |
|-----|------|
| **Source code (zip)** | 源码压缩包 |
| **Source code (tar.gz)** | 源码 tar 包 |

**普通用户不需要下载源码**。

---

## 五、快速选择决策树

```
你是哪个系统？
├── macOS (darwin)
│   ├── Apple Silicon (M1/M2/M3/M4) → mihomo-darwin-arm64-vX.Y.Z.gz
│   └── Intel Mac → mihomo-darwin-amd64-vX.Y.Z.gz
│
├── Linux (linux)
│   ├── 64 位 PC/服务器
│   │   ├── CPU 较新 (2015年后) → mihomo-linux-amd64-v3-vX.Y.Z.gz
│   │   └── 通用/不确定 → mihomo-linux-amd64-compatible-vX.Y.Z.gz
│   ├── 树莓派/ARM 设备 → mihomo-linux-arm64-vX.Y.Z.gz
│   └── 老旧 32 位 → mihomo-linux-386-vX.Y.Z.gz
│
├── Windows (windows)
│   ├── 64 位 + 需要 TUN 透明代理 → mihomo-windows-amd64-vX.Y.Z.zip
│   ├── 64 位 + 不需要 TUN → mihomo-windows-amd64-no_wintun-vX.Y.Z.zip
│   └── 32 位 → mihomo-windows-386-vX.Y.Z.zip
│
└── Android (android)
    └── 手机/平板 → mihomo-android-arm64-vX.Y.Z.gz
```

---

## 六、本项目推荐的下载链接

### 当前版本：v1.19.24

**macOS Apple Silicon（M 系列芯片）**：
```
https://github.com/MetaCubeX/mihomo/releases/download/v1.19.24/mihomo-darwin-arm64-v1.19.24.gz
```

**macOS Intel**：
```
https://github.com/MetaCubeX/mihomo/releases/download/v1.19.24/mihomo-darwin-amd64-v1.19.24.gz
```

**Linux 64 位（通用兼容版）**：
```
https://github.com/MetaCubeX/mihomo/releases/download/v1.19.24/mihomo-linux-amd64-compatible-v1.19.24.gz
```

**Linux 64 位（v3 优化版）**：
```
https://github.com/MetaCubeX/mihomo/releases/download/v1.19.24/mihomo-linux-amd64-v3-v1.19.24.gz
```

**Windows 64 位（含 WinTUN）**：
```
https://github.com/MetaCubeX/mihomo/releases/download/v1.19.24/mihomo-windows-amd64-v1.19.24.zip
```

---

## 七、Release 页面直达

最新版本：
```
https://github.com/MetaCubeX/mihomo/releases/latest
```

历史版本：
```
https://github.com/MetaCubeX/mihomo/releases
```

---

## 八、常见问题

### Q1: amd64 和 amd64-v3 有什么区别？

**amd64-v3** 针对较新的 CPU 指令集（AVX2、BMI2 等）优化，性能更好。但老旧 CPU 可能无法运行。

如果下载 v3 版本后运行报错（如 `illegal hardware instruction`），换用普通 `amd64` 或 `compatible` 版本。

### Q2: CGO 版本是什么？需要吗？

CGO 版本使用 C 语言绑定编译，某些 DNS 解析场景（如使用系统 DNS）可能需要。

**一般用户不需要**，除非遇到特定 DNS 问题。

### Q3: 如何检查 CPU 是否支持 v3？

**macOS/Linux**：
```bash
# 查看 CPU 特性
sysctl -a | grep machdep.cpu.features  # macOS
cat /proc/cpuinfo | grep flags         # Linux

# 检查 AVX2（v3 的关键特性）
# 如果看到 avx2 在列表中，说明支持 v3
```

### Q4: 下载后如何使用？

1. 解压：
```bash
# .gz 文件
gunzip mihomo-*.gz

# .zip 文件（Windows）
# 使用系统解压或 unzip 命令
```

2. 赋予执行权限（Unix 系统）：
```bash
chmod +x mihomo
```

3. 验证：
```bash
./mihomo -v
```

---

## 九、版本号说明

Mihomo 版本号格式：`v主版本.次版本.修订号`

示例：`v1.19.24`
- **1** - 主版本（重大更新）
- **19** - 次版本（功能更新）
- **3** - 修订号（Bug 修复）

**更新策略**：
- 关注 [GitHub Releases](https://github.com/MetaCubeX/mihomo/releases) 获取更新
- 修订号更新（如 1.19.2 → 1.19.3）通常安全，可直接升级
- 次版本/主版本更新建议查看 Changelog 后再升级

---

## 十、相关链接

- **Mihomo GitHub**: https://github.com/MetaCubeX/mihomo
- **Mihomo 文档**: https://wiki.metacubex.one/
- **Clash Verge Rev**: https://github.com/clash-verge-rev/clash-verge-rev
- **原版 Clash（已停更）**: https://github.com/Dreamacro/clash

---

**最后更新**：2026-05-05
**适用版本**：v1.19.24 及以上
