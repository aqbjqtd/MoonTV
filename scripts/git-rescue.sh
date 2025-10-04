#!/bin/bash

# MoonTV项目Git救援脚本
# 使用方法: ./scripts/git-rescue.sh [命令]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 帮助信息
show_help() {
    echo -e "${BLUE}MoonTV Git救援脚本${NC}"
    echo "=================================="
    echo "用法: $0 [命令]"
    echo ""
    echo "可用命令:"
    echo "  clean          清理工作区，恢复到最后一次提交"
    echo "  reset-hard     硬重置到指定提交"
    echo "  reset-soft     软重置到指定提交（保留更改）"
    echo "  uncommit       撤销最后一次提交"
    echo "  unstage        取消暂存所有文件"
    echo "  fix-large      处理大文件问题"
    echo "  fix-permission 修复权限问题"
    echo "  restore-branch 恢复丢失的分支"
    echo "  emergency      紧急回滚（安全模式）"
    echo "  status         显示详细状态信息"
    echo "  help           显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 clean                    # 清理工作区"
    echo "  $0 reset-hard HEAD~1        # 硬重置到上一个提交"
    echo "  $0 uncommit                 # 撤销最后一次提交"
    echo "  $0 emergency                # 紧急回滚模式"
}

# 错误处理
error_exit() {
    echo -e "${RED}❌ 错误: $1${NC}" >&2
    exit 1
}

# 确认提示
confirm() {
    read -p "$1 (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}操作已取消${NC}"
        exit 0
    fi
}

# 备份当前状态
backup_state() {
    echo -e "${BLUE}📦 备份当前状态...${NC}"
    BACKUP_BRANCH="backup-$(date +%Y%m%d-%H%M%S)"
    git branch "$BACKUP_BRANCH" 2>/dev/null || true
    git stash push -m "Auto-backup $(date)" 2>/dev/null || true
    echo -e "${GREEN}✅ 备份完成: $BACKUP_BRANCH${NC}"
}

# 清理工作区
clean_workspace() {
    echo -e "${BLUE}🧹 清理工作区...${NC}"
    backup_state

    echo "清理未跟踪的文件..."
    git clean -fd

    echo "重置工作区到最后一次提交..."
    git reset --hard HEAD

    echo -e "${GREEN}✅ 工作区已清理${NC}"
}

# 硬重置
reset_hard() {
    local commit="${1:-HEAD}"
    echo -e "${BLUE}🔄 硬重置到 $commit...${NC}"

    confirm "确定要硬重置到 $commit 吗？这将丢失所有未提交的更改"
    backup_state

    git reset --hard "$commit"
    echo -e "${GREEN}✅ 已硬重置到 $commit${NC}"
}

# 软重置
reset_soft() {
    local commit="${1:-HEAD}"
    echo -e "${BLUE}🔄 软重置到 $commit...${NC}"

    backup_state
    git reset --soft "$commit"
    echo -e "${GREEN}✅ 已软重置到 $commit${NC}"
}

# 撤销最后一次提交
uncommit() {
    echo -e "${BLUE}↩️ 撤销最后一次提交...${NC}"

    if [ "$(git rev-list --count HEAD)" -eq 0 ]; then
        error_exit "没有可撤销的提交"
    fi

    echo "最后一次提交信息:"
    git log -1 --oneline

    confirm "确定要撤销最后一次提交吗？"
    backup_state

    git reset --soft HEAD~1
    echo -e "${GREEN}✅ 已撤销最后一次提交，更改保留在工作区${NC}"
}

# 取消暂存
unstage() {
    echo -e "${BLUE}📤 取消暂存所有文件...${NC}"
    git reset HEAD
    echo -e "${GREEN}✅ 已取消暂存所有文件${NC}"
}

# 修复大文件问题
fix_large_files() {
    echo -e "${BLUE}🔧 修复大文件问题...${NC}"

    # 查找大文件
    echo "查找大于50MB的文件..."
    LARGE_FILES=$(find . -type f \
        -not -path "./node_modules/*" \
        -not -path "./.git/*" \
        -size +50M 2>/dev/null || true)

    if [ -n "$LARGE_FILES" ]; then
        echo -e "${YELLOW}发现大文件:${NC}"
        echo "$LARGE_FILES"

        confirm "是否将这些文件添加到.gitignore？"

        for file in $LARGE_FILES; do
            if [ -f "$file" ]; then
                echo "$(basename "$file")" >> .gitignore
                git rm --cached "$file" 2>/dev/null || true
            fi
        done

        echo -e "${GREEN}✅ 大文件已处理${NC}"
    else
        echo -e "${GREEN}✅ 未发现异常大文件${NC}"
    fi

    # 检查Git历史中的大文件
    echo "检查Git历史中的大文件..."
    git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | sed -n 's/^blob //p' | sort -nrk2 | head -10 | while read -r size hash file; do
        if [ "$size" -gt 52428800 ]; then  # 50MB
            echo -e "${YELLOW}历史中的大文件: $file (${size} bytes)${NC}"
        fi
    done
}

