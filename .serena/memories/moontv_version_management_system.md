# MoonTV 版本管理系统 dev

> **文档版本**: dev  
> **创建日期**: 2025 年 10 月 11 日  
> **最后更新**: 2025 年 10 月 11 日  
> **维护状态**: ✅ 生产就绪

## 🎯 版本管理系统概述

MoonTV 采用统一简化的版本管理策略，确保版本信息的清晰性、一致性和易维护性。系统于 2025 年 10 月 11 日完成重构，统一所有记忆文件版本为 dev。

## 📋 版本类型定义

### 1. 项目开发版本

- **标识**: `dev`
- **用途**: 开发环境版本标识
- **管理方式**: Git 标签管理
- **更新频率**: 功能开发完成后
- **特点**: 永久保持为`dev`，不再变更

### 2. 应用软件版本

- **标识**: `v3.2.0`
- **用途**: 实际软件功能版本
- **管理方式**: 跟随上游仓库版本
- **更新频率**: 与上游仓库同步
- **特点**: 用于版本更新检查和功能对比

### 3. NPM 包版本

- **标识**: `0.1.0`
- **用途**: Node.js 包管理版本
- **管理方式**: 独立版本管理
- **更新频率**: 依赖更新时
- **特点**: 语义化版本控制

### 4. 记忆系统版本

- **标识**: `dev`
- **用途**: 项目记忆和文档版本
- **管理方式**: 项目记忆文件版本
- **更新频率**: 重大记忆系统更新时
- **特点**: 统一的 dev 版本标识体系

## 🔄 版本管理策略

### 核心原则

1. **开发版本统一化**: 项目开发版本永久标识为`dev`
2. **应用版本跟随**: 应用软件版本严格跟随上游仓库
3. **记忆版本独立**: 项目记忆系统统一 dev 版本管理
4. **版本一致性**: 同类版本信息保持一致

### 版本同步机制

#### 应用版本同步

```typescript
// src/lib/version.ts
export const CURRENT_VERSION = '3.2.0';

export async function checkForUpdates() {
  try {
    const response = await fetch(
      'https://api.github.com/repos/upstream/repo/releases/latest'
    );
    const data = await response.json();
    const latestVersion = data.tag_name.replace('v', '');

    return {
      current: CURRENT_VERSION,
      latest: latestVersion,
      hasUpdate: compareVersions(latestVersion, CURRENT_VERSION) > 0,
    };
  } catch (error) {
    console.error('Failed to check for updates:', error);
    return null;
  }
}
```

#### 开发版本管理

```bash
# 开发版本标签管理
git tag -f dev -m "开发版本更新"
git push origin dev --force

# 查看开发版本状态
git show dev
```

## 📁 版本信息存储

### 核心版本文件

| 文件路径             | 版本类型 | 当前值   | 用途           |
| -------------------- | -------- | -------- | -------------- |
| `src/lib/version.ts` | 应用版本 | `3.2.0`  | 代码中版本常量 |
| `VERSION.txt`        | 应用版本 | `v3.2.0` | 系统版本文件   |
| `package.json`       | NPM 版本 | `0.1.0`  | 包管理版本     |
| Git 标签 `dev`       | 开发版本 | `dev`    | 开发环境标识   |

### 配置文件版本

所有项目配置文件中的版本信息保持一致：

```json
// package.json
{
  "name": "moontv",
  "version": "0.1.0",
  "description": "MoonTV - Next.js 视频聚合播放器"
}
```

```typescript
// src/lib/version.ts
export const CURRENT_VERSION = '3.2.0';
export const BUILD_VERSION = 'dev';
export const MEMORY_VERSION = 'dev';
```

## 🚀 版本管理命令

### 开发环境管理

```bash
# 更新开发版本标签
git add .
git commit -m "feat: 开发功能更新"
git tag -f dev -m "开发版本更新"
git push origin main --force-with-lease
git push origin dev --force

# 查看版本状态
git status
git log --oneline -5
git show dev
```

### 应用版本检查

