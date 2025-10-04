#!/bin/bash

# MoonTV项目Git自动化脚本
# 使用方法: ./scripts/git-automation.sh [命令]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_NAME="MoonTV"
DEFAULT_BRANCH="main"
DEPLOY_BRANCH="deploy"

# 日志函数
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "${PURPLE}🔄 $1${NC}"
}

# 检查必要工具
check_tools() {
    local tools=("git" "pnpm" "node")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool 未安装"
            exit 1
        fi
    done
}

# 获取当前分支
get_current_branch() {
    git branch --show-current
}

# 检查工作区状态
check_working_tree() {
    local status=$(git status --porcelain)
    if [ -n "$status" ]; then
        log_warning "工作区有未提交的更改"
        return 1
    fi
    return 0
}

# 运行项目检查
run_project_checks() {
    log_step "运行项目检查..."

    # 1. 依赖检查
    log_info "检查依赖..."
    if [ ! -d "node_modules" ]; then
        log_info "安装依赖..."
        pnpm install
    fi

    # 2. 代码格式检查
    log_info "检查代码格式..."
    if ! pnpm format:check; then
        log_warning "代码格式不正确，自动修复..."
        pnpm format
        git add .
    fi

    # 3. 代码质量检查
    log_info "检查代码质量..."
    if ! pnpm lint; then
        log_error "代码质量检查失败"
        return 1
    fi

    # 4. 类型检查
    log_info "检查类型..."
    if ! pnpm typecheck; then
        log_error "类型检查失败"
        return 1
    fi

    # 5. 测试检查（如果存在）
    if [ -d "__tests__" ] || [ -d "test" ] || [ -d "tests" ]; then
        log_info "运行测试..."
        pnpm test || log_warning "测试失败，但继续执行"
    fi

    log_success "项目检查通过"
    return 0
}

# 智能提交
smart_commit() {
    local message="$1"

    if [ -z "$message" ]; then
        log_error "请提供提交信息"
        return 1
    fi

    log_step "开始智能提交流程..."

    # 1. 检查工作区
    if ! check_working_tree; then
        log_info "暂存所有更改..."
        git add .
    fi

    # 2. 运行项目检查
    if ! run_project_checks; then
        log_error "项目检查失败，提交被中止"
        return 1
    fi

    # 3. 提交
    log_info "提交更改..."
    git commit -m "$message"

    log_success "提交成功: $message"
}

# 推送到远程
smart_push() {
    local branch="${1:-$(get_current_branch)}"
    local remote="${2:-origin}"

    log_step "推送分支 $branch 到 $remote..."

    # 1. 检查远程连接
    if ! git ls-remote "$remote" &> /dev/null; then
        log_error "无法连接到远程仓库 $remote"
        return 1
    fi

    # 2. 拉取最新更改
    log_info "拉取远程更新..."
    git fetch "$remote"

    # 3. 检查是否需要合并
    local local_hash=$(git rev-parse "$branch")
    local remote_hash=$(git rev-parse "$remote/$branch" 2>/dev/null || echo "")

    if [ "$local_hash" != "$remote_hash" ] && [ -n "$remote_hash" ]; then
        log_warning "本地和远程分支有差异"

        # 选择合并策略
        read -p "选择策略: (1)变基 (2)合并 [默认:1]: " -n 1 -r
        echo

        if [[ $REPLY =~ ^[2]$ ]]; then
            git pull "$remote" "$branch"
        else
            git pull --rebase "$remote" "$branch"
        fi
    fi

    # 4. 推送
    log_info "推送到远程..."
    git push "$remote" "$branch"

    log_success "推送成功"
}

# 创建功能分支
create_feature_branch() {
    local feature_name="$1"

    if [ -z "$feature_name" ]; then
        log_error "请提供功能名称"
        return 1
    fi

    local branch_name="feature/$feature_name"
    log_step "创建功能分支: $branch_name"

    # 1. 切换到主分支
    log_info "切换到主分支..."
    git checkout "$DEFAULT_BRANCH"

    # 2. 拉取最新更改
    log_info "拉取最新更改..."
    git fetch origin
    git pull origin "$DEFAULT_BRANCH"

    # 3. 创建新分支
    log_info "创建新分支..."
    git checkout -b "$branch_name"

    log_success "功能分支创建成功: $branch_name"
}

