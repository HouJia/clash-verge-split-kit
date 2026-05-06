#!/usr/bin/env bash
# Verge 配置回归测试脚本
# 用法: bash verge/scripts/test-rules.sh [extend|local|all]
# 默认测试 extend 文件

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TARGET="${1:-extend}"
EXIT_CODE=0

echo "========================================"
echo "Verge 配置回归测试"
echo "========================================"
echo "测试目标: ${TEST_TARGET}"
echo ""

# 根据目标选择文件
if [[ "${TEST_TARGET}" == "local" ]]; then
  YAML_FILE="${ROOT}/generated/airport-rule-split.local.yaml"
elif [[ "${TEST_TARGET}" == "all" ]]; then
  # 先测试 extend，再测试 local
  bash "$0" extend || EXIT_CODE=1
  echo ""
  bash "$0" local || EXIT_CODE=1
  exit ${EXIT_CODE}
else
  YAML_FILE="${ROOT}/extend/airport-rule-split-extend.yaml"
fi

# 检查文件存在
if [[ ! -f "${YAML_FILE}" ]]; then
  echo "✗ 文件不存在: ${YAML_FILE}"
  exit 1
fi

echo "测试文件: ${YAML_FILE}"
echo ""

# 使用 Python 进行详细测试
python3 << EOF
import yaml
import sys

errors = []
warnings = []
filename = "${YAML_FILE}"

try:
    with open(filename, 'r') as f:
        data = yaml.safe_load(f)
except Exception as e:
    print("【YAML 语法】✗ 解析失败")
    print(f"  错误: {e}")
    sys.exit(1)

print("【YAML 语法】✓ 解析成功")

proxy_groups = data.get('proxy-groups', [])
rules = data.get('rules', [])
group_names = [g.get('name', '') for g in proxy_groups]

print(f"【基本统计】策略组: {len(group_names)}, 规则: {len(rules)}")

# 1. 策略组引用一致性
print("\n【策略组引用检查】")
missing = []
for i, rule in enumerate(rules):
    if isinstance(rule, str) and ',' in rule:
        # 跳过 IP-CIDR/GEOIP 规则（以,no-resolve结尾的不是策略组名）
        if rule.endswith(',no-resolve'):
            continue
        parts = rule.rsplit(',', 1)
        if len(parts) == 2:
            group = parts[1].strip()
            # 排除 no-resolve 参数
            if ',no-resolve' in group:
                group = group.replace(',no-resolve', '').strip()
            if group not in group_names and group not in ['DIRECT', 'REJECT', 'no-resolve']:
                missing.append((i+1, group))

if missing:
    print(f"✗ 发现 {len(missing)} 条规则引用不存在的策略组")
    for line, group in missing[:3]:
        print(f"  行 {line}: '{group}'")
    errors.append("策略组引用不一致")
else:
    print("✓ 所有规则引用的策略组都存在")

# 2. 关键规则检查
print("\n【关键规则检查】")
checks = [
    ('category-ads-all', '🚫 系统 · 广告拦截', '广告拦截'),
    ('GEOSITE,tracker', '🍃 系统 · 应用遥测净化', '遥测净化'),
    ('PROCESS-NAME,Cursor', '🔜 工具 · Cursor', 'Cursor'),
    ('openai.com', '🧠 场景 · 境外 AI', 'OpenAI'),
    ('anthropic.com', '🧠 场景 · 境外 AI', 'Claude'),
    ('t.me', '💬 场景 · 即时通讯', 'Telegram'),
    ('mtalk.google.com', '📢 场景 · 谷歌推送', 'FCM'),
    ('netflix', '🎬 场景 · 海外音影社', 'Netflix'),
    ('tiktok', '📱 场景 · TikTok', 'TikTok'),
    ('github', '🐙 场景 · 开发源站', 'GitHub'),
    ('category-scholar', '📚 场景 · 学术与数据', '学术'),
    ('steam', '🎮 场景 · 游戏平台', 'Steam'),
    ('MATCH', '🐟 系统 · 漏网之鱼', '兜底'),
]

for keyword, expected_group, desc in checks:
    found = False
    for rule in rules:
        if isinstance(rule, str) and keyword in rule:
            # 验证策略组
            if expected_group in rule or keyword == 'MATCH':
                found = True
                break
    status = "✓" if found else "✗"
    print(f"  {status} {desc} ({keyword})")
    if not found:
        errors.append(f"缺失: {desc}")

# 3. Emoji 验证
print("\n【Emoji 验证】")
emoji_checks = [
    ('🚫 系统 · 广告拦截', 'U+1F6AB'),
    ('🍃 系统 · 应用遥测净化', 'U+1F343'),
    ('🔜 工具 · Cursor', 'U+1F51C'),
    ('🧠 场景 · 境外 AI', 'U+1F9E0'),
    ('💬 场景 · 即时通讯', 'U+1F4AC'),
    ('📢 场景 · 谷歌推送', 'U+1F4E2'),
    ('🎬 场景 · 海外音影社', 'U+1F3AC'),
    ('📱 场景 · TikTok', 'U+1F4F1'),
    ('🐙 场景 · 开发源站', 'U+1F419'),
    ('📚 场景 · 学术与数据', 'U+1F4DA'),
    ('🎮 场景 · 游戏平台', 'U+1F3AE'),
    ('🔌 国内直连', 'U+1F50C'),
    ('🎚️ 手动切换', 'U+1F3BA'),
    ('🐟 系统 · 漏网之鱼', 'U+1F41F'),
]

for name, code in emoji_checks:
    exists = name in group_names
    status = "✓" if exists else "○"  # ○ 表示未定义但不一定是错误
    print(f"  {status} {name} ({code})")

# 4. 规则顺序验证
print("\n【规则顺序验证】")
order_positions = {}
for keyword, _, desc in checks[:4]:  # 只检查前4个的顺序
    for i, rule in enumerate(rules):
        if isinstance(rule, str) and keyword in rule:
            order_positions[desc] = i
            break

if order_positions:
    items = sorted(order_positions.items(), key=lambda x: x[1])
    order_str = " → ".join([name for name, _ in items])
    print(f"  顺序: {order_str}")
    
    # 验证基本顺序
    ads_pos = order_positions.get('广告拦截', 999)
    private_pos = order_positions.get('私有/局域网', -1)
    cursor_pos = order_positions.get('Cursor', 999)
    
    if private_pos < ads_pos < cursor_pos:
        print("✓ 基本顺序正确")
    else:
        print("✗ 顺序异常!")
        errors.append("规则顺序错误")

# 5. 特殊标记检查（local 文件）
if "local" in filename:
    print("\n【本地规则标记检查】")
    content = open(filename).read()
    has_start = '__VERGE_INJECT_RULES_START__' in content
    has_end = '__VERGE_INJECT_RULES_END__' in content
    if has_start and has_end:
        print("✓ 本地规则注入标记存在")
    else:
        print(f"○ 注入标记: 开始={has_start}, 结束={has_end}")

# 总结
print("\n" + "=" * 40)
if errors:
    print(f"❌ 测试失败: {len(errors)} 个错误")
    for e in errors[:5]:
        print(f"  - {e}")
    sys.exit(1)
else:
    print("✅ 所有测试通过!")
    sys.exit(0)
EOF

EXIT_CODE=$?

echo ""
echo "========================================"
if [[ ${EXIT_CODE} -eq 0 ]]; then
    echo "✅ 回归测试通过"
else
    echo "❌ 回归测试失败"
fi
echo "========================================"

exit ${EXIT_CODE}
