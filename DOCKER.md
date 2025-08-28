# MoonTV Docker 部署指南

## 🐳 Docker 镜像构建

### 1. 拉取镜像
```bash
docker pull aqbjqtd/moontv:latest
```

### 2. 运行容器
```bash
docker run -d \
  --name moontv \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e DOCKER_ENV=true \
  aqbjqtd/moontv:latest
```

### 3. 使用 Docker Compose（推荐）
```bash
# 启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 4. 本地构建（可选）
如需从源码构建：
```bash
docker build -t moontv:latest .
```

## 📋 配置说明

### 环境变量
- `NODE_ENV=production`: 生产环境模式
- `DOCKER_ENV=true`: Docker环境标识
- `HOSTNAME=0.0.0.0`: 监听所有接口
- `PORT=3000`: 应用端口

### 依赖服务
- **Redis**: 可选，用于缓存和会话存储
- **端口映射**: 3000:3000 (主机:容器)

## 🔧 项目特性

### 已配置的 Docker 优化
- ✅ 多阶段构建，减小镜像体积
- ✅ 使用 Alpine Linux 基础镜像
- ✅ 非特权用户运行
- ✅ 自动处理 Edge Runtime → Node Runtime
- ✅ 强制动态渲染以支持环境变量
- ✅ 健康检查配置
- ✅ 自动启动脚本和定时任务

### 项目技术栈
- **框架**: Next.js 14.2.30
- **语言**: TypeScript
- **包管理**: pnpm
- **样式**: Tailwind CSS
- **数据库**: Redis (可选)
- **PWA**: 支持

## 🚀 访问应用

启动成功后，访问 http://localhost:3000

## 📦 镜像信息

- **仓库地址**: `docker.io/aqbjqtd/moontv`
- **镜像标签**: `latest`, `v1.1.1`
- **镜像大小**: 278MB
- **基础镜像**: node:20-alpine
- **支持架构**: linux/amd64, linux/arm64

## 🌟 可用版本

- `aqbjqtd/moontv:latest` - 最新稳定版

## 📝 注意事项

1. **首次构建**: 依赖下载可能需要较长时间
2. **端口占用**: 确保3000端口未被占用
3. **Redis**: 如需Redis功能，请使用docker-compose启动
4. **配置文件**: 确保config.json配置正确

## 🔍 故障排除

### 构建失败
```bash
# 清理Docker缓存
docker builder prune

# 重新构建
docker build --no-cache -t moontv:latest .
```

### 容器启动失败
```bash
# 查看容器日志
docker logs moontv

# 检查容器状态
docker ps -a
```

### 端口冲突
修改docker-compose.yml中的端口映射：
```yaml
ports:
  - "8080:3000"  # 使用8080端口
```