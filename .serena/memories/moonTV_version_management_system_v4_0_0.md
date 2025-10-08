# MoonTV 版本管理系统 v4.0.0

**更新日期**: 2025-10-08
**当前版本**: v3.2.0 (应用) / 0.1.0 (npm 包) / v4.0.0 (Docker)
**状态**: ✅ 与上游仓库同步

## 📋 版本管理概述

MoonTV 采用多维度版本管理策略，区分应用版本、npm 包版本和 Docker 镜像版本，确保与上游仓库版本同步，同时保持各版本体系的独立性。

## 🏷️ 版本体系结构

### 1. 应用版本 (Application Version)

- **格式**: v{major}.{minor}.{patch}
- **管理文件**: `src/lib/version.ts` 和 `VERSION.txt`
- **当前版本**: v3.2.0
- **同步目标**: 与上游仓库保持一致
- **更新检查**: 自动检查上游版本更新

### 2. npm 包版本 (NPM Package Version)

- **格式**: {major}.{minor}.{patch}
- **管理文件**: `package.json`
- **当前版本**: 0.1.0
- **用途**: npm 包发布和依赖管理
- **更新策略**: 独立于应用版本

### 3. Docker 镜像版本 (Docker Image Version)

- **格式**: v{major}.{minor}.{patch}
- **标签策略**: latest, v4.0.0, multi-arch
- **当前版本**: v4.0.0
- **构建方式**: 标准四阶段 Docker 构建
- **部署平台**: Docker, Vercel, Netlify, Cloudflare Pages

## 🔄 版本同步机制

### 自动版本检查

```typescript
// src/lib/version.ts
export async function checkForUpdates(): Promise<UpdateStatus> {
  const VERSION_CHECK_URLS = [
    'https://raw.githubusercontent.com/Stardm0/MoonTV/main/VERSION.txt',
  ];
  // 检查逻辑实现...
}
```

### 版本比较逻辑

```typescript
function compareVersions(remoteVersion: string): UpdateStatus {
  // 逐级比较主版本、次版本、修订版本
  // 返回更新状态: 有更新/无更新/获取失败
}
```

### 更新状态枚举

```typescript
export enum UpdateStatus {
  HAS_UPDATE = 'has_update', // 有新版本
  NO_UPDATE = 'no_update', // 无更新
  FETCH_FAILED = 'fetch_failed', // 获取失败
}
```

## 📊 当前版本状态

### 版本对比表

| 版本类型    | 当前版本 | 上游版本 | 同步状态  | 最后检查   |
| ----------- | -------- | -------- | --------- | ---------- |
| 应用版本    | v3.2.0   | v3.2.0   | ✅ 已同步 | 2025-10-08 |
| npm 包版本  | 0.1.0    | N/A      | ✅ 独立   | 持续维护   |
| Docker 版本 | v4.0.0   | N/A      | ✅ 独立   | 持续维护   |

### 版本检查配置

```typescript
// 版本检查URL配置
const VERSION_CHECK_URLS = [
  'https://raw.githubusercontent.com/Stardm0/MoonTV/main/VERSION.txt',
];

// 检查超时配置
const CHECK_TIMEOUT = 5000; // 5秒超时

// 缓存策略
const CACHE_DURATION = 3600000; // 1小时缓存
```

## 🛠️ 版本管理工具

### 版本检查脚本

```bash
#!/bin/bash
# scripts/test-version-check.sh

# 验证版本配置一致性
echo "✅ VERSION.txt: $(cat VERSION.txt)"
echo "✅ version.ts: $(grep 'CURRENT_VERSION' src/lib/version.ts | sed 's/.*= .//;s/..$//')"
echo "✅ package.json: $(grep '"version"' package.json | sed 's/.*": "//;s/".*//')"
```

### 手动版本更新

```bash
# 1. 更新版本号
echo "v3.2.1" > VERSION.txt
sed -i "s/3\.2\.0/3.2.1/" src/lib/version.ts

# 2. 验证一致性
./scripts/test-version-check.sh

# 3. 构建和测试
pnpm build
pnpm test

# 4. 提交更改
git add .
git commit -m "chore: 更新版本到v3.2.1"

# 5. 创建标签
git tag v3.2.1
git push origin v3.2.1
```

### npm 包版本更新

```bash
# 更新npm包版本
pnpm version patch  # 补丁版本 0.1.0 -> 0.1.1
pnpm version minor  # 次版本 0.1.0 -> 0.2.0
pnpm version major  # 主版本 0.1.0 -> 1.0.0

# 发布到npm (如果需要)
pnpm publish
```

### Docker 镜像版本更新

```bash
# 构建新版本镜像
docker build -t moontv:v4.0.1 .

# 多架构构建
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t moontv:v4.0.1-multi-arch \
  --push .

# 更新latest标签
docker tag moontv:v4.0.1 moontv:latest
docker push moontv:latest
```

## 🔍 版本检查流程

### 启动时检查

应用启动时自动检查版本更新：

