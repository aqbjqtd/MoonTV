/**
 * 日志系统测试
 */

import {
  logger,
  ErrorHandler,
  PerformanceMonitor,
  LogLevel,
} from '../lib/logger';

// Mock fetch
global.fetch = jest.fn().mockResolvedValue({
  ok: true,
  status: 200,
  statusText: 'OK',
});

// Mock window environment
(global as any).window = {
  navigator: {
    userAgent: 'Mozilla/5.0 Test',
  },
  location: {
    href: 'http://localhost:3000',
  },
};

describe('Logger Tests', () => {
  beforeEach(() => {
    // Clear logs before each test
    logger.clearLogs();
  });

  test('基础日志功能', () => {
    logger.debug('Debug message', { debug: true });
    logger.info('Info message', { info: true });
    logger.warn('Warning message', { warn: true });
    logger.error('Error message', new Error('Test error'), { error: true });

    const logs = logger.getLogs();
    expect(logs).toHaveLength(4);
    expect(logs[0].message).toBe('Debug message');
    expect(logs[1].message).toBe('Info message');
    expect(logs[2].message).toBe('Warning message');
    expect(logs[3].message).toBe('Error message');
  });

  test('性能日志功能', () => {
    logger.performance('test-operation', 150, { operation: 'test' });

    const logs = logger.getLogs();
    expect(logs).toHaveLength(1);
    expect(logs[0].message).toBe('Performance: test-operation');
    expect(logs[0].context?.duration).toBe(150);
  });

  test('API请求日志功能', () => {
    logger.apiRequest('GET', '/api/test', 250, 200, { endpoint: 'test' });
    logger.apiRequest('POST', '/api/error', 500, 500, { endpoint: 'error' });

    const logs = logger.getLogs();
    expect(logs).toHaveLength(2);
    expect(logs[0].message).toBe('API Request: GET /api/test');
    expect(logs[0].context?.statusCode).toBe(200);
    expect(logs[1].message).toBe('API Request: POST /api/error');
    expect(logs[1].context?.statusCode).toBe(500);
  });

  test('用户操作日志功能', () => {
    logger.userAction('登录', 'user123', { action: 'login' });
    logger.userAction('搜索视频', 'user456', { query: 'test' });

    const logs = logger.getLogs();
    expect(logs).toHaveLength(2);
    expect(logs[0].message).toBe('User Action: 登录');
    expect(logs[0].context?.userId).toBe('user123');
    expect(logs[1].message).toBe('User Action: 搜索视频');
  });

  test('安全事件日志功能', () => {
    logger.security('登录尝试失败', { ip: '127.0.0.1' });
    logger.security('可疑操作', { user: 'user789' });

    const logs = logger.getLogs();
    expect(logs).toHaveLength(2);
    expect(logs[0].message).toBe('Security Event: 登录尝试失败');
    expect(logs[0].context?.security).toBe(true);
  });

  test('日志统计功能', () => {
    logger.debug('Debug message');
    logger.info('Info message 1');
    logger.info('Info message 2');
    logger.warn('Warning message');
    logger.error('Error message');

    const stats = logger.getStats();
    expect(stats.total).toBe(5);
    expect(stats.byLevel.debug).toBe(1);
    expect(stats.byLevel.info).toBe(2);
    expect(stats.byLevel.warn).toBe(1);
    expect(stats.byLevel.error).toBe(1);
    expect(stats.byLevel.fatal).toBe(0);
  });

  test('日志级别过滤', () => {
    logger.debug('Debug message');
    logger.info('Info message');
    logger.warn('Warning message');
    logger.error('Error message');

    const errorLogs = logger.getLogs(LogLevel.ERROR);
    expect(errorLogs).toHaveLength(1);
    expect(errorLogs[0].message).toBe('Error message');

    const warnLogs = logger.getLogs(LogLevel.WARN);
    expect(warnLogs).toHaveLength(2);
  });

  test('日志限制功能', () => {
    // Create new logger instance with small max size
    const { Logger } = require('../lib/logger');
    const testLogger = new Logger({ maxLogSize: 3, module: 'TestLogger' });

    testLogger.info('Message 1');
    testLogger.info('Message 2');
    testLogger.info('Message 3');
    testLogger.info('Message 4'); // Should remove oldest

    const logs = testLogger.getLogs();
    expect(logs).toHaveLength(3);
    expect(logs[0].message).toBe('Message 2'); // First message should be removed
  });
});

describe('ErrorHandler Tests', () => {
  test('同步错误处理', async () => {
    const result = ErrorHandler.handleError(
      () => {
        throw new Error('Sync error');
      },
      { operation: 'sync_test' },
    );

    expect(result.success).toBe(false);
    expect(result.error).toBeInstanceOf(Error);
    expect(result.error?.message).toBe('Sync error');
  });

  test('异步错误处理', async () => {
    const result = await ErrorHandler.handleAsyncError(
      async () => {
        throw new Error('Async error');
      },
      { operation: 'async_test' },
    );

    expect(result.success).toBe(false);
    expect(result.error).toBeInstanceOf(Error);
    expect(result.error?.message).toBe('Async error');
  });

  test('成功操作处理', async () => {
    const result = ErrorHandler.handleError(
      () => {
        return 'success';
      },
      { operation: 'success_test' },
    );

    expect(result.success).toBe(true);
    expect(result.data).toBe('success');
  });

  test('重试机制', async () => {
    let attemptCount = 0;
    const result = await ErrorHandler.retry(
      async () => {
        attemptCount++;
        if (attemptCount < 3) {
          throw new Error(`Attempt ${attemptCount}`);
        }
        return 'success';
      },
      5,
      10,
      { operation: 'retry_test' },
    );

    expect(result).toBe('success');
    expect(attemptCount).toBe(3);
  });

  test('创建错误对象', () => {
    const error = ErrorHandler.createError('Custom error', 'CUSTOM_CODE', {
      context: 'test',
    });

    expect(error).toBeInstanceOf(Error);
    expect(error.message).toBe('Custom error');
    expect(error.code).toBe('CUSTOM_CODE');
    expect(error.context).toEqual({ context: 'test' });
  });
});

describe('PerformanceMonitor Tests', () => {
  test('计时器功能', () => {
    PerformanceMonitor.startTimer('test-timer');
    const duration = PerformanceMonitor.endTimer('test-timer');

    expect(duration).toBeGreaterThanOrEqual(0);
  });

  test('未启动的计时器', () => {
    const duration = PerformanceMonitor.endTimer('non-existent-timer');
    expect(duration).toBe(0);
  });

  test('同步操作测量', () => {
    const result = PerformanceMonitor.measure('sync-operation', () => {
      let sum = 0;
      for (let i = 0; i < 1000; i++) {
        sum += i;
      }
      return sum;
    });

    expect(result.result).toBeGreaterThan(0);
    expect(result.duration).toBeGreaterThanOrEqual(0);
  });

  test('异步操作测量', async () => {
    const result = await PerformanceMonitor.measureAsync(
      'async-operation',
      async () => {
        await new Promise((resolve) => setTimeout(resolve, 10));
        return 'async-result';
      },
    );

    expect(result.result).toBe('async-result');
    expect(result.duration).toBeGreaterThanOrEqual(10);
  });
});
