#!/bin/bash
# MoonTV Compact Build Script
# 专注于镜像大小优化的构建流程

set -euo pipefail

# 配置
IMAGE_NAME="moontv"
TAG="compact"
FULL_TAG="${IMAGE_NAME}:${TAG}"

echo "🚀 开始构建紧凑版Docker镜像: ${FULL_TAG}"

# 构建紧凑版镜像
docker build \
    --file Dockerfile.ultra-compact \
    --tag "${FULL_TAG}" \
    --progress=plain \
    --build-arg NODE_ENV=production \
    --build-arg DOCKER_ENV=true \
    .

# 显示镜像大小
echo "📊 镜像构建完成！"
docker images "${FULL_TAG}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# 分析镜像层
echo ""
echo "📈 镜像层分析:"
docker history "${FULL_TAG}" --format "table {{.ID}}\t{{.Size}}\t{{.CreatedBy}}" | head -15

# 测试容器启动
echo ""
echo "🧪 测试容器启动..."
if timeout 30s docker run --rm "${FULL_TAG}" echo "Container started successfully"; then
    echo "✅ 容器启动测试通过"
else
    echo "❌ 容器启动测试失败"
    exit 1
fi

echo ""
echo "🎉 紧凑版镜像构建完成！"
echo "使用命令: docker run -p 3000:3000 --env PASSWORD=your_password ${FULL_TAG}"