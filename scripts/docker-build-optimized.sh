#!/bin/bash
# =================================================================
# MoonTV 优化 Docker 构建脚本
# BuildKit 内联缓存 + 高级参数化 + 智能标签管理
# =================================================================

set -e

# 默认配置
DEFAULT_NODE_VERSION="20"
DEFAULT_ALPINE_VERSION="alpine"
DEFAULT_DISTROLESS_VERSION="debian12"
DEFAULT_PNPM_VERSION="8.15.0"
DEFAULT_REGISTRY="ghcr.io"
DEFAULT_CACHE_REGISTRY="cache.ghcr.io"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
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

# 显示帮助信息
show_help() {
    cat << EOF
MoonTV 优化 Docker 构建脚本

用法: $0 [选项] [标签]

选项:
  -h, --help              显示此帮助信息
  -t, --tag TAG           指定镜像标签 (默认: latest)
  -r, --registry REG      指定镜像仓库 (默认: $DEFAULT_REGISTRY)
  -c, --cache-reg REG     指定缓存仓库 (默认: $DEFAULT_CACHE_REGISTRY)
  --node-version VER      Node.js 版本 (默认: $DEFAULT_NODE_VERSION)
  --pnpm-version VER      pnpm 版本 (默认: $DEFAULT_PNPM_VERSION)
  --no-cache              禁用缓存
  --multi-arch            启用多架构构建
  --push                  构建后推送镜像
  --dry-run               仅显示构建命令，不执行
  -v, --verbose           详细输出

示例:
  $0 -t v4.0.1 -r myregistry.com/moontv
  $0 --multi-arch --push
  $0 --node-version 18 --pnpm-version 8.14.0
  $0 --dry-run -v

EOF
}

# 解析命令行参数
TAG="latest"
REGISTRY="$DEFAULT_REGISTRY"
CACHE_REGISTRY="$DEFAULT_CACHE_REGISTRY"
NODE_VERSION="$DEFAULT_NODE_VERSION"
PNPM_VERSION="$DEFAULT_PNPM_VERSION"
NO_CACHE=false
MULTI_ARCH=false
PUSH_IMAGE=false
DRY_RUN=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -c|--cache-reg)
            CACHE_REGISTRY="$2"
            shift 2
            ;;
        --node-version)
            NODE_VERSION="$2"
            shift 2
            ;;
        --pnpm-version)
            PNPM_VERSION="$2"
            shift 2
            ;;
        --no-cache)
            NO_CACHE=true
            shift
            ;;
        --multi-arch)
            MULTI_ARCH=true
            shift
            ;;
        --push)
            PUSH_IMAGE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -*)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
        *)
            TAG="$1"
            shift
            ;;
    esac
done

# 获取构建信息
APP_VERSION=${TAG:-latest}
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
IMAGE_NAME="${REGISTRY}/$(basename $(pwd) | tr '[:upper:]' '[:lower:]')"
CACHE_IMAGE="${CACHE_REGISTRY}/$(basename $(pwd) | tr '[:upper:]' '[:lower:]'):cache"

log_info "MoonTV Docker 构建配置:"
log_info "  镜像标签: $TAG"
log_info "  完整镜像: $IMAGE_NAME:$TAG"
log_info "  缓存镜像: $CACHE_IMAGE"
log_info "  Node.js 版本: $NODE_VERSION"
log_info "  pnpm 版本: $PNPM_VERSION"
log_info "  构建版本: $APP_VERSION"
log_info "  构建时间: $BUILD_DATE"
log_info "  Git 引用: $VCS_REF"
log_info "  多架构构建: $MULTI_ARCH"
log_info "  推送镜像: $PUSH_IMAGE"
log_info "  禁用缓存: $NO_CACHE"

# 启用 BuildKit
export DOCKER_BUILDKIT=1

# 构建基础命令
BUILD_CMD="docker build"

# 添加文件路径
BUILD_CMD="$BUILD_CMD -f Dockerfile.optimized"

# 添加构建参数
BUILD_CMD="$BUILD_CMD --build-arg NODE_VERSION=$NODE_VERSION"
BUILD_CMD="$BUILD_CMD --build-arg PNPM_VERSION=$PNPM_VERSION"
BUILD_CMD="$BUILD_CMD --build-arg APP_VERSION=$APP_VERSION"
BUILD_CMD="$BUILD_CMD --build-arg BUILD_DATE=$BUILD_DATE"
BUILD_CMD="$BUILD_CMD --build-arg VCS_REF=$VCS_REF"
BUILD_CMD="$BUILD_CMD --build-arg BUILDKIT_INLINE_CACHE=1"

# 添加缓存配置
if [ "$NO_CACHE" = false ]; then
    BUILD_CMD="$BUILD_CMD --cache-from type=registry,ref=$CACHE_IMAGE"
    BUILD_CMD="$BUILD_CMD --cache-to type=registry,ref=$CACHE_IMAGE,mode=max"
else
    BUILD_CMD="$BUILD_CMD --no-cache"
fi

# 添加多架构配置
if [ "$MULTI_ARCH" = true ]; then
    BUILD_CMD="docker buildx build $BUILD_CMD"
    BUILD_CMD="$BUILD_CMD --platform linux/amd64,linux/arm64"
else
    BUILD_CMD="$BUILD_CMD --load"
fi

# 添加推送配置
if [ "$PUSH_IMAGE" = true ]; then
    BUILD_CMD="$BUILD_CMD --push"
fi

# 添加标签
BUILD_CMD="$BUILD_CMD -t $IMAGE_NAME:$TAG"

# 如果是 latest 标签，同时添加 latest
if [ "$TAG" != "latest" ]; then
    BUILD_CMD="$BUILD_CMD -t $IMAGE_NAME:latest"
fi

# 添加上下文路径
BUILD_CMD="$BUILD_CMD ."

# 详细输出
if [ "$VERBOSE" = true ]; then
    log_info "构建命令:"
    echo "$BUILD_CMD"
    echo ""
fi

# 执行构建
if [ "$DRY_RUN" = false ]; then
    log_info "开始构建..."

    # 记录开始时间
    BUILD_START=$(date +%s)

    # 执行构建命令
    if eval "$BUILD_CMD"; then
        # 记录结束时间
        BUILD_END=$(date +%s)
        BUILD_DURATION=$((BUILD_END - BUILD_START))

        log_success "构建完成！"
        log_success "构建耗时: ${BUILD_DURATION}s"

        # 获取镜像信息
        if [ "$MULTI_ARCH" = false ] && [ "$PUSH_IMAGE" = false ]; then
            IMAGE_SIZE=$(docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" $IMAGE_NAME:$TAG | tail -n1 | awk '{print $2}')
            log_success "镜像大小: $IMAGE_SIZE"
        fi

        # 显示运行命令
        echo ""
        log_info "运行命令:"
        echo "docker run -d -p 3000:3000 --name moontv $IMAGE_NAME:$TAG"
        echo ""
        log_info "测试命令:"
        echo "curl http://localhost:3000/api/health"

    else
        log_error "构建失败！"
        exit 1
    fi
else
    log_info "Dry-run 模式，未执行构建"
fi

log_success "脚本执行完成！"