# Clash 配置模块化拆分方案

本目录包含从 `clash-after-phase03.local.yaml` 拆分出的模块化配置。

## 拆分逻辑

基于原文件的规则分析，按**业务场景**和**优先级**进行拆分，便于后续管理和定制。

### 原文件统计

| 指标 | 数值 |
|-----|------|
| 总规则数 | 52,674 条 |
| DOMAIN-SUFFIX | 51,926 条 (98.6%) |
| IP-CIDR | 506 条 (1.0%) |
| DOMAIN-KEYWORD | 91 条 |
| DOMAIN | 131 条 |
| GEOIP | 1 条 |
| MATCH | 1 条 |

### 目标分组分布

| 分组 | 规则数量 | 模块 |
|-----|---------|------|
| 🛑 广告拦截 | 44,217 条 | 30-rules-ads.yaml |
| 🚀 节点选择 | 5,920 条 | 65-rules-proxy.yaml |
| 🍃 应用净化 | 953 条 | 35-rules-telemetry.yaml |
| 🎯 全球直连 | 666 条 | 70-rules-geo.yaml |
| 🌍 国外媒体 | 222 条 | 45-rules-streaming.yaml |
| 🎮 游戏平台 | 28 条 | 60-rules-gaming.yaml |
| 🤖 AI | 15 条 | 40-rules-ai.yaml |
| 📺 流媒体 | ~290 条 | 45-rules-streaming.yaml |
| 📲 社交 | ~23 条 | 50-rules-social.yaml |
| 其他 | <150 条 | 55-rules-services.yaml |

---

## 文件清单

### 基础配置模块

| 文件名 | 说明 | 行数 |
|-------|------|------|
| `00-core.yaml` | 基础配置(端口、API、日志、模式) | 35 |
| `10-proxies.yaml` | 代理节点列表 (48个节点) | 48 |
| `20-proxy-groups.yaml` | 策略组定义 (26个策略组) | 446 |

### 规则模块 (按优先级排序)

| 文件名 | 说明 | 规则数 | 优先级 |
|-------|------|--------|-------|
| `25-rules-special.yaml` | 特殊网站与官网访问 | 5 | 高 |
| `40-rules-ai.yaml` | AI服务 (ChatGPT, Claude等) | 15 | 高 |
| `30-rules-ads.yaml` | 广告拦截 | 44,290 | 中 |
| `35-rules-telemetry.yaml` | 应用净化/遥测拦截 | 972 | 中 |
| `45-rules-streaming.yaml` | 流媒体平台 (YT/Netflix/B站等) | 317 | 中 |
| `50-rules-social.yaml` | 社交媒体 (TG/Twitter等) | 23 | 中 |
| `55-rules-services.yaml` | 邮件与云服务 (Gmail/微软服务) | 119 | 中 |
| `60-rules-gaming.yaml` | 游戏平台 (Steam等) | 28 | 低 |
| `65-rules-proxy.yaml` | 一般代理域名 | 5,997 | 低 |
| `70-rules-geo.yaml` | 地理位置分流 + 兜底 | 908 | 最低 |

### 说明文档

| 文件名 | 说明 |
|-------|------|
| `99-main.yaml` | 配置汇总说明，包含使用指南 |
| `README.md` | 本文档 |

---

## 使用方式

### 1. Clash Verge (推荐)

在「订阅配置」中，使用「全局扩展配置」功能引用各模块：

```yaml
# 在扩展配置中粘贴主配置文件的引用逻辑
# 或者直接合并 00-core.yaml + 10-proxies.yaml + 20-proxy-groups.yaml + 各规则模块
```

### 2. Mihomo / Clash Meta

使用 `proxy-providers` 和 `rule-providers` 动态加载：

```yaml
rule-providers:
  ads:
    type: file
    path: ./modules/30-rules-ads.yaml
    behavior: classical
  
  streaming:
    type: file
    path: ./modules/45-rules-streaming.yaml
    behavior: classical
```

### 3. 手动合并

按以下顺序将文件内容合并：

1. `00-core.yaml` - 基础配置
2. `10-proxies.yaml` - 代理节点 (proxies:)
3. `20-proxy-groups.yaml` - 策略组 (proxy-groups:)
4. `25-rules-special.yaml` - 特殊规则
5. `40-rules-ai.yaml` - AI服务规则
6. `30-rules-ads.yaml` - 广告拦截
7. `35-rules-telemetry.yaml` - 应用净化
8. `45-rules-streaming.yaml` - 流媒体
9. `50-rules-social.yaml` - 社交媒体
10. `55-rules-services.yaml` - 邮件/云服务
11. `60-rules-gaming.yaml` - 游戏平台
12. `65-rules-proxy.yaml` - 一般代理
13. `70-rules-geo.yaml` - 地理位置 + 兜底规则

---

## 规则优先级说明

Clash 规则是**自上而下首条命中**，顺序很重要：

```
高优先级 → 低优先级

特殊规则(官网) → AI服务 → 广告拦截 → 应用净化 → 
流媒体 → 社交 → 邮件/云服务 → 游戏 → 一般代理 → 
GEOIP分流 → MATCH兜底
```

**关键原则**：
- 广告拦截规则最多(~44,000条)，如果追求性能可删减或关闭
- `GEOIP,CN,🎯 全球直连` 应该在域名规则之后、MATCH之前
- `MATCH,🕹 规则之外` 必须放在最后作为兜底

---

## 定制建议

### 如果不需要广告拦截

删除或注释掉 `30-rules-ads.yaml` 的引用，可减少 44,000+ 条规则，显著提升匹配速度。

### 如果需要精简规则

保留以下核心模块即可：
- `00-core.yaml`
- `10-proxies.yaml`
- `20-proxy-groups.yaml`
- `40-rules-ai.yaml` (AI服务)
- `45-rules-streaming.yaml` (流媒体)
- `70-rules-geo.yaml` (GEOIP + MATCH)

### 添加自定义规则

创建 `90-rules-custom.yaml` 并放在 `70-rules-geo.yaml` 之前引用：

```yaml
# 90-rules-custom.yaml
rules:
 - DOMAIN,mycompany.com,🎯 全球直连
 - DOMAIN-SUFFIX,internal.net,🎯 全球直连
```

---

## 验证合并结果

合并后检查规则总数是否匹配：

```bash
# 统计合并后文件的总规则数
grep -c "^ - " merged.yaml

# 应接近 52,674 条 (允许少量误差)
```

---

## 文件生成时间

2026-05-06 由 Clash 配置分析工具自动生成
