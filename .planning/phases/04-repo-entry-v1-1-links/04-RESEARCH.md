# Phase 4: repo-entry-v1-1-links — Research

**Question:** 需要哪些信息才能为 VER-03（根 README 入口链与安装叙事）做好可执行规划？

## RESEARCH COMPLETE

### 结论摘要

1. **交付形态：** 仅改仓库根 `README.md`（等效入口已约定为根 README，见 `STRUCTURE.md`）。不新增代码、不改 Clash Verge 本体、不建新仓。
2. **链接全集（相对路径，与 `04-CONTEXT` canonical_refs 一致）：**
   - `docs/clash-verge/README.md` — 分流说明目录入口
   - `docs/clash-verge/local-split-vps.md` — 自用分流与工具链
   - `docs/clash-verge/verification-playbook.md` — 验证与审计联动
   - `hjs-egress-ip-cli/README.md` — **`pipx`/安装**细节（根只链入，不抄命令，**D-01**）
   - `verge/README.md` — Extend 粘贴主路径 + 脚本的**辅助**定位（**D-05 / D-06**）
3. **叙事顺序：** 先 **Verge 内 HTTPS 订阅 + 全局扩展粘贴**（与现有「快速分流」一句一致并强化），再 **v1.1 文档导航**表格或列表；单独短段落实 **D-02**（仅克隆 ≠ 已安装）、**D-03/D-04**（Python 3.9+、`pipx` 常见、细节见子 README），且与 **D-05** 连用避免「分流靠跑 Python 合并脚本」误读。
4. **版式裁定（灰区）：** 采用 **独立「v1.1 文档与工具链」小节**：含导航表（路径 + 一句话用途）+ 安装叙事段 + 可选一句链到 Clash Verge Extend 官方文档（`https://www.clashverge.dev/guide/extend.html`），与现有「仓库结构」表上下并列，不删除「快速分流」句，可微调其用语与导航互链。
5. **依赖：** Phase 2/3 文档路径已稳定；执行前确认上述目标文件均存在（当前仓库已具备）。

### 关键引用路径

| 资产 | 路径 |
|------|------|
| 当前根入口 | `README.md` |
| 需求 VER-03 | `.planning/REQUIREMENTS.md` |
| 决策 D-01～D-06 | `.planning/phases/04-repo-entry-v1-1-links/04-CONTEXT.md` |
| Phase 2 口径 | `.planning/phases/02-clash-verge-split-docs/02-CONTEXT.md`（CV-03 / D-13） |
| 结构约定 | `.planning/codebase/STRUCTURE.md` |

### 风险与边界

- **断链：** 重命名 `docs/` 下文件会导致根链接失效 — 交付验收须逐链核对（`test -f` 或等价）。
- **信息泄露：** 根 README 不得出现真实订阅 URL — 与 Phase 3 相同 `rg` 口径抽检。

---

## Validation Architecture

本阶段为**纯文档**，验证策略侧重：

1. **文件修改范围：** 仅 `README.md`（除非发现项目另有「等效入口」约定 — 当前无）。
2. **链接存在性：** 导航中列出的每个仓库内相对路径，在磁盘上存在且可读。
3. **VER-03 覆盖：** 根 README 同时出现指向「分流说明目录」「`pipx`/CLI 安装说明」「Verge/合并与扩展工作流（`verge/README.md`）」的 Markdown 链接；并含可观察的**安装路径澄清**字面要求（**仅克隆不等于已安装**、**推荐 `pipx`** 等，与 **D-01～D-04** 一致）。
4. **叙事：** 正文须体现 **Extend/订阅 + 粘贴** 为主路径，**`verge/scripts/` 为辅助**（**D-05 / D-06**），不得将 Python 脚本写成使用分流规则的**前置必跑步骤**。
5. **敏感信息：** `rg` 抽检公开订阅 URL 模式无命中（与 Phase 2/3 计划一致）。

Nyquist：任务级以 `rg`/`test` 为主；人工通读根 README 为 Manual-Only 最终签核。
