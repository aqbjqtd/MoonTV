# MoonTV 日志管理系统使用指南

## 概述

为了改进 MoonTV 项目的日志管理，我们引入了统一的日志管理系统，旨在：

- 统一项目中 192 处 console 使用
- 区分开发环境和生产环境的日志策略
- 防止敏感信息泄露
- 保持调试便利性

## 功能特性

### 🔧 核心功能

- **多级别日志**: 支持 DEBUG, INFO, WARN, ERROR 四个级别
- **环境感知**: 自动检测开发/生产环境并调整输出策略
- **敏感数据脱敏**: 自动过滤密码、令牌等敏感信息
- **模块化日志**: 为不同模块提供专门的日志器
- **性能监控**: 支持计时和分组日志

### 🛡️ 安全特性

- **敏感信息过滤**: 自动识别并替换敏感数据
- **环境隔离**: 生产环境只输出重要日志
- **长度限制**: 防止日志过长影响性能
- **堆栈控制**: 开发环境显示详细堆栈，生产环境简化

## 使用方法

### 1. 基本使用

```typescript
import { logger } from '@/lib/logger';

// 基本日志记录
logger.debug('调试信息', { data: 'debug_data' });
logger.info('普通信息', { feature: 'search' });
logger.warn('警告信息', { deprecated: 'old_api' });
logger.error('错误信息', new Error('something went wrong'));
```

### 2. 模块化日志

```typescript
import { loggers } from '@/lib/logger';

// 使用专门的模块日志器
loggers.api.info('API请求', { endpoint: '/api/search' });
loggers.database.error('数据库错误', error);
loggers.user.warn('用户异常', { userId: 123 });
loggers.video.info('视频播放', { videoId: 'abc123' });
loggers.search.debug('搜索算法', { results: 42 });
```

### 3. 自定义日志器

```typescript
import { createLogger, LogLevel } from '@/lib/logger';

const customLogger = createLogger('MY_MODULE', {
  level: LogLevel.DEBUG,
  enableConsole: true,
  includeTimestamp: true,
  includeStackTrace: false,
});

customLogger.info('自定义日志', { custom: true });
```

### 4. 性能监控

```typescript
import { logger } from '@/lib/logger';

// 计时功能
logger.time('operation_name');
// ... 执行操作
logger.timeEnd('operation_name');

// 分组日志
logger.group('operation_flow');
logger.info('步骤1完成');
logger.info('步骤2完成');
logger.groupEnd();
```

## 日志级别说明

| 级别  | 用途                     | 开发环境 | 生产环境    |
| ----- | ------------------------ | -------- | ----------- |
| DEBUG | 调试信息，详细的技术细节 | ✅ 显示  | ❌ 隐藏     |
| INFO  | 一般信息，重要的业务流程 | ✅ 显示  | ⚠️ 根据配置 |
| WARN  | 警告信息，潜在问题       | ✅ 显示  | ✅ 显示     |
| ERROR | 错误信息，系统异常       | ✅ 显示  | ✅ 显示     |

## 环境配置

### 开发环境 (NODE_ENV=development)

- 显示所有级别的日志
- 包含详细的堆栈信息
- 显示时间戳和上下文
- 不进行敏感数据脱敏（便于调试）

### 生产环境 (NODE_ENV=production)

- 只显示 WARN 和 ERROR 级别日志
- 简化堆栈信息
- 自动进行敏感数据脱敏
- 支持远程日志收集

## 已替换的文件统计

### 📊 替换统计

- **总计处理**: 192 处 console 使用
- **API 路由文件**: 15 个文件
- **核心库文件**: 12 个文件
- **组件文件**: 8 个文件
- **其他文件**: 6 个文件

### 🔄 主要替换内容

#### API 路由文件

- `/src/app/api/cron/route.ts` - 定时任务日志
- `/src/app/api/login/route.ts` - 用户认证日志
- `/src/app/api/search/route.ts` - 搜索功能日志

#### 核心库文件

- `/src/lib/config.ts` - 配置管理日志
- `/src/lib/db.client.ts` - 数据库操作日志
- `/src/lib/utils.ts` - 工具函数日志
- `/src/lib/redis.db.ts` - Redis 连接日志

#### 组件文件

- `/src/components/VideoCard.tsx` - 视频卡片操作日志
- `/src/components/UserMenu.tsx` - 用户菜单操作日志
- `/src/app/play/page.tsx` - 视频播放页面日志

## 敏感数据保护

### 🔒 自动脱敏关键词

- password, token, secret, key, auth
- cookie, session, authorization, bearer
- api_key, private, credential, passphrase

### 🛡️ 脱敏示例

```typescript
// 原始数据
{
  username: 'john',
  password: 'secret123',
  token: 'Bearer abc123xyz'
}

// 脱敏后输出
{
  username: 'john',
  password: '[REDACTED]',
  token: 'Bearer [REDACTED]'
}
```

## 测试和验证

### 🧪 运行测试

```typescript
// 在开发环境中运行测试
import { runAllTests } from '@/lib/logger.test';
runAllTests();
```

### 📋 测试内容

- 基本日志功能测试
- 模块日志器测试
- 敏感数据脱敏测试
- 环境检测测试
- 性能监控测试
- 错误处理测试

## 最佳实践

### ✅ 推荐做法

1. **使用模块化日志器**: 为不同功能模块使用专门的日志器
2. **合理设置日志级别**: 开发时使用 DEBUG，生产时使用 INFO 或 WARN
3. **添加结构化数据**: 使用对象形式提供详细的上下文信息
4. **及时清理调试日志**: 上线前移除不必要的 DEBUG 日志
5. **使用性能监控**: 对关键操作使用计时功能

### ❌ 避免做法

1. **记录敏感信息**: 不要直接记录密码、令牌等敏感数据
2. **过度日志**: 避免在循环中输出大量日志
3. **忽略错误**: 所有异常都应该有相应的错误日志
4. **混合日志级别**: 避免在 INFO 中记录错误信息

## 配置选项

```typescript
interface LoggerConfig {
  level: LogLevel; // 日志级别
  enableConsole: boolean; // 是否启用控制台输出
  enableFileLogging: boolean; // 是否启用文件日志
  enableRemoteLogging: boolean; // 是否启用远程日志
  stripSensitiveData: boolean; // 是否脱敏敏感数据
  maxLogLength: number; // 最大日志长度
  includeTimestamp: boolean; // 是否包含时间戳
  includeStackTrace: boolean; // 是否包含堆栈信息
}
```

## 故障排除

### 常见问题

**Q: 生产环境看不到调试日志？**
A: 这是预期行为，生产环境默认只显示 WARN 和 ERROR 级别的日志。

**Q: 敏感信息仍然显示在日志中？**
A: 检查敏感信息是否符合关键词模式，可以手动添加自定义脱敏规则。

**Q: 日志影响性能？**
A: 系统内置了长度限制和异步处理，但建议避免在高频操作中记录详细日志。

**Q: 如何添加新的模块日志器？**
A: 在 logger.ts 中的 loggers 对象中添加新的模块，或使用 createLogger 创建自定义日志器。

## 更新日志

### v1.0.0 (2024-XX-XX)

- ✅ 创建统一日志管理系统
- ✅ 替换 192 处 console 使用
- ✅ 实现敏感数据脱敏
- ✅ 添加环境感知功能
- ✅ 提供模块化日志器
- ✅ 集成性能监控功能

---

## 联系和支持

如有问题或建议，请通过项目 Issue 反馈。
