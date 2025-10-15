/**
 * 安全工具库
 * 提供各种安全相关的工具函数
 */

// XSS 防护
export function sanitizeHtml(input: string): string {
  const div = document.createElement('div');
  div.textContent = input;
  return div.innerHTML;
}

// URL 验证
export function isValidUrl(url: string): boolean {
  try {
    const urlObject = new URL(url);
    return ['http:', 'https:'].includes(urlObject.protocol);
  } catch {
    return false;
  }
}

// 邮箱验证
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

// 安全的JSON解析
export function safeJsonParse<T>(json: string, fallback: T): T {
  try {
    return JSON.parse(json);
  } catch {
    return fallback;
  }
}

// 防止CSRF攻击的token生成
export function generateCSRFToken(length: number = 32): string {
  const chars =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

// 密码强度检查
export function checkPasswordStrength(password: string): {
  score: number;
  feedback: string[];
} {
  const feedback: string[] = [];
  let score = 0;

  if (password.length >= 8) {
    score += 1;
  } else {
    feedback.push('密码长度至少需要8个字符');
  }

  if (/[a-z]/.test(password)) {
    score += 1;
  } else {
    feedback.push('密码需要包含小写字母');
  }

  if (/[A-Z]/.test(password)) {
    score += 1;
  } else {
    feedback.push('密码需要包含大写字母');
  }

  if (/\d/.test(password)) {
    score += 1;
  } else {
    feedback.push('密码需要包含数字');
  }

  if (/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
    score += 1;
  } else {
    feedback.push('密码需要包含特殊字符');
  }

  if (password.length >= 12) {
    score += 1;
  }

  return { score, feedback };
}

// 内容安全策略配置
export const CSP_DIRECTIVES = {
  'default-src': ["'self'"],
  'script-src': ["'self'", "'unsafe-eval'", "'unsafe-inline'"], // 开发环境需要
  'style-src': ["'self'", "'unsafe-inline'"],
  'img-src': ["'self'", 'data:', 'https:', 'http:'],
  'font-src': ["'self'", 'data:'],
  'connect-src': ["'self'", 'https:', 'http:'],
  'media-src': ["'self'", 'https:', 'http:'],
  'object-src': ["'none'"],
  'base-uri': ["'self'"],
  'form-action': ["'self'"],
  'frame-ancestors': ["'none'"],
  'upgrade-insecure-requests': [],
};

// 生成CSP头部字符串
export function generateCSPHeader(): string {
  return Object.entries(CSP_DIRECTIVES)
    .map(([directive, sources]) => `${directive} ${sources.join(' ')}`)
    .join('; ');
}

// 安全头部配置
export const SECURITY_HEADERS = {
  'X-Frame-Options': 'DENY',
  'X-Content-Type-Options': 'nosniff',
  'Referrer-Policy': 'origin-when-cross-origin',
  'X-XSS-Protection': '1; mode=block',
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
  'Content-Security-Policy': generateCSPHeader(),
  'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
};

// Rate limiting 配置
export interface RateLimitConfig {
  windowMs: number;
  maxRequests: number;
  message: string;
}

export const RATE_LIMIT_CONFIGS: Record<string, RateLimitConfig> = {
  // API 路由限制
  '/api/search': {
    windowMs: 60 * 1000, // 1分钟
    maxRequests: 30,
    message: '搜索请求过于频繁，请稍后再试',
  },
  '/api/login': {
    windowMs: 15 * 60 * 1000, // 15分钟
    maxRequests: 5,
    message: '登录尝试过于频繁，请15分钟后再试',
  },
  '/api/register': {
    windowMs: 60 * 60 * 1000, // 1小时
    maxRequests: 3,
    message: '注册请求过于频繁，请1小时后再试',
  },
  // 默认限制
  default: {
    windowMs: 60 * 1000, // 1分钟
    maxRequests: 100,
    message: '请求过于频繁，请稍后再试',
  },
};

// 内存中的rate limiting存储（生产环境应使用Redis等）
const rateLimitStore = new Map<string, { count: number; resetTime: number }>();

// Rate limiting 检查
export function checkRateLimit(
  identifier: string,
  config: RateLimitConfig,
): { allowed: boolean; resetTime?: number; remaining?: number } {
  const now = Date.now();
  const key = identifier;

  let record = rateLimitStore.get(key);

  if (!record || now > record.resetTime) {
    // 创建新记录或重置过期记录
    record = {
      count: 1,
      resetTime: now + config.windowMs,
    };
    rateLimitStore.set(key, record);
    return {
      allowed: true,
      resetTime: record.resetTime,
      remaining: config.maxRequests - 1,
    };
  }

  if (record.count >= config.maxRequests) {
    return {
      allowed: false,
      resetTime: record.resetTime,
      remaining: 0,
    };
  }

  record.count++;
  return {
    allowed: true,
    resetTime: record.resetTime,
    remaining: config.maxRequests - record.count,
  };
}

// 安全中间件工具
export class SecurityMiddleware {
  // 生成nonce
  static generateNonce(length: number = 16): string {
    const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }

  // 验证请求来源
  static validateOrigin(request: Request, allowedOrigins: string[]): boolean {
    const origin = request.headers.get('origin');
    const referer = request.headers.get('referer');

    if (!origin && !referer) return false;

    const checkOrigin = (url: string | null) => {
      if (!url) return false;
      try {
        const urlObj = new URL(url);
        return allowedOrigins.some(
          (allowed) => urlObj.origin === allowed || allowed === '*',
        );
      } catch {
        return false;
      }
    };

    return checkOrigin(origin) || checkOrigin(referer);
  }

  // 验证请求大小
  static validateRequestSize(
    request: Request,
    maxSize: number = 10 * 1024 * 1024,
  ): boolean {
    const contentLength = request.headers.get('content-length');
    if (!contentLength) return true;

    const size = parseInt(contentLength, 10);
    return !isNaN(size) && size <= maxSize;
  }

  // 检测可疑请求模式
  static detectSuspiciousPatterns(request: Request): boolean {
    const userAgent = request.headers.get('user-agent') || '';
    const url = request.url;

    // 检查可疑的User-Agent
    const suspiciousUAs = [/bot/i, /crawler/i, /scanner/i, /curl/i, /wget/i];

    if (suspiciousUAs.some((pattern) => pattern.test(userAgent))) {
      // 对于爬虫，需要进一步判断是否为合法爬虫
      const legitimateBots = ['googlebot', 'bingbot', 'slurp', 'duckduckbot'];

      if (
        !legitimateBots.some((bot) => userAgent.toLowerCase().includes(bot))
      ) {
        return true;
      }
    }

    // 检查SQL注入模式
    const sqlInjectionPatterns = [
      /(\%27)|(\')|(\-\-)|(\%23)|(#)/i,
      /((\%3D)|(=))[^\n]*((\%27)|(\')|(\-\-)|(\%3B)|(;))/i,
      /\w*((\%27)|(\'))((\%6F)|o|(\%4F))((\%72)|r|(\%52))/i,
    ];

    if (sqlInjectionPatterns.some((pattern) => pattern.test(url))) {
      return true;
    }

    // 检查XSS模式
    const xssPatterns = [
      /<script[^>]*>.*?<\/script>/gi,
      /<iframe[^>]*>.*?<\/iframe>/gi,
      /javascript:/gi,
      /on\w+\s*=/gi,
    ];

    if (xssPatterns.some((pattern) => pattern.test(url))) {
      return true;
    }

    return false;
  }
}

// 数据加密工具
export class DataEncryption {
  private static encoder = new TextEncoder();
  private static decoder = new TextDecoder();

  // 生成随机盐值
  static generateSalt(length: number = 16): Uint8Array {
    return crypto.getRandomValues(new Uint8Array(length));
  }

  // 生成密钥派生
  static async deriveKey(
    password: string,
    salt: Uint8Array,
  ): Promise<CryptoKey> {
    const encoder = new TextEncoder();
    const keyMaterial = await crypto.subtle.importKey(
      'raw',
      encoder.encode(password),
      'PBKDF2',
      false,
      ['deriveBits', 'deriveKey'],
    );

    return crypto.subtle.deriveKey(
      {
        name: 'PBKDF2',
        salt: new Uint8Array(salt), // 确保类型正确
        iterations: 100000,
        hash: 'SHA-256',
      },
      keyMaterial,
      { name: 'AES-GCM', length: 256 },
      true,
      ['encrypt', 'decrypt'],
    );
  }

  // 简化的Base64加密（仅用于演示，生产环境需要更安全的实现）
  static async encrypt(data: string, key: string): Promise<string> {
    // 简单的XOR加密（仅用于演示）
    const encoder = new TextEncoder();
    const dataBytes = encoder.encode(data);
    const keyBytes = encoder.encode(
      key.padEnd(dataBytes.length, '0').slice(0, dataBytes.length),
    );

    const encrypted = Array.from(dataBytes).map(
      (byte, i) => byte ^ keyBytes[i],
    );
    return btoa(String.fromCharCode(...encrypted));
  }

  static async decrypt(encryptedData: string, key: string): Promise<string> {
    try {
      const decoded = atob(encryptedData);
      const encrypted = new Uint8Array(
        Array.from(decoded).map((char) => char.charCodeAt(0)),
      );

      const encoder = new TextEncoder();
      const keyBytes = encoder.encode(
        key.padEnd(encrypted.length, '0').slice(0, encrypted.length),
      );

      const decrypted = encrypted.map((byte, i) => byte ^ keyBytes[i]);
      const decoder = new TextDecoder();
      return decoder.decode(decrypted);
    } catch (error) {
      throw new Error('Decryption failed');
    }
  }
}

// 安全日志记录
export class SecurityLogger {
  private static logs: Array<{
    timestamp: Date;
    level: 'info' | 'warning' | 'error' | 'critical';
    event: string;
    details: any;
  }> = [];

  static log(
    level: 'info' | 'warning' | 'error' | 'critical',
    event: string,
    details: any = {},
  ) {
    const logEntry = {
      timestamp: new Date(),
      level,
      event,
      details: JSON.stringify(details),
    };

    this.logs.push(logEntry);

    // 保持日志数量在合理范围内
    if (this.logs.length > 1000) {
      this.logs = this.logs.slice(-500);
    }

    // 在开发环境中输出到控制台
    if (process.env.NODE_ENV === 'development') {
      console.log(`[Security:${level.toUpperCase()}] ${event}`, details);
    }
  }

  static getLogs(): typeof SecurityLogger.logs {
    return [...this.logs];
  }

  static clearLogs(): void {
    this.logs = [];
  }

  static getRecentLogs(minutes: number = 60): typeof SecurityLogger.logs {
    const cutoff = new Date(Date.now() - minutes * 60 * 1000);
    return this.logs.filter((log) => log.timestamp >= cutoff);
  }
}