# 合并功能分支
merge_feature_branch() {
    local feature_branch="$1"

    if [ -z "$feature_branch" ]; then
        feature_branch=$(get_current_branch)
    fi

    if [[ ! "$feature_branch" == feature/* ]]; then
        log_error "当前不是功能分支: $feature_branch"
        return 1
    fi

    log_step "合并功能分支: $feature_branch"

    # 1. 检查功能分支状态
    if ! check_working_tree; then
        log_error "功能分支有未提交的更改"
        return 1
    fi

    # 2. 切换到主分支
    log_info "切换到主分支..."
    git checkout "$DEFAULT_BRANCH"

    # 3. 拉取最新更改
    log_info "拉取最新更改..."
    git fetch origin
    git pull origin "$DEFAULT_BRANCH"

    # 4. 合并功能分支
    log_info "合并功能分支..."
    git merge "$feature_branch"

    # 5. 运行检查
    if ! run_project_checks; then
        log_error "合并后检查失败"
        git merge --abort 2>/dev/null || true
        return 1
    fi

    # 6. 删除功能分支
    log_info "删除功能分支..."
    git branch -d "$feature_branch"
    git push origin --delete "$feature_branch" 2>/dev/null || log_warning "无法删除远程分支"

    log_success "功能分支合并成功"
}

# 部署准备
prepare_deploy() {
    log_step "准备部署..."

    # 1. 检查当前分支
    local current_branch=$(get_current_branch)
    if [ "$current_branch" != "$DEFAULT_BRANCH" ]; then
        log_warning "当前不在主分支，切换到主分支..."
        git checkout "$DEFAULT_BRANCH"
    fi

    # 2. 确保最新
    log_info "拉取最新更改..."
    git fetch origin
    git pull origin "$DEFAULT_BRANCH"

    # 3. 运行完整检查
    if ! run_project_checks; then
        log_error "部署前检查失败"
        return 1
    fi

    # 4. 构建项目
    log_info "构建项目..."
    if ! pnpm build; then
        log_error "构建失败"
        return 1
    fi

    # 5. 创建部署分支
    log_info "创建部署分支..."
    git checkout -b "$DEPLOY_BRANCH"

    # 6. 添加构建产物
    log_info "准备部署文件..."
    git add -f out/ .next/ build/ 2>/dev/null || true
    git commit -m "build: prepare for deployment $(date)" || log_warning "没有新的构建产物需要提交"

    log_success "部署准备完成"
}

# 自动化工作流
auto_workflow() {
    local task="$1"

    case $task in
        "feature")
            local feature_name="$2"
            if [ -z "$feature_name" ]; then
                read -p "输入功能名称: " feature_name
            fi
            create_feature_branch "$feature_name"
            ;;
        "commit")
            local message="$2"
            if [ -z "$message" ]; then
                read -p "输入提交信息: " message
            fi
            smart_commit "$message"
            ;;
        "push")
            smart_push
            ;;
        "merge")
            merge_feature_branch "$2"
            ;;
        "deploy")
            prepare_deploy
            ;;
        "complete")
            # 完整的功能开发工作流
            local feature_name="$2"
            if [ -z "$feature_name" ]; then
                read -p "输入功能名称: " feature_name
            fi

            create_feature_branch "$feature_name"
            log_success "功能分支已创建，开始开发..."
            log_info "开发完成后，运行: $0 merge $feature_name"
            ;;
        *)
            log_error "未知工作流: $task"
            return 1
            ;;
    esac
}

# 设置Git钩子
setup_hooks() {
    log_step "设置Git钩子..."

    # 检查husky是否已安装
    if [ ! -d ".husky" ]; then
        log_info "初始化husky..."
        pnpm prepare
    fi

    # 创建pre-commit钩子
    if [ ! -f ".husky/pre-commit" ]; then
        log_info "创建pre-commit钩子..."
        cat > .husky/pre-commit << 'EOF'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

# 运行lint-staged
npx lint-staged

# 运行类型检查
pnpm typecheck

# 检查大文件
./scripts/git-automation.sh check-large-files
EOF
        chmod +x .husky/pre-commit
    fi

    # 创建commit-msg钩子
    if [ ! -f ".husky/commit-msg" ]; then
        log_info "创建commit-msg钩子..."
        cat > .husky/commit-msg << 'EOF'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx --no -- commitlint --edit \$1
EOF
        chmod +x .husky/commit-msg
    fi

    log_success "Git钩子设置完成"
}

# 检查大文件
check_large_files() {
    local large_files=$(find . -type f \
        -not -path "./node_modules/*" \
        -not -path "./.git/*" \
        -not -path "./.next/*" \
        -size +10M 2>/dev/null || true)

    if [ -n "$large_files" ]; then
        log_error "发现大文件，请处理后再提交:"
        echo "$large_files"
        return 1
    fi
    return 0
}

# 显示帮助
show_help() {
    echo -e "${BLUE}$PROJECT_NAME Git自动化脚本${NC}"
    echo "=================================="
    echo "用法: $0 [命令] [参数]"
    echo ""
    echo "命令:"
    echo "  check              运行项目检查"
    echo "  commit <message>   智能提交"
    echo "  push [branch]      推送到远程"
    echo "  feature <name>     创建功能分支"
    echo "  merge [branch]     合并功能分支"
    echo "  deploy             准备部署"
    echo "  workflow <task>    自动化工作流"
    echo "  setup-hooks        设置Git钩子"
    echo "  check-large-files  检查大文件"
    echo "  help               显示帮助"
    echo ""
    echo "工作流任务:"
    echo "  feature <name>     创建功能分支"
    echo "  commit <message>   提交更改"
    echo "  push               推送到远程"
    echo "  merge [branch]     合并功能分支"
    echo "  deploy             准备部署"
    echo "  complete <name>    完整功能开发流程"
    echo ""
    echo "示例:"
    echo "  $0 commit 'feat: add video player'"
    echo "  $0 feature video-player"
    echo "  $0 workflow complete user-auth"

# 主程序
main() {
    # 检查Git仓库
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "当前目录不是Git仓库"
        exit 1
    fi

    # 检查工具
    check_tools

    case "${1:-help}" in
        "check")
            run_project_checks
            ;;
        "commit")
            smart_commit "$2"
            ;;
        "push")
            smart_push "$2" "$3"
            ;;
        "feature")
            create_feature_branch "$2"
            ;;
        "merge")
            merge_feature_branch "$2"
            ;;
        "deploy")
            prepare_deploy
            ;;
        "workflow")
            auto_workflow "$2" "$3"
            ;;
        "setup-hooks")
            setup_hooks
            ;;
        "check-large-files")
            check_large_files
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            log_error "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

# 运行主程序
main "$@"