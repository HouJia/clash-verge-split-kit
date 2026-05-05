# 操作手册：3x-ui 网页面板 + VLESS Reality（Netlify 2026 篇）

## 文档信息

| 项目 | 说明 |
|------|------|
| 依据网页 | https://timely-vacherin-fcf11a.netlify.app |
| 本地原文（繁体） | `sources/netlify-vpn-2026-original.md` |
| 配套演示 | `ppt-netlify/index.html` |

## 合规与风险

- 请遵守**所在地法律法规**及云服务商 acceptable use policy；本文仅整理公开网页中的操作步骤。
- `root` 密码、面板账号、`vless://` 链接属于高敏感信息，勿公开传播。
- 一键脚本来自第三方 GitHub 仓库，执行前请自行核对仓库维护者与校验方式。

## 适用环境

- 已购买境外 **VPS**，镜像为 **Ubuntu 22.04 LTS 或 24.04 LTS**（网页要求）。
- 本机浏览器可访问 **VPS 公网 IP**；本机终端可 **SSH** 登录。
- 预计连续操作约 **30 分钟**（网页说明）。

---

## 阶段 0：准备（无命令）

按网页「必要清单」准备：

- 境外可支付的信用卡或等价代充渠道；电子邮箱；Windows 10+ 或 macOS 10.14+ 电脑（或手机用于后续客户端）。
- 网页提示：若无境外卡/邮箱，可通过电商平台购买礼品卡或邮箱成品号——**存在账号找回与合规风险**，仅作技术文档转述，不作推荐。

---

## 阶段 A：创建 VPS（控制台操作）

### A1. 选择服务商与区域

网页列举 DigitalOcean、Linode、Vultr、搬瓦工、Oracle Cloud、RackNerd/Hostinger 等。**网页特别提醒**：中国大陆用户尽量**避开 Vultr 日本东京**；可优先考虑美西、新加坡、**日本大阪**等；若 IP 被墙可在控制台**重建**实例换 IP。

### A2. 创建实例参数（必须与网页表格一致）

| 选项 | 选择 |
|------|------|
| 系统镜像 | **Ubuntu 22.04 LTS** 或 **Ubuntu 24.04 LTS** |
| 规格 | 约 **$5–$6/月**（网页示例：1 vCPU，**1GB RAM**） |
| 认证方式 | **Password**，设置强密码（大小写+数字） |

### A3. 记录信息

在控制台复制并保存：

- **公网 IPv4**（如 `203.0.113.10`）
- **root 密码**（或你设置的密码）

**本阶段无固定 CLI**（各厂商控制台不同）。

---

## 阶段 B：SSH 登录

### B1. Windows 10 / 11

1. `Win + R` → 输入 `cmd` → 回车。  
2. 执行（将 IP 换成你的 VPS 地址）：

```bash
ssh root@你的服务器IP
```

3. 首次连接若询问 `Are you sure you want to continue connecting`，输入：

```text
yes
```

4. 在 `password:` 后粘贴 **root 密码**（**不回显**为正常现象）→ 回车。

### B2. macOS

1. `Command + 空格` → 搜索「终端」→ 打开 **Terminal**。  
2. 执行与 Windows 相同的命令：

```bash
ssh root@你的服务器IP
```

### B3. 登录成功标志

提示符类似：

```text
root@hostname:~#
```

后续**阶段 C、D** 的命令均在已登录的 SSH 窗口中执行。

---

## 阶段 C：安装 3x-ui 面板

### C1. 一键安装（网页给定命令）

