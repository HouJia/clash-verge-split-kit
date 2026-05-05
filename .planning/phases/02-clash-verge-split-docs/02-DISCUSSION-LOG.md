# Phase 2: clash-verge-split-docs - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-03
**Phase:** 2-clash-verge-split-docs
**Areas discussed:** 文档位置与可发现性, 叙述深度与术语, 示例形态与分流模式, 机场订阅与敏感信息边界

---

## 文档位置与可发现性

| Option | Description | Selected |
|--------|-------------|----------|
| 顶层 `docs/clash-verge/` | 与 CLI 包分离，便于 Phase 4 README 链入 | ✓ |
| 仅 `.planning` 或仅 CLI README | 可发现性或与 v1.1 文档边界不清 | |

**User's choice:** 全选讨论项；补充场景为多订阅 + 自建 DO，需国内直连与海外走自建。
**Notes:** 采用 `docs/clash-verge/` 为主交付路径；Phase 4 再更新根入口。

---

## 叙述深度与术语

| Option | Description | Selected |
|--------|-------------|----------|
| 实操向 + mihomo/Meta 术语对照 | 匹配 Clash Verge + Meta 内核用户 | ✓ |
| 纯新手百科 | 与「已会导入订阅」前提略重复 | |

**User's choice:** 需结合业界最佳实践（用户提及 SS-Rule-Snippet、自行调研期望）。
**Notes:** CONTEXT 锁定：中文 + 界面用词为主，内核处标注 mihomo/Meta；写明 GeoSite/GEOIP 主流顺序。

---

## 示例形态与分流模式

| Option | Description | Selected |
|--------|-------------|----------|
| 独立脱敏 YAML + GeoSite/GeoIP 主示例 | 满足 CV-02，与仓库现有模板一致 | ✓ |
| 仅进程级或仅 DOMAIN 列表 | 不满足「至少一种」或维护成本过高作为主路径 | |

**User's choice:** 希望直接得到可落地配置与验证结论；代理环境无法代操作，改为模板 + 自检步骤。
**Notes:** 仓库模板与 Meta 社区常见 `GEOSITE,cn` / `geolocation-!cn` / `GEOIP,cn` / `MATCH` 一致；SS-Rule-Snippet 作 DOMAIN 片段参考。

---

## 机场订阅与敏感信息边界

| Option | Description | Selected |
|--------|-------------|----------|
| 概念 + Merge/操作级步骤 + 细占位符清单 | 可落地且合规 | ✓ |
| 仅概念不写操作 | 无法解决多订阅合并痛点 | |

**User's choice:** 三机场 + 一自建；曾粘贴真实节点字段（应在文档外轮换）。
**Notes:** 交付物禁止真实订阅与密钥；核对清单写入 CONTEXT。

---

## Claude's Discretion

- 截图与图示打码；示例命名与现有 `PROXY`/`DIRECT` 结构保持一致。

## Deferred Ideas

- 本机 Clash Verge 实机验证由用户在 Rule 模式下按自检步骤完成；Phase 3 承接与 `hjs-egress-ip` 对齐的验证 playbook。

---

## 2026-05-04 补充：用户本机 Verge profile 结构对照

**触发：** 用户提供 Clash Verge `profiles` 下单个 YAML 路径，要求对照说明「仓库配置文件应如何写」。

**结论（写入 CONTEXT D-10～D-12）：**

| 维度 | 用户本机合并 profile（SS-Rule-Snippet / 订阅转换典型形态） | 仓库 `clash-verge-do-split.yaml`（CV-02） |
|------|-------------------------------------------------------------|------------------------------------------|
| 规则体量 | 大量 `DOMAIN`/`DOMAIN-KEYWORD` 行 + 多策略组（AI/Youtube/广告等） | 短规则 + `GEOSITE`/`GEOIP` + `MATCH` |
| 规则尾部 | `GEOIP,CN → 全球直连`，`MATCH → 🕹 规则之外` | `GEOIP,cn,DIRECT`，`MATCH,PROXY` |
| 节点来源 | 机场 `proxies` 已内联 | 仅自建占位 `MY-VLESS-DO` |
| 入库 | **禁止**（含真实凭据与订阅元数据） | **仅**脱敏模板 |

**安全备注（审计）：** 该类 profile 常含订阅链接与节点密钥；若曾进入对话上下文，作者侧应按 CONTEXT D-09/D-12 轮换，且不在仓库中保存原文。

---

## 2026-05-04：口径统一为「自用工具说明」

- Phase 2 交付物从「对外可读教程」调整为 **作者自用说明 + 脱敏模板**；`PROJECT.md` / `REQUIREMENTS.md` / `ROADMAP.md` / `02-CONTEXT.md` 已同步。
- 主说明文件：`docs/clash-verge/local-split-vps.md`；**不**做截图级对外教程。

---

## 2026-05-04：里程碑产物 — 订阅 URL 自动化合并 + 跨平台

- 用户期望：在本机更新机场 **HTTPS 订阅 URL** 后，经**自动化**生成**已含分流规则**、可直接导入 Clash Verge 的配置，**无额外手工合并步骤**；并可在 **macOS / Windows** 多台机器复用。
- 已写入 `REQUIREMENTS.md` **CV-03、CV-04**，`PROJECT.md` / `ROADMAP.md` Phase 2 成功标准，`02-CONTEXT.md` **D-13～D-15**，`local-split-vps.md` 里程碑目标段；**不**在仓库记录真实订阅链接。
