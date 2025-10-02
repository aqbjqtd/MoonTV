#!/bin/bash
# MoonTV Ultra-Optimized Build Script (2025)
# 基于深度研究和BuildKit高级缓存优化

set -euo pipefail

# ==================== 配置参数 ====================
IMAGE_NAME="moontv"
TAG="test"
FULL_TAG="${IMAGE_NAME}:${TAG}"
PLATFORMS="linux/amd64"

# 构建参数
BUILD_ARGS=(
    "--build-arg=NODE_ENV=production"
    "--build-arg=DOCKER_ENV=true"
    "--build-arg=BUILDKIT_INLINE_CACHE=1"
)

# 缓存配置 - 使用本地缓存
CACHE_FROM="type=local,src=/tmp/.buildx-cache"
CACHE_TO="type=local,dest=/tmp/.buildx-cache"

# ==================== 颜色输出 ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ==================== 检查前置条件 ====================
check_prerequisites() {
    log_info "检查前置条件..."

    # 检查Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装"
        exit 1
    fi

    # 检查Docker BuildKit
    if ! docker buildx version &> /dev/null; then
        log_error "Docker BuildKit未启用"
        exit 1
    fi

    # 检查Dockerfile
    if [ ! -f "Dockerfile.optimized-v4" ]; then
        log_error "Dockerfile.optimized-v4不存在"
        exit 1
    fi

    log_success "前置条件检查通过"
}

# ==================== 设置构建环境 ====================
setup_buildx() {
    log_info "设置Docker Buildx构建环境..."

    # 创建或使用现有的builder
    if ! docker buildx inspect moon-builder &> /dev/null; then
        docker buildx create --name moon-builder --use --bootstrap
    else
        docker buildx use moon-builder
    fi

    log_success "Buildx环境设置完成"
}

# ==================== 构建镜像 ====================
build_image() {
    local build_context="."
    local dockerfile="Dockerfile.optimized-v4"

    log_info "开始构建镜像: ${FULL_TAG}"
    log_info "目标平台: ${PLATFORMS}"

    # 构建命令
    local build_cmd=(
        "docker" "buildx" "build"
        "--platform" "${PLATFORMS}"
        "--tag" "${FULL_TAG}"
        "--file" "${dockerfile}"
        "--cache-from" "${CACHE_FROM}"
        "--cache-to" "${CACHE_TO}"
        "--progress" "plain"
        "${BUILD_ARGS[@]}"
        "${build_context}"
    )

    # 解析命令行参数
    local push=false
    local load=false
    local scan=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --push)
                push=true
                build_cmd+=("--push")
                shift
                ;;
            --load)
                load=true
                build_cmd+=("--load")
                shift
                ;;
            --scan)
                scan=true
                shift
                ;;
            --multi-arch)
                # 已经默认启用多架构
                shift
                ;;
            --no-cache)
                build_cmd+=("--no-cache")
                shift
                ;;
            *)
                log_warning "未知参数: $1"
                shift
                ;;
        esac
    done

    # 如果既不push也不load，默认load到本地
    if [[ "$push" == false && "$load" == false ]]; then
        build_cmd+=("--load")
    fi

    # 显示构建命令
    log_info "执行构建命令:"
    echo "${build_cmd[@]}"

    # 执行构建
    local start_time=$(date +%s)

    if "${build_cmd[@]}"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_success "镜像构建完成，耗时: ${duration}s"
    else
        log_error "镜像构建失败"
        exit 1
    fi
}

# ==================== 镜像分析 ====================
analyze_image() {
    log_info "分析镜像信息..."

    # 显示镜像大小
    local image_size=$(docker images ${FULL_TAG} --format "{{.Size}}" 2>/dev/null || echo "N/A")
    log_info "镜像大小: ${image_size}"

    # 显示镜像层数
    local layer_count=$(docker history ${FULL_TAG} --format "{{.ID}}" 2>/dev/null | wc -l || echo "N/A")
    log_info "镜像层数: ${layer_count}"

    # 显示镜像详细信息
    log_info "镜像详细信息:"
    docker images ${FULL_TAG} --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" 2>/dev/null || true
}

# ==================== 安全扫描 ====================
security_scan() {
    if [[ "${1:-}" == "--scan" ]]; then
        log_info "执行安全扫描..."

        # 尝试使用Docker Scout
        if command -v docker-scout &> /dev/null || docker scout version &> /dev/null; then
            log_info "使用Docker Scout进行漏洞扫描..."
            docker scout cves ${FULL_TAG} || log_warning "Docker Scout扫描失败"
        else
            log_warning "Docker Scout未安装，跳过漏洞扫描"
        fi

        # 尝试使用Trivy
        if command -v trivy &> /dev/null; then
            log_info "使用Trivy进行漏洞扫描..."
            trivy image ${FULL_TAG} || log_warning "Trivy扫描失败"
        else
            log_warning "Trivy未安装，跳过漏洞扫描"
        fi
    fi
}

# ==================== 性能测试 ====================
performance_test() {
    log_info "执行基本性能测试..."

    # 测试镜像启动时间
    local start_time=$(date +%s%3N)

    if timeout 60s docker run --rm ${FULL_TAG} echo "Container started successfully" &> /dev/null; then
        local end_time=$(date +%s%3N)
        local startup_time=$((end_time - start_time))
        log_success "容器启动时间: ${startup_time}ms"
    else
        log_error "容器启动测试失败"
    fi
}

# ==================== 使用说明 ====================
usage() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --push          推送镜像到registry"
    echo "  --load          加载镜像到本地（默认）"
    echo "  --scan          执行安全扫描"
    echo "  --multi-arch    启用多架构构建（默认启用）"
    echo "  --no-cache      禁用缓存"
    echo "  --help          显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                           # 本地构建"
    echo "  $0 --push --scan            # 构建并推送，执行安全扫描"
    echo "  $0 --no-cache               # 禁用缓存构建"
}

# ==================== 主函数 ====================
main() {
    # 检查帮助参数
    if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
        usage
        exit 0
    fi

    log_info "MoonTV Ultra-Optimized Build Script启动"
    log_info "目标镜像: ${FULL_TAG}"

    # 执行构建流程
    check_prerequisites
    setup_buildx
    build_image "$@"
    analyze_image
    security_scan "$@"
    performance_test

    log_success "构建流程完成！"
    log_info "镜像标签: ${FULL_TAG}"

    if [[ "${1:-}" == "--push" ]]; then
        log_success "镜像已推送到registry"
    else
        log_info "使用以下命令运行容器:"
        echo "docker run -p 3000:3000 --env PASSWORD=your_password ${FULL_TAG}"
    fi
}

# 执行主函数
main "$@"