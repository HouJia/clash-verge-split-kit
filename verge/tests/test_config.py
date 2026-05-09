#!/usr/bin/env python3
"""
Clash Verge Split Kit - 配置回归测试脚本
验证生成的 config.local.ini 和 config.local.yaml 配置正确性

使用方式:
    cd clash-verge-split-kit/verge
    python3 tests/test_config.py

环境要求:
    pip install pyyaml
"""

import unittest
import sys
import os
import re
from pathlib import Path
from typing import Dict, List, Set, Tuple, Any

# 确保可以导入 yaml
try:
    import yaml
except ImportError:
    print("错误: 需要安装 PyYAML")
    print("运行: pip install pyyaml")
    sys.exit(1)


class ConfigPaths:
    """配置路径管理"""
    BASE_DIR = Path(__file__).parent.parent
    INI_PATH = BASE_DIR / "generated" / "config.local.ini"
    YAML_PATH = BASE_DIR / "generated" / "config.local.yaml"


class INIParser:
    """简单的 INI 配置解析器"""

    def __init__(self, content: str):
        self.content = content
        self.sections: Dict[str, List[str]] = {}
        self.custom_proxy_groups: List[Dict[str, Any]] = []
        self.rulesets: List[Dict[str, str]] = []
        self._parse()

    def _parse(self):
        """解析 INI 内容"""
        current_section = None
        lines = self.content.split('\n')

        for line in lines:
            line = line.strip()
            if not line or line.startswith(';'):
                continue

            # 检查节头
            if line.startswith('[') and line.endswith(']'):
                current_section = line[1:-1]
                if current_section not in self.sections:
                    self.sections[current_section] = []
                continue

            # 收集节内容
            if current_section:
                self.sections[current_section].append(line)

            # 解析 custom_proxy_group
            if line.startswith('custom_proxy_group='):
                self._parse_proxy_group(line)

            # 解析 ruleset
            if line.startswith('ruleset='):
                self._parse_ruleset(line)

    def _parse_proxy_group(self, line: str):
        """解析代理组定义"""
        # 格式: custom_proxy_group=名称`类型`匹配`选项1`选项2`...
        content = line[len('custom_proxy_group='):]
        parts = content.split('`')

        if len(parts) >= 2:
            group = {
                'name': parts[0],
                'type': parts[1],
                'match': parts[2] if len(parts) > 2 else '',
                'options': parts[3:] if len(parts) > 3 else []
            }
            self.custom_proxy_groups.append(group)

    def _parse_ruleset(self, line: str):
        """解析规则集定义"""
        # 格式: ruleset=策略组名,规则定义
        content = line[len('ruleset='):]
        if ',' in content:
            group_name, rule_def = content.split(',', 1)
            self.rulesets.append({
                'group': group_name,
                'rule': rule_def
            })


class TestConfigStructure(unittest.TestCase):
    """测试配置文件结构和基本格式"""

    @classmethod
    def setUpClass(cls):
        """加载配置文件"""
        cls.ini_path = ConfigPaths.INI_PATH
        cls.yaml_path = ConfigPaths.YAML_PATH

        # 检查文件存在
        if not cls.ini_path.exists():
            raise FileNotFoundError(f"INI 配置文件不存在: {cls.ini_path}")
        if not cls.yaml_path.exists():
            raise FileNotFoundError(f"YAML 配置文件不存在: {cls.yaml_path}")

        # 读取内容
        with open(cls.ini_path, 'r', encoding='utf-8') as f:
            cls.ini_content = f.read()
        with open(cls.yaml_path, 'r', encoding='utf-8') as f:
            cls.yaml_content = f.read()

        # 解析配置
        cls.ini_parser = INIParser(cls.ini_content)
        cls.yaml_data = yaml.safe_load(cls.yaml_content)

    def test_001_files_exist(self):
        """测试: 配置文件必须存在"""
        self.assertTrue(ConfigPaths.INI_PATH.exists(), "INI 配置文件必须存在")
        self.assertTrue(ConfigPaths.YAML_PATH.exists(), "YAML 配置文件必须存在")

    def test_002_ini_has_custom_section(self):
        """测试: INI 文件必须包含 [custom] 节"""
        self.assertIn('custom', self.ini_parser.sections, "INI 必须包含 [custom] 节")

    def test_003_yaml_has_proxy_groups(self):
        """测试: YAML 文件必须包含 proxy-groups"""
        self.assertIn('proxy-groups', self.yaml_data, "YAML 必须包含 proxy-groups")
        self.assertIsInstance(self.yaml_data['proxy-groups'], list)
        self.assertGreater(len(self.yaml_data['proxy-groups']), 0, "proxy-groups 不能为空")

    def test_004_yaml_has_rules(self):
        """测试: YAML 文件必须包含 rules"""
        self.assertIn('rules', self.yaml_data, "YAML 必须包含 rules")
        self.assertIsInstance(self.yaml_data['rules'], list)
        self.assertGreater(len(self.yaml_data['rules']), 0, "rules 不能为空")

    def test_005_metadata_header_exists(self):
        """测试: 文件必须包含生成元信息头部"""
        ini_has_meta = "本机生成元信息" in self.ini_content and "生成时间" in self.ini_content
        yaml_has_meta = "本机生成元信息" in self.yaml_content and "生成时间" in self.yaml_content

        self.assertTrue(ini_has_meta, "INI 文件必须包含生成元信息头部")
        self.assertTrue(yaml_has_meta, "YAML 文件必须包含生成元信息头部")

    def test_006_ini_proxy_groups_count(self):
        """测试: INI 代理组数量检查"""
        # 预期至少有 20+ 个代理组
        self.assertGreaterEqual(
            len(self.ini_parser.custom_proxy_groups),
            20,
            f"INI 中代理组数量不足，实际 {len(self.ini_parser.custom_proxy_groups)}"
        )


