/* eslint-disable no-console */

/**
 * 安全Cookie配置工具
 * 提供生产环境安全的Cookie配置选项
 */

export interface SecureCookieOptions {
  /** Cookie名称 */
  name?: string;
  /** Cookie值 */
  value: string;
  /** 过期时间（秒） */
  maxAge?: number;
  /** 域名 */
  domain?: string;
  /** 路径 */
  path?: string;
  /** 是否仅HTTP访问 */
  httpOnly: boolean;
  /** 是否仅HTTPS传输 */
  secure: boolean;
  /** 同站策略 */
  sameSite: 'strict' | 'lax' | 'none';
  /** 分区状态 */
  partitioned?: boolean;
}

/**
 * 默认安全Cookie配置
 * 适用于生产环境的严格安全设置
 */
export const DEFAULT_SECURE_COOKIE_OPTIONS: Omit<SecureCookieOptions, 'name' | 'value'> = {
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'strict',
  maxAge: 3600, // 1小时
  path: '/',
};

/**
 * 认证Cookie配置
 * 用于用户认证相关的Cookie设置
 */
export const AUTH_COOKIE_OPTIONS: Omit<SecureCookieOptions, 'name' | 'value'> = {
  ...DEFAULT_SECURE_COOKIE_OPTIONS,
  maxAge: 7 * 24 * 3600, // 7天
};

/**
 * 会话Cookie配置
 * 用于临时会话数据的Cookie设置
 */
export const SESSION_COOKIE_OPTIONS: Omit<SecureCookieOptions, 'name' | 'value'> = {
  ...DEFAULT_SECURE_COOKIE_OPTIONS,
  maxAge: 1800, // 30分钟
};

/**
 * CSRF Token Cookie配置
 * 用于CSRF保护的Cookie设置
 */
export const CSRF_COOKIE_OPTIONS: Omit<SecureCookieOptions, 'name' | 'value'> = {
  ...DEFAULT_SECURE_COOKIE_OPTIONS,
  httpOnly: false, // CSRF token需要前端JavaScript访问
  sameSite: 'lax',
  maxAge: 3600, // 1小时
};

/**
 * 创建安全的Cookie字符串
 * @param options Cookie配置选项
 * @returns 格式化的Cookie字符串
 */
export function createSecureCookie(options: SecureCookieOptions): string {
  const {
    name,
    value,
    maxAge,
    domain,
    path,
    httpOnly,
    secure,
    sameSite,
    partitioned,
  } = options;

  if (!name) {
    throw new Error('Cookie名称不能为空');
  }

  const encodedValue = encodeURIComponent(value);
  let cookie = `${name}=${encodedValue}`;

  if (maxAge) {
    cookie += `; Max-Age=${maxAge}`;
  }

  if (domain) {
    cookie += `; Domain=${domain}`;
  }

  if (path) {
    cookie += `; Path=${path}`;
  }

  if (httpOnly) {
    cookie += '; HttpOnly';
  }

  if (secure) {
    cookie += '; Secure';
  }

  if (sameSite) {
    cookie += `; SameSite=${sameSite}`;
  }

  if (partitioned) {
    cookie += '; Partitioned';
  }

  return cookie;
}

/**
 * 验证Cookie值的安全性
 * @param cookieValue Cookie值
 * @returns 是否安全
 */
export function validateCookieValue(cookieValue: string): boolean {
  // 防止注入攻击的基本验证
  const unsafePatterns = [
    /[\r\n]/, // 换行符注入
    /[<>]/,   // HTML标签注入
    /['"]/,   // 引号注入
    /[&]/,    // HTML实体注入
  ];

  return !unsafePatterns.some(pattern => pattern.test(cookieValue));
}

/**
 * 安全的Cookie值编码
 * @param value 原始值
 * @returns 编码后的安全值
 */
export function encodeCookieValue(value: string): string {
  if (!validateCookieValue(value)) {
    throw new Error('Cookie值包含不安全字符');
  }
  
  return encodeURIComponent(value);
}

/**
 * Cookie值解码
 * @param encodedValue 编码后的值
 * @returns 解码后的原始值
 */
export function decodeCookieValue(encodedValue: string): string {
  try {
    return decodeURIComponent(encodedValue);
  } catch {
    throw new Error('Cookie值解码失败');
  }
}

/**
 * 从请求头中安全地解析Cookie
 * @param cookieHeader Cookie请求头
 * @returns 解析后的Cookie对象
 */
export function parseCookiesSafely(cookieHeader: string | null): Record<string, string> {
  if (!cookieHeader) {
    return {};
  }

  const cookies: Record<string, string> = {};
  
  try {
    cookieHeader.split(';').forEach(cookie => {
      const [name, value] = cookie.trim().split('=');
      if (name && value) {
        cookies[name] = decodeCookieValue(value);
      }
    });
  } catch (error) {
    console.warn('Cookie解析失败:', error);
    return {};
  }

  return cookies;
}

/**
 * 删除Cookie的辅助函数
 * @param name Cookie名称
 * @param options Cookie配置选项（用于确定domain和path）
 * @returns 用于删除Cookie的Set-Cookie头值
 */
export function deleteCookie(
  name: string,
  options: Pick<SecureCookieOptions, 'domain' | 'path'> = {}
): string {
  const { domain, path = '/' } = options;
  
  let cookie = `${name}=; Max-Age=0; Path=${path}`;
  
  if (domain) {
    cookie += `; Domain=${domain}`;
  }
  
  if (process.env.NODE_ENV === 'production') {
    cookie += '; Secure';
  }
  
  cookie += '; HttpOnly; SameSite=strict';
  
  return cookie;
}