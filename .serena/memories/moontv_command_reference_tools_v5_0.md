# MoonTV 命令参考手册

**版本**: v4.1
**更新日期**: 2025-10-09
**分类**: 项目管理

## 🚀 开发命令

### 基础开发

```bash
# 开发服务器启动
pnpm dev                          # 启动开发服务器 (0.0.0.0:3000)
pnpm dev --port 3001              # 指定端口启动
pnpm dev --hostname 0.0.0.0      # 指定主机启动
pnpm dev --turbo                  # Turbo 模式启动 (更快)

# 生产构建和启动
pnpm build                        # 生产环境构建
pnpm start                        # 启动生产服务器
pnpm build && pnpm start          # 构建并启动

# 代码质量检查
pnpm lint                         # 运行 ESLint 检查
pnpm lint:fix                     # 自动修复 ESLint 问题 + 格式化
pnpm typecheck                    # TypeScript 类型检查
pnpm format                       # Prettier 格式化所有文件

# 测试命令
pnpm test                         # 运行所有测试
pnpm test:watch                   # 测试监视模式
pnpm test --coverage              # 生成测试覆盖率报告
```

### 实用工具命令

```bash
# 生成配置文件
pnpm gen:manifest                 # 生成 PWA manifest.json
pnpm gen:runtime                  # 生成运行时配置从 config.json

# Cloudflare Pages 构建
pnpm pages:build                  # 构建用于 Cloudflare Pages 部署

# 依赖管理
pnpm outdated                     # 检查过期依赖
pnpm update                       # 更新所有依赖
pnpm update --latest              # 更新到最新版本
pnpm update -i                    # 交互式更新
```

## 🐳 Docker 命令

### 构建命令

```bash
# 标准构建
docker build -t moontv:v4.1.0 .                  # 标准四阶段构建
docker build -t moontv:latest .                  # 构建最新版本
docker build -t moontv:dev .                     # 构建开发版本

# 优化构建 (推荐)
./scripts/docker-build-optimized.sh -t v4.1.0    # 优化构建脚本
./scripts/docker-build-optimized.sh -t production # 生产环境构建
./scripts/docker-build-optimized.sh -t test      # 测试镜像构建

# 多架构构建
docker buildx build --platform linux/amd64,linux/arm64 -t moontv:multi-arch .
./scripts/docker-build-optimized.sh --multi-arch --push -t v4.1.0

# 构建缓存管理
docker builder prune                                 # 清理构建缓存
docker buildx prune                                 # 清理 BuildKit 缓存
```

### 运行命令

```bash
# 基础运行
docker run -d -p 3000:3000 --name moontv moontv:v4.1.0

# 生产环境运行 (推荐配置)
docker run -d \
  -p 3000:3000 \
  -e PASSWORD=yourpassword \
  -e NEXT_PUBLIC_STORAGE_TYPE=redis \
  -e REDIS_URL=redis://redis:6379 \
  -v moontv_data:/app/data \
  --name moontv \
  moontv:v4.1.0

# 测试镜像运行
docker run -d -p 3000:3000 \
  -e PASSWORD=yourpassword \
  --name moontv-test \
  moontv:test

# 开发环境运行
docker run -d \
  -p 3000:3000 \
  -e NODE_ENV=development \
  -e NEXT_PUBLIC_STORAGE_TYPE=localstorage \
  -v $(pwd):/app \
  --name moontv-dev \
  moontv:dev
```

### 容器管理

```bash
# 容器状态管理
docker ps                              # 查看运行中的容器
docker ps -a                          # 查看所有容器
docker logs moontv                    # 查看容器日志
docker logs -f moontv                 # 实时查看日志
docker stats moontv                   # 查看容器资源使用

# 容器操作
docker stop moontv                    # 停止容器
docker start moontv                   # 启动容器
docker restart moontv                 # 重启容器
docker rm moontv                      # 删除容器

# 进入容器
docker exec -it moontv /bin/sh        # 进入容器 (生产环境)
docker exec -it moontv-dev /bin/bash  # 进入容器 (开发环境)
```

## 🔄 Git 命令

### 基础操作

```bash
# 状态查看
git status                            # 查看工作区状态
git branch                            # 查看当前分支
git log --oneline -10                 # 查看最近10次提交
git diff                              # 查看未暂存的变更
git diff --staged                    # 查看已暂存的变更

# 分支管理
git checkout -b feature/new-feature   # 创建并切换到新分支
git checkout main                     # 切换到主分支
git merge feature/new-feature         # 合并分支
git branch -d feature/new-feature     # 删除本地分支

# 提交操作
git add .                             # 添加所有变更到暂存区
git add src/components/              # 添加特定目录
git commit -m "feat: 添加新功能"      # 提交变更
git commit -m "fix: 修复问题"         # 修复提交
git commit -m "docs: 更新文档"        # 文档提交
```

