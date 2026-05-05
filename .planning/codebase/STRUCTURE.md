# Repository Structure

**Analysis Date:** 2026-05-03

## 顶层布局

| 路径 | 角色 |
|------|------|
| `README.md` | 仓库入口说明；指向 CLI、`verge/`、`docs/clash-verge/` 与 `.planning/`。 |
| `hjs-egress-ip-cli/` | **可安装 Python 包**根目录（`pyproject.toml`、`src/`、`tests/`）。 |
| `verge/` | Clash Verge：全局扩展 YAML、脱敏模板、可选脚本、`out/` 本机输出（订阅拉取，勿提交）。 |
| `docs/clash-verge/` | 自用分流说明与 FAQ。 |
| `.planning/` | GSD 规划：`PROJECT.md`、`ROADMAP.md`、`MILESTONES.md`、`milestones/`、`codebase/`、`spikes/` 等。 |
| `.cursor/skills/`（若存在） | 可能含与本项目交叉引用的技能说明；**默认脚本路径**在 `cli.py` 中指向用户主目录下全局技能。 |
| `vpn-reality-guides/` | VPN 现实向指南与 Netlify 风格静态 PPT 等；**非** `hjs-egress-ip` 包的一部分。 |
| `旧内容-可能过期了/` | 历史 PPT、issue 相关素材；标注可能过期。 |

## Python 包：`hjs-egress-ip-cli/`

```
hjs-egress-ip-cli/
├── pyproject.toml          # 项目元数据、依赖、pytest/setuptools 配置
├── setup.py                # 兼容旧 pip 的 setuptools 入口
├── README.md               # 安装、手动验证、环境变量、构建说明
├── tests/
│   └── test_formatters.py  # formatters 单元测试
├── src/
│   └── hjs_egress_ip/
│       ├── __init__.py     # __version__
│       ├── cli.py          # CLI 主入口、serve 分发、bash 调用
│       ├── formatters.py   # TSV 解析、分组、snippet 提取
│       ├── probes.py       # 包内 probes YAML 加载与校验
│       ├── data/
│       │   ├── __init__.py
│       │   └── probes.default.yaml   # 内置探测表（package-data）
│       └── web/
│           ├── __init__.py
│           ├── server.py               # HTTPServer、/api/run
│           └── static/
│               └── index.html          # 本地审计 UI（package-data）
├── dist/                   # 构建产物目录（若执行过 build）
└── .venv/                  # 本地虚拟环境（不应提交；映射时忽略）
```

## 命名约定

- **Python 包名** — `hjs_egress_ip`（下划线），符合 PEP 8 模块名。
- **发行名 / CLI 命令** — `hjs-egress-ip`（连字符），在 `pyproject.toml` 的 `name` 与 `project.scripts` 中一致。
- **环境变量前缀** — `HJS_*`（如 `HJS_EGRESS_AUDIT_SCRIPT`、`HJS_EGRESS_IP_CLI`、`HJS_AUDIT_UI_HOST`），用于跨进程配置。
- **测试文件** — `test_*.py` 置于 `tests/`，与 `pytest` 默认发现一致。

## 关键文件速查

| 需求 | 首选路径 |
|------|-----------|
| 改 CLI 行为 /  flags | `hjs-egress-ip-cli/src/hjs_egress_ip/cli.py` |
| 改 Web API 或绑定 | `hjs-egress-ip-cli/src/hjs_egress_ip/web/server.py` |
| 改探测点列表（与脚本对齐） | `hjs-egress-ip-cli/src/hjs_egress_ip/data/probes.default.yaml` + 技能脚本内同源数据 |
| 改输出分组 / TSV 解析 | `hjs-egress-ip-cli/src/hjs_egress_ip/formatters.py` |
| 改前端展示 | `hjs-egress-ip-cli/src/hjs_egress_ip/web/static/index.html` |
| 依赖与版本 | `hjs-egress-ip-cli/pyproject.toml` |

## `.planning/` 中与代码协作的文档

| 路径 | 用途 |
|------|------|
| `.planning/PROJECT.md` | 项目目标、状态、关键决策摘要。 |
| `.planning/ROADMAP.md` | 阶段与路线图。 |
| `.planning/milestones/v1.0-phases/01-hjs-egress-ip-cli-tool/` | v1.0 计划、审查、验证与摘要。 |
| `.planning/codebase/*.md` | 本目录；代码库地图。 |
