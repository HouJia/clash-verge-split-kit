# 规则锚点片段（Rule Anchor Fragments）

本目录包含规则片段文件，由 `compose.sh` 组装到 `extend/airport-rule-split-extend.yaml`。

## 快速开始

### 修改规则后必须执行

```bash
# 1. 修改片段文件（如 verge/rulesets/_anchors/20-cursor.yaml）

# 2. 生成标准规则文件并测试
bash verge/derive/compose.sh -o verge/extend/airport-rule-split-extend.yaml
bash verge/scripts/test-rules.sh          # ← 回归测试（必须！）

# 3. 生成本机产物并测试
bash verge/scripts/render-local.sh
bash verge/scripts/test-rules.sh local    # ← 测试 local 文件

# 4. 复制到 Verge
cat verge/generated/airport-rule-split.local.yaml | pbcopy
```

---

## 回归测试说明

**每次修改片段后必须运行回归测试**，确保：
- YAML 语法正确
- 所有规则引用的策略组存在
- 13 项关键规则（广告、Cursor、AI、TikTok 等）存在
- 策略组 emoji 正确（🚫/🍃/🔜 等）
- 规则顺序正确（私有→广告→Cursor→AI→...）

### 测试命令

```bash
# 测试 extend 文件（标准规则）
bash verge/scripts/test-rules.sh extend

# 测试 local 文件（本机产物）
bash verge/scripts/test-rules.sh local

# 测试全部
bash verge/scripts/test-rules.sh all
```

---

## 命名规范

文件名格式：`NN-name.yaml`
- `NN`：两位数字前缀，控制组装顺序（与 rules 命中顺序一致）
- `name`：策略组语义缩写

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
# 🧠 场景 · 境外 AI
# OpenAI / ChatGPT / Codex / Anthropic / Claude / Claude Code

- DOMAIN-SUFFIX,openai.com,🧠 场景 · 境外 AI
- DOMAIN,api.anthropic.com,🧠 场景 · 境外 AI
```

**注意**：
- 标题必须使用 emoji 策略组名（如 `🧠 场景 · 境外 AI`）
- 规则中的策略组名必须与 `proxy-groups` 中定义的一致
- emoji 字符必须正确（如 🚫 U+1F6AB，不是 🛑 U+1F6D1）

---

## 修改流程

### 第一步：修改规则片段

```bash
vim verge/rulesets/_anchors/20-cursor.yaml
```

### 第二步：生成并测试

```bash
bash verge/derive/compose.sh -o verge/extend/airport-rule-split-extend.yaml
bash verge/scripts/test-rules.sh    # ← 必须运行！
```

产物 `extend/airport-rule-split-extend.yaml` 包含完整的标准规则，**纳入 git 管理**。

### 第三步：生成本机产物并测试

```bash
bash verge/scripts/render-local.sh
bash verge/scripts/test-rules.sh local    # ← 测试 local 文件
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

---

## 注意事项

1. **必须运行回归测试**：每次修改后执行 `bash verge/scripts/test-rules.sh`
2. **emoji 必须正确**：策略组名中的 emoji 必须与 `proxy-groups` 定义完全一致
3. **策略组名一致性**：片段标题、规则中的策略组名、`proxy-groups` 定义必须一致
4. **编号前缀连续性**：保持 00, 10, 20... 顺序，控制规则注入优先级