### 标签管理

```bash
# 创建标签
git tag -a v4.1.0 -m "发布版本 v4.1.0"     # 创建附注标签
git tag -f dev -m "开发版本更新"            # 更新开发版本标签
git tag -a v4.1.0-test -m "测试版本"       # 创建测试版本标签

# 查看标签
git tag                                    # 查看所有标签
git show v4.1.0                            # 查看标签详情
git log --oneline --decorate --graph       # 查看提交历史和标签

# 推送标签
git push origin v4.1.0                     # 推送特定标签
git push origin --tags                     # 推送所有标签
git push origin -f dev                     # 强制推送开发版本标签

# 删除标签
git tag -d v4.1.0                          # 删除本地标签
git push origin --delete v4.1.0            # 删除远程标签
```

### 高级操作

```bash
# 撤销操作
git reset --soft HEAD~1                  # 撤销最后一次提交 (保留更改)
git reset --hard HEAD~1                  # 撤销最后一次提交 (丢弃更改)
git checkout -- src/components/File.tsx  # 撤销文件更改

# 储存和恢复
git stash                               # 储存当前工作
git stash pop                           # 恢复储存的工作
git stash list                          # 查看储存列表

# 变基操作
git rebase main                         # 变基到主分支
git rebase -i HEAD~3                   # 交互式变基 (修改提交历史)
```

## 🔧 环境变量配置

### 开发环境配置

```bash
# .env.local (开发环境)
NODE_ENV=development
PORT=3000
HOSTNAME=0.0.0.0

# 存储配置
NEXT_PUBLIC_STORAGE_TYPE=localstorage

# 认证配置
PASSWORD=admin123
USERNAME=admin

# 站点配置
NEXT_PUBLIC_SITE_NAME=MoonTV Dev
NEXT_PUBLIC_SEARCH_MAX_PAGE=5

# 调试配置
NEXT_PUBLIC_DEBUG=true
NEXT_PUBLIC_LOG_LEVEL=debug
```

### 生产环境配置

```bash
# .env.production (生产环境)
NODE_ENV=production
PORT=3000

# 存储配置 (生产推荐)
NEXT_PUBLIC_STORAGE_TYPE=redis
REDIS_URL=redis://redis:6379

# 认证配置
PASSWORD=your-secure-password
USERNAME=admin
NEXT_PUBLIC_ENABLE_REGISTER=false

# 站点配置
NEXT_PUBLIC_SITE_NAME=MoonTV
NEXT_PUBLIC_SEARCH_MAX_PAGE=10

# Docker 环境
DOCKER_ENV=true
TZ=Asia/Shanghai
```

### 完整环境变量列表

```bash
# 基础配置
NODE_ENV                          # 环境模式 (development/production)
PORT                              # 应用端口 (默认: 3000)
HOSTNAME                          # 绑定主机 (开发环境: 0.0.0.0)

# 存储配置
NEXT_PUBLIC_STORAGE_TYPE          # 存储类型 (localstorage/redis/upstash/d1)
REDIS_URL                         # Redis 连接 URL
UPSTASH_URL                       # Upstash Redis URL
UPSTASH_TOKEN                     # Upstash Redis Token

# 认证配置
PASSWORD                          # 管理员密码 (必需)
USERNAME                          # 管理员用户名 (非-localstorage 模式)
NEXT_PUBLIC_ENABLE_REGISTER       # 允许用户注册 (true/false)

# 站点配置
NEXT_PUBLIC_SITE_NAME             # 站点显示名称
NEXT_PUBLIC_SEARCH_MAX_PAGE       # 搜索最大页数

# Docker 配置
DOCKER_ENV                        # Docker 环境标识 (true/false)
TZ                                # 时区设置 (如: Asia/Shanghai)

# 调试配置
NEXT_PUBLIC_DEBUG                 # 调试模式 (true/false)
NEXT_PUBLIC_LOG_LEVEL             # 日志级别 (debug/info/warn/error)
```

## 🐛 调试命令

### 应用调试

```bash
# 开发调试
pnpm dev:debug                     # 启动调试模式开发服务器
NODE_OPTIONS='--inspect' pnpm dev  # 启动 Node.js 调试

# 构建调试
pnpm build:debug                   # 启用详细日志的构建
ANALYZE=true pnpm build           # 构建包分析

# 测试调试
pnpm test:debug                    # 启用调试模式的测试
pnpm test --verbose                # 详细测试输出
```

### Docker 调试

