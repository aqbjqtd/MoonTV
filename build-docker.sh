#!/bin/bash

# MoonTV Docker 镜像构建脚本
# 用法: ./build-docker.sh [tag]

set -e

# 默认参数
IMAGE_NAME="aqbjqtd/moontv"
DEFAULT_TAG="test"
TAG="${1:-$DEFAULT_TAG}"

# 颜色输出
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

# 检查 Docker 是否可用
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker 守护进程未运行，请启动 Docker"
        exit 1
    fi
}

# 构建镜像
build_image() {
    log_info "开始构建 Docker 镜像: ${IMAGE_NAME}:${TAG}"
    
    # 使用 BuildKit 进行构建
    DOCKER_BUILDKIT=1 docker build \
        --tag "${IMAGE_NAME}:${TAG}" \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        --progress=plain \
        .
    
    if [ $? -eq 0 ]; then
        log_success "镜像构建成功: ${IMAGE_NAME}:${TAG}"
    else
        log_error "镜像构建失败"
        exit 1
    fi
}

# 测试镜像
test_image() {
    log_info "测试镜像运行..."
    
    # 启动临时容器测试
    CONTAINER_ID=$(docker run -d -p 3000:3000 "${IMAGE_NAME}:${TAG}")
    
    if [ $? -eq 0 ]; then
        log_info "容器启动成功，等待服务就绪..."
        sleep 10
        
        # 检查容器状态
        if docker ps | grep -q "$CONTAINER_ID"; then
            log_success "容器运行正常"
            
            # 测试健康检查
            if curl -f http://localhost:3000/login > /dev/null 2>&1; then
                log_success "服务健康检查通过"
            else
                log_warning "服务健康检查失败，但容器仍在运行"
            fi
        else
            log_error "容器启动后异常退出"
            docker logs "$CONTAINER_ID"
            exit 1
        fi
        
        # 停止测试容器
        docker stop "$CONTAINER_ID" > /dev/null
        docker rm "$CONTAINER_ID" > /dev/null
        log_info "测试容器已清理"
    else
        log_error "容器启动失败"
        exit 1
    fi
}

# 推送镜像（可选）
push_image() {
    read -p "是否推送镜像到 Docker Hub? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "登录 Docker Hub..."
        docker login
        
        if [ $? -eq 0 ]; then
            log_info "推送镜像: ${IMAGE_NAME}:${TAG}"
            docker push "${IMAGE_NAME}:${TAG}"
            
            if [ $? -eq 0 ]; then
                log_success "镜像推送成功"
                echo ""
                echo "镜像信息:"
                echo "- 名称: ${IMAGE_NAME}:${TAG}"
                echo "- 拉取命令: docker pull ${IMAGE_NAME}:${TAG}"
            else
                log_error "镜像推送失败"
                exit 1
            fi
        else
            log_error "Docker Hub 登录失败"
            exit 1
        fi
    else
        log_info "跳过镜像推送"
    fi
}

# 显示镜像信息
show_image_info() {
    log_info "镜像构建完成"
    echo ""
    echo "📦 镜像详情:"
    echo "名称: ${IMAGE_NAME}:${TAG}"
    echo "大小: $(docker images --format "{{.Size}}" "${IMAGE_NAME}:${TAG}")"
    echo ""
    echo "🚀 运行命令:"
    echo "docker run -d -p 3000:3000 --name moontv ${IMAGE_NAME}:${TAG}"
    echo ""
    echo "🔍 查看日志:"
    echo "docker logs moontv"
    echo ""
    echo "🛑 停止容器:"
    echo "docker stop moontv && docker rm moontv"
}

# 主函数
main() {
    log_info "MoonTV Docker 镜像构建工具"
    echo "目标镜像: ${IMAGE_NAME}:${TAG}"
    echo ""
    
    check_docker
    build_image
    test_image
    show_image_info
    push_image
    
    log_success "所有操作完成!"
}

# 执行主函数
main "$@"