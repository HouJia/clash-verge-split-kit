# Derive 流程配置格式规范

> 本规范用于 `render-local.sh` 生成 INI 和 YAML 时统一格式。

## 通用格式原则

### 1. 节分隔
- 每个规则类别（节）前后有空行
- 节标题使用分隔线：`================== 编号-标题 ==================`

### 2. 注释规范
- 节标题前有注释说明用途
- 节内规则分组前有子注释说明
- 保留原始片段中的注释内容

### 3. 规则间隔
- 同类规则之间根据语义分组加空行
- 不同类型规则（DOMAIN vs IP-CIDR）之间加空行

## INI 格式示例

```ini
; ================== 30-场景 · 🧠 境外 AI ==================
; OpenAI / ChatGPT / Codex / Anthropic / Claude / Claude Code

; OpenAI 域名对齐官方 Network recommendations
ruleset=场景 · 🧠 境外 AI,[]DOMAIN-SUFFIX,openai.com
ruleset=场景 · 🧠 境外 AI,[]DOMAIN-SUFFIX,chatgpt.com
...

; Anthropic / Claude
ruleset=场景 · 🧠 境外 AI,[]DOMAIN-SUFFIX,anthropic.com
ruleset=场景 · 🧠 境外 AI,[]DOMAIN-SUFFIX,claude.ai

; GEOSITE 兜底（新子域）
ruleset=场景 · 🧠 境外 AI,[]GEOSITE,openai
ruleset=场景 · 🧠 境外 AI,[]GEOSITE,anthropic


; ================== 40-场景 · 📢 谷歌推送 ==================
; FCM / Firebase Cloud Messaging
; 放在 GEOSITE,google 前面避免被截胡

; Android 设备推送服务
ruleset=场景 · 📢 谷歌推送,[]DOMAIN,mtalk.google.com
...

; IP 段覆盖 Google 推送服务出口
ruleset=场景 · 📢 谷歌推送,[]IP-CIDR,64.233.177.188/32,no-resolve
...
```

## YAML 格式对应

```yaml
# ================== 30-场景 · 🧠 境外 AI ==================
# OpenAI / ChatGPT / Codex / Anthropic / Claude / Claude Code

# OpenAI 域名对齐官方 Network recommendations
- DOMAIN-SUFFIX,openai.com,场景 · 🧠 境外 AI
- DOMAIN-SUFFIX,chatgpt.com,场景 · 🧠 境外 AI
...

# Anthropic / Claude
- DOMAIN-SUFFIX,anthropic.com,场景 · 🧠 境外 AI
- DOMAIN-SUFFIX,claude.ai,场景 · 🧠 境外 AI

# GEOSITE 兜底（新子域）
- GEOSITE,openai,场景 · 🧠 境外 AI
- GEOSITE,anthropic,场景 · 🧠 境外 AI


# ================== 40-场景 · 📢 谷歌推送 ==================
# FCM / Firebase Cloud Messaging
# 放在 GEOSITE,google 前面避免被截胡

# Android 设备推送服务
- DOMAIN,mtalk.google.com,场景 · 📢 谷歌推送
...

# IP 段覆盖 Google 推送服务出口
- IP-CIDR,64.233.177.188/32,场景 · 📢 谷歌推送,no-resolve
...
```

## 关键规则

1. **节分隔线**：`================== 编号-标题 ==================`
2. **空行**：
   - 节与节之间：2个空行
   - 节标题与内容之间：1个空行
   - 规则子分组之间：1个空行
3. **注释保留**：所有 `;` 或 `#` 开头的说明性注释都应保留
4. **子分组注释**：如 `; OpenAI 域名...`、`; Anthropic / Claude`、`; IP 段覆盖...`

## 片段文件头格式

片段文件（如 `30-ai.ini`）的前两行定义节标题和说明：

```ini
; 场景 · 🧠 境外 AI
; OpenAI / ChatGPT / Codex / Anthropic / Claude / Claude Code
```

生成时转换为：
- INI: `; ================== 30-场景 · 🧠 境外 AI ==================`
- YAML: `# ================== 30-场景 · 🧠 境外 AI ==================`

## 文件名到编号映射

| 文件名 | 编号 | 节标题 |
|--------|------|--------|
| 00-private.ini | 00 | 私有/局域网规则（基础直连） |
| 10-ads.ini | 10 | 广告拦截与遥测净化规则 |
| 20-cursor.ini | 20 | 工具 · 🔜 Cursor |
| 30-ai.ini | 30 | 场景 · 🧠 境外 AI |
| 35-messaging.ini | 35 | 场景 · 💬 即时通讯 |
| 40-fcm.ini | 40 | 场景 · 📢 谷歌推送 |
| 45-streaming.ini | 45 | 场景 · 🎬 海外音影社 |
| 50-dev.ini | 50 | 场景 · 🐙 开发源站 |
| 55-scholar.ini | 55 | 场景 · 📚 学术与数据 |
| 60-tech-giants.ini | 60 | 大厂 · 🔍 谷歌 / 大厂 · 🍎 苹果 / 大厂 · 💠 微软跨境 / 大厂 · 🪟 微软 |
| 65-gaming.ini | 65 | 场景 · 🎮 游戏平台 |
| 70-domestic.ini | 70 | 国内直连 |
| 80-geo.ini | 80 | 地理分流与兜底 |
