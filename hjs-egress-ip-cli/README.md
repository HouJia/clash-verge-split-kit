# hjs-egress-ip

本目录为 **独立可安装的出口 IP 探测 CLI**（Python 包名 `hjs-egress-ip`），与 Cursor 全局技能 `~/.cursor/skills/hjs-egress-ip-audit/` 解耦：默认行为与技能内 `egress-ip-audit.sh` 对齐，便于用 `pipx` 或虚拟环境分发。

## 与全局技能的关系

- **技能**：在 IDE 内提供说明、快捷入口与（可选）脚本路径。
- **本 CLI**：安装后可在任意终端执行 `hjs-egress-ip`，不依赖 Cursor。首版通过子进程调用技能目录下的 `egress-ip-audit.sh`（可用环境变量 `HJS_EGRESS_AUDIT_SCRIPT` 覆盖脚本路径）。

## 探测表单一数据源

- **语义与解析逻辑（唯一维护处）**：`src/hjs_egress_ip/web/static/audit-core.js` 内的 `PROBES` 与 `snippetFromBody`。
- **静态 HTML**：`static/index.html` 以普通 `<script src>` 引入 `audit-core.js`（挂载在 `globalThis.HjsEgressAuditCore`），浏览器内对工作流允许 `fetch` 的探测 URL **直连**。**无 CORS 的站点（如 `https://cip.cc`）在纯 `fetch` 下会表现为失败**——与地址栏能否打开无关；若以 `hjs-egress-ip serve` 同源打开，可走内置 **`GET /__probe?url=`**（仅允许 `probes.packaged.json` 中的 URL），由本机服务端代读正文后与页面解析逻辑一致。
- **Python 校验数据**：在包根目录执行 `node scripts/sync-probes.mjs`，将 `PROBES` 导出为 `src/hjs_egress_ip/data/probes.packaged.json`；CLI 在调用 bash 前仍会 `load_default()` 校验该 JSON 存在且结构合法。
- **与终端 curl 对齐**：实际多场景矩阵仍由全局技能内 `egress-ip-audit.sh` 执行。**若增删改探测点**，请同时修改 `audit-core.js`、重新运行 `sync-probes.mjs`，并在技能脚本中同步更新 bash 数组 `PROBES`，避免两处漂移。

## 安装（开发）

```bash
cd hjs-egress-ip-cli
pip install -e ".[dev]"
```

（开发机需安装 Node，仅用于运行 `scripts/sync-probes.mjs`。最终用户使用 wheel **不依赖** Node。）

## 推荐最终用户安装（pipx）

```bash
pipx install /path/to/hjs-egress-ip-cli   # 发布后可用 PyPI 包名
# 或
pipx run hjs-egress-ip -- --help
```

## 端到端手动检测（一轮）

1. 确认本机已安装 `curl`，且能访问外网。
2. `pip install -e .` 或 `pipx install ...` 后执行：`hjs-egress-ip`（无参）应输出「一键出口摘要」分组文本。
3. 机器可读：`hjs-egress-ip --simple-tsv | head -5`，首行表头应含 `scenario`。
4. 完整矩阵：`hjs-egress-ip --full --ipv6-skip | head -20`。
5. 静态审计页：**直接双击或打开** `src/hjs_egress_ip/web/static/index.html`（与 `audit-core.js` 同目录，勿单独移动导致相对路径断裂）；也可执行 `hjs-egress-ip serve` 做本地静态托管（页面仍不向本服务 POST）。健康检查：`curl -s http://127.0.0.1:18765/health` 期望 `ok`。

## 环境变量

| 变量 | 说明 |
|------|------|
| `HJS_EGRESS_AUDIT_SCRIPT` | 覆盖默认的 `egress-ip-audit.sh` 绝对路径 |
| `CURL_TIMEOUT` | 透传给底层脚本（秒，默认 8） |

## 构建 wheel

```bash
pip install build
python -m build
```

产物在 `dist/`。若需发布到 PyPI / Homebrew，请在本仓库外配置 CI 与签名流程（此处仅占位说明）。

## 测试

```bash
cd hjs-egress-ip-cli
pytest -q
```
