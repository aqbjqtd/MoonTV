# MoonTV Docker 构建标准

本文档定义了 MoonTV 项目的标准化 Docker 构建流程和规范。

## 🎯 构建策略

MoonTV 使用 **三阶段分层构建** 作为唯一的标准化构建方式：

1. **base-deps**: 基础依赖层 - 系统依赖和 Node.js 包依赖
2. **build-prep**: 构建准备层 - 源代码构建和运行时配置生成
3. **production-runner**: 生产运行时层 - 最小化的生产环境

## 📁 核心文件

### Dockerfile
- **位置**: 项目根目录 `/Dockerfile`
- **类型**: 三阶段分层构建
- **基础镜像**: `node:20.10.0-alpine`
- **包管理器**: pnpm@10.14.0

### 配置文件
- `docker-compose.test.yml` - 测试环境配置
- `config.test.json` - 测试环境 API 配置
- `docker-compose.yml` - 生产环境配置

### 构建脚本
- `scripts/build-three-stage.sh` - 标准构建脚本
- `scripts/validate-three-stage.sh` - 构建验证脚本

## 🚀 标准构建命令

### 基础构建
```bash
# 标准构建
docker build -t moontv:test .

# 无缓存构建
docker build --no-cache -t moontv:test .

# 多平台构建
docker build --platform linux/amd64,linux/arm64 -t moontv:test .
```

### 分阶段构建
```bash
# 仅构建基础依赖层
docker build --target base-deps -t moontv:base-deps .

# 仅构建准备层
docker build --target build-prep -t moontv:build-prep .

# 构建最终生产镜像
docker build --target production-runner -t moontv:test .
```

### 自动化构建
```bash
# 一键构建和测试
./scripts/build-three-stage.sh

# 验证构建配置
./scripts/validate-three-stage.sh
```

## 🏗️ 三阶段架构详解

### 阶段 1: base-deps (基础依赖层)
**目标**: 最大化缓存命中率，仅在依赖变化时重建

**关键特性**:
- ✅ Alpine Linux 最小镜像 (~5MB)
- ✅ pnpm@10.14.0 包管理器
- ✅ 仅安装生产依赖
- ✅ 优化缓存清理策略

**预期大小**: 150-200MB
**缓存命中率**: 高

### 阶段 2: build-prep (构建准备层)
**目标**: 源代码构建和运行时配置生成

**关键特性**:
- ✅ 复制生产依赖 (从 base-deps)
- ✅ 按变化频率分层复制文件
- ✅ Docker 环境兼容性修复
- ✅ 运行时配置自动生成

**预期大小**: 300-400MB (包含源码)
**缓存命中率**: 中等

### 阶段 3: production-runner (生产运行时层)
**目标**: 最小化安全的生产环境

**关键特性**:
- ✅ 非 root 用户运行 (nextjs:1001)
- ✅ 最小化系统依赖
- ✅ 生产环境安全配置
- ✅ 健康检查机制

**预期大小**: 180-250MB (优化后)
**安全性**: 高

## 🔧 环境配置

### 必需环境变量
```bash
PASSWORD=your-password                    # 认证密码
NEXT_PUBLIC_STORAGE_TYPE=localstorage     # 存储类型
```

### 可选环境变量
```bash
NEXT_PUBLIC_SITE_NAME=MoonTV             # 站点名称
NEXT_PUBLIC_SEARCH_MAX_PAGE=5            # 搜索页数限制
USERNAME=admin                           # 所有者用户名 (数据库模式)
NEXT_PUBLIC_ENABLE_REGISTER=false        # 允许注册
```

### 生产环境变量 (自动配置)
```bash
NODE_ENV=production                      # 生产环境
DOCKER_ENV=true                          # Docker 环境
HOSTNAME=0.0.0.0                        # 监听地址
PORT=3000                               # 服务端口
NEXT_TELEMETRY_DISABLED=1               # 禁用遥测
NODE_OPTIONS="--max-old-space-size=1024 --enable-source-maps"
TZ=Asia/Shanghai                         # 时区设置
```