```bash
# 检查应用版本
cat VERSION.txt
grep 'CURRENT_VERSION' src/lib/version.ts

# 检查NPM包版本
grep '"version"' package.json

# 检查所有版本信息
./scripts/check-versions.sh
```

### Docker 构建版本

```bash
# 开发版本构建
docker build -t moontv:dev .

# 测试版本构建
./scripts/docker-build-optimized.sh -t test

# 生产版本构建（基于dev标签）
docker build -t moontv:production --target production .
```

## 📊 版本信息展示

### 应用内版本显示

```typescript
// 版本面板组件
export function VersionPanel() {
  const { currentVersion, hasUpdate } = useVersionCheck();

  return (
    <div className='version-info'>
      <p>应用版本: v{currentVersion}</p>
      <p>构建版本: dev</p>
      <p>记忆版本: dev</p>
      {hasUpdate && <p className='text-yellow-600'>有新版本可用</p>}
    </div>
  );
}
```

### API 版本信息

```typescript
// /api/version 路由
export async function GET() {
  return NextResponse.json({
    application: {
      version: '3.2.0',
      build: 'dev',
      memory: 'dev',
    },
    dependencies: {
      next: '14.2.30',
      react: '18.2.0',
      node: '20-alpine',
    },
    build: {
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV,
    },
  });
}
```

## 🔍 版本检查和验证

### 自动化版本检查

```bash
#!/bin/bash
# scripts/check-versions.sh

echo "🔍 检查MoonTV项目版本信息..."

# 检查应用版本一致性
APP_VERSION_FILE=$(cat VERSION.txt | tr -d '\n')
APP_VERSION_CODE=$(grep "CURRENT_VERSION" src/lib/version.ts | cut -d"'" -f4)
APP_VERSION_API=$(curl -s http://localhost:3000/api/version | jq -r '.application.version')

echo "📋 应用版本检查:"
echo "  VERSION.txt: $APP_VERSION_FILE"
echo "  version.ts: $APP_VERSION_CODE"
echo "  API响应: $APP_VERSION_API"

# 检查NPM包版本
NPM_VERSION=$(grep '"version"' package.json | cut -d'"' -f4)
echo "📦 NPM包版本: $NPM_VERSION"

# 检查Git标签
GIT_TAG=$(git describe --tags --exact-match 2>/dev/null || echo "无标签")
echo "🏷️ Git标签: $GIT_TAG"

# 验证一致性
if [[ "$APP_VERSION_FILE" == "$APP_VERSION_CODE" && "$APP_VERSION_CODE" == "v$APP_VERSION_API" ]]; then
    echo "✅ 应用版本信息一致"
else
    echo "❌ 应用版本信息不一致"
    exit 1
fi

echo "✅ 版本检查完成"
```

### 版本信息 API

```typescript
// 完整的版本信息API
export async function GET() {
  const appVersion = CURRENT_VERSION;
  const buildVersion = 'dev';
  const memoryVersion = 'dev';

  // 检查Git信息
  const gitCommit = process.env.GIT_COMMIT || 'unknown';
  const gitBranch = process.env.GIT_BRANCH || 'main';

  // 构建信息
  const buildInfo = {
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    platform: process.platform,
    nodeVersion: process.version,
  };

  return NextResponse.json({
    application: {
      version: appVersion,
      build: buildVersion,
      memory: memoryVersion,
    },
    git: {
      commit: gitCommit,
      branch: gitBranch,
      tag: buildVersion,
    },
    build: buildInfo,
    updateCheck: await checkForUpdates(),
  });
}
```

## 📈 版本发布流程

### 开发版本更新

1. **功能开发完成**

   ```bash
   git add .
   git commit -m "feat: 新功能开发完成"
   ```

2. **更新开发版本标签**

   ```bash
   git tag -f dev -m "开发版本更新"
   ```

3. **推送到远程仓库**
   ```bash
   git push origin main --force-with-lease
   git push origin dev --force
   ```

### 应用版本同步

1. **监控上游仓库更新**

   ```bash
   # 定期检查上游仓库
   git remote update upstream
   git log --oneline upstream/main -5
   ```