# 修复权限问题
fix_permissions() {
    echo -e "${BLUE}🔐 修复权限问题...${NC}"

    # 修复文件权限
    find . -type f -name "*.sh" -exec chmod +x {} \;
    find . -type f -name "*.js" -exec chmod 644 {} \;
    find . -type f -name "*.ts" -exec chmod 644 {} \;
    find . -type f -name "*.tsx" -exec chmod 644 {} \;
    find . -type f -name "*.json" -exec chmod 644 {} \;

    # 修复目录权限
    find . -type d -exec chmod 755 {} \;

    echo -e "${GREEN}✅ 权限已修复${NC}"
}

# 恢复丢失的分支
restore_branch() {
    echo -e "${BLUE}🔍 恢复丢失的分支...${NC}"

    echo "显示reflog（最近50条）:"
    git reflog --oneline -50

    echo ""
    read -p "输入要恢复的commit哈希: " COMMIT_HASH

    if [ -z "$COMMIT_HASH" ]; then
        error_exit "未输入commit哈希"
    fi

    read -p "输入新分支名称: " BRANCH_NAME

    if [ -z "$BRANCH_NAME" ]; then
        error_exit "未输入分支名称"
    fi

    git checkout -b "$BRANCH_NAME" "$COMMIT_HASH"
    echo -e "${GREEN}✅ 已恢复分支: $BRANCH_NAME${NC}"
}

# 紧急回滚
emergency_rollback() {
    echo -e "${RED}🚨 紧急回滚模式${NC}"
    echo "=================================="

    # 显示当前状态
    echo "当前状态:"
    git status
    echo ""
    echo "最近5次提交:"
    git log --oneline -5

    echo ""
    echo "可用操作:"
    echo "1) 清理工作区（保留提交历史）"
    echo "2) 回滚到上一个提交"
    echo "3) 回滚到指定提交"
    echo "4) 仅取消暂存"
    echo "5) 查看reflog"

    read -p "选择操作 (1-5): " CHOICE

    case $CHOICE in
        1)
            clean_workspace
            ;;
        2)
            reset_hard "HEAD~1"
            ;;
        3)
            read -p "输入commit哈希: " COMMIT
            reset_hard "$COMMIT"
            ;;
        4)
            unstage
            ;;
        5)
            echo "Reflog:"
            git reflog --oneline -20
            ;;
        *)
            error_exit "无效选择"
            ;;
    esac
}

# 显示详细状态
show_status() {
    echo -e "${BLUE}📊 详细状态信息${NC}"
    echo "=================================="

    # 基础信息
    echo "仓库信息:"
    echo "  当前分支: $(git branch --show-current)"
    echo "  远程仓库: $(git remote get-url origin 2>/dev/null || echo '未配置')"
    echo "  提交数量: $(git rev-list --count HEAD 2>/dev/null || echo '0')"

    # 工作区状态
    echo ""
    echo "工作区状态:"
    git status --porcelain | while read -r line; do
        if [[ $line == M* ]]; then
            echo "  修改: ${line:2}"
        elif [[ $line == A* ]]; then
            echo "  新增: ${line:2}"
        elif [[ $line == D* ]]; then
            echo "  删除: ${line:2}"
        elif [[ $line == ??* ]]; then
            echo "  未跟踪: ${line:2}"
        fi
    done

    # 分支信息
    echo ""
    echo "分支信息:"
    git branch -vv

    # 远程状态
    echo ""
    echo "远程状态:"
    git remote show origin 2>/dev/null || echo "  未配置远程仓库"

    # 最近活动
    echo ""
    echo "最近活动:"
    git log --oneline -5 --graph --decorate
}

# 主程序
main() {
    # 检查是否在Git仓库中
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error_exit "当前目录不是Git仓库"
    fi

    case "${1:-help}" in
        "clean")
            clean_workspace
            ;;
        "reset-hard")
            reset_hard "$2"
            ;;
        "reset-soft")
            reset_soft "$2"
            ;;
        "uncommit")
            uncommit
            ;;
        "unstage")
            unstage
            ;;
        "fix-large")
            fix_large_files
            ;;
        "fix-permission")
            fix_permissions
            ;;
        "restore-branch")
            restore_branch
            ;;
        "emergency")
            emergency_rollback
            ;;
        "status")
            show_status
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            error_exit "未知命令: $1。使用 '$0 help' 查看帮助"
            ;;
    esac
}

# 运行主程序
main "$@"