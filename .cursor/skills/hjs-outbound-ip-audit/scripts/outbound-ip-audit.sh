#!/usr/bin/env bash
# 出口 IP 探测：默认「一键」只看常用不同类型站点在单一路径下的出口；--full 输出完整技术矩阵。
# 依赖：curl；可选 python3（解析 httpbin JSON）。

set -uo pipefail

CURL_TIMEOUT="${CURL_TIMEOUT:-8}"
USER_AGENT="${USER_AGENT:-Mozilla/5.0 (compatible; hjs-outbound-ip-audit/1.1)}"

MODE="simple"   # simple | full
FORMAT="pretty" # pretty | tsv（仅 simple 模式）
IPV6_SKIP=0
BIND_IFACE=""
FLAG_IPV6=0
FLAG_IFACE=0

usage() {
  cat <<'EOF'
用法: outbound-ip-audit.sh [选项]

默认（不写参数）：一键摘要 —— 各「站点类型」在「单次绕过代理环境变量」路径下的出口（适合日常查看）。

  --full              完整技术矩阵：S0 当前环境、S1 --noproxy、IPv4/IPv6、可选网卡绑定等
  --simple-tsv        与默认同路径，但只输出 TSV（含表头），供程序/UI 解析
  --ipv6-skip         仅作用于 --full：不跑 IPv6 场景
  --interface IFACE   仅作用于 --full：追加绑定网卡场景（进阶：TUN/策略路由排查）
  -h, --help          帮助

环境变量: CURL_TIMEOUT（默认 8）

说明：默认一键路径使用 curl --noproxy '*'，即单次请求不跟随 http_proxy/ALL_PROXY 等环境变量，
      便于观察「常见站点类型」各自看到的公网地址；与浏览器是否走系统代理无关。
      完整矩阵见 --full；其中 S0 为尊重当前代理变量时的行为。
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --full) MODE="full"; shift ;;
    --simple-tsv) MODE="simple"; FORMAT="tsv"; shift ;;
    --interface) BIND_IFACE="${2:-}"; FLAG_IFACE=1; shift 2 ;;
    --ipv6-skip) IPV6_SKIP=1; FLAG_IPV6=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "未知参数: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$MODE" == "simple" && ( "$FLAG_IPV6" -eq 1 || "$FLAG_IFACE" -eq 1 ) ]]; then
  echo "提示: --ipv6-skip / --interface 仅在 --full 模式下生效；一键模式已忽略。" >&2
fi

# category|name|url|parser
PROBES=(
  "domestic|ipip.net|https://myip.ipip.net|plain"
  "domestic|cip.cc|https://cip.cc|cip_cc_ip"
  "intl_plain|ipecho.net|https://ipecho.net/plain|plain"
  "intl_plain|ipify|https://api.ipify.org|plain"
  "intl_plain|ipify_v6_hint|https://api64.ipify.org|plain"
  "intl_plain|icanhazip|https://icanhazip.com|plain"
  "intl_plain|ifconfig.me|https://ifconfig.me/ip|plain"
  "intl_plain|ipinfo.io|https://ipinfo.io/ip|plain"
  "intl_plain|aws_checkip|https://checkip.amazonaws.com|plain"
  "intl_plain|ident.me|https://ident.me|plain"
  "cdn_trace|cloudflare_trace|https://1.1.1.1/cdn-cgi/trace|cloudflare_trace"
  "meta|httpbin_ip|https://httpbin.org/ip|httpbin_ip"
)

run_one() {
  local scenario="$1" category="$2" name="$3" url="$4" parser="$5"
  shift 5
  local extra=("$@")
  local errfile code body snippet
  errfile="$(mktemp -t outbound-ip-audit.XXXXXX)"

  code="$(
    curl -gfsS \
      --connect-timeout "$CURL_TIMEOUT" \
      --max-time "$CURL_TIMEOUT" \
      -A "$USER_AGENT" \
      -w '%{http_code}' \
      -o "$errfile" \
      "${extra[@]}" \
      "$url" 2>/dev/null || true
  )"
  body="$(cat "$errfile" 2>/dev/null || true)"
  rm -f "$errfile"

  case "$parser" in
    plain)
      snippet="$(printf '%s' "$body" | tr '\r\n' '  ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | cut -c1-160)"
      ;;
    cloudflare_trace)
      snippet="$(printf '%s' "$body" | grep -E '^ip=' | head -1 | tr -d '\r' | cut -c1-160)"
      ;;
    httpbin_ip)
      if command -v python3 >/dev/null 2>&1; then
        snippet="$(printf '%s' "$body" | python3 -c 'import sys,json
