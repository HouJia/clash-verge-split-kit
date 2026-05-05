---
phase: 01-hjs-egress-ip-cli-tool
plan: "04"
status: complete
---

# Plan 01-04 执行摘要

## 结果

- 更新全局技能 `~/.cursor/skills/hjs-egress-ip-audit/SKILL.md`：`pipx` / `hjs-egress-ip` 为第一推荐，脚本与旧 Web 启动方式为 fallback；维护节补充 `probes.default.yaml`。
- 在 airport 根目录新增 `README.md`，链向 `hjs-egress-ip-cli/README.md`。

## 关键文件

- `/Users/hubery/.cursor/skills/hjs-egress-ip-audit/SKILL.md`（全局路径）
- `airport/README.md`

## 自检

- `rg -n "pipx|hjs-egress-ip[^-]" ~/.cursor/skills/hjs-egress-ip-audit/SKILL.md` 有命中。

## Self-Check: PASSED
