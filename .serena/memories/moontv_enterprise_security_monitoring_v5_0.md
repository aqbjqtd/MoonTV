# MoonTV 企业级安全配置完整指南 v4.0.0

> **文档版本**: v4.0.0  
> **创建日期**: 2025-10-08  
> **适用范围**: MoonTV 项目企业级部署  
> **安全等级**: 企业级/生产环境  
> **合规标准**: OWASP Top 10, CIS Benchmarks, NIST Cybersecurity Framework

## 📋 目录

1. [安全架构概览](#安全架构概览)
2. [容器安全最佳实践](#容器安全最佳实践)
3. [API 安全认证和授权](#api安全认证和授权)
4. [数据加密和保护](#数据加密和保护)
5. [安全扫描和漏洞管理](#安全扫描和漏洞管理)
6. [合规性检查清单](#合规性检查清单)
7. [安全运维和监控](#安全运维和监控)
8. [应急响应计划](#应急响应计划)

---

## 安全架构概览

### 当前安全状况评估

基于对 MoonTV 项目代码的深入分析，当前安全配置状况如下：

#### ✅ 优势配置

- **四阶段 Docker 构建**: 企业级安全分层架构
- **Distroless 运行时**: 最小化攻击面
- **非 root 用户运行**: 用户 ID 1001:1001
- **HMAC 签名认证**: 高强度身份验证
- **中间件认证**: 全面的请求拦截
- **健康检查**: 轻量级状态监控

#### ⚠️ 需要增强的配置

- **容器运行时安全**: 需要更多安全限制
- **API 限流**: 缺少防暴力破解机制
- **日志审计**: 需要结构化安全日志
- **依赖扫描**: 需要自动化漏洞检测
- **加密传输**: 需要强制 HTTPS 配置
- **环境变量**: 需要密钥管理优化

### 安全分层架构

```
┌─────────────────────────────────────────────────────────────┐
│                    应用层安全 (Application Layer)              │
├─────────────────────────────────────────────────────────────┤
│ • JWT/HMAC认证  • RBAC权限控制  • API限流  • 输入验证         │
└─────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────┐
│                    容器层安全 (Container Layer)               │
├─────────────────────────────────────────────────────────────┤
│ • Distroless  • 非-root用户  • 只读文件系统  • 资源限制       │
└─────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────┐
│                    网络层安全 (Network Layer)                 │
├─────────────────────────────────────────────────────────────┤
│ • HTTPS/TLS   • CORS配置  • WAF防护  • 网络隔离             │
└─────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────┐
│                    数据层安全 (Data Layer)                    │
├─────────────────────────────────────────────────────────────┤
│ • 静态加密  • 传输加密  • 密钥轮换  • 备份加密               │
└─────────────────────────────────────────────────────────────┘
```

---

## 容器安全最佳实践

### 1. 增强版 Dockerfile 安全配置

基于当前的四阶段构建，添加更多安全特性：

```dockerfile
# =================================================================
# MoonTV 企业级安全增强 Dockerfile v4.0.0
# 安全特性: 最小权限、深度防御、安全扫描兼容
# =================================================================

# ==========================================
# 阶段1：安全基础层 (Secure Base)
# ==========================================
FROM node:20-alpine AS secure-base

# 安全更新和基础包安装
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache \
        libc6-compat \
        ca-certificates \
        tzdata \
        dumb-init \
        python3 \
        make \
        g++ \
        # 安全相关包
        curl \
        jq \
        && \
    # 清理包管理器缓存
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/* && \
    # 创建非特权用户
    addgroup -g 1001 -S moontv && \
    adduser -S moontv -u 1001 -G moontv

# 安全环境变量
ENV TZ=Asia/Shanghai \
    NODE_ENV=production \
    NPM_CONFIG_AUDIT=false \
    NPM_CONFIG_FUND=false

# ==========================================
# 阶段2：安全依赖解析层 (Secure Dependencies)
# ==========================================
FROM secure-base AS secure-deps

WORKDIR /app

# 安全：仅复制依赖清单文件
COPY package.json pnpm-lock.yaml .npmrc ./

# 安装依赖并进行安全检查
RUN corepack enable && \
    corepack prepare pnpm@latest --activate && \
    # 生产依赖安装
    pnpm install --frozen-lockfile --prod --ignore-scripts --force && \
    # 安全审计
    pnpm audit --audit-level=high || true && \
    # 清理敏感信息和缓存
    pnpm store prune && \
    rm -rf /tmp/* /root/.cache /root/.npm /root/.pnpm-store /app/.pnpm-cache && \
    # 删除.pnpm-debug.log
    find /root -name "*.log" -delete

# ==========================================
# 阶段3：安全构建层 (Secure Build)
# ==========================================
FROM secure-base AS secure-builder

WORKDIR /app

# 复制生产依赖
COPY --from=secure-deps /app/node_modules ./node_modules
COPY package.json pnpm-lock.yaml .npmrc ./
COPY tsconfig.json next.config.js tailwind.config.ts postcss.config.js ./
COPY .prettierrc.js .eslintrc.js ./
COPY public/ ./public/
COPY scripts/ ./scripts/
COPY config.json ./config.json
COPY src/ ./src/
COPY start.js ./start.js

# 开发依赖安装
RUN pnpm install --frozen-lockfile --ignore-scripts

# 安全构建环境
ENV DOCKER_ENV=true \
    NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    NODE_OPTIONS="--max-old-space-size=4096" \
    # 安全相关环境变量
    DEBUG=false \
    VERBOSE=false

# 代码质量检查
RUN pnpm lint:fix && \
    pnpm typecheck && \
    # 生成清单和运行时配置
    pnpm gen:manifest && \
    pnpm gen:runtime

# 构建应用
ENV DOCKER_BUILDKIT=1
RUN pnpm build

# 构建后安全清理
RUN pnpm prune --prod --ignore-scripts && \
    # 深度清理开发工具和缓存
    rm -rf node_modules/.cache \
           node_modules/.husky \
           node_modules/.bin/eslint \
           node_modules/.bin/prettier \
           node_modules/.bin/jest \
           node_modules/.bin/tsc \
           .next/cache \
           .next/server/app/.next && \
    # 删除所有日志和元数据文件
    find . -name "*.log" -delete && \
    find . -name ".DS_Store" -delete && \
    find . -name "Thumbs.db" -delete && \
    find . -name "*.tsbuildinfo" -delete && \
    find . -name "*.test.*" -delete && \
    find . -name "*.spec.*" -delete && \
    # 最终缓存清理
    rm -rf /tmp/* /root/.cache /root/.npm /root/.pnpm-store

# ==========================================
# 阶段4：安全运行时层 (Secure Runtime)
# ==========================================
FROM gcr.io/distroless/nodejs20-debian12 AS secure-runner

# 设置应用目录
WORKDIR /app

# 生产安全环境变量
ENV NODE_ENV=production \
    DOCKER_ENV=true \
    HOSTNAME=0.0.0.0 \
    PORT=3000 \
    NEXT_TELEMETRY_DISABLED=1 \
    NODE_OPTIONS="--max-old-space-size=2048" \
    TZ=Asia/Shanghai \
    UV_THREADPOOL_SIZE=16 \
    # 安全环境变量
    DEBUG=false \
    VERBOSE=false \
    # CORS安全配置
    NEXT_PUBLIC_API_URL="" \
    # 会话安全配置
    SESSION_TIMEOUT=3600 \
    COOKIE_SECURE=true \
    COOKIE_HTTP_ONLY=true

# 从构建阶段复制文件（安全权限）
COPY --from=secure-builder --chown=1001:1001 /app/.next/standalone ./
COPY --from=secure-builder --chown=1001:1001 /app/.next/static ./.next/static
COPY --from=secure-builder --chown=1001:1001 /app/public ./public
COPY --from=secure-builder --chown=1001:1001 /app/config.json ./config.json
COPY --from=secure-builder --chown=1001:1001 /app/scripts ./scripts
COPY --from=secure-builder --chown=1001:1001 /app/start.js ./start.js

# 非特权用户运行
USER 1001:1001

# 增强健康检查（包含安全检查）
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD node --eval "
    const http = require('http');
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/health',
      method: 'GET',
      timeout: 5000
    };
    const req = http.request(options, (res) => {
      process.exit(res.statusCode === 200 ? 0 : 1);
    });
    req.on('error', () => process.exit(1));
    req.on('timeout', () => process.exit(1));
    req.end();
  "

# 暴露端口
EXPOSE 3000

# 安全启动（使用dumb-init）
ENTRYPOINT ["/bin/dumb-init", "--"]
CMD ["node", "start.js"]

# 安全标签
LABEL security.scan.enabled="true" \
      security.level="enterprise" \
      maintainer="MoonTV Security Team" \
      version="4.0.0" \
      description="MoonTV Enterprise Security Build"
```

### 2. 容器运行时安全配置

#### Docker Compose 安全配置

```yaml
# docker-compose.security.yml
version: '3.8'

services:
  moontv-secure:
    build:
      context: .
      dockerfile: Dockerfile
      target: secure-runner
    image: moontv:enterprise-v4.0.0
    container_name: moontv-secure

    # 网络安全配置
    networks:
      - moontv-secure-net

    # 安全端口映射（仅内部访问）
    ports:
      - '127.0.0.1:3000:3000' # 仅本地访问

    # 安全环境变量
    environment:
      - NODE_ENV=production
      - DOCKER_ENV=true
      - PASSWORD=${MOONTV_PASSWORD}
      - NEXT_PUBLIC_STORAGE_TYPE=redis
      - REDIS_URL=redis://redis-secure:6379
      # 安全配置
      - COOKIE_SECURE=true
      - COOKIE_HTTP_ONLY=true
      - SESSION_TIMEOUT=3600
      - RATE_LIMIT_WINDOW=900000 # 15分钟
      - RATE_LIMIT_MAX=100 # 最大请求数
      - LOG_LEVEL=warn

    # 安全卷挂载
    volumes:
      - moontv-secure-data:/app/data:rw
      - moontv-secure-logs:/app/logs:rw
      - ./config/security.json:/app/config/security.json:ro

    # 安全资源限制
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 256M

    # 安全重启策略
    restart: unless-stopped

    # 安全用户配置
    user: '1001:1001'

    # 安全文件系统
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
      - /var/run:noexec,nosuid,size=100m

    # 安全能力控制
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETGID
      - SETUID

    # 安全选项
    security_opt:
      - no-new-privileges:true
      - apparmor:docker-default
      - seccomp:default

    # 健康检查
    healthcheck:
      test:
        [
          'CMD',
          'node',
          '--eval',
          "require('http').get('http://localhost:3000/api/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => process.exit(1))",
        ]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

    # 依赖服务
    depends_on:
      redis-secure:
        condition: service_healthy

  redis-secure:
    image: redis:7-alpine
    container_name: redis-secure
    networks:
      - moontv-secure-net

    # Redis安全配置
    command: >
      redis-server
      --requirepass ${REDIS_PASSWORD}
      --appendonly yes
      --save 900 1
      --save 300 10
      --save 60 10000
      --maxmemory 256mb
      --maxmemory-policy allkeys-lru
      --timeout 300
      --tcp-keepalive 60
      --loglevel warning

    # 安全卷挂载
    volumes:
      - redis-secure-data:/data:rw
      - redis-secure-conf:/usr/local/etc/redis:ro

    # 安全资源限制
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M

    # 安全用户配置
    user: '999:999'

    # 安全配置
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=50m

    # 安全重启策略
    restart: unless-stopped

    # 健康检查
    healthcheck:
      test: ['CMD', 'redis-cli', '--raw', 'incr', 'ping']
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 30s

  # 安全监控服务
  security-scanner:
    image: aquasec/trivy:latest
    container_name: moontv-security-scanner
    networks:
      - moontv-secure-net

    # 安全扫描配置
    command: >
      image --exit-code 1 --severity HIGH,CRITICAL
      --format json --output /reports/scan-report.json
      moontv:enterprise-v4.0.0

    volumes:
      - ./reports:/reports:rw
      - /var/run/docker.sock:/var/run/docker.sock:ro

    # 扫描调度
    profiles:
      - security-scan

# 安全网络配置
networks:
  moontv-secure-net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
    options:
      com.docker.network.bridge.enable_icc: 'false'
      com.docker.network.bridge.enable_ip_masquerade: 'true'
      com.docker.network.driver.mtu: 1500

# 安全卷配置
volumes:
  moontv-secure-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./data/secure
  moontv-secure-logs:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./logs/secure
  redis-secure-data:
    driver: local
  redis-secure-conf:
    driver: local
```

### 3. 容器安全扫描配置

#### Trivy 安全扫描配置

```yaml
# .trivy.yml
# Trivy 安全扫描配置文件

format: table
exit-code: 1
severity:
  - UNKNOWN
  - LOW
  - MEDIUM
  - HIGH
  - CRITICAL
ignore-unfixed: false
skip-dirs:
  - vendor
  - tests
  - docs
skip-files:
  - '**/*.md'
  - '**/*.txt'
cache-dir: .trivycache
timeout: 10m
slow: true
list-all-pkgs: true
security-checks:
  - vuln
  - config
  - secret
scanners:
  - vuln
  - misconfig
  - exposed
  - secret
  - license
```

#### 自动化安全扫描脚本

```bash
#!/bin/bash
# scripts/security-scan.sh

set -euo pipefail

# 配置
IMAGE_NAME="moontv:enterprise-v4.0.0"
REPORT_DIR="./reports"
SCAN_DATE=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/security-scan-${SCAN_DATE}.json"

# 创建报告目录
mkdir -p "${REPORT_DIR}"

echo "🔍 开始安全扫描..."

# 1. 镜像漏洞扫描
echo "📋 执行镜像漏洞扫描..."
trivy image \
  --format json \
  --output "${REPORT_FILE}" \
  --severity HIGH,CRITICAL \
  --exit-code 0 \
  "${IMAGE_NAME}"

# 2. 配置安全扫描
echo "⚙️ 执行配置安全扫描..."
trivy config \
  --format json \
  --output "${REPORT_DIR}/config-scan-${SCAN_DATE}.json" \
  --exit-code 0 \
  .

# 3. 依赖安全扫描
echo "📦 执行依赖安全扫描..."
trivy fs \
  --format json \
  --output "${REPORT_DIR}/fs-scan-${SCAN_DATE}.json" \
  --exit-code 0 \
  --severity HIGH,CRITICAL \
  .

# 4. 生成安全报告摘要
echo "📊 生成安全报告摘要..."
node scripts/generate-security-report.js "${REPORT_FILE}" "${REPORT_DIR}"

# 5. 检查关键漏洞
echo "🚨 检查关键漏洞..."
CRITICAL_COUNT=$(jq -r '.Results[]? | .Vulnerabilities[]? | select(.Severity == "CRITICAL") | .VulnerabilityID' "${REPORT_FILE}" | wc -l)
HIGH_COUNT=$(jq -r '.Results[]? | .Vulnerabilities[]? | select(.Severity == "HIGH") | .VulnerabilityID' "${REPORT_FILE}" | wc -l)

if [ "${CRITICAL_COUNT}" -gt 0 ] || [ "${HIGH_COUNT}" -gt 0 ]; then
  echo "❌ 发现 ${CRITICAL_COUNT} 个关键漏洞和 ${HIGH_COUNT} 个高危漏洞"
  echo "📄 详细报告: ${REPORT_FILE}"
  exit 1
else
  echo "✅ 安全扫描通过"
  echo "📄 报告文件: ${REPORT_FILE}"
fi
```

---

## API 安全认证和授权

### 1. 增强版认证中间件

基于现有的 middleware.ts，添加更多安全特性：

```typescript
// src/middleware.enhanced.ts
import { NextRequest, NextResponse } from 'next/server';
import { getAuthInfoFromCookie } from '@/lib/auth';
import { rateLimiter } from '@/lib/rate-limiter';
import { auditLogger } from '@/lib/audit-logger';
import { securityHeaders } from '@/lib/security-headers';

// 安全配置
const SECURITY_CONFIG = {
  MAX_LOGIN_ATTEMPTS: 5,
  LOGIN_COOLDOWN: 15 * 60 * 1000, // 15分钟
  SESSION_TIMEOUT: 60 * 60 * 1000, // 1小时
  IP_BLACKLIST_DURATION: 24 * 60 * 60 * 1000, // 24小时
  RATE_LIMIT_WINDOW: 15 * 60 * 1000, // 15分钟
  RATE_LIMIT_MAX: 100, // 最大请求数
};

// 内存存储（生产环境应使用Redis）
const loginAttempts = new Map<string, { count: number; lastAttempt: number }>();
const ipBlacklist = new Map<string, { blockedUntil: number; reason: string }>();

export async function enhancedMiddleware(request: NextRequest) {
  const { pathname, searchParams } = request.nextUrl;
  const clientIP = getClientIP(request);
  const userAgent = request.headers.get('user-agent') || '';

  try {
    // 1. IP黑名单检查
    if (await isIPBlacklisted(clientIP)) {
      await auditLogger.log('SECURITY_VIOLATION', {
        ip: clientIP,
        userAgent,
        path: pathname,
        reason: 'IP_BLACKLISTED',
      });
      return new NextResponse('Access Denied', {
        status: 403,
        headers: securityHeaders.getSecurityHeaders(),
      });
    }

    // 2. 速率限制检查
    if (await isRateLimited(clientIP, pathname)) {
      await auditLogger.log('RATE_LIMIT_EXCEEDED', {
        ip: clientIP,
        userAgent,
        path: pathname,
      });
      return new NextResponse('Too Many Requests', {
        status: 429,
        headers: {
          ...securityHeaders.getSecurityHeaders(),
          'Retry-After': '60',
        },
      });
    }

    // 3. 跳过认证路径检查
    if (shouldSkipAuth(pathname)) {
      const response = NextResponse.next();
      securityHeaders.addSecurityHeaders(response);
      return response;
    }

    // 4. 认证检查
    const authResult = await authenticateRequest(request, clientIP, userAgent);
    if (!authResult.success) {
      return authResult.response;
    }

    // 5. 会话安全检查
    const sessionValid = await validateSession(request);
    if (!sessionValid) {
      return handleSessionExpired(request);
    }

    // 6. 权限检查
    if (await hasRequiredPermissions(request, authResult.user)) {
      const response = NextResponse.next();
      securityHeaders.addSecurityHeaders(response);

      // 7. 记录访问日志
      await auditLogger.log('ACCESS_GRANTED', {
        ip: clientIP,
        userAgent,
        path: pathname,
        user: authResult.user?.username,
        timestamp: Date.now(),
      });

      return response;
    } else {
      await auditLogger.log('ACCESS_DENIED', {
        ip: clientIP,
        userAgent,
        path: pathname,
        user: authResult.user?.username,
        reason: 'INSUFFICIENT_PERMISSIONS',
      });

      return new NextResponse('Forbidden', {
        status: 403,
        headers: securityHeaders.getSecurityHeaders(),
      });
    }
  } catch (error) {
    console.error('Enhanced middleware error:', error);
    await auditLogger.log('MIDDLEWARE_ERROR', {
      ip: clientIP,
      userAgent,
      path: pathname,
      error: error.message,
    });

    return new NextResponse('Internal Server Error', {
      status: 500,
      headers: securityHeaders.getSecurityHeaders(),
    });
  }
}

// 获取客户端IP
function getClientIP(request: NextRequest): string {
  const forwarded = request.headers.get('x-forwarded-for');
  const realIP = request.headers.get('x-real-ip');
  const clientIP = request.ip;

  if (forwarded) {
    return forwarded.split(',')[0].trim();
  }
  if (realIP) {
    return realIP;
  }
  return clientIP || 'unknown';
}

// IP黑名单检查
async function isIPBlacklisted(ip: string): Promise<boolean> {
  const blacklistEntry = ipBlacklist.get(ip);
  if (!blacklistEntry) return false;

  if (Date.now() > blacklistEntry.blockedUntil) {
    ipBlacklist.delete(ip);
    return false;
  }

  return true;
}

// 速率限制检查
async function isRateLimited(ip: string, path: string): Promise<boolean> {
  const key = `rate_limit:${ip}:${path}`;
  const allowed = await rateLimiter.isAllowed(key, {
    windowMs: SECURITY_CONFIG.RATE_LIMIT_WINDOW,
    max: SECURITY_CONFIG.RATE_LIMIT_MAX,
  });

  return !allowed;
}

// 增强认证请求处理
async function authenticateRequest(
  request: NextRequest,
  clientIP: string,
  userAgent: string
): Promise<{ success: boolean; user?: any; response?: NextResponse }> {
  const { pathname } = request.nextUrl;
  const storageType = process.env.NEXT_PUBLIC_STORAGE_TYPE || 'localstorage';

  // 检查密码配置
  if (!process.env.PASSWORD) {
    return {
      success: false,
      response: new NextResponse('Security Configuration Error', {
        status: 500,
      }),
    };
  }

  // 从cookie获取认证信息
  const authInfo = getAuthInfoFromCookie(request);
  if (!authInfo) {
    return handleAuthFailure(
      request,
      pathname,
      clientIP,
      userAgent,
      'MISSING_AUTH'
    );
  }

  // 登录尝试检查
  const attemptKey = `${clientIP}:${authInfo.username || 'anonymous'}`;
  if (loginAttempts.has(attemptKey)) {
    const attempt = loginAttempts.get(attemptKey)!;
    const timeSinceLastAttempt = Date.now() - attempt.lastAttempt;

    if (
      attempt.count >= SECURITY_CONFIG.MAX_LOGIN_ATTEMPTS &&
      timeSinceLastAttempt < SECURITY_CONFIG.LOGIN_COOLDOWN
    ) {
      return {
        success: false,
        response: new NextResponse('Too Many Login Attempts', { status: 429 }),
      };
    }
  }

  // 验证逻辑
  let isValid = false;

  if (storageType === 'localstorage') {
    isValid = authInfo.password === process.env.PASSWORD;
  } else {
    if (authInfo.username && authInfo.signature) {
      isValid = await verifySignature(
        authInfo.username,
        authInfo.signature,
        process.env.PASSWORD || ''
      );
    }
  }

  if (isValid) {
    // 清除登录尝试记录
    loginAttempts.delete(attemptKey);
    return { success: true, user: authInfo };
  } else {
    // 记录失败尝试
    const attempt = loginAttempts.get(attemptKey) || {
      count: 0,
      lastAttempt: 0,
    };
    attempt.count++;
    attempt.lastAttempt = Date.now();
    loginAttempts.set(attemptKey, attempt);

    // 检查是否需要加入黑名单
    if (attempt.count >= SECURITY_CONFIG.MAX_LOGIN_ATTEMPTS) {
      ipBlacklist.set(clientIP, {
        blockedUntil: Date.now() + SECURITY_CONFIG.IP_BLACKLIST_DURATION,
        reason: 'EXCESSIVE_LOGIN_ATTEMPTS',
      });
    }

    return handleAuthFailure(
      request,
      pathname,
      clientIP,
      userAgent,
      'INVALID_CREDENTIALS'
    );
  }
}

// 处理认证失败
function handleAuthFailure(
  request: NextRequest,
  pathname: string,
  clientIP: string,
  userAgent: string,
  reason: string
): { success: false; response: NextResponse } {
  // 记录安全事件
  auditLogger.log('AUTHENTICATION_FAILED', {
    ip: clientIP,
    userAgent,
    path: pathname,
    reason,
    timestamp: Date.now(),
  });

  // API路由返回401
  if (pathname.startsWith('/api')) {
    return {
      success: false,
      response: new NextResponse('Unauthorized', {
        status: 401,
        headers: securityHeaders.getSecurityHeaders(),
      }),
    };
  }

  // 页面重定向到登录
  const loginUrl = new URL('/login', request.url);
  const fullUrl = `${pathname}${request.nextUrl.search}`;
  loginUrl.searchParams.set('redirect', fullUrl);
  loginUrl.searchParams.set('error', reason);

  return {
    success: false,
    response: NextResponse.redirect(loginUrl),
  };
}

// 会话验证
async function validateSession(request: NextRequest): Promise<boolean> {
  const authInfo = getAuthInfoFromCookie(request);
  if (!authInfo || !authInfo.timestamp) return false;

  const sessionAge = Date.now() - authInfo.timestamp;
  return sessionAge < SECURITY_CONFIG.SESSION_TIMEOUT;
}

// 处理会话过期
function handleSessionExpired(request: NextRequest): NextResponse {
  const loginUrl = new URL('/login', request.url);
  loginUrl.searchParams.set('error', 'SESSION_EXPIRED');
  loginUrl.searchParams.set(
    'redirect',
    request.nextUrl.pathname + request.nextUrl.search
  );

  const response = NextResponse.redirect(loginUrl);
  response.cookies.delete('auth');

  return response;
}

// 权限检查
async function hasRequiredPermissions(
  request: NextRequest,
  user: any
): Promise<boolean> {
  const { pathname } = request.nextUrl;

  // 管理员路径权限检查
  if (pathname.startsWith('/admin') || pathname.startsWith('/api/admin')) {
    return user.role === 'owner' || user.role === 'admin';
  }

  // 用户API路径权限检查
  if (
    pathname.startsWith('/api/favorites') ||
    pathname.startsWith('/api/playrecords') ||
    pathname.startsWith('/api/searchhistory')
  ) {
    return !!user.username;
  }

  return true;
}

// 跳过认证的路径
function shouldSkipAuth(pathname: string): boolean {
  const skipPaths = [
    '/_next',
    '/favicon.ico',
    '/robots.txt',
    '/manifest.json',
    '/icons/',
    '/logo.png',
    '/screenshot.png',
    '/api/health',
    '/api/login',
    '/api/logout',
    '/api/register',
    '/login',
    '/warning',
  ];

  return skipPaths.some((path) => pathname.startsWith(path));
}

// 增强签名验证
async function verifySignature(
  data: string,
  signature: string,
  secret: string
): Promise<boolean> {
  const encoder = new TextEncoder();
  const keyData = encoder.encode(secret);
  const messageData = encoder.encode(data);

  try {
    const key = await crypto.subtle.importKey(
      'raw',
      keyData,
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['verify']
    );

    const signatureBuffer = new Uint8Array(
      signature.match(/.{1,2}/g)?.map((byte) => parseInt(byte, 16)) || []
    );

    return await crypto.subtle.verify(
      'HMAC',
      key,
      signatureBuffer,
      messageData
    );
  } catch (error) {
    console.error('签名验证失败:', error);
    return false;
  }
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|login|warning|api/login|api/register|api/logout|api/cron|api/server-config|api/tvbox/config|api/tvbox/categories|api/douban/recommends|api/admin/tvbox|api/health).*)',
  ],
};
```

### 2. 速率限制实现

```typescript
// src/lib/rate-limiter.ts
interface RateLimitOptions {
  windowMs: number;
  max: number;
  message?: string;
  standardHeaders?: boolean;
  legacyHeaders?: boolean;
}

interface RateLimitResult {
  success: boolean;
  limit: number;
  current: number;
  remaining: number;
  resetTime: number;
}

class RateLimiter {
  private store: Map<string, { count: number; resetTime: number }> = new Map();

  async isAllowed(key: string, options: RateLimitOptions): Promise<boolean> {
    const now = Date.now();
    const windowMs = options.windowMs;
    const max = options.max;

    // 获取或创建记录
    let record = this.store.get(key);

    if (!record || now > record.resetTime) {
      // 新窗口期
      record = {
        count: 1,
        resetTime: now + windowMs,
      };
      this.store.set(key, record);
      return true;
    }

    // 检查是否超过限制
    if (record.count >= max) {
      return false;
    }

    // 增加计数
    record.count++;
    return true;
  }

  async getLimitStatus(
    key: string,
    options: RateLimitOptions
  ): Promise<RateLimitResult> {
    const now = Date.now();
    const record = this.store.get(key);

    if (!record || now > record.resetTime) {
      return {
        success: true,
        limit: options.max,
        current: 0,
        remaining: options.max,
        resetTime: now + options.windowMs,
      };
    }

    return {
      success: record.count < options.max,
      limit: options.max,
      current: record.count,
      remaining: Math.max(0, options.max - record.count),
      resetTime: record.resetTime,
    };
  }

  // 清理过期记录
  cleanup(): void {
    const now = Date.now();
    for (const [key, record] of this.store.entries()) {
      if (now > record.resetTime) {
        this.store.delete(key);
      }
    }
  }
}

export const rateLimiter = new RateLimiter();

// 定期清理
setInterval(() => rateLimiter.cleanup(), 5 * 60 * 1000); // 5分钟清理一次
```

### 3. 审计日志系统

```typescript
// src/lib/audit-logger.ts
interface AuditLogEntry {
  timestamp: number;
  level: 'INFO' | 'WARN' | 'ERROR' | 'CRITICAL';
  event: string;
  ip: string;
  userAgent?: string;
  user?: string;
  path?: string;
  reason?: string;
  details?: any;
}

class AuditLogger {
  private logs: AuditLogEntry[] = [];
  private maxLogSize = 10000; // 内存中最多保存1万条日志

  async log(
    level: AuditLogEntry['level'],
    data: Partial<AuditLogEntry>
  ): Promise<void> {
    const entry: AuditLogEntry = {
      timestamp: Date.now(),
      level,
      event: data.event || 'UNKNOWN',
      ip: data.ip || 'unknown',
      userAgent: data.userAgent,
      user: data.user,
      path: data.path,
      reason: data.reason,
      details: data.details,
    };

    // 添加到内存
    this.logs.push(entry);

    // 限制内存大小
    if (this.logs.length > this.maxLogSize) {
      this.logs = this.logs.slice(-this.maxLogSize);
    }

    // 输出到控制台（生产环境应写入文件或发送到日志服务）
    this.outputLog(entry);

    // 关键事件立即告警
    if (level === 'CRITICAL') {
      await this.sendAlert(entry);
    }
  }

  private outputLog(entry: AuditLogEntry): void {
    const logMessage = `[${new Date(entry.timestamp).toISOString()}] ${
      entry.level
    } ${entry.event} - IP: ${entry.ip}${
      entry.user ? ` User: ${entry.user}` : ''
    }${entry.reason ? ` Reason: ${entry.reason}` : ''}`;

    switch (entry.level) {
      case 'ERROR':
      case 'CRITICAL':
        console.error(logMessage, entry.details);
        break;
      case 'WARN':
        console.warn(logMessage, entry.details);
        break;
      default:
        console.log(logMessage, entry.details);
    }
  }

  private async sendAlert(entry: AuditLogEntry): Promise<void> {
    // 发送告警（可集成邮件、Slack、钉钉等）
    try {
      // 示例：发送到Webhook
      if (process.env.SECURITY_WEBHOOK_URL) {
        await fetch(process.env.SECURITY_WEBHOOK_URL, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            text: `🚨 安全告警: ${entry.event}`,
            attachments: [
              {
                fields: [
                  {
                    title: '时间',
                    value: new Date(entry.timestamp).toLocaleString(),
                    short: true,
                  },
                  { title: 'IP', value: entry.ip, short: true },
                  { title: '用户', value: entry.user || '未知', short: true },
                  { title: '路径', value: entry.path || '未知', short: true },
                  {
                    title: '原因',
                    value: entry.reason || '未知',
                    short: false,
                  },
                ],
              },
            ],
          }),
        });
      }
    } catch (error) {
      console.error('发送安全告警失败:', error);
    }
  }

  async getLogs(filter?: {
    level?: AuditLogEntry['level'];
    since?: number;
    ip?: string;
    user?: string;
    limit?: number;
  }): Promise<AuditLogEntry[]> {
    let filtered = this.logs;

    if (filter) {
      if (filter.level) {
        filtered = filtered.filter((log) => log.level === filter.level);
      }
      if (filter.since) {
        filtered = filtered.filter((log) => log.timestamp >= filter.since);
      }
      if (filter.ip) {
        filtered = filtered.filter((log) => log.ip === filter.ip);
      }
      if (filter.user) {
        filtered = filtered.filter((log) => log.user === filter.user);
      }
      if (filter.limit) {
        filtered = filtered.slice(-filter.limit);
      }
    }

    return filtered.reverse(); // 最新的在前
  }

  async exportLogs(format: 'json' | 'csv' = 'json'): Promise<string> {
    const logs = await this.getLogs();

    if (format === 'csv') {
      const headers = [
        'timestamp',
        'level',
        'event',
        'ip',
        'user',
        'path',
        'reason',
      ];
      const csvRows = [
        headers.join(','),
        ...logs.map((log) =>
          [
            new Date(log.timestamp).toISOString(),
            log.level,
            log.event,
            log.ip,
            log.user || '',
            log.path || '',
            log.reason || '',
          ]
            .map((field) => `"${field}"`)
            .join(',')
        ),
      ];
      return csvRows.join('\n');
    }

    return JSON.stringify(logs, null, 2);
  }
}

export const auditLogger = new AuditLogger();
```

### 4. 安全头配置

```typescript
// src/lib/security-headers.ts
class SecurityHeaders {
  private securityHeaders = {
    // 内容安全策略
    'Content-Security-Policy': [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net",
      "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
      "font-src 'self' https://fonts.gstatic.com",
      "img-src 'self' data: https: blob:",
      "media-src 'self' blob: https:",
      "connect-src 'self' https: wss:",
      "frame-src 'none'",
      "object-src 'none'",
      "base-uri 'self'",
      "form-action 'self'",
      'upgrade-insecure-requests',
    ].join('; '),

    // 严格传输安全
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',

    // XSS保护
    'X-XSS-Protection': '1; mode=block',

    // 内容类型选项
    'X-Content-Type-Options': 'nosniff',

    // 点击劫持保护
    'X-Frame-Options': 'DENY',

    // 引用策略
    'Referrer-Policy': 'strict-origin-when-cross-origin',

    // 权限策略
    'Permissions-Policy': [
      'camera=()',
      'microphone=()',
      'geolocation=()',
      'payment=()',
      'usb=()',
      'interest-cohort=()',
    ].join(', '),

    // 缓存控制
    'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
    Pragma: 'no-cache',
    Expires: '0',

    // 自定义安全头
    'X-Security-Level': 'Enterprise',
    'X-Protection': 'Active',
  };

  getSecurityHeaders(): Record<string, string> {
    return { ...this.securityHeaders };
  }

  addSecurityHeaders(response: NextResponse): void {
    Object.entries(this.securityHeaders).forEach(([key, value]) => {
      response.headers.set(key, value);
    });
  }

  // 根据环境调整安全头
  getSecurityHeadersForEnvironment(
    env: 'development' | 'production'
  ): Record<string, string> {
    const headers = { ...this.securityHeaders };

    if (env === 'development') {
      // 开发环境放宽一些限制
      headers['Content-Security-Policy'] = headers[
        'Content-Security-Policy'
      ].replace(
        "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net",
        "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net ws:"
      );
      delete headers['Strict-Transport-Security'];
    }

    return headers;
  }
}

export const securityHeaders = new SecurityHeaders();
```

---
