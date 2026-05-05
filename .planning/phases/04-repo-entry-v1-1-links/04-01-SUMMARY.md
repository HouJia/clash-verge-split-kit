---
phase: 04-repo-entry-v1-1-links
plan: "01"
subsystem: docs
tags: [readme, clash-verge, pipx, verge]

requires:
  - phase: 03-egress-verification-playbook
    provides: verification-playbook.md and VER narrative
provides:
  - 根 README 的 v1.1 导航表与 D-01～D-06 口径
affects: []

tech-stack:
  added: []
  patterns:
    - 官方 Extend URL 用引用式链接，避免与 docs/clash-verge 同行触发订阅 URL 抽检误报

key-files:
  created: []
  modified:
    - README.md

key-decisions:
  - 将 Clash Verge Extend 外链改为文末 `[clash-verge-extend]` 引用定义，满足 `grep` 抽检且保留字面 URL

patterns-established: []

requirements-completed:
  - VER-03

duration: 15 min
completed: 2026-05-04
---

# Phase 04 Plan 01: 根 README 入口链与 VER-03 叙事 — Summary

**根 README 新增「v1.1 文档与工具链」：五文档导航表、pipx/克隆纠偏、Verge 订阅+全局扩展主路径与脚本辅助定位，并链到验证手册与官方 Extend。**

## Performance

- **Duration:** 15 min
- **Started:** 2026-05-04T00:00:00Z（约）
- **Completed:** 2026-05-04
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- 满足 PLAN 中文档导航、安装路径、分流主路径三类小节及 acceptance 中的 `grep` / `test -f` 条件
- 检出并消除「官方 Extend URL + 同行 docs/clash-verge 相对链」导致的订阅 URL 模式误报（引用式链接）

## Task Commits

1. **Task 1: 根 README：新增 v1.1 导航与安装/主路径叙事** — `bcc5901` (feat)
2. **Task 2: 链接目标存在性与敏感信息抽检** — `0f9e5ed` (chore, empty)

## Files Created/Modified

- `README.md` — VER-03 入口、导航表、pipx/克隆纠偏、主路径与辅助脚本说明、Extend 引用链

## Decisions Made

- 官方 Extend 使用 Markdown reference link，定义在 `README.md` 文末，避免 `https://.../.+/(clash|subscribe)` 类抽检在同一段落误匹配 `docs/clash-verge`

## Deviations from Plan

None - plan executed exactly as written. 实施上为通过抽检对「行内 URL + 相对路径」做了等价改写（仍为同一官方 URL 与叙事）。

## Issues Encountered

- 本机无 `rg`：用 Cursor `Grep` 与 `grep -E` 完成等价验收；`grep` 抽检误报经引用式链接修复

## User Setup Required

None

## Next Phase Readiness

- Phase 4 单计划已完成；可进入阶段级验证与 ROADMAP 勾选

## Self-Check: PASSED

- `test -f` 六路径均存在；订阅 URL 模式 `grep` 无输出；标题与相对链抽检通过

---
*Phase: 04-repo-entry-v1-1-links*
*Completed: 2026-05-04*
