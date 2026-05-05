# Phase 2: clash-verge-split-docs - Context

**Gathered:** 2026-05-03
**Status:** Ready for planning

<domain>
## Phase Boundary

在仓库内交付 **CV-01～CV-04**：**自用**中文说明（CV-01）、**脱敏**规则骨架（CV-02）、**从本机配置的订阅 URL 拉取节点并与仓库内规则自动化合并为可导入 mihomo 配置**（CV-03）、**macOS/Windows 可复用**（CV-04）。核心叙事：维护者更新**私有订阅 URL**（不进 Git）→ 一条命令生成**已含分流规则的单文件（或等价产物）**→ Clash Verge **导入即用**，**不依赖**客户端内多步扩展手工拼接；过渡期可仍用手工扩展。**不是**对外教程。Phase 3–4 仍为验证与根入口（可约定 `docs/clash-verge/`）。

</domain>

<decisions>
## Implementation Decisions

### 文档位置与可发现性（灰区 1）

- **D-01:** 自用说明主路径为 **`docs/clash-verge/`**（当前已有 `local-split-vps.md`；若合并为单文件可收敛为 `README.md`），与 `hjs-egress-ip-cli/` 解耦；根 `README` 在 Phase 4 再链入。Phase 2 在 CONTEXT 中**固定相对路径**，避免漂移。
- **D-02:** 不在 `.planning/` 内隐藏唯一正文；`.planning` 仅保留规划与 Phase 工件。`PROJECT.md` / 路线图可一句话指向 `docs/clash-verge/`。

### 叙述深度与术语（灰区 2）

- **D-03:** 受众为**作者本人**（已会用 Clash Verge 导入订阅）；说明用**中文**，术语以 **Clash Verge 界面**为准，内核行为处标注 **mihomo / Meta**，不绑定某一闭源发行版独占菜单名。
- **D-04:** 须写清：**Rule 模式**、主策略组（模板中为 `PROXY`，合并订阅时需改为**与订阅里真实组名一致**）、**GeoSite `cn` + `geolocation-!cn` + GEOIP CN 兜底**；与「仅 `MATCH,PROXY`」的差异及国内站体验（不作系统指纹检测展开）。

### 示例形态与分流模式（灰区 3）

- **D-05:** CV-02 为 **`verge/extend/global-split.yaml`（扩展用规则+DNS+geodata）** 与 **`verge/templates/`** 脱敏示例；主路径为 **GeoSite/GeoIP**；进程级分流可一句带过。
- **D-06:** 仓库内仅 **脱敏模板**；**禁止**提交真实 `uuid`、服务器 IP、Reality 密钥、真实订阅 URL。填真值仅在本机 Verge / 私有副本。
- **D-07:** 说明须覆盖 **目标主路径（CV-03）**：自动化合并产物如何生成与导入；并保留 **过渡期** Verge **扩展配置**合并顺序（全局 → 订阅）作为对照；**不**写成对外点击教程。

### 订阅与敏感信息边界（灰区 4）

- **D-08:** 仅描述**概念与自用流程**（导入订阅、策略组命名对齐、扩展注入规则层），**不**在仓库维护真实订阅链接或商业评价；多订阅 + VPS 用占位名示意即可。
- **D-09:** 核对清单：示例无真实 URL/密钥；曾泄露的凭据**轮换**。

### 作者本机 Verge profile 与仓库模板（2026-05-04 补充）

- **D-10:** 本机 **Clash Verge 合并 profile**（`Application Support/.../profiles/*.yaml`）可为 **大表 DOMAIN 规则 + 多策略组**（如 SS-Rule-Snippet / 订阅转换产物），末尾常见 `GEOIP,CN → 全球直连`、`MATCH → 漏网组`。与仓库 **`verge/extend/global-split.yaml`** 的 **短 GEOSITE/GEOIP 链**是不同维护方式：前者细而长，后者短而依赖 geodata。自用说明中**可对照说明**两条路径；并强调「只合并节点、不合并 dns/rules/geodata」时会分流异常。
- **D-11:** 仓库 **仅保留** `verge/extend/` + `verge/templates/` 脱敏文件；**不**内嵌真实订阅节点。日常 **Verge 订阅 URL** 提供节点；**全局扩展**提供规则与 DNS。若以现成大表 profile 为主：仍可用扩展注入；**策略组名与订阅对齐**。
- **D-12:** **禁止**将本机 profile **真实路径或含密钥内容**写入仓库 / 公开 issue；仅私有环境对照。泄露按 **D-09** 轮换。

### 订阅 URL 自动化与跨机（2026-05-04 需求补充）

