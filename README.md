# airport

公开仓库：**不放**真实订阅链接与节点密钥；规则与说明可提交，密钥只放本机。

## 仓库结构

| 路径 | 内容 |
|------|------|
| [`verge/`](verge/) | Clash Verge：**`derive/parts/`**（主线分层）→ **`scripts/derive/compose.sh`** → **`template/airport-rule-split-extend.yaml`** → **`scripts/render-local.sh`** → `generated/*-rule-split.local.yaml`。设计原则见 [`docs/clash-verge/RULEBASE-PROGRAM.md`](docs/clash-verge/RULEBASE-PROGRAM.md)。 |
| [`docs/clash-verge/`](docs/clash-verge/) | 自用说明与里程碑白话 FAQ。 |
| [`.planning/`](.planning/) | 路线图、需求、阶段上下文（GSD）。 |

快速分流：**机场主线**改 [`verge/derive/parts/`](verge/derive/parts/) 后按 [`verge/README.md`](verge/README.md) 执行 `compose` / `render-local.sh`；**个人稿**直接维护 `verge/template/*-rule-split-extend.yaml`。可配合 **`verge/generated/local/override.local.ini`**（INI 格式）与 Hooks。

## v1.1 文档与工具链

### 文档导航

| 文档 | 说明 |
|------|------|
| [`docs/clash-verge/README.md`](docs/clash-verge/README.md) | 分流说明目录入口 |
| [`docs/clash-verge/local-split-vps.md`](docs/clash-verge/local-split-vps.md) | 自用分流与工具链说明 |
| [`docs/clash-verge/verification-playbook.md`](docs/clash-verge/verification-playbook.md) | 可重复验证与审计联动 |
| [`hjs-egress-ip-cli/README.md`](hjs-egress-ip-cli/README.md) | CLI 与审计 UI；**pipx** 与可复制的安装命令**仅在此文** |
| [`verge/README.md`](verge/README.md) | 扩展分流：`template/*-rule-split-extend.yaml` ⇄ `generated/*-rule-split.local.yaml`、`render-local.sh`、Hooks |
| [`docs/clash-verge/RULEBASE-PROGRAM.md`](docs/clash-verge/RULEBASE-PROGRAM.md) | 自用规则库：背景、阶段顺序（Verge → 其它端）、`verge/template/` 与配置分层、脱敏红线、模块化切块口径 |

### 安装与使用路径

本仓库推荐通过 **`pipx`** 安装 **`hjs-egress-ip`**；**具体 `pip install` / `pipx install` 等命令行请只阅读** [`hjs-egress-ip-cli/README.md`](hjs-egress-ip-cli/README.md)，**根 README 不抄写**。**仅克隆**本仓库**并不意味着已安装**可执行工具；若要用 CLI，请按该子目录说明完成安装。**分流 YAML** 维护见 [`verge/README.md`](verge/README.md)。

### 分流与验证主路径（与 Verge 内置能力一致）

日常在 Verge 内维护节点后，按 [`verge/README.md`](verge/README.md) 用 `render-local.sh` / Hooks 刷新 **`generated/airport-rule-split.local.yaml`**（默认）或与当前 Template 对应的 **`generated/*-rule-split.local.yaml`**，再粘贴进「全局扩展配置」；详见 [Clash Verge — Extend][clash-verge-extend] 与 [`docs/clash-verge/verification-playbook.md`](docs/clash-verge/verification-playbook.md)。

v1.0 归档：`.planning/milestones/v1.0-phases/`。

[clash-verge-extend]: https://www.clashverge.dev/guide/extend.html
