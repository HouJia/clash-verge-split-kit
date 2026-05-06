# 机场配置分析目录

本目录包含对不同机场订阅配置的离线分析和模块化拆分。

**注意**：本目录仅保留匿名的分析结果，具体的机场名称、节点信息、订阅链接等敏感信息**不得**写入此 README 或任何提交到 Git 的文件。

## 目录结构

```
verge/analysis/
├── airport-a/          # 机场A分析（匿名标识）
│   ├── modules/        # 模块化拆分后的配置（仅规则，无节点）
│   └── ori-*.yaml      # 原始订阅文件（本地保留，不提交到 git）
├── airport-b/          # 机场B分析（匿名标识）
│   ├── modules/        # 模块化拆分后的配置（仅规则，无节点）
│   └── ori-*.yaml      # 原始订阅文件（本地保留，不提交到 git）
└── README.md           # 本文件（通用说明，不含具体机场信息）

```

## 本地识别方式

由于隐私脱敏要求，目录使用匿名标识（airport-a/airport-b）。
**本地识别方法（仅本地使用，不提交到 Git）：**

1. **查看本地原始文件**：`ori-airport-*.yaml`
   - 这些文件在本地保留，包含原始的节点信息，可以识别是哪个机场

2. **根据特征识别**（仅本地判断）：
   - 查看 `modules/README.md` 中的统计数据（规则数、策略组数、节点数）
   - 对比本地笔记中记录的特征

3. **查看本机备忘录**：在本地笔记软件中记录映射关系
   - 例如：airport-a = 某机场，airport-b = 某机场

## 脱敏原则

| 类型 | 处理方式 | 示例 |
|------|----------|------|
| **禁止提交** | 机场名称、订阅链接、节点密钥、个人域名 | 机场B、机场A、机场官网 |
| **禁止提交** | 原始订阅文件（含节点信息） | `ori-*.yaml` |
| **可以提交** | 匿名标识（airport-a/b） | 仅目录名 |
| **可以提交** | 模块化规则文件（仅分流逻辑） | `modules/*.yaml`（无节点信息） |
| **可以提交** | 通用配置模板 | `20-routing-mihomo.yaml` 中的通用规则 |

## 使用方式

各机场的模块化配置用于：
1. 分析其规则物料和分流逻辑（离线学习）
2. 反哺到主配置（`verge/derive/parts/`）
3. 对比不同机场的配置风格差异

**反哺方式**：
- 从 `modules/` 中提取通用的规则模式
- 将通用规则添加到 `verge/derive/parts/20-routing-mihomo.yaml`
- 将私有/机场特定规则添加到本地 `override.local`，**不走 Git**

## 本地配置文件

对于仅本机生效的规则（如机场面板域名），使用：

```bash
verge/generated/local/override.local
```

此文件已在 `.gitignore` 中排除，**不会**提交到 Git。

示例用法：
```bash
# 1. 复制示例文件
cp verge/generated/local/override.local.example verge/generated/local/override.local

# 2. 编辑 override.local，在 [rules-before-cn] 节中添加本地规则
# 例如：机场面板域名直连、个人域名等

# 3. 重新生成配置
bash verge/scripts/render-local.sh
```

---

**隐私提醒**：
- 提交前检查：`git diff --cached` 查看暂存区变更
- 确保无机场名称、无订阅链接、无节点密钥
- 如有疑问，先本地备份再提交