1. 读取本地版本 (CURRENT_VERSION)
2. 获取远程版本 (VERSION_CHECK_URLS)
3. 比较版本号
4. 在主页显示更新状态

### 手动检查

```bash
# 手动触发版本检查
curl https://raw.githubusercontent.com/Stardm0/MoonTV/main/VERSION.txt

# 本地版本
cat VERSION.txt
grep "CURRENT_VERSION" src/lib/version.ts
```

### 前端检查

```typescript
// 在React组件中使用
import { checkForUpdates, UpdateStatus } from '@/lib/version';

const UpdateNotification = () => {
  const [updateStatus, setUpdateStatus] = useState<UpdateStatus>(
    UpdateStatus.NO_UPDATE
  );

  useEffect(() => {
    checkForUpdates().then(setUpdateStatus);
  }, []);

  // 渲染更新通知...
};
```

## 📈 版本发布策略

### 语义化版本控制 (SemVer)

- **主版本**: 不兼容的 API 修改
- **次版本**: 向后兼容的功能性新增
- **补丁版本**: 向后兼容的问题修正

### 版本号格式规范

- **应用版本**: v{major}.{minor}.{patch} (如 v3.2.0)
- **开发版本**: v{major}.{minor}.{patch}-dev (如 v3.2.1-dev)
- **测试版本**: v{major}.{minor}.{patch}-beta (如 v3.2.1-beta)
- **正式版本**: v{major}.{minor}.{patch} (如 v3.2.1)

### 发布流程

1. **开发完成**: 代码开发和测试完成
2. **版本更新**: 更新相关版本文件
3. **构建验证**: 构建和测试验证
4. **创建标签**: 创建 Git 标签
5. **发布部署**: 发布到各平台

## 🔄 版本回滚策略

### 应用版本回滚

```bash
# 回滚到指定版本
git checkout v3.2.0
git checkout -- VERSION.txt src/lib/version.ts

# 重新构建
pnpm build
docker build -t moontv:v3.2.0 .
```

### Docker 镜像回滚

```bash
# 使用指定版本镜像
docker run -d -p 3000:3000 \
  --name moontv-rollback \
  moontv:v3.2.0

# 或者从registry拉取
docker pull moontv:v3.2.0
```

### npm 包回滚

```bash
# 回滚npm包版本
npm install moontv@0.1.0

# 或使用yarn
yarn add moontv@0.1.0
```

## 📊 版本监控

### 版本检查监控

- **检查频率**: 应用启动时 + 每 24 小时
- **超时设置**: 5 秒
- **重试机制**: 最多 3 次重试
- **缓存策略**: 1 小时本地缓存

### 版本状态跟踪

```typescript
interface VersionInfo {
  currentVersion: string;
  remoteVersion: string;
  lastCheck: Date;
  updateStatus: UpdateStatus;
  checkUrl: string;
}
```

### 监控指标

- **版本同步状态**: 与上游版本是否一致
- **检查成功率**: 版本检查请求成功率
- **响应时间**: 版本检查 API 响应时间
- **更新频率**: 版本更新频率统计

## 🚨 故障处理

### 版本检查失败

**问题**: 无法获取远程版本信息
**解决方案**:

```typescript
try {
  const remoteVersion = await fetchVersionFromUrl(url);
  return compareVersions(remoteVersion);
} catch (error) {
  console.error('版本检查失败:', error);
  return UpdateStatus.FETCH_FAILED;
}
```

### 版本格式错误

**问题**: 版本号格式不正确
**解决方案**:

```typescript
function validateVersion(version: string): boolean {
  const versionRegex = /^v?\d+\.\d+\.\d+(-[a-zA-Z0-9]+)?$/;
  return versionRegex.test(version);
}
```

### 网络连接问题

**问题**: 无法访问 GitHub 仓库
**解决方案**:

- 设置合理的超时时间
- 实现重试机制
- 提供备用 URL
- 本地缓存机制

## 📚 最佳实践

### 版本管理最佳实践

1. **语义化版本**: 严格遵循 SemVer 规范
2. **自动检查**: 实现自动化版本检查
3. **及时同步**: 与上游仓库保持同步
4. **版本标签**: 使用 Git 标签标记版本
5. **文档更新**: 及时更新版本相关文档

### 开发流程最佳实践

1. **功能开发**: 在 feature 分支开发新功能
2. **版本更新**: 合并到主分支时更新版本
3. **测试验证**: 全面测试版本更新
4. **构建发布**: 构建和发布新版本
5. **标签创建**: 创建 Git 标签

### 部署流程最佳实践

1. **版本检查**: 部署前检查版本状态
2. **备份当前**: 备份当前版本
3. **更新版本**: 更新到新版本
4. **验证部署**: 验证新版本部署
5. **监控观察**: 观察部署后状态

---

**最后更新**: 2025-10-08
**当前版本**: v3.2.0 (应用) / 0.1.0 (npm) / v4.0.0 (Docker)
**同步状态**: ✅ 与上游仓库同步
**维护状态**: ✅ 活跃维护