## 🧪 测试和验证

### 容器运行测试
```bash
# 使用 docker-compose 测试
docker-compose -f docker-compose.test.yml up -d

# 查看状态
docker-compose -f docker-compose.test.yml ps

# 查看日志
docker-compose -f docker-compose.test.yml logs -f

# 健康检查
curl http://localhost:3000/api/health

# 停止服务
docker-compose -f docker-compose.test.yml down
```

### 验证脚本
```bash
# 验证构建配置
./scripts/validate-three-stage.sh

# 自动化构建验证
./scripts/build-three-stage.sh
```

## 📊 性能指标

### 构建性能
- **首次构建**: 5-8 分钟
- **缓存命中构建**: 1-2 分钟
- **镜像大小**: 180-250MB (压缩后)
- **层数量**: 15-20 层

### 运行时性能
- **启动时间**: <30 秒
- **内存使用**: <512MB
- **CPU 使用**: <50% (正常负载)
- **响应时间**: <2 秒

## 🛠️ 故障排除

### 常见问题

1. **构建失败**
   ```bash
   # 清理构建缓存
   docker builder prune -a

   # 查看详细错误
   docker build --progress=plain .
   ```

2. **依赖安装失败**
   ```bash
   # 检查 lockfile 一致性
   pnpm install --frozen-lockfile --dry-run

   # 清理 pnpm 缓存
   pnpm store prune
   ```

3. **运行时错误**
   ```bash
   # 查看容器日志
   docker logs moontv-test

   # 进入容器调试
   docker exec -it moontv-test sh
   ```

### 调试命令
```bash
# 查看镜像层
docker history moontv:test

# 查看镜像详情
docker inspect moontv:test

# 进入构建阶段调试
docker run -it --rm moontv:base-deps sh
docker run -it --rm moontv:build-prep sh
```

## 📋 最佳实践

### 开发流程
1. 本地开发和测试 (`pnpm dev`, `pnpm test`)
2. Docker 构建验证 (`./scripts/build-three-stage.sh`)
3. 集成测试 (`docker-compose -f docker-compose.test.yml up -d`)
4. 生产部署 (生产镜像标签和推送到仓库)

### 构建优化
1. **依赖缓存**: 优先复制 package.json 和 pnpm-lock.yaml
2. **源码缓存**: 按变化频率排序复制文件
3. **并行构建**: 使用 BuildKit (`DOCKER_BUILDKIT=1`)

### 安全最佳实践
1. **用户权限**: 非 root 用户运行
2. **最小依赖**: 仅安装必要的系统依赖
3. **生产配置**: 禁用遥测和调试功能
4. **健康检查**: 监控应用运行状态

## 🔄 CI/CD 集成

### GitHub Actions 示例
```yaml
name: Build and Test
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Build Docker image
        run: ./scripts/build-three-stage.sh

      - name: Run tests
        run: |
          docker-compose -f docker-compose.test.yml up -d
          sleep 30
          curl http://localhost:3000/api/health
          docker-compose -f docker-compose.test.yml down
```

## 📈 维护和监控

### 定期维护
```bash
# 定期更新基础镜像
docker pull node:20.10.0-alpine

# 重新构建
docker build --no-cache .

# 安全扫描
trivy image moontv:test
docker scout cves moontv:test
```

### 性能监控
```bash
# 监控容器资源使用
docker stats moontv-test

# 监控镜像大小变化
docker images moontv:test --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
```

## 📚 相关文档

- [三阶段构建详细指南](./THREE_STAGE_BUILD_GUIDE.md)
- [三阶段构建报告](./THREE_STAGE_BUILD_REPORT.md)
- [项目架构指南](./CLAUDE.md)

---

**标准版本**: v1.0
**最后更新**: 2025-10-07
**维护状态**: ✅ 活跃维护