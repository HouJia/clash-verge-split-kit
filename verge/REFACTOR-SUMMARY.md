# Verge 配置重构完成总结

> **2026-06-25 注：** 早期 `verge/rulesets/_anchors/`（YAML 片段）已删除；规则真值源现为 **`verge/derive/parts/rulesets/*.ini`**，见 [`derive/README.md`](derive/README.md) 与 [`README.md`](README.md)。

## 重构目标
将「单文件混杂规则」改为「骨架 + 规则片段」架构，**保持「复制单个文件」的使用方式不变**。

---

## 清晰的分层架构

```
verge/
├── derive/parts/
│   ├── 10-runtime-verge-mihomo.yaml     # 运行时壳（保持不变）
│   └── 20-routing-mihomo.yaml           # 路由骨架（proxy-groups + 空的 rules 占位符）
│
├── rulesets/_anchors/                    # 规则片段目录（维护侧）
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
├── extend/airport-rule-split-extend.yaml  # 完整的标准规则（145条，纳入git管理）
│
├── generated/airport-rule-split.local.yaml  # 本机产物（148条，+本地私有规则，不纳入git）
│
└── scripts/
    ├── compose.sh                         # 生成 extend 文件（注入片段规则）
    └── render-local.sh                    # 生成本地文件（IP替换 + 本地规则注入）
```

---

## 清晰的流程

### 第一层：生成标准规则（compose.sh）
```
derive/parts/
  ├── 10-runtime-verge-mihomo.yaml    # 运行时壳
  └── 20-routing-mihomo.yaml          # 路由骨架（proxy-groups + 空的 rules 占位符）
           ↓ compose.sh（注入规则片段）
extend/airport-rule-split-extend.yaml  # 完整的标准规则（145条，纳入git管理）
```

**产物**：`extend/airport-rule-split-extend.yaml`
- 包含完整的 proxy-groups（29个策略组）
- 包含完整的标准规则（145条，由片段组装）
- **纳入 git 管理**

### 第二层：生成本机产物（render-local.sh）
```
extend/airport-rule-split-extend.yaml  # 标准规则模板
           ↓ render-local.sh
    1. 替换 IP 占位符（192.0.2.1 → 真实IP）
    2. 注入本地私有规则（最高优先级）
           ↓
generated/airport-rule-split.local.yaml  # 本机产物（148条，不纳入git管理）
```

**产物**：`generated/airport-rule-split.local.yaml`
- 在 extend 基础上替换 IP 占位符
- 在最前面注入本地私有规则（3条）
- **不纳入 git 管理**

---

## 使用方式（保持不变）

```bash
# 1. 修改规则片段（如修改 Cursor 规则）
vim verge/rulesets/_anchors/20-cursor.yaml

# 2. 重新生成 extend 文件（标准规则）
bash verge/derive/compose.sh -o verge/extend/airport-rule-split-extend.yaml

# 3. 生成本机产物（IP替换 + 本地规则）
bash verge/scripts/render-local.sh

# 4. 复制单个文件到 Verge（使用方式完全不变）
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

### 重构后（清晰分层）
```
修改规则片段 → rulesets/_anchors/XX-name.yaml
        ↓
bash derive/compose.sh → extend/airport-rule-split-extend.yaml（完整的标准规则，145条）
        ↓
bash scripts/render-local.sh → generated/*.local.yaml（本机产物，148条）
        ↓
全文复制到 Verge
```

### 修改规则示例

**场景：添加新的 Cursor 相关域名**

**重构前**：
1. 编辑 `derive/parts/20-routing-mihomo.yaml`（746行）
2. 找到 Cursor 段落（约行 475-487）
3. 添加新规则
4. 运行 `compose.sh` + `render-local.sh`
5. 全文复制

**重构后**：
1. 编辑 `rulesets/_anchors/20-cursor.yaml`（专注 Cursor 规则，仅 11 行）
2. 添加新规则
3. 运行 `compose.sh` 更新 extend 文件
4. 运行 `render-local.sh` 生成本地文件
5. 全文复制

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
| **标准规则总计** | **188** | extend 文件（含 RULE-SET 引用） |
| **本机产物总计** | **191** | generated 文件（+3条本地私有规则） |

---

## 关键设计决策

### 1. 保持单文件产物
- 用户反馈：复制目录比复制单文件成本高
- 方案：片段文件仅在**维护侧**存在，渲染后合并为单文件

### 2. 清晰的分层
- **extend 文件**：完整的标准规则，纳入 git 管理
- **generated 文件**：本机产物（IP替换 + 本地规则），不纳入 git

### 3. 片段顺序控制
- 使用编号前缀（00, 10, 20...）控制注入顺序
- 与命中优先级一致：私有 → 广告 → Cursor → AI → ... → 兜底

---

## 验证清单

- [x] `compose.sh` 生成完整的 extend 文件（145条标准规则）
- [x] `render-local.sh` 生成本地文件（IP替换 + 本地规则注入）
- [x] extend 文件纳入 git 管理
- [x] generated 文件不纳入 git 管理（在 .gitignore 中）
- [x] 使用方式保持不变（复制单个文件）
- [x] 规则片段逻辑分离（13个片段文件）
- [x] 本地私有规则注入正常（最高优先级）

---

*重构完成时间: 2026-05-06*
*方案版本: V2 清晰分层版（单文件 + 片段化维护）*
