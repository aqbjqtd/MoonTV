# MoonTV 部署指南

## 项目部署概述

MoonTV 支持多种部署平台，每种平台都有特定的配置要求和最佳实践。本指南涵盖了 Docker、Vercel、Netlify 和 Cloudflare Pages 的完整部署流程。

## 部署平台对比

| 平台 | 存储类型推荐 | 构建时间 | 冷启动 | 适用场景 |
|------|-------------|----------|--------|----------|
| Docker | redis/upstash/d1 | 2-3分钟 | 1-2秒 | 完整功能、自托管 |
| Vercel | upstash/d1 | 1-2分钟 | <100ms | 快速部署、全球CDN |
| Netlify | upstash/d1 | 1-2分钟 | <200ms | 静态优化、边缘计算 |
| Cloudflare Pages | d1 | 2-3分钟 | <50ms | 极致性能、Workers集成 |

## 1. Docker 部署

### 1.1 环境准备

```bash
# 创建项目目录
mkdir moontv-docker
cd moontv-docker

# 创建配置文件
cp config.json.example config.json
```

### 1.2 Docker Compose 配置

```yaml
# docker-compose.yml
version: '3.8'

services:
  moontv:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DOCKER_ENV=true
      - NEXT_PUBLIC_STORAGE_TYPE=redis
      - REDIS_URL=redis://redis:6379
      - PASSWORD=your_secure_password
    depends_on:
      - redis
    volumes:
      - ./config.json:/app/config.json:ro

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes

volumes:
  redis_data:
```

### 1.3 构建优化配置

```dockerfile
# Dockerfile (4阶段构建)
FROM node:18-alpine AS deps
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm && pnpm fetch

FROM node:18-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV DOCKER_ENV=true
ENV NODE_ENV=production
RUN npm install -g pnpm && \
    pnpm install --frozen-lockfile && \
    pnpm gen:manifest && \
    pnpm gen:runtime && \
    pnpm build

FROM node:18-alpine AS runner
WORKDIR /app
ENV DOCKER_ENV=true
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/config.json ./
COPY --from=builder /app/node_modules ./node_modules

EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"
CMD ["node", "server.js"]
```

### 1.4 生产环境部署

```bash
# 构建和启动
docker-compose up -d

# 查看日志
docker-compose logs -f moontv

# 停止服务
docker-compose down

# 更新部署
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### 1.5 性能优化

```bash
# 优化 Redis 配置
redis-cli config set maxmemory 256mb
redis-cli config set maxmemory-policy allkeys-lru

# 监控资源使用
docker stats moontv
docker logs moontv | grep "memory usage"
```

## 2. Vercel 部署

### 2.1 项目配置

```json
// vercel.json
{
  "builds": [
    {
      "src": "package.json",
      "use": "@vercel/next"
    }
  ],
  "env": {
    "NEXT_PUBLIC_STORAGE_TYPE": "upstash",
    "UPSTASH_URL": "@upstash_redis_url",
    "UPSTASH_TOKEN": "@upstash_redis_token",
    "PASSWORD": "@password",
    "NEXT_PUBLIC_SITE_NAME": "MoonTV"
  },
  "crons": []
}
```

### 2.2 环境变量设置

```bash
# Vercel CLI 配置
vercel env add UPSTASH_URL production
vercel env add UPSTASH_TOKEN production
vercel env add PASSWORD production
vercel env add NEXT_PUBLIC_SITE_NAME production

# 验证配置
vercel env ls
```

### 2.3 构建优化

```json
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  experimental: {
    serverActions: true,
    serverComponentsExternalPackages: []
  },
  images: {
    domains: [],
    unoptimized: true
  },
  compress: true,
  poweredByHeader: false
}

module.exports = nextConfig
```

### 2.4 部署流程

```bash
# 安装 Vercel CLI
npm install -g vercel

# 登录和部署
vercel login
vercel --prod

# 监控部署
vercel logs
vercel inspect
```

## 3. Netlify 部署

### 3.1 构建配置

```yaml
# netlify.toml
[build]
  command = "pnpm build"
  publish = ".next"

[build.environment]
  NODE_VERSION = "18"
  NEXT_PUBLIC_STORAGE_TYPE = "upstash"

[[plugins]]
  package = "@netlify/plugin-nextjs"

[context.production]
  environment = { NEXT_PUBLIC_ENABLE_REGISTER = "true" }

[context.deploy-preview]
  environment = { NEXT_PUBLIC_ENABLE_REGISTER = "false" }
```

### 3.2 函数配置

```javascript
// netlify/functions/headers.js
const headers = {
  'Content-Security-Policy': "default-src 'self'; script-src 'self' 'unsafe-eval' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' wss: https:;",
  'X-Frame-Options': 'DENY',
  'X-Content-Type-Options': 'nosniff'
};

