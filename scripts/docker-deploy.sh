#!/bin/bash
# =================================================================
# MoonTV Docker 部署脚本
# 支持开发、测试和生产环境部署
# =================================================================

set -e  # 遇到错误立即退出

# 颜色定义
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
MoonTV Docker 部署脚本

用法: $0 [选项] [命令]

命令:
    build           构建Docker镜像
    dev             启动开发环境
    staging         启动测试环境
    production      启动生产环境
    logs            查看应用日志
    stop            停止所有服务
    clean           清理Docker资源
    update          更新部署
    status          查看服务状态

选项:
    -h, --help      显示此帮助信息
    -v, --verbose   详细输出
    -e, --env       指定环境文件 (默认: .env)
    -f, --force     强制执行（跳过确认）
    --no-cache      构建时不使用缓存
    --pull          拉取最新基础镜像

示例:
    $0 dev                    # 启动开发环境
    $0 production             # 启动生产环境
    $0 build --no-cache       # 无缓存构建
    $0 logs moontv            # 查看应用日志
    $0 update                 # 滚动更新

EOF
}

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装Docker"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装Docker Compose"
        exit 1
    fi

    log_success "依赖检查通过"
}

# 检查环境文件
check_env_file() {
    local env_file="${1:-.env}"

    if [[ ! -f "$env_file" ]]; then
        log_warning "环境文件 $env_file 不存在"
        if [[ -f ".env.example" ]]; then
            log_info "复制示例环境文件..."
            cp .env.example "$env_file"
            log_warning "请编辑 $env_file 文件配置正确的环境变量"
            read -p "是否继续？ (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        else
            log_error "找不到环境文件或示例文件"
            exit 1
        fi
    fi
}

# 构建镜像
build_images() {
    local no_cache=""
    if [[ "$NO_CACHE" == "true" ]]; then
        no_cache="--no-cache"
    fi

    local pull=""
    if [[ "$PULL" == "true" ]]; then
        pull="--pull"
    fi

    log_info "构建Docker镜像..."

    # 构建应用镜像
    if [[ "$VERBOSE" == "true" ]]; then
        docker build $no_cache $pull -f Dockerfile.optimized -t moontv:latest .
    else
        docker build $no_cache $pull -f Dockerfile.optimized -t moontv:latest . > /dev/null
    fi

    log_success "镜像构建完成"
}

# 启动开发环境
start_dev() {
    log_info "启动开发环境..."

    check_env_file

    # 启动应用和Redis
    docker-compose up -d moontv redis

    log_success "开发环境已启动"
    log_info "应用地址: http://localhost:3000"
    log_info "查看日志: $0 logs"
}

# 启动测试环境
start_staging() {
    log_info "启动测试环境..."

    check_env_file

    # 启动完整服务栈
    docker-compose --profile staging up -d

    log_success "测试环境已启动"
    log_info "应用地址: http://localhost:3000"
}

# 启动生产环境
start_production() {
    log_info "启动生产环境..."

    check_env_file

    # 检查必需的环境变量
    source .env
    if [[ -z "$PASSWORD" ]]; then
        log_error "生产环境必须设置PASSWORD环境变量"
        exit 1
    fi

    # 启动生产服务栈
    docker-compose --profile production up -d

    log_success "生产环境已启动"
    log_info "应用地址: http://localhost"

    # 启动监控（如果配置了）
    if [[ -n "$GRAFANA_PASSWORD" ]]; then
        log_info "Grafana地址: http://localhost:3001 (admin/$GRAFANA_PASSWORD)"
        log_info "Prometheus地址: http://localhost:9090"
    fi
}

# 查看日志
show_logs() {
    local service="$1"

    if [[ -n "$service" ]]; then
        docker-compose logs -f "$service"
    else
        docker-compose logs -f
    fi
}

# 停止服务
stop_services() {
    log_info "停止所有服务..."

    docker-compose down

    log_success "所有服务已停止"
}

# 清理Docker资源
clean_docker() {
    log_info "清理Docker资源..."

    if [[ "$FORCE" != "true" ]]; then
        read -p "这将删除所有Docker镜像、容器和数据卷，确定吗？ (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "操作已取消"
            exit 0
        fi
    fi

    # 停止并删除容器
    docker-compose down -v --remove-orphans

    # 删除镜像
    docker images -q moontv* | xargs -r docker rmi -f || true
    docker images -q gcr.io/distroless/nodejs20-debian12 | xargs -r docker rmi -f || true

    # 清理悬空镜像
    docker image prune -f

    # 清理数据卷（谨慎）
    if [[ "$FORCE" == "true" ]]; then
        docker volume prune -f
    fi

    log_success "Docker资源清理完成"
}

# 滚动更新
update_deployment() {
    log_info "执行滚动更新..."

    # 构建新镜像
    build_images

    # 停止旧容器
    docker-compose stop moontv

    # 启动新容器
    docker-compose up -d --no-deps moontv

    # 等待启动
    log_info "等待服务启动..."
    sleep 30

    # 健康检查
    if curl -f http://localhost:3000/health &> /dev/null; then
        log_success "滚动更新成功"
    else
        log_error "健康检查失败，请检查日志"
        show_logs moontv
        exit 1
    fi
}

# 查看服务状态
show_status() {
    log_info "服务状态:"
    echo

    # 显示容器状态
    docker-compose ps

    echo
    log_info "资源使用情况:"
    docker stats --no-stream

    echo
    log_info "健康检查状态:"
    docker-compose exec moontv curl -s http://localhost:3000/health || echo "健康检查失败"
}

# 主函数
main() {
    # 解析命令行参数
    VERBOSE=false
    FORCE=false
    NO_CACHE=false
    PULL=false
    ENV_FILE=".env"

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -e|--env)
                ENV_FILE="$2"
                shift 2
                ;;
            --no-cache)
                NO_CACHE=true
                shift
                ;;
            --pull)
                PULL=true
                shift
                ;;
            build)
                check_dependencies
                build_images
                exit 0
                ;;
            dev)
                check_dependencies
                start_dev
                exit 0
                ;;
            staging)
                check_dependencies
                start_staging
                exit 0
                ;;
            production)
                check_dependencies
                start_production
                exit 0
                ;;
            logs)
                show_logs "$2"
                exit 0
                ;;
            stop)
                stop_services
                exit 0
                ;;
            clean)
                check_dependencies
                clean_docker
                exit 0
                ;;
            update)
                check_dependencies
                update_deployment
                exit 0
                ;;
            status)
                show_status
                exit 0
                ;;
            *)
                log_error "未知命令: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 没有指定命令时显示帮助
    show_help
}

# 执行主函数
main "$@"