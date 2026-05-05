# Technology Stack

**Analysis Date:** 2026-05-03

## Languages

**Primary**

- **Python** — `requires-python >= 3.9`（`hjs-egress-ip-cli/pyproject.toml`）。应用与测试代码均在此版本及以上运行。
- 包布局为 **src layout**：可安装包源码在 `hjs-egress-ip-cli/src/hjs_egress_ip/`。

**Secondary / 周边**

- **Markdown** — 仓库根 `README.md`、`hjs-egress-ip-cli/README.md`、`.planning/` 下规划与里程碑文档。
- **YAML** — 内置探测表 `hjs-egress-ip-cli/src/hjs_egress_ip/data/probes.default.yaml`（随包分发，由 `pyyaml` 解析）。
- **HTML / CSS / JavaScript** — 本地审计 UI 静态页 `hjs-egress-ip-cli/src/hjs_egress_ip/web/static/index.html`（由 `importlib.resources` 读取）。
- **Shell（运行时依赖）** — CLI 通过 `/bin/bash` 调用外部 `egress-ip-audit.sh`（见 `hjs-egress-ip-cli/src/hjs_egress_ip/cli.py`），非 Python 实现探测本身。

## Runtime

- **CPython 3.9+** — 开发与安装目标环境。
- **Bash** — 与技能脚本一致，探测逻辑在 `egress-ip-audit.sh` 内；本仓库 Python 层负责参数拼接与子进程。
- **curl** — 底层脚本假设本机可用（`hjs-egress-ip-cli/README.md` 手动验证步骤）。

## Build & Packaging

- **setuptools** — `[build-system]` 使用 `setuptools.build_meta`；`[tool.setuptools.packages.find]` 中 `where = ["src"]`。
- **wheel** — 与 setuptools 一并列为构建依赖。
- **兼容入口** — `hjs-egress-ip-cli/setup.py` 为旧版 pip 可编辑安装的薄封装，实际配置以 `pyproject.toml` 为准。
- **构建工具（开发可选）** — `build>=1` 列在 `[project.optional-dependencies].dev`；README 说明使用 `python -m build` 生成 `dist/`。

## Application Dependencies

**运行时（`[project].dependencies`）**

- **PyYAML >= 6** — 在 `hjs_egress_ip.probes.load_default` 中 `yaml.safe_load` 读取包内 `probes.default.yaml`。

**开发可选（`dev` extra）**

- **pytest >= 7** — 单元测试；配置见 `[tool.pytest.ini_options]`：`testpaths = ["tests"]`，`pythonpath = ["src"]`。
- **build >= 1** — 打 wheel/sdist。

## CLI 与入口

- **控制台脚本** — `[project.scripts]`：`hjs-egress-ip = hjs_egress_ip.cli:main`。
- **模块入口** — Web 服务侧通过 `python -m hjs_egress_ip.cli` 形式调用（`hjs_egress_ip/web/server.py` 中 `_cli_command_prefix` 的回退路径）。

## 标准库使用（要点）

- `argparse` — CLI 与子命令 `serve` 的参数解析（`cli.py`、`web/server.py`）。
- `subprocess` — 调用 bash 审计脚本与 UI 触发的 CLI 子进程。
- `http.server.HTTPServer` / `BaseHTTPRequestHandler` — 本地 HTTP 服务，无第三方 ASGI/WSGI 框架。
- `importlib.resources` — 读取包内静态 HTML 与 YAML。
- `csv`、`json`、`io`、`re`、`urllib.parse` — TSV 解析、JSON API、路径解析等（`formatters.py`、`server.py`）。

## 版本与元数据

- 包版本 **0.1.0** — `pyproject.toml` 与 `hjs_egress_ip/__init__.py` 中 `__version__` 一致。

## 仓库中非 Python 交付物

- **vpn-reality-guides/**、`旧内容-可能过期了/` — 历史或演示用静态站点与素材，与 `hjs-egress-ip` 包无直接构建依赖。
- **.planning/** — GSD 规划产物，不参与 pip 安装。