exports.handler = async (event) => {
  return {
    statusCode: 200,
    headers: headers,
    body: JSON.stringify({ message: 'Headers applied' })
  };
};
```

### 3.3 环境变量管理

```bash
# Netlify CLI 配置
netlify env:set UPSTASH_URL "your_upstash_url"
netlify env:set UPSTASH_TOKEN "your_upstash_token"
netlify env:set PASSWORD "your_password"

# 部署
netlify deploy --prod
```

## 4. Cloudflare Pages 部署

### 4.1 构建配置

```yaml
# wrangler.toml
name = "moontv"
compatibility_date = "2023-10-30"

[build]
command = "pnpm pages:build"
cwd = "."
watch_dir = "src/app"

[build.upload]
format = "directory"
dir = ".vercel/output/static"

[[d1_databases]]
binding = "DB"
name = "moontv-db"
database_id = "your-database-id"

[env.production.vars]
NEXT_PUBLIC_STORAGE_TYPE = "d1"
NEXT_PUBLIC_SITE_NAME = "MoonTV"
PASSWORD = "your_password"

[env.preview.vars]
NEXT_PUBLIC_STORAGE_TYPE = "d1"
NEXT_PUBLIC_ENABLE_REGISTER = "false"
```

### 4.2 构建脚本

```json
// package.json scripts
{
  "scripts": {
    "pages:build": "NODE_ENV=production pnpm build && pnpm export",
    "pages:dev": "wrangler pages dev .vercel/output/static",
    "pages:deploy": "wrangler pages deploy .vercel/output/static"
  }
}
```

### 4.3 D1 数据库配置

```bash
# 创建 D1 数据库
wrangler d1 create moontv-db

# 执行迁移
wrangler d1 execute moontv-db --file=./scripts/d1-migrations.sql

# 本地开发
wrangler d1 execute moontv-db --local --file=./scripts/d1-migrations.sql
```

### 4.4 部署流程

```bash
# 构建项目
pnpm pages:build

# 部署到 Pages
pnpm pages:deploy

# 查看日志
wrangler pages tail
```

## 5. 存储后端配置

### 5.1 Upstash Redis 配置

```javascript
// src/lib/upstash.db.ts
import { Redis } from '@upstash/redis'

const redis = new Redis({
  url: process.env.UPSTASH_URL!,
  token: process.env.UPSTASH_TOKEN!,
  automaticDeserialization: false
})

export default redis
```

### 5.2 Cloudflare D1 配置

```typescript
// src/lib/d1.db.ts
interface D1Storage implements IStorage {
  private db: D1Database

  constructor(db: D1Database) {
    this.db = db
  }

  async get(key: string): Promise<string | null> {
    const result = await this.db.prepare('SELECT value FROM kv WHERE key = ?').bind(key).first()
    return result ? result.value : null
  }

  async set(key: string, value: string, ttl?: number): Promise<void> {
    if (ttl) {
      await this.db.prepare('INSERT OR REPLACE INTO kv (key, value, expires_at) VALUES (?, ?, ?)')
        .bind(key, value, Date.now() + ttl * 1000)
        .run()
    } else {
      await this.db.prepare('INSERT OR REPLACE INTO kv (key, value) VALUES (?, ?)')
        .bind(key, value)
        .run()
    }
  }
}
```

## 6. 监控和维护

### 6.1 健康检查

```typescript
// src/app/api/health/route.ts
export async function GET() {
  const startTime = Date.now()
  
  try {
    // 检查数据库连接
    const db = getStorage()
    await db.set('health-check', 'ok')
    await db.get('health-check')
    
    // 检查配置加载
    const config = await getConfig()
    
    return Response.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      responseTime: Date.now() - startTime,
      version: process.env.npm_package_version || 'unknown',
      storage: process.env.NEXT_PUBLIC_STORAGE_TYPE,
      config: config.sites.length > 0 ? 'loaded' : 'empty'
    })
  } catch (error) {
    return Response.json({
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    }, { status: 500 })
  }
}
```

### 6.2 性能监控

```typescript
// src/lib/monitoring.ts
export class Monitoring {
  static async trackMetric(name: string, value: number, tags: Record<string, string> = {}) {
    // 实现性能指标收集
    console.log(`[${new Date().toISOString()}] METRIC: ${name}=${value}`, tags)
  }

  static async trackError(error: Error, context: Record<string, any> = {}) {
    console.error(`[${new Date().toISOString()}] ERROR: ${error.message}`, {
      stack: error.stack,
      ...context
    })
  }

