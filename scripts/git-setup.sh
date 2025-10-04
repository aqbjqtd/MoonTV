#!/bin/bash

# MoonTV项目Git配置优化脚本
# 使用方法: ./scripts/git-setup.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="MoonTV"
PROJECT_TYPE="Next.js"

echo -e "${BLUE}🔧 $PROJECT_NAME Git配置优化${NC}"
echo "=================================="

# 配置函数
setup_git_config() {
    echo -e "\n1. 配置Git基础设置..."

    # 用户信息
    if [ -z "$(git config user.name)" ]; then
        read -p "输入您的姓名: " USER_NAME
        git config --global user.name "$USER_NAME"
    fi

    if [ -z "$(git config user.email)" ]; then
        read -p "输入您的邮箱: " USER_EMAIL
        git config --global user.email "$USER_EMAIL"
    fi

    # 编辑器
    if [ -z "$(git config core.editor)" ]; then
        git config --global core.editor "nano"
    fi

    # 默认分支名称
    git config --global init.defaultBranch main

    # 推送策略
    git config --global push.default simple

    # 拉取策略（推荐rebase）
    git config --global pull.rebase true

    # 合并策略（仅快进）
    git config --global merge.ff only

    echo -e "${GREEN}✅ Git基础配置完成${NC}"
}

setup_wsl_config() {
    echo -e "\n2. 配置WSL环境..."

    # 检测WSL环境
    if grep -q Microsoft /proc/version; then
        echo "检测到WSL环境，应用WSL特定配置..."

        # 行尾符处理（WSL环境使用input）
        git config --global core.autocrlf input
        git config --global core.eol lf

        # 文件模式
        git config --global core.filemode false

        # 权限处理
        git config --global core.protectNTFS false

        echo -e "${GREEN}✅ WSL配置完成${NC}"
    else
        echo -e "${YELLOW}⚠️  非WSL环境，跳过WSL配置${NC}"
    fi
}

setup_performance() {
    echo -e "\n3. 性能优化配置..."

    # HTTP缓冲区大小（用于大文件推送）
    git config --global http.postBuffer 524288000  # 500MB

    # 压缩级别
    git config --global core.compression 0

    # 并行操作
    git config --global submodule.fetchJobs 8

    # 缓存设置
    git config --global core.packedGitLimit 512m
    git config --global core.packedGitWindowSize 32k

    echo -e "${GREEN}✅ 性能配置完成${NC}"
}

setup_aliases() {
    echo -e "\n4. 设置Git别名..."

    # 常用别名
    git config --global alias.st status
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.unstage 'reset HEAD --'
    git config --global alias.last 'log -1 HEAD'
    git config --global alias.tree 'log --graph --oneline --decorate --all'
    git config --global alias.uncommit 'reset --soft HEAD~1'
    git config --global alias.amend 'commit --amend --no-edit'

    # 项目特定别名
    git config --global alias.check './scripts/git-check.sh'
    git config --global alias.rescue './scripts/git-rescue.sh'
    git config --global alias.auto './scripts/git-automation.sh'
    git config --global alias.dev '!git checkout main && git pull origin main && ./scripts/git-automation.sh feature'
    git config --global alias.done '!./scripts/git-automation.sh merge'

    echo -e "${GREEN}✅ 别名设置完成${NC}"
}

