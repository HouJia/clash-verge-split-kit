# Roadmap：airport

## 里程碑

- ✅ **v1.1 Clash Verge 分流与验证** — Phase 2–4（2026-05-04）— 需求见 `.planning/REQUIREMENTS.md`
- ✅ **v1.0 CLI 与审计 UI** — Phase 1（2026-05-03）— [路线图归档](milestones/v1.0-ROADMAP.md) · [需求/验收归档](milestones/v1.0-REQUIREMENTS.md)

## 阶段

### v1.1 Clash Verge 分流与验证（Phase 2–4）

- [x] **Phase 2: clash-verge-split-docs**（2026-05-04）— 自用说明、脱敏规则骨架、**订阅拉取与分流合并自动化**（CV-01～CV-04）
- [x] **Phase 3: egress-verification-playbook**（2026-05-04）— 可重复验证流程与 `hjs-egress-ip` / 审计 UI 对齐（VER-01、VER-02）
- [x] **Phase 4: repo-entry-v1-1-links**（2026-05-04）— 仓库入口链向 v1.1 交付物并说明与安装路径关系（VER-03）

#### Phase 2: clash-verge-split-docs

**目标：** 交付 **CV-01～CV-04**：自用说明、脱敏规则骨架、**从订阅 URL 自动化生成含分流规则的完整可导入配置**、**macOS/Windows 可复用**。

**Depends on：** 无（v1.1 首阶段）

**成功标准（可观察）：**

1. 仓库内存在自用中文说明（如 `docs/clash-verge/`），阐明分流概念与**合并产物**如何导入 Verge。
2. 存在脱敏规则/配置骨架（`verge/extend/global-split.yaml` 与 `verge/templates/`），公开树中无真实订阅 URL 与密钥。
3. **自动化（Verge Extend）：** 维护者在本机 Verge 配置 **HTTPS 订阅**（URL 不进 Git），并将 `verge/extend/global-split.yaml` 置于 **全局扩展配置**；订阅负责节点，扩展负责 `dns`/`geodata`/`rules`，得到**可直接使用**的运行配置；更新订阅 URL 或扩展内容后按 Verge 流程刷新即可。
4. **跨平台：** 上述流程在 **macOS 与 Windows** 上均有文档化运行方式（与 Python/`pipx` 路径一致者优先）。
5. 说明中注明客户端行为以**本机安装版本**为准。

**需求映射：** CV-01、CV-02、CV-03、CV-04

**Plans：** 3/3 — `02-01`（文档/跨平台说明）、`02-02`（脱敏骨架审计）、`02-03`（合并脚本与 pytest）

---

#### Phase 3: egress-verification-playbook

**目标：** 定义可重复验证步骤，并与现有 `hjs-egress-ip` CLI 与审计 UI 的检查清单式衔接，满足 VER-01、VER-02。

**Depends on：** Phase 2（分流概念、脱敏骨架与**合并产物形态**已就绪，验证文档可引用同一术语与产出文件）

**成功标准（可观察）：**

1. 存在步骤级验证说明：在切换规则或节点后，可按顺序重复执行以确认某类流量走 DIRECT 或指定策略组。
2. 各关键步骤写明 Clash Verge 内可观察指标（如连接/日志等视图）及可选的系统侧核对建议。
3. 同一交付物（或明确交叉引用）说明何时运行 `hjs-egress-ip`、如何解读其输出，并与分流预期逐项对照。
4. 提供简短检查清单（条目化），与审计 UI 的典型打开—加载—对照流程有显式对应（章节或表格）。

**需求映射：** VER-01、VER-02

**Plans：** 1/1 — `03-01`（验证 playbook 文档 + 入口与交叉引用）

---

#### Phase 4: repo-entry-v1-1-links

**目标：** 在仓库根 `README` 或等效单一入口中链向 v1.1 文档集合，并澄清与 `pipx`/包安装路径的关系，满足 VER-03。

**Depends on：** Phase 2、Phase 3（交付文档路径稳定后再写入入口链接）

**成功标准（可观察）：**

1. 根 `README.md`（或项目约定的等效入口文件）包含指向 v1.1 分流说明、脱敏示例与验证/审计联动文档的链接。
2. 入口段落说明：工具以 `pipx`/包安装为第一路径；本里程碑含**分流合并自动化**与验证方法论，不要求修改 Clash Verge 本体。
3. 交付前核对：上述链接在仓库内相对路径有效、无断链。

**需求映射：** VER-03

**Plans：** 1/1 — `04-01`（根 README：VER-03 链与安装/主路径叙事）

---

<details>
<summary>✅ v1.0 CLI 与审计 UI（Phase 1）— 已于 2026-05-03 交付</summary>

- [x] **Phase 1: hjs-egress-ip-cli-tool**（4/4 计划）— 2026-05-03

完整叙述、成功标准与计划链接见 [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)。

</details>

## 下一步

v1.1 阶段 2–4 已全部完成。后续迭代见 `.planning/REQUIREMENTS.md`「后续版本」与里程碑规划。

## 进度

| 阶段 | 里程碑 | 计划完成 | 状态 | 完成日 |
|------|--------|----------|------|--------|
| 2. clash-verge-split-docs | v1.1 | 3/3 | Complete | 2026-05-04 |
| 3. egress-verification-playbook | v1.1 | 1/1 | Complete | 2026-05-04 |
| 4. repo-entry-v1-1-links | v1.1 | 1/1 | Complete | 2026-05-04 |
| 1. hjs-egress-ip-cli-tool | v1.0 | 4/4 | Complete | 2026-05-03 |
