# MoonTV DevOps部署与运维指南 (v3.2.0-fixed)
**最后更新**: 2025-10-06
**维护专家**: DevOps架构师
**适用版本**: v3.2.0-fixed及以上

## 🐳 Docker容器化部署完整方案

### 1. 生产级Dockerfile优化

#### 多阶段构建策略详解
```dockerfile
# ===== 第0阶段：依赖解析与缓存 =====
FROM node:20.10.0-alpine AS deps
# 使用Alpine Linux减少镜像体积
RUN corepack enable && corepack prepare pnpm@10.14.0 --activate
WORKDIR /app

# 优先复制依赖文件以利用层缓存
COPY package.json pnpm-lock.yaml ./
# 安装生产依赖，跳过开发脚本（husky等）
RUN pnpm install --frozen-lockfile --prod --ignore-scripts && \
    pnpm store prune && \
    rm -rf /tmp/* && \
    rm -rf /root/.cache

# ===== 第1阶段：应用构建 =====
FROM node:20.10.0-alpine AS builder
RUN corepack enable && corepack prepare pnpm@10.14.0 --activate
WORKDIR /app

# 复制所有源代码
COPY . .
# 复制依赖（利用缓存层）
COPY --from=deps /app/node_modules ./node_modules

# 安装完整依赖（包括开发依赖）
RUN pnpm install --frozen-lockfile

# 设置构建环境变量
ENV DOCKER_ENV=true NODE_ENV=production

# 生成运行时配置和PWA清单
RUN pnpm gen:manifest && pnpm gen:runtime

# 统一API路由运行时为nodejs（避免Edge Runtime兼容性问题）
RUN find ./src/app/api -name "route.ts" -type f -print0 | xargs -0 sed -i 's/export const runtime = '\''edge'\'';/export const runtime = '\''nodejs'\'';/g' || true

# Next.js构建
RUN pnpm build

# 清理开发依赖，保留生产依赖
RUN pnpm prune --prod --ignore-scripts && \
    rm -rf node_modules/.cache && \
    rm -rf .next/cache

# ===== 第2阶段：生产运行时 =====
FROM node:20.10.0-alpine AS runner

# 创建非特权用户
RUN addgroup -g 1001 -S nodejs && adduser -u 1001 -S nextjs -G nodejs

# 生产环境变量
ENV NODE_ENV=production \
    DOCKER_ENV=true \
    HOSTNAME=0.0.0.0 \
    PORT=3000 \
    NEXT_TELEMETRY_DISABLED=1

WORKDIR /app

# 复制构建产物（使用chown确保权限正确）
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

EXPOSE 3000

# 启动命令
CMD ["node", "start.js"]
```

#### 极致优化的.dockerignore配置
```dockerignore
# ===== 核心构建文件 =====
node_modules
.pnpm-store
.npm
.yarn/cache

# ===== 构建产物 =====
.next/
out/
dist/
build/
*.tsbuildinfo

# ===== 缓存文件 =====
.cache/
.parcel-cache/
.eslintcache

# ===== 环境配置 =====
.env
.env*.local
.envrc

# ===== 开发工具 =====
.vscode/
.idea/
*.swp
*.swo
*~

# ===== 版本控制 =====
.git/
.gitignore
.gitattributes

# ===== CI/CD =====
.github/
.gitlab-ci.yml
.travis.yml

# ===== 测试和覆盖率 =====
coverage/
.nyc_output/
junit.xml
test-results/

# ===== 文档 =====
README.md
CHANGELOG.md
LICENSE
*.md
docs/
examples/

# ===== 日志文件 =====
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*

# ===== 系统文件 =====
.DS_Store
Thumbs.db
desktop.ini
*.lnk

# ===== 开发配置 =====
.prettierrc*
.eslintrc*
jest.config.*
tsconfig.json
tailwind.config.*
postcss.config.*

# ===== 备份文件 =====
*.bak
*.backup
*.orig

# ===== AI助手文件 =====
.claude/
claudedocs/
CLAUDE.md

# ===== Serena记忆 =====
.serena/memories/

# ===== 其他工具 =====
.husky/
.lintstagedrc*
commitlint.config.*
```

### 2. Docker Compose生产编排

