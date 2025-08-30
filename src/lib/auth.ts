import { NextRequest } from 'next/server';

// 从cookie获取认证信息 (服务端使用)
// 从cookie获取认证信息 (服务端使用)
export function getAuthInfoFromCookie(request: NextRequest): {
  password?: string;
  username?: string;
  signature?: string;
  timestamp?: number;
} | null {
  const authCookie = request.cookies.get('auth');

  if (!authCookie) {
    return null;
  }

  try {
    const decoded = decodeURIComponent(authCookie.value);
    const authData = JSON.parse(decoded);
    
    // 验证时间戳，防止重放攻击 (30天有效期，与cookie过期时间保持一致)
    if (authData.timestamp && Date.now() - authData.timestamp > 2592000000) {
      return null;
    }
    
    return authData;
  } catch (error) {
    return null;
  }
}

// 从cookie获取认证信息 (客户端使用)
// 从cookie获取认证信息 (客户端使用)
export function getAuthInfoFromBrowserCookie(): {
  password?: string;
  username?: string;
  signature?: string;
  timestamp?: number;
  role?: 'owner' | 'admin' | 'user';
} | null {
  if (typeof window === 'undefined') {
    return null;
  }

  try {
    // 解析 document.cookie
    const cookies = document.cookie.split(';').reduce((acc, cookie) => {
      const trimmed = cookie.trim();
      const firstEqualIndex = trimmed.indexOf('=');

      if (firstEqualIndex > 0) {
        const key = trimmed.substring(0, firstEqualIndex);
        const value = trimmed.substring(firstEqualIndex + 1);
        if (key && value) {
          acc[key] = value;
        }
      }

      return acc;
    }, {} as Record<string, string>);

    const authCookie = cookies['auth'];
    if (!authCookie) {
      return null;
    }

    // 处理可能的双重编码
    let decoded = decodeURIComponent(authCookie);

    // 如果解码后仍然包含 %，说明是双重编码，需要再次解码
    if (decoded.includes('%')) {
      decoded = decodeURIComponent(decoded);
    }

    const authData = JSON.parse(decoded);
    
    // 验证时间戳，防止重放攻击 (30天有效期，与cookie过期时间保持一致)
    if (authData.timestamp && Date.now() - authData.timestamp > 2592000000) {
      return null;
    }
    
    return authData;
  } catch (error) {
    return null;
  }
}

/**
 * 创建安全的认证Cookie
 * @param authData 认证数据
 * @returns 安全的Set-Cookie头值
 */
export function createSecureAuthCookie(authData: {
  username: string;
  signature?: string;
  timestamp?: number;
  role?: 'owner' | 'admin' | 'user';
}): string {
  // 添加时间戳防止重放攻击
  const secureAuthData = {
    ...authData,
    timestamp: Date.now(),
  };

  const encodedValue = encodeURIComponent(JSON.stringify(secureAuthData));
  
  const isProduction = process.env.NODE_ENV === 'production';
  
  return `auth=${encodedValue}; Path=/; ${isProduction ? 'Secure; ' : ''}HttpOnly; SameSite=strict; Max-Age=2592000`;
}

/**
 * 验证签名的时间窗口（防止重放攻击）
 * @param timestamp 时间戳
 * @param maxAge 最大有效期（毫秒，默认5分钟）
 * @returns 是否在有效期内
 */
export function validateSignatureTimestamp(timestamp: number, maxAge = 2592000000): boolean {
  return Date.now() - timestamp <= maxAge;
}

/**
 * 删除认证Cookie
 * @returns 用于删除Cookie的Set-Cookie头值
 */
export function deleteAuthCookie(): string {
  const isProduction = process.env.NODE_ENV === 'production';
  return `auth=; Path=/; ${isProduction ? 'Secure; ' : ''}HttpOnly; SameSite=strict; Max-Age=0`;
}
