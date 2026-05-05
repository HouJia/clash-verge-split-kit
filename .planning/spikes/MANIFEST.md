# Spike Manifest

## Idea

为「多出口 / 分流 / 代理环境」建立可重复的出口 IP 探测技能：分类用户提供的 `curl` 回显站点，补充业界常用端点与多场景矩阵（当前环境、绕过代理、IPv4/IPv6、可选绑定 TUN），并交付 Cursor 技能与可执行脚本。

## Requirements

- 技能名必须符合团队约定：以 `hjs-` 前缀命名；技能目录位于用户全局 `~/.cursor/skills/hjs-egress-ip-audit/`。
- 默认探测需覆盖：**国内向**与**国际向**至少各一类；须包含用户曾列出的核心域名（ipecho、ipinfo、ifconfig、icanhazip、cip、ipip、ip.cip.cc）。
- 必须能区分 **`S0` 当前环境（尊重代理变量）** 与 **`S1` 单次 `--noproxy '*'`** 两类场景。
- 脚本仅依赖 `curl`；`httpbin` JSON 解析在缺少 `python3` 时允许降级为原始片段。

## Spikes

| # | Name | Type | Validates | Verdict | Tags |
|---|------|------|-----------|---------|------|
| 001 | hjs-egress-ip-audit-skill | standard | Given 本机存在分流或代理，当运行多场景探测脚本，则能在表格中观察到与各路径一致的公网地址差异 | VALIDATED | network,proxy,curl,skill |
