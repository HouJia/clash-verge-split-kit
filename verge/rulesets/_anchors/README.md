# 规则锚点片段（Rule Anchor Fragments）

本目录包含规则片段文件，由 `compose.sh` 组装到 `extend/airport-rule-split-extend.yaml`。

## 命名规范

文件名格式：`NN-name.yaml`，其中：
- `NN`：两位数字前缀，控制组装顺序（与 rules 命中顺序一致）
- `name`：策略组语义缩写（小写，连字符分隔）

## 片段列表

| 文件 | 策略组 | 说明 |
|------|--------|------|
| `00-private.yaml` | DIRECT | 私有/局域网直连 |
| `10-ads.yaml` | 🚫/🍃 | 广告拦截与遥测净化 |
| `20-cursor.yaml` | 🔜 工具 · Cursor | Cursor IDE 规则 |
| `30-ai.yaml` | 🧠 场景 · 境外 AI | OpenAI/ChatGPT/Claude |
| `35-messaging.yaml` | 💬/👥 | 即时通讯 + 脸书系兜底 |
| `40-fcm.yaml` | 📢 场景 · 谷歌推送 | FCM 推送服务 |
| `45-streaming.yaml` | 🎬/📱 | 流媒体 + TikTok |
| `50-dev.yaml` | 🐙 场景 · 开发源站 | GitHub/Docker/npm |
| `55-scholar.yaml` | 📚 场景 · 学术与数据 | 学术数据库 |
| `60-tech-giants.yaml` | 🔍/🍎/💠/🪟 | Google/Apple/Microsoft |
| `65-gaming.yaml` | 🎮 场景 · 游戏平台 | Steam/Epic/PlayStation |
| `70-domestic.yaml` | 🔌/💳 | 国内直连 + PayPal |
| `80-geo.yaml` | 🔌/🎚️/🐟 | 地理分流 + 兜底 |

## 文件格式

片段文件**仅包含规则列表**：

```yaml
# 文件头部注释（策略组、说明）
- DOMAIN-SUFFIX,example.com,🔜 策略组名
- IP-CIDR,1.2.3.0/24,🔜 策略组名,no-resolve
```

## 修改流程

### 第一步：修改规则片段

编辑本目录下的片段文件（如修改 Cursor 规则）：
```bash
vim verge/rulesets/_anchors/20-cursor.yaml
```

### 第二步：生成标准规则文件

运行 `compose.sh` 组装片段到 extend 文件：
```bash
bash verge/derive/compose.sh -o verge/extend/airport-rule-split-extend.yaml
```

产物 `extend/airport-rule-split-extend.yaml` 包含完整的标准规则（199条），**纳入 git 管理**。

### 第三步：生成本机产物

运行 `render-local.sh` 替换 IP 并注入本地私有规则：
```bash
bash verge/scripts/render-local.sh
```

产物 `generated/airport-rule-split.local.yaml` 在标准规则基础上：
- 替换 IP 占位符（192.0.2.1 → 你的真实 IP）
- 在最前面注入本地私有规则（最高优先级）

**不纳入 git 管理**。

### 第四步：复制到 Verge

```bash
cat verge/generated/airport-rule-split.local.yaml | pbcopy
# 粘贴到 Verge 全局扩展配置
```

## 注意事项

- **不要**修改片段文件中的策略组名称，必须与 `proxy-groups` 中定义的一致
- 保持编号前缀连续性，便于顺序控制
- 每个策略组片段之间会自动插入空行，便于阅读
