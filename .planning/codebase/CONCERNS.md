# Concerns

**Analysis Date:** 2026-05-03

## 依赖全局技能路径

- **默认** 假设 `~/.cursor/skills/hjs-egress-ip-audit/scripts/egress-ip-audit.sh` 存在（`cli.py`）。在未安装技能且未设置 `HJS_EGRESS_AUDIT_SCRIPT` 的机器上，CLI **无法工作**。
- **运维含义** — 「独立 CLI」仍与技能仓库中的脚本版本 **强耦合**；脚本升级不会自动通过本包版本号传达。

## 探测逻辑双轨与 YAML 角色

- `load_default()` 校验的 `probes.default.yaml` 与 **实际 curl 目标列表** 在运行时由 bash 脚本主导；若两处漂移，可能出现 **Python 校验通过但脚本使用另一套 URL** 的认知不一致。
- README 已说明外置自定义 YAML 为后续能力；当前用户无法仅通过本包 CLI 切换探测表文件。

## 子进程与安全

- **bash + 外部脚本** — 攻击面主要在用户环境内的脚本内容替换；Python 仅拼接有限 flag（`--full`、`--ipv6-skip`、`--interface` 等）。`iface` 在 Web 层做了字符白名单，但最终仍传入下游，需保持脚本侧无注入式用法。
- **`POST /api/run`** — 虽限制 body 大小，本地服务若绑定非 localhost（用户显式配置）会扩大暴露面；默认 `127.0.0.1` 降低风险。

## Web UI 行为边角

- CLI 非零退出时 HTTP 仍可能返回 **200** 且 JSON `ok: false`（设计便于前端展示），与纯 REST 习惯不同；监控若以 HTTP 状态判断会误判成功。
- **长耗时** — `MAX_RUN_SECONDS = 600`；慢网络下 UI 可能长时间无响应，仅依赖超时错误 JSON。

## 测试缺口

- **`cli` / `probes` / `server` 无自动化测试** — 回归依赖手动与 pytest 覆盖的 `formatters` 子集。
- **无 CI** — 合并前无强制 `pytest` 门禁（仓库内未见 GitHub Actions 等）。

## 可维护性

- **静态 HTML + 内联 CSS/JS** — 单文件 `web/static/index.html` 便于分发，但大改动时缺少组件化与类型检查。
- **仓库体量** — `vpn-reality-guides/`、`旧内容-可能过期了/` 与核心包无关，新贡献者可能混淆主交付路径（以 `hjs-egress-ip-cli/` 为准）。

## 供应链与发布

- **PyPI/README** 提示构建与发布流程在仓库外配置；**无**自动化签名或版本打 tag 的脚本绑定本分析日可见文件。

## 已缓解或低风险项（上下文记录）

- **请求体大小** — 已对 `/api/run` 做 64KiB 上限（`server.py`）。
- **本地绑定** — 默认 `127.0.0.1`，符合 `.planning/PROJECT.md` 中本地 UI 约束描述。
