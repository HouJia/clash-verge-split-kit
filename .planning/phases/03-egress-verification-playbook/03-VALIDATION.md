---
phase: 3
slug: egress-verification-playbook
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-04
---

# Phase 3 — Validation Strategy

> 本阶段以**文档与人工走查**为主；不强制新增自动化测试代码。

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | 无新增；可选 `pytest`（`hjs-egress-ip-cli`）作回归 |
| **Config file** | `hjs-egress-ip-cli/pyproject.toml`（仅当执行回归时） |
| **Quick run command** | `rg -n "verification-playbook" docs/clash-verge/README.md` |
| **Full suite command** | `cd hjs-egress-ip-cli && pytest -q`（可选） |
| **Estimated runtime** | ~5–30 秒 |

---

## Sampling Rate

- **After every task commit:** 运行 quick run + 对新增/修改的 `docs/clash-verge/*.md` 执行敏感信息 rg（见各 PLAN `acceptance_criteria`）
- **After every plan wave:** 人工通读 playbook 一节结构完整性（可选）
- **Before `/gsd-verify-work`:** Quick run 通过；可选 pytest 全绿

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 3-01-01 | 01 | 1 | VER-01 | — | 文档无真实密钥 URL | doc | `rg -n "verification-playbook.md" docs/clash-verge/README.md` | ✅ | ⬜ pending |
| 3-01-02 | 01 | 1 | VER-02 | — | 同上 | doc | `rg -n "hjs-egress-ip serve|18765" docs/clash-verge/verification-playbook.md` | ✅ | ⬜ pending |
| 3-01-03 | 01 | 1 | VER-01, VER-02 | — | 同上 | doc | `rg -n "检查清单" docs/clash-verge/verification-playbook.md` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- [ ] 无强制 Wave 0 — 现有 `hjs-egress-ip-cli/tests/` 已覆盖包行为

*本阶段不修改 CLI 时，pytest 为可选回归。*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Verge 连接视图与规则一致 | VER-01 | 需本机 GUI | 按 `verification-playbook.md` 顺序切换节点后观察 Connections |
| 审计 UI 一键检测与预期对照 | VER-02 | 需浏览器 | `hjs-egress-ip serve` 后按 playbook 表格勾选 |

---

## Validation Sign-Off

- [ ] 所有任务具备 doc 级 `acceptance_criteria` 或可观察清单
- [ ] Manual-Only 表覆盖 Verge / 审计 UI
- [ ] `nyquist_compliant: true` 在终验前由执行者按实填

**Approval:** pending