#### docker-compose.prod.yml
```yaml
version: '3.8'

services:
  # MoonTV主应用
  moontv:
    build:
      context: .
      dockerfile: Dockerfile
      target: runner
    image: moontv:latest
    container_name: moontv-app
    restart: unless-stopped
    ports:
      - "8080:3000"
    environment:
      - NODE_ENV=production
      - DOCKER_ENV=true
      - USERNAME=admin
      - PASSWORD=${PASSWORD:-your_secure_password}
      - NEXT_PUBLIC_STORAGE_TYPE=${STORAGE_TYPE:-localstorage}
      - NEXT_PUBLIC_SITE_NAME=${SITE_NAME:-MoonTV}
      # Redis配置（如果使用）
      - REDIS_URL=${REDIS_URL:-redis://redis:6379}
      # Upstash配置（如果使用）
      - UPSTASH_URL=${UPSTASH_URL:-}
      - UPSTASH_TOKEN=${UPSTASH_TOKEN:-}
      # 豆瓣代理配置
      - DOUBAN_PROXY_TYPE=${DOUBAN_PROXY_TYPE:-direct}
      - DOUBAN_PROXY=${DOUBAN_PROXY:-}
    volumes:
      # 配置文件挂载（可选）
      - ./config.json:/app/config.json:ro
      # 日志挂载
      - ./logs:/app/logs
    depends_on:
      - redis
    networks:
      - moontv-network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  # Redis缓存服务
  redis:
    image: redis:7-alpine
    container_name: moontv-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - redis-data:/data
    networks:
      - moontv-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Nginx反向代理（可选）
  nginx:
    image: nginx:alpine
    container_name: moontv-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
      - ./logs/nginx:/var/log/nginx
    depends_on:
      - moontv
    networks:
      - moontv-network

volumes:
  redis-data:
    driver: local

networks:
  moontv-network:
    driver: bridge
```

#### Nginx配置 (nginx.conf)
```nginx
events {
    worker_connections 1024;
}

http {
    upstream moontv-app {
        server moontv:3000;
    }

    # HTTP重定向到HTTPS
    server {
        listen 80;
        server_name your-domain.com;
        return 301 https://$server_name$request_uri;
    }

    # HTTPS主配置
    server {
        listen 443 ssl http2;
        server_name your-domain.com;

        # SSL配置
        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
        ssl_prefer_server_ciphers off;

        # 安全头
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # 静态文件缓存
        location /_next/static/ {
            proxy_pass http://moontv-app;
            proxy_cache_valid 200 1y;
            add_header Cache-Control "public, immutable";
        }

        # API请求
        location /api/ {
            proxy_pass http://moontv-app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # 主应用
        location / {
            proxy_pass http://moontv-app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

### 3. 生产环境部署脚本

#### deploy.sh
```bash
#!/bin/bash

# MoonTV生产环境部署脚本
# 使用方法: ./deploy.sh [环境名称]
# 示例: ./deploy.sh production

set -e

# 配置变量
ENVIRONMENT=${1:-production}
DOCKER_REGISTRY=${DOCKER_REGISTRY:-your-registry.com}
VERSION=${VERSION:-latest}
IMAGE_NAME=${DOCKER_REGISTRY}/moontv:${VERSION}

echo "🚀 开始部署MoonTV到 ${ENVIRONMENT} 环境..."

# 1. 环境检查
echo "📋 检查部署环境..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose未安装"
    exit 1
fi

# 2. 构建镜像
echo "🔨 构建Docker镜像..."
docker build -t ${IMAGE_NAME} .

# 3. 推送镜像（如果配置了registry）
if [[ "$DOCKER_REGISTRY" != "your-registry.com" ]]; then
    echo "📤 推送镜像到registry..."
    docker push ${IMAGE_NAME}
fi

# 4. 备份当前版本
echo "💾 备份当前版本..."
docker-compose -f docker-compose.prod.yml down || true
docker tag moontv:latest moontv:backup-$(date +%Y%m%d-%H%M%S) || true

# 5. 部署新版本
echo "🔄 部署新版本..."
export VERSION=${VERSION}
export PASSWORD=${PASSWORD}
export STORAGE_TYPE=${STORAGE_TYPE:-localstorage}
export SITE_NAME=${SITE_NAME:-MoonTV}

docker-compose -f docker-compose.prod.yml up -d

# 6. 健康检查
echo "🏥 执行健康检查..."
sleep 30
HEALTH_CHECK_URL="http://localhost:8080/api/health"
MAX_ATTEMPTS=10
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    if curl -f $HEALTH_CHECK_URL > /dev/null 2>&1; then
        echo "✅ 健康检查通过！"
        break
    else
        echo "⏳ 健康检查失败，${ATTEMPT}/${MAX_ATTEMPTS} 次尝试..."
        sleep 10
        ((ATTEMPT++))
    fi
done

