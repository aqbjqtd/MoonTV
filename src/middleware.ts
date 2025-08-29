import { NextRequest, NextResponse } from 'next/server';

import { getAuthInfoFromCookie } from '@/lib/auth';
import { getSafeEnv } from '@/lib/env';
import { createModuleLogger } from '@/lib/logger';
import { logRequest, logResponse } from '@/lib/request-logger';

const middlewareLogger = createModuleLogger('middleware');

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const metrics = logRequest(request);

  // 跳过不需要认证的路径
  if (shouldSkipAuth(pathname)) {
    const response = NextResponse.next();
    logResponse(metrics, response);
    return response;
  }

  // 使用验证后的环境变量
  const env = getSafeEnv();
  const storageType = env.NEXT_PUBLIC_STORAGE_TYPE;
  
  if (!env.PASSWORD) {
    middlewareLogger.warn('No password configured, redirecting to warning', {
      path: pathname,
      ip: request.ip || request.headers.get('x-forwarded-for'),
    });
    // 如果没有设置密码，重定向到警告页面
    const warningUrl = new URL('/warning', request.url);
    const response = NextResponse.redirect(warningUrl);
    logResponse(metrics, response);
    return response;
  }

  // 从cookie获取认证信息
  const authInfo = getAuthInfoFromCookie(request);

  if (!authInfo) {
    middlewareLogger.warn('No auth info found', {
      path: pathname,
      ip: request.ip || request.headers.get('x-forwarded-for'),
    });
    const response = handleAuthFailure(request, pathname);
    logResponse(metrics, response);
    return response;
  }

  // localstorage模式：在middleware中完成验证
  if (storageType === 'localstorage') {
    if (!authInfo.password || authInfo.password !== env.PASSWORD) {
      middlewareLogger.warn('Invalid password in localStorage mode', {
        path: pathname,
        username: authInfo.username,
        ip: request.ip || request.headers.get('x-forwarded-for'),
      });
      const response = handleAuthFailure(request, pathname);
      logResponse(metrics, response);
      return response;
    }
    const response = NextResponse.next();
    logResponse(metrics, response);
    return response;
  }

  // 其他模式：只验证签名
  // 检查是否有用户名（非localStorage模式下密码不存储在cookie中）
  if (!authInfo.username || !authInfo.signature) {
    middlewareLogger.warn('Missing username or signature', {
      path: pathname,
      hasUsername: !!authInfo.username,
      hasSignature: !!authInfo.signature,
      ip: request.ip || request.headers.get('x-forwarded-for'),
    });
    const response = handleAuthFailure(request, pathname);
    logResponse(metrics, response);
    return response;
  }

  // 验证签名（如果存在）
  if (authInfo.signature) {
    const isValidSignature = await verifySignature(
      authInfo.username,
      authInfo.signature,
      env.PASSWORD || ''
    );

    // 签名验证通过即可
    if (isValidSignature) {
      middlewareLogger.debug('Signature verification successful', {
        path: pathname,
        username: authInfo.username,
      });
      const response = NextResponse.next();
      logResponse(metrics, response);
      return response;
    }
  }

  // 签名验证失败或不存在签名
  middlewareLogger.warn('Signature verification failed', {
    path: pathname,
    username: authInfo.username,
    ip: request.ip || request.headers.get('x-forwarded-for'),
  });
  const response = handleAuthFailure(request, pathname);
  logResponse(metrics, response);
  return response;
}

// 验证签名
async function verifySignature(
  data: string,
  signature: string,
  secret: string
): Promise<boolean> {
  const encoder = new TextEncoder();
  const keyData = encoder.encode(secret);
  const messageData = encoder.encode(data);

  try {
    // 导入密钥
    const key = await crypto.subtle.importKey(
      'raw',
      keyData,
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['verify']
    );

    // 将十六进制字符串转换为Uint8Array
    const signatureBuffer = new Uint8Array(
      signature.match(/.{1,2}/g)?.map((byte) => parseInt(byte, 16)) || []
    );

    // 验证签名
    return await crypto.subtle.verify(
      'HMAC',
      key,
      signatureBuffer,
      messageData
    );
  } catch (error) {
    middlewareLogger.error('Signature verification error', error as Error, {
      data: data.slice(0, 10) + '...',
    });
    return false;
  }
}

// 处理认证失败的情况
function handleAuthFailure(
  request: NextRequest,
  pathname: string
): NextResponse {
  // 如果是 API 路由，返回 401 状态码
  if (pathname.startsWith('/api')) {
    return new NextResponse('Unauthorized', { status: 401 });
  }

  // 否则重定向到登录页面
  const loginUrl = new URL('/login', request.url);
  // 保留完整的URL，包括查询参数
  const fullUrl = `${pathname}${request.nextUrl.search}`;
  loginUrl.searchParams.set('redirect', fullUrl);
  return NextResponse.redirect(loginUrl);
}

// 判断是否需要跳过认证的路径
function shouldSkipAuth(pathname: string): boolean {
  const skipPaths = [
    '/_next',
    '/favicon.ico',
    '/robots.txt',
    '/manifest.json',
    '/icons/',
    '/logo.png',
    '/screenshot.png',
  ];

  return skipPaths.some((path) => pathname.startsWith(path));
}

// 配置middleware匹配规则
export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|login|warning|api/login|api/register|api/logout|api/cron|api/server-config|api/health).*)',
  ],
};
