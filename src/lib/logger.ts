/**
 * 统一日志管理工具
 *
 * 功能特性：
 * - 支持不同日志级别 (debug, info, warn, error)
 * - 自动检测环境并调整输出策略
 * - 可配置的日志输出目标
 * - 保持开发时的调试便利性
 * - 确保生产环境的安全性
 */

// 日志级别枚举
export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  SILENT = 4,
}

// 日志配置接口
export interface LoggerConfig {
  level: LogLevel;
  enableConsole: boolean;
  enableFileLogging: boolean;
  enableRemoteLogging: boolean;
  stripSensitiveData: boolean;
  maxLogLength: number;
  includeTimestamp: boolean;
  includeStackTrace: boolean;
}

// 默认配置
const DEFAULT_CONFIG: LoggerConfig = {
  level: process.env.NODE_ENV === 'production' ? LogLevel.WARN : LogLevel.DEBUG,
  enableConsole: true,
  enableFileLogging: false,
  enableRemoteLogging: process.env.NODE_ENV === 'production',
  stripSensitiveData: process.env.NODE_ENV === 'production',
  maxLogLength: 1000,
  includeTimestamp: true,
  includeStackTrace: process.env.NODE_ENV === 'development',
};

// 敏感信息关键词
const _SENSITIVE_KEYWORDS = [
  'password',
  'token',
  'secret',
  'key',
  'auth',
  'cookie',
  'session',
  'authorization',
  'bearer',
  'api_key',
  'private',
  'credential',
  'passphrase',
  'sign',
  'hash',
  'salt',
];

