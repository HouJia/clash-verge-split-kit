# 自用分流说明（Verge 扩展）

本仓库 **`verge/`** 提供 **扩展分流策略 YAML**：`dns`、`geodata`、`sniffer`、`proxy-groups`、`rules`，不写节点。你在 Verge 里自行接入节点。

**公开仓库：** 说明与模板可提交；**密钥类敏感信息** 只放在本机，**不得** push 进 Git。

**主路径：** [Clash Verge — Extend](https://www.clashverge.dev/guide/extend.html)：`airport` **主线**的真值源为 **`verge/derive/parts/`**，经 **`verge/derive/compose.sh`** 得到 [`verge/extend/airport-rule-split-extend.yaml`](../../verge/extend/airport-rule-split-extend.yaml)，再 **`bash verge/scripts/render-local.sh`**（或 `VERGE_EXTEND_FILE=…` 选用个人稿）得到 **`verge/generated/*-rule-split.local.yaml`**，粘贴进 **全局扩展配置**。详见 [`verge/derive/README.md`](../../verge/derive/README.md) 与 [`verge/README.md`](../../verge/README.md)。

**换机：** 克隆仓库 → 复制 `verge/generated/local/override.local.ini.example` 为 **`override.local.ini`** 并填写 **`[rules]`**（VPS `IP-CIDR`、面板域名等）→ 运行 `bash verge/derive/scripts/render-local.sh` 得到 `config.local.yaml`。

---

## 1. 分层（概念）

| 层 | 内容 | 本仓库 |
|----|------|--------|
| 分流与解析 / 分组 | `dns`、`geodata`、`sniffer`、`rules`、`proxy-groups` | ✅ 主线：`derive/parts/` 合并 → `extend/airport-rule-split-extend.yaml`；个人稿：`extend/*` |
| 节点 | `proxies` / 订阅 | ❌ 不在此仓库维护 |

---

## 2. Verge 里配置如何叠加（概念）

- **扩展配置**（YAML）按官方 Extend 链路叠加。
- 合并后在 Verge **当前配置（只读）** 核对；**规则（Rule）模式** 下分流才按 `rules` 生效。
- v1.7+ 起 **`prepend-rules` 写在扩展 YAML 里常不生效**；插队请用卡片 **编辑规则** 的前置/追加，或 **扩展脚本**（见 [自定义脚本](https://www.clashverge.dev/guide/script.html)）。

---

## 3. 排障（速查）

| 现象 | 方向 |
|------|------|
| 改扩展后规则没变 | 是否已保存并重载 |
| 国内仍走代理 | `mode` 是否 `rule`；`dns` / `sniffer` / `geodata` 是否进入运行时配置 |
| 节点消失 | 扩展是否错误整段覆盖了 `proxies`（本仓库模板不含 `proxies`） |

---

## 4. 公开仓库要注意啥？

- **可进 Git：** 文档、`verge/extend/*-rule-split-extend.yaml`（仅含占位 IP 的模板）。
- **勿进 Git：** `*.local.yaml`（任意路径）、`verge/generated/local/override.local.ini`、订阅、`uuid`、密码等；**`verge/generated/local/*.example`** 可提交（见根 `.gitignore`）。

---

## 5. 分流（Clash）和 `outbound-ip` 有啥关系？

- **Clash / Verge：** 决定流量走哪条代理或直连。
- **`outbound-ip`：** 核对「访问某站点时对方看到的出口 IP」。

具体复查步骤见 **[verification-playbook.md](verification-playbook.md)**。

---

**免责声明：** Clash Verge 菜单与文案随版本变化；请以 **你本机已安装的客户端 / mihomo** 为准。
