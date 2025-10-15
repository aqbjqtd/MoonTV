/**
 * 安全中间件
 * 为API路由提供安全保护
 */

import { NextRequest, NextResponse } from 'next/server';
import {
  SecurityMiddleware,
  checkRateLimit,
  RATE_LIMIT_CONFIGS,
  SecurityLogger,
  SECURITY_HEADERS,
} from './security';

// 安全配置
const SECURITY_CONFIG = {
  // 允许的来源（开发环境可以宽松一些）
  allowedOrigins: [
    'http://localhost:3000',
    'http://localhost:3001',
    'https://yourdomain.com', // 生产环境替换为实际域名
  ],

  // 最大请求大小 (10MB)
  maxRequestSize: 10 * 1024 * 1024,

  // 是否启用严格模式（生产环境建议启用）
  strictMode: process.env.NODE_ENV === 'production',
};

// 请求标识符生成
function generateRequestId(): string {
  return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
}

// 获取客户端标识符
function getClientIdentifier(request: NextRequest): string {
  // 优先使用IP地址
  const forwardedFor = request.headers.get('x-forwarded-for');
  const realIp = request.headers.get('x-real-ip');
  const ip = forwardedFor?.split(',')[0] || realIp || 'unknown';

  // 组合IP和User-Agent作为唯一标识
  const userAgent = request.headers.get('user-agent') || 'unknown';
  return `${ip}:${Buffer.from(userAgent).toString('base64').substr(0, 16)}`;
}

// 主要安全中间件
export async function securityMiddleware(
  request: NextRequest,
  options: {
    rateLimitKey?: string;
    skipRateLimit?: boolean;
    skipOriginCheck?: boolean;
  } = {},
): Promise<NextResponse | null> {
  const requestId = generateRequestId();
  const startTime = Date.now();

  try {
    // 1. 检测可疑请求模式
    if (SecurityMiddleware.detectSuspiciousPatterns(request)) {
      SecurityLogger.log('warning', 'Suspicious request pattern detected', {
        requestId,
        url: request.url,
        userAgent: request.headers.get('user-agent'),
      });

      return NextResponse.json({ error: 'Invalid request' }, { status: 400 });
    }

    // 2. 验证请求大小
    if (
      !SecurityMiddleware.validateRequestSize(
        request,
        SECURITY_CONFIG.maxRequestSize,
      )
    ) {
      SecurityLogger.log('warning', 'Request size exceeded', {
        requestId,
        contentLength: request.headers.get('content-length'),
      });

      return NextResponse.json({ error: 'Request too large' }, { status: 413 });
    }

    // 3. 验证请求来源（仅在严格模式下）
    if (SECURITY_CONFIG.strictMode && !options.skipOriginCheck) {
      if (
        !SecurityMiddleware.validateOrigin(
          request,
          SECURITY_CONFIG.allowedOrigins,
        )
      ) {
        SecurityLogger.log('warning', 'Invalid origin', {
          requestId,
          origin: request.headers.get('origin'),
          referer: request.headers.get('referer'),
        });

        return NextResponse.json({ error: 'Invalid origin' }, { status: 403 });
      }
    }

    // 4. Rate limiting检查
    if (!options.skipRateLimit) {
      const rateLimitKey = options.rateLimitKey || request.nextUrl.pathname;
      const rateLimitConfig =
        RATE_LIMIT_CONFIGS[rateLimitKey] || RATE_LIMIT_CONFIGS.default;
      const clientId = getClientIdentifier(request);

      const rateLimitResult = checkRateLimit(clientId, rateLimitConfig);

      if (!rateLimitResult.allowed) {
        SecurityLogger.log('warning', 'Rate limit exceeded', {
          requestId,
          clientId,
          rateLimitKey,
        });

        const response = NextResponse.json(
          { error: rateLimitConfig.message },
          { status: 429 },
        );

        // 添加rate limiting头部
        response.headers.set(
          'X-RateLimit-Limit',
          rateLimitConfig.maxRequests.toString(),
        );
        response.headers.set('X-RateLimit-Remaining', '0');
        response.headers.set(
          'X-RateLimit-Reset',
          rateLimitResult.resetTime?.toString() || '',
        );

        return response;
      }

      // 如果允许通过，添加rate limiting信息到响应头部
      const response = NextResponse.next();
      response.headers.set(
        'X-RateLimit-Limit',
        rateLimitConfig.maxRequests.toString(),
      );
      response.headers.set(
        'X-RateLimit-Remaining',
        rateLimitResult.remaining?.toString() || '0',
      );
      response.headers.set(
        'X-RateLimit-Reset',
        rateLimitResult.resetTime?.toString() || '',
      );

      return response;
    }

    // 5. 添加安全头部
    const response = NextResponse.next();
    Object.entries(SECURITY_HEADERS).forEach(([header, value]) => {
      response.headers.set(header, value);
    });

    // 6. 添加请求ID和自定义头部
    response.headers.set('X-Request-ID', requestId);
    response.headers.set('X-Response-Time', `${Date.now() - startTime}ms`);

    SecurityLogger.log('info', 'Security check passed', {
      requestId,
      url: request.url,
      method: request.method,
    });

    return response;
  } catch (error) {
    SecurityLogger.log('error', 'Security middleware error', {
      requestId,
      error: error instanceof Error ? error.message : 'Unknown error',
    });

    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 },
    );
  }
}

// API路由包装器
export function withSecurity<T = any>(
  handler: (request: NextRequest) => Promise<NextResponse<T>>,
  options?: Parameters<typeof securityMiddleware>[1],
) {
  return async (request: NextRequest): Promise<NextResponse<T>> => {
    // 执行安全检查
    const securityResult = await securityMiddleware(request, options);

    // 如果安全中间件返回了响应（表示有安全问题），直接返回
    if (securityResult) {
      return securityResult as unknown as NextResponse<T>;
    }

    // 否则继续执行原始处理程序
    try {
      return await handler(request);
    } catch (error) {
      SecurityLogger.log('error', 'API handler error', {
        url: request.url,
        method: request.method,
        error: error instanceof Error ? error.message : 'Unknown error',
      });

      return NextResponse.json(
        { error: 'Internal server error' },
        { status: 500 },
      ) as unknown as NextResponse<T>;
    }
  };
}

// 安全头部中间件（用于页面路由）
export function addSecurityHeaders(response: NextResponse): NextResponse {
  Object.entries(SECURITY_HEADERS).forEach(([header, value]) => {
    response.headers.set(header, value);
  });

  // 添加缓存控制头部
  if (response.headers.get('cache-control')) {
    response.headers.set(
      'cache-control',
      'no-store, no-cache, must-revalidate',
    );
  }

  return response;
}

// 健康检查中间件
export function healthCheckMiddleware(request: NextRequest): NextResponse {
  const healthData = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    version: process.env.npm_package_version || 'unknown',
    environment: process.env.NODE_ENV || 'development',
  };

  return NextResponse.json(healthData, {
    status: 200,
    headers: {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'X-Health-Check': 'true',
    },
  });
}
