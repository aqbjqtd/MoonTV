# Docker构建优化记录

## 🎯 优化目标
创建简化的Docker镜像，优化构建速度和镜像大小，确保稳定运行。

## 🔧 构建配置

### Dockerfile 结构 (多阶段构建)
```dockerfile
# 第1阶段: 依赖安装
FROM node:20-alpine AS deps
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# 第2阶段: 项目构建
FROM node:20-alpine AS builder
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# 修复Edge Runtime问题
RUN find ./src -type f -name "route.ts" -print0 | xargs -0 sed -i "s/export const runtime = 'edge';/export const runtime = 'nodejs';/g"
ENV DOCKER_ENV=true
RUN sed -i "/const inter = Inter({ subsets: \['latin'] });/a export const dynamic = 'force-dynamic';" src/app/layout.tsx
RUN pnpm run build

# 第3阶段: 运行时镜像
FROM node:20-alpine AS runner
RUN addgroup -g 1001 -S nodejs && adduser -u 1001 -S nextjs -G nodejs
WORKDIR /app
ENV NODE_ENV=production HOSTNAME=0.0.0.0 PORT=3000 DOCKER_ENV=true
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/scripts ./scripts
COPY --from=builder --chown=nextjs:nodejs /app/start.js ./start.js
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/config.json ./config.json
USER nextjs
EXPOSE 3000
CMD ["node", "start.js"]
```

### .dockerignore 优化
```
# 依赖和构建产物
node_modules
.next
.vercel
npm-debug.log
yarn-debug.log
yarn-error.log
pnpm-debug.log

# 版本控制
.git
.gitignore
.gitattributes

# 文档
README.md
*.md
docs/

# 环境变量
.env*
!.env.example

# 开发工具
.vscode
.idea
*.swp
*.swo
*~

# 操作系统
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# 日志
logs
*.log

# 测试
coverage
.nyc_output
junit.xml

# Docker相关
Dockerfile*
docker-compose*
.dockerignore

# 备份文件
*.bak
*.backup
*.tmp

# Serena项目记忆
.serena/

# 其他
*.tsbuildinfo
```

## 🚀 构建优化策略

### 1. 构建缓存优化
- **依赖层缓存**: 先复制package.json，利用Docker层缓存
- **源代码缓存**: 后复制源代码，避免依赖变化时重新构建
- **BuildKit**: 启用BuildKit并行构建

### 2. 镜像大小优化
- **多阶段构建**: 分离构建环境和运行环境
- **依赖清理**: 只复制必要的运行时文件
- **用户权限**: 使用非root用户运行

### 3. 构建速度优化
- **并行构建**: BuildKit支持并行下载和构建
- **缓存利用**: 合理利用Docker层缓存
- **网络优化**: 使用国内镜像源(如果配置)

## 📊 构建结果

### 构建性能
- **总构建时间**: 约3.5分钟
- **依赖安装**: 1分48秒
- **项目构建**: 1分39秒
- **镜像导出**: 5.5秒

### 镜像信息
- **镜像名称**: aqbjqtd/moontv:simplified
- **基础镜像**: node:20-alpine
- **运行用户**: nextjs (UID: 1001)
- **暴露端口**: 3000

## 🎯 运行配置

### 启动命令
```bash
docker run -d --name moontv -p 9000:3000 --env PASSWORD=123456 aqbjqtd/moontv:simplified
```

### 访问信息
- **本地访问**: http://localhost:9000
- **管理密码**: 123456
- **健康检查**: 容器启动时间约72ms

## 💡 优化经验

### 成功实践
1. **多阶段构建**: 显著减少最终镜像大小
2. **缓存优化**: 合理利用Docker层缓存加速构建
3. **安全运行**: 使用非root用户提高安全性
4. **环境变量**: 通过DOCKER_ENV控制Docker环境行为

### 注意事项
1. **网络状况**: 依赖下载速度受网络影响较大
2. **缓存清理**: 定期清理无用镜像和构建缓存
3. **版本管理**: 使用明确的镜像标签便于版本管理
4. **资源限制**: 注意容器资源限制和监控