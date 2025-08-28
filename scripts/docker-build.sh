#!/bin/bash
# =================================================================
# MoonTV 分层镜像构建脚本
# 功能：缓存优化构建、多环境支持、镜像管理
# =================================================================

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
IMAGE_NAME=${IMAGE_NAME:-"moontv"}
VERSION=${VERSION:-"latest"}
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
DOCKER_FILE=${DOCKER_FILE:-"Dockerfile.optimized"}
PLATFORM=${PLATFORM:-"linux/amd64,linux/arm64"}

# 打印函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Docker环境
check_docker() {
    print_info "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker未安装或不在PATH中"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon未运行"
        exit 1
    fi
    
    # 检查buildx支持
    if ! docker buildx version &> /dev/null; then
        print_warning "Docker buildx不可用，将使用传统构建"
        USE_BUILDX=false
    else
        USE_BUILDX=true
    fi
    
    print_success "Docker环境检查完成"
}

# 清理旧镜像
cleanup_images() {
    print_info "清理悬空镜像..."
    
    # 清理无标签镜像
    if docker images -f "dangling=true" -q | grep -q .; then
        docker rmi $(docker images -f "dangling=true" -q) || true
    fi
    
    # 清理旧的构建缓存
    docker builder prune -f || true
    
    print_success "镜像清理完成"
}

# 分层构建函数
build_layered() {
    local target=$1
    local tag="${IMAGE_NAME}:${target}"
    
    print_info "构建阶段: ${target}"
    
    if [ "$USE_BUILDX" = true ]; then
        docker buildx build \
            --platform $PLATFORM \
            --target $target \
            --tag $tag \
            --build-arg BUILD_DATE="$BUILD_DATE" \
            --cache-from type=local,src=/tmp/.buildx-cache \
            --cache-to type=local,dest=/tmp/.buildx-cache-new,mode=max \
            --file $DOCKER_FILE \
            --load \
            .
    else
        docker build \
            --target $target \
            --tag $tag \
            --build-arg BUILD_DATE="$BUILD_DATE" \
            --file $DOCKER_FILE \
            .
    fi
    
    print_success "阶段 ${target} 构建完成"
}

# 主构建流程
main_build() {
    print_info "开始分层镜像构建..."
    print_info "镜像名称: ${IMAGE_NAME}"
    print_info "版本标签: ${VERSION}"
    print_info "构建时间: ${BUILD_DATE}"
    print_info "Dockerfile: ${DOCKER_FILE}"
    
    # 创建buildx缓存目录
    [ "$USE_BUILDX" = true ] && mkdir -p /tmp/.buildx-cache
    
    # 分层构建
    build_layered "base"
    build_layered "deps"  
    build_layered "builder"
    build_layered "runner"
    
    # 标记最终镜像
    docker tag "${IMAGE_NAME}:runner" "${IMAGE_NAME}:${VERSION}"
    docker tag "${IMAGE_NAME}:runner" "${IMAGE_NAME}:latest"
    
    # 移动buildx缓存
    if [ "$USE_BUILDX" = true ]; then
        rm -rf /tmp/.buildx-cache
        mv /tmp/.buildx-cache-new /tmp/.buildx-cache || true
    fi
    
    print_success "所有构建阶段完成!"
}

# 镜像信息显示
show_image_info() {
    print_info "镜像构建信息:"
    echo "----------------------------------------"
    docker images | grep "$IMAGE_NAME" | head -10
    echo "----------------------------------------"
    
    # 显示镜像大小对比
    local final_size=$(docker images --format "table {{.Size}}" "${IMAGE_NAME}:latest" | tail -n +2)
    print_success "最终镜像大小: $final_size"
    
    # 显示镜像层信息
    print_info "镜像层信息:"
    docker history "${IMAGE_NAME}:latest" --no-trunc
}

# 运行测试
test_image() {
    print_info "测试镜像..."
    
    # 启动容器测试
    local container_id=$(docker run -d -p 3001:3000 "${IMAGE_NAME}:latest")
    
    # 等待启动
    sleep 10
    
    # 健康检查
    if curl -f http://localhost:3001/api/health &> /dev/null; then
        print_success "镜像测试通过"
    else
        print_error "镜像测试失败"
        docker logs $container_id
    fi
    
    # 清理测试容器
    docker stop $container_id
    docker rm $container_id
}

# 推送镜像
push_image() {
    if [ -n "${REGISTRY:-}" ]; then
        print_info "推送镜像到注册表: $REGISTRY"
        
        local registry_image="${REGISTRY}/${IMAGE_NAME}:${VERSION}"
        docker tag "${IMAGE_NAME}:latest" "$registry_image"
        docker push "$registry_image"
        
        print_success "镜像推送完成: $registry_image"
    fi
}

# 主函数
main() {
    print_info "MoonTV 分层镜像构建脚本启动"
    
    check_docker
    cleanup_images
    main_build
    show_image_info
    
    # 可选功能
    if [ "${RUN_TESTS:-false}" = "true" ]; then
        test_image
    fi
    
    if [ -n "${REGISTRY:-}" ]; then
        push_image
    fi
    
    print_success "构建流程完成!"
}

# 显示帮助信息
show_help() {
    cat << EOF
MoonTV 分层镜像构建脚本

用法: $0 [选项]

选项:
    -h, --help          显示帮助信息
    -n, --name NAME     设置镜像名称 (默认: moontv)
    -v, --version VER   设置版本标签 (默认: latest)
    -f, --file FILE     指定Dockerfile (默认: Dockerfile.optimized)
    -t, --test          构建后运行测试
    -p, --push          推送到注册表
    -c, --cleanup       构建前清理镜像

环境变量:
    IMAGE_NAME          镜像名称
    VERSION             版本标签
    DOCKER_FILE         Dockerfile路径
    REGISTRY            镜像注册表地址
    PLATFORM            目标平台 (默认: linux/amd64,linux/arm64)
    RUN_TESTS           是否运行测试 (true/false)

示例:
    $0                              # 默认构建
    $0 --name myapp --version 1.0   # 自定义名称和版本
    $0 --test --push                # 构建、测试并推送
EOF
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -f|--file)
            DOCKER_FILE="$2"
            shift 2
            ;;
        -t|--test)
            RUN_TESTS=true
            shift
            ;;
        -p|--push)
            PUSH_IMAGE=true
            shift
            ;;
        -c|--cleanup)
            CLEANUP_FIRST=true
            shift
            ;;
        *)
            print_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 执行主函数
main