setup_ignore() {
    echo -e "\n5. 优化.gitignore..."

    if [ ! -f .gitignore ]; then
        echo "创建.gitignore文件..."
        cat > .gitignore << 'EOF'
# See https://help.github.com/articles/ignoring-files/ for more about ignoring files.

# dependencies
/node_modules
/.pnp
.pnp.js

# testing
/coverage

# next.js
/.next/
/out/
/build/

# misc
.DS_Store
*.pem

# IDE
.vscode
.idea/
*.swp
*.swo

# debug
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.pnpm-debug.log*

# local env files
.env
.env*.local

# vercel
.vercel

# typescript
*.tsbuildinfo
next-env.d.ts

# next-sitemap
sitemap.xml
sitemap-*.xml

# generated files
src/lib/runtime.ts
public/manifest.json

# OS specific
Thumbs.db
*.tmp
*.temp

# Logs
logs
*.log

# Cache
.cache
.parcel-cache

# Lock files (keep package-lock.json but ignore yarn.lock if using npm)
# yarn.lock

# Testing
.nyc_output

# Storybook
.storybook-out

# Temporary folders
tmp/
temp/
EOF
        git add .gitignore
        git commit -m "chore: add .gitignore file" 2>/dev/null || echo "No initial commit yet"
    else
        echo "检查现有.gitignore完整性..."
        # 可以添加更详细的检查逻辑
    fi

    echo -e "${GREEN}✅ .gitignore配置完成${NC}"
}

setup_hooks() {
    echo -e "\n6. 设置Git Hooks..."

    # 检查package.json中是否有husky
    if [ -f package.json ] && grep -q "husky" package.json; then
        echo "检测到husky配置，设置hooks..."

        # 初始化husky
        if [ ! -d .husky ]; then
            npx husky install
            npm pkg set scripts.prepare="husky install"
        fi

        # 创建pre-commit hook
        if [ ! -f .husky/pre-commit ]; then
            npx husky add .husky/pre-commit "npm run lint && npm run typecheck"
            echo "Created pre-commit hook"
        fi

        # 创建commit-msg hook
        if [ ! -f .husky/commit-msg ]; then
            npx husky add .husky/commit-msg "npx --no -- commitlint --edit \$1"
            echo "Created commit-msg hook"
        fi

        echo -e "${GREEN}✅ Git Hooks设置完成${NC}"
    else
        echo -e "${YELLOW}⚠️  未检测到husky，跳过Hooks设置${NC}"
        echo "建议安装husky: npm install --save-dev husky @commitlint/cli @commitlint/config-conventional"
    fi
}

setup_ssh() {
    echo -e "\n7. SSH配置检查..."

    # 检查SSH密钥
    if [ ! -f ~/.ssh/id_ed25519 ] && [ ! -f ~/.ssh/id_rsa ]; then
        echo "未找到SSH密钥，是否生成新密钥？(y/N)"
        read -r GENERATE_SSH

        if [[ $GENERATE_SSH =~ ^[Yy]$ ]]; then
            echo "生成新的SSH密钥..."
            ssh-keygen -t ed25519 -C "$(git config user.email)"

            echo "SSH密钥已生成，请将公钥添加到GitHub:"
            echo "cat ~/.ssh/id_ed25519.pub"
            echo ""
            echo "然后测试连接: ssh -T git@github.com"
        fi
    else
        echo "SSH密钥已存在"

        # 测试SSH连接
        if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
            echo -e "${GREEN}✅ SSH连接正常${NC}"
        else
            echo -e "${YELLOW}⚠️  SSH连接可能有问题${NC}"
            echo "请检查SSH密钥是否已添加到GitHub"
        fi
    fi
}

setup_project_specific() {
    echo -e "\n8. 项目特定配置..."

    # 检查是否是Next.js项目
    if [ -f package.json ] && grep -q "next" package.json; then
        echo "检测到Next.js项目，应用特定配置..."

        # 设置LFS（如果需要）
        if [ ! -f .gitattributes ]; then
            echo "创建.gitattributes..."
            cat > .gitattributes << 'EOF'
# Auto detect text files and perform LF normalization
* text=auto eol=lf

# Explicitly declare text files you want to always be normalized and converted
# to native line endings on checkout.
*.js text eol=lf
*.jsx text eol=lf
*.ts text eol=lf
*.tsx text eol=lf
*.json text eol=lf
*.md text eol=lf
*.yml text eol=lf
*.yaml text eol=lf

# Denote all files that are truly binary and should not be modified.
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.svg binary
*.woff binary
*.woff2 binary

# Large files
*.mp4 filter=lfs diff=lfs merge=lfs -text
*.zip filter=lfs diff=lfs merge=lfs -text
*.tar.gz filter=lfs diff=lfs merge=lfs -text
EOF
            git add .gitattributes
            git commit -m "chore: add .gitattributes for Next.js project" 2>/dev/null || echo "No initial commit yet"
        fi

        echo -e "${GREEN}✅ Next.js配置完成${NC}"
    fi
}

