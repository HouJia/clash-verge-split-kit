# Clash 配置模块化拆分方案 (机场B)

本目录包含从 `ori-airport-b-rule-split.local.yaml` 拆分出的模块化配置。

## 拆分逻辑

基于原文件的规则分析，按**业务场景**和**优先级**进行拆分，便于后续管理和定制。

### 原文件统计

| 指标 | 数值 |
|-----|------|
| 总规则数 | 9,563 条 |
| DOMAIN-SUFFIX | 9,018 条 (94.3%) |
| IP-CIDR | 488 条 (5.1%) |
| DOMAIN-KEYWORD | 127 条 (1.3%) |
| DOMAIN | 151 条 (1.6%) |
| IP-CIDR6 | 17 条 (0.2%) |
| DST-PORT | 13 条 (0.1%) |
| GEOIP | 1 条 |
| MATCH | 1 条 |

### 代理节点分布

| 地区 | 节点数量 | 说明 |
|-----|---------|------|
| 香港 | 11 个 | 含 IEPL 线路 |
| 日本 | 18 个 | 含 7 个免费节点 |
| 新加坡 | 3 个 | IEPL x2 线路 |
| 台湾 | 1 个 | IEPL x2 线路 |
| 美国 | 2 个 | IEPL x1.5 线路 |
| 其他 | 12 个 | 英国/阿根廷/俄罗斯/土耳其/韩国/印度/德国/加拿大/澳大利亚/法国/乌克兰 |
| **总计** | **47 个** | 36 付费 + 7 免费 |

### 目标分组分布

| 分组 | 规则数量 | 模块 |
|-----|---------|------|
| 🛑 广告拦截 | 1,596 条 | 30-rules-ads.yaml |
| 🔰 节点选择 | 7,116 条 | 65-rules-proxy.yaml |
| 🇨🇳 国内网站 | 687 条 | 70-rules-geo.yaml |
| 🌩️ Cloudflare | 36 条 | 55-rules-services.yaml |
| 🎮 Steam 商店/社区 | 19 条 | 60-rules-gaming.yaml |
| 🎓学术网站 | 17 条 | 55-rules-services.yaml |
| ☁️ OneDrive | 14 条 | 55-rules-services.yaml |
| 🌏 爱奇艺&哔哩哔哩 | 12 条 | 45-rules-streaming.yaml |
| 📺 动画疯 | 5 条 | 45-rules-streaming.yaml |
| 🎮 Steam 登录/下载 | 2 条 | 60-rules-gaming.yaml |
| 🐟 漏网之鱼 | 1 条 | 70-rules-geo.yaml |

---

## 文件清单

### 基础配置模块

| 文件名 | 说明 | 内容 |
|-------|------|------|
| `20-proxy-groups.yaml` | 策略组定义 | 11 个策略组，包含节点选择、流媒体、游戏、学术等 |

### 规则模块 (按优先级排序)

| 文件名 | 说明 | 规则数 | 优先级 |
|-------|------|--------|-------|
| `30-rules-ads.yaml` | 广告拦截 | 1,596 | 高 |
| `40-rules-ai.yaml` | AI 服务 | 0 | 高 |
| `45-rules-streaming.yaml` | 流媒体平台 | 17 | 中 |
| `50-rules-social.yaml` | 社交媒体 | 0 | 中 |
| `55-rules-services.yaml` | 云服务与学术 | 67 | 中 |
| `60-rules-gaming.yaml` | 游戏平台 | 21 | 中 |
| `65-rules-proxy.yaml` | 一般代理 | 7,116 | 低 |
| `70-rules-geo.yaml` | 地理位置分流 + 兜底 | 746 | 最低 |

### 说明文档

| 文件名 | 说明 |
|-------|------|
| `99-main.yaml` | 配置汇总说明，包含使用指南 |
| `README.md` | 本文档 |

---

## 与 机场A 配置的主要差异

| 维度 | 机场A | 机场B |
|------|-----------|-------|
| 总规则数 | ~52,000 条 | ~9,600 条 |
| 广告拦截 | 44,000+ 条 | 1,600 条 |
| 策略组数 | 26 个 | 11 个 |
| 分流粒度 | 精细分层 | 较粗（大部分走节点选择） |
| 适用场景 | 严格广告拦截 | 简洁快速 |

---

## 使用方式

### 1. Clash Verge (推荐)

在「订阅配置」中，使用「全局扩展配置」功能引用各模块：

```yaml
# 在扩展配置中粘贴主配置文件的引用逻辑
# 或者直接合并 20-proxy-groups.yaml + 各规则模块
```

### 2. Mihomo / Clash Meta

使用 `proxy-providers` 和 `rule-providers` 动态加载：

```yaml
rule-providers:
  ads:
    type: file
    path: ./modules/30-rules-ads.yaml
    behavior: classical
  proxy:
    type: file
    path: ./modules/65-rules-proxy.yaml
    behavior: classical
```

### 3. 手动合并

按以下顺序将文件内容合并：

1. `20-proxy-groups.yaml` - 策略组 (proxy-groups:)
2. `30-rules-ads.yaml` - 广告拦截
3. `40-rules-ai.yaml` - AI 服务（空占位）
4. `45-rules-streaming.yaml` - 流媒体
5. `50-rules-social.yaml` - 社交媒体（空占位）
6. `55-rules-services.yaml` - 云服务与学术
7. `60-rules-gaming.yaml` - 游戏平台
8. `65-rules-proxy.yaml` - 一般代理
9. `70-rules-geo.yaml` - 地理位置 + 兜底规则

```bash
# 合并命令示例
cat 20-proxy-groups.yaml 30-rules-ads.yaml 40-rules-ai.yaml \
    45-rules-streaming.yaml 50-rules-social.yaml 55-rules-services.yaml \
    60-rules-gaming.yaml 65-rules-proxy.yaml 70-rules-geo.yaml > merged.yaml

# 验证规则数
grep -c "^- " merged.yaml
# 应输出约 9,563 条
```

---

## 规则优先级说明

Clash 规则是**自上而下首条命中**，顺序很重要：

```
高优先级 → 低优先级

广告拦截 → 流媒体 → 云服务/学术 → 游戏 → 一般代理 → 
GEOIP分流 → MATCH兜底
```

**关键原则**:
- 机场B 的广告拦截规则约 1,600 条，比 机场A 精简很多，性能影响较小
- `GEOIP,CN,🎯 全球直连` 应该在域名规则之后、MATCH 之前
- `MATCH,🐟 漏网之鱼` 必须放在最后作为兜底

---

## 定制建议

### 如果不需要广告拦截

删除或注释掉 `30-rules-ads.yaml` 的引用，可减少 1,600 条规则。

### 如果需要添加自定义规则

创建 `90-rules-custom.yaml` 并放在 `70-rules-geo.yaml` 之前引用：

```yaml
# 90-rules-custom.yaml
rules:
 - DOMAIN,mycompany.com,🎯 全球直连
 - DOMAIN-SUFFIX,internal.net,🎯 全球直连
```

### 与 机场A 规则混合使用

机场B 和 机场A 的模块化文件可以交叉引用，但需注意：
- 策略组名称可能不同（机场A 用 `🚀 节点选择`，机场B 用 `🔰 选择节点`）
- 规则数量和粒度差异较大

---

## 验证合并结果

合并后检查规则总数是否匹配：

```bash
# 统计合并后文件的总规则数
grep -c "^- " merged.yaml

# 应接近 9,563 条 (允许少量误差)
```

---

## 文件生成时间

2026-05-06 由 Clash 配置分析工具自动拆分生成
