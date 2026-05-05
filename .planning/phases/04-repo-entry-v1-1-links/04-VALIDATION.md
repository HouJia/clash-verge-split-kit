---
phase: 4
slug: repo-entry-v1-1-links
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-04
---

# Phase 4 — Validation Strategy

> 文档阶段：以 shell 检查与 `rg` 为主，无单测框架。

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | 无 — 使用 `bash` + `rg` + `test` |
| **Config file** | 无 |
| **Quick run command** | `rg -n "https://[a-zA-Z0-9.-]+/.+/(clash|subscribe)" README.md || true` |
| **Full suite command** | 对 `README.md` 内链目标逐条 `test -f`（见计划 `<verification>`） |
| **Estimated runtime** | ~5 秒 |

---

## Sampling Rate

- **After every task commit:** Quick `rg`（敏感 URL 模式）
- **After every plan wave:** 全量 `test -f` 链接目标
- **Before `/gsd-verify-work`:** 上述两项通过 + 人工通读根 README
- **Max feedback latency:** 10 秒

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 4-01-01 | 01 | 1 | VER-03 | T-4-01 / — | 根 README 无真实订阅 URL | rg | `rg -n "https://[a-zA-Z0-9.-]+/.+/(clash|subscribe)" README.md \|\| true` | ✅ | ⬜ pending |
| 4-01-02 | 01 | 1 | VER-03 | — | N/A | shell | 计划内 `test -f` 链接目标列表 | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- 无 — 本阶段不引入新测试目录；现有基础设施不适用。

*Existing infrastructure: N/A for doc-only phase.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 根 README 叙事是否误导「Python 合并为默认主路径」 | VER-03 + D-05/D-06 | 需人读语义 | 通读「快速分流」「v1.1」段：主路径为 Verge 订阅 + 全局扩展粘贴；脚本为可选辅助 |
| Markdown 渲染与表格可读性 | VER-03 | IDE/渲染差异 | 在编辑器预览中检查新增小节 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references — N/A
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
