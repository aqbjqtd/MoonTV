# MoonTV项目Git错误诊断与解决方案指南

## 📋 项目环境分析

**项目特点**:
- Next.js 14 应用，使用 pnpm 包管理器
- WSL2 环境开发 (Linux 6.6.87.2-microsoft-standard-WSL2)
- SSH 远程仓库配置 (git@github.com:aqbjqtd/MoonTV.git)
- 包含构建产物、依赖文件等需要Git忽略的内容
- 使用 husky + lint-staged 进行代码质量控制

---

## 🔴 常见Git错误类型及解决方案

### 1. 提交相关错误 (Commit Issues)

#### 错误1: pre-commit hook 失败
```bash
# 错误示例
husky: pre-commit hook failed
❌ Linting failed...
❌ Type check failed...
```

**原因分析**: MoonTV项目配置了husky和lint-staged，代码质量检查失败

**解决方案**:
```bash
# 1. 查看具体错误信息
git status
cat .git/hooks/pre-commit

# 2. 手动运行检查命令
pnpm lint
pnpm typecheck
pnpm format

# 3. 修复代码质量问题
pnpm lint:fix
pnpm format

# 4. 如果紧急需要跳过（不推荐）
git commit --no-verify -m "commit message"
```

**预防措施**:
```bash
# 提交前自动检查
pnpm lint && pnpm typecheck && git add .
```

#### 错误2: 提交信息格式错误
```bash
# 错误示例
❌ commitlint found 1 problems, 0 warnings
⧗   input: fix bug
✖   subject may not be capitalized
```

**原因分析**: MoonTV项目配置了commitlint，要求提交信息遵循conventional commits

**解决方案**:
```bash
# 正确的提交格式
git commit -m "feat: add user authentication feature"
git commit -m "fix: resolve video player loading issue"
git commit -m "docs: update API documentation"
git commit -m "style: improve component styling"
git commit -m "refactor: optimize search performance"
git commit -m "test: add unit tests for video service"
```

### 2. 分支操作错误 (Branching Problems)

#### 错误1: 分支名称冲突
```bash
# 错误示例
fatal: A branch named 'feature/video-player' already exists.
```

**解决方案**:
```bash
# 1. 查看所有分支
git branch -a

# 2. 切换到现有分支
git checkout feature/video-player

# 3. 或者使用不同的分支名
git checkout -b feature/video-player-v2

# 4. 强制覆盖现有分支（谨慎使用）
git checkout -B feature/video-player
```

#### 错误2: 分支丢失
```bash
# 错误示例
fatal: invalid reference: feature/lost-branch
```

**解决方案**:
```bash
# 1. 查看reflog找回分支
git reflog

# 2. 重新创建分支
git checkout -b feature/lost-branch <commit-hash>

# 3. 从远程恢复
git fetch origin
git checkout -b feature/lost-branch origin/feature/lost-branch
```

### 3. 合并冲突 (Merge Conflicts)

#### 错误1: 自动合并失败
```bash
# 错误示例
Auto-merging src/components/VideoPlayer.tsx
CONFLICT (content): Merge conflict in src/components/VideoPlayer.tsx
Automatic merge failed; fix conflicts and then commit the result.
```

**解决方案**:
```bash
# 1. 查看冲突文件
git status

# 2. 手动解决冲突
# 编辑冲突文件，保留需要的代码

# 3. 标记冲突已解决
git add src/components/VideoPlayer.tsx

# 4. 完成合并
git commit

# 5. 如果需要取消合并
git merge --abort
```

**MoonTV项目特定冲突解决**:
```typescript
// src/components/VideoPlayer.tsx 冲突示例
// <<<<<<< HEAD
//   const playerRef = useRef<ArtPlayerType>(null);
//   const [isPlaying, setIsPlaying] = useState(false);
// =======
//   const playerRef = useRef<any>(null);
//   const [playerState, setPlayerState] = useState({
//     isPlaying: false,
//     currentTime: 0,
//     duration: 0
//   });
// >>>>>>> feature/playlist-manager

// 解决方案：合并两个实现
const playerRef = useRef<ArtPlayerType>(null);
const [playerState, setPlayerState] = useState({
  isPlaying: false,
  currentTime: 0,
  duration: 0
});
```

### 4. 远程仓库问题 (Remote Repository Issues)

#### 错误1: SSH连接失败
```bash
# 错误示例
git@github.com: Permission denied (publickey).
fatal: Could not read from remote repository.
```