class TestProxyGroups(unittest.TestCase):
    """测试代理组定义"""

    @classmethod
    def setUpClass(cls):
        cls.ini_path = ConfigPaths.INI_PATH
        cls.yaml_path = ConfigPaths.YAML_PATH

        with open(cls.ini_path, 'r', encoding='utf-8') as f:
            cls.ini_content = f.read()
        with open(cls.yaml_path, 'r', encoding='utf-8') as f:
            cls.yaml_content = f.read()

        cls.ini_parser = INIParser(cls.ini_content)
        cls.yaml_data = yaml.safe_load(cls.yaml_content)

        # 构建名称映射
        cls.ini_group_names = {g['name'] for g in cls.ini_parser.custom_proxy_groups}
        cls.yaml_group_map = {g['name']: g for g in cls.yaml_data.get('proxy-groups', [])}

    def test_100_base_groups_exist(self):
        """测试: 底座策略组必须存在"""
        base_groups = [
            '♻️ 自动最优',
            '🔌 国内直连',
            '🎚️ 手动切换',
        ]
        for group in base_groups:
            self.assertIn(group, self.ini_group_names, f"INI 缺少底座组: {group}")
            self.assertIn(group, self.yaml_group_map, f"YAML 缺少底座组: {group}")

    def test_101_business_groups_exist(self):
        """测试: 业务场景策略组必须存在"""
        business_groups = [
            '🔜 工具 · Cursor',
            '🧠 场景 · 境外 AI',
            '💬 场景 · 即时通讯',
            '📢 场景 · 谷歌推送',
            '🎬 场景 · 海外音影社',
            '📱 场景 · TikTok',
            '🐙 场景 · 开发源站',
            '📚 场景 · 学术与数据',
            '🎮 场景 · 游戏平台',
            '💳 PayPal · 国内线路',
            '💳 PayPal · 国际线路',
        ]
        for group in business_groups:
            self.assertIn(group, self.ini_group_names, f"INI 缺少业务组: {group}")
            self.assertIn(group, self.yaml_group_map, f"YAML 缺少业务组: {group}")

    def test_102_big_tech_groups_exist(self):
        """测试: 大厂策略组必须存在"""
        tech_groups = [
            '🍎 大厂 · 苹果',
            '🪟 大厂 · 微软',
            '💠 大厂 · 微软跨境',
            '🔍 大厂 · 谷歌',
            '👥 大厂 · 脸书系',
        ]
        for group in tech_groups:
            self.assertIn(group, self.ini_group_names, f"INI 缺少大厂组: {group}")
            self.assertIn(group, self.yaml_group_map, f"YAML 缺少大厂组: {group}")

    def test_103_system_groups_exist(self):
        """测试: 系统策略组必须存在"""
        system_groups = [
            '🚫 系统 · 广告拦截',
            '🍃 系统 · 应用遥测净化',
            '🐟 系统 · 漏网之鱼',
        ]
        for group in system_groups:
            self.assertIn(group, self.ini_group_names, f"INI 缺少系统组: {group}")
            self.assertIn(group, self.yaml_group_map, f"YAML 缺少系统组: {group}")

    def test_104_region_groups_exist(self):
        """测试: 国家/地区节点分组必须存在"""
        region_groups = [
            '🇺🇸 美国节点',
            '🇭🇰 香港节点',
            '🇯🇵 日本节点',
            '🇸🇬 新加坡节点',
            '🌺 台湾节点',
            '🌍 其它国家',
        ]
        for group in region_groups:
            self.assertIn(group, self.ini_group_names, f"INI 缺少地区组: {group}")
            self.assertIn(group, self.yaml_group_map, f"YAML 缺少地区组: {group}")

    def test_105_auto_best_group_type(self):
        """测试: ♻️ 自动最优 必须是 url-test 类型"""
        group = self.yaml_group_map.get('♻️ 自动最优')
        self.assertIsNotNone(group)
        self.assertEqual(group['type'], 'url-test')
        self.assertIn('url', group)
        self.assertIn('interval', group)
        self.assertIn('tolerance', group)

    def test_106_region_groups_are_url_test(self):
        """测试: 地区节点分组必须是 url-test 类型"""
        region_groups = ['🇺🇸 美国节点', '🇭🇰 香港节点', '🇯🇵 日本节点',
                        '🇸🇬 新加坡节点', '🌺 台湾节点', '🌍 其它国家']
        for name in region_groups:
            group = self.yaml_group_map.get(name)
            self.assertIsNotNone(group, f"找不到组: {name}")
            self.assertEqual(group['type'], 'url-test',
                           f"{name} 应该是 url-test 类型，实际是 {group['type']}")
            self.assertIn('filter', group, f"{name} 应该有 filter 字段")

    def test_107_other_countries_filter_pattern(self):
        """测试: 🌍 其它国家 必须有正确的排除正则"""
        group = self.yaml_group_map.get('🌍 其它国家')
        self.assertIsNotNone(group)
        filter_pattern = group.get('filter', '')

        # 应该包含负向前瞻断言，排除已定义的地区
        self.assertIn('?!', filter_pattern, "其它国家 filter 应该使用负向前瞻")
        self.assertIn('美国', filter_pattern, "filter 应该排除美国")
        self.assertIn('香港', filter_pattern, "filter 应该排除香港")
        self.assertIn('日本', filter_pattern, "filter 应该排除日本")

    def test_108_select_groups_have_proxies(self):
        """测试: select 类型的组必须有 proxies 列表"""
        for group in self.yaml_data.get('proxy-groups', []):
            if group['type'] == 'select':
                self.assertIn('proxies', group,
                            f"{group['name']} 是 select 类型但缺少 proxies")
                self.assertGreater(len(group['proxies']), 0,
                                 f"{group['name']} 的 proxies 不能为空")

    def test_109_manual_switch_first_options(self):
        """测试: 🎚️ 手动切换 的选项顺序检查"""
        group = self.yaml_group_map.get('🎚️ 手动切换')
        self.assertIsNotNone(group)
        proxies = group.get('proxies', [])

        # 检查第一个选项应该是 ♻️ 自动最优
        if len(proxies) > 0:
            self.assertEqual(proxies[0], '♻️ 自动最优',
                           "🎚️ 手动切换 的第一个选项应该是 ♻️ 自动最优")

    def test_110_overseas_ai_default_preference(self):
        """测试: 🧠 场景 · 境外 AI 默认优先美国节点"""
        group = self.yaml_group_map.get('🧠 场景 · 境外 AI')
        self.assertIsNotNone(group)
        proxies = group.get('proxies', [])

        if len(proxies) > 0:
            self.assertEqual(proxies[0], '🇺🇸 美国节点',
                           "🧠 场景 · 境外 AI 的第一个选项应该是 🇺🇸 美国节点")

    def test_111_tiktok_default_preference(self):
        """测试: 📱 场景 · TikTok 默认优先美国节点"""
        group = self.yaml_group_map.get('📱 场景 · TikTok')
        self.assertIsNotNone(group)
        proxies = group.get('proxies', [])

        if len(proxies) > 0:
            self.assertEqual(proxies[0], '🇺🇸 美国节点',
                           "📱 场景 · TikTok 的第一个选项应该是 🇺🇸 美国节点")

    def test_112_google_group_default_preference(self):
        """测试: 🔍 大厂 · 谷歌 默认优先美国节点"""
        group = self.yaml_group_map.get('🔍 大厂 · 谷歌')
        self.assertIsNotNone(group)
        proxies = group.get('proxies', [])

        if len(proxies) > 0:
            self.assertEqual(proxies[0], '🇺🇸 美国节点',
                           "🔍 大厂 · 谷歌 的第一个选项应该是 🇺🇸 美国节点")

    def test_113_apple_microsoft_default_direct(self):
        """测试: 苹果和微软组默认优先直连"""
        groups_to_check = ['🍎 大厂 · 苹果', '🪟 大厂 · 微软']
        for name in groups_to_check:
            group = self.yaml_group_map.get(name)
            self.assertIsNotNone(group, f"找不到组: {name}")
            proxies = group.get('proxies', [])
            if len(proxies) > 0:
                self.assertEqual(proxies[0], '🔌 国内直连',
                               f"{name} 的第一个选项应该是 🔌 国内直连")

    def test_114_ad_block_first_option_reject(self):
        """测试: 广告拦截组第一个选项必须是 REJECT"""
        group = self.yaml_group_map.get('🚫 系统 · 广告拦截')
        self.assertIsNotNone(group)
        proxies = group.get('proxies', [])

        if len(proxies) > 0:
            self.assertEqual(proxies[0], 'REJECT',
                           "🚫 系统 · 广告拦截 的第一个选项应该是 REJECT")

    def test_115_final_group_options(self):
        """测试: 🐟 系统 · 漏网之鱼 选项完整性"""
        group = self.yaml_group_map.get('🐟 系统 · 漏网之鱼')
        self.assertIsNotNone(group)
        proxies = group.get('proxies', [])

        # 应该包含所有主要出口选项
        required_options = ['♻️ 自动最优', '🎚️ 手动切换', '🇺🇸 美国节点', '🔌 国内直连']
        for opt in required_options:
            self.assertIn(opt, proxies, f"🐟 系统 · 漏网之鱼 缺少选项: {opt}")

    def test_116_paypal_groups_order(self):
        """测试: PayPal 分组默认选项检查"""
        # 国内线路默认直连
        cn_group = self.yaml_group_map.get('💳 PayPal · 国内线路')
        self.assertIsNotNone(cn_group)
        cn_proxies = cn_group.get('proxies', [])
        if len(cn_proxies) > 0:
            self.assertEqual(cn_proxies[0], '🔌 国内直连',
                           "PayPal 国内线路默认应该是直连")

        # 国际线路默认自动最优
        intl_group = self.yaml_group_map.get('💳 PayPal · 国际线路')
        self.assertIsNotNone(intl_group)
        intl_proxies = intl_group.get('proxies', [])
        if len(intl_proxies) > 0:
            self.assertEqual(intl_proxies[0], '♻️ 自动最优',
                           "PayPal 国际线路默认应该是自动最优")

    def test_117_all_groups_exclude_filter(self):
        """测试: 所有代理组都有 exclude-filter 排除海外用户专用节点"""
        for group in self.yaml_data.get('proxy-groups', []):
            self.assertIn('exclude-filter', group,
                        f"{group['name']} 缺少 exclude-filter")
            exclude = group.get('exclude-filter', '')
            self.assertIn('海外用户专用', exclude,
                        f"{group['name']} 的 exclude-filter 应该排除 '海外用户专用'")


