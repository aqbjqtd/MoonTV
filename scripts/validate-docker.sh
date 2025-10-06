#!/bin/bash
# =================================================================
# MoonTV Docker 配置验证脚本
# 验证Docker配置的正确性和最佳实践
# =================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 计数器
TESTS_PASSED=0
TESTS_FAILED=0

# 测试函数
test_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

test_failure() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

test_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

test_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# 开始验证
echo "MoonTV Docker 配置验证"
echo "=========================="
echo

# 1. 检查必需文件
test_info "1. 检查必需文件..."

required_files=(
    "Dockerfile.optimized"
    "docker-compose.yml"
    ".env.example"
    ".dockerignore.optimized"
    "redis.conf"
    "nginx/conf.d/default.conf"
    "monitoring/prometheus.yml"
    "DOCKER_BEST_PRACTICES.md"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        test_success "文件存在: $file"
    else
        test_failure "文件缺失: $file"
    fi
done

echo

# 2. 验证Dockerfile语法
test_info "2. 验证Dockerfile语法..."

if docker build -f Dockerfile.optimized --dry-run . &> /dev/null; then
    test_success "Dockerfile.optimized 语法正确"
else
    test_failure "Dockerfile.optimized 语法错误"
fi

echo

# 3. 检查docker-compose配置
test_info "3. 检查docker-compose配置..."

if docker-compose config &> /dev/null; then
    test_success "docker-compose.yml 配置正确"
else
    test_failure "docker-compose.yml 配置错误"
fi

echo

# 4. 验证环境变量
test_info "4. 验证环境变量..."

if [[ -f ".env.example" ]]; then
    required_vars=("PASSWORD" "STORAGE_TYPE")
    while IFS= read -r line; do
        if [[ $line =~ ^[A-Z_]+= ]]; then
            var_name="${line%%=*}"
            for req_var in "${required_vars[@]}"; do
                if [[ "$var_name" == "$req_var" ]]; then
                    test_success "环境变量示例存在: $req_var"
                    break
                fi
            done
        fi
    done < .env.example
fi

echo

# 5. 检查安全性配置
test_info "5. 检查安全性配置..."

# 检查Dockerfile中的用户配置
if grep -q "USER.*1001" Dockerfile.optimized; then
    test_success "Dockerfile 配置了非root用户"
else
    test_failure "Dockerfile 未配置非root用户"
fi

# 检查基础镜像安全性
if grep -q "distroless" Dockerfile.optimized; then
    test_success "使用了distroless基础镜像"
else
    test_warning "建议使用distroless基础镜像以增强安全性"
fi

# 检查健康检查配置
if grep -q "HEALTHCHECK" Dockerfile.optimized; then
    test_success "Dockerfile 配置了健康检查"
else
    test_failure "Dockerfile 未配置健康检查"
fi

echo

# 6. 检查性能优化
test_info "6. 检查性能优化..."

# 检查多阶段构建
stages=$(grep -c "^FROM " Dockerfile.optimized)
if [[ $stages -ge 3 ]]; then
    test_success "采用了多阶段构建 ($stages 阶段)"
else
    test_warning "建议采用多阶段构建以优化镜像大小"
fi

# 检查缓存优化
if grep -q "package.json.*pnpm-lock.yaml" Dockerfile.optimized; then
    test_success "优化了Docker层缓存"
else
    test_warning "建议优化Docker层缓存以提高构建速度"
fi

echo

# 7. 检查监控配置
test_info "7. 检查监控配置..."

if [[ -f "monitoring/prometheus.yml" ]]; then
    test_success "Prometheus配置文件存在"
fi

if [[ -f "monitoring/grafana/datasources/prometheus.yml" ]]; then
    test_success "Grafana数据源配置存在"
fi

if grep -q "healthcheck" docker-compose.yml; then
    test_success "Docker Compose配置了健康检查"
else
    test_warning "建议在Docker Compose中配置健康检查"
fi

echo

# 8. 检查网络配置
test_info "8. 检查网络配置..."

if grep -q "networks:" docker-compose.yml; then
    test_success "配置了自定义网络"
else
    test_warning "建议配置自定义网络以增强安全性"
fi

if grep -q "172.20.0.0" docker-compose.yml; then
    test_success "使用了私有IP段"
else
    test_warning "建议使用私有IP段"
fi

echo

# 9. 检查存储配置
test_info "9. 检查存储配置..."

if grep -q "volumes:" docker-compose.yml; then
    test_success "配置了数据持久化"
else
    test_warning "建议配置数据持久化"
fi

echo

# 10. 构建测试（可选）
test_info "10. 执行构建测试..."

if docker build -f Dockerfile.optimized -t moontv:test . &> /dev/null; then
    test_success "镜像构建成功"

    # 检查镜像大小
    image_size=$(docker images moontv:test --format "{{.Size}}" | head -1)
    test_info "镜像大小: $image_size"

    # 清理测试镜像
    docker rmi moontv:test &> /dev/null || true
else
    test_failure "镜像构建失败"
fi

echo

# 显示结果
echo "验证结果汇总:"
echo "================"
echo -e "通过: ${GREEN}$TESTS_PASSED${NC}"
echo -e "失败: ${RED}$TESTS_FAILED${NC}"
echo

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}🎉 所有验证通过！Docker配置符合最佳实践。${NC}"
    exit 0
else
    echo -e "${RED}❌ 存在 $TESTS_FAILED 个问题，请修复后重试。${NC}"
    exit 1
fi