---
status: issues
phase: "01"
phase_name: hjs-egress-ip-cli-tool
depth: standard
files_reviewed: 17
critical: 0
warning: 0
info: 3
total: 3
reviewed_at: "2026-05-03"
scope_note: "SUMMARY 未含 key_files YAML；范围来自 git diff（01 相关提交相对父提交）。"
---

# Phase 01 代码审查报告

## 摘要

对 `hjs-egress-ip-cli` 与仓库根 `README.md` 做了 **standard** 深度审查：CLI 委托 bash、本地 Web UI、`formatters`/`probes` 与测试。未发现可导致远程 RCE 的路径（本地服务默认绑定 `127.0.0.1`）。原 **2 条 Warning** 已在修复闭环中处理（见 `01-REVIEW-FIX.md`）；仍余 **3 条 Info**（测试覆盖缺口、TSV 解析假设、网卡名校验边界）。

## 严重级别说明

- **CR**：安全或数据损坏高风险
- **WR**：正确性、可用性或中等风险（含本地滥用面）
- **IN**：可维护性、测试缺口或低风险改进

---

### WR-01：`Content-Length` 非数字时 `do_POST` 可能未处理异常

**位置**：`hjs-egress-ip-cli/src/hjs_egress_ip/web/server.py`（`do_POST` 中 `int(self.headers.get("Content-Length", ...))`）

**问题**：若客户端发送非法 `Content-Length`（非十进制整数），`int(...)` 抛出 `ValueError`，未在本方法内捕获，可能导致连接以 500 结束或依赖基类行为；与相邻 JSON 解析的防御式风格不一致。

**建议**：用 `try/except` 将非法长度视为 `0` 或返回 400，并记录简短错误信息。

**修复状态**：已在 `hjs-egress-ip-cli/src/hjs_egress_ip/web/server.py` 对非法 `Content-Length` 返回 400 JSON（见 `01-REVIEW-FIX.md`）。

---

### WR-02：`/api/run` 未限制请求体大小

**位置**：同上，`self.rfile.read(length)`

**问题**：恶意或错误客户端可声明极大 `Content-Length`，在单次请求中占用大量内存（本地开发服务仍有 DoS/误操作面）。

**建议**：设定合理上限（例如 64KiB），超出则返回 413 或 400 并丢弃/不读满体。

**修复状态**：已设 `MAX_POST_BODY_BYTES = 64 * 1024`，超限返回 413，并有限丢弃正文、关闭 keep-alive（见 `01-REVIEW-FIX.md`）。

---

### IN-01：CLI / Web 路径缺少自动化测试

**位置**：`hjs-egress-ip-cli/src/hjs_egress_ip/cli.py`、`web/server.py`

**说明**：`tests/test_formatters.py` 覆盖了解析与分组；`cli` 的参数组合、`resolve_audit_script` 分支、`Handler` 的 GET/POST 分支与错误 JSON 等未覆盖。回归时易漏。

**建议**：为 `server.Handler` 使用 `http.client` 或 `urllib.request` 做轻量集成测试；对 `cli` 可用 `pytest` + `monkeypatch` 模拟 `subprocess.run` 与脚本路径。

---

### IN-02：`parse_tsv_rows` 固定六列

**位置**：`hjs-egress-ip-cli/src/hjs_egress_ip/formatters.py`

**说明**：列数不足时补空；超过 6 列时静默截断。若上游 TSV 演进增加列，可能无声丢数据。

**建议**：文档约定列模式，或在检测到额外非空列时写入日志/断言（测试环境）。

---

### IN-03：网卡名白名单可能过严

**位置**：`server.py` 中 `iface` 字符校验

**说明**：仅允许字母数字与 `._-`。多数常见接口名满足；极少数系统接口名若含其他字符会被拒绝（当前返回 400 JSON，行为明确）。

**建议**：若收到真实环境反馈再放宽或改为平台相关校验。

---

## 正面结论

- CLI 使用 `subprocess.run` 且未启用 `shell=True`，参数以列表传递，有利于注入防护。
- 静态页面对用户可控字段使用 `escapeHtml` 后再写入 `innerHTML`，降低 XSS 面。
- `yaml.safe_load`、JSON 解析失败时的降级处理整体合理。
- `pyproject.toml` 中 `package-data` 已包含 YAML 与静态 HTML，打包路径正确。

## 后续命令

- Warning 修复记录：`cat .planning/milestones/v1.0-phases/01-hjs-egress-ip-cli-tool/01-REVIEW-FIX.md`
- 如需再次评审：`/gsd-code-review 1` 或 `/gsd-code-review 1 --fix`
- 查看本报告：`cat .planning/milestones/v1.0-phases/01-hjs-egress-ip-cli-tool/01-REVIEW.md`
