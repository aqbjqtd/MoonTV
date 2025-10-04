#!/bin/bash

# MoonTV项目Git简化工具
# 提供基本的Git操作自动化

set -e

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
MoonTV Git简化工具

用法: $0 [命令] [选项]

可用命令:
  status    显示Git状态
  add       添加文件到暂存区
  commit    提交更改
  push      推送到远程仓库
  pull      拉取远程更改
  clean     清理工作区
  help      显示此帮助信息

示例:
  $0 status                    # 显示当前状态
  $0 add .                     # 添加所有文件
  $0 commit "fix: 修复bug"      # 提交更改
  $0 push                      # 推送到远程
  $0 pull                      # 拉取更改
  $0 clean                     # 清理工作区
EOF
}

# 检查Git状态
show_status() {
    log_info "MoonTV项目Git状态检查..."
    echo "=================================="

    # 基本状态
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "当前目录不是Git仓库"
        return 1
    fi

    # 当前分支
    local branch=$(git branch --show-current 2>/dev/null || echo "未知")
    log_info "当前分支: $branch"

    # 工作区状态
    if git diff --quiet && git diff --cached --quiet; then
        log_success "工作区干净"
    else
        log_warning "工作区有未提交的更改"
        git status --short
    fi

    # 远程状态
    if git remote get-url origin >/dev/null 2>&1; then
        local remote_url=$(git remote get-url origin)
        log_info "远程仓库: $remote_url"

        # 检查是否有未推送的提交
        local unpushed=$(git log origin/$branch..$branch --oneline 2>/dev/null | wc -l)
        if [ "$unpushed" -gt 0 ]; then
            log_warning "有 $unpushed 个提交未推送"
        else
            log_success "所有提交已推送"
        fi
    else
        log_warning "未配置远程仓库"
    fi

    echo "=================================="
}

# 添加文件到暂存区
add_files() {
    local files="$1"
    log_info "添加文件到暂存区: $files"

    if [ "$files" = "." ]; then
        git add .
        log_success "已添加所有文件"
    else
        git add $files
        log_success "已添加指定文件"
    fi
}

# 提交更改
commit_changes() {
    local message="$1"

    if [ -z "$message" ]; then
        log_error "请提供提交信息"
        echo "用法: $0 commit \"提交信息\""
        return 1
    fi

    log_info "提交更改: $message"

    # 检查是否有暂存的更改
    if git diff --cached --quiet; then
        log_warning "没有暂存的更改"
        return 1
    fi

    git commit -m "$message"
    log_success "提交成功"
}

# 推送到远程仓库
push_changes() {
    local branch=$(git branch --show-current 2>/dev/null || echo "main")
    log_info "推送到远程仓库: $branch"

    if ! git remote get-url origin >/dev/null 2>&1; then
        log_error "未配置远程仓库"
        return 1
    fi

    if git push origin "$branch"; then
        log_success "推送成功"
    else
        log_error "推送失败"
        return 1
    fi
}

# 拉取远程更改
pull_changes() {
    local branch=$(git branch --show-current 2>/dev/null || echo "main")
    log_info "拉取远程更改: $branch"

    if ! git remote get-url origin >/dev/null 2>&1; then
        log_error "未配置远程仓库"
        return 1
    fi

    if git pull origin "$branch"; then
        log_success "拉取成功"
    else
        log_error "拉取失败"
        return 1
    fi
}

# 清理工作区
clean_workspace() {
    log_info "清理工作区..."

    # 清理未跟踪的文件
    if [ "$(git ls-files --others --exclude-standard | wc -l)" -gt 0 ]; then
        log_info "发现未跟踪的文件:"
        git ls-files --others --exclude-standard
        read -p "是否删除这些文件? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git clean -fd
            log_success "已清理未跟踪的文件"
        fi
    else
        log_success "没有未跟踪的文件"
    fi

    # 重置工作区更改
    if ! git diff --quiet; then
        log_warning "发现工作区更改"
        read -p "是否重置工作区更改? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git checkout -- .
            log_success "已重置工作区更改"
        fi
    else
        log_success "工作区干净"
    fi
}

# 主函数
main() {
    case "$1" in
        "status")
            show_status
            ;;
        "add")
            add_files "${2:-.}"
            ;;
        "commit")
            commit_changes "$2"
            ;;
        "push")
            push_changes
            ;;
        "pull")
            pull_changes
            ;;
        "clean")
            clean_workspace
            ;;
        "help"|"--help"|"-h"|"")
            show_help
            ;;
        *)
            log_error "未知命令: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# 运行主程序
main "$@"