setup_remote() {
    echo -e "\n9. 远程仓库配置..."

    # 检查是否有远程仓库
    if ! git remote get-url origin &>/dev/null; then
        echo "未配置远程仓库，是否现在配置？(y/N)"
        read -r SETUP_REMOTE

        if [[ $SETUP_REMOTE =~ ^[Yy]$ ]]; then
            echo "输入远程仓库URL:"
            echo "1) SSH (推荐): git@github.com:username/repo.git"
            echo "2) HTTPS: https://github.com/username/repo.git"
            read -p "选择方式 (1/2): " REMOTE_TYPE

            read -p "输入仓库URL: " REPO_URL

            case $REMOTE_TYPE in
                1)
                    git remote add origin "$REPO_URL"
                    echo "已添加SSH远程仓库"
                    ;;
                2)
                    git remote add origin "$REPO_URL"
                    echo "已添加HTTPS远程仓库"
                    ;;
                *)
                    echo "无效选择，跳过远程配置"
                    ;;
            esac
        fi
    else
        REMOTE_URL=$(git remote get-url origin)
        echo "远程仓库已配置: $REMOTE_URL"

        # 检查连接
        if [[ "$REMOTE_URL" == *"@"* ]]; then
            if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
                echo -e "${GREEN}✅ 远程连接正常${NC}"
            else
                echo -e "${YELLOW}⚠️  远程连接可能有问题${NC}"
            fi
        else
            echo -e "${GREEN}✅ HTTPS远程仓库配置${NC}"
        fi
    fi
}

show_summary() {
    echo -e "\n${GREEN}🎉 Git配置完成！${NC}"
    echo "=================================="
    echo "配置摘要:"
    echo "- 基础Git配置"
    echo "- WSL环境优化"
    echo "- 性能优化"
    echo "- 便捷别名"
    echo "- Git忽略规则"
    echo "- 自动化Hooks"
    echo "- SSH配置检查"
    echo "- 项目特定配置"
    echo "- 远程仓库设置"
    echo ""
    echo "现在可以使用以下便捷命令:"
    echo "- git check    # 运行健康检查"
    echo "- git rescue   # 紧急救援"
    echo "- git auto     # 自动化操作"
    echo "- git dev      # 开发工作流"
    echo "- git done     # 完成功能"
    echo ""
    echo "更多信息请查看: ./claudedocs/git-troubleshooting-guide.md"
}

# 主程序
main() {
    # 检查Git是否已安装
    if ! command -v git &> /dev/null; then
        echo -e "${RED}❌ Git未安装${NC}"
        echo "请先安装Git: https://git-scm.com/"
        exit 1
    fi

    # 检查是否在Git仓库中
    if ! git rev-parse --git-dir &> /dev/null; then
        echo -e "${YELLOW}⚠️  当前目录不是Git仓库${NC}"
        read -p "是否初始化Git仓库？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git init
            echo -e "${GREEN}✅ Git仓库已初始化${NC}"
        else
            echo "请先在Git仓库中运行此脚本"
            exit 1
        fi
    fi

    # 运行所有配置步骤
    setup_git_config
    setup_wsl_config
    setup_performance
    setup_aliases
    setup_ignore
    setup_hooks
    setup_ssh
    setup_project_specific
    setup_remote
    show_summary
}

# 运行主程序
main "$@"