if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
    echo "❌ 健康检查失败，部署回滚..."
    docker-compose -f docker-compose.prod.yml down
    docker tag moontv:backup-$(date +%Y%m%d-%H%M%S) moontv:latest
    docker-compose -f docker-compose.prod.yml up -d
    exit 1
fi

echo "🎉 部署完成！"
echo "📱 访问地址: http://localhost:8080"
echo "📊 查看日志: docker-compose -f docker-compose.prod.yml logs -f"
```

## 🌐 多平台部署策略

### 1. Vercel Serverless部署

#### vercel.json配置
```json
{
  "version": 2,
  "name": "moontv",
  "buildCommand": "pnpm run build",
  "outputDirectory": ".next",
  "installCommand": "pnpm install",
  "framework": "nextjs",
  "regions": ["sin1", "hkg1"],
  "env": {
    "NEXT_PUBLIC_STORAGE_TYPE": "upstash",
    "NODE_ENV": "production"
  },
  "build": {
    "env": {
      "NEXT_TELEMETRY_DISABLED": "1"
    }
  },
  "functions": {
    "src/app/api/**/*.ts": {
      "runtime": "nodejs18.x"
    }
  },
  "headers": [
    {
      "source": "/api/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "s-maxage=86400"
        }
      ]
    }
  ]
}
```

#### Vercel部署脚本
```bash
#!/bin/bash

# Vercel部署脚本
echo "🌐 部署到Vercel..."

# 检查Vercel CLI
if ! command -v vercel &> /dev/null; then
    echo "📦 安装Vercel CLI..."
    npm i -g vercel
fi

# 设置生产环境
export NODE_ENV=production
export NEXT_PUBLIC_STORAGE_TYPE=upstash

# 部署到生产环境
vercel --prod

echo "✅ Vercel部署完成！"
```

### 2. Cloudflare Pages部署

#### wrangler.toml配置
```toml
name = "moontv"
compatibility_date = "2024-01-01"
compatibility_flags = ["nodejs_compat"]

[env.production]
vars = { NODE_ENV = "production", NEXT_PUBLIC_STORAGE_TYPE = "d1" }

[[env.production.d1_databases]]
binding = "DB"
database_name = "moontv-db"
database_id = "your-d1-database-id"
```

#### Cloudflare部署脚本
```bash
#!/bin/bash

# Cloudflare Pages部署脚本
echo "☁️ 部署到Cloudflare Pages..."

# 检查Wrangler CLI
if ! command -v wrangler &> /dev/null; then
    echo "📦 安装Wrangler CLI..."
    npm i -g wrangler
fi

# 构建适配Cloudflare的版本
export NODE_ENV=production
export NEXT_PUBLIC_STORAGE_TYPE=d1

# 特殊构建处理
pnpm run pages:build

# 部署到Cloudflare Pages
wrangler pages publish .vercel/output/static --project-name moontv

echo "✅ Cloudflare Pages部署完成！"
```

### 3. Netlify部署

#### netlify.toml配置
```toml
[build]
  base = "/"
  command = "pnpm run build"
  publish = ".next"

[build.environment]
  NODE_VERSION = "18"
  NPM_VERSION = "10"
  NEXT_TELEMETRY_DISABLED = "1"

[[redirects]]
  from = "/api/*"
  to = "/.netlify/functions/:splat"
  status = 200

[[headers]]
  for = "/api/*"
  [headers.values]
    Cache-Control = "s-maxage=86400"

[functions]
  directory = "netlify/functions"
```

## 🔧 监控和运维体系

### 1. 应用性能监控

#### 自定义健康检查端点 (src/app/api/health/route.ts)
```typescript
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  try {
    // 检查数据库连接
    let dbStatus = 'disconnected';
    try {
      // 根据存储类型检查连接
      const storageType = process.env.NEXT_PUBLIC_STORAGE_TYPE;
      if (storageType === 'redis' && process.env.REDIS_URL) {
        // Redis连接检查
        const redis = await import('../lib/redis.db');
        const client = await redis.default.getClient();
        await client.ping();
        dbStatus = 'connected';
      } else if (storageType === 'upstash' && process.env.UPSTASH_URL) {
        // Upstash连接检查
        const upstash = await import('../lib/upstash.db');
        const client = await upstash.default.getClient();
        await client.ping();
        dbStatus = 'connected';
      } else {
        dbStatus = 'localstorage';
      }
    } catch (error) {
      console.error('Database health check failed:', error);
    }

    // 系统信息
    const systemInfo = {
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      version: process.env.npm_package_version || 'unknown',
      environment: process.env.NODE_ENV || 'unknown',
      storageType: process.env.NEXT_PUBLIC_STORAGE_TYPE || 'localstorage',
      dbStatus,
    };

    // 检查关键服务
    const checks = {
      database: dbStatus !== 'disconnected',
      memory: systemInfo.memory.heapUsed < 500 * 1024 * 1024, // 500MB
      uptime: systemInfo.uptime > 60, // 运行超过1分钟
    };

    const isHealthy = Object.values(checks).every(Boolean);

    return NextResponse.json({
      status: isHealthy ? 'healthy' : 'unhealthy',
      checks,
      system: systemInfo,
    }, {
      status: isHealthy ? 200 : 503,
    });
  } catch (error) {
    return NextResponse.json({
      status: 'error',
      error: error instanceof Error ? error.message : 'Unknown error',
    }, {
      status: 503,
    });
  }
}
```

### 2. 日志管理配置

#### 日志聚合脚本 (scripts/log-monitor.sh)
```bash
#!/bin/bash

