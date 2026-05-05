# Phase 3: egress-verification-playbook — Research

**Question:** 需要哪些信息才能为 VER-01 / VER-02 做好可执行规划？

## RESEARCH COMPLETE

### 结论摘要

1. **交付形态：** 以 `docs/clash-verge/` 下**新增独立 playbook** 为主（与 D-01 一致），与 `local-split-vps.md` 交叉引用；不在 Phase 3 修改 `hjs-egress-ip-cli` 行为，只**对齐文档**。
2. **VER-01：** 步骤需绑定 **Clash Verge 可观察面**：Rule 模式、当前运行时配置（只读）、**连接 / Connections**（或等价视图）中域名与策略链、必要时 **日志**。系统侧可选：`dig`/`curl` 仅作辅助，不作为唯一判据。
3. **VER-02：** CLI 侧以仓库已 documented 的用法为准：`hjs-egress-ip` 无参摘要、`--simple-tsv` 表头含 `scenario`；审计 UI：`hjs-egress-ip serve`、`http://127.0.0.1:18765/health` 返回 `ok`、页面「一键检测」。Playbook 须给出**何时**在改规则/切节点后执行、以及如何与「预期走 DIRECT / 某策略组」逐项对照。
4. **依赖 Phase 2 术语：** 沿用 `verge/extend/global-split.yaml`、Extend 主路径、策略组名与订阅对齐等表述，避免与 `02-CONTEXT` 冲突。
5. **测试：** 本阶段以**文档验收**为主；自动化可为 `rg`/链接存在性；不要求新增 pytest，除非执行阶段扩展范围。

### 关键引用路径

| 资产 | 路径 |
|------|------|
| 分流自用说明 | `docs/clash-verge/local-split-vps.md` |
| 入口 | `docs/clash-verge/README.md` |
| CLI / 审计 UI 说明 | `hjs-egress-ip-cli/README.md` |
| Phase 2 决策与 canonical | `.planning/phases/02-clash-verge-split-docs/02-CONTEXT.md` |
| 需求 | `.planning/REQUIREMENTS.md`（VER-01、VER-02） |

### 风险与边界

- **无法自动化：** 本机 Verge 点击与实时连接列表依赖人工；playbook 只定义**可重复顺序**，不承诺 CI 内仿真。
- **客户端差异：** 须保留「以本机安装版本为准」免责声明（与现有文档一致）。

---

## Validation Architecture

本阶段以**文档与清单**为主，验证策略侧重：

1. **交付物存在性：** `docs/clash-verge/verification-playbook.md` 存在且被 `README.md` 链入。
2. **内容覆盖：** 文档中显式出现步骤序列、Verge 观察项、`hjs-egress-ip` 与 `serve` 流程、**检查清单**（表格或条目）。
3. **敏感信息：** 公开树中无真实订阅 URL / 密钥示例（与 Phase 2 相同 rg 口径）。
4. **回归：** 可选在 Wave 0 运行 `pytest`（`hjs-egress-ip-cli`）确认未误改包；**非阻塞**本阶段目标。

Nyquist：**无**连续多任务缺少可自动化核对 — 以人工按 playbook 走查为主；`VALIDATION.md` 中标注 Manual-Only 行。
