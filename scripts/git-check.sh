#!/bin/bash

# MoonTV项目Git健康检查脚本
# 使用方法: ./scripts/git-check.sh

set -e

echo "🏥 MoonTV项目Git健康检查开始..."
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查函数
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
    fi
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 1. 检查Git仓库状态
echo "1. 检查Git仓库状态..."
if git rev-parse --git-dir > /dev/null 2>&1; then
    check_status "Git仓库初始化正常"
else
    echo -e "${RED}❌ 当前目录不是Git仓库${NC}"
    exit 1
fi

# 2. 检查工作区状态
echo -e "\n2. 检查工作区状态..."
STATUS=$(git status --porcelain)
if [ -z "$STATUS" ]; then
    check_status "工作区干净"
else
    warning "工作区有未提交的更改:"
    echo "$STATUS"
fi

# 3. 检查分支状态
echo -e "\n3. 检查分支状态..."
CURRENT_BRANCH=$(git branch --show-current)
TRACKING_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "无跟踪分支")
echo "当前分支: $CURRENT_BRANCH"
echo "跟踪分支: $TRACKING_BRANCH"

if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    check_status "在主分支上"
else
    warning "在功能分支上: $CURRENT_BRANCH"
fi

# 4. 检查远程连接
echo -e "\n4. 检查远程连接..."
if git remote | grep -q "origin"; then
    REMOTE_URL=$(git remote get-url origin)
    echo "远程仓库: $REMOTE_URL"

    if [[ "$REMOTE_URL" == *"@"* ]]; then
        # SSH连接测试
        if timeout 10 ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
            check_status "SSH连接正常"
        else
            warning "SSH连接可能有问题，请检查密钥配置"
        fi
    else
        check_status "HTTPS连接配置"
    fi
else
    warning "未配置远程仓库"
fi

# 5. 检查最近的提交
echo -e "\n5. 检查最近的提交..."
COMMIT_COUNT=$(git rev-list --count HEAD 2>/dev/null || echo "0")
if [ "$COMMIT_COUNT" -gt 0 ]; then
    echo "最近5次提交:"
    git log --oneline -5 --color=always
    check_status "找到 $COMMIT_COUNT 次提交"
else
    warning "未找到任何提交"
fi

# 6. 检查大文件
echo -e "\n6. 检查大文件..."
LARGE_FILES=$(find . -type f \
    -not -path "./node_modules/*" \
    -not -path "./.next/*" \
    -not -path "./out/*" \
    -not -path "./.git/*" \
    -size +10M \
    2>/dev/null || true)

if [ -n "$LARGE_FILES" ]; then
    warning "发现大文件:"
    echo "$LARGE_FILES"
else
    check_status "未发现异常大文件"
fi

# 7. 检查.gitignore配置
echo -e "\n7. 检查.gitignore配置..."
if [ -f .gitignore ]; then
    # 检查关键忽略项
    CRITICAL_IGNORES=(
        "node_modules"
        ".next"
        "out"
        ".env"
        ".DS_Store"
        "coverage"
    )

    MISSING_IGNORES=()
    for ignore in "${CRITICAL_IGNORES[@]}"; do
        if ! grep -q "^$ignore$" .gitignore; then
            MISSING_IGNORES+=("$ignore")
        fi
    done

    if [ ${#MISSING_IGNORES[@]} -eq 0 ]; then
        check_status ".gitignore配置完整"
    else
        warning ".gitignore缺少以下关键项:"
        printf '  %s\n' "${MISSING_IGNORES[@]}"
    fi
else
    warning ".gitignore文件不存在"
fi

# 8. 检查Git配置
echo -e "\n8. 检查Git配置..."
USER_NAME=$(git config user.name || echo "未配置")
USER_EMAIL=$(git config user.email || echo "未配置")

if [ "$USER_NAME" != "未配置" ] && [ "$USER_EMAIL" != "未配置" ]; then
    echo "用户名: $USER_NAME"
    echo "邮箱: $USER_EMAIL"
    check_status "Git用户配置完整"
else
    warning "Git用户配置不完整"
fi

# 9. 检查hooks状态
echo -e "\n9. 检查Git Hooks..."
if [ -d .git/hooks ]; then
    HOOKS_COUNT=$(find .git/hooks -name "*.sample" -not -name "*.sample.sample" | wc -l)
    ACTIVE_HOOKS_COUNT=$(find .git/hooks -type f -not -name "*.sample" | wc -l)
    echo "可用hooks: $HOOKS_COUNT"
    echo "激活hooks: $ACTIVE_HOOKS_COUNT"

    if [ -f .git/hooks/pre-commit ]; then
        check_status "pre-commit hook已激活"
    else
        warning "pre-commit hook未激活"
    fi
else
    warning "Git hooks目录不存在"
fi

# 10. 检查项目特定文件
echo -e "\n10. 检查项目特定文件..."
PROJECT_FILES=(
    "package.json"
    "next.config.js"
    "tailwind.config.js"
    "tsconfig.json"
)

for file in "${PROJECT_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_status "$file 存在"
    else
        warning "$file 不存在"
    fi
done

# 11. 生成建议
echo -e "\n=================================="
echo -e "${BLUE}🎯 建议操作:${NC}"

# 基于检查结果给出建议
if [ -n "$STATUS" ]; then
    info "有未提交的更改，建议: git add . && git commit -m 'feat: update files'"
fi

if [[ "$REMOTE_URL" == *"@"* ]] && ! timeout 10 ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    info "SSH连接有问题，建议检查SSH密钥配置"
fi

if [ ${#MISSING_IGNORES[@]} -gt 0 ]; then
    info "建议更新.gitignore文件，添加缺少的忽略项"
fi

if [ "$USER_NAME" = "未配置" ] || [ "$USER_EMAIL" = "未配置" ]; then
    info "建议配置Git用户信息: git config --global user.name 'Your Name' && git config --global user.email 'your-email@example.com'"
fi

if [ ! -f .git/hooks/pre-commit ]; then
    info "建议启用pre-commit hooks: npx husky install"
fi

echo -e "\n${GREEN}🎉 Git健康检查完成！${NC}"