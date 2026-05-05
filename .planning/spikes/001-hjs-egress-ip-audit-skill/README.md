---
spike: 001
name: hjs-egress-ip-audit-skill
type: standard
validates: "Given 分流或代理环境，当执行 egress-ip-audit.sh 多场景矩阵，则输出中可按 scenario 解释不同出口"
verdict: VALIDATED
related: []
tags: [network, curl, proxy, skill, egress-ip]
---

# Spike 001：hjs-egress-ip-audit 技能与脚本

## What This Validates

在同一终端内，通过 `S0`/`S1`/`S_ipv4_only`/`S_ipv6_only`/可选 `S_bind_iface`，验证「环境变量代理」「单次绕过代理」「双栈」「绑定 TUN」对出口观测的影响是否可被稳定记录。

## Research

- 参考业界做法：多服务端点、`curl` 代理对照、`--interface` 策略路由验证、`httpbin` 元数据；见技能内 `reference-endpoints.md`。
- `cip.cc` 返回 HTML，需从 `IP  :` 抽取；`ip.cip.cc` 在部分链路下会空响应。

## How to Run

技能已迁至全局：`~/.cursor/skills/hjs-egress-ip-audit/`（项目内不再保留副本）。

```bash
~/.cursor/skills/hjs-egress-ip-audit/scripts/egress-ip-audit.sh
# 完整矩阵：~/.cursor/skills/hjs-egress-ip-audit/scripts/egress-ip-audit.sh --full --ipv6-skip
```

Agent 加载技能：读取 `~/.cursor/skills/hjs-egress-ip-audit/SKILL.md`。

## What to Expect

- 制表符分隔多行：`scenario`、`category`、`probe_name`、`url`、`http_code`、`snippet`。
- 若 `http_code` 为 `000`，多为超时、TLS 失败或代理不可达。
- 同一 `scenario` 下 **`aws_checkip` 与其他国际点 IP 不同** 可为正常现象（边缘路径不同）。

## Investigation Trail

1. 初版脚本使用嵌套 `env -i` 传递探测表失败，改为 `--noproxy '*'` 场景矩阵。
2. 在沙箱首轮 `S0` 全 `000`、`S1` 成功，说明「仅环境变量代理」可导致首轮阻塞；技能正文已解释。
3. `cip.cc` 原始 HTML 片段过长，增加 `cip_cc_ip` 解析器抽取 IPv4。

## Results

- **Verdict：VALIDATED**。脚本在真实网络下可完成全矩阵；技能文档覆盖用户原始命令分类、扩展端点、与 RULE/TUN/环境变量关系及局限。
- 交付物：全局技能目录 `~/.cursor/skills/hjs-egress-ip-audit/`；工具化路线见 `.planning/milestones/v1.0-phases/01-hjs-egress-ip-cli-tool/PLAN.md`。
