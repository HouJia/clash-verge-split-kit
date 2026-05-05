# Integrations

**Analysis Date:** 2026-05-03

## 外部脚本与技能（核心集成）

**`egress-ip-audit.sh`**

- **默认路径** — `~/.cursor/skills/hjs-egress-ip-audit/scripts/egress-ip-audit.sh`（`hjs_egress_ip/cli.py` 中 `resolve_audit_script`）。
- **覆盖方式** — 环境变量 `HJS_EGRESS_AUDIT_SCRIPT` 指向任意可执行脚本文件；缺失或路径无效时 CLI 以退出码 2 报错并中文提示。
- **调用方式** — Python 使用 `subprocess.run`，命令形如 `["/bin/bash", <script>, ...flags]`，`cwd` 设为脚本所在目录，以便脚本内相对路径一致。
- **透传环境** — 使用 `os.environ.copy()`；`CURL_TIMEOUT` 由 README 说明可透传给底层脚本（默认 8 秒量级，以脚本为准）。

**与包内 YAML 的关系**

- `probes.default.yaml` 注释写明与脚本内 `PROBES` 对齐；Python 在运行审计前调用 `load_default()` 做 **包内 YAML 存在性与结构校验**，实际 HTTP 探测仍由 **bash + curl** 执行，而非在 Python 内直连各 URL。

## 出站 HTTP（探测目标，由脚本发起）

以下 URL 类别来自 `hjs-egress-ip-cli/src/hjs_egress_ip/data/probes.default.yaml`（代表脚本侧会访问的站点类型；具体以技能脚本实现为准）：

- **国内 / 中文语境** — 如 `https://myip.ipip.net`、`https://cip.cc`、`http://ip.cip.cc` 等（`category: domestic`）。
- **国际通用回显** — 如 `https://ipecho.net/plain`、`https://api.ipify.org`、`https://icanhazip.com`、`https://ifconfig.me/ip`、`https://ipinfo.io/ip`、`https://checkip.amazonaws.com`、`https://ident.me` 等（`category: intl_plain`）。
- **CDN 侧观测** — 如 `https://1.1.1.1/cdn-cgi/trace`（`category: cdn_trace`，`parser: cloudflare_trace`）。
- **HTTP 元数据（JSON）** — 如 `https://httpbin.org/ip`（`category: meta`，`parser: httpbin_ip`）。

**说明：** 这些为 **用户机器对外网的出站请求**；仓库内 Python Web 层不代用户批量访问上述站点，除非用户通过 UI 触发 CLI 间接执行。

## 本地 Web UI（进程内集成）

**HTTP 服务**

- `hjs_egress_ip.web.server` 基于标准库 `HTTPServer` 绑定 **默认** `127.0.0.1:18765`（可用 CLI 参数 `--host` / `--port` 或环境变量 `HJS_AUDIT_UI_HOST`、`HJS_AUDIT_UI_PORT` 覆盖）。
- **路由** — `GET /`、`GET /index.html` 返回包内静态页；`GET /health` 返回纯文本 `ok`；`POST /api/run` 接受 JSON，内部再 `subprocess` 调用本 CLI（`--simple-tsv` 或 `--full` 等组合）。

**子进程调用链**

- `_cli_command_prefix`：优先 `HJS_EGRESS_IP_CLI` 整行命令前缀；否则 `shutil.which("hjs-egress-ip")`；再否则 `sys.executable -m hjs_egress_ip.cli`。
- `_run_cli_audit` — 与审计相同的 CLI 入口，捕获 stdout/stderr，超时上限 `MAX_RUN_SECONDS = 600`。

**浏览器**

- 默认尝试 `webbrowser.open` 打开本地 URL（`serve` 未带 `--no-open` 时）。

## 安全与限流相关集成点

- **`POST /api/run`** — `Content-Length` 上限 `MAX_POST_BODY_BYTES = 64 * 1024`（`server.py`），超限返回 413 并丢弃部分 body，避免恶意超大请求。
- **interface 名称校验** — 仅允许字母数字与 `._-`（降低命令注入面；最终仍由 CLI 传参给脚本层）。

## 无下列集成（截至本分析日）

- **无 PyPI 发布 CI** — README 占位说明 PyPI/Homebrew 在外部配置；仓库内未发现 `.github/workflows`。
- **无数据库、消息队列、第三方 OAuth** — 架构为本地 CLI + 可选本地 HTTP + 外部探测站点。
