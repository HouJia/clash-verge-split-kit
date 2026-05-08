# Clash Verge 扩展分流（模板 + 本机稿）

长期目标、多端路线与脱敏红线见 **[`docs/clash-verge/RULEBASE-PROGRAM.md`](../docs/clash-verge/RULEBASE-PROGRAM.md)**；订阅配置的拆解与审计材料已脱敏移至 **`docs/clash-verge/`**。  
**主线机场稿**的真值源为 **`derive/parts/`**（分层见 **[`derive/README.md`](derive/README.md)**），合并为 **`template/airport-rule-split-extend.yaml`** 后再走 `render-local.sh`；个人/专用稿仍只维护 **`template/`** 下其它文件名。

本目录 **`verge/template/*-rule-split-extend.yaml`**：代理分组、`rules`、`dns` 等，**不包含**节点。`render-local.sh` **默认**读合并后的 `airport-rule-split-extend.yaml`（渲染前会先 **`scripts/derive/compose.sh`**，除非 `VERGE_SKIP_COMPOSE=1`）。命名：**Extend** 须以 **`-extend.yaml`** 结尾；产物去掉 **`-extend`** 加 **`.local.yaml`**。

## 文件说明

| 路径 | 说明 |
|------|------|
| [`derive/README.md`](derive/README.md) | **主线机场稿**：`parts/` 分层（Verge/Mihomo 运行时 vs `proxy-groups`+`rules`）→ **`scripts/derive/compose.sh`** → `template/airport-rule-split-extend.yaml`。 |
| [`template/airport-rule-split-extend.yaml`](template/airport-rule-split-extend.yaml) | **默认主线合并稿**（由 **`derive/parts/`** 生成；日常改策略请编辑 **`derive/parts/20-routing-mihomo.yaml`** 等后再 `compose.sh` / `render-local.sh`）。含 **`# >>> rulebase:*`** 分段。 |
| [`template/` 下其它 `*-rule-split-extend.yaml`](template/) | **个人/专用稿**：不经 `derive/parts/`；渲染时 **`VERGE_EXTEND_FILE`** 为**文件名**。 |
| `generated/` 下 **`*-rule-split.local.yaml`** | **本机产物**：与各 Extend **一一成对**（见上文命名约定）；任选其一全文复制进 Verge **全局扩展配置**。**勿提交**。 |
| [`scripts/render-local.sh`](scripts/render-local.sh) | 对 **`airport-rule-split-extend.yaml`**：**先** `scripts/derive/compose.sh` 写入合并稿（可用 **`VERGE_SKIP_COMPOSE=1`** 跳过）；再 **`sed`** 替换 **`YOUR_VPS_IP`** / **`192.0.2.1`**；可选并入 **`generated/local/override.local.ini`** 的 **`[rules]`**（INI 格式）。`VERGE_EXTEND_FILE` 选其它 extend **文件名**。 |
| [`generated/local/override.local.ini.example`](generated/local/override.local.ini.example) | 复制为 **`generated/local/override.local.ini`**（勿提交）；INI 格式，含 **`[vps]`** 与 **`[rules]`** 节。 |

**忽略规则（根 `.gitignore`）：** **`*.local.yaml`** 覆盖仓库内任意位置的 Mihomo 粘贴稿；**`verge/generated/*`** 默认可忽略，**仅放行 `verge/generated/local/*.example`**（本机覆写 **`override.ini`** 不在仓库中）。

## 一次性配置（本机）

1. **本机合并配置（推荐）**  
   ```bash
   cp verge/generated/local/override.local.ini.example verge/generated/local/override.local.ini
   # 编辑：在 [vps] 下写一行公网 IPv4；按需填写 [rules-before-cn]（可留空仅注释）
   ```
   **说明：** Hooks / 无参运行依赖 **`[vps]`** 中已填写 IPv4，或本机已导出 **`VPS_PUBLIC_IP`**。

2. **Git 提交前自动生成（可选）**  
   ```bash
   chmod +x .githooks/pre-commit   # 若 git 提示 hook 无法执行
   git config core.hooksPath .githooks
   ```
   之后凡 **暂存** **`verge/derive/parts/*`**、**`verge/template/airport-rule-split-extend.yaml`** 或任一其它 **`verge/template/*-rule-split-extend.yaml`** 并 `git commit`：会先校验 **parts 与 airport 合并稿一致**（仅涉机场稿时）；并对 template 尝试渲染 `generated/*-rule-split.local.yaml`（失败仅提示，不拦提交）。

