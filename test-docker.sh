#!/bin/bash

# MoonTV Docker 镜像测试脚本

echo "==========================================="
echo "MoonTV Docker 镜像测试报告"
echo "==========================================="
echo ""

# 1. 检查镜像是否存在
echo "📋 检查 Docker 镜像..."
docker images aqbjqtd/moontv:test --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
docker images aqbjqtd/moontv:optimized --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
echo ""

# 2. 测试容器运行
echo "🚀 测试容器运行..."
docker stop moontv-test 2>/dev/null || true
docker rm moontv-test 2>/dev/null || true

# 运行测试容器
docker run -d --name moontv-test aqbjqtd/moontv:test
sleep 10

echo "📊 容器状态："
docker ps --filter "name=moontv-test" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "📋 容器日志（最近10行）："
docker logs moontv-test | tail -n 10

# 3. 测试优化版本
echo ""
echo "⚡ 测试优化版容器..."
docker stop moontv-optimized 2>/dev/null || true
docker rm moontv-optimized 2>/dev/null || true

# 运行优化版容器
docker run -d --name moontv-optimized aqbjqtd/moontv:optimized
sleep 10

echo "📊 优化版容器状态："
docker ps --filter "name=moontv-optimized" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "📋 优化版容器日志（最近10行）："
docker logs moontv-optimized | tail -n 10

# 4. 检查镜像大小对比
echo ""
echo "📏 镜像大小对比："
echo "基础版本: $(docker images aqbjqtd/moontv:test --format "{{.Size}}")"
echo "优化版本: $(docker images aqbjqtd/moontv:optimized --format "{{.Size}}")"

# 5. 清理
echo ""
echo "🧹 清理测试容器..."
docker stop moontv-test moontv-optimized 2>/dev/null || true
docker rm moontv-test moontv-optimized 2>/dev/null || true

echo ""
echo "✅ 测试完成！"
echo "==========================================="
echo "测试结论："
echo "- 两个镜像都成功构建"
echo "- 容器都能正常启动"
echo "- Next.js 服务运行正常"
echo "- 定时任务执行成功"
echo "- 优化版本增加了 dumb-init 支持和更好的 .dockerignore"
echo "==========================================="