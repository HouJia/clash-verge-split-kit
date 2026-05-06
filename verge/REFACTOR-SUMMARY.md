# Verge 配置重构完成总结

## 重构目标
将「单文件混杂规则」改为「骨架 + 规则片段」架构，**保持「复制单个文件」的使用方式不变**。

---

## 重构成果

### 目录结构变更

```
verge/
├── derive/parts/
│   ├── 10-runtime-verge-mihomo.yaml     # 运行时壳（保持不变）
│   └── 20-routing-mihomo.yaml           # 路由骨架（精简版，使用占位符）
│
├── rulesets/_anchors/                    # 新增：规则片段目录
│   ├── 00-private.yaml                   # 私有/局域网规则
│   ├── 10-ads.yaml                      # 广告拦截与遥测净化
│   ├── 20-cursor.yaml                   # Cursor IDE
│   ├── 30-ai.yaml                       # 境外 AI 服务
│   ├── 35-messaging.yaml                # 即时通讯 + 脸书系
│   ├── 40-fcm.yaml                      # 谷歌推送服务
│   ├── 45-streaming.yaml                # 流媒体/音影社 + TikTok
│   ├── 50-dev.yaml                      # 开发源站
│   ├── 55-scholar.yaml                  # 学术与数据
│   ├── 60-tech-giants.yaml              # 大厂服务（Google/Apple/Microsoft）
│   ├── 65-gaming.yaml                   # 游戏平台
│   ├── 70-domestic.yaml                 # 国内流量 + PayPal
│   ├── 80-geo.yaml                      # 地理分流 + 兜底
│   └── README.md                        # 片段文档
│
├── scripts/
│   ├── render-local.sh                  # 更新：注入片段规则 + IP替换
│   └── sync-fragments.sh                # 新增：同步片段到骨架（备用）
│
└── generated/airport-rule-split.local.yaml  # 产物（单文件，~834行）
```

### 使用方式（保持不变）

```bash
# 修改规则片段（如修改 Cursor 规则）
vim verge/rulesets/_anchors/20-cursor.yaml

# 渲染生成最终产物
bash verge/scripts/render-local.sh

# 复制单个文件到 Verge（使用方式完全不变）
cat verge/generated/airport-rule-split.local.yaml | pbcopy
# 或打开文件全选复制 → 粘贴到 Verge 全局扩展配置
```

---

## 维护工作流对比

### 重构前
```
derive/parts/20-routing-mihomo.yaml (746行，proxy-groups + 混杂规则)
        ↓
bash derive/compose.sh → extend/airport-rule-split-extend.yaml
        ↓
bash scripts/render-local.sh → generated/*.local.yaml
        ↓
全文复制到 Verge
```

### 重构后
```
derive/parts/20-routing-mihomo.yaml (骨架，proxy-groups + 规则占位符)
        ↓
bash derive/compose.sh → extend/airport-rule-split-extend.yaml
        ↓
bash scripts/render-local.sh (注入片段) → generated/*.local.yaml
        ↓
全文复制到 Verge（使用方式不变）
```

### 修改规则示例

**场景：添加新的 Cursor 相关域名**

**重构前**：
1. 编辑 `derive/parts/20-routing-mihomo.yaml`
2. 在 746 行中找到 Cursor 段落（约行 475-487）
3. 添加新规则
4. 运行 `compose.sh` + `render-local.sh`
5. 全文复制

**重构后**：
1. 编辑 `rulesets/_anchors/20-cursor.yaml`（专注 Cursor 规则，仅 12 行）
2. 添加新规则
3. 运行 `render-local.sh`
4. 全文复制

---

## 规则数量统计

| 来源 | 规则数 | 说明 |
|------|--------|------|
| 00-private.yaml | 2 | 私有/局域网 |
| 10-ads.yaml | 3 | 广告拦截 + RULE-SET |
| 20-cursor.yaml | 11 | Cursor IDE |
| 30-ai.yaml | 39 | OpenAI/Claude |
| 35-messaging.yaml | 13 | Telegram/WhatsApp/Meta |
| 40-fcm.yaml | 33 | FCM 推送 |
| 45-streaming.yaml | 16 | Netflix/Spotify/TikTok |
| 50-dev.yaml | 11 | GitHub/Docker/npm |
| 55-scholar.yaml | 1 | 学术数据库 |
| 60-tech-giants.yaml | 20 | Google/Apple/Microsoft |
| 65-gaming.yaml | 27 | Steam/Epic/PlayStation |
| 70-domestic.yaml | 8 | 国内流量 + PayPal |
| 80-geo.yaml | 4 | 地理分流 + 兜底 |
| **总计（片段）** | **~188** | 不含本地私有规则 |

---

## 关键设计决策

### 1. 保持单文件产物
- 用户反馈：复制目录比复制单文件成本高
- 方案：片段文件仅在**维护侧**存在，渲染后合并为单文件

### 2. 不使用 YAML 锚点别名
- 问题：`*anchor` 在列表中展开为嵌套数组，Mihomo 不支持
- 方案：render-local.sh 直接将片段内容**扁平化注入**

### 3. 片段顺序控制
- 使用编号前缀（00, 10, 20...）控制注入顺序
- 与命中优先级一致：私有 → 广告 → Cursor → AI → ... → 兜底

---

## 后续优化建议

1. **片段热更新**：目前修改片段后需重新运行 `render-local.sh`，未来可考虑支持片段级热重载

2. **片段依赖检查**：添加脚本验证片段中的策略组名与骨架中 `proxy-groups` 的一致性

3. **自动化 CI**：GitHub Action 自动在 PR 时运行渲染并校验产物

---

## 验证清单

- [x] `compose.sh` 正常生成 extend 文件
- [x] `render-local.sh` 正常生成 local 文件
- [x] 产物为单文件（~834行）
- [x] 使用方式保持不变（复制单个文件）
- [x] 规则片段逻辑分离（13个片段文件）
- [x] 本地私有规则注入正常（最高优先级）
- [x] IP 占位符替换正常（YOUR_VPS_IP → 真实IP）

---

*重构完成时间: 2026-05-06*
*方案版本: V2（单文件 + 片段化维护）*
