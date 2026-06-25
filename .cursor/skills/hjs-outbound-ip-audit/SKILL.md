---
name: hjs-outbound-ip-audit
description: >-
  一键按「站点类型」汇总本机 curl 看到的公网出口（国内/国际/CDN/元数据）；可选完整技术矩阵（代理对照、
  IPv4/IPv6、网卡绑定等进阶项）。含本地 Web 面板。全局技能路径 ~/.cursor/skills/hjs-outbound-ip-audit/。
  在用户询问出口 IP、分流现象、代理是否生效、国内外 IP 不一致时使用。
disable-model-invocation: true
---

# hjs-outbound-ip-audit：出站 IP 一键检测

## 技能位置

- **仓库副本（随 Git 同步）：** `clash-verge-split-kit/.cursor/skills/hjs-outbound-ip-audit/`
- **本机全局（Cursor 加载）：** `~/.cursor/skills/hjs-outbound-ip-audit/`（可从仓库复制或 `pipx` 安装 CLI 后仅用包内脚本）

## 目标（默认很简单）

- **默认一键**：不按 TUN、不解释底层；只回答「不同类型常用探测目标各自看到的出口是什么」。
- **可选进阶**：需要对照「是否尊重代理环境变量」「IPv4/IPv6」「网卡绑定」时，使用 **`--full`** 或 Web 里勾选「完整技术矩阵」；详细说明在输出附注与 [reference-endpoints.md](reference-endpoints.md)。

## 何时加载

- 用户想快速看「国内站 vs 国际站」出口差异、或验证代理/分流表象
- 需要可重复的 curl 矩阵留档（`--full` + TSV）

## 命令行（推荐：独立 CLI）

优先使用已安装的 **`outbound-ip`**（与 Cursor 解耦），便于 `pipx` 分发与脚本自动化：

```bash
# 安装示例（本地路径或发布后包名以实际为准）
pipx install /path/to/airport/outbound-ip-cli

# 默认：一键摘要（按站点类型分组，单次 --noproxy '*' 路径）
outbound-ip

# 仅机器可读 TSV（表头 + 场景 S1_noproxy_star）
outbound-ip --simple-tsv

# 完整技术矩阵（S0/S1/IPv4/IPv6/可选 --interface）
outbound-ip --full --ipv6-skip
```

首版 CLI 通过子进程调用 **`outbound-ip-audit.sh`**（默认：包内 `outbound-ip-cli/scripts/` 或技能目录）；若脚本不在默认路径，请设置 **`OUTBOUND_IP_AUDIT_SCRIPT`** 指向该文件的绝对路径。

**未安装 CLI 时（fallback）** 可直接调用仓库内脚本：

```bash
~/.cursor/skills/hjs-outbound-ip-audit/scripts/outbound-ip-audit.sh
~/.cursor/skills/hjs-outbound-ip-audit/scripts/outbound-ip-audit.sh --simple-tsv
```

环境变量：`CURL_TIMEOUT`（秒，默认 8）。

## Web 面板

**默认推荐：纯静态页（无需本地服务器）**

- 用浏览器直接打开 **`web/index.html`**（路径：`~/.cursor/skills/hjs-outbound-ip-audit/web/index.html`）。
- 页内用 **`fetch` 并行探测**，看到的是**当前浏览器 + 系统代理**下的出口，与脚本里 **`curl --noproxy '*'`** 的摘要**不可逐项等同**；部分站点可能因 **CORS** 在浏览器里失败。
- 需要与 shell **完全一致**、或 **`--full` 矩阵**时，请用 **`outbound-ip-audit.sh`** / **`outbound-ip`**，不要用静态页代替。

**可选：本地 HTTP（与 CLI 同源，便于与脚本共用 `/api/run`）**

```bash
outbound-ip serve
# 或：outbound-ip serve --no-open
```

- 默认 **`http://127.0.0.1:18765/`**；勾选「完整技术矩阵」时由服务端调用 `--full`。
- **`--no-open`**、**`HJS_AUDIT_UI_HOST`**、**`HJS_AUDIT_UI_PORT`** 与旧版一致。

**未安装 CLI 时（仅当需要服务端矩阵时）**：

```bash
cd ~/.cursor/skills/hjs-outbound-ip-audit/scripts
chmod +x outbound-ip-audit.sh serve-audit-ui.py
python3 serve-audit-ui.py
```

## Agent 解读要点

- **一键路径**使用 `curl --noproxy '*'`：不跟随当前 shell 的 `HTTP_PROXY` / `ALL_PROXY`，便于看各探测点本身走到的公网出口；与浏览器是否走系统代理无关。
- **`--full`** 才有 `S0_current_env`（尊重代理变量）与 `S_ipv4_only` / `S_ipv6_only` / `S_bind_iface_*`。
- 多个国际点与 `aws_checkip` IP 不同可为正常现象（多云边缘）。

## 维护

新增探测点：同时改 `scripts/outbound-ip-audit.sh` 内 `PROBES`、包内 `probes.default.yaml`（若已安装 CLI）与 `reference-endpoints.md`。
