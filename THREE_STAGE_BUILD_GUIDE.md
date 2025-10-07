# MoonTV 三阶段分层构建指南

## 概述

本指南详细说明了 MoonTV 项目的三阶段分层 Docker 构建策略，该策略旨在：

- **最大化缓存效率**: 分离依赖层和源码层，提高构建速度
- **最小化镜像体积**: 多阶段构建减少最终镜像大小
- **增强安全性**: 非 root 用户和生产环境配置
- **提高可维护性**: 清晰的阶段划分便于调试和优化

## 构建架构

### 阶段 1: 基础依赖层 (base-deps)

**目标**: 安装系统依赖和 Node.js 包依赖

**特性**:

- 使用 Alpine Linux 最小镜像 (~5MB)
- 锁定 Node.js 版本: 20.10.0-alpine
- 锁定 pnpm 版本: 10.14.0 (与项目一致)
- 仅安装生产依赖
- 优化缓存命中率

**关键优化**:

```dockerfile
# 优先复制依赖文件，提高层缓存
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prod --ignore-scripts
```

**预期大小**: ~150-200MB
**缓存命中率**: 高 (仅在依赖变化时重建)

### 阶段 2: 构建准备层 (build-prep)

**目标**: 源代码构建和运行时配置生成

**特性**:

- 复制生产依赖 (从 base-deps 阶段)
- 复制全部源代码和配置文件
- 安装开发依赖用于构建
- 生成运行时配置和 PWA manifest
- 修复 Edge Runtime 兼容性
- 执行 Next.js 构建

**关键流程**:

```dockerfile
# 从依赖层复制
COPY --from=base-deps /app/node_modules ./node_modules

# 构建应用
RUN pnpm gen:manifest && pnpm gen:runtime
RUN pnpm build

# 清理开发依赖
RUN pnpm prune --prod --ignore-scripts
```

**预期大小**: ~300-400MB (包含源码和依赖)
**缓存命中率**: 中等 (源码变化时重建)

### 阶段 3: 生产运行时层 (production-runner)

**目标**: 最小化的生产运行环境

**特性**:

- 非 root 用户运行 (nextjs:1001)
- 最小化系统依赖
- 生产环境变量配置
- 健康检查机制
- 安全配置

**安全配置**:

```dockerfile
# 非 root 用户
RUN addgroup -g 1001 -S nodejs && adduser -u 1001 -S nextjs -G nodejs

# 生产环境变量
ENV NODE_ENV=production \
    DOCKER_ENV=true \
    NEXT_TELEMETRY_DISABLED=1

# 健康检查
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3
```

**预期大小**: ~180-250MB (优化后)
**安全性**: 高

## 使用方法

### 快速开始

1. **完整构建和测试**:

```bash
# 一键构建和运行测试
./scripts/build-three-stage.sh
```

2. **手动构建**:

```bash
# 构建完整镜像
docker build -t moontv:test .

# 分阶段构建 (用于调试)
docker build --target base-deps -t moontv:base-deps .
docker build --target build-prep -t moontv:build-prep .
docker build --target production-runner -t moontv:test .
```

3. **运行测试**:

```bash
# 使用 docker-compose
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

### 开发调试

1. **验证构建配置**:

```bash
./scripts/validate-three-stage.sh
```

2. **查看构建日志**:

```bash
# 完整构建日志
./scripts/build-three-stage.sh 2>&1 | tee full-build.log

# 分阶段日志
docker build --target base-deps . 2>&1 | tee stage1.log
docker build --target build-prep . 2>&1 | tee stage2.log
docker build --target production-runner . 2>&1 | tee stage3.log
```

3. **调试构建问题**:

```bash
# 进入构建阶段调试
docker run -it --rm moontv:base-deps sh
docker run -it --rm moontv:build-prep sh

# 查看镜像层
docker history moontv:test
docker inspect moontv:test
```

## 配置文件说明

### Dockerfile

标准三阶段分层的核心 Dockerfile，包含:

- **base-deps**: 基础依赖层
- **build-prep**: 构建准备层
- **production-runner**: 生产运行时层

### docker-compose.test.yml

测试环境的 Docker Compose 配置:

```yaml
version: '3.8'
services:
  moontv-test:
    build:
      context: .
      dockerfile: Dockerfile
      target: production-runner
    image: moontv:test
    ports:
      - '3000:3000'
    environment:
      - NODE_ENV=production
      - DOCKER_ENV=true
      - PASSWORD=test123456
