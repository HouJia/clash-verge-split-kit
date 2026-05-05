# Phase 4: repo-entry-v1-1-links - Context

**Gathered:** 2026-05-04
**Status:** Ready for planning

<domain>
## Phase Boundary

在仓库**根** `README.md`（或项目约定的等效单一入口）中：**链向 v1.1 文档集合**（分流说明、脱敏/扩展产物、验证与审计联动），并**澄清**工具安装与使用路径，满足 **VER-03**。交付前核对相对链接有效、无断链。本阶段**不**改 Clash Verge 软件本体、**不**新建私有仓库。

**叙事底线（与 CV-03 / Phase 2 D-13 一致）：** 日常由维护者在 **Clash Verge 内导入并刷新 HTTPS 订阅**；**分流规则、策略组、DNS/geodata 等进入 Verge「当前配置（最终生效）」的主路径**是客户端**内置**的**全局扩展 / 订阅扩展 / 覆写合并链**（将仓库内 `verge/extend/global-split.yaml` 或按文档生成的粘贴稿交给 Verge）。**不是**以 Python 脚本自建一套「替代 Verge 合并管线」作为读者理解的默认做法。

</domain>

<decisions>
## Implementation Decisions

### 根 README：pipx / 包安装叙事（讨论区域 3）

- **D-01：** 根 `README.md` **不**抄写可复制安装命令；用简短表述说明 **CLI 推荐 `pipx` 安装**，并**链接** `hjs-egress-ip-cli/README.md`，由子文档给出具体命令与开发安装。
- **D-02：** 根 `README` **单独一句纠偏**：**仅克隆仓库不等于已安装**；若要用 `hjs-egress-ip` 等可执行入口，须按子目录说明执行 `pipx`/`pip` 安装；根**不**展开命令。
- **D-03：** 根可用**一句泛化**概括工具链：**Python 3.9+**、**`pipx`** 为常见分发方式；**细节**分别见 `hjs-egress-ip-cli/` 与 `verge/README.md`。**须与 D-05 连用**：该句**不得**被读者理解成「分流进 Verge 靠跑 Python 合并脚本」——见下条。
- **D-04：** 根可补**半句**：若**尚未**从包索引（如 PyPI）安装，可按本仓库**包目录**与子文档完成安装；仍**不在**根贴具体命令，避免与发布进度不同步。

### Verge：扩展 / 覆写为主路径（2026-05-04 用户纠正）

- **D-05：** **订阅与节点**由用户在 **Verge 内**维护（导入、刷新）；仓库交付的是**可粘贴进「全局扩展配置」等的规则与组定义**（及文档），依赖 Verge **内置**能力把扩展与订阅产物**合并进最终使用的配置**。入口文案、链接与用语须**优先**指向这一路径，与官方 Extend 说明一致。
- **D-06：** `verge/scripts/` 下 Python（如占位符渲染、可选拉取到 `out/`、可选单文件合并）为**辅助**：调试、替换占位 IP、备份或离线对照等；**根入口与 VER-03 相关段落不得**将这些脚本写成使用本仓库分流规则的**前置必跑步骤**。

### 本会话未讨论的灰区（交由 `/gsd-plan-phase` 在 VER-03 内裁定）

- **根 README 信息架构**：独立「v1.1 导航」小节 vs 表格内链 vs 顶部 TL;DR — **未定**。
- **必链路径的完整清单与顺序**（如是否并列 `verification-playbook.md`、`local-split-vps.md`、`verge/README.md`）— **未定**。
- **与现有「快速分流」段落的关系**（上下并列 vs 合并叙事）— **未定**。

### Claude's Discretion

- 无：用户未选择「你决定」类选项；未讨论灰区由 planner 在 VER-03 与 D-01～D-06 约束下补齐。

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 需求与路线

- `.planning/REQUIREMENTS.md` — **VER-03** 与 v1.1 边界（根入口、`pipx`、合并工具若有则链出；不改 Verge 本体）
- `.planning/ROADMAP.md` — Phase 4 目标、成功标准、需求映射
- `.planning/PROJECT.md` — 里程碑叙述、`pipx`/包为第一入口、不写真实订阅

### 本阶段讨论与 Phase 2 锁定口径

- `.planning/phases/02-clash-verge-split-docs/02-CONTEXT.md` — **CV-03 / D-13**：Verge **Extend** 主路径（HTTPS 订阅 + 全局扩展粘贴）；可选脚本不替代 Verge 订阅机制

### 仓库内入口与文档（实施时核对相对路径）

- `README.md` — 待按本 CONTEXT 更新（VER-03）
- `docs/clash-verge/README.md` — 分流说明目录入口
- `docs/clash-verge/local-split-vps.md` — 自用分流与工具链说明
- `docs/clash-verge/verification-playbook.md` — 可重复验证与审计联动
- `verge/README.md` — 扩展粘贴工作流、可选脚本定位（**辅助**）
- `verge/extend/global-split.yaml` — 全局扩展片段（脱敏占位）
- `hjs-egress-ip-cli/README.md` — **`pipx`/安装**细节（根仅链入）

### 结构地图

- `.planning/codebase/STRUCTURE.md` — 顶层目录角色与 `README` 预期

### 外部参考（不在仓库内）

- Clash Verge **Extend** 官方说明：`https://www.clashverge.dev/guide/extend.html`（入口文案可链；以用户本机客户端版本为准）

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- 根 `README.md` 已有目录表与「快速分流」一句；Phase 4 在其上增补 VER-03 链与 **D-01～D-06** 口径即可，无需新代码资产。
- `verge/README.md` 已区分「推荐工作流（订阅 + 全局扩展粘贴）」与「可选合并单文件」；根入口应 **放大前者**、弱化后者为可选，以符合 **D-05 / D-06**。

### Established Patterns

- 用户可见说明以**中文**为主（见 `.planning/codebase/CONVENTIONS.md`）；Clash/mihomo 键名保持英文。
- `STRUCTURE.md` 将根 `README` 定义为仓库入口，指向 CLI、`verge/`、`docs/clash-verge/`、`.planning/`。

### Integration Points

- Phase 4 仅动文档入口与交叉引用；与 Phase 2/3 已落盘路径对齐，避免断链。

</code_context>

<specifics>
## Specific Ideas

- 用户明确：**在 Verge 里导入/刷新订阅**；**利用 Verge 内置扩展与覆写**把代理分组、分流规则、策略写入**最终配置** — **不是**把「用 Python 自研一套合并管线」当作默认心智模型（**D-05 / D-06**）。

</specifics>

<deferred>
## Deferred Ideas

- **根 README 版式与链接全集**（未在本次讨论中选定）：见 `<decisions>` 中「本会话未讨论的灰区」；由 plan 在 VER-03 内一次定稿。

**None beyond scope** — 未引入新要求能力。

</deferred>

---

*Phase: 4-repo-entry-v1-1-links*
*Context gathered: 2026-05-04*
