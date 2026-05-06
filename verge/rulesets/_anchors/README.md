# 规则锚点片段（Rule Anchor Fragments）

本目录包含 YAML 锚点格式的规则片段，用于 `render-fragments.sh` 组装到主配置。

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

片段文件**仅包含规则列表**，不含锚点定义：

```yaml
# 文件头部注释（策略组、说明）
- DOMAIN-SUFFIX,example.com,🔜 策略组名
- IP-CIDR,1.2.3.0/24,🔜 策略组名,no-resolve
```

渲染脚本会自动添加锚点定义：
```yaml
_rules-name: &rules-name
  - DOMAIN-SUFFIX,example.com,🔜 策略组名
```

## 修改流程

1. 编辑本目录下的片段文件（如修改 Cursor 规则 → 编辑 `20-cursor.yaml`）
2. 运行渲染脚本组装：
   ```bash
   bash verge/scripts/render-fragments.sh
   bash verge/scripts/render-local.sh
   ```
3. 复制生成的 `generated/*.local.yaml` 到 Verge

## 注意事项

- **不要**在片段文件中手动添加锚点定义（`&anchor`），由脚本自动添加
- **不要**修改片段文件中的策略组名称，必须与 `proxy-groups` 中定义的一致
- 保持编号前缀连续性，便于顺序控制
