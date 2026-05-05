# Verge 扩展 — 派生（主线机场稿）

## 分层

| 片段 | 文件 | 含义 |
|------|------|------|
| 文档头 | `parts/airport-dochead.txt` | 协作说明（注释，不进解析器逻辑） |
| 运行时壳 | `parts/10-runtime-verge-mihomo.yaml` | `mode` / `dns` / `sniffer` / `geodata` 等 **Verge+Mihomo 专用** |
| 路由策略 | `parts/20-routing-mihomo.yaml` | `proxy-groups` / `rule-providers` / `rules`；**多终端派生时优先复用本层语义**（其它客户端需语法翻译，不在此目录完成） |

合并稿：`verge/extend/airport-rule-split-extend.yaml`（由 `compose.sh` 生成，**应与 `parts/` 同步提交**）。

## 工作流程（重要）

**正确的迭代方式（单点修改原则）：**

1. **只修改源文件**：所有策略变更**只允许**在 `parts/` 目录下的源文件中进行
   - 改 `proxy-groups` / `rules` → 编辑 `parts/20-routing-mihomo.yaml`
   - 改 `dns` / `sniffer` / `geodata` → 编辑 `parts/10-runtime-verge-mihomo.yaml`

2. **禁止直接修改**：**永远不要**手动编辑 `verge/extend/airport-rule-split-extend.yaml`
   - 该文件是**生成产物**，任何手动修改都会被 `compose.sh` 覆盖
   - 直接修改会导致源文件与生成文件不一致，造成重复工作和逻辑混乱

3. **生成合并稿**：修改完成后，必须执行：
   ```bash
   bash verge/derive/compose.sh -o verge/extend/airport-rule-split-extend.yaml
   ```

4. **提交两者**：`git add` 时同时包含：
   - `verge/derive/parts/*.yaml`（源文件，变更逻辑）
   - `verge/extend/airport-rule-split-extend.yaml`（生成文件，同步状态）

## 命令

```bash
# 写入合并稿（改 parts 后必做）
bash verge/derive/compose.sh -o verge/extend/airport-rule-split-extend.yaml

# 校验合并稿与 parts 是否一致（CI / 提交前）
bash verge/derive/verify-compose.sh
```

`verge/scripts/render-local.sh` 在渲染 `airport-rule-split-extend.yaml` 时会**默认**先执行合并；应急可设 **`VERGE_SKIP_COMPOSE=1`** 只对手改合并稿做 IP 替换（应尽快把改动回填 `parts/`）。

## 与个人稿的关系

`extend/` 下其它 **`*-rule-split-extend.yaml`** 不经 `parts/`，仍按 `VERGE_EXTEND_FILE` 选用；个人稿与主线派生链路无关。
