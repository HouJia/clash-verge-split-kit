---
status: applied
phase: "01"
phase_name: hjs-egress-ip-cli-tool
warnings_fixed: 2
info_fixed: 0
fixed_at: "2026-05-03"
---

# Phase 01 代码审查修复记录

## 范围

按 `01-REVIEW.md` 默认修复范围处理 **Warning**（未改 Info 项）。

## 已处理项

| 编号 | 摘要 | 修改文件 |
|------|------|----------|
| WR-01 | `Content-Length` 非十进制整数时返回 400，避免未捕获的 `ValueError` | `hjs-egress-ip-cli/src/hjs_egress_ip/web/server.py` |
| WR-02 | `/api/run` 请求体上限 64KiB，超出返回 413，并有限丢弃正文、`Connection: close` | 同上 |

## 验证

- `python3 -m ast.parse` 语法检查通过。
- 在项目内 `.venv` 下执行 `pytest tests/`，6 项通过。

## 后续

- 若需把 Info 项也落地：使用 `/gsd-code-review 1 --fix --all` 或按 `01-REVIEW.md` 中 IN 条目逐项排期。
- 合并前可自行：`git add` 上述 `server.py` 与本文档、`git commit`。