在 `root@...#` 下执行：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
```

**说明**：

- 依赖 `curl` 拉取远程脚本；若提示 `curl: not found`，可先执行：

```bash
apt update -y
apt install curl -y
```

然后再执行 C1 主命令。（网页未写 `apt update`，融合版建议先做系统更新，见《操作指南手册-融合版》。）

### C2. 安装过程中的交互（按网页描述）

当脚本询问：

1. `是否设置面板账户密码端口? [y/n]:` → 输入 **`y`** 回车。  
2. `请设置您的账户名:` → 例如 **`admin`**。  
3. `请设置您的密码:` → 自行设置强密码并**离线保存**。  
4. `请设置面板访问端口:` → **10000–65000** 间任选，例如 **`23456`**。

安装成功时，终端应出现绿色提示 **x-ui 面板启动成功**（以实际脚本输出为准）。

### C3. 放行面板端口（云防火墙）

若浏览器无法打开面板，登录 **VPS 供应商控制台** → **Firewall / Security Group** → 为 **TCP** 放行你在 C2 中设置的**面板端口**（如 `23456`）。网页亦提示可临时放行所需 TCP 端口（最小权限原则下建议只放行必要端口）。

**可选（VPS 本机 ufw，若已启用）**示例：

```bash
ufw allow 23456/tcp
ufw reload
```

将 `23456` 换成你的面板端口；若未安装或未启用 `ufw` 可跳过。

---

## 阶段 D：浏览器配置 Reality 入站

### D1. 打开面板

在浏览器地址栏输入（示例）：

```text
http://你的服务器IP:你的面板端口
```

例如：`http://203.0.113.10:23456`  
使用 C2 中设置的**用户名与密码**登录。

### D2. 新建 Inbound（网页表格）

在面板中进入 **Inbounds（入站）** → **Add Inbound**，按网页要求填写：

| 字段 | 值 |
|------|-----|
| Remark | 任意，如 `MyReality` |
| Protocol | **vless** |
| Port | **443** |
| Reality | **开启** |
| Dest | `www.microsoft.com:443` |
| SNI (Server Names) | `www.microsoft.com` |
| Keys | 使用 **Get New Cert** 生成密钥对 |

保存 **Add**。

### D3. 导出 `vless://`

在入站列表中，对该节点使用**二维码/分享/复制**，得到以 `vless://` 开头的分享链接，**加密备份**。

---

## 阶段 E：客户端（按网页）

### E1. Windows

- **v2rayN**：自 GitHub 下载 `v2rayN-Core.zip`，解压运行；`Ctrl + V` 从剪贴板导入；选中节点回车测延迟；托盘图标右键 → **系统代理** → **自动配置系统代理**。  
- **Clash Verge Rev**：GitHub 安装后，「代理」→「新建」→「从剪贴板导入」。

仓库路径以官方 Releases 为准（网页未写死版本号）：

- `https://github.com/2dust/v2rayN/releases`  
- 自行搜索 Clash Verge Rev 官方仓库

### E2. Android

安装 **v2rayNG**（Google Play 或 GitHub Releases）。`+` → **从剪贴板导入** 或扫面板二维码 → 点击连接按钮。

### E3. iOS

使用**美区** Apple ID 购买 **Shadowrocket**；复制 `vless://` 打开 App 按提示**添加**，开启连接开关并授权 VPN。

---

## 阶段 F：验证与排错

### F1. 验证出口 IP

浏览器访问：

```text
https://whatismyipaddress.com
```

若显示的公网 IP **等于你的 VPS IP**，说明流量经隧道出口（网页判据）。

### F2. 网页给出的三类问题

| 现象 | 处理 |
|------|------|
| 客户端 `certificate has expired` | 校准本机时间，与标准时间误差建议 **&lt; 1 分钟** |
| 数日後斷聯 | 登录面板，尝试将 **SNI/Dest** 改为与**同云厂商**官网域名（网页举例 Oracle 用 `www.oracle.com`） |
| 面板网页打不开 | 检查云厂商**安全组/防火墙**是否放行面板端口 |

---

## 快速命令清单（VPS 内）

```bash
# 可选：先更新系统（网页未强调，融合版推荐）
apt update -y && apt upgrade -y

# 若无 curl
apt install curl -y

# 安装 3x-ui（网页核心命令）
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
```

本机 SSH：

```bash
ssh root@你的服务器IP
```

---

## 本地文件

| 文件 | 用途 |
|------|------|
| `sources/netlify-vpn-2026-original.md` | 网页原文存档 |
| `操作指南手册-融合版.md` | 与 Issue #94 路线合并后的总册 |
| `冲突与差异报告.md` | 两来源冲突对照 |
