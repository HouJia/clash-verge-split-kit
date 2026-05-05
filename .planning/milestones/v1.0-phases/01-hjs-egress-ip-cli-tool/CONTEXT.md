# Phase 1：hjs-egress-ip-cli-tool — Context

**Gathered:** 2026-05-03  
**Status:** Ready for planning  
**来源:** 用户要求将 `~/.cursor/skills/hjs-egress-ip-audit/scripts/` 演进为正式工具项目。

## Phase Boundary

交付物为**独立可安装的命令行工具**（建议 Python 包或单一二进制分发策略二选一），功能上覆盖当前技能脚本：

- 默认：一键按站点类型（国内 / 国际 / CDN / 元数据）汇总出口观测。
- 可选：`--full` 完整矩阵（S0 尊重代理、S1 `--noproxy`、IPv4/IPv6、可选 `--interface`）。
- 可选：本地 Web UI（或作为 extras 子包），与 CLI 共享核心探测逻辑。

不在本阶段：商业级分布式探测、账号体系、云端存储。

## Implementation Decisions

- **默认 UX 保持简单**：主命令无子命令时即「一键」；进阶项通过 `--full` 与文档中的「技术附注」暴露。
- **探测列表数据驱动**：探测点从 YAML/JSON 配置文件加载，便于发布后不改代码增删端点。
- **与 Cursor 解耦**：工具名可与技能名对齐（如 `hjs-egress-ip` CLI），技能文档改为「调用已安装的 CLI」或「内嵌兼容层调用」二选一（PLAN 中定稿）。

## Claude's Discretion

- 选择 `pyproject.toml + uv/pipx` 或 `Go single binary` 的具体栈。
- Web UI 是否拆为 `pip install hjs-egress-ip[web]` optional extra。
- 单元测试框架（pytest）与 mock curl 的策略。

## Canonical References

- `~/.cursor/skills/hjs-egress-ip-audit/SKILL.md`
- `~/.cursor/skills/hjs-egress-ip-audit/reference-endpoints.md`
- `~/.cursor/skills/hjs-egress-ip-audit/scripts/egress-ip-audit.sh`
- `~/.cursor/skills/hjs-egress-ip-audit/scripts/serve-audit-ui.py`
- 本阶段执行索引：`.planning/milestones/v1.0-phases/01-hjs-egress-ip-cli-tool/PLAN.md`
- 子计划：`01-01-PLAN.md` … `01-04-PLAN.md`

## Deferred Ideas

- 浏览器插件或系统代理 PAC 联动检测。
- 多机器集中上报与对比。

---

*Phase: 001-hjs-egress-ip-cli-tool*
