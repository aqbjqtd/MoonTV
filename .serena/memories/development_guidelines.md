# MoonTV 开发指导原则

## 开发环境配置

### 必要环境
- Node.js 20+
- pnpm 10.14.0 (推荐包管理器)
- Docker (可选，用于容器化部署)

### 核心命令速查
```bash
# 启动开发服务器
pnpm dev

# 构建生产版本
pnpm build

# 代码质量检查
pnpm lint && pnpm typecheck

# 运行测试
pnpm test

# Docker构建
docker build -t moontv .
```

## 代码约定

### TypeScript规范
- 启用严格模式 (strict: true)
- 使用路径别名: @/* (src), ~/* (public)
- 优先使用 interface 而非 type (除非需要联合类型)
- 避免使用 any，优先使用 unknown 或具体类型

### React组件规范
- 使用函数组件 + Hooks
- 组件名使用 PascalCase
- 文件名使用 kebab-case 或 PascalCase (组件)
- Props接口以组件名 + Props 结尾

### 样式规范
- 优先使用 Tailwind CSS 类
- 组件特定样式使用 CSS Modules 或 styled-components
- 支持暗黑模式，使用 Tailwind 的 dark: 前缀
- 响应式设计：移动端优先

## 架构开发原则

### 存储抽象层
- 所有数据库操作通过 DbManager 类
- 使用 getStorage() 获取存储实例
- 不要直接操作具体的存储后端
- 新增存储后端需实现 IStorage 接口

### 配置管理
- 使用 getConfig() 获取运行时配置
- 环境变量优先级：环境变量 > 数据库配置 > 文件配置
- 配置变更需要考虑不同存储后端的兼容性
- Docker环境特殊处理：DOCKER_ENV=true

### API开发
- 所有API路由使用 Edge Runtime
- 统一错误处理和响应格式
- 认证检查使用中间件或工具函数
- 支持流式响应（搜索API）

### 认证系统
- LocalStorage模式：密码直接验证
- 数据库模式：HMAC签名验证
- 用户角色：owner/admin/user
- 权限检查在每个API路由中进行

## 测试策略

### 单元测试
- 工具函数：100%覆盖率
- React组件：关键交互测试
- API路由：正常和异常情况测试
- 配置加载：不同环境配置测试

### 集成测试
- 用户注册登录流程
- 搜索和播放流程
- 数据同步功能
- 管理员操作

## 部署注意事项

### 环境变量
- PASSWORD: 必需，管理员密码
- NEXT_PUBLIC_STORAGE_TYPE: 存储后端类型
- USERNAME: 数据库模式下的管理员用户名
- UPSTASH_URL/UPSTASH_TOKEN: Upstash Redis配置

### Docker部署
- 使用多阶段构建优化镜像大小
- 非root用户运行
- 动态配置文件读取
- Edge Runtime适配

### Vercel部署
- Edge Runtime兼容性
- 环境变量配置
- 自动构建触发
- 域名绑定

## 性能优化建议

### 前端优化
- 使用 Next.js Image 组件优化图片
- 实现组件懒加载
- 优化bundle大小
- 利用PWA缓存

### 后端优化
- API响应缓存
- 数据库查询优化
- 并发请求处理
- Edge Runtime利用

## 安全最佳实践

### 认证安全
- 始终验证用户身份
- 使用HMAC签名防篡改
- 实施防重放攻击机制
- 定期更新密码策略

### API安全
- 输入参数验证
- SQL注入防护
- XSS防护
- CSRF保护

### 数据保护
- 敏感数据加密存储
- 安全的密钥管理
- 数据传输加密
- 访问日志记录

## 故障排查指南

### 常见问题
1. **配置加载失败**: 检查环境变量和存储后端
2. **认证失败**: 验证密码和签名逻辑
3. **播放问题**: 检查视频源和网络连接
4. **数据库连接**: 验证连接字符串和权限

### 调试技巧
- 使用浏览器开发工具
- 检查网络请求和响应
- 查看控制台错误信息
- 使用 Next.js 调试模式

## 贡献指南

### 代码提交
- 使用语义化提交信息
- 确保所有测试通过
- 代码质量检查通过
- 更新相关文档

### 功能开发
1. 创建功能分支
2. 实现功能并测试
3. 更新文档
4. 提交Pull Request

### Bug修复
1. 复现问题
2. 定位根本原因
3. 修复并测试
4. 添加回归测试

## 工具和资源

### 开发工具
- VS Code + 相关插件
- Git客户端
- Docker Desktop
- 浏览器开发工具

### 有用链接
- Next.js 官方文档
- Tailwind CSS 文档
- TypeScript 手册
- 项目仓库地址

## 联系和支持

- 项目维护者：查看提交历史
- 问题反馈：GitHub Issues
- 技术讨论：项目讨论区
- 文档更新：提交Pull Request