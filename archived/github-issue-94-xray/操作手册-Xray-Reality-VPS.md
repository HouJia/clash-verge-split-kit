# 操作手册：Issue #94 教程步骤化（VPS + Xray Reality 一键脚本）

## 文档信息

| 项目 | 说明 |
|------|------|
| 依据 | [MyMaskKing.github.io Issue #94](https://github.com/MyMaskKing/MyMaskKing.github.io/issues/94) |
| 本地原文 | `issue-94-original.md` |
| 演示稿 | `ppt/index.html`（guizang 杂志风单文件） |

## 合规与风险说明

- 请遵守**所在地法律法规**及服务商 acceptable use policy；本文仅整理公开 Issue 中的技术步骤，**不构成**对任何用途的背书。
- VPS 公网 IP 可能被封锁或变更；脚本来源为第三方仓库，执行前请自行评估可信度与版本。
- 服务器 `root` 密码与 `vless://` 链接属于敏感信息，勿在公开渠道传播。

## 适用环境假设

- 已租用境外 **VPS**，系统为 **Debian / Ubuntu**（Issue 中以 `apt` 为例）。
- 本机可安装 **SSH 客户端**（Windows 10+ 自带 OpenSSH，macOS / Linux 自带终端）。
- 可访问 **GitHub** 以下载一键脚本（若网络受限需自行解决获取脚本的方式）。

---

## 阶段 A：租用并创建 VPS（控制台操作，无统一 CLI）

**目的**：获得公网 `IP`、`root` 用户与密码（或密钥）。

**操作说明**（与 Issue 中 Vultr 示例一致，其他厂商界面不同但要素相同）：

1. 在供应商网站注册并充值。
2. 创建实例：**Cloud Compute** 或等价产品；区域选延迟较低的节点（如东京、新加坡、洛杉矶等）。
3. **系统镜像**：选 **Ubuntu 22.04 LTS x64** 或 **Debian 11 x64**（Issue 推荐）。
4. **规格**：最低档（如 1 vCPU / 512MB）通常足够代理用途。
5. 可选勾选 **IPv6**（Issue 建议）。
6. 部署完成后，在控制台记录：**IPv4 地址**、**用户名**（多为 `root`）、**密码**。

**本阶段无固定终端命令**；若供应商提供 API，可自行用 CLI 创建，不在 Issue 原文范围内。

---

## 阶段 B：SSH 登录 VPS

**目的**：进入服务器 shell，后续命令均在 VPS 上执行。

### B1. 打开终端

- **Windows**：`Win + R` → 输入 `cmd` 或 `powershell` → 回车；或打开 Windows Terminal。
- **macOS**：打开「终端」。
- **Linux**：打开默认终端模拟器。

### B2. 首次连接

将下面命令中的 `你的服务器IP` 换成控制台中的公网 IP：

```bash
ssh root@你的服务器IP
```

示例（IP 为虚构示例）：

```bash
ssh root@192.0.2.1
```

### B3. 主机指纹确认

若提示 `Are you sure you want to continue connecting`，输入：

```text
yes
```

再按回车。

### B4. 输入密码

在 `password:` 提示后粘贴或键入 **root 密码**；**终端不会回显**星号，属正常现象，输入完直接回车。

### B5. 登录成功判定

提示符类似：

```text
root@hostname:~#
```

表示已登录 VPS，后续 **阶段 C、D** 的命令都在此窗口执行。

---

## 阶段 C：更新系统软件包

**目的**：同步软件索引并升级已安装包，降低依赖问题概率。

**在 VPS 的 SSH 会话中依次执行**：

```bash
apt update -y
```

说明：`apt update` 刷新可用软件列表；`-y` 自动对提示回答「是」（若系统无该参数行为，以实际发行版为准）。

```bash
apt upgrade -y
```

说明：升级已安装软件包；耗时取决于镜像与网络，需等待完成。

> 若提示 `apt: command not found`，可能不是 Debian/Ubuntu 系，需改用对应包管理器（不在 Issue 原文内）。

---

## 阶段 D：一键安装脚本（XrayR 发布脚本）

**目的**：按 Issue 所述通过社区脚本安装并配置 **Xray + Reality（VLESS）**。

### D1. 确认已安装 curl

若未安装，执行：

```bash
apt install curl -y
```

### D2. 下载并执行安装脚本

Issue 原文给出的命令为：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh)
```

**操作说明**：

- 该命令通过 `curl` 拉取远程 `install.sh` 并由当前 shell 解释执行。
- 若 `curl` 访问 GitHub 失败，需排查网络或使用已下载到本地的同名脚本（需自行保证来源完整性与完整性校验）。

### D3. 交互菜单中与 Issue 对齐的要点

脚本为交互式，选项会随版本变化；Issue 建议倾向如下（**以屏幕实际提示为准**）：

- 安装类型：选择安装 **Xray / XrayR** 相关项（Issue 示例为「安装 XrayR」）。
- **Reality**：选择 **启用 / Y**。
- **服务器 IP 或域名**：无域名则**直接回车**使用当前 VPS IP。
- **伪装站点（SNI）**：在列表中任选其一（Issue 示例为 `www.microsoft.com`）。
- **端口**：可使用脚本默认随机端口（直接回车）。
- **BBR**：Issue 建议选 **Y** 以启用拥塞控制优化。
- 其余项：无特殊需求可优先选默认。

### D4. 安装结束后必须保存的输出

终端会打印 **UUID、端口、Reality 公钥、SNI、ShortId（若有）** 以及 **`vless://` 分享链接**。请：