  static async getSystemInfo() {
    return {
      memoryUsage: process.memoryUsage(),
      uptime: process.uptime(),
      platform: process.platform,
      version: process.version,
      storageType: process.env.NEXT_PUBLIC_STORAGE_TYPE
    }
  }
}
```

## 7. 安全配置

### 7.1 HTTPS 强制

```typescript
// next.config.js
const nextConfig = {
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=31536000; includeSubDomains; preload'
          },
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block'
          },
          {
            key: 'X-Frame-Options',
            value: 'DENY'
          },
          {
            key: 'Content-Security-Policy',
            value: "default-src 'self'; script-src 'self' 'unsafe-eval' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' wss: https:;"
          }
        ]
      }
    ]
  }
}
```

### 7.2 环境变量验证

```typescript
// src/lib/env.ts
export function validateEnv() {
  const required = ['PASSWORD']
  const storageType = process.env.NEXT_PUBLIC_STORAGE_TYPE

  if (storageType === 'redis') {
    required.push('REDIS_URL')
  } else if (storageType === 'upstash') {
    required.push('UPSTASH_URL', 'UPSTASH_TOKEN')
  } else if (storageType === 'd1') {
    // D1 通过 binding 自动配置
  }

  const missing = required.filter(key => !process.env[key])
  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`)
  }
}
```

## 8. 故障排除

### 8.1 常见问题

```bash
# Docker 构建失败
docker-compose build --no-cache

# 内存不足问题
docker-compose up -d --memory="2g" --memory-swap="3g"

# Redis 连接问题
docker-compose logs redis
docker exec -it moontv-redis-1 redis-cli ping

# Edge Runtime 错误
# 检查是否使用了 Node.js 特有模块
# 确保所有 API 路由使用 edge runtime
```

### 8.2 性能调优

```typescript
// 性能优化配置
const performanceConfig = {
  // 启用压缩
  compress: true,
  
  // 优化图片
  images: {
    domains: [],
    unoptimized: true
  },
  
  // 缓存配置
  generateBuildId: async () => {
    return 'build-' + process.env.BUILD_ID || Date.now().toString()
  },
  
  // 实验性功能
  experimental: {
    serverActions: true,
    incrementalCacheHandlerPath: '/api/cache'
  }
}
```

## 9. 备份和恢复

### 9.1 配置备份

```bash
# 备份配置文件
cp config.json config.json.backup.$(date +%Y%m%d)

# 备份数据库 (Redis)
redis-cli save
cp dump.rdb backup/dump.rdb.$(date +%Y%m%d)

# 恢复配置
cp config.json.backup config.json
docker-compose restart
```

### 9.2 自动备份脚本

```bash
#!/bin/bash
# scripts/backup.sh

BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# 备份配置
cp config.json "$BACKUP_DIR/config_$DATE.json"

# 备份 Redis 数据
docker exec moontv-moontv-1 redis-cli BGSAVE
sleep 5
docker cp moontv-moontv-1:/data/dump.rdb "$BACKUP_DIR/dump_$DATE.rdb"

# 清理旧备份 (保留7天)
find $BACKUP_DIR -name "*.json" -mtime +7 -delete
find $BACKUP_DIR -name "*.rdb" -mtime +7 -delete

echo "Backup completed: $DATE"
```

## 10. 版本管理

### 10.1 部署版本控制

```bash
# 标记版本
git tag -a v1.0.0 -m "Production release v1.0.0"
git push origin v1.0.0

# 回滚版本
git checkout v1.0.0
docker-compose build --no-cache
docker-compose up -d
```

### 10.2 蓝绿部署

```yaml
# docker-compose.blue.yml
version: '3.8'
services:
  moontv-blue:
    image: moontv:latest
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DEPLOYMENT_COLOR=blue

# docker-compose.green.yml
version: '3.8'
services:
  moontv-green:
    image: moontv:latest
    ports:
      - "3001:3000"
    environment:
      - NODE_ENV=production
      - DEPLOYMENT_COLOR=green
```

## 最佳实践总结

1. **选择合适的存储后端**
   - Docker: Redis (性能最优)
   - Serverless: Upstash (简单易用)
   - Cloudflare: D1 (原生集成)

2. **环境配置**
   - 使用环境变量管理敏感信息
   - 实施配置验证和健康检查
   - 启用 HTTPS 和安全头

3. **性能优化**
   - 启用边缘运行时 (Edge Runtime)
   - 配置适当的缓存策略
   - 监控资源使用情况

4. **部署策略**
   - 实施蓝绿部署减少停机时间
   - 配置自动备份和恢复
   - 建立监控和告警系统

5. **维护流程**
   - 定期更新依赖和镜像
   - 监控日志和性能指标
   - 制定应急响应计划

---

*创建时间: 2025-10-07*
*最后更新: 2025-10-07*
*版本: v1.0*
*适用版本: MoonTV v3.2.0+*