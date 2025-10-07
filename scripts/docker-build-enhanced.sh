#!/bin/bash

# =================================================================
# MoonTV 增强版 Docker 构建脚本
# 版本: v4.0.0
# 功能: 自动化构建、部署和监控
# =================================================================

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_header() {
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}================================================================${NC}"
}

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_TYPE="${1:-enhanced}"
ENVIRONMENT="${2:-production}"
MULTI_ARCH="${3:-false}"

# 构建配置
IMAGE_NAME="moontv"
IMAGE_TAG="v4.0.0-${BUILD_TYPE}"
DOCKERFILE="Dockerfile.${BUILD_TYPE}"
COMPOSE_FILE="docker-compose.${BUILD_TYPE}.yml"

# 性能追踪
BUILD_START_TIME=0
BUILD_END_TIME=0
PREV_SIZE=0
NEW_SIZE=0

# 函数：检查Docker环境
check_docker() {
    log_step "检查Docker环境..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装或不在PATH中"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker守护进程未运行或权限不足"
        exit 1
    fi

    # 检查Docker BuildKit
    if ! docker buildx version &> /dev/null; then
        log_warning "Docker BuildKit未启用，构建性能可能受影响"
        export DOCKER_BUILDKIT=1
    else
        export DOCKER_BUILDKIT=1
        log_success "Docker BuildKit已启用"
    fi

    # 检查可用磁盘空间（至少需要2GB）
    available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_space" -lt 2 ]; then
        log_warning "可用磁盘空间不足2GB，构建可能失败"
    fi

    log_success "Docker环境检查完成"
}

# 函数：准备构建环境
prepare_build() {
    log_step "准备构建环境..."

    cd "$PROJECT_ROOT"

    # 创建必要的目录
    mkdir -p logs data/redis data/prometheus data/grafana cache/media cache/temp webroot

    # 检查必要文件
    local required_files=("$DOCKERFILE" "package.json" "pnpm-lock.yaml")
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "缺少必要文件: $file"
            exit 1
        fi
    done

    # 清理旧的构建缓存
    log_step "清理旧的构建缓存..."
    docker system prune -f --volumes

    # 设置构建参数
    export BUILDKIT_INLINE_CACHE=1
    export DOCKER_BUILDKIT=1

    log_success "构建环境准备完成"
}

# 函数：获取镜像大小
get_image_size() {
    local image="$1"
    if docker image inspect "$image" &> /dev/null; then
        docker image inspect "$image" --format='{{.Size}}' | awk '{print int($1/1024/1024)"MB"}'
    else
        echo "0MB"
    fi
}

# 函数：构建Docker镜像
build_image() {
    log_header "开始构建Docker镜像"

    BUILD_START_TIME=$(date +%s)

    # 获取之前镜像大小用于对比
    local old_image="${IMAGE_NAME}:${IMAGE_TAG}"
    PREV_SIZE=$(get_image_size "$old_image")

    # 构建命令
    local build_cmd=(
        "docker" "build"
        "--file" "$DOCKERFILE"
        "--tag" "${IMAGE_NAME}:${IMAGE_TAG}"
        "--tag" "${IMAGE_NAME}:latest"
        "--build-arg" "BUILDKIT_INLINE_CACHE=1"
        "--progress" "plain"
    )

    # 多架构构建支持
    if [ "$MULTI_ARCH" = "true" ]; then
        log_step "启用多架构构建..."
        build_cmd+=(
            "--platform" "linux/amd64,linux/arm64"
        )
        docker buildx create --name moontv-builder --use --bootstrap 2>/dev/null || true
    fi

    # 添加缓存选项
    build_cmd+=(
        "--cache-from" "type=local,src=/tmp/.buildx-cache"
        "--cache-to" "type=local,dest=/tmp/.buildx-cache-new,mode=max"
    )

    # 执行构建
    log_step "执行构建命令..."
    log_info "构建参数: ${build_cmd[*]}"

    if "${build_cmd[@]}" .; then
        BUILD_END_TIME=$(date +%s)
        NEW_SIZE=$(get_image_size "${IMAGE_NAME}:${IMAGE_TAG}")

        log_success "镜像构建成功！"
        log_info "构建耗时: $((BUILD_END_TIME - BUILD_START_TIME))秒"

        if [ "$PREV_SIZE" != "0MB" ]; then
            log_info "镜像大小变化: ${PREV_SIZE} → ${NEW_SIZE}"
        else
            log_info "新镜像大小: ${NEW_SIZE}"
        fi

        # 交换缓存
        rm -rf /tmp/.buildx-cache
        mv /tmp/.buildx-cache-new /tmp/.buildx-cache
    else
        log_error "镜像构建失败！"
        exit 1
    fi
}

# 函数：安全扫描
security_scan() {
    log_step "执行安全扫描..."

    # 检查是否安装了Trivy
    if command -v trivy &> /dev/null; then
        log_info "运行Trivy安全扫描..."
        if trivy image --severity HIGH,CRITICAL "${IMAGE_NAME}:${IMAGE_TAG}"; then
            log_success "安全扫描完成，未发现高危漏洞"
        else
            log_warning "安全扫描发现潜在问题，请查看详细报告"
        fi
    else
        log_warning "Trivy未安装，跳过安全扫描"
        log_info "安装命令: apt-get install trivy 或 brew install trivy"
    fi
}