**解决方案**:
```bash
# 1. 检查SSH配置
ssh -T git@github.com

# 2. 生成新的SSH密钥
ssh-keygen -t ed25519 -C "your-email@example.com"

# 3. 添加SSH密钥到ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 4. 复制公钥到GitHub
cat ~/.ssh/id_ed25519.pub

# 5. 测试连接
ssh -T git@github.com
```

#### 错误2: 远程分支不同步
```bash
# 错误示例
! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to 'git@github.com:aqbjqtd/MoonTV.git'
```

**解决方案**:
```bash
# 1. 拉取远程更新
git fetch origin

# 2. 查看差异
git log HEAD..origin/main --oneline

# 3. 合并远程更改
git pull origin main

# 4. 或者变基（推荐）
git pull --rebase origin main

# 5. 解决冲突后推送
git push origin main
```

### 5. 推送失败 (Push Failures)

#### 错误1: 大文件推送失败
```bash
# 错误示例
error: RPC failed; curl 56 OpenSSL SSL_read: SSL_ERROR_SYSCALL, errno 10054
fatal: the remote end hung up unexpectedly
```

**解决方案**:
```bash
# 1. 检查文件大小
git ls-files | xargs ls -la | sort -k5 -n | tail -10

# 2. 使用Git LFS处理大文件
git lfs track "*.mp4"
git lfs track "*.zip"
git add .gitattributes
git add video-file.mp4
git commit -m "Add large video file with LFS"

# 3. 或者增加缓冲区大小
git config http.postBuffer 524288000

# 4. 分批推送
git push origin main --no-verify
```

---

## 🪟 Windows环境特定问题

### 1. WSL环境下的Git配置

#### 问题1: 行尾符不一致
```bash
# 错误示例
warning: CRLF will be replaced by LF in src/app/page.tsx.
The file will have its original line endings in your working directory.
```

**解决方案**:
```bash
# 1. 配置Git行尾符处理
git config --global core.autocrlf input  # WSL环境
git config --global core.autocrlf true   # Windows环境
git config --global core.autocrlf false  # 禁用自动转换

# 2. 查看当前配置
git config --global --list | grep autocrlf

# 3. 重新规范化所有文件
git add --renormalize .
git commit -m "Normalize line endings"
```

#### 问题2: 权限问题
```bash
# 错误示例
error: unable to create file src/components/VideoPlayer.tsx: Permission denied
```

**解决方案**:
```bash
# 1. 检查文件权限
ls -la src/components/VideoPlayer.tsx

# 2. 修改权限
chmod 644 src/components/VideoPlayer.tsx

# 3. 检查目录权限
ls -la src/components/

# 4. 如果是挂载的Windows目录，检查WSL配置
# 编辑 /etc/wsl.conf
sudo nano /etc/wsl.conf
# 添加：
# [automount]
# options = "metadata,umask=22,fmask=111"
```

### 2. 路径分隔符问题

#### 问题1: 路径格式不兼容
```bash
# 错误示例
fatal: pathspec 'src\\components\\VideoPlayer.tsx' did not match any files
```

**解决方案**:
```bash
# 1. 使用Unix风格路径
git add src/components/VideoPlayer.tsx  # 正确
git add src\\components\\VideoPlayer.tsx  # 错误

# 2. 配置Git路径处理
git config --global core.protectNTFS false

# 3. 使用通配符
git add src/components/*.tsx
```

### 3. 字符编码问题

#### 问题1: 文件编码不一致
```bash
# 错误示例
error: 'src/app/page.tsx' contains invalid UTF-8 byte sequences
```

**解决方案**:
```bash
# 1. 检查文件编码
file -bi src/app/page.tsx

# 2. 转换编码为UTF-8
iconv -f GBK -t UTF-8 src/app/page.tsx > src/app/page-utf8.tsx
mv src/app/page-utf8.tsx src/app/page.tsx

# 3. 配置Git编码
git config --global core.quotepath false
git config --global i18n.commitencoding utf-8
git config --global i18n.logoutputencoding utf-8
```

---

## 🚀 Next.js项目特定考虑

### 1. 大文件处理

#### 问题1: node_modules 提交问题
```bash
# 错误示例
error: File 'node_modules/react/index.js' is 45.2 MB; this exceeds GitHub's file size limit of 100.0 MB
```

**解决方案**:
```bash
# 1. 检查.gitignore是否包含node_modules
cat .gitignore | grep node_modules

# 2. 如果已经提交，从Git历史中移除
git rm -r --cached node_modules/
git commit -m "Remove node_modules from git tracking"

# 3. 添加到.gitignore（如果还没有）
echo "/node_modules" >> .gitignore
echo ".pnp.js" >> .gitignore
echo ".pnp" >> .gitignore

# 4. 强制推送（谨慎使用）
git push origin main --force-with-lease
```

