# Phase 1 — hjs-egress-ip-cli-tool — 执行索引

本阶段计划已按 GSD 习惯拆为 **`{phase}-{plan}-PLAN.md`**，供 `/gsd-execute-phase` 依次匹配 `*-PLAN.md` / `*-SUMMARY.md` 对执行。

## 计划一览

| 计划 | 文件 | Wave | `depends_on` | 摘要 |
|------|------|------|----------------|------|
| 01-01 | [01-01-PLAN.md](01-01-PLAN.md) | 1 | — | 仓库骨架、`pyproject.toml`、可编辑安装与占位入口 |
| 01-02 | [01-02-PLAN.md](01-02-PLAN.md) | 2 | `01` | YAML 探测表、CLI 与 bash 对齐、pytest、`README` pipx |
| 01-03 | [01-03-PLAN.md](01-03-PLAN.md) | 3 | `02` | `serve` 子命令、静态页打包、`python -m build` |
| 01-04 | [01-04-PLAN.md](01-04-PLAN.md) | 4 | `03` | 全局技能文档优先 CLI；仓库内交叉引用 |

执行顺序：**01-01 → 01-02 → 01-03 → 01-04**（后序计划 frontmatter 中 `depends_on` 已声明）。

## 阶段级验收（ROADMAP Success Criteria 对照）

1. `hjs-egress-ip --help` 与无参运行无未捕获异常。
2. 探测点外置 YAML，非法配置有明确报错。
3. `pytest` 覆盖解析/分组；`README` 含端到端手动检测步骤。

## 阶段级 Nyquist

- `README.md` 中至少一段「如何做一轮端到端检测」（CLI 与可选 Web）。

---

*详细任务、`<verify>`、`<must_haves>` 以各 `01-XX-PLAN.md` 为准；本文件不重复任务正文。*
