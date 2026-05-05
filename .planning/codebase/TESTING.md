# Testing

**Analysis Date:** 2026-05-03

## 框架与配置

- **pytest** — 版本约束 `>=7`（`hjs-egress-ip-cli/pyproject.toml` 的 `dev` extra）。
- **发现路径** — `[tool.pytest.ini_options]`：`testpaths = ["tests"]`。
- **导入路径** — `pythonpath = ["src"]`，测试中以 `from hjs_egress_ip.formatters import ...` 导入，无需安装后再跑（与可编辑安装一致）。

## 如何运行

```bash
cd hjs-egress-ip-cli
pip install -e ".[dev]"
pytest -q
```

（与 `hjs-egress-ip-cli/README.md` 一致。）

## 当前测试范围

**唯一测试模块：** `hjs-egress-ip-cli/tests/test_formatters.py`

| 用例 | 覆盖点 |
|------|--------|
| `test_parse_tsv_skips_header` | `parse_tsv_rows` 跳过首行表头 `scenario`。 |
| `test_httpbin_empty_and_invalid` / `test_httpbin_valid` | `extract_httpbin_origin` 对空、非 JSON、合法 JSON 的行为。 |
| `test_cip_cc_ip_line` / `test_cip_fallback_truncates` | `extract_cip_cc_ip` 正则提取与无 IP 时的截断回退。 |
| `test_build_groups_order` | `build_groups` 仅包含有数据的分类桶，且顺序遵循 `GROUP_ORDER`。 |

## 未覆盖或仅手动的区域

- **`cli.py`** — 无单元测试；依赖 README「端到端手动检测」与真实环境下的 `egress-ip-audit.sh`。
- **`probes.py`** — 无针对 YAML 校验失败的测试用例。
- **`web/server.py`** — 无 HTTP 层或 `subprocess` 集成测试；手动步骤见 README（`serve`、`curl /health`、`/api/run`）。
- **端到端 / 回归** — 仓库内 **无** `.github/workflows` 或其他 CI 配置文件（截至本分析日）。

## Mock 与夹具

- **当前无 unittest.mock / pytest fixture** — 测试均为纯函数与内联字符串输入，无外部服务打桩。

## 覆盖率

- **未配置** `pytest-cov` 或 `[tool.coverage.*]`；若需覆盖率需在 `dev` 依赖与 CI 中另行引入。

## 与质量门禁的关系

- v1.0 阶段材料（`.planning/milestones/v1.0-phases/01-hjs-egress-ip-cli-tool/`）记录过审查与验证；**自动化**层面目前以本地 `pytest` 为主。