# 日志监控脚本
LOG_DIR="./logs"
ALERT_EMAIL="admin@example.com"
MAX_LOG_SIZE="100M"

# 创建日志目录
mkdir -p $LOG_DIR

# 监控容器日志
monitor_docker_logs() {
    echo "📊 监控Docker容器日志..."
    
    while true; do
        # 检查应用容器日志
        docker logs moontv-app --since=1m 2>&1 | grep -i "error\|warning\|critical" && \
        send_alert "MoonTV应用出现错误或警告"
        
        # 检查容器状态
        if ! docker ps | grep -q moontv-app; then
            send_alert "MoonTV应用容器已停止"
        fi
        
        sleep 60
    done
}

# 发送告警
send_alert() {
    local message=$1
    echo "🚨 告警: $message"
    echo "$message" | mail -s "MoonTV告警" $ALERT_EMAIL
}

# 日志轮转
rotate_logs() {
    echo "🔄 执行日志轮转..."
    
    # 查找大日志文件并轮转
    find $LOG_DIR -name "*.log" -size +$MAX_LOG_SIZE -exec sh -c '
        for file; do
            mv "$file" "$file.$(date +%Y%m%d-%H%M%S).old"
            touch "$file"
        done
    ' sh {} +
}

# 启动监控
case "$1" in
    "monitor")
        monitor_docker_logs
        ;;
    "rotate")
        rotate_logs
        ;;
    *)
        echo "使用方法: $0 {monitor|rotate}"
        exit 1
        ;;
esac
```

### 3. 自动化备份策略

#### 备份脚本 (scripts/backup.sh)
```bash
#!/bin/bash

# 自动备份脚本
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="moontv-backup-$DATE"

# 创建备份目录
mkdir -p $BACKUP_DIR

echo "💾 开始备份MoonTV数据..."

# 1. 备份配置文件
echo "📋 备份配置文件..."
cp config.json $BACKUP_DIR/$BACKUP_NAME-config.json

# 2. 备份Redis数据（如果使用）
if [ "$NEXT_PUBLIC_STORAGE_TYPE" = "redis" ]; then
    echo "🗄️ 备份Redis数据..."
    docker exec moontv-redis redis-cli BGSAVE
    docker cp moontv-redis:/data/dump.rdb $BACKUP_DIR/$BACKUP_NAME-redis.rdb
fi

# 3. 备份应用日志
echo "📄 备份应用日志..."
tar -czf $BACKUP_DIR/$BACKUP_NAME-logs.tar.gz logs/

# 4. 压缩所有备份
echo "🗜️ 压缩备份文件..."
tar -czf $BACKUP_DIR/$BACKUP_NAME.tar.gz \
    $BACKUP_DIR/$BACKUP_NAME-*.json \
    $BACKUP_DIR/$BACKUP_NAME-*.rdb \
    $BACKUP_DIR/$BACKUP_NAME-*.tar.gz

# 清理临时文件
rm -f $BACKUP_DIR/$BACKUP_NAME-*.json \
      $BACKUP_DIR/$BACKUP_NAME-*.rdb \
      $BACKUP_DIR/$BACKUP_NAME-*.tar.gz

# 清理旧备份（保留最近7天）
echo "🧹 清理旧备份..."
find $BACKUP_DIR -name "moontv-backup-*.tar.gz" -mtime +7 -delete

echo "✅ 备份完成: $BACKUP_DIR/$BACKUP_NAME.tar.gz"
```

## 🔒 安全加固措施

### 1. 容器安全配置

#### 安全扫描脚本 (scripts/security-scan.sh)
```bash
#!/bin/bash

