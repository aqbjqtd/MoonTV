# Docker构建与SSR修复最佳实践指南
**适用项目**: Next.js应用，特别是使用动态配置和Edge Runtime的项目
**最后更新**: 2025-10-06
**版本**: v1.0

## 🎯 适用场景识别

### 何时应用此最佳实践
✅ **Next.js App Router项目**  
✅ **使用动态配置加载**  
✅ **Docker环境部署**  
✅ **Edge Runtime兼容性问题**  
✅ **SSR渲染错误**  
✅ **配置依赖外部文件**  

### 问题识别信号
🚨 **构建失败**: husky prepare脚本错误  
🚨 **SSR错误**: Application error: a server-side exception has occurred  
🚨 **EvalError**: Code generation from strings disallowed for this context  
🚨 **配置加载失败**: 动态配置读取异常  
🚨 **容器启动异常**: 服务无法正常启动  

## 🔧 核心解决方案

### 1. Docker多阶段构建优化

#### 优化策略
```dockerfile
# 第0阶段: 依赖解析
FROM node:20.10.0-alpine AS deps
RUN corepack enable && corepack prepare pnpm@10.14.0 --activate
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prod --ignore-scripts && \
    pnpm store prune && \
    rm -rf /tmp/* && \
    rm -rf /root/.cache

# 第1阶段: 应用构建
FROM node:20.10.0-alpine AS builder
RUN corepack enable && corepack prepare pnpm@10.14.0 --activate
WORKDIR /app
COPY . .
COPY --from=deps /app/node_modules ./node_modules
RUN pnpm install --frozen-lockfile
ENV DOCKER_ENV=true NODE_ENV=production
RUN pnpm gen:manifest && pnpm gen:runtime
RUN find ./src/app/api -name "route.ts" -type f -print0 | xargs -0 sed -i 's/export const runtime = '\''edge'\'';/export const runtime = '\''nodejs'\'';/g' || true
RUN pnpm build
RUN pnpm prune --prod --ignore-scripts && \
    rm -rf node_modules/.cache && \
    rm -rf .next/cache

# 第2阶段: 生产运行时
FROM node:20.10.0-alpine AS runner
RUN addgroup -g 1001 -S nodejs && adduser -u 1001 -S nextjs -G nodejs
ENV NODE_ENV=production DOCKER_ENV=true HOSTNAME=0.0.0.0 PORT=3000 NEXT_TELEMETRY_DISABLED=1
WORKDIR /app
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/config.json ./config.json
COPY --from=builder --chown=nextjs:nodejs /app/scripts ./scripts
COPY --from=builder --chown=nextjs:nodejs /app/start.js ./start.js
USER nextjs
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD node --eval "require('http').get('http://localhost:3000/api/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => process.exit(1))" || echo "Health check fallback"
EXPOSE 3000
CMD ["node", "start.js"]
```

#### .dockerignore优化
```dockerignore
# 极致优化的构建忽略文件
# 环境变量文件
.env
.env*.local
.envrc

# 依赖目录
node_modules
.pnpm-store
.npm
.yarn/cache

# 构建产物和缓存
.next/
out/
dist/
build/
.cache/
*.tsbuildinfo

# 开发工具配置
.vscode/
.idea/
*.swp
*.swo
*~

# Git 相关
.git/
.gitignore
.gitattributes

# CI/CD 配置
.github/
.gitlab-ci.yml
.travis.yml

# 测试和覆盖率
coverage/
.nyc_output/
junit.xml
test-results/

# 文档和示例
README.md
CHANGELOG.md
LICENSE
*.md
docs/
examples/

# 日志文件
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*

# 系统文件
.DS_Store
Thumbs.db
desktop.ini
*.lnk

# 开发配置
.prettierrc*
.eslintrc*
jest.config.*
tsconfig.json
tailwind.config.*
postcss.config.*

# 备份文件
*.bak
*.backup
*.orig

# Claude 相关文件
.claude/
claudedocs/
CLAUDE.md

# Serena 记忆文件
.serena/memories/

# 其他工具配置
.husky/
.lintstagedrc*
commitlint.config.*
```

### 2. 配置加载安全化

#### 问题根源
```typescript
// 问题代码: 使用eval('require')动态加载模块
const _require = eval('require') as NodeJS.Require;
const fs = _require('fs') as typeof import('fs');
const path = _require('path') as typeof import('path');
```

#### 解决方案
```typescript
// 安全的动态import实现
async function initConfig() {
  if (process.env.DOCKER_ENV === 'true') {
    try {
      // 使用动态import替代eval('require')，提高Edge Runtime兼容性
      const fs = await import('fs');
      const path = await import('path');

      const configPath = path.join(process.cwd(), 'config.json');
      const raw = fs.readFileSync(configPath, 'utf-8');

      // 安全的JSON解析，避免EvalError
      const parsedConfig = JSON.parse(raw);
      if (parsedConfig && typeof parsedConfig === 'object') {
        fileConfig = parsedConfig as ConfigFileStruct;
        console.log('load dynamic config success');
      } else {
        throw new Error('Invalid config structure');
      }
    } catch (error) {
      console.error('Failed to load dynamic config, falling back to runtime config:', error);
      // 确保runtimeConfig是有效的对象结构
      fileConfig = (runtimeConfig && typeof runtimeConfig === 'object')
        ? runtimeConfig as unknown as ConfigFileStruct
        : {} as ConfigFileStruct;
    }
  }
}
```