3. **Cursor 保存后自动生成（可选）**  
   仓库已含 [`.cursor/hooks.json`](../.cursor/hooks.json)：编辑 **`verge/derive/parts/*`** 或 **`verge/template/*-rule-split-extend.yaml`** 并保存后，会调用 [`after-rule-split-extend-edit.sh`](../.cursor/hooks/after-rule-split-extend-edit.sh)（parts：`compose` + `render-local`；template：按文件名 `VERGE_EXTEND_FILE=… render-local.sh`）。需在 Cursor **信任本工作区** 且 Hooks 已启用。

## 日常流程

1. **主线机场稿**：编辑 **`verge/derive/parts/`**（**`10-runtime-verge-mihomo.yaml`** 或 **`20-routing-mihomo.yaml`**）；保存后 **`render-local.sh` / Hook** 会先 `compose` 再生成 `generated/`（也可手工：`bash verge/scripts/derive/compose.sh -o verge/template/airport-rule-split-extend.yaml`）。  
2. **个人稿**：直接编辑 **`verge/template/`** 下非 `airport` 的 **`*-rule-split-extend.yaml`**。  
3. **自动生成**：若已配置 `generated/local/override.local.ini`（`[vps]`，INI 格式）且使用 Cursor Hooks，或提交前 Hook，会得到最新的 **`generated/config.local.yaml`**。  
4. **手动生成**（任意时刻）：  
   ```bash
   bash verge/scripts/render-local.sh
   # 或改用个人稿：
   # VERGE_EXTEND_FILE=myvps-DO-rule-split-extend.yaml bash verge/scripts/render-local.sh
   # 或未写 override.ini 的 [vps] 时：
   bash verge/scripts/render-local.sh 你的公网IPv4
   ```  
5. 打开 `generated/airport-rule-split.local.yaml`（或当前稿对应的 `*-rule-split.local.yaml`）→ 全选复制 → Verge **全局扩展配置** → 保存；**模式** 选 **规则（Rule）**。

本稿可直接 **`template/airport-rule-split-extend.yaml` 全文复制**到 Verge 全局扩展：**代理组与分流规则**已在 Extend 内（与主配置订阅的 **节点** 通过 `include-all-proxies` 衔接；换机场如「忍者云」时只要订阅里节点名在合并后仍对 `proxy-groups` 可见即可）。**`reject-loyal`** 为 **http** 型：首次重载需能访问外网以下载规则集，缓存在配置目录 `./ruleset/reject-loyal.txt`（与旧版说明一致）。**模块化 `RULE-SET` / `rule-providers`** 在 `# >>> rulebase:*` 与 `# <<< rulebase:*` 之间**手工维护**（可由 `verge/analysis` 的整理结论反哺）；两段留空亦可正常运行。

占位 **`YOUR_VPS_IP`** / **`192.0.2.1/32`** 均为模板中的**非真实地址**（便于把 Extend 提交进仓库）；渲染时用脚本 **`sed` 全文替换**为你的公网 IPv4 后，**`IP-CIDR,…/32,DIRECT`** 才指向你的 VPS。若模板改用其它占位，请同步修改 `scripts/render-local.sh` 中的 `grep` / `sed`。

## Verge / 订阅侧手检（与计划对齐）

以下项**不在**本 YAML 内，需在 Clash Verge Rev 中自行核对：

- **合并**：确认全局扩展与订阅合并后，本片段里的 `dns`、`rule-providers` 未被静默覆盖（订阅若自带同名顶层键需注意顺序）。
- **控制面**：`external-controller` 建议绑 `127.0.0.1`；`secret` 非空；与「局域网设备走代理端口 (`allow-lan` + mixed-port）」区分开。
- **自动选节点**：订阅里 `url-test` 的 `interval` 建议 **300～600 秒**，避免整日不测速。
- **TLS**：抽样节点可把 `skip-cert-verify` 改为 `false` 试错；握手失败则保持 `true` 或核对 `sni`。

**协作说明：** 在 Cursor **外**用编辑器改模板（未触发 Cursor Hook）时，可在仓库根执行一次 `bash verge/scripts/render-local.sh`。终端 Agent 在本仓库修改该模板后，也应执行同命令以保持 `generated/` 下成对 `*-rule-split.local.yaml` 与模板一致。

更多概念见 [`docs/clash-verge/local-split-vps.md`](../docs/clash-verge/local-split-vps.md)；官方 Extend：[Clash Verge — Extend](https://www.clashverge.dev/guide/extend.html)。