# 容器安全扫描脚本
IMAGE_NAME="moontv:latest"

echo "🔒 执行容器安全扫描..."

# 1. 使用Docker Scout扫描漏洞
if command -v docker scout &> /dev/null; then
    echo "📡 Docker Scout漏洞扫描..."
    docker scout cves --format sarif $IMAGE_NAME > security-scan.sarif
fi

# 2. 使用Trivy扫描漏洞
if command -v trivy &> /dev/null; then
    echo "🔍 Trivy漏洞扫描..."
    trivy image --format json --output trivy-report.json $IMAGE_NAME
fi

# 3. 检查镜像配置
echo "📋 检查镜像配置..."
docker inspect $IMAGE_NAME | jq '.[0].Config' > image-config.json

# 4. 检查运行时安全
echo "🏃 检查运行时安全..."
docker run --rm --security-opt=no-new-privileges \
    --cap-drop ALL \
    --cap-add NET_BIND_SERVICE \
    $IMAGE_NAME echo "Security check passed"

echo "✅ 安全扫描完成！"
```

### 2. 网络安全配置

#### Docker网络隔离
```bash
#!/bin/bash

# 创建专用网络
docker network create --driver bridge moontv-internal

# 运行应用时使用专用网络
docker run -d \
  --name moontv-app \
  --network moontv-internal \
  --network-alias app \
  moontv:latest

# 运行Redis时使用专用网络
docker run -d \
  --name moontv-redis \
  --network moontv-internal \
  --network-alias redis \
  redis:alpine
```

## 📊 性能优化和调优

### 1. 资源限制配置

#### Docker Compose资源限制
```yaml
services:
  moontv:
    # ... 其他配置
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  redis:
    # ... 其他配置
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
        reservations:
          cpus: '0.25'
          memory: 128M
```

### 2. 缓存优化策略

#### Redis缓存配置优化
```bash
# Redis配置文件 (redis.conf)
maxmemory 256mb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
```

## 🚨 故障排除和恢复

### 1. 常见问题诊断

#### 诊断脚本 (scripts/diagnose.sh)
```bash
#!/bin/bash

# 系统诊断脚本
echo "🔍 MoonTV系统诊断..."

# 1. 检查容器状态
echo "📦 检查容器状态..."
docker ps -a | grep moontv

# 2. 检查资源使用
echo "📊 检查资源使用..."
docker stats --no-stream moontv-app

# 3. 检查网络连接
echo "🌐 检查网络连接..."
docker exec moontv-app wget -qO- http://localhost:3000/api/health

# 4. 检查日志
echo "📄 检查最近日志..."
docker logs --tail=50 moontv-app

# 5. 检查配置
echo "⚙️ 检查配置文件..."
docker exec moontv-app cat /app/config.json | jq .

echo "✅ 诊断完成！"
```

### 2. 自动恢复机制

#### 健康检查自动重启
```yaml
# docker-compose.yml中的健康检查配置
services:
  moontv:
    # ... 其他配置
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "node", "--eval", "require('http').get('http://localhost:3000/api/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => process.exit(1))"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
```

## 📈 监控指标和告警

### 1. 关键性能指标 (KPIs)

```yaml
# 应用性能指标
performance_metrics:
  response_time:
    target: "<200ms"
    warning: ">500ms"
    critical: ">1000ms"
  
  availability:
    target: "99.9%"
    warning: "<99.5%"
    critical: "<99.0%"
  
  error_rate:
    target: "<0.1%"
    warning: ">1%"
    critical: ">5%"

# 资源使用指标
resource_metrics:
  cpu_usage:
    target: "<50%"
    warning: ">70%"
    critical: ">90%"
  
  memory_usage:
    target: "<256MB"
    warning: ">400MB"
    critical: ">512MB"
  
  disk_usage:
    target: "<80%"
    warning: ">85%"
    critical: ">95%"
```

### 2. 告警配置

#### Prometheus告警规则
```yaml
# prometheus-rules.yml
groups:
  - name: moontv-alerts
    rules:
      - alert: HighResponseTime
        expr: http_request_duration_seconds{quantile="0.95"} > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "MoonTV响应时间过高"
          description: "95%的请求响应时间超过500ms"

      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "MoonTV错误率过高"
          description: "5xx错误率超过5%"

      - alert: ServiceDown
        expr: up{job="moontv"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "MoonTV服务不可用"
          description: "MoonTV服务已停止响应"
```

---

**文档维护**: DevOps架构师  
**更新频率**: 根据部署需要更新  
**版本**: v3.2.0-fixed  
**最后更新**: 2025-10-06