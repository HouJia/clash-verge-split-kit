# SubConverter INI 排障与原生 ISP 分流经验

| 项目 | 内容 |
|---|---|
| **创建时间** | 2026-06-25 |
| **最后更新** | 2026-06-25 |

## 更新记录

| 日期 | 更新内容 |
|---|----|
| 2026-06-25 | 初稿：沉淀原生/ISP 节点分流排查经验（订阅链路、INI 正则、#119、gist 验收） |

## 目录

- [更新记录](#更新记录)
- [适用场景](#适用场景)
- [实际订阅链路（先认清真值路径）](#实际订阅链路先认清真值路径)
- [常见误区](#常见误区)
- [INI 策略组 filter 写法](#ini-策略组-filter-写法)
- [原生 ISP 分组设计](#原生-isp-分组设计)
- [症状 → 原因 → 处理](#症状--原因--处理)
- [验收与回归](#验收与回归)
- [相关文件](#相关文件)

## 适用场景

在 Clash Verge 中通过 **机场订阅 + SubConverter + gist 上的 `config.local.ini`** 拉取配置时，出现下列任一情况，优先对照本文：

- `地区 · 🇺🇸 美国节点` 等 **url-test 组里仍出现「原生 / isp」命名节点**
- 只改了 `render-local.sh` 生成的 YAML `exclude-filter`，Verge **刷新订阅后无变化**
- gist 已更新，SubConverter 输出仍像旧版
- 本地 pytest 全绿，但 NAS SubConverter 运行时节点列表不对

## 实际订阅链路（先认清真值路径）

典型 Sub 链接形态（`config=` 指向 gist raw INI）：

```text
http://<subconverter>/sub?target=clash&url=<机场订阅>&config=https://gist.githubusercontent.com/.../raw/config.local.ini&...
```

数据流：

```text
verge/derive/parts/20-routing.ini     ← 仓库真值（改这里）
        │ compose-ini.sh → render-local.sh
        ▼
verge/generated/config.local.ini      ← 本机产物
        │ sync-generated-gists.sh
        ▼
gist raw config.local.ini             ← SubConverter 实际读取
        │ SubConverter 转换
        ▼
Clash Verge 订阅 YAML                 ← 你在客户端看到的分组与节点
```

**结论：** 走 SubConverter 时，**运行时生效的是 INI 里 `custom_proxy_group` 第三段（filter 正则）**，不是 `verge/generated/config.local.yaml` 里的 `exclude-filter`。

## 常见误区

| 误区 | 为什么无效 |
|------|------------|
| 只给 YAML 的 url-test 组加 `exclude-filter` | SubConverter **不读** extend YAML；它只解析 INI 的 `custom_proxy_group` |
| 只改 `verge/generated/*` 不跑 render / 不同步 gist | `generated/` 不进 Git；gist 未更新则 Sub 仍用旧 INI |
| 在地区 filter 末尾写 `.*$`「兜底」 | 触发 subconverter [#119](https://github.com/tindy2013/subconverter/issues/119)：会把**未匹配进其它组的剩余节点**也塞进该 url-test 组 |
| 使用 `(?:…)` 非捕获组 | 部分 SubConverter 版本对复杂正则支持不稳定，负向前瞻 `(?!…)` + 普通分组更稳妥 |

## INI 策略组 filter 写法

格式（反引号分隔）：

```ini
custom_proxy_group=组名`类型`filter正则`测速URL`间隔,,容差
```

### 排除原生 / ISP（所有 url-test 组共用）

```ini
(?i)^(?!.*(海外用户专用|原生|isp))
```

- `(?i)`：不区分大小写（匹配 `ISP`、`isp`、`原生` 等）
- 负向前瞻 `(?!…)`：节点名含这些子串则**不进入**该 url-test 组

### 底座 · ♻️ 自动最优（catch-all，**可以**用末尾 `.*$`）

```ini
custom_proxy_group=底座 · ♻️ 自动最优`url-test`(?i)^(?!.*(海外用户专用|原生|isp)).*$`http://www.gstatic.com/generate_204`300,,50
```

### 地区 url-test（**禁止**在地区关键字后再加 `.*$`）

**错误（会把其它节点吸进美国组）：**

```ini
….*(美国|US|USA|United States).*$`http://…
```

**正确（filter 在地区关键字后直接接反引号）：**

```ini
custom_proxy_group=地区 · 🇺🇸 美国节点`url-test`(?i)^(?!.*(海外用户专用|原生|isp)).*(美国|US|USA|United States)`http://www.gstatic.com/generate_204`300,,50
```

港/台/新/日同理。**例外：** `地区 · 🌍 其它国家` 是排除已知地区后的兜底，仍使用 `.*$`。

### 仅原生 / ISP 节点（select 手动组）

```ini
custom_proxy_group=底座 · 🏠 原生 ISP`select`(?i).*(原生|isp).*
```

## 原生 ISP 分组设计

| 组 | 类型 | 节点来源 | 说明 |
|----|------|----------|------|
| 底座 · ♻️ 自动最优 | url-test | 非原生、非 ISP | **不含**「原生 ISP」子组选项 |
| 底座 · 🏠 原生 ISP | select | 名称含「原生」或 `isp` | 手动选用 |
| 底座 · 🔌 国内直连 | select | DIRECT + 可切原生/自动最优 | 顺序：直连 → 原生 ISP → 自动最优 |
| 含「国内直连」选项的业务 select 组 | select | — | 选项链中注入 `[]底座 · 🏠 原生 ISP` |

YAML 侧（`convert-ini-to-yaml.sh` / `render-local.sh`）：除「底座 · 🏠 原生 ISP」外，所有 url-test 组仍写 `exclude-filter: '(?i)(海外用户专用|原生|isp)'`，供**直接贴 YAML** 或 Mihomo 本地 extend 路径使用；与 SubConverter 路径**并行**，不可互相替代。

## 症状 → 原因 → 处理

| 症状 | 常见原因 | 处理 |
|------|----------|------|
| 美国 url-test 组仍有「梅萨-原生」 | 地区 filter 末尾仍有 `.*$` | 改 `20-routing.ini`，去掉地区后的 `.*$` → compose → render → sync gist |
| 改 YAML 无效 | 订阅走 SubConverter INI | 改 INI 第三段 filter，见上文 |
| 本地对、Verge 仍旧 | gist CDN 延迟或未 sync | `sync-generated-gists.sh` 后等 1～2 分钟；Verge **更新订阅** |
| pytest 过、SubConverter 不过 | 验的是本地文件，不是 gist/运行时 | 跑 `verify-native-split.sh`（含 gist + curl SubConverter） |
| Sub-Store 与 SubConverter 行为不一致 | 两者都读 INI，但版本/正则实现差异 | 以 NAS SubConverter 实测 YAML 为准；关键行写进 pytest + verify 脚本 |

## 验收与回归

**推荐顺序（仓库根目录）：**

```bash
bash verge/derive/scripts/compose-ini.sh
bash verge/derive/scripts/render-local.sh          # 内置 65 项 pytest
bash verge/derive/scripts/verify-native-split.sh   # INI + gist + SubConverter 交叉验收
bash verge/derive/scripts/sync-generated-gists.sh # 推送 gist 后再跑 verify
```

`verify-native-split.sh` 检查项摘要：

1. 地区 url-test filter **无**「地区关键字 + `.*$`」错误形态  
2. gist raw 与本地 `config.local.ini` 关键行一致  
3. curl SubConverter 产出 YAML：全部 url-test 无原生/isp；「底座 · 🏠 原生 ISP」仅含原生/isp 节点  

环境变量（可选）：

- `SUBCONVERTER_VERIFY_URL`：完整 sub 链接  
- `GIST_RAW_INI_URL`：gist raw INI 地址  

**pytest 相关用例：** `verge/tests/test_config.py` 中 `test_119_*`（全 url-test 排除原生）、`test_120_*`（地区 filter 无末尾 `.*$`）。

## 相关文件

| 文件 | 作用 |
|------|------|
| [`parts/20-routing.ini`](parts/20-routing.ini) | INI 真值：策略组与 filter |
| [`scripts/verify-native-split.sh`](scripts/verify-native-split.sh) | 交叉验收脚本 |
| [`scripts/sync-generated-gists.sh`](scripts/sync-generated-gists.sh) | 同步 gist 并自动 verify |
| [`../tests/test_config.py`](../tests/test_config.py) | 配置回归测试 |
| [`../README.md`](../README.md) | 日常 compose / render / sync 流程 |
