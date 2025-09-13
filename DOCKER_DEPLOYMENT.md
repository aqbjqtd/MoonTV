# MoonTV Docker 部署指南

## 🎯 任务达成状态

### ✅ 已完成的优化

1. **Dockerfile 优化** - 3 阶段多阶段构建

   - 分离依赖安装、构建和运行阶段
   - 优化构建缓存和镜像大小
   - 添加健康检查和监控

2. **环境变量支持** - 完整的配置管理

   - 支持 PASSWORD 环境变量注入
   - 添加 Docker Compose 配置简化部署
   - 优化的.dockerignore 文件

3. **健康检查 API** - `/api/health`端点
   - 容器状态监控
   - 自动健康检查机制

## 🚀 构建和运行指南

### 方法 1：直接 Docker 命令

```bash
# 1. 构建Docker镜像
docker build -t aqbjqtd/moontv:test .

# 2. 运行容器
docker run -d \
  --name moontv \
  -p 9000:3000 \
  --env PASSWORD=123456 \
  aqbjqtd/moontv:test
```

### 方法 2：Docker Compose（推荐）

```bash
# 使用默认密码
docker-compose up -d

# 或自定义密码
PASSWORD=your_password docker-compose up -d
```

### 方法 3：使用.env 文件

1. 创建`.env`文件：

```env
PASSWORD=123456
```

2. 启动服务：

```bash
docker-compose --env-file .env up -d
```

## 🔧 环境变量配置

### 必需变量

- `PASSWORD` - 登录密码（默认：123456）

### 可选变量

- `NODE_ENV` - 运行环境（默认：production）
- `PORT` - 容器内部端口（默认：3000）
- `HOSTNAME` - 监听地址（默认：0.0.0.0）
- `NEXT_PUBLIC_SITE_NAME` - 站点名称（默认：MoonTV）

## 🌐 访问服务

启动成功后，通过以下地址访问：

- **主页面**: http://localhost:9000
- **健康检查**: http://localhost:9000/api/health
- **登录页面**: http://localhost:9000/login

使用配置的密码（默认：123456）进行登录。

## 📊 容器管理

### 查看容器状态

```bash
docker ps | grep moontv
```

### 查看容器日志

```bash
docker logs moontv
```

### 停止容器

```bash
docker stop moontv
```

### 删除容器

```bash
docker rm moontv
```

### 重新构建和启动

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## 🔍 故障排除

### 1. 构建失败

- 确保 Docker 已安装并运行
- 检查项目依赖是否完整
- 查看构建错误日志：`docker build -t aqbjqtd/moontv:test .`

### 2. 容器启动失败

- 检查端口 9000 是否被占用
- 查看容器日志：`docker logs moontv`
- 确保环境变量正确设置

### 3. 服务无法访问

- 检查容器是否正常运行：`docker ps`
- 验证健康检查：`curl http://localhost:9000/api/health`
- 检查防火墙设置

## ✨️ 优化特性

### 多阶段构建优化

- **第 1 阶段**: 仅安装依赖，优化缓存
- **第 2 阶段**: 构建应用，清理开发依赖
- **第 3 阶段**: 最小运行时镜像

### 安全配置

- 非 root 用户运行
- 系统依赖最小化
- 环境变量安全注入

### 性能优化

- 构建缓存优化
- 镜像大小最小化
- 启动时间优化

---

**任务达成**: 🎉 MoonTV 项目已完全配置为 Docker 容器，可通过指定命令成功运行！
