# Phase 4: repo-entry-v1-1-links - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-04
**Phase:** 4-repo-entry-v1-1-links
**Areas discussed:** pipx / 包安装叙事（根 README）

---

## pipx / 包安装叙事

| Option | Description | Selected |
|--------|-------------|----------|
| A | 根给最短可复制 `pipx` 命令 + 深链子 README | |
| B | 根只声明推荐 `pipx` + 链 `hjs-egress-ip-cli/README.md`，不写命令 | ✓ |
| C | 交由实现再选 | |

**User's choice:** B

**Notes:** 满足 VER-03 时由子文档承载具体命令；根保持短。

---

### 问题 2：克隆 vs 已安装

| Option | Description | Selected |
|--------|-------------|----------|
| A | 根单独一句：克隆 ≠ 已安装；须按子目录 `pipx`/`pip`（根不展开命令） | ✓ |
| B | 仅靠表格/链接暗示 | |

**User's choice:** A

---

### 问题 3：CLI 与 `verge/` 脚本叙事

| Option | Description | Selected |
|--------|-------------|----------|
| A | 分两句：CLI `pipx`；`verge/` 脚本单独链 | |
| B | 一句泛化：Python 3.9+、`pipx`，细节见两子 README | ✓ |
| C | 交由实现 | |

**User's choice:** B

**后续纠正（同日）：** 用户强调 Verge **内置扩展/覆写**为规则进最终配置的主路径；Python 脚本非默认心智模型。已在 CONTEXT **D-03 + D-05 / D-06** 中收紧，避免「一句泛化」被误读为「分流靠跑脚本」。

---

### 问题 4：未上 PyPI 时的表述

| Option | Description | Selected |
|--------|-------------|----------|
| A | 根不点名「从仓库路径安装」 | |
| B | 根加半句：若尚未从索引安装，可从本仓库包目录按子文档安装（仍不贴命令） | ✓ |
| C | 交由实现 | |

**User's choice:** B

---

## 收尾

- 用户选择 **结束区域 3**，未讨论灰区 1、2、4（README 架构、必链清单、「快速分流」段落关系）。
- **用户纠正：** 订阅在 Verge 内导入/刷新；分流与策略经 **Verge 扩展与覆写**进入最终配置，**非**以 Python 自建一套为默认 — 写入 CONTEXT **D-05 / D-06**。

## Claude's Discretion

（无）

## Deferred Ideas

- 根 README 信息架构、完整链接集合与顺序、与「快速分流」段落关系 — 留待 Phase 4 规划在 VER-03 内裁定。
