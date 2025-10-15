/**
 * 企业级日志系统
 * 提供结构化日志记录、错误追踪和性能监控
 */

// 日志级别枚举
export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  FATAL = 4,
}

// 日志条目接口
export interface LogEntry {
  timestamp: string;
  level: LogLevel;
  message: string;
  module: string;
  context?: Record<string, any>;
  userId?: string;
  requestId?: string;
  stackTrace?: string;
  userAgent?: string;
  ip?: string;
  url?: string;
  method?: string;
  duration?: number;
}

// 日志配置接口
export interface LoggerConfig {
  level: LogLevel;
  module: string;
  enableConsole: boolean;
  enableFile: boolean;
  enableRemote: boolean;
  maxLogSize: number;
  remoteEndpoint?: string;
  apiKey?: string;
}

// 默认日志配置
const DEFAULT_CONFIG: LoggerConfig = {
  level: process.env.NODE_ENV === 'production' ? LogLevel.INFO : LogLevel.DEBUG,
  module: 'app',
  enableConsole: true,
  enableFile: process.env.NODE_ENV === 'production',
  enableRemote: process.env.NODE_ENV === 'production',
  maxLogSize: 10000,
};

// 日志管理器类
export class Logger {
  private static instance: Logger;
  private config: LoggerConfig;
  private logs: LogEntry[] = [];
  private maxLogs: number;

  private constructor(config: Partial<LoggerConfig> = {}) {
    this.config = { ...DEFAULT_CONFIG, ...config };
    this.maxLogs = this.config.maxLogSize;
  }

  public static getInstance(config?: Partial<LoggerConfig>): Logger {
    if (!Logger.instance) {
      Logger.instance = new Logger(config);
    }
    return Logger.instance;
  }

  // 更新配置
  public updateConfig(config: Partial<LoggerConfig>): void {
    this.config = { ...this.config, ...config };
    this.maxLogs = this.config.maxLogSize;
  }

  // 获取当前日志级别
  private getLogLevelName(level: LogLevel): string {
    return LogLevel[level];
  }

  // 格式化日志条目
  private formatLogEntry(entry: LogEntry): string {
    const timestamp = new Date(entry.timestamp).toISOString();
    const level = this.getLogLevelName(entry.level).padEnd(5);
    const module = entry.module.padEnd(15);
    const message = entry.message;

    let formatted = `[${timestamp}] ${level} ${module} ${message}`;

    if (entry.context && Object.keys(entry.context).length > 0) {
      formatted += ` | Context: ${JSON.stringify(entry.context)}`;
    }

    if (entry.requestId) {
      formatted += ` | RequestID: ${entry.requestId}`;
    }

    if (entry.userId) {
      formatted += ` | UserID: ${entry.userId}`;
    }

    if (entry.duration) {
      formatted += ` | Duration: ${entry.duration}ms`;
    }

    return formatted;
  }

  // 内部日志记录方法
  private log(
    level: LogLevel,
    message: string,
    context?: Record<string, any>,
  ): void {
    if (level < this.config.level) {
      return;
    }

    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level,
      message,
      module: this.config.module,
      context,
      userAgent:
        typeof window !== 'undefined' ? window.navigator.userAgent : undefined,
      url: typeof window !== 'undefined' ? window.location.href : undefined,
    };

    // 添加到内存日志
    this.logs.push(entry);

    // 限制日志数量
    if (this.logs.length > this.maxLogs) {
      this.logs = this.logs.slice(-this.maxLogs);
    }

    // 控制台输出
    if (this.config.enableConsole) {
      const formatted = this.formatLogEntry(entry);
      switch (level) {
        case LogLevel.DEBUG:
          console.debug(formatted);
          break;
        case LogLevel.INFO:
          console.info(formatted);
          break;
        case LogLevel.WARN:
          console.warn(formatted);
          break;
        case LogLevel.ERROR:
        case LogLevel.FATAL:
          console.error(formatted);
          if (entry.stackTrace) {
            console.error(entry.stackTrace);
          }
          break;
      }
    }

