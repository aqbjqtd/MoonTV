# MoonTV Docker 快速开始指南

> **版本**: v4.0.1 | **更新**: 2025-01-08
> 企业级 BuildKit 优化构建

## 🚀 快速构建

### 1. 基础构建（推荐）

```bash
# 优化构建
./scripts/docker-build-optimized.sh -t v4.0.1

# 运行容器
docker run -d -p 3000:3000 --name moontv moontv:v4.0.1

# 测试服务
curl http://localhost:3000/api/health
```

### 2. 多架构构建

```bash
# 同时构建 AMD64 + ARM64
./scripts/docker-build-optimized.sh --multi-arch --push -t v4.0.1
```

### 3. 智能标签管理

```bash
# 查看项目信息
./scripts/docker-tag-manager.sh info

# 自动推送所有标签
./scripts/docker-tag-manager.sh push moontv:v4.0.1
```

## 📊 优化效果

| 指标       | 优化前     | 优化后     | 提升     |
| ---------- | ---------- | ---------- | -------- |
| 镜像大小   | 1.08GB     | 318MB      | **-71%** |
| 构建时间   | 4 分 15 秒 | 2 分 30 秒 | **-40%** |
| 缓存命中率 | 60%        | 95%        | **+58%** |

## 🔧 高级配置

### 参数化构建

```bash
# 自定义构建参数
./scripts/docker-build-optimized.sh \
  --node-version 20 \
  --pnpm-version 8.15.0 \
  -t custom-build

# 禁用缓存
./scripts/docker-build-optimized.sh --no-cache -t clean-build

# 详细输出
./scripts/docker-build-optimized.sh -v -t debug-build
```

### CI/CD 集成

```yaml
# .github/workflows/docker-build.yml 已优化
- ✅ 多平台并行构建
- ✅ 智能缓存策略
- ✅ 自动标签生成
- ✅ 安全扫描
- ✅ 自动清理
```

## 🏷️ 标签策略

自动生成的标签：

- `v4.0.1` - 项目版本
- `app-3.2.0` - 应用版本
- `branch-main` - 分支名称
- `sha-abc123` - 提交哈希
- `build-42` - 构建编号
- `latest` - 主分支最新
- `20250108` - 构建日期

## 🛠️ 故障排除

### 缓存问题

```bash
# 清理 BuildKit 缓存
docker buildx prune -a

# 重置 BuildKit
docker buildx stop && docker buildx rm
docker buildx create --use
```

### 权限问题

```bash
# 登录容器仓库
docker login ghcr.io

# 检查构建权限
./scripts/docker-tag-manager.sh info
```

## 📖 完整文档

- 📚 [详细优化指南](./docker-optimization-guide.md)
- 🏗️ [构建架构说明](./docker-four-stage-standard.md)
- 📖 [项目开发指南](./CLAUDE.md)

---

**快速开始**: `./scripts/docker-build-optimized.sh -t latest` 🚀
