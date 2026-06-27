# WebRTC 封闭 — INI 模板方案（旁路由 + Verge 共用）

| 项目 | 内容 |
|---|---|
| **创建时间** | 2026-06-27 |
| **最后更新** | 2026-06-27 |

## 更新记录

| 日期 | 更新内容 |
|---|----|
| 2026-06-27 | 接入 compose：`20-routing.ini` WebRTC 组、`compose-ini.sh` 含 `05-webrtc.ini`；已推 gist + GitHub `a621cfa`；旁路由更新订阅并清 custom |

## 目录

- [更新记录](#更新记录)
- [已对齐决策](#已对齐决策)
- [规则真值路径](#规则真值路径)
- [INI 改动清单（待你迭代）](#ini-改动清单待你迭代)
- [旁路由侧保留什么](#旁路由侧保留什么)
- [验收流程](#验收流程)
- [Verge 本机测 WebRTC](#verge-本机测-webrtc)
- [为何按端口、不只 Google](#为何按端口不只-google)
- [相关仓库](#相关仓库)

## 已对齐决策

| # | 决策 |
|---|------|
| 1 | **旁路由 + Verge 桌面** 共用 **同一条 SubConverter 转换 URL**（gist 上的 `config.local.ini`） |
| 2 | **WebRTC 策略组默认 REJECT**；要测 WebRTC 时在 Verge/OpenClash 面板 **手动改 WebRTC 组** |
| 3 | **规则写在本文仓库**（`clash-verge-split-kit`），**不**在 `side-router-lab` 的 OpenClash custom 里长期维护 STUN 规则 |
| 4 | **旁路由** 仅保留 **`verify-webrtc-gate.sh` 自动验收**；table354 钩子、旁路由 custom STUN **可回滚默认** |

## 规则真值路径

```text
clash-verge-split-kit
  verge/derive/parts/20-routing.ini          ← 增加「系统 · 📡 WebRTC」策略组
  verge/derive/parts/rulesets/05-webrtc.ini  ← STUN/TURN UDP 端口规则（草稿）
        │ compose-ini.sh → render-local.sh
        ▼
verge/generated/config.local.ini
        │ sync-generated-gists.sh
        ▼
gist raw config.local.ini                    ← SubConverter config=
        │ SubConverter + 机场订阅
        ▼
  ├─ Clash Verge（Mac TUN）
  └─ R4S 旁路由 OpenClash（fake-ip + TProxy）   ← 同一套 rules / proxy-groups
```

**旁路由 OpenClash 的分流规则以本仓库生成并经 SubConverter 转换后的 YAML 为准**；详见 [`side-router-lab` 交叉引用](#相关仓库)。

## INI 改动清单（已接入）

### 1. `verge/derive/parts/20-routing.ini` — 新增策略组 ✅

放在 **系统组**（广告拦截附近），**`[]REJECT` 放第一位** 作默认：

```ini
; 系统 · 📡 WebRTC：STUN/TURN UDP；默认 REJECT 封闭；可改选地区/底座组做试验
custom_proxy_group=系统 · 📡 WebRTC`select`.*`[]REJECT`[]地区 · 🇺🇸 美国节点`[]底座 · ♻️ 自动最优`[]底座 · 🎚️ 手动切换`[]地区 · 🇭🇰 香港节点`[]地区 · 🌺 台湾节点`[]地区 · 🇸🇬 新加坡节点`[]地区 · 🇯🇵 日本节点`[]地区 · 🌍 其它国家`[]底座 · 🏠 原生 ISP`[]底座 · 🔌 国内直连`[]DIRECT
```

### 2. `verge/derive/parts/rulesets/05-webrtc.ini` — 端口规则（已建草稿）

**必须排在 rulesets 最前段**（`compose-ini.sh` 里在 `00-private` 之后、`10-ads` 之前），避免被 GeoSite 抢先：

```ini
; WebRTC / STUN / TURN — 按 UDP 端口（各厂商 STUN 通用，不限 Google）
ruleset=系统 · 📡 WebRTC,[]AND,((NETWORK,udp),(DST-PORT,3478))
ruleset=系统 · 📡 WebRTC,[]AND,((NETWORK,udp),(DST-PORT,5349))
ruleset=系统 · 📡 WebRTC,[]AND,((NETWORK,udp),(DST-PORT,19302))
```

> **SubConverter 语法待本机验证：** 合并后跑 `convert-ini-to-yaml.sh` / `verify-native-split.sh`，确认 YAML 中出现三条 `AND,...WebRTC` 或等价 REJECT。

### 3. `verge/derive/scripts/compose-ini.sh` ✅

在 `fragments` 数组 **`00-private.ini` 之后** 已加入 `"05-webrtc.ini"`。

### 4. 日常发布

```bash
bash verge/derive/scripts/compose-ini.sh -o verge/template/config-template.ini
bash verge/derive/scripts/render-local.sh
bash verge/derive/scripts/sync-generated-gists.sh   # 推 gist
```

旁路由 LuCI **更新订阅** 后，STUN 规则应出现在 **`/etc/openclash/忍者云+cc.yaml`**，而非 `openclash_custom_rules.list`。

### 5. 旁路由 custom 清理（gist 生效后）

```bash
bash skills/hjs-side-router-setup/scripts/_ab-webrtc-set-mode.sh none   # 在 side-router-lab 仓库
```

确认 yaml 内已有 WebRTC 三条后再清 custom，避免空窗期。

## 旁路由侧保留什么

| 组件 | 保留？ | 说明 |
|------|--------|------|
| **gist INI → SubConverter → OpenClash** | ✅ 主配置 | 本仓库 |
| **`verify-webrtc-gate.sh`** | ✅ | `side-router-lab`；改 OpenClash 后跑；`--auto-fix` 临时写 custom REJECT 直至订阅生效 |
| **table354 防火墙钩子** | ❌ 回滚 | OpenClash 默认；出问题再加回 `install-openclash-custom-firewall-rules.sh` 旧版 |
| **custom STUN REJECT** | ❌ 长期不要 | gist 生效后删除；过渡期 gate 可兜底 |

## 验收流程

**本仓库（改 INI 后）：**

```bash
bash verge/derive/scripts/compose-ini.sh -o verge/template/config-template.ini
bash verge/derive/scripts/render-local.sh
bash verge/derive/scripts/convert-ini-to-yaml.sh   # 看 rules 段含 WebRTC
bash verge/derive/scripts/sync-generated-gists.sh
```

**旁路由（更新订阅后）：**

```bash
ssh side-router 'grep -E "3478|5349|19302|WebRTC" /etc/openclash/config/忍者云+cc.yaml | head -6'
bash skills/hjs-side-router-setup/scripts/verify-webrtc-gate.sh
```

**浏览器（Chrome/Safari）：** https://browserleaks.com/webrtc → **No Leak**；Public **n/a** 可接受。

## Verge 本机测 WebRTC

1. 打开 Verge → 策略组 **`系统 · 📡 WebRTC`**
2. 从 **REJECT** 改为 **地区 · 🇺🇸 美国节点**（或手动切换）
3. 测 https://browserleaks.com/webrtc
4. 测完改回 **REJECT**

旁路由与 Verge **共用 sub** 时，旁路由 OpenClash 面板里同样改 **WebRTC 组** 即可（非 custom 文件）。

## 为何按端口、不只 Google

- 浏览器 ICE 会连 **多家 STUN**（Google、Cloudflare、Mozilla、Twilio、站点自建等）。
- **按端口 3478 / 5349 / 19302** 覆盖 STUN/TURN，**不绑定** `stun.l.google.com`。
- 按 `GEOSITE,google` 分流 STUN **会漏** 非 Google 的 STUN 服务器。

## 相关仓库

| 仓库 | 职责 |
|------|------|
| **`clash-verge-split-kit`（本仓库）** | INI 真值、gist、SubConverter 输入；**旁路由与 Verge 共用规则来源** |
| **`side-router-lab`** | R4S 装机、OpenClash UCI、② only、`verify-webrtc-gate`；**不**长期维护 STUN 分流规则 |

交叉引用：`side-router-lab/skills/hjs-side-router-setup/references/webrtc-lockdown-policy.md`