try:
  d=json.load(sys.stdin)
  print(str(d.get("origin",""))[:160])
except Exception:
  print("")' 2>/dev/null || true)"
      else
        snippet="$(printf '%s' "$body" | tr -d '\r\n' | cut -c1-160)"
      fi
      ;;
    cip_cc_ip)
      snippet="$(printf '%s' "$body" | sed -n 's/.*IP[[:space:]]*:[[:space:]]*\([0-9][0-9.]*\).*/\1/p' | head -1)"
      [[ -z "$snippet" ]] && snippet="$(printf '%s' "$body" | tr '\r\n' '  ' | cut -c1-160)"
      ;;
    *)
      snippet="$(printf '%s' "$body" | tr '\r\n' '  ' | cut -c1-160)"
      ;;
  esac

  snippet="${snippet//$'\t'/ }"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$scenario" "$category" "$name" "$url" "${code:-000}" "$snippet"
}

print_header() {
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' scenario category probe_name url http_code snippet
}

run_matrix() {
  local scenario="$1"
  shift
  local extra=("$@")
  local line category name url parser
  for line in "${PROBES[@]}"; do
    IFS='|' read -r category name url parser <<<"$line"
    run_one "$scenario" "$category" "$name" "$url" "$parser" "${extra[@]}"
  done
}

emit_simple_tsv() {
  print_header
  run_matrix "S1_noproxy_star" "--noproxy" "*"
}

print_simple_pretty() {
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " 一键出口摘要（按「站点类型」分组）"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  emit_simple_tsv | tail -n +2 | awk -F '\t' '
  function lab(c) {
    if (c=="domestic") return "【国内 / 中文语境站点】"
    if (c=="intl_plain") return "【国际通用回显】"
    if (c=="cdn_trace") return "【CDN 侧观测】"
    if (c=="meta") return "【HTTP 元数据 (JSON)】"
    return "【" c "】"
  }
  {
    cat=$2
    line="  • " $3 "  HTTP " $5 "\n    " $6
    if (buf[cat] == "") buf[cat] = line
    else buf[cat] = buf[cat] "\n" line
  }
  END {
    n=split("domestic intl_plain cdn_trace meta", order, " ")
    for (i=1;i<=n;i++) {
      k=order[i]
      if (buf[k] != "") print lab(k) "\n" buf[k] "\n"
    }
  }'

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " 技术附注（可忽略）"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "• 上表为「单路径快照」：本脚本对每次 curl 使用 --noproxy '*'，不跟随当前 shell 的"
  echo "  HTTP_PROXY / HTTPS_PROXY / ALL_PROXY 等环境变量（便于看各站点类型本身走到的公网出口）。"
  echo "• 若终端里设置了代理变量且希望对照「走代理时」与「绕过代理时」："
  echo "  请使用  outbound-ip-audit.sh --full  （含 S0_current_env 与 S1_noproxy_star 等场景）。"
  echo "• 进阶：策略路由 / TUN / 绑定网卡 仅在使用 --full --interface <接口名> 时纳入矩阵；"
  echo "  一般排查分流不必填写接口。"
  echo ""
}

if [[ "$MODE" == "simple" ]]; then
  if [[ "$FORMAT" == "tsv" ]]; then
    emit_simple_tsv
  else
    print_simple_pretty
  fi
  exit 0
fi

# ---------- full 模式 ----------
print_header
run_matrix "S0_current_env" ""
run_matrix "S1_noproxy_star" "--noproxy" "*"
run_matrix "S_ipv4_only" "-4"
if [[ "$IPV6_SKIP" != 1 ]]; then
  run_matrix "S_ipv6_only" "-6"
fi
if [[ -n "$BIND_IFACE" ]]; then
  run_matrix "S_bind_iface_${BIND_IFACE}" "--interface" "$BIND_IFACE"
  run_matrix "S_bind_iface_${BIND_IFACE}_noproxy" "--interface" "$BIND_IFACE" "--noproxy" "*"
fi
