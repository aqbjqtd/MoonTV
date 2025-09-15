# MoonTV 超优化Docker镜像 - 最小化版本
# 目标：最小化镜像大小，充分利用Next.js standalone特性

# ---- 第 1 阶段：依赖安装 ----
FROM node:22-alpine AS deps

WORKDIR /app

# 优化npm配置
RUN npm config set fund false && \
    npm config set audit false && \
    npm config set loglevel error

# 复制依赖文件
COPY package.json package-lock.json ./

# 仅安装生产依赖
RUN npm ci --omit=dev --legacy-peer-deps --ignore-scripts && \
    npm cache clean --force

# ---- 第 2 阶段：构建应用 ----
FROM node:22-alpine AS builder

WORKDIR /app

# 复制依赖文件并安装所有依赖（包含开发依赖用于构建）
COPY package.json package-lock.json ./
RUN npm ci --legacy-peer-deps --ignore-scripts && \
    npm cache clean --force

# 复制源代码
COPY . .

# 设置环境变量
ENV NODE_ENV=production
ENV DOCKER_ENV=true
ENV NEXT_TELEMETRY_DISABLED=1
ENV HUSKY=0

# 修复Edge Runtime为Node Runtime
RUN find ./src -type f -name "route.ts" -print0 \
    | xargs -0 sed -i "s/export const runtime = 'edge';/export const runtime = 'nodejs';/g"

# 启用动态渲染以读取环境变量
RUN sed -i "/const inter = Inter({ subsets: \\['latin'] });/a export const dynamic = 'force-dynamic';" src/app/layout.tsx

# 构建应用
RUN node scripts/convert-config.js && \
    node scripts/generate-manifest.js && \
    npx next build

# ---- 第 3 阶段：运行时镜像（超小化） ----
FROM node:22-alpine AS runner

# 仅安装必要的运行时工具
RUN apk add --no-cache dumb-init curl && \
    rm -rf /var/cache/apk/*

# 创建非root用户
RUN addgroup -g 1001 -S nodejs && \
    adduser -u 1001 -S nextjs -G nodejs

WORKDIR /app

# 设置环境变量
ENV NODE_ENV=production
ENV NODE_OPTIONS=--max-old-space-size=256
ENV HOSTNAME=0.0.0.0
ENV PORT=3000
ENV DOCKER_ENV=true
ENV NEXT_TELEMETRY_DISABLED=1
ENV TZ=Asia/Shanghai

# 从构建阶段复制standalone输出（Next.js已经包含了所有必要的依赖）
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/public ./public/
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static/

# 复制必要的配置文件和scripts目录
COPY --from=builder --chown=nextjs:nodejs /app/start.js ./start.js
COPY --from=builder --chown=nextjs:nodejs /app/config.json ./config.json
COPY --from=builder --chown=nextjs:nodejs /app/scripts ./scripts/

# 创建必要的目录
RUN mkdir -p /app/data /app/logs && \
    chown -R nextjs:nodejs /app/data /app/logs

# 修复脚本权限
RUN chmod +x ./start.js

# 切换到非特权用户
USER nextjs

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/api/health || exit 1

EXPOSE 3000

# 启动命令
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "start.js"]