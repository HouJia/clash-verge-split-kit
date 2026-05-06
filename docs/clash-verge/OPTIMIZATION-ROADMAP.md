# 配置优化路线图

## 优化原则（优先级排序）

1. **准确优先** - 分流正确是第一目标，不能误拦、误代理、误直连
2. **性能其次** - 在准确基础上，提高转发效率和启动速度
3. **可维护性** - 配置易于理解、更新和排查问题

---

## 当前状态评估

### 优势（已做到）

| 方面 | 现状 | 评估 |
|------|------|------|
| 分层架构 | `parts/` 分层 → `compose.sh` → `extend/` → `render-local.sh` | ✅ 优秀 |
| 策略组设计 | 底座组 + 业务组 + 系统组 + 地区组，MECE 原则 | ✅ 良好 |
| 精确规则 | Cursor/AI/GitHub 等关键业务用 DOMAIN/PROCESS-NAME 前置 | ✅ 准确 |
| GEOSITE 兜底 | 大厂流量用 GEOSITE 简化 | ✅ 合理 |
| 规则数量 | ~200 条显式规则 + GEOSITE 引用 | ✅ 精简 |

### 待优化项

| 方面 | 现状 | 目标 |
|------|------|------|
| Rule-providers | 仅有 reject-loyal | 扩展更多场景化规则集 |
| 广告拦截 | 依赖外部 reject-loyal | 评估本地轻量补充 |
| 国内站点 | 部分依赖 GEOSITE,cn | 关键站点显式前置（如已做的 机场面板域名） |
| 规则顺序 | 已分层，但可进一步优化 | 高频命中规则前置 |

---

## 优化方案（分阶段）

### 第一阶段：准确性加固（高优先级，1-2 周）

目标：消除潜在误分流，确保关键业务 100% 准确

#### 1.1 关键业务显式规则审查

- [ ] **Cursor 规则** - 已添加 PROCESS-NAME + DOMAIN，观察是否需补充新域名
- [ ] **AI 服务** - 检查 OpenAI/Claude/Perplexity 域名是否完整
- [ ] **GitHub 生态** - ghcr.io/npm.pkg.github.com 已前置，观察是否需要补充 raw.githubusercontent.com
- [ ] **机场面板** - ✅ 已添加 机场面板域名 直连，如有其他机场需类似处理

**执行方式**：
```bash
# 遇到分流问题时，在 20-routing-mihomo.yaml 中添加显式规则
# 位置：GEOSITE,cn 之前，或对应业务段落中
```

#### 1.2 国内站点直连加固

基于 analysis 中 airport-a/airport-b 的拆解，提取应直连的国内域名：

| 类别 | 示例域名 | 处理方式 |
|------|----------|----------|
| 机场面板 | 机场面板域名 | ✅ 已添加 |
| 国内视频 | bilibili/youku/iqiyi | 已用 GEOSITE，观察即可 |
| 腾讯系 | qq.com/wechat.com | GEOSITE,tencent 兜底 |
| 阿里云 | aliyun.com/alicdn.com | 评估是否需要显式添加 |

#### 1.3 异常流量监控

在 Verge 面板中定期检查：
- 哪些国内域名走了代理（应直连）
- 哪些国外域名走了直连（应代理）
- 将异常域名记录并回填到配置

---

### 第二阶段：性能优化（中优先级，2-4 周）

目标：在保持准确的前提下，提升启动速度和转发效率

#### 2.1 Rule-Providers 扩展（按需）

当前仅有 `reject-loyal`，评估是否需增加：

| 规则集 | 用途 | 建议 |
|--------|------|------|
| 广告拦截 | 拦截广告域名 | 保持 reject-loyal，已足够 |
| 局域网 | 国内局域网 IP | 已用 GEOSITE,cn + GEOIP,cn，暂不需 |
| 流媒体 | Netflix/Disney 等 | 已用 GEOSITE 兜底，暂不需 |

