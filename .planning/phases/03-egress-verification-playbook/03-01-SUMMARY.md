---
phase: 03-egress-verification-playbook
plan: "01"
subsystem: docs
tags:
  - clash-verge
  - hjs-egress-ip
  - verification
requires: []
provides:
  - docs/clash-verge/verification-playbook.md（VER-01 步骤骨架 + VER-02 CLI/审计 UI）
  - README 与 local-split-vps 交叉引用
affects: []
tech-stack:
  added: []
  patterns: []
key-files:
  created:
    - docs/clash-verge/verification-playbook.md
  modified:
    - docs/clash-verge/README.md
    - docs/clash-verge/local-split-vps.md
key-decisions:
  - 检查清单用四列表格对齐 Verge / CLI / 判据，满足 VER-01+02 条目化要求
patterns-established: []
requirements-completed:
  - VER-01
  - VER-02
duration: 15min
completed: 2026-05-04
---

# Phase 03：egress-verification-playbook — Plan 01 小结

**交付一份可重复的中文验证说明**，覆盖 Rule 模式下的 Verge 观察点、与 `hjs-egress-ip` 及 `serve`（18765 健康检查 `ok`）的衔接，并在 `README.md` 与 §5.4 链入该文。

## Performance

- **Duration:** ~15min（估算）
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- 新增 `verification-playbook.md`：通用步骤、两类场景、CLI/`serve`、≥4 行检查清单表。
- `docs/clash-verge/README.md` 增加 playbook 入口链接。
- `local-split-vps.md` §5.4 段末链至 playbook。

## Task Commits

1. **新建 verification-playbook.md（主体）** — `5ed1599`（docs）
2. **更新 docs/clash-verge/README.md 入口** — `1e777ab`（docs）
3. **local-split-vps.md 交叉引用 playbook** — `34b88bb`（docs）

## Plan-level verification（执行记录）

- `test -f docs/clash-verge/verification-playbook.md` → PASS
- 敏感 URL 扫描（`docs/clash-verge/` 下 `https://…/(clash|subscribe)` 模式）→ 无命中
- `verification-playbook.md` 出现在 `README.md` 与 `local-split-vps.md` → PASS（编辑器内 rg）

## Self-Check: PASSED
