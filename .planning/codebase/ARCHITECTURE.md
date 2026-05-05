# Architecture

**Analysis Date:** 2026-05-03

## 总体模式

**薄编排 CLI + 技能侧探测脚本 + 可选本地 Web 外壳**

- **探测与 curl 编排** 保留在全局技能目录下的 **bash 脚本**（与本仓库解耦，通过路径或环境变量接入）。
- **Python 包** 负责：参数解析、脚本路径解析、子进程执行、TSV 结果解析与分组、以及可选的 **本地 HTTP UI**（静态页 + JSON API）。

该拆分降低首版重写风险，并与 `.planning/PROJECT.md` 中「复用 bash 探测脚本」决策一致。

## 分层与模块边界

```
终端用户 / 浏览器
        │
        ▼
┌───────────────────┐
│ hjs_egress_ip.cli │  argparse；区分 serve / 审计模式
└─────────┬─────────┘
          │
   serve  │                     审计（默认 / --full / --simple-tsv）
          ▼                               ▼
┌───────────────────┐          ┌──────────────────────┐
│ web.server        │          │ subprocess + bash    │
│ HTTPServer        │          │ egress-ip-audit.sh   │
│ + static/index    │          │ （curl 在各 URL）     │
└─────────┬─────────┘          └──────────┬───────────┘
          │                               │
          │ POST /api/run ──subprocess──►│ 同上 CLI 入口
          ▼                               ▼
     JSON + TSV 文本                TSV / 分组文本（stdout）
          │
          ▼
┌───────────────────┐
│ hjs_egress_ip.    │  parse_tsv_rows / build_groups /
│ formatters        │  extract_*（snippet 解析辅助）
└───────────────────┘

┌───────────────────┐
│ hjs_egress_ip.    │  包内 YAML 校验（启动审计前）
│ probes            │
└───────────────────┘
```

## 入口点

| 入口 | 文件 | 说明 |
|------|------|------|
| 已安装 CLI | `hjs_egress_ip.cli:main` | `pyproject.toml` 中 `project.scripts` |
| 模块运行 | `python -m hjs_egress_ip.cli` | Web 服务回退调用链 |
| Web 子命令 | `hjs-egress-ip serve` | `cli.run_audit` 检测 `argv` 首段为 `serve` 时分发到 `web.server.serve_main` |

## 数据流（审计模式）

1. 用户执行 `hjs-egress-ip` 或带 `--full` / `--simple-tsv` 等标志。
2. `run_audit` 校验互斥参数（如 `--full` 与 `--simple-tsv` 不可同时使用）。
3. `load_default()` 读取并校验 `probes.default.yaml`（失败则 `sys.exit(2)`）。
4. 组装 bash 命令：`/bin/bash` + 脚本路径 + 与模式对应的参数（`--full`、`--ipv6-skip`、`--interface`、`--simple-tsv` 等）。
5. `subprocess.run` 继承环境变量，**工作目录**设为脚本所在目录。
6. 进程退出码原样返回给 shell。

## 数据流（serve 模式）

1. `serve_main` 解析 `--host` / `--port` / `--no-open`，合并环境变量覆盖默认绑定。
2. `HTTPServer` 提供静态页与 `/health`。
3. `POST /api/run` 解析 JSON body（`mode`、`ipv6_skip`、`iface`），映射为 CLI 参数列表。
4. `_run_cli_audit` 同步子进程执行 CLI，超时 600 秒；stdout 作 TSV 文本解析。
5. `mode == simple` 时 `parse_tsv_rows` + `build_groups` 生成前端可用的分组结构；`full` 模式亦返回 TSV，分组列表为空数组。
6. 统一 JSON 响应（`ok`、错误信息、截断后的 `stderr` 等）。

## 错误处理策略

- **CLI** — 配置类错误（脚本不存在、参数互斥）打印到 **stderr**，返回码 2 或 argparse 默认行为。
- **probes** — YAML 缺失、解析失败、结构不合法：中文错误到 stderr，`sys.exit(2)`。
- **Web** — HTTP 层对非法 `Content-Length`、过大 body、非法 `iface` 返回 400/413；CLI 非零返回在 JSON 中 `ok: false`（仍可能 HTTP 200 携带错误载荷，便于前端展示）。

## 与仓库其余部分的关系

- **`.planning/`** — 里程碑、路线图、验证记录；不参与运行时 import。
- **`vpn-reality-guides/`、`旧内容-可能过期了/`** — 文档与演示资产，与 pip 包独立。