    // 远程日志记录（生产环境）
    if (this.config.enableRemote && this.config.remoteEndpoint) {
      this.sendToRemote(entry);
    }
  }

  // 发送日志到远程服务
  private async sendToRemote(entry: LogEntry): Promise<void> {
    try {
      const response = await fetch(this.config.remoteEndpoint!, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(this.config.apiKey && {
            Authorization: `Bearer ${this.config.apiKey}`,
          }),
        },
        body: JSON.stringify(entry),
      });

      if (!response.ok) {
        console.warn(
          'Failed to send log to remote endpoint:',
          response.statusText,
        );
      }
    } catch (error) {
      console.warn('Error sending log to remote endpoint:', error);
    }
  }

  // 公共日志方法
  public debug(message: string, context?: Record<string, any>): void {
    this.log(LogLevel.DEBUG, message, context);
  }

  public info(message: string, context?: Record<string, any>): void {
    this.log(LogLevel.INFO, message, context);
  }

  public warn(message: string, context?: Record<string, any>): void {
    this.log(LogLevel.WARN, message, context);
  }

  public error(
    message: string,
    error?: Error | Record<string, any>,
    context?: Record<string, any>,
  ): void {
    let errorContext = context;
    let stackTrace: string | undefined;

    if (error instanceof Error) {
      errorContext = { ...context, error: error.message, name: error.name };
      stackTrace = error.stack;
    } else if (error) {
      errorContext = { ...context, error };
    }

    this.log(LogLevel.ERROR, message, errorContext);
    if (stackTrace) {
      this.logs[this.logs.length - 1].stackTrace = stackTrace;
    }
  }

  public fatal(
    message: string,
    error?: Error | Record<string, any>,
    context?: Record<string, any>,
  ): void {
    let errorContext = context;
    let stackTrace: string | undefined;

    if (error instanceof Error) {
      errorContext = { ...context, error: error.message, name: error.name };
      stackTrace = error.stack;
    } else if (error) {
      errorContext = { ...context, error };
    }

    this.log(LogLevel.FATAL, message, errorContext);
    if (stackTrace) {
      this.logs[this.logs.length - 1].stackTrace = stackTrace;
    }
  }

  // 性能日志
  public performance(
    operation: string,
    duration: number,
    context?: Record<string, any>,
  ): void {
    this.info(`Performance: ${operation}`, {
      ...context,
      operation,
      duration,
      performance: true,
    });
  }

  // API请求日志
  public apiRequest(
    method: string,
    url: string,
    duration: number,
    statusCode: number,
    context?: Record<string, any>,
  ): void {
    const level =
      statusCode >= 500
        ? LogLevel.ERROR
        : statusCode >= 400
          ? LogLevel.WARN
          : LogLevel.INFO;

    this.log(level, `API Request: ${method} ${url}`, {
      ...context,
      method,
      url,
      duration,
      statusCode,
      apiRequest: true,
    });
  }

  // 用户操作日志
  public userAction(
    action: string,
    userId?: string,
    context?: Record<string, any>,
  ): void {
    this.info(`User Action: ${action}`, {
      ...context,
      userId,
      userAction: true,
    });
  }

  // 安全事件日志
  public security(event: string, context?: Record<string, any>): void {
    this.warn(`Security Event: ${event}`, {
      ...context,
      security: true,
    });
  }

  // 获取日志
  public getLogs(level?: LogLevel, limit?: number): LogEntry[] {
    let filteredLogs = this.logs;

    if (level !== undefined) {
      filteredLogs = filteredLogs.filter((log) => log.level >= level);
    }

    if (limit) {
      filteredLogs = filteredLogs.slice(-limit);
    }

    return filteredLogs;
  }

  // 清除日志
  public clearLogs(): void {
    this.logs = [];
  }

  // 获取日志统计
  public getStats(): {
    total: number;
    byLevel: {
      debug: number;
      info: number;
      warn: number;
      error: number;
      fatal: number;
    };
    byModule: Record<string, number>;
    recent: number;
  } {
    const stats = {
      total: this.logs.length,
      byLevel: {
        debug: 0,
        info: 0,
        warn: 0,
        error: 0,
        fatal: 0,
      },
      byModule: {} as Record<string, number>,
      recent: 0,
    };

    this.logs.forEach((log) => {
      stats.byLevel[
        LogLevel[log.level].toLowerCase() as keyof typeof stats.byLevel
      ]++;
      stats.byModule[log.module] = (stats.byModule[log.module] || 0) + 1;

      const oneHourAgo = Date.now() - 60 * 60 * 1000;
      if (new Date(log.timestamp).getTime() > oneHourAgo) {
        stats.recent++;
      }
    });

    return stats;
  }
}

// 错误处理工具类
export class ErrorHandler {
  private static logger = Logger.getInstance({ module: 'ErrorHandler' });

  // 处理异步错误
  public static async handleAsyncError<T>(
    operation: () => Promise<T>,
    context?: Record<string, any>,
  ): Promise<{ success: boolean; data?: T; error?: Error }> {
    try {
      const data = await operation();
      return { success: true, data };
    } catch (error) {
      this.logger.error('Async operation failed', error as Error, context);
      return { success: false, error: error as Error };
    }
  }