1. 全选复制到加密笔记或离线备份；
2. **不要**发到公开聊天或截图外泄。

若提供二维码 URL，仅用于受信任设备扫描导入。

---

## 阶段 E：本机安装客户端并导入节点

**目的**：在 Windows / macOS / Android / iOS 上使用图形客户端连接 VPS。

以下链接与名称来自 **Issue 原文**（版本号随时间变化，请以各仓库 **Releases** 最新资产为准）。

### E1. Windows（NekoRay 或 V2rayN）

1. 下载（Releases 页面选择 Windows x64 zip）  
   - NekoRay：`https://github.com/MatsuriDayo/NekoRay/releases`  
   - v2rayN：`https://github.com/2dust/v2rayN/releases`
2. 解压后启动程序。
3. **从剪贴板导入**：复制完整 `vless://` 链接 → NekoRay：`文件` → `从剪贴板导入 URL`；v2rayN：`服务器` → `从剪贴板导入批量URL`。
4. 选中节点并连接（NekoRay 小飞机按钮；v2rayN 托盘图标中设置系统代理）。
5. 浏览器访问 `https://www.google.com` 做连通性自测。

**本阶段无必用 shell 命令**（除非使用便携版附带 CLI，略）。

### E2. Android（NekoBox 或 Clash for Android）

1. 下载 APK：  
   - `https://github.com/MatsuriDayo/NekoBoxForAndroid/releases`  
   - `https://github.com/Kr328/ClashForAndroid/releases`
2. NekoBox：`Profile` → `+` → `Import URI` → 粘贴 `vless://`。  
   Clash：`配置` → `+` → `URL` → 粘贴 `vless://`。
3. 允许建立 VPN，启动后浏览器自测。

### E3. iOS（Shadowrocket / Stash）

1. 使用 **非中国大陆区** Apple ID 在 App Store 购买/下载客户端。
2. 通过「扫描二维码」或按应用内指引添加 `vless://`。
3. 打开连接开关后自测。

### E4. macOS（NekoRay 或 ClashX Pro）

1. 下载：  
   - NekoRay：`https://github.com/MatsuriDayo/NekoRay/releases`（macOS zip）  
   - ClashX Pro：`https://github.com/ClashX-Pro/ClashX-Pro/releases`（dmg）
2. 导入方式与 Windows 类似；在菜单栏启用系统代理并选择节点。

---

## 阶段 F：可选优化与维护

### F1. 补装 BBR（若安装时未启用）

在 **VPS SSH** 中执行（与 Issue 一致）：

```bash
wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh && chmod +x bbr.sh && ./bbr.sh
```

按脚本提示操作；**重启后**需重新 SSH 登录。若内核不支持，脚本会提示失败原因。

### F2. 日常系统更新

```bash
apt update -y && apt upgrade -y
```

### F3. 更新 Xray 核心

Issue 建议：**再次运行**阶段 D 中的安装脚本，由脚本检测并更新（以脚本当前行为为准）。

### F4. 故障排查（摘自 Issue 要点）

| 现象 | 可执行检查 |
|------|------------|
| 无法连接 | `ping` VPS IP；用 `https://ping.pe/` 看多地是否可达；核对 UUID/端口/公钥/SNI；检查本机客户端是否选对出站模式 |
| 速度慢 | 确认 BBR 是否生效；尝试更换 VPS 区域；检查本地宽带与国际出口 |
| IP 被封锁 | 更换 IP 或新开实例；无通用「命令行解锁」手段 |

---

## 快速命令清单（复制区）

**仅 VPS 上执行：**

```bash
apt update -y && apt upgrade -y
apt install curl -y
bash <(curl -Ls https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh)
```

**可选 BBR：**

```bash
wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh && chmod +x bbr.sh && ./bbr.sh
```

**本机 SSH：**

```bash
ssh root@<你的VPS_IP>
```

---

## 本地关联文件

| 文件 | 用途 |
|------|------|
| `issue-94-original.md` | Issue 正文存档 |
| `ppt/index.html` | 步骤纲要演示（浏览器打开，方向键翻页） |
| `ppt/assets/motion.min.js` | 动效离线兜底 |

预览 PPT（macOS，先在包含 `ppt` 的目录下执行）：

```bash
cd github-issue-94-xray
open ppt/index.html
```

若当前工作目录不同，请把 `cd` 换成该文件夹的实际路径。
