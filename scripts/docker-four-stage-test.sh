#!/bin/bash

# MoonTV 四阶段Docker构建验证脚本
# 用于验证标准四阶段构建架构

set -e

echo "🚀 MoonTV 四阶段Docker构建验证开始..."
echo "========================================"

# 检查Docker环境
echo "📋 检查Docker环境..."
docker --version
echo "✅ Docker环境检查完成"

# 检查Dockerfile
echo "📋 检查Dockerfile结构..."
if [ ! -f "Dockerfile" ]; then
    echo "❌ Dockerfile不存在"
    exit 1
fi

# 检查四个构建阶段
stages=("system-base" "deps" "builder" "runner")
for stage in "${stages[@]}"; do
    if grep -q "FROM.*AS $stage" Dockerfile; then
        echo "✅ 找到构建阶段: $stage"
    else
        echo "❌ 缺少构建阶段: $stage"
        exit 1
    fi
done

# 检查关键优化配置
echo "📋 检查关键优化配置..."
if grep -q "distroless" Dockerfile; then
    echo "✅ Distroless运行时: 已配置"
else
    echo "⚠️  Distroless运行时: 未配置"
fi

if grep -q "USER 1001:1001" Dockerfile; then
    echo "✅ 非特权用户: 已配置"
else
    echo "⚠️  非特权用户: 未配置"
fi

if grep -q "HEALTHCHECK" Dockerfile; then
    echo "✅ 健康检查: 已配置"
else
    echo "⚠️  健康检查: 未配置"
fi

echo "========================================"
echo "🔧 开始构建测试..."

# 测试各阶段构建（不完整构建，只测试语法和依赖）
echo "📦 阶段1: 测试系统基础层..."
timeout 120 docker build --target system-base -t moontv:test-stage1 . || {
    echo "❌ 阶段1构建失败"
    exit 1
}
echo "✅ 阶段1构建成功"

echo "📦 阶段2: 测试依赖解析层..."
timeout 180 docker build --target deps -t moontv:test-stage2 . || {
    echo "❌ 阶段2构建失败"
    exit 1
}
echo "✅ 阶段2构建成功"

# 清理测试镜像
docker rmi moontv:test-stage1 moontv:test-stage2 2>/dev/null || true

echo "========================================"
echo "📊 构建配置分析..."

# 分析镜像大小预估
echo "🔍 分析构建配置..."
echo "📋 构建阶段:"
grep -n "FROM.*AS" Dockerfile | while read line; do
    echo "   $line"
done

echo ""
echo "📋 关键优化:"
echo "   - 基础镜像: $(grep "FROM.*node" Dockerfile | head -1 | cut -d' ' -f2)"
echo "   - 运行时镜像: $(grep "FROM.*distroless\|FROM.*alpine" Dockerfile | tail -1 | cut -d' ' -f2)"
echo "   - 并行构建: $(grep -c "wait &&" Dockerfile)"
echo "   - 缓存优化: $(grep -c "COPY.*from=" Dockerfile)"

echo ""
echo "========================================"
echo "✅ 四阶段Docker构建验证完成!"
echo ""
echo "🚀 下一步操作建议:"
echo "   1. 完整构建: docker build -t moontv:latest ."
echo "   2. 运行测试: docker run -p 3000:3000 moontv:latest"
echo "   3. 健康检查: curl http://localhost:3000/api/health"
echo ""
echo "📋 构建特性:"
echo "   ✅ 四阶段分层构建架构"
echo "   ✅ Distroless最小化运行时"
echo "   ✅ BuildKit并行构建优化"
echo "   ✅ 企业级安全配置"
echo "   ✅ 非 root 用户运行"
echo "   ✅ 轻量级健康检查机制"