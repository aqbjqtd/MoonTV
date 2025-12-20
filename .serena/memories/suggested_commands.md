# MoonTV 常用命令参考

**记忆类型**: 命令参考  
**创建时间**: 2025-12-17  
**最后更新**: 2025-12-17  
**版本**: v1.0.0  
**重要性**: 高  
**相关记忆**: 开发规范, 运维指南, 项目概览  
**语义标签**: 命令参考, 快速开始, 开发命令, 运维命令  
**索引关键词**: pnpm, 构建命令, 测试命令, 代码质量, 部署命令

## 概述

MoonTV 项目开发、测试、构建和部署过程中常用的命令参考，为开发者提供快速查阅和使用的命令集合。

## 开发环境命令

### 环境设置

```bash
# 克隆项目
git clone https://github.com/stardm0/MoonTV.git
cd MoonTV

# 安装依赖 (推荐使用pnpm)
pnpm install

# 设置环境变量
cp .env.example .env.local
# 编辑 .env.local 文件配置必要的环境变量

# 启动开发服务器 (监听所有网络接口)
pnpm dev
# 访问: http://localhost:3000
```

### 代码生成和配置

```bash
# 生成PWA清单文件
pnpm gen:manifest

# 生成运行时配置
pnpm gen:runtime

# 启动开发服务器 (自动生成manifest和runtime)
pnpm dev
```

## 代码质量命令

### 代码检查

```bash
# ESLint代码检查
pnpm lint

# 自动修复代码问题
pnpm lint:fix

# 严格模式检查 (max-warnings=0)
pnpm lint:strict

# TypeScript类型检查
pnpm typecheck
```

### 代码格式化

```bash
# Prettier格式化代码
pnpm format

# 检查代码格式化
pnpm format:check
```

### 测试相关

```bash
# 运行Jest单元测试
pnpm test

# 测试监听模式
pnpm test:watch

# 生成测试覆盖率报告
pnpm test -- --coverage
```

## 构建和部署命令

### 构建命令

```bash
# 生产构建 (包含manifest和runtime生成)
pnpm build

# 启动生产服务器
pnpm start

# Cloudflare Pages构建
pnpm pages:build
```

### Docker 相关命令

```bash
# 构建Docker镜像
docker build -t moontv:latest .

# 运行容器 (LocalStorage模式)
docker run -d --name moontv -p 3000:3000 -e PASSWORD=your_password moontv:latest

# 运行容器 (Redis模式)
docker run -d --name moontv -p 3000:3000 \
  -e PASSWORD=your_password \
  -e NEXT_PUBLIC_STORAGE_TYPE=redis \
  -e REDIS_URL=redis://redis:6379 \
  --link redis:redis \
  moontv:latest

# 使用Docker Compose
docker-compose up -d
```

### 部署平台命令

```bash
# Vercel部署
vercel --prod

# Netlify部署
netlify deploy --prod
```

## Git 工作流程命令

### 标准 Git 操作

```bash
# 拉取最新代码
git pull origin main

# 创建功能分支
git checkout -b feature/new-feature

# 添加更改
git add .

# 提交更改 (遵循提交规范)
git commit -m "feat: 添加新功能"

# 推送分支
git push origin feature/new-feature

# 合并分支后同步上游
git fetch upstream
git merge upstream/main
```

### 提交规范

```bash
# 新功能
git commit -m "feat: 添加用户认证系统"

# Bug修复
git commit -m "fix: 修复播放进度同步问题"

# 文档更新
git commit -m "docs: 更新部署指南"

# 代码重构
git commit -m "refactor: 重构存储抽象层接口"

# 性能优化
git commit -m "perf: 优化搜索响应时间"

# 测试相关
git commit -m "test: 添加视频组件单元测试"

# 构建/配置更改
git commit -m "chore: 更新Docker构建配置"
```

## 运维和管理命令

### 系统检查

```bash
# 检查应用健康状态
curl -f http://localhost:3000/api/health

# 检查数据库连接
curl -f http://localhost:3000/api/health/db

# 检查Redis连接
curl -f http://localhost:3000/api/health/redis
```

### Redis 管理

```bash
# 连接Redis
redis-cli

# 查看Redis信息
redis-cli INFO

# 查看内存使用
redis-cli INFO memory

# 查看连接数
redis-cli INFO clients

# 清除所有数据 (谨慎使用)
redis-cli FLUSHALL

# 保存数据到磁盘
redis-cli SAVE
```

### 日志查看

```bash
# 查看应用日志
tail -100 /var/log/moontv/error.log

# 查看访问日志
tail -100 /var/log/moontv/access.log

# 实时查看日志
tail -f /var/log/moontv/error.log

# 查看Docker容器日志
docker logs moontv
```

## 项目管理和维护

### 依赖管理

