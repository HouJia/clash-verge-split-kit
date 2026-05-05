# Phase 1 — Research（摘要）

## 分发形态对比

| 方案 | 优点 | 缺点 |
|------|------|------|
| Python + pyproject，入口 console_scripts | 与现有 `serve-audit-ui.py` 一致、迭代快 | 目标机需 Python 或 pipx |
| Go 单文件 | 单二进制易分发 | 重写探测与解析成本较高 |

**倾向：** Python 包 + `pipx install`，Web 作为 optional extra。

## 配置外置

将 `PROBES` 迁入 `probes.default.yaml`，CLI 支持 `--config` 覆盖；技能内保留默认配置同步策略在文档中说明。

## 测试

- 对 TSV 解析与分组逻辑做纯函数单元测试（不发起真实 curl 时用 fixture）。
- 可选「集成测试」标记，在 CI 默认跳过，本地 `pytest -m integration` 启用。
