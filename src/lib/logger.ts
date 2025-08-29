/**
 * 生产级日志系统
 * 提供结构化的日志记录和错误监控功能
 */

interface LogContext {
  userId?: string;
  requestId?: string;
  [key: string]: unknown;
}

type LogLevel = 'debug' | 'info' | 'warn' | 'error' | 'fatal';

interface LogEntry {
  level: LogLevel;
  message: string;
  timestamp: number;
  context?: LogContext;
  error?: {
    name: string;
    message: string;
    stack?: string;
  };
}

class Logger {
  private readonly isDev: boolean;
  private readonly serviceName: string;
  
  constructor() {
    this.isDev = process.env.NODE_ENV === 'development';
    this.serviceName = process.env.NEXT_PUBLIC_SITE_NAME || 'MoonTV';
  }

  /**
   * 调试日志 - 开发环境使用
   */
  debug(message: string, context?: LogContext): void {
    if (this.isDev) {
      this.logToConsole('debug', message, context);
    }
    this.sendToMonitoring('debug', message, context);
  }

  /**
   * 信息日志
   */
  info(message: string, context?: LogContext): void {
    if (this.isDev) {
      this.logToConsole('info', message, context);
    }
    this.sendToMonitoring('info', message, context);
  }

  /**
   * 警告日志
   */
  warn(message: string, context?: LogContext): void {
    if (this.isDev) {
      this.logToConsole('warn', message, context);
    }
    this.sendToMonitoring('warn', message, context);
  }

  /**
   * 错误日志
   */
  error(message: string, error?: Error, context?: LogContext): void {
    const errorContext = error ? this.formatError(error) : undefined;
    const fullContext = { ...context, ...errorContext };
    
    if (this.isDev) {
      this.logToConsole('error', message, fullContext);
    }
    this.sendToMonitoring('error', message, fullContext);
  }

  /**
   * 致命错误日志
   */
  fatal(message: string, error?: Error, context?: LogContext): void {
    const errorContext = error ? this.formatError(error) : undefined;
    const fullContext = { ...context, ...errorContext };
    
    if (this.isDev) {
      this.logToConsole('error', `[FATAL] ${message}`, fullContext);
    }
    this.sendToMonitoring('fatal', message, fullContext);
    
    // 生产环境下发送告警
    if (!this.isDev) {
      this.sendAlert(message, fullContext);
    }
  }

  /**
   * API请求日志
   */
  apiRequest(
    method: string,
    path: string,
    statusCode: number,
    duration: number,
    context?: LogContext
  ): void {
    const message = `${method} ${path} ${statusCode} - ${duration}ms`;
    const apiContext = {
      ...context,
      method,
      path,
      statusCode,
      duration,
    };
    
    this.info(message, apiContext);
  }

  /**
   * 性能日志
   */
  performance(
    operation: string,
    duration: number,
    context?: LogContext
  ): void {
    const message = `${operation} completed in ${duration}ms`;
    const perfContext = {
      ...context,
      operation,
      duration,
    };
    
    this.info(message, perfContext);
  }

  private logToConsole(level: LogLevel, message: string, context?: LogContext): void {
    const timestamp = new Date().toISOString();
    const levelColor = this.getLevelColor(level);
    const resetColor = '\x1b[0m';
    
    // eslint-disable-next-line no-console
    console[level === 'fatal' ? 'error' : level](
      `${this.getLevelEmoji(level)} ${timestamp} [${levelColor}${level.toUpperCase()}${resetColor}] ${message}`,
      context ? JSON.stringify(context, null, 2) : ''
    );
  }

  private sendToMonitoring(level: LogLevel, message: string, context?: LogContext): void {
    if (this.isDev) {
      return; // 开发环境不发送到监控服务
    }

    const logEntry: LogEntry = {
      level,
      message,
      timestamp: Date.now(),
      context,
    };

    // 生产环境发送到监控服务（Sentry, DataDog, 等）
    this.sendToExternalService(logEntry);
  }

  private sendToExternalService(logEntry: LogEntry): void {
    // 这里可以集成实际的监控服务
    // 例如: Sentry, DataDog, Elasticsearch, 等
    
    const _monitoringData = {
      service: this.serviceName,
      environment: process.env.NODE_ENV || 'development',
      ...logEntry,
    };

    // 模拟发送到外部服务
    if (process.env.NODE_ENV === 'production') {
      // 实际项目中这里会调用监控服务的API
      // console.log('[MONITORING]', JSON.stringify(monitoringData));
    }
  }

