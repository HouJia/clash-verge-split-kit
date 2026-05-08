# airport — 项目说明（v1.0 后）

## 这是什么

将全局 Cursor 技能 **hjs-egress-ip-audit** 中的探测脚本演进为可独立安装的 Python CLI **`hjs-egress-ip`**（目录 `hjs-egress-ip-cli/`），与 IDE 解耦；可选本地 Web 审计 UI（`serve`）。

## 核心价值

一键按站点类型梳理出口 IP 探测结果；`--full` 保留完整矩阵能力。

## 当前里程碑：v1.1 Clash Verge 分流与验证（已完成）

**Validated in Phase 2–4（2026-05-04）：** 在**不把真实订阅密钥写进公开 Git** 的前提下，已交付自用说明、`verge/` 扩展分流模板与 Bash 粘贴稿生成脚本、跨平台文档、与 `hjs-egress-ip` 对齐的验证 playbook，以及**根 [`README.md`](../README.md) 入口**（VER-03：`pipx` 叙事链至子目录、Verge Extend 主路径）。

## 当前状态（仓库）

- **已发布版本：** v1.0（标签 `v1.0`）— CLI 与审计 UI 已交付
- **v1.1 交付：** Phase 2–4 已完成；入口见根 `README.md` 中「v1.1 文档与工具链」；验证见 [`docs/clash-verge/verification-playbook.md`](../docs/clash-verge/verification-playbook.md)
- **技术栈：** Python 3.9+、setuptools、PyYAML、标准库 `http.server`
- **主要路径：** `hjs-egress-ip-cli/src/hjs_egress_ip/`（CLI、`formatters`、`web`、`data/probes.packaged.json`）；`verge/scripts/render-local.sh` + `.cursor/hooks/` / `.githooks/`（扩展 `*-rule-split-extend.yaml` → 成对的 `verge/generated/*-rule-split.local.yaml`）；本机覆写 **`verge/generated/local/override.local.ini`**（示例见同目录 **`*.example`**，根 `.gitignore` 约定）
- **质量：** `pytest` 覆盖解析与分组；v1.0 审查 Warning 已闭环
- **v1.0 规划归档：** `.planning/milestones/v1.0-phases/01-hjs-egress-ip-cli-tool/`

## 需求

### 已验证（v1.0）

- 独立可安装 CLI，与技能脚本行为对齐（默认一键 / `--full`）
- 外置 YAML 探测表与文档
- 基础自动化测试与 README 手动验证说明
- 可选 `serve` 与打包路径正确
- 技能文档与仓库入口交叉引用

### 已验证（v1.1，里程碑级）

- 分流文档、`verge` 自动化与验证 playbook、根 README 链（细节与条目化状态见 `.planning/REQUIREMENTS.md`）。

### 明确不做（当前）

- 不在本仓库内复制全局技能路径为硬依赖；以 `pipx` / 包安装为第一入口。
- 不维护真实订阅、节点或商业机场信息；示例须脱敏。

## 关键决策

| 决策 | 结果 |
|------|------|
| PyPI 风格包 + `project.scripts` 注册入口 | 采用，便于 `pip install` / `pipx` |
| 复用 bash 探测脚本（子进程列表参数） | 采用，降低首版重写风险 |
| 静态 UI 随包分发（`importlib.resources`） | 采用 |

## 约束

- 本地 UI 默认绑定 `127.0.0.1`；`/api/run` 请求体大小受限（64KiB）以降低误用面。
- Clash Verge 相关交付：**自动化合并产物** + 自用说明 + 脱敏骨架；客户端行为以本机安装版本为准。

## Evolution

本文档在阶段切换与里程碑边界上持续更新。

**每次阶段切换后（`/gsd-transition`）：**

1. 需求失效？→ 移入「明确不做」并写明原因  
2. 需求已验证？→ 移入「已验证」并标注阶段  
3. 新需求？→ 写入「进行中」  
4. 新决策？→ 追加「关键决策」  
5. 「这是什么」是否仍准确？→ 漂移则改写  

**每次里程碑结束后（`/gsd-complete-milestone`）：**

1. 通读各节  
2. 核对「核心价值」是否仍为第一优先级  
3. 复核「明确不做」理由是否仍成立  
4. 用当前事实更新上下文描述  

---

*最后更新：2026-05-04（v1.1 Phase 2–4 完成，含根 README / VER-03）*