```

### config.test.json

测试环境配置，包含少量测试 API 源。

### scripts/build-three-stage.sh

自动化构建脚本，提供:

- 依赖检查
- 分阶段构建监控
- 镜像大小分析
- 容器健康检查
- 性能测试
- 构建报告生成

## 性能优化

### 构建时间优化

1. **依赖缓存**:

   - package.json 和 pnpm-lock.yaml 优先复制
   - 生产依赖单独安装和缓存

2. **源码缓存**:

   - 按变化频率排序复制文件
   - 配置文件优先于源码文件

3. **并行构建**:
   ```bash
   # 使用 BuildKit 并行构建
   DOCKER_BUILDKIT=1 docker build .
   ```

### 镜像大小优化

1. **多阶段构建**: 仅复制必要的文件到最终镜像
2. **Alpine Linux**: 使用最小的基础镜像
3. **依赖清理**: 删除开发依赖和缓存文件
4. **单层复制**: 使用 `--chown` 减少层数

### 安全优化

1. **非 root 用户**: 创建专用用户运行应用
2. **最小权限**: 仅安装必要的系统依赖
3. **生产配置**: 禁用遥测和调试功能
4. **健康检查**: 监控应用运行状态

## 故障排除

### 常见问题

1. **构建失败**:

   ```bash
   # 清理构建缓存
   docker builder prune -a

   # 检查磁盘空间
   df -h

   # 查看详细错误
   docker build . --progress=plain
   ```

2. **依赖安装失败**:

   ```bash
   # 检查 pnpm-lock.yaml 一致性
   pnpm install --frozen-lockfile --dry-run

   # 清理 pnpm 缓存
   pnpm store prune
   ```

3. **运行时错误**:

   ```bash
   # 查看容器日志
   docker logs moontv-test

   # 进入容器调试
   docker exec -it moontv-test sh

   # 检查健康状态
   curl http://localhost:3000/api/health
   ```

4. **内存不足**:

   ```bash
   # 增加 Docker 内存限制
   # Docker Desktop -> Settings -> Resources -> Memory

   # 或调整 Node.js 内存限制
   ENV NODE_OPTIONS="--max-old-space-size=512"
   ```

### 性能调优

1. **构建慢**:

   - 使用本地 Docker 镜像仓库缓存
   - 启用 BuildKit 缓存挂载
   - 优化 .dockerignore 文件

2. **镜像大**:

   - 检查不必要的文件是否被复制
   - 使用 `docker history` 分析层大小
   - 考虑使用 distroless 镜像

3. **启动慢**:
   - 检查健康检查配置
   - 优化应用启动代码
   - 考虑预热机制

## 最佳实践

### 开发流程

1. **本地测试**:

   ```bash
   # 开发环境运行
   pnpm dev

   # 确保测试通过
   pnpm test
   pnpm typecheck
   ```

2. **Docker 测试**:

   ```bash
   # 构建 Docker 镜像
   ./scripts/build-three-stage.sh

   # 验证功能
   docker-compose -f docker-compose.test.yml up -d
   curl http://localhost:3000/api/health
   ```

3. **生产部署**:

   ```bash
   # 生产镜像标签
   docker build -t moontv:prod .

   # 推送到仓库
   docker push your-registry/moontv:prod
   ```

### CI/CD 集成

```yaml
# GitHub Actions 示例
- name: Build Docker image
  run: |
    ./scripts/build-three-stage.sh

- name: Run tests
  run: |
    docker-compose -f docker-compose.test.yml up -d
    sleep 30
    curl http://localhost:3000/api/health
    docker-compose -f docker-compose.test.yml down
```

### 监控和维护

1. **镜像更新**:

   ```bash
   # 定期更新基础镜像
   docker pull node:20.10.0-alpine

   # 重新构建
   docker build --no-cache .
   ```

2. **安全扫描**:

   ```bash
   # 使用 trivy 扫描
   trivy image moontv:test

   # 使用 docker scout
   docker scout cves moontv:test
   ```

3. **性能监控**:

   ```bash
   # 监控容器资源使用
   docker stats moontv-test

   # 监控镜像大小变化
   docker images moontv:test --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
   ```

## 总结

三阶段分层构建策略为 MoonTV 项目提供了:

- **高效缓存**: 显著减少重复构建时间
- **优化大小**: 最小化生产镜像体积
- **增强安全**: 生产级安全配置
- **易于维护**: 清晰的构建阶段划分

通过遵循本指南的最佳实践，可以确保 Docker 构建过程的高效、安全和可维护性。
