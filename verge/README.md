# Clash Verge 扩展分流（INI 模板 + 本机稿）

| 项目 | 内容 |
|---|---|
| **创建时间** | 2026-03-01 |
| **最后更新** | 2026-06-27 |

## 更新记录

| 日期 | 更新内容 |
|---|----|
| 2026-06-27 | WebRTC 封闭 INI 方案文档、05-webrtc.ini 草稿、旁路由规则源说明 |
| 2026-06-25 | 补充 SubConverter 排障文档链接、交叉验收脚本说明 |
| 2026-03-01 | 初稿：INI 模板与本机稿数据流 |

长期目标与脱敏红线见 **[`docs/clash-verge/RULEBASE-PROGRAM.md`](../docs/clash-verge/RULEBASE-PROGRAM.md)**。

**SubConverter / 原生 ISP 踩坑：** 见 **[`derive/TROUBLESHOOTING-subconverter-ini.md`](derive/TROUBLESHOOTING-subconverter-ini.md)**（订阅走 gist INI 时必读）。

**WebRTC 封闭（旁路由 + Verge 共用 sub）：** 见 **[`docs/clash-verge/webrtc-lockdown-ini-plan.md`](../docs/clash-verge/webrtc-lockdown-ini-plan.md)**。旁路由 OpenClash 的分流规则 **以本仓库 INI → gist → SubConverter 为准**（非 `side-router-lab` custom 规则）。

## 数据流（当前主线）

```text
verge/derive/parts/20-routing.ini
  + parts/rulesets/*.ini
        │  compose-ini.sh
        ▼
verge/template/config-template.ini          ← 合并模板（可提交）
        │  render-local.sh + override.local.ini [rules]
        ▼
verge/generated/config.local.ini / .yaml    ← 本机产物（勿提交）
```

**真值源：** [`derive/parts/`](derive/parts/)（通用规则与策略组）。  
**本机私有规则：** [`generated/local/override.local.ini`](generated/local/override.local.ini) 的 **`[rules]`** 节（VPS IP、机场面板等，勿提交）。

## 文件说明

| 路径 | 说明 |
|------|------|
| [`derive/parts/20-routing.ini`](derive/parts/20-routing.ini) | 策略组定义 + 规则注入锚点 |
| [`derive/parts/rulesets/*.ini`](derive/parts/rulesets/) | 按场景拆分的通用 `ruleset=` 片段 |
| [`derive/scripts/compose-ini.sh`](derive/scripts/compose-ini.sh) | 合并 parts → `template/config-template.ini` |
| [`template/config-template.ini`](template/config-template.ini) | **合并后的 subconverter INI 模板**（由 compose 生成，日常改 parts 后需重跑 compose） |
| [`derive/scripts/render-local.sh`](derive/scripts/render-local.sh) | 读模板 + 注入 `override.local.ini` 的 `[rules]` → 写出 `generated/config.local.*` |
| [`generated/local/override.local.ini.example`](generated/local/override.local.ini.example) | 复制为 `override.local.ini`（勿提交） |
| [`derive/scripts/sync-generated-gists.sh`](derive/scripts/sync-generated-gists.sh) | 将本机产物推到 secret gist（需 `gist-sync.local.env`）；末尾自动跑交叉验收 |
| [`derive/scripts/verify-native-split.sh`](derive/scripts/verify-native-split.sh) | INI + gist + SubConverter 原生/ISP 分流交叉验收 |
| [`derive/TROUBLESHOOTING-subconverter-ini.md`](derive/TROUBLESHOOTING-subconverter-ini.md) | SubConverter INI 排障与原生 ISP 经验沉淀 |

## 一次性配置（本机）

```bash
cp verge/generated/local/override.local.ini.example verge/generated/local/override.local.ini
# 编辑 [rules]：VPS IP-CIDR、机场面板域名等私有直连/代理规则
```

## 日常流程

1. **改通用规则：** 编辑 `verge/derive/parts/rulesets/*.ini` 或 `20-routing.ini`  
2. **合并模板：** `bash verge/derive/scripts/compose-ini.sh -o verge/template/config-template.ini`  
3. **生成本机稿：** `bash verge/derive/scripts/render-local.sh`  
4. **（可选）同步 gist：** `bash verge/derive/scripts/sync-generated-gists.sh`（内含 verify）  
5. **改策略组 filter 后建议交叉验收：** `bash verge/derive/scripts/verify-native-split.sh`  
6. 将 `verge/generated/config.local.yaml` 用于 Sub-Store / subconverter，或按你的 Verge 接入方式粘贴规则段

若 Verge 订阅 URL 的 `config=` 指向 gist INI，**以 INI 的 `custom_proxy_group` 为准**；仅改 YAML `exclude-filter` 不会生效（详见排障文档）。

编辑 `derive/parts/*` 或 `override.local.ini` 并保存时，Cursor Hook（[`.cursor/hooks.json`](../.cursor/hooks.json)）会尝试自动执行 compose + render。

## 私有规则约定

- VPS、亮数据 ISP、NAS、机场面板等 **只写在 `override.local.ini` 的 `[rules]`**  
- 格式：`ruleset=策略组名,[]规则类型,规则内容,no-resolve`  
- 策略组名须与 `20-routing.ini` 中 `custom_proxy_group` **完全一致**（含「底座 ·」前缀）  
- 注入位置为模板内 `; >>> RULESET_INJECTION_START`，**优先于**标准 rulesets 命中

更多概念见 [`docs/clash-verge/local-split-vps.md`](../docs/clash-verge/local-split-vps.md)。
