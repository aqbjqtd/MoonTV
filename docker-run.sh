#!/bin/bash

# MoonTV Docker 启动脚本
# 版本: test-dev-v2

set -e

# 默认配置
IMAGE_NAME="moontv:test-dev-v2"
CONTAINER_NAME="moontv-app"
HOST_PORT="3000"
CONTAINER_PORT="3000"
PASSWORD=""
STORAGE_TYPE="localstorage"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 帮助信息
show_help() {
    echo -e "${BLUE}MoonTV Docker 启动脚本${NC}"
    echo -e "${BLUE}======================${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -p, --password PASSWORD     设置访问密码 (默认: 无密码)"
    echo "  -s, --storage TYPE          存储类型: localstorage|redis|upstash|d1 (默认: localstorage)"
    echo "  -P, --port PORT             主机端口 (默认: 3000)"
    echo "  -n, --name NAME             容器名称 (默认: moontv-app)"
    echo "  -i, --image IMAGE           镜像名称 (默认: moontv:test-dev-v2)"
    echo "  -d, --detach                后台运行"
    echo "  -k, --kill                  停止并删除现有容器"
    echo "  -l, --logs                  查看容器日志"
    echo "  -h, --help                  显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0                          # 使用默认配置启动"
    echo "  $0 -p mypassword -s redis   # 设置密码并使用Redis存储"
    echo "  $0 -P 8080 -d               # 使用8080端口后台运行"
    echo "  $0 -k                       # 停止并删除容器"
    echo ""
}

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

# 检查Docker是否运行
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker未运行或未安装"
        exit 1
    fi
}

# 检查镜像是否存在
check_image() {
    if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
        log_error "镜像 $IMAGE_NAME 不存在"
        log_info "请先构建镜像: docker build -t $IMAGE_NAME -f Dockerfile.four-stage ."
        exit 1
    fi
}

# 停止并删除容器
kill_container() {
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        log_info "停止容器 $CONTAINER_NAME..."
        docker stop "$CONTAINER_NAME"
    fi

    if docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
        log_info "删除容器 $CONTAINER_NAME..."
        docker rm "$CONTAINER_NAME"
    fi
    log_success "容器已停止并删除"
}

# 启动容器
start_container() {
    local detach_flag=""
    if [ "$DETACH" = "true" ]; then
        detach_flag="-d"
    fi

    log_info "启动 MoonTV 容器..."
    log_info "镜像: $IMAGE_NAME"
    log_info "容器名: $CONTAINER_NAME"
    log_info "端口: $HOST_PORT:$CONTAINER_PORT"
    log_info "存储类型: $STORAGE_TYPE"

    if [ -n "$PASSWORD" ]; then
        log_info "密码: 已设置"
    else
        log_warning "密码: 未设置 (空密码登录)"
    fi

    # 环境变量设置
    local env_vars="-e NEXT_PUBLIC_STORAGE_TYPE=$STORAGE_TYPE"
    if [ -n "$PASSWORD" ]; then
        env_vars="$env_vars -e PASSWORD=$PASSWORD"
    fi

    # 启动容器
    docker run $detach_flag \
        --name "$CONTAINER_NAME" \
        -p "$HOST_PORT:$CONTAINER_PORT" \
        $env_vars \
        "$IMAGE_NAME"

    if [ "$DETACH" = "true" ]; then
        log_success "容器已在后台启动"
        log_info "访问地址: http://localhost:$HOST_PORT"

        # 等待健康检查
        log_info "等待服务启动..."
        sleep 10

        if docker ps -f name="$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}" | grep -q "healthy"; then
            log_success "服务启动成功，健康检查通过"
        else
            log_warning "服务启动中，请稍后检查"
        fi
    fi
}

# 查看日志
show_logs() {
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        docker logs -f "$CONTAINER_NAME"
    else
        log_error "容器 $CONTAINER_NAME 未运行"
        exit 1
    fi
}

# 默认参数解析
DETACH="false"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--password)
            PASSWORD="$2"
            shift 2
            ;;
        -s|--storage)
            STORAGE_TYPE="$2"
            shift 2
            ;;
        -P|--port)
            HOST_PORT="$2"
            shift 2
            ;;
        -n|--name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        -i|--image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -d|--detach)
            DETACH="true"
            shift
            ;;
        -k|--kill)
            kill_container
            exit 0
            ;;
        -l|--logs)
            show_logs
            exit 0
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 主函数
main() {
    check_docker
    check_image

    # 如果容器已存在，先停止
    if docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
        log_warning "容器 $CONTAINER_NAME 已存在，正在停止..."
        kill_container
    fi

    start_container

    if [ "$DETACH" = "false" ]; then
        log_info "容器正在前台运行..."
        log_info "按 Ctrl+C 停止容器"
        # 等待容器启动
        sleep 5
        log_info "访问地址: http://localhost:$HOST_PORT"

        # 健康检查
        log_info "执行健康检查..."
        sleep 15

        if docker ps -f name="$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}" | grep -q "healthy"; then
            log_success "✅ 健康检查通过"
            log_info "📊 查看健康状态: curl http://localhost:$HOST_PORT/api/health"
        else
            log_warning "⚠️  健康检查中，请稍等"
        fi

        # 保持前台运行
        docker logs -f "$CONTAINER_NAME"
    fi
}

# 运行主函数
main