  // 处理同步错误
  public static handleError<T>(
    operation: () => T,
    context?: Record<string, any>,
  ): { success: boolean; data?: T; error?: Error } {
    try {
      const data = operation();
      return { success: true, data };
    } catch (error) {
      this.logger.error('Operation failed', error as Error, context);
      return { success: false, error: error as Error };
    }
  }

  // 创建错误边界友好的错误对象
  public static createError(
    message: string,
    code?: string,
    context?: Record<string, any>,
  ): Error & { code?: string; context?: Record<string, any> } {
    const error = new Error(message) as Error & {
      code?: string;
      context?: Record<string, any>;
    };
    if (code) error.code = code;
    if (context) error.context = context;
    return error;
  }

  // 包装函数以添加错误处理
  public static wrapFunction<T extends (...args: any[]) => any>(
    fn: T,
    context?: Record<string, any>,
  ): T {
    return ((...args: any[]) => {
      try {
        const result = fn(...args);
        if (result instanceof Promise) {
          return result.catch((error: Error) => {
            this.logger.error('Function error', error, context);
            throw error;
          });
        }
        return result;
      } catch (error) {
        this.logger.error('Function error', error as Error, context);
        throw error;
      }
    }) as T;
  }

  // 重试机制
  public static async retry<T>(
    operation: () => Promise<T>,
    maxRetries: number = 3,
    delay: number = 1000,
    context?: Record<string, any>,
  ): Promise<T> {
    let lastError: Error = new Error('Operation failed');

    for (let i = 0; i <= maxRetries; i++) {
      try {
        const result = await operation();
        if (i > 0) {
          this.logger.info(`Operation succeeded after ${i} retries`, context);
        }
        return result;
      } catch (error) {
        lastError = error as Error;
        if (i < maxRetries) {
          this.logger.warn(
            `Operation failed, retrying in ${delay}ms (attempt ${i + 1}/${maxRetries + 1})`,
            {
              ...context,
              error: lastError.message,
            },
          );
          await new Promise((resolve) => setTimeout(resolve, delay));
          delay *= 2; // 指数退避
        }
      }
    }

    this.logger.error(
      `Operation failed after ${maxRetries + 1} attempts`,
      lastError,
      context,
    );
    throw lastError;
  }

  // 超时处理
  public static withTimeout<T>(
    operation: Promise<T>,
    timeoutMs: number,
    context?: Record<string, any>,
  ): Promise<T> {
    return Promise.race([
      operation,
      new Promise<never>((_, reject) => {
        setTimeout(() => {
          const timeoutError = new Error(
            `Operation timed out after ${timeoutMs}ms`,
          );
          this.logger.error('Operation timeout', timeoutError, context);
          reject(timeoutError);
        }, timeoutMs);
      }),
    ]);
  }
}

// 性能监控器
export class PerformanceMonitor {
  private static logger = Logger.getInstance({ module: 'Performance' });
  private static timers = new Map<string, number>();

  // 开始计时
  public static startTimer(name: string): void {
    this.timers.set(name, Date.now());
  }

  // 结束计时并记录
  public static endTimer(name: string, context?: Record<string, any>): number {
    const startTime = this.timers.get(name);
    if (startTime === undefined) {
      this.logger.warn(`Timer '${name}' was not started`, context);
      return 0;
    }

    const duration = Date.now() - startTime;
    this.timers.delete(name);
    this.logger.performance(name, duration, context);

    return duration;
  }

  // 测量函数执行时间
  public static async measureAsync<T>(
    name: string,
    operation: () => Promise<T>,
    context?: Record<string, any>,
  ): Promise<{ result: T; duration: number }> {
    const startTime = Date.now();
    const result = await operation();
    const duration = Date.now() - startTime;

    this.logger.performance(name, duration, context);
    return { result, duration };
  }

  // 测量同步函数执行时间
  public static measure<T>(
    name: string,
    operation: () => T,
    context?: Record<string, any>,
  ): { result: T; duration: number } {
    const startTime = Date.now();
    const result = operation();
    const duration = Date.now() - startTime;

    this.logger.performance(name, duration, context);
    return { result, duration };
  }
}

// 导出默认日志实例
export const logger = Logger.getInstance();

// 向后兼容的console方法
export const consoleLogger = {
  log: (...args: any[]) => {
    if (process.env.NODE_ENV !== 'production') {
      console.log(...args);
    }
  },
  warn: (...args: any[]) => {
    if (process.env.NODE_ENV !== 'production') {
      console.warn(...args);
    }
  },
  error: (...args: any[]) => {
    console.error(...args);
  },
};
