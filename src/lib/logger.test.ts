/**
 * 日志系统测试文件
 * 用于验证统一日志管理工具的功能和效果
 */

import {
  createLogger,
  isDevelopment,
  isProduction,
  logger,
  loggers,
  LogLevel,
} from './logger';

// 测试基本日志功能
export function testBasicLogging() {
  console.log('=== 测试基本日志功能 ===');

  // 测试不同级别的日志
  logger.debug('这是一个调试消息', { userId: 123, action: 'login' });
  logger.info('这是一个信息消息', { feature: 'search', query: 'test' });
  logger.warn('这是一个警告消息', { deprecated: 'old_api', version: '1.0' });
  logger.error('这是一个错误消息', new Error('测试错误'));

  console.log('基本日志功能测试完成\n');
}

// 测试不同模块的日志器
export function testModuleLoggers() {
  console.log('=== 测试模块日志器 ===');

  loggers.api.info('API请求处理', { endpoint: '/api/search', method: 'GET' });
  loggers.database.error('数据库连接失败', new Error('Connection timeout'));
  loggers.user.warn('用户操作异常', {
    userId: 456,
    action: 'invalid_password',
  });
  loggers.video.info('视频播放开始', { videoId: 'abc123', quality: '1080p' });
  loggers.search.debug('搜索算法执行', { algorithm: 'tfidf', results: 42 });

  console.log('模块日志器测试完成\n');
}

// 测试自定义日志器
export function testCustomLogger() {
  console.log('=== 测试自定义日志器 ===');

  const customLogger = createLogger('CUSTOM_MODULE', {
    level: LogLevel.DEBUG,
    enableConsole: true,
    includeTimestamp: true,
    includeStackTrace: false,
  });

  customLogger.info('自定义日志器测试', { custom: true });
  customLogger.debug('调试信息', { debug_data: { nested: { value: 42 } } });

  console.log('自定义日志器测试完成\n');
}

// 测试敏感数据脱敏
export function testDataSanitization() {
  console.log('=== 测试敏感数据脱敏 ===');

  // 测试包含敏感信息的数据
  const sensitiveData = {
    username: 'testuser',
    password: 'secret123',
    token: 'Bearer abc123def456',
    apiKey: 'sk-test123456789',
    normalField: 'normal_value',
  };

  logger.info('包含敏感数据的日志', sensitiveData);

  // 测试字符串形式的敏感信息
  const sensitiveString =
    'User password=secret123 and token=Bearer xyz789 logged in';
  logger.warn('敏感信息字符串', sensitiveString);

  console.log('敏感数据脱敏测试完成\n');
}

// 测试环境检测
export function testEnvironmentDetection() {
  console.log('=== 测试环境检测 ===');

  console.log(
    `当前环境: ${
      isDevelopment ? '开发环境' : isProduction ? '生产环境' : '其他环境'
    }`
  );
  console.log(`日志级别: ${LogLevel[logger.getLevel()]}`);

  if (isDevelopment) {
    logger.debug('开发环境 - 调试信息可见');
  }

  if (isProduction) {
    logger.info('生产环境 - 只显示重要信息');
  }

  console.log('环境检测测试完成\n');
}

// 测试性能计时功能
export function testPerformanceLogging() {
  console.log('=== 测试性能计时功能 ===');

  logger.time('性能测试');

  // 模拟一些耗时操作
  setTimeout(() => {
    logger.timeEnd('性能测试');
    console.log('性能计时测试完成\n');
  }, 100);
}

// 测试分组日志
export function testGroupLogging() {
  console.log('=== 测试分组日志 ===');

  logger.group('用户操作流程');
  logger.info('用户登录', { userId: 123 });
  logger.info('验证权限', { role: 'admin' });
  logger.info('加载用户数据', { dataCount: 50 });
  logger.groupEnd();

  console.log('分组日志测试完成\n');
}

// 测试错误对象处理
export function testErrorHandling() {
  console.log('=== 测试错误对象处理 ===');

  try {
    // 故意抛出错误
    throw new Error('这是一个测试错误');
  } catch (error) {
    logger.error('捕获到异常', error);
  }

  // 测试自定义错误
  const customError = {
    name: 'ValidationError',
    message: '参数验证失败',
    code: 'VALIDATION_ERROR',
    details: { field: 'email', value: 'invalid-email' },
  };

  logger.error('自定义错误', customError);

  console.log('错误处理测试完成\n');
}

// 运行所有测试
export function runAllTests() {
  console.log('🧪 开始日志系统测试...\n');

  testBasicLogging();
  testModuleLoggers();
  testCustomLogger();
  testDataSanitization();
  testEnvironmentDetection();
  testPerformanceLogging();
  testGroupLogging();
  testErrorHandling();

  console.log('✅ 所有日志系统测试完成！');

  // 显示日志配置信息
  console.log('\n📋 当前日志配置:');
  console.log(`- 环境检测: 开发=${isDevelopment}, 生产=${isProduction}`);
  console.log(`- 默认日志级别: ${LogLevel[logger.getLevel()]}`);
  console.log(`- 支持的日志器: ${Object.keys(loggers).join(', ')}`);
}

// 如果直接运行此文件，执行所有测试
if (typeof window === 'undefined' && require.main === module) {
  runAllTests();
}

export default {
  runAllTests,
  testBasicLogging,
  testModuleLoggers,
  testCustomLogger,
  testDataSanitization,
  testEnvironmentDetection,
  testPerformanceLogging,
  testGroupLogging,
  testErrorHandling,
};
