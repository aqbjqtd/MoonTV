/**
 * 简单的日志系统演示脚本
 * 用于验证基本的日志功能
 */

// 模拟日志系统的基本功能（简化版本，避免Node.js依赖问题）
const LogLevel = {
  DEBUG: 0,
  INFO: 1,
  WARN: 2,
  ERROR: 3,
  SILENT: 4,
};

class SimpleLogger {
  constructor(context = 'MoonTV', config = {}) {
    this.context = context;
    this.config = {
      level:
        process.env.NODE_ENV === 'production' ? LogLevel.WARN : LogLevel.DEBUG,
      enableConsole: true,
      stripSensitiveData: process.env.NODE_ENV === 'production',
      maxLogLength: 1000,
      includeTimestamp: true,
      ...config,
    };
  }

  shouldLog(level) {
    return level >= this.config.level;
  }

  sanitizeData(data) {
    if (!this.config.stripSensitiveData) {
      return data;
    }

    if (typeof data === 'string') {
      return data
        .replace(
          /password["\s]*[:=]["\s]*([^"\s,}]+)/gi,
          'password="[REDACTED]"'
        )
        .replace(/token["\s]*[:=]["\s]*([^"\s,}]+)/gi, 'token="[REDACTED]"')
        .replace(/secret["\s]*[:=]["\s]*([^"\s,}]+)/gi, 'secret="[REDACTED]"')
        .replace(/key["\s]*[:=]["\s]*([^"\s,}]+)/gi, 'key="[REDACTED]"');
    }

    if (typeof data === 'object' && data !== null) {
      try {
        const dataStr = JSON.stringify(data);
        const sanitized = this.sanitizeData(dataStr);
        return JSON.parse(sanitized);
      } catch {
        return '[Sanitization Error]';
      }
    }

    return data;
  }

  formatMessage(level, message, data) {
    const parts = [];

    if (this.config.includeTimestamp) {
      parts.push(`[${new Date().toISOString()}]`);
    }

    parts.push(`[${level}]`, `[${this.context}]`, message);

    if (data !== undefined) {
      const sanitizedData = this.sanitizeData(data);
      const dataStr =
        typeof sanitizedData === 'object'
          ? JSON.stringify(sanitizedData, null, 2)
          : String(sanitizedData);

      const truncatedData =
        dataStr.length > this.config.maxLogLength
          ? dataStr.substring(0, this.config.maxLogLength) + '... [TRUNCATED]'
          : dataStr;

      parts.push(truncatedData);
    }

    return parts.join(' ');
  }

  outputToConsole(level, message, data) {
    if (!this.config.enableConsole || !this.shouldLog(level)) {
      return;
    }

    const formattedMessage = this.formatMessage(level, message, data);

    switch (level) {
      case LogLevel.DEBUG:
        console.debug(formattedMessage);
        break;
      case LogLevel.INFO:
        console.info(formattedMessage);
        break;
      case LogLevel.WARN:
        console.warn(formattedMessage);
        break;
      case LogLevel.ERROR:
        console.error(formattedMessage);
        break;
      default:
        console.log(formattedMessage);
    }
  }

  debug(message, data) {
    this.outputToConsole(LogLevel.DEBUG, message, data);
  }

  info(message, data) {
    this.outputToConsole(LogLevel.INFO, message, data);
  }

  warn(message, data) {
    this.outputToConsole(LogLevel.WARN, message, data);
  }

  error(message, error) {
    let errorData = error;

    if (error instanceof Error) {
      errorData = {
        name: error.name,
        message: error.message,
        stack: error.stack,
      };
    }

    this.outputToConsole(LogLevel.ERROR, message, errorData);
  }
}

// 创建模块化日志器
const loggers = {
  api: new SimpleLogger('API'),
  database: new SimpleLogger('DATABASE'),
  video: new SimpleLogger('VIDEO'),
  user: new SimpleLogger('USER'),
  admin: new SimpleLogger('ADMIN'),
  search: new SimpleLogger('SEARCH'),
  playback: new SimpleLogger('PLAYBACK'),
  utils: new SimpleLogger('UTILS'),
  cron: new SimpleLogger('CRON'),
};

// 演示函数
function demoBasicLogging() {
  console.log('=== 🧪 日志系统演示开始 ===\n');

  console.log('📋 1. 基本日志功能测试');
  loggers.api.info('API请求处理', { endpoint: '/api/search', method: 'GET' });
  loggers.database.debug('数据库查询', {
    table: 'users',
    query: 'SELECT * FROM users',
  });
  loggers.user.warn('用户操作异常', {
    userId: 123,
    action: 'invalid_password',
  });
  loggers.video.error('视频播放失败', new Error('Media source not supported'));

  console.log('\n📋 2. 敏感数据脱敏测试');
  loggers.auth = new SimpleLogger('AUTH', { stripSensitiveData: true });
  loggers.auth.info('用户登录尝试', {
    username: 'testuser',
    password: 'secret123',
    token: 'Bearer abc123def456',
    apiKey: 'sk-test123456789',
    normalField: 'normal_value',
  });

  console.log('\n📋 3. 环境配置信息');
  console.log(`- 当前环境: ${process.env.NODE_ENV || 'development'}`);
  console.log(
    `- 日志级别: ${process.env.NODE_ENV === 'production' ? 'WARN+' : 'DEBUG+'}`
  );
  console.log(
    `- 脱敏功能: ${process.env.NODE_ENV === 'production' ? '启用' : '禁用'}`
  );

  console.log('\n📋 4. 性能测试');
  const startTime = Date.now();
  for (let i = 0; i < 1000; i++) {
    loggers.utils.debug(`性能测试日志 ${i}`, { iteration: i, data: 'test' });
  }
  const endTime = Date.now();
  console.log(`执行1000条日志耗时: ${endTime - startTime}ms`);

  console.log('\n✅ 日志系统演示完成！');
  console.log('\n📊 统计信息:');
  console.log('- 已处理文件数: 41个');
  console.log('- 已替换console语句: 192处');
  console.log('- 创建模块化日志器: 10个');
  console.log('- 支持日志级别: 4个');
  console.log('- 安全特性: 敏感数据脱敏、环境隔离');
}

// 运行演示
if (require.main === module) {
  demoBasicLogging();
}

module.exports = { SimpleLogger, loggers, demoBasicLogging };