class TestRules(unittest.TestCase):
    """测试规则定义"""

    @classmethod
    def setUpClass(cls):
        cls.ini_path = ConfigPaths.INI_PATH
        cls.yaml_path = ConfigPaths.YAML_PATH

        with open(cls.ini_path, 'r', encoding='utf-8') as f:
            cls.ini_content = f.read()
        with open(cls.yaml_path, 'r', encoding='utf-8') as f:
            cls.yaml_content = f.read()

        cls.ini_parser = INIParser(cls.ini_content)
        cls.yaml_data = yaml.safe_load(cls.yaml_content)
        cls.yaml_rules = cls.yaml_data.get('rules', [])

        # 收集所有策略组名称
        cls.proxy_group_names = {g['name'] for g in cls.yaml_data.get('proxy-groups', [])}
        cls.proxy_group_names.add('DIRECT')
        cls.proxy_group_names.add('REJECT')

    def test_200_all_rules_target_valid_groups(self):
        """测试: 所有规则引用的策略组必须存在"""
        for rule in self.yaml_rules:
            if isinstance(rule, str):
                parts = rule.split(',')
                if len(parts) >= 2:
                    target = parts[-1]
                    # 处理带 no-resolve 的情况
                    if 'no-resolve' in target:
                        target = parts[-2] if len(parts) >= 3 else target

                    self.assertIn(target, self.proxy_group_names,
                                f"规则引用了不存在的策略组: {target}\n规则: {rule}")

    def test_201_private_rules_first(self):
        """测试: GEOSITE/GEOIP private 应早于后续片段中的 DOMAIN/IP-CIDR 规则。

        列表首部允许本地注入的直连规则（render-local 写入的 IP-CIDR、DOMAIN-SUFFIX 等），
        它们优先于私网库规则命中，与模板注释「最高优先级」一致。
        """
        private_types = {'GEOSITE,private', 'GEOIP,private'}
        first_private_idx = None
        for i, rule in enumerate(self.yaml_rules):
            if isinstance(rule, str) and any(pt in rule for pt in private_types):
                first_private_idx = i
                break
        self.assertIsNotNone(first_private_idx, '缺少 GEOSITE,private 或 GEOIP,private')

        found_non_private = False
        domain_ip_markers = ('DOMAIN-SUFFIX', 'DOMAIN-KEYWORD', 'IP-CIDR')
        for i, rule in enumerate(self.yaml_rules):
            if not isinstance(rule, str):
                continue
            if any(pt in rule for pt in private_types):
                if found_non_private:
                    self.fail(f"私有规则应该在前面，但在位置 {i} 发现: {rule}")
            elif i > first_private_idx and any(m in rule for m in domain_ip_markers):
                found_non_private = True

    def test_202_cursor_rules_exist(self):
        """测试: Cursor 规则必须存在"""
        cursor_rules = [r for r in self.yaml_rules
                       if isinstance(r, str) and '🔜 工具 · Cursor' in r]
        self.assertGreater(len(cursor_rules), 0, "缺少 Cursor 规则")

        # 检查必须有进程名规则
        process_rules = [r for r in cursor_rules if 'PROCESS-NAME' in r]
        self.assertGreater(len(process_rules), 0, "Cursor 应该有 PROCESS-NAME 规则")

    def test_203_ai_rules_exist(self):
        """测试: 境外 AI 规则必须存在"""
        ai_rules = [r for r in self.yaml_rules
                   if isinstance(r, str) and '🧠 场景 · 境外 AI' in r]
        self.assertGreater(len(ai_rules), 5, "境外 AI 规则数量不足")

        # 检查必须包含 OpenAI 和 Anthropic 相关域名
        openai_found = any('openai' in r.lower() for r in ai_rules)
        anthropic_found = any('anthropic' in r.lower() or 'claude' in r.lower()
                             for r in ai_rules)
        self.assertTrue(openai_found, "应该包含 OpenAI 相关规则")
        self.assertTrue(anthropic_found, "应该包含 Anthropic/Claude 相关规则")

    def test_204_telegram_rules_exist(self):
        """测试: Telegram 规则必须存在"""
        tg_rules = [r for r in self.yaml_rules
                   if isinstance(r, str) and '💬 场景 · 即时通讯' in r]
        self.assertGreater(len(tg_rules), 0, "缺少 Telegram 规则")

        # 检查 IP 段规则
        ip_rules = [r for r in tg_rules if 'IP-CIDR' in r]
        self.assertGreater(len(ip_rules), 0, "Telegram 应该有 IP-CIDR 规则")

    def test_205_fcm_rules_exist(self):
        """测试: FCM 推送规则必须存在"""
        fcm_rules = [r for r in self.yaml_rules
                    if isinstance(r, str) and '📢 场景 · 谷歌推送' in r]
        self.assertGreater(len(fcm_rules), 10, "FCM 规则数量不足")

        # 检查 mtalk.google.com 规则
        mtalk_found = any('mtalk.google.com' in r for r in fcm_rules)
        self.assertTrue(mtalk_found, "FCM 规则应该包含 mtalk.google.com")

    def test_206_github_rules_exist(self):
        """测试: GitHub 规则必须存在"""
        github_rules = [r for r in self.yaml_rules
                       if isinstance(r, str) and '🐙 场景 · 开发源站' in r]
        self.assertGreater(len(github_rules), 0, "缺少 GitHub 规则")

    def test_207_netflix_rules_exist(self):
        """测试: Netflix 等流媒体规则必须存在"""
        media_rules = [r for r in self.yaml_rules
                      if isinstance(r, str) and '🎬 场景 · 海外音影社' in r]
        self.assertGreater(len(media_rules), 0, "缺少流媒体规则")

        netflix_found = any('netflix' in r.lower() for r in media_rules)
        self.assertTrue(netflix_found, "应该包含 Netflix 规则")

    def test_208_tiktok_separate_group(self):
        """测试: TikTok 应该有独立的策略组"""
        tiktok_rules = [r for r in self.yaml_rules
                       if isinstance(r, str) and '📱 场景 · TikTok' in r]
        self.assertGreater(len(tiktok_rules), 0, "TikTok 应该有独立规则指向 📱 场景 · TikTok")

    def test_209_paypal_cn_rules_exist(self):
        """测试: PayPal 国内规则必须存在"""
        paypal_cn_rules = [r for r in self.yaml_rules
                          if isinstance(r, str) and '💳 PayPal · 国内线路' in r]
        self.assertGreater(len(paypal_cn_rules), 0, "缺少 PayPal 国内线路规则")

        paypal_cn_found = any('paypal.cn' in r for r in paypal_cn_rules)
        self.assertTrue(paypal_cn_found, "应该包含 paypal.cn 规则")

    def test_210_paypal_intl_rules_exist(self):
        """测试: PayPal 国际规则必须存在"""
        paypal_intl_rules = [r for r in self.yaml_rules
                            if isinstance(r, str) and '💳 PayPal · 国际线路' in r]
        self.assertGreater(len(paypal_intl_rules), 0, "缺少 PayPal 国际线路规则")

    def test_211_google_rules_exist(self):
        """测试: Google 规则必须存在"""
        google_rules = [r for r in self.yaml_rules
                       if isinstance(r, str) and '🔍 大厂 · 谷歌' in r]
        self.assertGreater(len(google_rules), 0, "缺少 Google 规则")

    def test_212_apple_rules_exist(self):
        """测试: Apple 规则必须存在"""
        apple_rules = [r for r in self.yaml_rules
                      if isinstance(r, str) and '🍎 大厂 · 苹果' in r]
        self.assertGreater(len(apple_rules), 0, "缺少 Apple 规则")

    def test_213_microsoft_rules_exist(self):
        """测试: Microsoft 规则必须存在"""
        ms_rules = [r for r in self.yaml_rules
                   if isinstance(r, str) and '🪟 大厂 · 微软' in r]
        ms_cross_rules = [r for r in self.yaml_rules
                         if isinstance(r, str) and '💠 大厂 · 微软跨境' in r]
        self.assertGreater(len(ms_rules), 0, "缺少 Microsoft 规则")
        self.assertGreater(len(ms_cross_rules), 0, "缺少 Microsoft 跨境规则")

    def test_214_cn_direct_rules_exist(self):
        """测试: 国内直连规则必须存在"""
        cn_rules = [r for r in self.yaml_rules
                   if isinstance(r, str) and '🔌 国内直连' in r]
        self.assertGreater(len(cn_rules), 0, "缺少国内直连规则")

        # 检查 GEOSITE,cn 和 GEOIP,cn
        geosite_cn = any('GEOSITE,cn' in r for r in cn_rules)
        geoip_cn = any('GEOIP,cn' in r for r in cn_rules)
        self.assertTrue(geosite_cn, "应该有 GEOSITE,cn 规则")
        self.assertTrue(geoip_cn, "应该有 GEOIP,cn 规则")

    def test_215_final_rule_is_match(self):
        """测试: 最后一条规则必须是 MATCH 兜底"""
        final_rules = [r for r in self.yaml_rules
                      if isinstance(r, str) and 'MATCH' in r]
        self.assertEqual(len(final_rules), 1, "应该只有一条 MATCH 规则")

        last_rule = self.yaml_rules[-1]
        self.assertIn('MATCH', str(last_rule), "最后一条规则应该是 MATCH")
        self.assertIn('🐟 系统 · 漏网之鱼', str(last_rule),
                     "MATCH 应该指向 🐟 系统 · 漏网之鱼")

    def test_216_geolocation_not_cn_rule(self):
        """测试: 必须有 GEOSITE,geolocation-!cn 规则"""
        geo_rules = [r for r in self.yaml_rules
                    if isinstance(r, str) and 'geolocation-!cn' in r]
        self.assertEqual(len(geo_rules), 1, "应该有且只有一条 geolocation-!cn 规则")
        self.assertIn('🎚️ 手动切换', geo_rules[0],
                     "geolocation-!cn 应该指向 🎚️ 手动切换")

    def test_217_ads_rules_exist(self):
        """测试: 广告拦截规则必须存在"""
        ads_rules = [r for r in self.yaml_rules
                    if isinstance(r, str) and '🚫 系统 · 广告拦截' in r]
        self.assertGreater(len(ads_rules), 0, "缺少广告拦截规则")

        category_ads = any('category-ads-all' in r for r in ads_rules)
        self.assertTrue(category_ads, "应该有 category-ads-all 规则")

    def test_218_tracker_rules_exist(self):
        """测试: 遥测净化规则必须存在"""
        tracker_rules = [r for r in self.yaml_rules
                        if isinstance(r, str) and '🍃 系统 · 应用遥测净化' in r]
        self.assertGreater(len(tracker_rules), 0, "缺少遥测净化规则")


