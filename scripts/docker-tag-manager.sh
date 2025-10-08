#!/bin/bash
# =================================================================
# MoonTV 智能标签管理脚本
# 自动生成和管理 Docker 镜像标签
# =================================================================

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 获取项目信息
get_project_info() {
    # 应用版本 (从 VERSION.txt 或 package.json)
    if [ -f "VERSION.txt" ]; then
        APP_VERSION=$(cat VERSION.txt | tr -d '\n\r')
    elif [ -f "package.json" ]; then
        APP_VERSION=$(grep '"version"' package.json | sed 's/.*"version": *"\([^"]*\)".*/\1/')
    else
        APP_VERSION="unknown"
    fi

    # 项目版本 (从 Git 标签)
    if git rev-parse --git-dir > /dev/null 2>&1; then
        PROJECT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "v4.0.0")
        COMMIT_SHA=$(git rev-parse --short HEAD)
        BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
        IS_CLEAN=$(git diff-index --quiet HEAD -- && echo "true" || echo "false")
    else
        PROJECT_VERSION="v4.0.0"
        COMMIT_SHA="unknown"
        BRANCH_NAME="unknown"
        IS_CLEAN="false"
    fi

    # 构建信息
    BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    BUILD_NUMBER=${BUILD_NUMBER:-"local"}
}

# 生成标签策略
generate_tags() {
    local registry=${1:-"ghcr.io/$(basename $(pwd))"}
    local tag_prefix=${2:-""}

    local tags=()

    # 主标签
    if [ -n "$tag_prefix" ]; then
        tags+=("$registry:$tag_prefix")
    fi

    # 应用版本标签
    if [ "$APP_VERSION" != "unknown" ]; then
        tags+=("$registry:v$APP_VERSION")
        tags+=("$registry:app-$APP_VERSION")
    fi

    # 项目版本标签
    if [ "$PROJECT_VERSION" != "unknown" ]; then
        tags+=("$registry:$PROJECT_VERSION")
    fi

    # 分支标签
    if [ "$BRANCH_NAME" != "unknown" ]; then
        local clean_branch=$(echo "$BRANCH_NAME" | sed 's/[^a-zA-Z0-9._-]/-/g')
        tags+=("$registry:branch-$clean_branch")

        # 主分支特殊处理
        if [ "$BRANCH_NAME" = "main" ] || [ "$BRANCH_NAME" = "master" ]; then
            tags+=("$registry:stable")
        fi
    fi

    # Git SHA 标签
    if [ "$COMMIT_SHA" != "unknown" ]; then
        tags+=("$registry:sha-$COMMIT_SHA")
    fi

    # 构建信息标签
    if [ "$BUILD_NUMBER" != "local" ]; then
        tags+=("$registry:build-$BUILD_NUMBER")
    fi

    # 开发版本特殊标签
    if [ "$IS_CLEAN" = "false" ]; then
        tags+=("$registry:dirty")
        tags+=("$registry:dev-$(date +%Y%m%d-%H%M%S)")
    fi

    # 时间戳标签
    tags+=("$registry:$(date +%Y%m%d)")

    # latest 标签（仅主分支）
    if [ "$BRANCH_NAME" = "main" ] || [ "$BRANCH_NAME" = "master" ]; then
        tags+=("$registry:latest")
    fi

    echo "${tags[@]}"
}

# 显示项目信息
show_project_info() {
    log_info "项目信息:"
    log_info "  应用版本: $APP_VERSION"
    log_info "  项目版本: $PROJECT_VERSION"
    log_info "  分支名称: $BRANCH_NAME"
    log_info "  提交 SHA: $COMMIT_SHA"
    log_info "  工作区状态: $([ "$IS_CLEAN" = "true" ] && echo "干净" || echo "有修改")"
    log_info "  构建日期: $BUILD_DATE"
    log_info "  构建编号: $BUILD_NUMBER"
}

# 显示标签策略
show_tags() {
    local registry=${1:-"ghcr.io/$(basename $(pwd))"}
    local tag_prefix=${2:-""}

    log_info "生成的标签策略:"

    local tags=($(generate_tags "$registry" "$tag_prefix"))
    for tag in "${tags[@]}"; do
        echo "  $tag"
    done

    log_info "总计: ${#tags[@]} 个标签"
}

# 推送标签
push_tags() {
    local source_tag=$1
    local registry=${2:-"ghcr.io/$(basename $(pwd))"}
    local tag_prefix=${3:-""}

    log_info "推送标签到仓库: $registry"

    local tags=($(generate_tags "$registry" "$tag_prefix"))

    for tag in "${tags[@]}"; do
        if [ "$tag" != "$source_tag" ]; then
            log_info "推送标签: $tag"
            docker tag "$source_tag" "$tag"

            if docker push "$tag"; then
                log_success "✓ 推送成功: $tag"
            else
                log_error "✗ 推送失败: $tag"
            fi
        fi
    done
}

# 清理旧标签
cleanup_old_tags() {
    local registry=${1:-"ghcr.io/$(basename $(pwd))"}
    local keep_count=${2:-10}

    log_info "清理旧标签，保留最近 $keep_count 个"

    # 获取远程标签列表
    if command -v skopeo > /dev/null; then
        skopeo list-tags "docker://$registry" | \
            jq -r '.Tags[]' | \
            sort -V -r | \
            tail -n +$((keep_count + 1)) | \
            while read -r tag; do
                log_info "删除旧标签: $registry:$tag"
                skopeo delete "docker://$registry:$tag" || true
            done
    else
        log_warning "skopeo 未安装，跳过标签清理"
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
MoonTV 智能标签管理脚本

用法: $0 <命令> [选项]

命令:
  info                    显示项目信息
  tags [registry] [prefix] 显示生成的标签策略
  push <source-tag> [registry] [prefix] 推送标签到仓库
  cleanup [registry] [count] 清理旧标签
  help                    显示此帮助信息

示例:
  $0 info
  $0 tags ghcr.io/username/moontv
  $0 push moontv:latest ghcr.io/username/moontv
  $0 cleanup ghcr.io/username/moontv 20

环境变量:
  BUILD_NUMBER            构建编号 (默认: local)
  DOCKER_REGISTRY         默认镜像仓库

EOF
}

# 主函数
main() {
    # 获取项目信息
    get_project_info

    # 解析命令
    case "${1:-help}" in
        info)
            show_project_info
            ;;
        tags)
            show_project_info
            echo ""
            show_tags "$2" "$3"
            ;;
        push)
            if [ -z "$2" ]; then
                log_error "请指定源标签"
                exit 1
            fi
            show_project_info
            echo ""
            push_tags "$2" "$3" "$4"
            ;;
        cleanup)
            cleanup_old_tags "$2" "$3"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"