// 统一日志管理
export enum LogLevel {
  ERROR = 0,
  WARN = 1,
  INFO = 2,
  DEBUG = 3,
}

export interface LogEntry {
  level: LogLevel;
  message: string;
  timestamp: string;
  context?: Record<string, any>;
}

class Logger {
  private isProduction: boolean;
  private logLevel: LogLevel;

  constructor() {
    this.isProduction = process.env.NODE_ENV === 'production';
    this.logLevel = this.isProduction ? LogLevel.INFO : LogLevel.DEBUG;
  }

  private shouldLog(level: LogLevel): boolean {
    return level <= this.logLevel;
  }

  private formatLogEntry(level: LogLevel, message: string, context?: Record<string, any>): LogEntry {
    return {
      level,
      message,
      timestamp: new Date().toISOString(),
      context,
    };
  }

  private log(entry: LogEntry) {
    if (!this.shouldLog(entry.level)) return;

    const { level, message, timestamp, context } = entry;
    const logMessage = `[${timestamp}] ${this.getLevelName(level)}: ${message}`;

    switch (level) {
      case LogLevel.ERROR:
        console.error(logMessage, context);
        break;
      case LogLevel.WARN:
        console.warn(logMessage, context);
        break;
      case LogLevel.INFO:
        if (!this.isProduction) {
          console.info(logMessage, context);
        }
        break;
      case LogLevel.DEBUG:
        if (!this.isProduction) {
          console.debug(logMessage, context);
        }
        break;
    }
  }

  private getLevelName(level: LogLevel): string {
    switch (level) {
      case LogLevel.ERROR:
        return 'ERROR';
      case LogLevel.WARN:
        return 'WARN';
      case LogLevel.INFO:
        return 'INFO';
      case LogLevel.DEBUG:
        return 'DEBUG';
      default:
        return 'UNKNOWN';
    }
  }

  error(message: string, context?: Record<string, any>) {
    this.log(this.formatLogEntry(LogLevel.ERROR, message, context));
  }

  warn(message: string, context?: Record<string, any>) {
    this.log(this.formatLogEntry(LogLevel.WARN, message, context));
  }

  info(message: string, context?: Record<string, any>) {
    this.log(this.formatLogEntry(LogLevel.INFO, message, context));
  }

  debug(message: string, context?: Record<string, any>) {
    this.log(this.formatLogEntry(LogLevel.DEBUG, message, context));
  }

  // 开发环境专用
  devLog(message: string, context?: Record<string, any>) {
    if (!this.isProduction) {
      console.log(`[DEV] ${message}`, context);
    }
  }
}

// 导出单例实例
export const logger = new Logger();

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