"""Tests for TSV parsing and snippet extractors."""

from __future__ import annotations

from outbound_ip.formatters import (
    build_groups,
    extract_cip_cc_ip,
    extract_httpbin_origin,
    parse_tsv_rows,
)


def test_parse_tsv_skips_header() -> None:
    tsv = (
        "scenario\tcategory\tprobe_name\turl\thttp_code\tsnippet\n"
        "S1\tdomestic\ta\tu\t200\tok\n"
    )
    rows = parse_tsv_rows(tsv)
    assert len(rows) == 1
    assert rows[0]["probe_name"] == "a"


def test_httpbin_empty_and_invalid() -> None:
    assert extract_httpbin_origin("") == ""
    assert extract_httpbin_origin("not json") == ""


def test_httpbin_valid() -> None:
    body = '{"origin": "1.2.3.4"}'
    assert "1.2.3.4" in extract_httpbin_origin(body)


def test_cip_cc_ip_line() -> None:
    html = "<html>IP : 8.8.8.8</html>"
    assert extract_cip_cc_ip(html) == "8.8.8.8"


def test_cip_fallback_truncates() -> None:
    html = "<html>no numeric ip here</html>"
    out = extract_cip_cc_ip(html)
    assert "no numeric" in out


def test_build_groups_order() -> None:
    tsv = "scenario\tcategory\tprobe_name\turl\thttp_code\ts\n"
    tsv += "S1\tmeta\tx\tu\t200\ta\n"
    tsv += "S1\tdomestic\ty\tu\t200\tb\n"
    groups = build_groups(parse_tsv_rows(tsv))
    keys = [g["key"] for g in groups]
    assert keys == ["domestic", "meta"]