```bash
# 查看过时的依赖
pnpm outdated

# 更新依赖
pnpm update

# 添加新依赖
pnpm add package-name

# 添加开发依赖
pnpm add -D package-name

# 移除依赖
pnpm remove package-name

# 清理node_modules
rm -rf node_modules
pnpm install
```

### 项目清理

```bash
# 清理构建缓存
rm -rf .next

# 清理node_modules
rm -rf node_modules

# 清理Docker构建缓存
docker builder prune -f

# 清理未使用的Docker镜像
docker image prune -f
```

## 故障排除命令

### 常见问题诊断

```bash
# 检查端口占用
netstat -tulpn | grep :3000
# 或 (Windows)
netstat -ano | findstr :3000

# 检查进程
ps aux | grep node
# 或 (Windows)
tasklist | findstr node

# 检查文件权限
ls -la

# 检查磁盘空间
df -h

# 检查内存使用
free -h
```

### 性能分析

```bash
# Node.js性能分析
node --prof app.js
node --prof-process isolate-0x*.log > processed.txt

# 内存分析
node --inspect app.js
# 然后在Chrome DevTools中分析内存

# 网络请求分析
curl -o /dev/null -s -w "Total: %{time_total}s\n" http://localhost:3000/
```

## Windows 特定命令

### 基础命令

```cmd
:: 列出目录内容
dir

:: 查看文件内容
type filename.txt

:: 复制文件
copy source.txt destination.txt

:: 移动文件
move source.txt destination.txt

:: 删除文件
del filename.txt

:: 创建目录
mkdir dirname

:: 删除目录
rmdir dirname /s
```

### Git 和 Node.js 命令

```cmd
:: Git命令与Unix/Linux相同
git status
git add .
git commit -m "message"

:: pnpm命令相同
pnpm install
pnpm dev
pnpm build

:: 检查Node.js版本
node --version

:: 检查pnpm版本
pnpm --version
```

## 快速参考表

### 日常开发流程

| 任务           | 命令             |
| -------------- | ---------------- |
| 启动开发服务器 | `pnpm dev`       |
| 代码检查       | `pnpm lint`      |
| 代码格式化     | `pnpm format`    |
| 类型检查       | `pnpm typecheck` |
| 运行测试       | `pnpm test`      |

### 构建和部署

| 任务           | 命令                                       |
| -------------- | ------------------------------------------ |
| 生产构建       | `pnpm build`                               |
| 启动生产服务器 | `pnpm start`                               |
| Docker 构建    | `docker build -t moontv:latest .`          |
| Docker 运行    | `docker run -d -p 3000:3000 moontv:latest` |

### 代码质量

| 任务             | 命令                                       |
| ---------------- | ------------------------------------------ |
| 完整代码质量检查 | `pnpm lint && pnpm typecheck && pnpm test` |
| 提交前检查       | `pnpm lint:fix && pnpm format`             |
| 严格模式检查     | `pnpm lint:strict`                         |

## 环境变量快速参考

### 必需变量

```bash
# 生产环境必须设置
PASSWORD=strong_password_123!
NEXT_PUBLIC_STORAGE_TYPE=localstorage|redis|upstash|d1

# Redis存储需要
REDIS_URL=redis://host:port

# Upstash存储需要
UPSTASH_URL=https://your-upstash-url.upstash.io
UPSTASH_TOKEN=your_token
```

### 常用配置

```bash
# 站点配置
NEXT_PUBLIC_SITE_NAME=MoonTV
NEXT_PUBLIC_ENABLE_REGISTER=false

# TVBox配置
TVBOX_ENABLED=true
TVBOX_PASSWORD=tvbox_password

# 豆瓣集成
NEXT_PUBLIC_DOUBAN_PROXY_TYPE=none|custom
```

## 提示和建议

### 开发效率提示

1. **使用 VS Code 扩展**: 安装 ESLint, Prettier, Tailwind CSS IntelliSense 扩展
2. **利用 Git Hooks**: 提交前自动运行代码检查和格式化
3. **使用调试器**: 利用 Node.js 调试工具进行问题诊断
4. **保持依赖更新**: 定期更新依赖包，注意兼容性

### 生产环境建议

1. **设置强密码**: 必须设置`PASSWORD`环境变量
2. **关闭用户注册**: 生产环境设置`NEXT_PUBLIC_ENABLE_REGISTER=false`
3. **启用监控**: 配置应用监控和日志收集
4. **定期备份**: 定期备份数据和配置文件

### 故障排除流程

1. 检查日志文件
2. 验证环境变量配置
3. 检查存储后端连接
4. 查看系统资源使用情况
5. 使用健康检查端点验证服务状态

## 更新历史

- 2025-12-17: 创建常用命令参考记忆文件，汇总所有开发、构建、部署和运维命令
- 2025-12-12: 基于现有开发规范和运维指南整理
- 2025-12-09: 集成最新构建和部署命令
- 2025-10-15: 建立基础命令参考框架
