---
phase: 04-repo-entry-v1-1-links
status: passed
verified: 2026-05-04
---

# Phase 4 — Verification

## Goal（来自 ROADMAP）

根 `README` 链向 v1.1 文档集合，澄清 `pipx`/安装路径与分流主路径（VER-03），相对链接有效。

## Must-haves（对照 PLAN 04-01）

| 条目 | 证据 | 结果 |
|------|------|------|
| 根 README 含指向五份文档的相对 Markdown 链 | `README.md` 文档导航表 | ✓ |
| pipx 叙事 + 安装命令仅在子 README | 安装路径段 + 无行首 `pip install`/`pipx install` | ✓ |
| 仅克隆 / 不等于已安装 | 正文「仅克隆」「并不意味着已安装」 | ✓ |
| Verge 订阅 + 全局扩展为主路径；scripts 辅助非必需前置 | 「分流与验证主路径」段 | ✓ |
| 无真实订阅 URL 模式 | `grep -nE 'https://[a-zA-Z0-9.-]+/.+/(clash|subscribe)' README.md` 无输出 | ✓ |
| 导航链目标存在 | `test -f` 六路径 + `verge/extend/global-split.yaml` | ✓ |

## 执行的自动化命令（复验）

```bash
test -f docs/clash-verge/README.md docs/clash-verge/local-split-vps.md \
  docs/clash-verge/verification-playbook.md hjs-egress-ip-cli/README.md \
  verge/README.md verge/extend/global-split.yaml
grep -nE '^[[:space:]]*(pipx|pip)[[:space:]]+install' README.md   # 期望无输出
grep -nE 'https://[a-zA-Z0-9.-]+/.+/(clash|subscribe)' README.md || true  # 期望无输出
```

## 回归

- `hjs-egress-ip-cli`：`python3 -m pytest -q` — 6 passed（与 Phase 4 文档变更无冲突）

## human_verification

无（本阶段为文档入口）。

## Gaps

无。

## 结论

**status: passed** — VER-03 与 D-01～D-06 在根 README 中可追溯；链接可解析；抽检无订阅 URL 误报路径。