  private sendAlert(message: string, context?: LogContext): void {
    // 发送告警到监控系统
    const _alertData = {
      service: this.serviceName,
      message,
      severity: 'critical',
      timestamp: Date.now(),
      context,
    };

    // 实际项目中这里会调用告警系统
    // console.log('[ALERT]', JSON.stringify(alertData));
  }

  private formatError(error: Error): { error: { name: string; message: string; stack?: string } } {
    return {
      error: {
        name: error.name,
        message: error.message,
        stack: error.stack,
      },
    };
  }

  private getLevelColor(level: LogLevel): string {
    const colors = {
      debug: '\x1b[36m', // cyan
      info: '\x1b[32m',  // green
      warn: '\x1b[33m',  // yellow
      error: '\x1b[31m', // red
      fatal: '\x1b[35m', // magenta
    };
    return colors[level];
  }

  private getLevelEmoji(level: LogLevel): string {
    const emojis = {
      debug: '🔍',
      info: 'ℹ️',
      warn: '⚠️',
      error: '❌',
      fatal: '💀',
    };
    return emojis[level];
  }

  /**
   * 创建子日志器（用于特定模块）
   */
  createChildLogger(module: string): Logger {
    const childLogger = new Logger();
    
    // 重写日志方法以包含模块信息
    const originalSendToMonitoring = childLogger.sendToMonitoring.bind(childLogger);
    childLogger.sendToMonitoring = (level: LogLevel, message: string, context?: LogContext) => {
      const moduleContext = { ...context, module };
      originalSendToMonitoring(level, message, moduleContext);
    };

    return childLogger;
  }
}

// 全局日志器实例
export const logger = new Logger();

// 模块特定的日志器
export const authLogger = logger.createChildLogger('auth');
export const apiLogger = logger.createChildLogger('api');
export const dbLogger = logger.createChildLogger('database');
export const middlewareLogger = logger.createChildLogger('middleware');

// 工厂函数
export function createLogger(module: string): Logger {
  return logger.createChildLogger(module);
}

export function createModuleLogger(module: string): Logger {
  return logger.createChildLogger(module);
}

/**
 * 日志工具函数
 */

export function measurePerformance<T>(
  operation: string,
  callback: () => T,
  context?: LogContext
): T {
  const startTime = Date.now();
  
  try {
    const result = callback();
    const duration = Date.now() - startTime;
    
    if (duration > 1000) {
      logger.warn(`Performance warning: ${operation} took ${duration}ms`, context);
    }
    
    logger.performance(operation, duration, context);
    return result;
  } catch (error) {
    const duration = Date.now() - startTime;
    logger.error(`Performance error: ${operation} failed after ${duration}ms`, error as Error, context);
    throw error;
  }
}

export function withLogging<T extends (...args: unknown[]) => unknown>(
  fn: T,
  name: string = fn.name
): T {
  return ((...args: Parameters<T>): ReturnType<T> => {
    logger.debug(`Calling ${name}`, { args: _sanitizeArgs(args) });
    
    try {
      const result = fn(...args);
      
      if (result instanceof Promise) {
        return result
          .then((value) => {
            logger.debug(`Success: ${name}`, { result: _sanitizeResult(value) });
            return value;
          })
          .catch((error) => {
            logger.error(`Error in async function: ${name}`, error);
            throw error;
          }) as ReturnType<T>;
      }
      
      logger.debug(`Success: ${name}`, { result: _sanitizeResult(result) });
      return result as ReturnType<T>;
    } catch (error) {
      logger.error(`Error in function: ${name}`, error as Error);
      throw error;
    }
  }) as T;
}

// 参数和结果清理（避免记录敏感信息）
function _sanitizeArgs(args: unknown[]): unknown[] {
  return args.map(arg => {
    if (typeof arg === 'object' && arg !== null) {
      const sanitized = { ...arg };
      
      // 移除敏感字段
      if ('password' in sanitized) sanitized.password = '***';
      if ('token' in sanitized) sanitized.token = '***';
      if ('authorization' in sanitized) sanitized.authorization = '***';
      
      return sanitized;
    }
    return arg;
  });
}

function _sanitizeResult(result: unknown): unknown {
  if (typeof result === 'object' && result !== null) {
    const sanitized = { ...result };
    
    // 移除敏感字段
    if ('password' in sanitized) sanitized.password = '***';
    if ('token' in sanitized) sanitized.token = '***';
    if ('authorization' in sanitized) sanitized.authorization = '***';
    
    return sanitized;
  }
  return result;
}