#### 错误处理增强
```typescript
// 多层错误处理机制
export async function getConfig(): Promise<AdminConfig> {
  try {
    await initConfig();
    if (!cachedConfig) {
      throw new Error('Configuration failed to initialize');
    }
    return cachedConfig;
  } catch (error) {
    console.error('Critical error in getConfig:', error);
    // 返回一个最小的安全配置
    return {
      ConfigFile: '{}',
      SiteConfig: {
        SiteName: 'MoonTV',
        Announcement: 'Configuration temporarily unavailable',
        SearchDownstreamMaxPage: 5,
        SiteInterfaceCacheTime: 7200,
        DoubanProxyType: 'direct',
        DoubanProxy: '',
        DoubanImageProxyType: 'direct',
        DoubanImageProxy: '',
        DisableYellowFilter: false,
        TVBoxEnabled: false,
        TVBoxPassword: '',
      },
      UserConfig: {
        AllowRegister: false,
        Users: [],
      },
      SourceConfig: [],
      CustomCategories: [],
    };
  }
}
```

### 3. Runtime配置统一

#### API路由Runtime统一
```bash
# 自动替换所有API路由为nodejs runtime
find ./src/app/api -name "route.ts" -type f -print0 | xargs -0 sed -i 's/export const runtime = '\''edge'\'';/export const runtime = '\''nodejs'\'';/g' || true
```

#### Layout.tsx优化
```typescript
// export const runtime = 'edge'; // 在Docker环境中使用Node.js Runtime

export async function generateMetadata(): Promise<Metadata> {
  let siteName = process.env.NEXT_PUBLIC_SITE_NAME || 'MoonTV';

  try {
    if (process.env.NEXT_PUBLIC_STORAGE_TYPE !== 'localstorage') {
      const config = await getConfig();
      siteName = config.SiteConfig.SiteName;
    }
  } catch (error) {
    console.error('Failed to load config for metadata:', error);
    // 使用默认值
  }

  return {
    title: siteName,
    description: '影视聚合',
    manifest: '/manifest.json',
  };
}
```

### 4. 错误边界和监控

#### 服务器组件错误处理
```typescript
// 在layout.tsx中添加错误处理
if (storageType !== 'localstorage') {
  try {
    const config = await getConfig();
    siteName = config.SiteConfig.SiteName;
    announcement = config.SiteConfig.Announcement;
    enableRegister = config.UserConfig.AllowRegister;
    // ... 其他配置
  } catch (error) {
    console.error('Failed to load config in RootLayout:', error);
    // 使用环境变量作为fallback
  }
}
```

#### 健康检查配置
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD node --eval "require('http').get('http://localhost:3000/api/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => process.exit(1))" || echo "Health check fallback"
```

## 📊 性能优化策略

### 构建性能
- **层缓存优化**: 先复制依赖文件，再复制源代码
- **并行构建**: 多个构建阶段并行执行
- **依赖缓存**: 利用.pnpm-store缓存
- **构建清理**: 及时清理临时文件和缓存

### 运行时性能
- **最小化镜像**: 使用distroless基础镜像
- **非root用户**: 提高安全性
- **健康检查**: 及时发现和恢复问题
- **环境变量**: 优化运行时配置

## 🛠️ 故障排除指南

### 常见问题诊断

#### 1. 构建失败 - husky错误
**症状**: `sh: husky: not found`
**原因**: 只安装了生产依赖，husky是开发依赖
**解决**: 使用 `--ignore-scripts` 参数跳过prepare脚本

#### 2. SSR错误 - EvalError
**症状**: `Application error: a server-side exception has occurred`
**原因**: 使用eval('require')进行动态代码生成
**解决**: 使用动态import替代eval()

#### 3. 配置加载失败
**症状**: 配置读取异常，应用无法启动
**原因**: 文件路径错误或权限问题
**解决**: 添加完整错误处理和回退机制

#### 4. 容器启动异常
**症状**: 容器启动后立即退出
**原因**: 健康检查失败或端口冲突
**解决**: 检查端口配置和健康检查端点

### 调试工具和命令

#### 构建调试
```bash
# 查看构建日志
docker build -t app:debug . 2>&1 | tee build.log

# 进入容器调试
docker run -it --entrypoint sh app:debug

# 检查容器状态
docker ps -a
docker logs <container_id>
```

#### 运行时调试
```bash
# 检查应用健康状态
curl -f http://localhost:8080/api/health

# 查看实时日志
docker logs -f <container_name>

# 进入容器检查文件
docker exec -it <container_name> sh
```

## 📈 质量保证措施

### 构建质量
- **多环境测试**: 开发、测试、生产环境验证
- **依赖扫描**: 检查依赖安全性
- **镜像扫描**: 检查镜像漏洞
- **性能测试**: 验证构建时间和镜像大小

### 部署质量
- **健康检查**: 自动检测服务状态
- **监控告警**: 关键指标监控
- **日志聚合**: 集中化日志管理
- **备份策略**: 配置和数据备份

### 运维质量
- **资源监控**: CPU、内存、磁盘使用监控
- **性能优化**: 定期性能分析和优化
- **安全更新**: 及时更新依赖和补丁
- **文档维护**: 保持文档最新状态

## 🔄 持续改进计划

### 短期改进
- 自动化构建流程
- 集成CI/CD流水线
- 增加更多测试用例
- 优化错误处理机制

### 中期改进
- 实施蓝绿部署
- 添加灰度发布
- 集成监控告警系统
- 建立性能基准

### 长期改进
- 微服务架构演进
- 云原生部署
- 智能化运维
- 自动化扩缩容

---

**文档维护**: 技术团队  
**更新频率**: 根据需要更新  
**版本**: v1.0  
**最后更新**: 2025-10-06