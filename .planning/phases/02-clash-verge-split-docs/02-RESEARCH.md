# Phase 2 — Technical Research（clash-verge-split-docs）

**问题：** 为规划 CV-01～CV-04，需要弄清 mihomo/Clash Verge 的配置合并语义、仓库内已有脚本边界，以及可验证的交付形态。

---

## 1. Clash Verge Extend 与「单文件」差异

- **官方 Extend 链**（全局扩展 YAML → … → 订阅）：适合日常；订阅负责 `proxies`/`proxy-groups` 更新，全局扩展覆盖 `dns`/`geodata`/`sniffer`/`rules`（及本仓库在扩展中声明的 `proxy-groups` 结构）。
- **单文件合并产物**：便于备份、离线核对、CI 外对比；需用 YAML 合并策略明确 **订阅内已有 `rules` 与扩展 `rules` 谁优先**（CONTEXT D-15）。本阶段推荐默认：**扩展规则全量作为最终 `rules`**，可选开关保留订阅规则（文档写清行为，避免 silent 失效）。

## 2. 策略组名对齐（D-15）

- `verge/extend/global-split.yaml` 使用 **`🌍 节点选择`** 等具名组；订阅面板导出的组名可能不同。
- 合并工具应支持 **`--primary-group` 或映射表**：将规则中引用的「主代理组」与订阅中实际「全节点汇总组」对齐；若不对齐，mihomo 会引用不存在的组导致启动/重载失败。

## 3. 现有脚本与缺口

| 脚本 | 现状 | 缺口 |
|------|------|------|
| `verge/scripts/fetch_subscription_nodes.py` | URL → `verge/out/fetched.yaml` | 缺单元测试；Windows 上 `python3` 文案需与 `py` 启动器对照说明 |
| `verge/scripts/render_global_split.py` | `YOUR_VPS_IP` → `out/global-split.for-verge.yaml` | 同上；错误信息已可用 |
| 合并 | **未实现** | 需新脚本或子命令：订阅 + `extend/global-split.yaml`（或已渲染 IP 的片段）→ `verge/out/merged.profile.yaml` |

## 4. 验证与 Nyquist（执行期）

- **可自动化：** 对合并脚本做 **离线 fixture**（脱敏最小 `proxies` + `proxy-groups` + 两行 `rules`）断言输出 YAML 键序/字段存在、`rules` 条数、组名解析。
- **不可自动化（本阶段）：** 真实 Verge 内「当前配置」观察；留给 Phase 3 playbook 引用自检要点（CONTEXT 已defer）。

## 5. 跨平台（CV-04）

- 优先 **Python 3.9+ 标准库 + PyYAML（若引入）**；`pipx` 与裸 `python3` 两种路径在文档中并列。
- Windows：说明 `py -3`、`UTF-8` 控制台、路径分隔符；脚本一律 `pathlib`。

---

## Validation Architecture

**维度 8（反馈采样）：** 本阶段在 Wave 0/任务级以 **Python 离线测试** 为主，覆盖 `verge/scripts/` 下新增合并逻辑与对现有拉取脚本的回归；**不**将「启动 Clash Verge」纳入自动化门禁。

| 维度 | 策略 |
|------|------|
| 测试框架 | `pytest`（可在仓库根或 `verge/scripts/` 旁新增 `tests/` 小套件，不强制并入 `hjs-egress-ip-cli` 包） |
| 快速命令 | `pytest verge/tests -q`（路径以 PLAN 落盘为准） |
| 全量命令 | 同快速命令（本阶段体量小） |
| 手工 | 作者本机：Extend 主路径 + 可选 `merged.profile.yaml` 导入核对 |

**门禁：** 每个修改 `verge/scripts/*.py` 的 task 须在 `<acceptance_criteria>` 中给出可 `pytest` 或 `python -m compileall` 复核的条件；合并行为须有 **fixture YAML** 断言。

---

## RESEARCH COMPLETE

本研究结论已足够进入 PLAN：主路径继续 **Verge Extend**；补充 **可选单文件合并脚本** + **文档/模板/跨平台** 收口 CV-01～CV-04。
