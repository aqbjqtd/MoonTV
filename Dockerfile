# ================================
# 最优化 MoonTV Docker 构建配置
# 多阶段构建 + Alpine Linux + 缓存优化
# ================================

# ---- 第 1 阶段：依赖安装（优化缓存层） ----
FROM node:20-alpine AS deps
LABEL stage=deps

# 安装必要系统依赖并启用 pnpm
RUN apk add --no-cache libc6-compat git \
    && corepack enable \
    && corepack prepare pnpm@latest --activate

WORKDIR /app

# 优化：分层复制包配置文件以最大化缓存命中
COPY package.json pnpm-lock.yaml ./

# 高效依赖安装：仅生产依赖 + 跳过脚本
RUN pnpm install --prod --frozen-lockfile --no-optional --ignore-scripts \
    && pnpm store prune

# ---- 第 2 阶段：开发依赖安装 ----
FROM node:20-alpine AS dev-deps
LABEL stage=dev-deps

RUN apk add --no-cache libc6-compat \
    && corepack enable \
    && corepack prepare pnpm@latest --activate

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
COPY --from=deps /app/node_modules ./node_modules

# 安装开发依赖用于构建（跳过脚本避免 husky 错误）
RUN pnpm install --frozen-lockfile --no-optional --ignore-scripts

# ---- 第 3 阶段：应用构建 ----
FROM node:20-alpine AS builder
LABEL stage=builder

RUN apk add --no-cache libc6-compat \
    && corepack enable \
    && corepack prepare pnpm@latest --activate

WORKDIR /app

# 复制依赖和源代码
COPY --from=dev-deps /app/node_modules ./node_modules
COPY . .

# Docker 环境优化：确保 Node.js runtime
ENV DOCKER_ENV=true \
    NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1

# 运行时优化脚本：强制 Node.js runtime 替代 Edge runtime
RUN find ./src -type f -name "route.ts" -exec \
    sed -i "s/export const runtime = 'edge';/export const runtime = 'nodejs';/g" {} \; \
    && sed -i "/const inter = Inter/a export const dynamic = 'force-dynamic';" src/app/layout.tsx

# 高效构建：类型检查 + 构建 + 清理
RUN pnpm run build \
    && pnpm store prune \
    && rm -rf /app/.next/cache

# ---- 第 4 阶段：生产运行镜像（最小化） ----
FROM node:20-alpine AS runner
LABEL maintainer="aqbjqtd" \
      version="v2.0.0" \
      description="MoonTV Production Image - Optimized Alpine"

# 安全优化：创建非特权用户
RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 nextjs nodejs

# 生产环境配置
ENV NODE_ENV=production \
    HOSTNAME=0.0.0.0 \
    PORT=3000 \
    DOCKER_ENV=true \
    NEXT_TELEMETRY_DISABLED=1

WORKDIR /app

# 精确复制生产所需文件（最小化镜像大小）
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/scripts ./scripts
COPY --from=builder --chown=nextjs:nodejs /app/start.js ./start.js
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/config.json ./config.json

# 安全切换到非特权用户
USER nextjs

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "http.get('http://localhost:3000/api/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1); })" || exit 1

EXPOSE 3000

# 优化启动：使用自定义启动脚本
CMD ["node", "start.js"]