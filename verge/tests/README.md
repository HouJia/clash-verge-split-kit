# Clash Verge Split Kit - 配置回归测试

本目录包含自动化回归测试脚本，用于验证生成的 `config.local.ini` 和 `config.local.yaml` 配置文件的正确性。

## 测试范围

测试脚本覆盖以下验证维度：

### 1. 配置结构验证
- 文件存在性检查
- INI 文件 `[custom]` 节检查
- YAML 文件必需字段检查（proxy-groups、rules）
- 生成元信息头部检查

### 2. 策略组定义验证（23 项检查）
- **底座组**: 底座 · ♻️ 自动最优、底座 · 🏠 原生 ISP、底座 · 🔌 国内直连、底座 · 🎚️ 手动切换
- **业务场景组**: Cursor、境外 AI、即时通讯、谷歌推送、海外音影社、TikTok、开发源站、学术与数据、游戏平台、PayPal 分组
- **大厂组**: 苹果、微软、微软跨境、谷歌、脸书系
- **系统组**: 广告拦截、遥测净化、漏网之鱼
- **地区节点组**: 美国、香港、日本、新加坡、台湾、其它国家
- 各组默认选项顺序验证
- 所有组排除 `海外用户专用` 节点验证

### 3. 规则定义验证（18 项检查）
- 所有规则引用有效的策略组
- 规则优先级顺序检查
- 特定场景规则存在性检查（Cursor、AI、Telegram、FCM、GitHub、Netflix 等）
- 兜底 MATCH 规则检查
- 地理分流规则检查

### 4. 一致性验证
- INI 与 YAML 代理组名称一致性
- 生成时间一致性（INI 与 YAML 头部）
- 代理组数量一致性

### 5. 顺序与完整性验证
- 底座组在前、地区组在后的顺序
- url-test 类型组必需字段检查
- 无重复组名检查
- 特定规则优先级顺序（学术 > Google、FCM > Google、微软跨境 > 微软等）

## 使用方法

### 快速测试（推荐）

```bash
cd clash-verge-split-kit/verge
./tests/run-tests.sh
```

### Python 测试脚本直接运行

```bash
cd clash-verge-split-kit/verge
python3 tests/test_config.py
```

### 详细输出模式

```bash
./tests/run-tests.sh --verbose
```

## 依赖安装

```bash
pip3 install pyyaml
```

## 测试输出示例

```
========================================
  Clash Verge Split Kit - 配置回归测试
========================================

配置文件:
  INI:  .../verge/generated/config.local.ini
  YAML: .../verge/generated/config.local.yaml

文件生成时间:
  INI:  2026-05-08 11:27:18 +0800
  YAML: 2026-05-08 11:27:18 +0800

开始运行测试...

...

----------------------------------------------------------------------
Ran 61 tests in 0.129s

OK

======================================================================
测试摘要
======================================================================
总共运行: 61 个测试
成功: 61 个
失败: 0 个
错误: 0 个

✅ 所有测试通过！配置验证成功。

配置统计:
  代理组数量: 26
  规则数量: 320
```

## 集成到生成流程

建议将测试集成到配置生成脚本中，每次生成后自动运行：

```bash
# 在 render-local.sh 或相关生成脚本末尾添加:
echo "运行配置回归测试..."
if ! python3 "$(dirname "$0")/tests/test_config.py"; then
    echo "❌ 配置测试失败，请检查生成的配置"
    exit 1
fi
echo "✅ 配置测试通过"
```

## 故障排查

### 测试失败时的处理

1. **查看具体失败的测试项**: 运行 `./tests/run-tests.sh --verbose` 查看完整错误信息
2. **检查配置文件**: 确认 `verge/generated/config.local.ini` 和 `verge/generated/config.local.yaml` 存在且最新
3. **对比模板文件**: 检查 `verge/template/config-template.ini` 和 `verge/derive/parts/rulesets/*.ini` 的修改

### 常见失败场景

| 失败类型 | 可能原因 | 解决方向 |
|---------|---------|---------|
| 策略组缺失 | 模板文件修改导致组未生成 | 检查模板中的 `custom_proxy_group` 定义 |
| 规则顺序错误 | rulesets 片段文件名顺序问题 | 检查 `derive/parts/rulesets/` 中文件的数字前缀顺序 |
| 默认选项错误 | 组定义中的选项顺序变化 | 检查模板中 `proxies` 列表的顺序 |
| INI/YAML 不一致 | 生成脚本转换逻辑问题 | 检查 `render-local.sh` 中的转换逻辑 |

## 扩展测试

如需添加新的测试用例，编辑 `tests/test_config.py` 文件，在相应的 TestCase 类中添加新的测试方法：

```python
def test_xxx_your_test_name(self):
    """测试: 描述说明"""
    # 测试逻辑
    self.assertTrue(condition, "失败时的提示信息")
```

遵循命名规范：
- 测试方法以 `test_` 开头
- 使用三位数字前缀分类（100-代理组、200-规则、300-一致性等）

## 维护记录

- **创建时间**: 2026-05-08
- **测试数量**: 61 项
- **覆盖维度**: 结构、策略组、规则、一致性、顺序
