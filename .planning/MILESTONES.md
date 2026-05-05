# Milestones

## v1.0 CLI 与审计 UI（交付：2026-05-03）

**完成：** 1 个阶段，4 份计划执行摘要（01-01 … 01-04），索引见 `.planning/milestones/v1.0-phases/01-hjs-egress-ip-cli-tool/PLAN.md`  
**归档：** [v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md) · [v1.0-REQUIREMENTS.md](milestones/v1.0-REQUIREMENTS.md)

**预检：** 关闭前 `gsd-sdk query audit-open` 无未关闭工件。磁盘上无 `v1.0-MILESTONE-AUDIT.md`；若需正式里程碑审计，可补跑 `/gsd-audit-milestone`。

**主要成果：**

1. 建立 `hjs-egress-ip-cli/`：可编辑安装、`hjs-egress-ip` 入口与占位扩展为完整 CLI。
2. 外置 `probes.default.yaml`、CLI 参数与 `formatters` + `pytest` 覆盖默认与全量路径。
3. `serve` 子命令、静态审计 UI 随包分发、`python -m build` 产物可用。
4. 全局技能与仓库根 `README` 以 `pipx` / 包安装为第一推荐路径。
5. 代码审查中 Warning（`Content-Length` 与 POST 体大小）已修复并记录在 `01-REVIEW-FIX.md`。

---