// 敏感信息正则表达式
const SENSITIVE_PATTERNS = [
  /password["\s]*[:=]["\s]*([^"\s,}]+)/gi,
  /token["\s]*[:=]["\s]*([^"\s,}]+)/gi,
  /secret["\s]*[:=]["\s]*([^"\s,}]+)/gi,
  /key["\s]*[:=]["\s]*([^"\s,}]+)/gi,
  /auth["\s]*[:=]["\s]*([^"\s,}]+)/gi,
  /Bearer\s+([a-zA-Z0-9._~+/\\-]+=*)/gi,
  /basic\s+([a-zA-Z0-9._~+/\\-]+=*)/gi,
  /['"]([a-zA-Z0-9]{32,})['"]/gi, // 32位以上长度的字符串可能是密钥
];

class Logger {
  private config: LoggerConfig;
  private context: string;

  constructor(context = 'MoonTV', config: Partial<LoggerConfig> = {}) {
    this.config = { ...DEFAULT_CONFIG, ...config };
    this.context = context;
  }

  /**
   * 更新日志配置
   */
  updateConfig(config: Partial<LoggerConfig>): void {
    this.config = { ...this.config, ...config };
  }

  /**
   * 设置日志上下文
   */
  setContext(context: string): void {
    this.context = context;
  }

  /**
   * 获取当前日志级别
   */
  getLevel(): LogLevel {
    return this.config.level;
  }

  /**
   * 检查是否应该输出指定级别的日志
   */
  private shouldLog(level: LogLevel): boolean {
    return level >= this.config.level;
  }

  /**
   * 脱敏处理 - 移除敏感信息
   */
  private sanitizeData(data: unknown): unknown {
    if (!this.config.stripSensitiveData) {
      return data;
    }

    if (typeof data === 'string') {
      let sanitized = data;

      // 使用正则表达式替换敏感信息
      SENSITIVE_PATTERNS.forEach((pattern) => {
        sanitized = sanitized.replace(pattern, (match, captured) => {
          if (captured) {
            return match.replace(captured, '[REDACTED]');
          }
          return match;
        });
      });

      return sanitized;
    }

    if (typeof data === 'object' && data !== null) {
      try {
        const dataStr = JSON.stringify(data);
        const sanitized = this.sanitizeData(dataStr);
        return JSON.parse(sanitized as string);
      } catch {
        return '[Sanitization Error]';
      }
    }

    return data;
  }

  /**
   * 格式化日志消息
   */
  private formatMessage(
    level: string,
    message: string,
    data?: unknown
  ): string {
    const parts: string[] = [];

    // 添加时间戳
    if (this.config.includeTimestamp) {
      const timestamp = new Date().toISOString();
      parts.push(`[${timestamp}]`);
    }

    // 添加日志级别和上下文
    parts.push(`[${level}]`, `[${this.context}]`);

    // 添加消息
    parts.push(message);

    // 添加数据
    if (data !== undefined) {
      const sanitizedData = this.sanitizeData(data);
      const dataStr =
        typeof sanitizedData === 'object'
          ? JSON.stringify(sanitizedData, null, 2)
          : String(sanitizedData);

      // 限制日志长度
      const truncatedData =
        dataStr.length > this.config.maxLogLength
          ? dataStr.substring(0, this.config.maxLogLength) + '... [TRUNCATED]'
          : dataStr;

      parts.push(truncatedData);
    }

    return parts.join(' ');
  }

  /**
   * 获取调用堆栈信息
   */
  private getStackTrace(): string {
    if (!this.config.includeStackTrace) {
      return '';
    }

    try {
      const stack = new Error().stack;
      if (stack) {
        // 移除前几行堆栈信息，只保留有用的调用信息
        const lines = stack.split('\n').slice(3, 8);
        return lines.length > 0 ? '\n' + lines.join('\n') : '';
      }
    } catch {
      // 忽略获取堆栈时的错误
    }

    return '';
  }

  /**
   * 输出日志到控制台
   */
  private outputToConsole(
    level: string,
    message: string,
    data?: unknown
  ): void {
    if (!this.config.enableConsole) {
      return;
    }

    const formattedMessage = this.formatMessage(level, message, data);
    const stackTrace = this.getStackTrace();

    switch (level) {
      case 'DEBUG':
        // eslint-disable-next-line no-console
        console.debug(formattedMessage + stackTrace);
        break;
      case 'INFO':
        // eslint-disable-next-line no-console
        console.info(formattedMessage);
        break;
      case 'WARN':
        // eslint-disable-next-line no-console
        console.warn(formattedMessage);
        break;
      case 'ERROR':
        // eslint-disable-next-line no-console
        console.error(formattedMessage + stackTrace);
        break;
      default:
        // eslint-disable-next-line no-console
        console.log(formattedMessage);
    }
  }

  /**
   * 远程日志记录 (生产环境)
   */
  private async logToRemote(
    level: string,
    message: string,
    data?: unknown
  ): Promise<void> {
    if (
      !this.config.enableRemoteLogging ||
      process.env.NODE_ENV !== 'production'
    ) {
      return;
    }

    try {
      // 这里可以集成第三方日志服务，如 Sentry, LogRocket 等
      // 目前只做简单的错误收集
      if (level === 'ERROR') {
        const logData = {
          level,
          message,
          data: this.sanitizeData(data),
          context: this.context,
          timestamp: new Date().toISOString(),
          url:
            typeof window !== 'undefined'
              ? window.location.href
              : 'server-side',
          userAgent:
            typeof window !== 'undefined'
              ? window.navigator.userAgent
              : 'server-side',
        };

        // 这里可以发送到日志服务
        // await fetch('/api/logs', { ... });

        // 暂时不实现，避免网络请求
        // eslint-disable-next-line no-console
        console.warn('[Remote Logger]', logData);
      }
    } catch (error) {
      // 避免日志记录本身产生错误
      // eslint-disable-next-line no-console
      console.warn('[Logger] Failed to send remote log:', error);
    }
  }

  /**
   * 核心日志方法
   */
  private async log(
    level: LogLevel,
    levelName: string,
    message: string,
    data?: unknown
  ): Promise<void> {
    if (!this.shouldLog(level)) {
      return;
    }

    // 输出到控制台
    this.outputToConsole(levelName, message, data);

    // 远程日志记录
    await this.logToRemote(levelName, message, data);
  }

  /**
   * 调试级别日志
   */
  debug(message: string, data?: unknown): void {
    this.log(LogLevel.DEBUG, 'DEBUG', message, data);
  }

  /**
   * 信息级别日志
   */
  info(message: string, data?: unknown): void {
    this.log(LogLevel.INFO, 'INFO', message, data);
  }

  /**
   * 警告级别日志
   */
  warn(message: string, data?: unknown): void {
    this.log(LogLevel.WARN, 'WARN', message, data);
  }

  /**
   * 错误级别日志
   */
  error(message: string, error?: Error | unknown): void {
    let errorData = error;

    // 如果是 Error 对象，提取有用信息
    if (error instanceof Error) {
      errorData = {
        name: error.name,
        message: error.message,
        stack: error.stack,
      };
    }

    this.log(LogLevel.ERROR, 'ERROR', message, errorData);
  }

  /**
   * 性能计时开始
   */
  time(label: string): void {
    if (this.shouldLog(LogLevel.DEBUG)) {
      // eslint-disable-next-line no-console
      console.time(`${this.context}:${label}`);
    }
  }

  /**
   * 性能计时结束
   */
  timeEnd(label: string): void {
    if (this.shouldLog(LogLevel.DEBUG)) {
      // eslint-disable-next-line no-console
      console.timeEnd(`${this.context}:${label}`);
    }
  }

  /**
   * 分组日志
   */
  group(label: string): void {
    if (this.shouldLog(LogLevel.DEBUG)) {
      // eslint-disable-next-line no-console
      console.group(`${this.context}: ${label}`);
    }
  }

  /**
   * 分组日志结束
   */
  groupEnd(): void {
    if (this.shouldLog(LogLevel.DEBUG)) {
      // eslint-disable-next-line no-console
      console.groupEnd();
    }
  }

  /**
   * 表格形式输出
   */
  table(data: unknown[]): void {
    if (this.shouldLog(LogLevel.DEBUG) && this.config.enableConsole) {
      // eslint-disable-next-line no-console
      console.table(this.sanitizeData(data));
    }
  }
}

// 创建默认日志实例
export const logger = new Logger();

// 创建带上下文的日志实例工厂
export function createLogger(
  context: string,
  config?: Partial<LoggerConfig>
): Logger {
  return new Logger(context, config);
}

// 快速创建不同模块的日志实例
export const loggers = {
  api: createLogger('API'),
  config: createLogger('CONFIG'),
  database: createLogger('DATABASE'),
  video: createLogger('VIDEO'),
  user: createLogger('USER'),
  admin: createLogger('ADMIN'),
  search: createLogger('SEARCH'),
  playback: createLogger('PLAYBACK'),
  utils: createLogger('UTILS'),
  cron: createLogger('CRON'),
};

// 环境检测工具
export const isDevelopment = process.env.NODE_ENV === 'development';
export const isProduction = process.env.NODE_ENV === 'production';
export const isTest = process.env.NODE_ENV === 'test';

export default logger;