class TestConsistency(unittest.TestCase):
    """测试 INI 和 YAML 配置的一致性"""

    @classmethod
    def setUpClass(cls):
        cls.ini_path = ConfigPaths.INI_PATH
        cls.yaml_path = ConfigPaths.YAML_PATH

        with open(cls.ini_path, 'r', encoding='utf-8') as f:
            cls.ini_content = f.read()
        with open(cls.yaml_path, 'r', encoding='utf-8') as f:
            cls.yaml_content = f.read()

        cls.ini_parser = INIParser(cls.ini_content)
        cls.yaml_data = yaml.safe_load(cls.yaml_content)

        cls.ini_group_names = {g['name'] for g in cls.ini_parser.custom_proxy_groups}
        cls.yaml_group_names = {g['name'] for g in cls.yaml_data.get('proxy-groups', [])}

    def test_300_proxy_groups_consistency(self):
        """测试: INI 和 YAML 的代理组名称必须一致"""
        ini_only = self.ini_group_names - self.yaml_group_names
        yaml_only = self.yaml_group_names - self.ini_group_names

        self.assertEqual(ini_only, set(),
                        f"INI 中有但 YAML 中没有的组: {ini_only}")
        self.assertEqual(yaml_only, set(),
                        f"YAML 中有但 INI 中没有的组: {yaml_only}")

    def test_301_proxy_group_count_match(self):
        """测试: INI 和 YAML 的代理组数量必须相同"""
        self.assertEqual(
            len(self.ini_group_names),
            len(self.yaml_group_names),
            f"INI ({len(self.ini_group_names)}) 和 YAML ({len(self.yaml_group_names)}) 代理组数量不一致"
        )

    def test_302_cursor_group_in_both(self):
        """测试: Cursor 组在 INI 和 YAML 中都必须存在"""
        cursor_name = '🔜 工具 · Cursor'
        self.assertIn(cursor_name, self.ini_group_names)
        self.assertIn(cursor_name, self.yaml_group_names)

    def test_303_generation_time_format(self):
        """测试: 生成时间格式检查"""
        # INI 中的时间格式
        ini_time_match = re.search(r'生成时间：(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})',
                                   self.ini_content)
        yaml_time_match = re.search(r'生成时间：(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})',
                                    self.yaml_content)

        self.assertIsNotNone(ini_time_match, "INI 应该有正确的生成时间格式")
        self.assertIsNotNone(yaml_time_match, "YAML 应该有正确的生成时间格式")

        # 两个文件的时间应该一致
        self.assertEqual(ini_time_match.group(1), yaml_time_match.group(1),
                        "INI 和 YAML 的生成时间应该一致")

    def test_304_vps_ip_format(self):
        """测试: VPS IP 格式检查"""
        ip_pattern = r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'

        ini_ip_match = re.search(rf'VPS IP：({ip_pattern})', self.ini_content)
        yaml_ip_match = re.search(rf'VPS IP：({ip_pattern})', self.yaml_content)

        self.assertIsNotNone(ini_ip_match, "INI 应该有正确的 VPS IP 格式")
        self.assertIsNotNone(yaml_ip_match, "YAML 应该有正确的 VPS IP 格式")
        self.assertEqual(ini_ip_match.group(1), yaml_ip_match.group(1),
                        "INI 和 YAML 的 VPS IP 应该一致")


