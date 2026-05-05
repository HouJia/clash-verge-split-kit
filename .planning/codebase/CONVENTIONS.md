# Conventions

**Analysis Date:** 2026-05-03

## Python 版本与语法

- **最低版本** — 3.9（`pyproject.toml` 中 `requires-python`）。
- **`from __future__ import annotations`** — 在 `cli.py`、`formatters.py`、`probes.py`、`server.py`、`tests/test_formatters.py` 中使用，便于类型注解前向引用与统一风格。

## 类型与命名

- **模块 / 函数** — `snake_case`（如 `resolve_audit_script`、`parse_tsv_rows`、`serve_main`）。
- **常量** — 模块级全大写 + 下划线（如 `MAX_POST_BODY_BYTES`、`GROUP_ORDER`、`MAX_RUN_SECONDS`）。
- **类型注解** — 在公共函数参数与返回值上使用（如 `-> int`、`-> list[dict[str, str]]`）；复杂结构使用 `typing`（如 `list[dict[str, Any]]`）。

## CLI 与用户可见字符串

- **面向用户的错误与提示** — 使用 **简体中文**（如「错误: 未找到 egress-ip-audit.sh」「提示: --ipv6-skip …」），与 README 一致。
- **argparse** — `prog="hjs-egress-ip"`；`description` / `epilog` 中文说明子命令 `serve`。
- **退出码** — 配置与校验错误倾向使用 **2**（与 `sys.exit(2)` 及 `return 2` 一致）；脚本子进程返回码透传。

## 错误处理模式

- **快速失败** — 脚本路径无效、YAML 非法、互斥参数：打印 **stderr** 后退出，不抛未捕获异常到顶层（`probes.py`、`cli.py`）。
- **Web 层** — 尽量将异常转为 JSON `ok: false`；`subprocess.TimeoutExpired` 映射为 504 与明确中文 `error` 字段。

## I/O 与编码

- **子进程** — `_run_cli_audit` 使用 `text=True` 与默认 UTF-8 解码策略处理 CLI 输出。
- **静态资源** — `index.html` 声明 `charset=utf-8`；`read_bytes` / `read_text(encoding="utf-8")` 读取包内文件。
- **JSON API** — `json.dumps(..., ensure_ascii=False)` 保留中文键值展示。

## 日志

- **HTTP** — 自定义 `Handler.log_message` 写入 **stderr**，格式类似通用访问日志。

## 依赖边界

- **不在 Python 内直接 curl** — 网络探测交给 bash 脚本；`formatters` 仅处理 **已得** TSV 文本。
- **资源路径** — 包内数据使用 `importlib.resources.files(...)`，避免硬编码仓库根相对路径，便于安装后运行。

## 测试代码风格

- **pytest 风格** — 文件 `tests/test_formatters.py`，函数名 `test_*`，断言直接使用 `assert`。
- **无 class 嵌套** — 当前测试均为函数式用例，便于快速阅读。

## 文档与注释

- **模块 docstring** — 简短英文或中英混合一句话说明职责（如 `"""CLI entry: ..."""`）。
- **行内注释** — 关键安全行为（如丢弃 body、interface 校验）配有中文说明。