**结论**：当前配置已较精简，暂不需扩展 rule-providers

#### 2.2 规则顺序优化

按命中频率重新排序（高频在前）：

```
当前顺序（已较好）：
1. 私有/局域网
2. 广告拦截 (reject-loyal)
3. Cursor/AI/GitHub (精确规则)
4. 各业务组 (GEOSITE)
5. 国内流量 (GEOSITE,cn)
6. 国外流量 (geolocation-!cn)
7. MATCH

可微调：
- 将最常访问的业务组（如谷歌、GitHub）相对前置
- 但 GEOSITE 匹配效率已较高，线性优化收益有限
```

#### 2.3 GEOSITE 更新策略优化

当前配置：
```yaml
geo-auto-update: true
geo-update-interval: 24
```

评估：24 小时更新一次较合理，无需调整。

---

### 第三阶段：可维护性提升（长期）

目标：降低长期维护成本，便于协作和传承

#### 3.1 规则注释规范化

每条显式规则添加注释说明原因：
```yaml
# 格式：[原因] [来源] [时间]
- DOMAIN-SUFFIX,机场面板域名,🎯 国内直连  # [机场面板登录] [analysis/airport-b] [2026-05-06]
```

#### 3.2 定期复盘机制

每月检查：
1. Verge 面板异常流量记录
2. analysis/ 中是否有新的机场配置值得吸收
3. 上游 rule-providers 更新情况

#### 3.3 个人机场稿分离（如有需要）

若同时使用多个机场，可在 `extend/` 下创建：
```
extend/
├── airport-a-rule-split-extend.yaml    # 机场A专用稿
├── airport-b-rule-split-extend.yaml    # 机场B专用稿
└── airport-rule-split-extend.yaml        # 通用主线稿（当前）
```

使用方式：
```bash
VERGE_EXTEND_FILE=airport-a-rule-split-extend.yaml bash verge/scripts/render-local.sh
```

---

## 决策记录

### 为什么保持当前架构，不做大改？

1. **当前配置已符合最佳实践**
   - PROCESS-NAME > DOMAIN > GEOSITE > GEOIP > MATCH 的顺序正确
   - 精确规则前置，大厂 GEOSITE 兜底，符合分层原则

2. **性能瓶颈不在配置**
   - 当前 ~200 条显式规则 + GEOSITE 引用，启动和匹配性能优秀
   - 调研显示 5 万条 DOMAIN-SUFFIX 才会有明显性能问题

3. **准确性已满足需求**
   - 关键业务（Cursor/AI/GitHub）已精确控制
   - 国内流量 GEOSITE,cn 兜底，异常已显式添加

### 什么时候需要调整？

| 触发条件 | 应对措施 |
|----------|----------|
| 发现某域名分流错误 | 在 20-routing-mihomo.yaml 添加显式规则 |
| 启动速度明显变慢 | 检查 rule-providers 加载，考虑缓存 |
| 更换机场 | 视新机场节点名调整 proxy-groups 中的过滤条件 |
| 新应用需要精确控制 | 新增业务组（如新增 IDE、新 AI 服务） |

---

## 下一步行动（本周）

- [x] ✅ 添加 机场面板域名 直连规则
- [x] ✅ 创建 analysis/README.md 机场映射文档
- [ ] 观察 Cursor 分流是否正常（新加坡/阿根廷跳动是否影响使用）
- [ ] 如有需要，调整 Cursor 组默认走特定地区（而非 ♻️ 自动最优）

---

## 参考文档

- [RULEBASE-PROGRAM.md](./RULEBASE-PROGRAM.md) - 项目长期目标
- [verge/derive/README.md](../../verge/derive/README.md) - 配置分层说明
- [verge/analysis/README.md](../../verge/analysis/README.md) - 机场映射

---

*生成时间: 2026-05-06*  
*原则: 准确 > 性能 > 可维护性*
