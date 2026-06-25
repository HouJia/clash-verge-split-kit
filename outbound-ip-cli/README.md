# outbound-ip — 出站 IP 探测工具

| 项目 | 内容 |
|---|---|
| **创建时间** | 2026-06-25 |
| **最后更新** | 2026-06-25 |

## 更新记录

| 日期 | 更新内容 |
|---|----|
| 2026-06-25 | 自 `hjs-egress-ip` 更名为 `outbound-ip`（与 3x-ui「出站」同义） |
| 2026-06-25 | 技能与脚本统一 outbound 命名；澄清 CLI 与网页两种形态 |

## 目录

- [更新记录](#更新记录)
- [一句话](#一句话)
- [这是什么？终端 + 网页，不是「只有一个网页」](#这是什么终端--网页不是只有一个网页)
- [背景：为什么要做这个工具](#背景为什么要做这个工具)
- [它解决什么问题](#它解决什么问题)
- [和 Clash 分流是什么关系](#和-clash-分流是什么关系)
- [什么时候该用它](#什么时候该用它)
- [它不是什么](#它不是什么)
- [输出长什么样](#输出长什么样)
- [安装与日常用法](#安装与日常用法)
- [与 Cursor 技能的关系](#与-cursor-技能的关系)
- [维护者与探测点变更](#维护者与探测点变更)
- [相关文档](#相关文档)

## 一句话

**在你这台机器上，从多个「查 IP」网站同时看出去，对方眼里你的公网出口是哪里——用来验证代理/分流有没有按预期工作。**

## 这是什么？终端 + 网页，不是「只有一个网页」

| 形态 | 怎么用 | 适合 |
|------|--------|------|
| **终端 CLI** | 安装后执行 `outbound-ip`（见下文 `pipx` / `pip install -e`） | 改完分流规则后快速看摘要、脚本留档 |
| **浏览器页** | `outbound-ip serve` 或仓库根 `./start-outbound-ip.sh` | 点按钮看图、给不熟悉终端时用 |
| **纯静态 HTML** | 直接打开包内 `web/static/index.html` | 无需安装，但部分站点受 CORS 限制 |

**只有网页、不装 CLI 也可以点「一键检测」**（浏览器 `fetch`）；但 **`--full` 矩阵、与 curl 完全一致的摘要** 仍依赖 **`outbound-ip-audit.sh`**，由 CLI 在终端调用。克隆仓库 ≠ 已安装命令，需要时才 `pipx install` 或用仓库里的 `start-outbound-ip.sh` 起本地服务。

---

## 背景：为什么要做这个工具

本仓库（`airport`）的主线是 **Clash Verge 分流**：用规则决定「哪些流量直连、哪些走机场节点」。  
分流改完后，你真正关心的是：

- 访问 Google / TikTok / 国内站时，**对方服务器看到的 IP** 是家宽、VPS，还是某个机场机房？
- 刚在 Verge 里 **换了节点、改了规则、重载配置**，效果对不对？
- 终端里 `curl` 看到的 IP，和浏览器里打开 `whatismyip` 是否一致？（系统代理、TUN、规则漏网会导致不一致）

最早这些检查写在 Cursor 全局技能 **`hjs-outbound-ip-audit`** 里的 bash 脚本（`outbound-ip-audit.sh`）：在终端里对一批探测 URL 做 `curl`，按「国内站 / 国际站 / CDN 观测 / JSON 接口」分组汇总。

**`outbound-ip-cli`** 是把同一套能力 **打包成可独立安装的 CLI**（`pipx install` 后终端随处可用），并附带可选的 **浏览器审计页**（`outbound-ip serve`），不再绑在 Cursor IDE 里。

---

## 它解决什么问题

| 困惑 | 本工具能帮你 |
|------|-------------|
| 「我明明选了美国节点，网站还是把我当地域限制？」 | 看多个探测点回显的 IP / 地域是否真是美国机房 |
| 「这条域名应该直连，怎么还是慢？」 | 对照出口是否仍是代理 IP，而不是家宽 |
| 「改完 `verge/` 规则并 reload 了，生效了吗？」 | 改规则前后各跑一次，对比摘要是否变化 |
| 「只有浏览器能上网，终端 curl 不对」 | CLI 走 shell 网络栈；审计页走浏览器栈，可发现 **分流不同步** |

**Clash 告诉你「规则命中哪一组」；本工具告诉你「数据包出去时长什么样」。** 两者互补，不能互相替代。

---

## 和 Clash 分流是什么关系

```text
verge/ 规则（谁该直连 / 谁该走代理）
        ↓ 你在 Verge 里保存、重载
Clash 按 rules 转发流量
        ↓ 你想确认「对外 IP 对不对」
outbound-ip（多站点探测出口）
```

配套验证流程见仓库 [`docs/clash-verge/verification-playbook.md`](../docs/clash-verge/verification-playbook.md)：先在 Verge **Connections** 里看策略链，再用本工具做出口侧抽查。

---

## 什么时候该用它

**适合跑一遍：**

- 新装/换机场、切换 **策略组默认节点** 之后
- 修改 `verge/derive/parts/` 或 `override.local.ini` 并 **重载 Clash** 之后
- 怀疑某站「该走代理却直连」或反过来
- 配置 **亮数据 ISP、VPS 直连** 等新规则后，确认相关流量没绕回隧道

**不必天天跑：** 节点和规则稳定、出口无异常时，不必例行探测。

---

## 它不是什么

- **不是** 测速、延迟、丢包工具（不替代 `url-test` 测速）
- **不是** 规则编辑器，不会改 Clash 配置
- **不能保证** 某个具体网站（如 Netflix）的 IP——它用的是一批 **通用「我是谁」探测站**，与目标站 CDN 可能不同
- **不能** 代替 Verge 里看 `rules` 命中与 Connections 策略链（见 playbook）

---

## 输出长什么样

**默认（无参数）：** 按场景分组的一段 **人类可读摘要**，例如国内站、国际回显、Cloudflare trace、JSON 接口等各自显示的 IP / 地域片段。

**`--simple-tsv`：** 带 `scenario` 表头的表格行，便于脚本对比或存档。

**`--full`：** 完整技术矩阵（多网卡/IPv6 等场景，底层仍由 `outbound-ip-audit.sh` 执行）。

**`outbound-ip serve`：** 在本机 `127.0.0.1` 打开静态审计页，点「一键检测」在浏览器里看同样分组的结果（部分站点需经本地 `GET /__probe` 代读，绕过浏览器 CORS 限制）。

---

## 安装与日常用法

### 安装（推荐 pipx）

```bash
cd outbound-ip-cli
pipx install .
# 或开发模式：pip install -e ".[dev]"
```

依赖：本机有 **`curl`**。探测脚本查找顺序：`OUTBOUND_IP_AUDIT_SCRIPT` → 包内 `outbound-ip-cli/scripts/outbound-ip-audit.sh` → `~/.cursor/skills/hjs-outbound-ip-audit/scripts/outbound-ip-audit.sh`。

### 三条最常用命令

```bash
# 1. 改完分流/换节点后：一眼看分组摘要
outbound-ip

# 2. 要给脚本或笔记留底
outbound-ip --simple-tsv | head -10

# 3. 浏览器里点着看（可选）
outbound-ip serve
# 另开终端：curl -s http://127.0.0.1:18765/health  → 应返回 ok
```

仓库根目录另有快捷脚本 [`start-outbound-ip.sh`](../start-outbound-ip.sh)，等价于启动 `serve`。

### 环境变量

| 变量 | 说明 |
|------|------|
| `OUTBOUND_IP_AUDIT_SCRIPT` | 覆盖 `outbound-ip-audit.sh` 的绝对路径 |
| `CURL_TIMEOUT` | 透传底层脚本超时（秒，默认 8） |

### 测试与打包

```bash
cd outbound-ip-cli
pytest -q
python -m build   # 需 pip install build；产物在 dist/
```

---

## 与 Cursor 技能的关系

| | Cursor 技能 `hjs-outbound-ip-audit` | 本 CLI `outbound-ip` |
|---|-----------------------------------|-------------------------|
| 运行环境 | IDE 内说明 + 脚本路径 | 任意终端，`pipx` 安装 |
| 探测逻辑 | `outbound-ip-audit.sh` | **默认仍调用同一脚本** |
| 审计页 | 技能内文档指向静态页 | 随包分发，`serve` 子命令 |

没有装 Cursor 也可以装 CLI；但 **首版仍依赖技能目录下的 bash 脚本**（或你通过环境变量指定的副本）。

---

## 维护者与探测点变更

探测 URL 与解析逻辑的 **语义真值** 在：

`src/outbound_ip/web/static/audit-core.js` 内的 `PROBES` 与 `snippetFromBody`。

变更后请：

1. 在包根目录执行 `node scripts/sync-probes.mjs` → 更新 `src/outbound_ip/data/probes.packaged.json`
2. 同步修改技能内 `outbound-ip-audit.sh` 的 `PROBES` 数组，避免 CLI 与终端脚本漂移

---

## 相关文档

| 文档 | 内容 |
|------|------|
| [`.cursor/skills/hjs-outbound-ip-audit/SKILL.md`](../.cursor/skills/hjs-outbound-ip-audit/SKILL.md) | 配套 Cursor 技能与脚本说明 |
| [`docs/clash-verge/verification-playbook.md`](../docs/clash-verge/verification-playbook.md) | 改规则后：Verge 内检查 + 何时跑本 CLI |
| [`docs/clash-verge/local-split-vps.md`](../docs/clash-verge/local-split-vps.md) | 分流概念；第 5 节简述与出站探测工具关系 |
| [`verge/README.md`](../verge/README.md) | 分流规则维护（`derive/parts/`、`override.local.ini`） |
