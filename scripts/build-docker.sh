#!/bin/bash
# MoonTV Docker优化构建脚本
# 使用方法: ./scripts/build-docker.sh [options]

set -euo pipefail

# 默认配置
DOCKERFILE="Dockerfile.docker-optimal"
IMAGE_NAME="moontv"
IMAGE_TAG="optimized"
BUILD_ARGS=""
PUSH=false
PLATFORMS="linux/amd64,linux/arm64"
CACHE_FROM=""
CACHE_TO=""

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

# 帮助信息
show_help() {
    cat << EOF
MoonTV Docker构建脚本

使用方法:
    $0 [options]

选项:
    -h, --help              显示帮助信息
    -f, --dockerfile FILE   指定Dockerfile (默认: $DOCKERFILE)
    -t, --tag TAG          指定镜像标签 (默认: $IMAGE_TAG)
    -n, --name NAME        指定镜像名称 (默认: $IMAGE_NAME)
    -p, --push             构建后推送镜像
    -a, --arch ARCH        指定架构 (默认: $PLATFORMS)
    --cache-from FROM      指定缓存源
    --cache-to TO          指定缓存目标
    --no-cache             禁用缓存
    --prod                 生产环境构建优化
    --dev                  开发环境构建

示例:
    $0 --prod --push
    $0 --tag v1.0.0 --push
    $0 --no-cache --arch linux/amd64
    $0 --cache-from type=local,src=/tmp/.buildx-cache
EOF
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--dockerfile)
            DOCKERFILE="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -n|--name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -p|--push)
            PUSH=true
            shift
            ;;
        -a|--arch)
            PLATFORMS="$2"
            shift 2
            ;;
        --cache-from)
            CACHE_FROM="--cache-from $2"
            shift 2
            ;;
        --cache-to)
            CACHE_TO="--cache-to $2"
            shift 2
            ;;
        --no-cache)
            BUILD_ARGS="--no-cache"
            shift
            ;;
        --prod)
            BUILD_ARGS="$BUILD_ARGS --build-arg NODE_ENV=production"
            BUILD_ARGS="$BUILD_ARGS --build-arg DOCKER_ENV=true"
            shift
            ;;
        --dev)
            BUILD_ARGS="$BUILD_ARGS --build-arg NODE_ENV=development"
            DOCKERFILE="Dockerfile"
            shift
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    log_error "Docker未安装，请先安装Docker"
    exit 1
fi

# 检查Docker Buildx是否可用
if ! docker buildx version &> /dev/null; then
    log_error "Docker Buildx不可用，请升级Docker版本"
    exit 1
fi

# 检查Dockerfile是否存在
if [[ ! -f "$DOCKERFILE" ]]; then
    log_error "Dockerfile不存在: $DOCKERFILE"
    exit 1
fi

# 显示构建信息
log_info "开始构建Docker镜像..."
log_info "镜像名称: $IMAGE_NAME:$IMAGE_TAG"
log_info "Dockerfile: $DOCKERFILE"
log_info "目标架构: $PLATFORMS"

# 创建构建器实例
BUILDER_NAME="moontv-builder"
if ! docker buildx inspect "$BUILDER_NAME" &> /dev/null; then
    log_info "创建新的构建器实例: $BUILDER_NAME"
    docker buildx create --name "$BUILDER_NAME" --use --driver docker-container
else
    log_info "使用现有构建器实例: $BUILDER_NAME"
    docker buildx use "$BUILDER_NAME"
fi

# 构建参数
FULL_IMAGE_NAME="$IMAGE_NAME:$IMAGE_TAG"
BUILD_CMD="docker buildx build"

# 添加平台支持
if [[ "$PLATFORMS" == *","* ]]; then
    BUILD_CMD="$BUILD_CMD --platform $PLATFORMS"
fi

# 添加缓存配置
if [[ -n "$CACHE_FROM" ]]; then
    BUILD_CMD="$BUILD_CMD $CACHE_FROM"
fi

if [[ -n "$CACHE_TO" ]]; then
    BUILD_CMD="$BUILD_CMD $CACHE_TO"
fi

# 添加推送参数
if [[ "$PUSH" == "true" ]]; then
    BUILD_CMD="$BUILD_CMD --push"
else
    BUILD_CMD="$BUILD_CMD --load"
fi

# 添加构建参数
if [[ -n "$BUILD_ARGS" ]]; then
    BUILD_CMD="$BUILD_CMD $BUILD_ARGS"
fi

# 添加标签
BUILD_CMD="$BUILD_CMD --tag $FULL_IMAGE_NAME"

# 添加Dockerfile
BUILD_CMD="$BUILD_CMD --file $DOCKERFILE"

# 添加构建上下文
BUILD_CMD="$BUILD_CMD ."

# 记录开始时间
START_TIME=$(date +%s)

# 执行构建
log_info "执行构建命令..."
log_info "$BUILD_CMD"

if eval "$BUILD_CMD"; then
    # 计算构建时间
    END_TIME=$(date +%s)
    BUILD_TIME=$((END_TIME - START_TIME))

    log_success "构建完成！"
    log_info "构建时间: ${BUILD_TIME}秒"
    log_info "镜像大小:"

    # 显示镜像大小信息
    if [[ "$PUSH" != "true" ]]; then
        docker images | grep "$IMAGE_NAME" | grep "$IMAGE_TAG" | awk '{printf "  %s: %s\n", $1":"$2, $7}'
    fi

    # 如果是多平台构建，显示支持的架构
    if [[ "$PLATFORMS" == *","* ]]; then
        log_info "支持的架构: $PLATFORMS"
    fi

    # 安全扫描建议
    log_warning "建议进行安全扫描: docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $PWD:/root/.cache/ aquasec/trivy image $FULL_IMAGE_NAME"

else
    log_error "构建失败！"
    exit 1
fi

# 推送镜像
if [[ "$PUSH" == "true" ]]; then
    log_info "镜像已推送到仓库: $FULL_IMAGE_NAME"
fi

# 清理构建器（可选）
# log_info "清理构建器实例..."
# docker buildx rm "$BUILDER_NAME"

log_success "Docker构建脚本执行完成！"