# MoonTV 版本管理规范

## 📋 概述

本文档定义了 MoonTV 项目的版本管理策略、流程和标准，确保版本一致性和可维护性。

## 🎯 版本管理原则

### 1. 独立版本路线

- 项目采用独立版本管理，不再依赖原始上游仓库
- 版本号遵循语义化版本规范 (SemVer)
- 与 `Stardm0/MoonTV` 保持功能同步，但独立版本号

### 2. 版本一致性原则

- 所有版本文件必须保持同步
- 三个关键版本文件必须一致：
  - `package.json` 中的 `version` 字段
  - `VERSION.txt` 中的版本号
  - `src/lib/version.ts` 中的 `CURRENT_VERSION`

### 3. 版本检查策略

- 主要检查源：自身仓库的 `VERSION.txt`
- 备用检查源：`Stardm0/MoonTV` 的 `VERSION.txt`
- 版本检查用于用户端更新提示

## 🏷️ 版本号规范

### 语义化版本格式

```
MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]
```

- **MAJOR**：不兼容的 API 变更
- **MINOR**：向后兼容的功能新增
- **PATCH**：向后兼容的问题修复
- **PRERELEASE**：预发布版本 (alpha, beta, rc)
- **BUILD**：构建元数据

### 版本类型说明

- **主版本**：架构重大变更、不兼容更新
- **次版本**：新功能、重要改进
- **补丁版本**：Bug 修复、安全更新

## 🐳 Docker 镜像标签规范

### 标准标签格式

```bash
# 版本标签
aqbjqtd/moontv:v3.5.0
aqbjqtd/moontv:v3.5

# 稳定标签
aqbjqtd/moontv:latest     # 最新稳定版本
aqbjqtd/moontv:stable     # 稳定版本

# 特殊标签
aqbjqtd/moontv:dev        # 开发版本
aqbjqtd/moontv:testing    # 测试版本

# 多架构标签
aqbjqtd/moontv:v3.5.0-linux-amd64
aqbjqtd/moontv:v3.5.0-linux-arm64
```

### 镜像发布流程

1. 构建时自动创建版本标签和 latest 标签
2. 支持手动指定版本标签
3. 多架构镜像自动构建

## 🔄 版本发布流程

### 发布前检查清单

- [ ] 所有版本文件已同步
- [ ] 代码测试通过
- [ ] 更新日志已编写
- [ ] Docker 镜像构建测试成功
- [ ] 版本检查功能正常

### 发布步骤

1. **版本文件更新**

   ```bash
   # 更新所有版本文件到新版本号
   echo "X.Y.Z" > VERSION.txt
   # 更新 package.json 和 src/lib/version.ts
   ```

2. **创建 Git 标签**

   ```bash
   git add .
   git commit -m "chore: update version files for v{version}"
   git tag v{version}
   git push origin main --tags
   ```

3. **Docker 镜像构建**

   ```bash
   # 本地构建
   docker build -t aqbjqtd/moontv:v{version} -t aqbjqtd/moontv:latest .

   # 或通过GitHub Actions自动构建
   ```

4. **发布说明编写**
   - 更新 `RELEASE_NOTES_v{version}.md`
   - 包含新功能、改进、修复内容

## ⚙️ 自动化工作流

### GitHub Actions 配置

项目包含以下自动化工作流：

1. **Version Manager** (`.github/workflows/version-manager.yml`)

   - 标签推送时自动同步版本文件
   - 自动更新版本相关配置

2. **Docker Build** (`.github/workflows/docker-build.yml`)

   - 手动触发 Docker 镜像构建
   - 支持多架构镜像发布

3. **Release Workflow** (`.github/workflows/release.yml`)
   - 自动化发布流程
   - 生成发布说明

### 版本检查自动化

- 版本文件自动同步检查
- 版本一致性验证
- 镜像标签合规性检查

## 📊 版本状态监控

### 版本文件状态检查

```bash
# 检查版本一致性
check_version_consistency() {
    local version_txt=$(cat VERSION.txt)
    local package_json=$(grep '"version"' package.json | cut -d'"' -f4)
    local version_ts=$(grep 'CURRENT_VERSION' src/lib/version.ts | cut -d"'" -f2)

    if [ "$version_txt" = "$package_json" ] && [ "$package_json" = "$version_ts" ]; then
        echo "✅ 版本一致性检查通过: $version_txt"
        return 0
    else
        echo "❌ 版本不一致:"
        echo "  VERSION.txt: $version_txt"
        echo "  package.json: $package_json"
        echo "  version.ts: $version_ts"
        return 1
    fi
}
```

### 镜像状态检查

```bash
# 检查本地镜像
docker images aqbjqtd/moontv --format "table {{.Repository}}\t{{.Tag}}\t{{.CreatedAt}}\t{{.Size}}"

# 检查远程镜像
curl -s "https://registry.hub.docker.com/v2/repositories/aqbjqtd/moontv/tags/" | jq -r '.results[].name'
```

## 🚨 版本回滚策略

### 回滚触发条件

- 重大 Bug 发现
- 性能问题
- 安全漏洞
- 兼容性问题

### 回滚流程

1. **评估影响范围**

   - 确定受影响的功能和用户
   - 评估回滚的复杂性

2. **准备回滚**

   - 备份当前版本
   - 准备回滚脚本
   - 通知相关人员

3. **执行回滚**

   ```bash
   # Git标签回滚
   git checkout v{previous_version}

   # Docker镜像回滚
   docker tag aqbjqtd/moontv:v{previous_version} aqbjqtd/moontv:latest
   ```

4. **验证回滚**
   - 功能测试
   - 性能验证
   - 用户反馈收集

## 📈 版本发布节奏

### 定期发布

- **主版本**：每 6-12 个月（重大架构变更）
- **次版本**：每 2-3 个月（功能更新）
- **补丁版本**：按需发布（Bug 修复）

### 紧急发布

- 安全漏洞修复：24 小时内
- 严重 Bug：48 小时内
- 兼容性问题：72 小时内

## 🔄 与上游同步策略

### 功能同步

- 定期关注 `Stardm0/MoonTV` 的功能更新
- 评估新功能的适用性和兼容性
- 独立决定是否集成新功能

### 版本独立

- 不强制跟随上游版本号
- 根据项目需求独立发布版本
- 保持向后兼容性

## 📝 维护指南

### 日常维护

1. 定期检查版本一致性
2. 监控 Docker 镜像状态
3. 关注上游项目动态
4. 收集用户反馈

### 发布前准备

1. 完整的功能测试
2. 性能基准测试
3. 安全检查
4. 文档更新

### 发布后跟进

1. 监控系统状态
2. 收集用户反馈
3. 处理问题报告
4. 准备下次发布

## 📞 问题处理

### 常见问题

1. **版本不一致**：运行版本同步脚本
2. **镜像构建失败**：检查 Dockerfile 和依赖
3. **标签冲突**：清理冲突标签后重新构建
4. **版本检查失败**：验证网络和 URL 配置

### 联系方式

- **技术支持**：GitHub Issues
- **文档更新**：Pull Request
- **紧急问题**：项目维护者

---

**最后更新**: 2025-11-07
**版本**: v1.0
**维护者**: MoonTV 开发团队

本文档将随项目发展持续更新。