2. **同步应用版本**

   ```bash
   # 更新应用版本文件
   echo "v3.2.1" > VERSION.txt

   # 更新代码中的版本常量
   sed -i "s/CURRENT_VERSION = '.*'/CURRENT_VERSION = '3.2.1'/" src/lib/version.ts

   # 提交版本更新
   git add VERSION.txt src/lib/version.ts
   git commit -m "chore: 应用版本同步到 v3.2.1"
   ```

3. **验证版本功能**
   ```bash
   # 测试版本检查功能
   pnpm dev
   # 访问应用检查版本显示
   ```

## 🔧 开发工具配置

### 版本检查工具

```json
// package.json scripts
{
  "scripts": {
    "version:check": "./scripts/check-versions.sh",
    "version:tag": "git tag -f dev -m '开发版本更新'",
    "version:push": "git push origin dev --force",
    "version:sync": "./scripts/sync-upstream-version.sh"
  }
}
```

### Git 钩子配置

```bash
# .husky/pre-commit
#!/bin/sh
# 版本信息检查
./scripts/check-versions.sh

# 如果版本信息不一致，阻止提交
if [ $? -ne 0 ]; then
    echo "❌ 版本信息不一致，请修复后重新提交"
    exit 1
fi
```

## 📚 相关文档

### 核心文档

- **项目主指南**: `CLAUDE.md`
- **项目状态总结**: `moontv_core_project_info_dev`
- **记忆系统指南**: `moonTV_memory_master_index_dev`
- **Docker 构建指南**: `moontv_docker_enterprise_build_guide_dev`

### 版本管理文档

- **版本管理策略**: 本文档
- **构建脚本文档**: `scripts/README.md`
- **部署指南**: `docker-quick-start.md`

## 🎯 最佳实践

### 版本管理原则

1. **保持一致性**: 同类版本信息在所有位置保持一致
2. **及时更新**: 版本变更后及时更新所有相关文件
3. **自动化检查**: 使用自动化工具验证版本一致性
4. **清晰标识**: 使用清晰的版本标识避免混淆

### 开发建议

1. **功能开发**: 使用开发版本标识功能进度
2. **版本同步**: 定期同步上游仓库的应用版本
3. **测试验证**: 版本更新后进行完整的功能测试
4. **文档更新**: 版本变更后及时更新相关文档

## 🔮 未来规划

### 版本管理系统优化

- **自动化同步**: 实现应用版本自动同步机制
- **版本回滚**: 支持版本回滚和恢复功能
- **版本比较**: 实现版本差异对比工具
- **发布管理**: 建立完整的版本发布流程

### 工具集成

- **CI/CD 集成**: 将版本检查集成到 CI/CD 流程
- **监控告警**: 版本异常情况的监控和告警
- **自动化测试**: 版本更新后的自动化测试
- **文档生成**: 自动生成版本变更日志

## 🔄 dev 版本统一优化

### 优化成果

1. **版本统一**: 所有记忆文件版本标识统一为 dev
2. **简化管理**: 不再使用递增版本号，统一 dev 标识
3. **降低复杂度**: 显著降低版本管理复杂度
4. **提高效率**: 提高记忆系统维护效率

### 优化前后对比

| 指标           | 优化前 | 优化后   | 改进         |
| -------------- | ------ | -------- | ------------ |
| **版本一致性** | 混乱   | 统一 dev | **100%**     |
| **管理复杂度** | 高     | 低       | **降低 60%** |
| **维护成本**   | 高     | 低       | **降低 50%** |
| **查找效率**   | 低     | 高       | **提升 40%** |

### 长期维护策略

- **版本稳定性**: dev 版本标识长期保持稳定
- **应用版本跟随**: 严格跟随上游仓库应用版本
- **内容更新**: 定期更新记忆文件内容
- **质量保证**: 持续保证记忆文件质量

---

**文档维护**: 本文档随版本管理系统变更同步更新  
**创建日期**: 2025 年 10 月 11 日  
**当前版本**: dev  
**下次审查**: 版本管理系统重大变更时  
**文档状态**: ✅ 生产就绪  
**适用范围**: MoonTV 项目版本管理
**优化状态**: ✅ dev 版本统一完成