- **D-13（CV-03）：** **主路径**为 Clash Verge **内置** [Extend](https://www.clashverge.dev/guide/extend.html)：**HTTPS 订阅**（Verge 内拉取、自动更新 **proxies/proxy-groups**）+ **全局扩展配置**（粘贴仓库 `verge/extend/global-split.yaml`，覆写/合并 **dns/geodata/sniffer/rules**）；**只保留订阅节点，规则用仓库版**。可选脚本仅拉取订阅到 `verge/out/` 对照，**不**替代上述机制。
- **D-14（CV-04）：** 同一工具/流程须在 **macOS 与 Windows** 上可运行；优先 **Python 3.9+**，与现有 **`pipx install`** 路径对齐，Windows 须有安装与运行说明（路径、换行、证书等差异在文档或代码中处理）。
- **D-15：** 合并逻辑须处理 **策略组名对齐**（骨架中 `PROXY` 等与订阅内真实 `proxy-groups` 名称映射规则在 PLAN 中明确）；若订阅自带庞大 `rules`，需决定 **覆盖 / 前置 / 追加** 策略，避免 silently 失效。

### 技术备忘（供维护 CV-01～CV-04 时引用）

- **mihomo 常见顺序：** `geodata-mode` + **`MetaCubeX/meta-rules-dat`**；`private` →（可选）**VPS IP 直连** → **`GEOSITE,cn,DIRECT`** → **`GEOSITE,geolocation-!cn,<主代理组>`** → **`GEOIP,cn,DIRECT,no-resolve`** → **`MATCH,<主代理组>`**；配 `sniffer`、`dns`（常 `fake-ip`）。与 `verge/extend/global-split.yaml` 骨架一致；合并时 `<主代理组>` 须替换为订阅内真实名称。
- **SS-Rule-Snippet（作者本机可选克隆）：** DOMAIN 规则集参考；本地路径如 **`.../SS-Rule-Snippet`** 仅供作者自己对照，**不**作为仓库依赖。
- **验证：** 对话环境无法代作者点本机 Verge；自用说明中可写**自检要点**（Rule 模式、期望直连/代理站点），Phase 3 与 `hjs-egress-ip` / 审计 UI 对齐成 playbook。

### Claude's Discretion

- 示例代理组命名：模板保持 `PROXY` + `DIRECT`；合并工具实现 **显式映射** 或文档约定改名规则。
- Phase 2 交付：**合并工具（CLI 或脚本）** + `local-split-vps.md` + 脱敏骨架；**不**写截图教程。
- 合并实现细节（依赖 PyYAML、是否支持 `proxy-providers` 仅引用不展开等）由 `/gsd-plan-phase` 落 PLAN。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 需求与路线

- `.planning/REQUIREMENTS.md` — CV-01～CV-04、VER-* 验收口径
- `.planning/ROADMAP.md` — Phase 2 目标、成功标准、需求映射
- `.planning/PROJECT.md` — v1.1 边界、不写真实订阅、自用说明与验证对齐

### 仓库内可复用资产

- `docs/clash-verge/local-split-vps.md` — **自用**工具链说明（目标：订阅 URL → 自动化合并 → 导入；含过渡期扩展合并）
- `verge/extend/global-split.yaml` — **脱敏**全局扩展片段（GeoSite/GEOIP、DNS、sniffer、geox-url；**无** `proxies`）
- `verge/templates/standalone-profile.example.yaml` — 整份脱敏示例（可选单文件调试）
- `.planning/codebase/CONVENTIONS.md` — CLI 用户可见中文等（Python 包）；与 `docs/clash-verge` 自用说明分开
- `.planning/codebase/STRUCTURE.md` — 目录角色

### 外部参考（不在本仓库内）

- **MetaCubeX `meta-rules-dat`** — GeoSite/GeoIP 数据发布（`geox-url` 常用来源）
- **作者本机（可选）：** SS-Rule-Snippet 克隆路径 — DOMAIN 规则集与 GEOSITE 粗分流对照用，**不**进仓库依赖
- **作者本机（勿入库）：** Clash Verge `profiles` 下合并 YAML — 仅私有对照；**不得**提交含密钥副本

**说明：** ROADMAP 本阶段未列 `Canonical refs:` 字段；以上由讨论与 scout 汇总。

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `verge/extend/global-split.yaml`：**国内直连 + 境外走主代理组** 的常见 `rules` 顺序；**CV-03** 下由 Verge **全局扩展**加载。常见问题是 **未启用全局扩展** 或 **仅更新订阅、未同步扩展**。

### Established Patterns

- **CLI / Python 包**：用户可见字符串中文（CONVENTIONS）。**`docs/clash-verge/`**：作者自用中文说明；Clash 键名保持英文。

### Integration Points

- Phase 3 引用同一套术语与 YAML 结构，衔接 `hjs-egress-ip` 与审计 UI；Phase 4 根入口链到 `docs/clash-verge/`。

</code_context>

<specifics>
## Specific Ideas

- 作者场景：**订阅节点（含 VPS / 第三方）+ 本机分流规则**；若运行时只有 `MATCH,<代理组>` 而无 cn 直连链，国内站易全程代理。目标：**国内站直连**，**Google / Claude / YouTube 等**走主代理组。
- 可选对照本机 **SS-Rule-Snippet**：大表 DOMAIN 与短 GEOSITE 二选一或混用时的维护成本自知。
- 若 **Verge profile** 已是大表且含 `GEOIP,CN → 直连组`：仍异常时查 **DNS / sniffer / geodata** 与扩展是否进「当前配置」，而非只改最后一行 `MATCH`。

</specifics>

<deferred>
## Deferred Ideas

- **Phase 3（VER-01/02）：** 逐步验证流程、Clash 内可观察指标、与 `hjs-egress-ip` 及审计 UI 的检查清单式对照。
- **Phase 4（VER-03）：** 根 `README` 链到 `docs/clash-verge/` 与验证文档。
- **本阶段不纳入：** 自动化代替作者在本机点按验证；凭据轮换由作者在其基础设施上完成。

**None — discussion stayed within phase scope**（操作验证自动化属能力边界，已记入调研结论）

</deferred>

---

*Phase: 2-clash-verge-split-docs*
*Context gathered: 2026-05-03; 自用口径 2026-05-04; CV-03/CV-04 订阅自动化与跨平台 2026-05-04*
