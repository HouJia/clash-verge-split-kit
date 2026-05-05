# Phase 3 — UI Design Contract（文档对齐范围）

**Selected Framework:** 无新前端 — 本阶段**不**实现或改版审计 UI，仅在 playbook 中与现有能力对齐。

## 范围

- **现有审计 UI：** `hjs-egress-ip serve`（本地 Web，默认端口见 `hjs-egress-ip-cli/README.md` 当前描述，含 `/health` 与页面内一键检测）。
- **Playbook 义务：** 用文字说明「打开—加载—对照」与 CLI 并列表格；**不**规定新组件、色板或布局。

## 与 VER-02 的对应关系

| 能力 | 用户可观察行为 | Playbook 必须交代 |
|------|----------------|-------------------|
| 本地 Web | 浏览器访问提示 URL、点击探测 | 启动命令、与 Verge 步骤的前后顺序 |
| Health | `curl`/`health` 返回 | 可选自检命令行（与 README 一致） |
| CLI | 终端表格 / TSV | 何时执行、如何与「预期策略组/直连」对照 |

## 无障碍与主题

- 不扩展；沿用包内现有 Web 实现。

---

## UI-SPEC COMPLETE

*本文件满足 `workflow.ui_phase` 下「涉及 UI」阶段的契约占位：交付物为文档，而非新界面设计。*
