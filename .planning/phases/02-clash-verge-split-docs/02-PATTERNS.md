# Phase 2 — Pattern Map（PATTERNS.md）

从 CONTEXT / RESEARCH 抽取的「可对齐实现」与仓库内参照。

---

## 文件与角色

| 路径 | 角色 | 参照实现 |
|------|------|----------|
| `docs/clash-verge/local-split-vps.md` | 自用中文说明 | 已存在；与 ROADMAP 成功标准对齐时需补「合并脚本」一节 |
| `verge/extend/global-split.yaml` | 脱敏扩展主片段 | `rules` / `proxy-groups` / `dns` 全量在此；合并脚本应 **overlay** 到订阅顶层 |
| `verge/scripts/fetch_subscription_nodes.py` | 订阅拉取 | `urllib` + `Path`；错误码 2 = 缺 URL |
| `verge/scripts/render_global_split.py` | 占位符替换 | `YOUR_VPS_IP` 单点替换 |
| `hjs-egress-ip-cli/pyproject.toml` | Python 打包范式 | Phase 2 **不必**把 verge 并入该包；可独立 `pytest` |

---

## 合并逻辑（拟新增）

- **输入：** 订阅 YAML（`proxies`, `proxy-groups`, 可选 `rules`）+ 扩展 YAML（本仓库 extend）。
- **输出：** 单文件 `merged.profile.yaml`（路径 `verge/out/`，gitignored）。
- **规则：** 默认 **最终 `rules` 来自扩展**；订阅 `proxies`/`proxy-groups` 保留；`dns`/`geodata-mode`/`sniffer`/`geox-url` 以扩展为准（与 Verge「全局扩展覆盖」一致）。

---

## PATTERN MAPPING COMPLETE