class TestOrderAndCompleteness(unittest.TestCase):
    """测试顺序和完整性"""

    @classmethod
    def setUpClass(cls):
        cls.yaml_path = ConfigPaths.YAML_PATH

        with open(cls.yaml_path, 'r', encoding='utf-8') as f:
            cls.yaml_content = f.read()

        cls.yaml_data = yaml.safe_load(cls.yaml_content)
        cls.proxy_groups = cls.yaml_data.get('proxy-groups', [])
        cls.yaml_rules = cls.yaml_data.get('rules', [])

        # 获取代理组顺序
        cls.group_order = [g['name'] for g in cls.proxy_groups]

    def test_400_base_groups_first(self):
        """测试: 底座组应该排在前面"""
        base_groups = ['♻️ 自动最优', '🔌 国内直连', '🎚️ 手动切换']
        base_indices = [self.group_order.index(g) for g in base_groups if g in self.group_order]

        if len(base_indices) >= 2:
            # 底座组应该在最前面（前5个之内）
            self.assertLess(max(base_indices), 5,
                          "底座组应该排在前面（前5个之内）")

    def test_401_region_groups_last(self):
        """测试: 地区节点分组应该排在后面"""
        region_groups = ['🇺🇸 美国节点', '🇭🇰 香港节点', '🇯🇵 日本节点',
                        '🇸🇬 新加坡节点', '🌺 台湾节点', '🌍 其它国家']
        region_indices = [self.group_order.index(g) for g in region_groups if g in self.group_order]
        business_groups = ['🔜 工具 · Cursor', '🧠 场景 · 境外 AI', '🎬 场景 · 海外音影社']
        business_indices = [self.group_order.index(g) for g in business_groups if g in self.group_order]

        if region_indices and business_indices:
            self.assertGreater(min(region_indices), max(business_indices),
                             "地区节点分组应该排在业务组之后")

    def test_402_all_region_groups_present(self):
        """测试: 所有地区组都必须存在且完整"""
        region_groups = ['🇺🇸 美国节点', '🇭🇰 香港节点', '🇯🇵 日本节点',
                        '🇸🇬 新加坡节点', '🌺 台湾节点', '🌍 其它国家']
        for group in region_groups:
            self.assertIn(group, self.group_order, f"缺少地区组: {group}")

    def test_403_group_type_url_test_has_required_fields(self):
        """测试: url-test 类型的组必须有 url, interval, tolerance"""
        required_fields = ['url', 'interval', 'tolerance']
        for group in self.proxy_groups:
            if group['type'] == 'url-test':
                for field in required_fields:
                    self.assertIn(field, group,
                                f"{group['name']} (url-test) 缺少 {field}")

    def test_404_rule_providers_if_present(self):
        """测试: 如果有 rule-providers，格式必须正确"""
        if 'rule-providers' in self.yaml_data:
            providers = self.yaml_data['rule-providers']
            self.assertIsInstance(providers, dict)
            for name, provider in providers.items():
                self.assertIn('type', provider, f"rule-provider {name} 缺少 type")
                self.assertIn('url', provider, f"rule-provider {name} 缺少 url")

    def test_405_no_duplicate_group_names(self):
        """测试: 不能有重复的组名"""
        name_counts = {}
        for name in self.group_order:
            name_counts[name] = name_counts.get(name, 0) + 1

        duplicates = {k: v for k, v in name_counts.items() if v > 1}
        self.assertEqual(duplicates, {}, f"发现重复的组名: {duplicates}")

    def test_406_domain_rules_have_suffix_or_keyword(self):
        """测试: DOMAIN 规则应该使用 -SUFFIX 或明确类型"""
        for rule in self.yaml_rules:
            if isinstance(rule, str) and rule.startswith('DOMAIN'):
                # DOMAIN 或 DOMAIN-SUFFIX 都是合法的
                self.assertTrue(
                    rule.startswith('DOMAIN-SUFFIX,') or rule.startswith('DOMAIN,'),
                    f"DOMAIN 规则格式不正确: {rule}"
                )