```bash
# 构建调试
docker build --no-cache -t moontv:debug .    # 无缓存构建
docker build --progress=plain -t moontv .    # 详细构建日志

# 运行调试
docker run -it --entrypoint /bin/sh moontv  # 交互式容器
docker run --rm -p 3000:3000 moontv:debug    # 调试版本运行

# 日志调试
docker logs --tail 100 moontv                 # 查看最近100行日志
docker logs --since 1h moontv                 # 查看最近1小时日志
docker logs --until 1h moontv                 # 查看1小时前的日志
```

### 网络调试

```bash
# 端口检查
netstat -tulpn | grep :3000          # 检查端口占用
lsof -i :3000                        # 查看端口使用进程

# 连接测试
curl -I http://localhost:3000        # 测试 HTTP 连接
curl http://localhost:3000/api/health # 测试健康检查端点

# Docker 网络
docker network ls                     # 查看网络列表
docker network inspect bridge        # 查看网络详情
```

## 📊 监控命令

### 系统监控

```bash
# 资源监控
docker stats moontv                   # 容器资源使用监控
docker stats --no-stream             # 非实时资源使用
docker top moontv                     # 容器进程监控

# 日志监控
docker logs -f --tail 50 moontv       # 实时日志监控 (最近50行)
docker logs --since 1h -f moontv      # 最近1小时实时日志

# 健康检查
curl -f http://localhost:3000/api/health || echo "Health check failed"
```

### 性能分析

```bash
# 应用性能分析
pnpm build && pnpm start              # 启动生产环境
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:3000

# 包大小分析
pnpm analyze                          # 分析包大小 (需要配置)
npx webpack-bundle-analyzer .next    # Webpack 包分析

# Lighthouse 性能测试
npx lighthouse http://localhost:3000 --output html --output-path ./lighthouse-report.html
```

## 🛠️ 维护命令

### 清理命令

```bash
# 系统清理
pnpm store prune                      # 清理 pnpm 存储缓存
rm -rf .next                          # 清理 Next.js 构建缓存
rm -rf node_modules                   # 清理依赖
pnpm install                          # 重新安装依赖

# Docker 清理
docker system prune -f                # 清理未使用的 Docker 资源
docker volume prune -f                # 清理未使用的卷
docker network prune -f               # 清理未使用的网络
```

### 备份和恢复

```bash
# 数据备份
docker exec moontv tar czf /tmp/backup.tar.gz /app/data
docker cp moontv:/tmp/backup.tar.gz ./backup-$(date +%Y%m%d).tar.gz

# 配置备份
cp .env.local .env.local.backup.$(date +%Y%m%d)
cp config.json config.json.backup.$(date +%Y%m%d)

# Git 备份
git push origin --all                  # 推送所有分支
git push origin --tags                # 推送所有标签
```

## 🔄 工作流命令

### 开发工作流

```bash
# 1. 开始新功能开发
git checkout -b feature/new-feature
pnpm dev
# ... 开发工作 ...

# 2. 代码检查和提交
pnpm lint:fix
pnpm typecheck
pnpm test
git add .
git commit -m "feat: 添加新功能"

# 3. 部署测试
docker build -t moontv:test .
docker run -d -p 3001:3000 --name moontv-test moontv:test
# ... 测试验证 ...

# 4. 合并和清理
git checkout main
git merge feature/new-feature
git branch -d feature/new-feature
docker stop moontv-test
docker rm moontv-test
```

### 发布工作流

```bash
# 1. 准备发布
pnpm build
pnpm test
git status

# 2. 构建生产镜像
./scripts/docker-build-optimized.sh -t v4.1.0

# 3. 标签和推送
git tag -a v4.1.0 -m "发布版本 v4.1.0"
git push origin main
git push origin v4.1.0

# 4. 部署验证
docker run -d -p 3000:3000 --name moontv-prod moontv:v4.1.0
curl http://localhost:3000/api/health
```

## 📝 故障排除命令

### 常见问题解决

```bash
# 端口被占用
lsof -ti:3000 | xargs kill -9         # 强制结束占用3000端口的进程

# 依赖问题
rm -rf node_modules pnpm-lock.yaml
pnpm install

# 构建问题
rm -rf .next
pnpm build

# Docker 问题
docker system prune -f
docker build --no-cache -t moontv .

# 权限问题
sudo chown -R $USER:$USER .next
sudo chown -R $USER:$USER node_modules
```

### 日志分析

```bash
# 应用日志
docker logs moontv 2>&1 | grep ERROR    # 查看错误日志
docker logs moontv | tail -100          # 查看最近100行日志

# 系统日志
journalctl -u docker.service           # Docker 服务日志
dmesg | grep -i memory                 # 内存相关系统日志

# Git 日志
git log --oneline --grep="fix"          # 查看修复相关的提交
git log --stat --author="username"      # 查看特定作者的提交统计
```

---

**最后更新**: 2025-10-09
**适用版本**: MoonTV v4.1
**维护状态**: ✅ 活跃维护
**文档分类**: 项目管理 - 命令参考
