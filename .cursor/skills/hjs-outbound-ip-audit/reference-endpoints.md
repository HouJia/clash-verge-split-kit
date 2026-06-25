# 探测端点分类与来源说明

描述性文字使用中文；URL、服务名、命令保持原文。

## 零、默认「一键」与「完整矩阵」

| 模式 | 命令或 UI | 行为概要 |
|------|-----------|----------|
| 一键（默认） | 无参数，或 `--simple-tsv` | 仅跑 `S1_noproxy_star`（`curl --noproxy '*'`），按 `domestic` / `intl_plain` / `cdn_trace` / `meta` 分组展示 |
| 完整矩阵 | `--full` | 含 `S0_current_env`、`S1_noproxy_star`、`-4`/`-6`、可选 `--interface` |

## 一、用户原始命令归类

| 类别代码 | 你提供的命令 | 说明 |
|----------|--------------|------|
| `intl_plain` | `curl https://ipecho.net/plain` | 国际侧纯文本回显 |
| `intl_plain` | `curl https://ipinfo.io/ip` | 国际侧 API 风格回显 |
| `intl_plain` | `curl https://curlmyip.com` | 国际侧回显；已写入脚本 `PROBES`（`curlmyip`） |
| `intl_plain` | `curl https://ifconfig.me` | 国际侧回显（脚本使用 `/ip` 子路径，返回更稳定） |
| `intl_plain` | `curl https://icanhazip.com` | 国际侧纯文本 |
| `domestic` | `curl http://ip.cip.cc` | 国内向纯文本；部分网络下会 **Empty reply**，属服务端或链路问题 |
| `domestic` | `curl https://cip.cc` | 国内向，正文为 **HTML**，需从 `IP  :` 行抽取 |
| `domestic` | `curl https://myip.ipip.net` | 国内向，中文运营商描述，适合对照「家宽真实出口」 |

## 二、脚本默认额外收录（业界常用）

| 类别代码 | 端点 | 用途 |
|----------|------|------|
| `intl_plain` | `https://api.ipify.org` | 轻量 JSON/纯文本 IPv4，便于自动化 |
| `intl_plain` | `https://api64.ipify.org` | 提示 IPv6 或双栈路径（无 IPv6 时常回落到 IPv4） |
| `intl_plain` | `https://checkip.amazonaws.com` | 亚马逊云边缘回显，**常与其他国际点 IP 不同**，用于观察多路径 |
| `intl_plain` | `https://ident.me` | 另一路国际回显，增加 ASN/路径多样性 |
| `intl_plain` | `https://curlmyip.com` | 与用户原始命令一致，纳入默认矩阵 |
| `cdn_trace` | `https://1.1.1.1/cdn-cgi/trace` | Cloudflare trace，解析 `ip=` 行 |
| `meta` | `https://httpbin.org/ip` | JSON `origin` 字段，便于程序解析 |

## 三、建议手动抽检（未写入默认脚本）

| 端点 | 用途 |
|------|------|
| `https://httpbin.org/headers` | 观察代理链相关请求头（体积大，脚本默认不拉全量） |
| `https://www.cloudflare.com/cdn-cgi/trace` | 与 `1.1.1.1` trace 对照 |
| `https://ip.skk.moe`（网页） | Sukka 的多出口/分流可视化（需浏览器；自动化可改用其 API 若官方提供且稳定） |

## 四、业界常见方法摘要（与本技能对应关系）

- **多服务端点对照**：避免「单点即真理」；本脚本 `PROBES` 即该思路。
- **代理前后对照**：用 `curl` 带/不带 `-x` 或利用 `--noproxy '*'` 与环境变量组合；本脚本 `S0`/`S1`。
- **策略路由 / 分流**：Linux **policy routing**、VPN **split tunneling** 会导致不同目标走不同出口；脚本通过「多域 + 多云 + 多场景」采样，无法 100% 枚举所有内核规则。
- **按网卡绑定探测**：`curl --interface`；脚本 `--interface` 可选参数。
- **DNS 与 IP 分离验证**：出口 IP 正确不等于 DNS 未泄露；见主 `SKILL.md` 可选节。
