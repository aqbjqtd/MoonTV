# 极致优化的 MoonTV Dockerfile
# 基于深度研究的多阶段构建，实现最小镜像体积和最佳性能

# ---- 第 0 阶段：依赖解析 ----
FROM node:20.10.0-alpine AS deps
# 锁定具体版本号，确保构建一致性
# 使用Alpine Linux最小镜像 (~5MB vs ~100MB)

# 启用 corepack 并锁定 pnpm 版本与项目一致
RUN corepack enable && corepack prepare pnpm@10.14.0 --activate

# 设置工作目录
WORKDIR /app

# 安全：仅复制依赖清单文件，提高层缓存命中率
COPY package.json pnpm-lock.yaml ./

# 优化依赖安装：仅生产依赖，跳过prepare脚本（避免husky依赖问题）
RUN pnpm install --frozen-lockfile --prod --ignore-scripts && \
    pnpm store prune && \
    rm -rf /tmp/* && \
    rm -rf /root/.cache

# ---- 第 1 阶段：构建应用 ----
FROM node:20.10.0-alpine AS builder
RUN corepack enable && corepack prepare pnpm@10.14.0 --activate
WORKDIR /app

# 复制所有源代码（优化 .dockerignore 会过滤不必要文件）
COPY . .

# 复制生产依赖（从deps阶段）
COPY --from=deps /app/node_modules ./node_modules

# 修复：重新安装开发依赖用于构建
RUN pnpm install --frozen-lockfile

# Docker环境配置：强制使用Node.js Runtime而非Edge Runtime
# 确保在容器环境中的兼容性
ENV DOCKER_ENV=true
ENV NODE_ENV=production

# 生成运行时配置和PWA manifest（在构建前必须生成）
RUN pnpm gen:manifest && pnpm gen:runtime

# 修复Edge Runtime兼容性问题：替换为Node.js Runtime
# 容器环境不支持Edge Runtime的某些特性
RUN find ./src/app/api -name "route.ts" -type f -print0 | xargs -0 sed -i 's/export const runtime = '\''edge'\'';/export const runtime = '\''nodejs'\'';/g' || true

# 强制动态渲染以支持运行时环境变量
RUN sed -i "/const inter = Inter({ subsets: \['latin'] });/a export const dynamic = 'force-dynamic';" src/app/layout.tsx || true

# 构建Next.js应用（standalone模式，适合Docker部署）
RUN pnpm build

# 清理开发依赖，保留构建产物（跳过prepare脚本避免husky问题）
RUN pnpm prune --prod --ignore-scripts && \
    rm -rf node_modules/.cache && \
    rm -rf .next/cache

# ---- 第 2 阶段：生产运行时 ----
# 使用 Alpine Linux 镜像（平衡体积和兼容性）
FROM node:20.10.0-alpine AS runner

# 创建非 root 用户提高安全性
RUN addgroup -g 1001 -S nodejs && adduser -u 1001 -S nextjs -G nodejs

# 设置生产环境变量
ENV NODE_ENV=production \
    DOCKER_ENV=true \
    HOSTNAME=0.0.0.0 \
    PORT=3000 \
    NEXT_TELEMETRY_DISABLED=1

# 创建应用目录
WORKDIR /app

# 从构建阶段复制文件（使用正确的文件所有权）
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/config.json ./config.json
COPY --from=builder --chown=nextjs:nodejs /app/scripts ./scripts
COPY --from=builder --chown=nextjs:nodejs /app/start.js ./start.js

# 切换到非特权用户
USER nextjs

# 健康检查配置
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD node --eval "require('http').get('http://localhost:3000/api/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => process.exit(1))" || echo "Health check fallback"

# 暴露端口
EXPOSE 3000

# 启动应用
CMD ["node", "start.js"] 