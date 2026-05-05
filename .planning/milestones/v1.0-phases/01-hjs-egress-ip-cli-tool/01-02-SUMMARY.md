---
phase: 01-hjs-egress-ip-cli-tool
plan: "02"
status: complete
---

# Plan 01-02 执行摘要

## 结果

- `probes.default.yaml`：与技能脚本 `PROBES` 对齐；`probes.load_default()` 校验字段并处理 YAML 错误。
- `cli.py`：默认无参、`--simple-tsv`、`--full`、`--ipv6-skip`、`--interface` 通过子进程调用 `egress-ip-audit.sh`（`HJS_EGRESS_AUDIT_SCRIPT` 可覆盖）。
- `formatters.py`：TSV 解析、分组、`httpbin`/`cip.cc` 摘要抽取；`tests/test_formatters.py` 覆盖。

## 关键文件

- `hjs-egress-ip-cli/src/hjs_egress_ip/data/probes.default.yaml`
- `hjs-egress-ip-cli/src/hjs_egress_ip/cli.py`
- `hjs-egress-ip-cli/src/hjs_egress_ip/formatters.py`
- `hjs-egress-ip-cli/tests/test_formatters.py`

## 自检

- `pytest -q`：6 passed。
- `hjs-egress-ip --simple-tsv | head -3` 含表头 `scenario`。

## Self-Check: PASSED
