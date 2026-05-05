# 项目回顾（持续更新）

*在每个里程碑结束后追加一节；结论用于下一里程碑规划。*

## Milestone：v1.0 — CLI 与审计 UI

**交付日：** 2026-05-03  
**阶段数：** 1 | **计划数：** 4

### 交付内容

- 可安装的 `hjs-egress-ip` CLI 包骨架与入口脚本
- 默认/全量探测 YAML、TSV 解析与分组、`pytest` 覆盖
- `serve` 子命令与静态审计页面包内分发
- 全局技能与仓库 `README` 交叉引用；代码审查 Warning 闭环

### 顺畅之处

- 分四个小计划（01-01 … 01-04）递进，每波有独立 `SUMMARY.md`，便于验收与回顾
- 先委托既有 bash 脚本再迭代，首版风险可控

### 可改进之处

- 未使用独立 `REQUIREMENTS.md` 时，跨文档追溯依赖 `ROADMAP` 成功标准；下一里程碑可补正式需求表
- `gsd-sdk summary-extract` 对当前 SUMMARY  frontmatter 未产出 one_liner，里程碑条目需手工整理成果列表

### 形成惯例

- v1.0 阶段执行产物已迁入 `.planning/milestones/v1.0-phases/<phase>/`；下一里程碑仍可用 `.planning/phases/`（由 `/gsd-new-milestone` 等流程创建）
- 审查与修复记录：`01-REVIEW.md` + `01-REVIEW-FIX.md`

### 主要教训

1. 本地 HTTP 工具应在首版即限制请求体并校验 `Content-Length`，与 JSON 解析的防御风格一致。
2. 关闭里程碑前运行 `audit-open` 可快速确认无悬挂工件。

### 成本与工具（占位）

- 本会话未统计模型调用比例；后续若需成本复盘可在模板中补实测数据。

---

## 跨里程碑趋势

### 过程演进

| 里程碑 | 阶段数 | 主要变化 |
|--------|--------|----------|
| v1.0 | 1 | 建立 CLI 包与 GSD 规划目录结构 |

### 质量累积（占位）

| 里程碑 | 测试 | 说明 |
|--------|------|------|
| v1.0 | `pytest` 6 项通过 | 以 `formatters` 为主；CLI/Web 集成测试见 `01-REVIEW.md` Info |

### 经多里程碑验证的教训

1. （待 v1.1+ 后补充）
