---
phase: 02-clash-verge-split-docs
plan: "03"
subsystem: tooling
tags: [python, yaml, pytest, clash-verge]

requires: []
provides:
  - merge_subscription_with_extend.py CLI
  - fetch_subscription_nodes.py --dry-run
  - verge/tests pytest 覆盖
affects: []

tech-stack:
  added: [PyYAML, pytest]
  patterns: [CLI 退出码 3 表示策略组缺失]

key-files:
  created:
    - verge/scripts/merge_subscription_with_extend.py
    - verge/requirements-dev.txt
    - verge/tests/test_merge_subscription_with_extend.py
    - verge/tests/test_fetch_subscription_nodes.py
  modified:
    - verge/scripts/fetch_subscription_nodes.py
    - verge/README.md
    - docs/clash-verge/local-split-vps.md

key-decisions:
  - 扩展 proxy-groups 中与订阅同名的不覆盖，仅追加新组名，以满足扩展 rules 引用

patterns-established: []

requirements-completed: [CV-03, CV-04]

duration: 45min
completed: 2026-05-04
---

# Phase 02：Plan 03 小结

**可选「订阅 + 扩展 → 单文件」合并 CLI 已落地，配套 pytest 与 fetch `--dry-run`；文档与 README 已引用。**

## Task Commits

1. **merge CLI + PyYAML** — `c1fc1bf`
2. **fetch --dry-run + pytest** — `ce1eb28`
3. **文档与 README** — `63ac996`

## Accomplishments

- `merge_subscription_with_extend.py`：`--subscription` / `--extend` / `-o` / `--keep-subscription-rules`，组名缺失时退出码 3。
- `fetch_subscription_nodes.py --dry-run`：仅校验 URL scheme，不发起请求。
- `verge/tests/`：合并默认/保留订阅规则/退出码 3/扩展组追加；fetch mock 与 dry-run。

## Self-Check: PASSED

- `python3 -m pytest verge/tests -q` 通过。
- `merge_subscription_with_extend.py --help` 含 `--keep-subscription-rules`。

## Deviations

- 无
