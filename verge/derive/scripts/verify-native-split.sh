#!/usr/bin/env bash
# =============================================================================
# 交叉验收：原生/ISP 节点分流（INI 真值 + SubConverter 运行时）
# =============================================================================
# 用法（仓库根）:
#   bash verge/derive/scripts/verify-native-split.sh
#
# 可选环境变量:
#   SUBCONVERTER_VERIFY_URL  完整 sub 链接（含 config=gist raw ini）
#   GIST_RAW_INI_URL         gist raw config.local.ini（用于检查 6–7）
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
INI="${ROOT}/verge/generated/config.local.ini"

SUBCONVERTER_VERIFY_URL="${SUBCONVERTER_VERIFY_URL:-http://192.168.0.6:25500/sub?target=clash&url=https%3A%2F%2Fcc.hjshome.cc%2Fclash%2F2nyd0fv1fx7bihor&insert=false&config=https%3A%2F%2Fgist.githubusercontent.com%2FHouJia%2F54a5b224ac542a03beebf6701053269f%2Fraw%2Fconfig.local.ini&emoji=true&list=true&tfo=false&scv=true&fdn=false&expand=true&sort=false&new_name=true}"
GIST_RAW_INI_URL="${GIST_RAW_INI_URL:-https://gist.githubusercontent.com/HouJia/54a5b224ac542a03beebf6701053269f/raw/config.local.ini}"

[[ -f "${INI}" ]] || {
  echo "error: 缺少 ${INI}，请先 bash verge/derive/scripts/render-local.sh" >&2
  exit 2
}

failures=0
pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }

# --- 检查 6：地区 url-test filter 末尾勿为 .*$（subconverter #119）---
while IFS= read -r line; do
  group="${line#custom_proxy_group=}"
  group="${group%%\`*}"
  filter_field="$(printf '%s' "${line}" | awk -F'`' '{print $3}')"
  if [[ "${filter_field}" == *'(美国|US|USA|United States).*$'* ]] \
    || [[ "${filter_field}" == *'(香港|HK|Hong Kong).*$'* ]] \
    || [[ "${filter_field}" == *'(台湾|TW|Taiwan).*$'* ]] \
    || [[ "${filter_field}" == *'(新加坡|SG|Singapore).*$'* ]] \
    || [[ "${filter_field}" == *'(日本|JP|Japan).*$'* ]]; then
    fail "本地 INI ${group} filter 仍含地区末尾 .*$（subconverter 兼容）"
  else
    pass "本地 INI ${group} filter 无地区末尾 .*$"
  fi
done < <(rg '^custom_proxy_group=地区 ·' "${INI}" || true)

# --- 检查 7：gist 美国组/自动最优 与本地关键行一致 ---
local_us="$(rg '^custom_proxy_group=地区 · 🇺🇸 美国节点' "${INI}" || true)"
local_auto="$(rg '^custom_proxy_group=底座 · ♻️ 自动最优' "${INI}" || true)"
gist_ini="$(curl -sL "${GIST_RAW_INI_URL}?t=$(date +%s)")"
gist_us="$(printf '%s' "${gist_ini}" | rg '^custom_proxy_group=地区 · 🇺🇸 美国节点' || true)"
gist_auto="$(printf '%s' "${gist_ini}" | rg '^custom_proxy_group=底座 · ♻️ 自动最优' || true)"

if [[ "${local_us}" == "${gist_us}" ]]; then
  pass "gist 与本地 美国组 custom_proxy_group 一致"
else
  fail "gist 与本地 美国组不一致\n  local: ${local_us}\n  gist:  ${gist_us}"
fi
if [[ "${local_auto}" == "${gist_auto}" ]]; then
  pass "gist 与本地 自动最优 custom_proxy_group 一致"
else
  fail "gist 与本地 自动最优不一致"
fi

# --- 检查 1–5：SubConverter 运行时 YAML ---
tmp_yaml="$(mktemp)"
trap 'rm -f "${tmp_yaml}"' EXIT
if ! curl -sfL "${SUBCONVERTER_VERIFY_URL}" -o "${tmp_yaml}"; then
  fail "无法 curl SubConverter（${SUBCONVERTER_VERIFY_URL}）"
else
  pass "SubConverter YAML 已拉取"
  python3 - "${tmp_yaml}" <<'PY' || failures=$((failures + 1))
import re, sys, yaml
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    data = yaml.safe_load(f)
native_re = re.compile(r"原生|isp", re.I)
failed = []
for g in data.get("proxy-groups", []):
    if g.get("type") != "url-test":
        continue
    bad = [p for p in g.get("proxies", []) if native_re.search(str(p))]
    if bad:
        failed.append(f"{g['name']}: {bad}")
native = next((g for g in data["proxy-groups"] if g["name"] == "底座 · 🏠 原生 ISP"), None)
if not native:
    failed.append("缺少 底座 · 🏠 原生 ISP")
else:
    proxies = native.get("proxies", [])
    non_native = [p for p in proxies if not native_re.search(str(p))]
    if non_native:
        failed.append(f"原生 ISP 组含非原生节点: {non_native}")
    if not any(native_re.search(str(p)) for p in proxies):
        failed.append(f"原生 ISP 组无原生节点: {proxies}")
if failed:
    for item in failed:
        print(f"FAIL: {item}", file=sys.stderr)
    sys.exit(1)
print("PASS: 全部 url-test 无原生/isp；原生 ISP 组仅原生/isp")
PY
fi

if [[ "${failures}" -gt 0 ]]; then
  echo "VERDICT: FAIL (${failures} 项)" >&2
  exit 1
fi
echo "VERDICT: PASS（INI + gist + SubConverter 交叉验收）"
exit 0
