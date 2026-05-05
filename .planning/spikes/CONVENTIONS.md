# Spike Conventions

本仓库 spikes 以 **bash + curl** 做网络可行性验证；可执行文件放在对应技能的 `scripts/` 下，与 `.cursor/skills/hjs-*/` 同步维护。

## Stack

- Shell：`bash`（macOS 默认可用）
- 网络：`curl`；JSON 可选 `python3`

## Structure

- Spike 目录：`.planning/spikes/NNN-slug/`
- 对外技能：全局 `~/.cursor/skills/hjs-*/`（本仓库不内嵌技能副本）

## Patterns

- 长耗时探测使用 `CURL_TIMEOUT` 环境变量可调。
- 多场景命名统一前缀 `S0_` / `S1_` / `S_ipv4_only` 等，便于表格聚合。