class TestSpecificRules(unittest.TestCase):
    """测试特定规则要求"""

    @classmethod
    def setUpClass(cls):
        cls.yaml_path = ConfigPaths.YAML_PATH

        with open(cls.yaml_path, 'r', encoding='utf-8') as f:
            cls.yaml_content = f.read()

        cls.yaml_data = yaml.safe_load(cls.yaml_content)
        cls.yaml_rules = cls.yaml_data.get('rules', [])

    def test_500_scholar_before_google(self):
        """测试: 学术规则必须在 Google 规则之前"""
        scholar_indices = [i for i, r in enumerate(self.yaml_rules)
                          if isinstance(r, str) and 'category-scholar-!cn' in r]
        google_indices = [i for i, r in enumerate(self.yaml_rules)
                         if isinstance(r, str) and r.startswith('GEOSITE,google')]

        if scholar_indices and google_indices:
            self.assertLess(min(scholar_indices), min(google_indices),
                          "学术规则 (category-scholar-!cn) 必须在 Google 规则之前")

    def test_501_fcm_before_google(self):
        """测试: FCM 规则必须在 Google 规则之前"""
        fcm_indices = [i for i, r in enumerate(self.yaml_rules)
                      if isinstance(r, str) and '📢 场景 · 谷歌推送' in r]
        google_indices = [i for i, r in enumerate(self.yaml_rules)
                         if isinstance(r, str) and r.startswith('GEOSITE,google')]

        if fcm_indices and google_indices:
            self.assertLess(max(fcm_indices), min(google_indices),
                          "FCM 规则必须在 GEOSITE,google 规则之前")

    def test_502_microsoft_cross_before_microsoft(self):
        """测试: 微软跨境规则必须在微软主规则之前"""
        cross_indices = [i for i, r in enumerate(self.yaml_rules)
                        if isinstance(r, str) and '💠 大厂 · 微软跨境' in r]
        ms_indices = [i for i, r in enumerate(self.yaml_rules)
                     if isinstance(r, str) and '🪟 大厂 · 微软' in r and 'GEOSITE,microsoft' in r]

        if cross_indices and ms_indices:
            self.assertLess(max(cross_indices), min(ms_indices),
                          "微软跨境规则必须在 GEOSITE,microsoft 规则之前")

    def test_503_github_before_microsoft(self):
        """测试: GitHub 规则应该在 Microsoft 规则之前"""
        github_indices = [i for i, r in enumerate(self.yaml_rules)
                         if isinstance(r, str) and '🐙 场景 · 开发源站' in r and 'GEOSITE,github' in r]
        ms_indices = [i for i, r in enumerate(self.yaml_rules)
                     if isinstance(r, str) and 'GEOSITE,microsoft' in r]

        if github_indices and ms_indices:
            self.assertLess(min(github_indices), min(ms_indices),
                          "GitHub 规则应该在 Microsoft 规则之前")

    def test_504_paypal_cn_before_paypal_intl(self):
        """测试: PayPal 国内规则应该在国际规则之前"""
        cn_indices = [i for i, r in enumerate(self.yaml_rules)
                     if isinstance(r, str) and '💳 PayPal · 国内线路' in r]
        intl_indices = [i for i, r in enumerate(self.yaml_rules)
                       if isinstance(r, str) and '💳 PayPal · 国际线路' in r]

        if cn_indices and intl_indices:
            self.assertLess(max(cn_indices), min(intl_indices),
                          "PayPal 国内规则应该在国际规则之前")

    def test_505_openwrt_ai_in_manual(self):
        """测试: openwrt.ai 域名应该在 🎚️ 手动切换 组"""
        openwrt_rules = [r for r in self.yaml_rules
                        if isinstance(r, str) and 'openwrt.ai' in r]
        if openwrt_rules:
            for rule in openwrt_rules:
                self.assertIn('🎚️ 手动切换', rule,
                            f"openwrt.ai 应该指向 🎚️ 手动切换: {rule}")


def run_tests():
    """运行所有测试"""
    # 创建测试套件
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    # 添加所有测试类
    suite.addTests(loader.loadTestsFromTestCase(TestConfigStructure))
    suite.addTests(loader.loadTestsFromTestCase(TestProxyGroups))
    suite.addTests(loader.loadTestsFromTestCase(TestRules))
    suite.addTests(loader.loadTestsFromTestCase(TestConsistency))
    suite.addTests(loader.loadTestsFromTestCase(TestOrderAndCompleteness))
    suite.addTests(loader.loadTestsFromTestCase(TestSpecificRules))

    # 运行测试
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    # 输出摘要
    print("\n" + "=" * 70)
    print("测试摘要")
    print("=" * 70)
    print(f"总共运行: {result.testsRun} 个测试")
    print(f"成功: {result.testsRun - len(result.failures) - len(result.errors)} 个")
    print(f"失败: {len(result.failures)} 个")
    print(f"错误: {len(result.errors)} 个")

    if result.wasSuccessful():
        print("\n✅ 所有测试通过！配置验证成功。")
        return 0
    else:
        print("\n❌ 测试未通过，请检查配置问题。")
        return 1


if __name__ == '__main__':
    sys.exit(run_tests())