# 函数：运行测试
run_tests() {
    log_step "运行容器测试..."

    # 启动测试容器
    local test_container="moontv-test-${BUILD_TYPE}"

    if [ "$MULTI_ARCH" = "true" ]; then
        log_warning "多架构镜像跳过本地测试"
        return 0
    fi

    # 清理旧容器
    docker rm -f "$test_container" 2>/dev/null || true

    # 启动测试容器
    log_info "启动测试容器..."
    docker run -d \
        --name "$test_container" \
        -p 3001:3000 \
        -e NODE_ENV=test \
        "${IMAGE_NAME}:${IMAGE_TAG}"

    # 等待容器启动
    log_info "等待容器启动..."
    sleep 30

    # 健康检查
    local health_status=0
    for i in {1..10}; do
        if curl -f http://localhost:3001/api/health &> /dev/null; then
            health_status=1
            break
        fi
        log_info "等待容器就绪... ($i/10)"
        sleep 10
    done

    if [ $health_status -eq 1 ]; then
        log_success "容器健康检查通过"

        # 运行基础功能测试
        log_info "运行功能测试..."
        if curl -f http://localhost:3001/api/config &> /dev/null; then
            log_success "API功能测试通过"
        else
            log_warning "API功能测试失败，请检查应用日志"
        fi
    else
        log_error "容器健康检查失败"
        docker logs "$test_container"
        exit 1
    fi

    # 清理测试容器
    docker rm -f "$test_container"
}

# 函数：部署服务
deploy_services() {
    log_step "部署服务..."

    if [ ! -f "$COMPOSE_FILE" ]; then
        log_error "Compose文件不存在: $COMPOSE_FILE"
        exit 1
    fi

    # 停止旧服务
    log_info "停止旧服务..."
    docker-compose -f "$COMPOSE_FILE" down

    # 启动新服务
    log_info "启动新服务..."
    if docker-compose -f "$COMPOSE_FILE" up -d; then
        log_success "服务部署成功"

        # 等待服务就绪
        log_info "等待服务就绪..."
        sleep 60

        # 检查服务状态
        if docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
            log_success "服务运行正常"

            # 显示服务状态
            docker-compose -f "$COMPOSE_FILE" ps
        else
            log_warning "部分服务可能未正常启动，请检查日志"
        fi
    else
        log_error "服务部署失败"
        exit 1
    fi
}

# 函数：生成报告
generate_report() {
    log_header "构建报告"

    echo "构建类型: $BUILD_TYPE"
    echo "环境: $ENVIRONMENT"
    echo "多架构: $MULTI_ARCH"
    echo "镜像名称: ${IMAGE_NAME}:${IMAGE_TAG}"
    echo "构建耗时: $((BUILD_END_TIME - BUILD_START_TIME))秒"
    echo "镜像大小: ${NEW_SIZE}"

    if [ "$PREV_SIZE" != "0MB" ]; then
        echo "大小变化: ${PREV_SIZE} → ${NEW_SIZE}"
    fi

    echo "构建时间: $(date)"
    echo "Docker版本: $(docker --version)"

    # 保存构建信息
    cat > "build-report-${BUILD_TYPE}-$(date +%Y%m%d-%H%M%S).json" << EOF
{
  "build_type": "$BUILD_TYPE",
  "environment": "$ENVIRONMENT",
  "multi_arch": $MULTI_ARCH,
  "image_name": "${IMAGE_NAME}:${IMAGE_TAG}",
  "build_time": $((BUILD_END_TIME - BUILD_START_TIME)),
  "image_size": "${NEW_SIZE}",
  "previous_size": "${PREV_SIZE}",
  "build_date": "$(date -Iseconds)",
  "docker_version": "$(docker --version)"
}
EOF

    log_success "构建报告已生成"
}

# 函数：清理
cleanup() {
    log_step "清理临时文件..."

    # 清理未使用的镜像
    docker image prune -f

    # 清理构建缓存（保留最近一次）
    if [ -d "/tmp/.buildx-cache" ]; then
        log_info "保留构建缓存用于后续构建"
    fi

    log_success "清理完成"
}

# 主函数
main() {
    log_header "MoonTV 增强版 Docker 构建开始"

    log_info "构建类型: $BUILD_TYPE"
    log_info "环境: $ENVIRONMENT"
    log_info "多架构构建: $MULTI_ARCH"

    # 执行构建流程
    check_docker
    prepare_build
    build_image
    security_scan
    run_tests

    # 根据参数决定是否部署
    if [ "${4:-deploy}" = "deploy" ]; then
        deploy_services
    fi

    generate_report
    cleanup

    log_header "构建流程完成！"
    log_success "镜像 ${IMAGE_NAME}:${IMAGE_TAG} 构建成功"
    log_info "使用以下命令运行服务:"
    log_info "  docker-compose -f $COMPOSE_FILE up -d"
    log_info "查看服务状态:"
    log_info "  docker-compose -f $COMPOSE_FILE ps"
}

# 错误处理
trap 'log_error "脚本执行失败，退出码: $?"' ERR

# 显示帮助信息
show_help() {
    echo "用法: $0 [构建类型] [环境] [多架构] [部署选项]"
    echo ""
    echo "参数说明:"
    echo "  构建类型: enhanced (默认) | optimized | standard"
    echo "  环境: production (默认) | development | staging"
    echo "  多架构: false (默认) | true"
    echo "  部署选项: deploy (默认) | build-only"
    echo ""
    echo "示例:"
    echo "  $0 enhanced production false     # 标准增强版构建"
    echo "  $0 enhanced production true      # 多架构构建"
    echo "  $0 enhanced development false build-only  # 仅构建不部署"
}

# 参数处理
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac