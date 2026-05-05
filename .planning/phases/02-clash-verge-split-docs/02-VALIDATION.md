---
phase: 2
slug: clash-verge-split-docs
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-04
---

# Phase 2 — Validation Strategy

> 本阶段以 **离线脚本测试** 为主；Clash Verge 内省留在 Phase 3。

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest |
| **Config file** | `pyproject.toml` 或 `verge/pytest.ini`（以 PLAN 创建为准；若仅用 `python -m pytest` 默认发现也可） |
| **Quick run command** | `pytest verge/tests -q` |
| **Full suite command** | `pytest verge/tests` |
| **Estimated runtime** | ~5–30 seconds |

---

## Sampling Rate

- **After every task commit:** `pytest verge/tests -q`（若该 task 触及 `verge/scripts/` 或测试目录）
- **After every plan wave:** `pytest verge/tests`
- **Before `/gsd-verify-work`:** 全绿（若本阶段已挂接 verify-work）
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 2-01-01 | 01 | 1 | CV-01 | — | 文档不泄露真实 URL | manual grep | `rg -n "https://.*/(clash|sub)" docs/clash-verge verge/templates || true` | ⬜ | ⬜ pending |
| 2-02-01 | 02 | 1 | CV-02 | — | 模板无真实密钥 | manual grep | `rg -n "uuid:|password:" verge/templates` 应无真实值 | ⬜ | ⬜ pending |
| 2-03-01 | 03 | 2 | CV-03 | T-2-01 | 订阅 URL 仅 env/CLI | unit | `pytest verge/tests -q` | ⬜ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `verge/tests/` — 合并与拉取脚本的 fixture
- [ ] `pytest` 可在 CI/本机一键运行（文档中写明）

*若 PLAN 选择零依赖：至少 `python -m compileall verge/scripts` 作为 Wave 0 兜底。*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Verge 导入合并产物 | CV-03 | 需本机 GUI | 全局扩展或导入 `merged.profile.yaml` 后，在「当前配置」中确认 `rules` 含 GEOSITE cn 链 |
| Windows 路径 | CV-04 | OS 差异 | 在 Windows 上执行文档中的 `py -3` 命令各一次 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