#### 问题2: 构建产物问题
```bash
# 错误示例
error: File '.next/static/chunks/pages/_app-123456.js' is too large
```

**解决方案**:
```bash
# 1. 清理构建产物
rm -rf .next/
rm -rf out/
rm -rf build/

# 2. 确保.gitignore包含构建目录
echo "/.next/" >> .gitignore
echo "/out/" >> .gitignore
echo "/build/" >> .gitignore

# 3. 从Git历史中移除构建产物
git rm -r --cached .next/
git rm -r --cached out/
git rm -r --cached build/
git commit -m "Remove build artifacts from git tracking"
```

### 2. Git忽略配置优化

**MoonTV项目推荐.gitignore配置**:
```gitignore
# 依赖
/node_modules
/.pnp
.pnp.js

# Next.js构建产物
/.next/
/out/
/build/

# 环境变量
.env
.env*.local

# 测试覆盖率
/coverage

# 调试日志
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.pnpm-debug.log*

# 操作系统文件
.DS_Store
Thumbs.db

# IDE文件
.vscode/
.idea/
*.swp
*.swo

# 临时文件
*.tmp
*.temp

# 静态资源
public/manifest.json
sitemap*.xml

# TypeScript
*.tsbuildinfo
next-env.d.ts

# Vercel
.vercel/

# Cloudflare
.wrangler/
```

### 3. 自动部署相关的Git工作流

#### Vercel部署配置
```bash
# 1. 设置部署分支
git checkout -b deploy
git push origin deploy

# 2. 在Vercel中连接仓库
# 访问 vercel.com 导入项目

# 3. 配置环境变量
# 在Vercel控制台中设置环境变量

# 4. 自动触发部署
git push origin main  # 自动部署到生产环境
git push origin deploy # 部署到预览环境
```

#### Cloudflare Pages配置
```bash
# 1. 构建命令配置
# 构建命令: pnpm pages:build
# 输出目录: .vercel/output/static

# 2. 环境变量配置
# 在Cloudflare控制台中设置环境变量

# 3. 部署钩子
# git push origin main  # 自动部署
```

---

## 🔧 预防和解决方案

### 1. 最佳实践建议

#### 提交前检查清单
```bash
#!/bin/bash
# pre-commit-check.sh

echo "🔍 运行提交前检查..."

# 1. 代码格式检查
echo "检查代码格式..."
pnpm format:check || {
  echo "❌ 代码格式不正确，运行 'pnpm format' 修复"
  exit 1
}

# 2. 代码质量检查
echo "检查代码质量..."
pnpm lint || {
  echo "❌ 代码质量检查失败，运行 'pnpm lint:fix' 修复"
  exit 1
}

# 3. 类型检查
echo "检查类型..."
pnpm typecheck || {
  echo "❌ 类型检查失败"
  exit 1
}

# 4. 检查大文件
echo "检查大文件..."
large_files=$(find . -type f -not -path "./node_modules/*" -not -path "./.next/*" -size +50M)
if [ -n "$large_files" ]; then
  echo "❌ 发现大文件: $large_files"
  exit 1
fi

# 5. 检查敏感信息
echo "检查敏感信息..."
if git diff --cached --name-only | xargs grep -l "password\|secret\|api_key" 2>/dev/null; then
  echo "❌ 可能包含敏感信息"
  exit 1
fi

echo "✅ 所有检查通过"
```

#### Git配置优化
```bash
#!/bin/bash
# git-setup.sh

echo "🔧 配置Git..."

# 1. 基础配置
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"

# 2. 编辑器配置
git config --global core.editor "nano"

# 3. 行尾符配置（WSL环境）
git config --global core.autocrlf input
git config --global core.eol lf

# 4. 推送策略
git config --global push.default simple

# 5. 拉取策略
git config --global pull.rebase true

# 6. 分支合并策略
git config --global merge.ff only

# 7. 大文件处理
git config --global http.postBuffer 524288000

echo "✅ Git配置完成"
```

### 2. 自动化工具配置

#### Husky配置 (.husky/pre-commit)
```bash
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

# 运行lint-staged
npx lint-staged

# 运行类型检查
pnpm typecheck
```

#### lint-staged配置 (package.json)
```json
{
  "lint-staged": {
    "**/*.{js,jsx,ts,tsx}": [
      "eslint --max-warnings=0",
      "prettier -w"
    ],
    "**/*.{json,css,scss,md,webmanifest}": [
      "prettier -w"
    ]
  }
}
```

#### commitlint配置 (commitlint.config.js)
```javascript
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',     // 新功能
        'fix',      // 修复
        'docs',     // 文档
        'style',    // 格式
        'refactor', // 重构
        'test',     // 测试
        'chore',    // 构建过程或辅助工具的变动
        'perf',     // 性能优化
        'ci',       // CI配置
        'build',    // 构建系统
        'revert',   // 回滚
      ],
    ],
    'subject-max-length': [2, 'always', 50],
    'body-max-line-length': [2, 'always', 72],
  },
};
```

### 3. 错误恢复策略

#### 紧急回滚脚本 (emergency-rollback.sh)
```bash
#!/bin/bash

echo "🚨 紧急回滚程序..."

# 1. 备份当前状态
git stash push -m "Emergency backup $(date)"

# 2. 回滚到上一个稳定版本
git reset --hard HEAD~1

# 3. 强制推送（谨慎使用）
read -p "是否强制推送到远程？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  git push --force-with-lease origin main
  echo "✅ 强制推送完成"
else
  echo "⚠️  仅本地回滚，未推送到远程"
fi
```

#### 状态重置脚本 (git-reset.sh)
```bash
#!/bin/bash

echo "🔄 重置Git状态..."

# 1. 清理工作区
git clean -fd

# 2. 重置所有更改
git reset --hard HEAD

# 3. 清理未跟踪的文件
git clean -fdx

# 4. 检查状态
git status

echo "✅ Git状态已重置"
```

### 4. 监控和诊断方法

#### Git健康检查脚本 (git-health-check.sh)
```bash
#!/bin/bash

echo "🏥 Git健康检查..."

# 1. 检查Git状态
echo "=== Git Status ==="
git status --porcelain

# 2. 检查远程连接
echo "=== Remote Connection ==="
git remote -v
ssh -T git@github.com 2>/dev/null && echo "✅ SSH连接正常" || echo "❌ SSH连接失败"

# 3. 检查分支状态
echo "=== Branch Status ==="
git branch -vv

# 4. 检查最近的提交
echo "=== Recent Commits ==="
git log --oneline -5

# 5. 检查大文件
echo "=== Large Files ==="
find . -type f -not -path "./node_modules/*" -not -path "./.next/*" -size +10M -exec ls -lh {} \;

# 6. 检查.gitignore覆盖
echo "=== Gitignore Coverage ==="
if [ -f .gitignore ]; then
  echo "✅ .gitignore存在"
  echo "Node.js文件覆盖: $(grep -c 'node_modules' .gitignore)"
  echo "Next.js文件覆盖: $(grep -c '\.next\|out\|build' .gitignore)"
else
  echo "❌ .gitignore不存在"
fi
```

#### 日志记录配置
```bash
# 启用详细日志
export GIT_TRACE=1
export GIT_TRACE_PACK_ACCESS=1
export GIT_TRACE_PERFORMANCE=1

# 或者临时启用
GIT_CURL_VERBOSE=1 GIT_TRACE=1 git push origin main
```

---

## 📞 故障排除快速参考

### 常见错误代码对照表

| 错误代码 | 错误类型 | 快速解决方案 |
|---------|---------|-------------|
| `Permission denied` | SSH权限问题 | 检查SSH密钥配置 |
| `non-fast-forward` | 推送被拒绝 | 先pull，再push |
| `merge conflict` | 合并冲突 | 手动解决冲突 |
| `RPC failed` | 网络或大文件 | 增加缓冲区或使用LFS |
| `hook failed` | 预提交钩子失败 | 运行lint:fix |
| `file too large` | 文件过大 | 使用Git LFS |
| `pathspec invalid` | 路径错误 | 检查文件路径格式 |

### 紧急联系方案

1. **代码丢失**: `git reflog` → `git reset --hard`
2. **推送失败**: 检查网络 → 增加缓冲区 → 分批推送
3. **合并冲突**: `git merge --abort` → 重新合并
4. **权限问题**: 重新生成SSH密钥 → 添加到GitHub
5. **大文件问题**: 使用Git LFS → 从历史中移除

---

## 🎯 MoonTV项目特别建议

1. **定期清理**: 每周清理构建产物和临时文件
2. **分支策略**: 使用`feature/`、`fix/`、`hotfix/`前缀命名分支
3. **提交规范**: 严格遵循conventional commits规范
4. **代码审查**: 重要功能必须经过代码审查
5. **自动化**: 充分利用husky、lint-staged等工具
6. **备份策略**: 定期备份到多个远程仓库
7. **监控**: 设置Git操作的日志记录和监控

通过遵循本指南，可以最大程度地减少Git操作中的错误，提高开发效率和代码质量。