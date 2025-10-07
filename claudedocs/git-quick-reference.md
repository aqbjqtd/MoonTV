# MoonTV Git 快速参考卡片

## 🚀 快速命令

### 基础操作

```bash
# 检查Git健康状态
./scripts/git-check.sh

# 智能提交（自动检查代码质量）
./scripts/git-automation.sh commit "feat: 添加新功能"

# 推送到远程
./scripts/git-automation.sh push

# 创建功能分支
./scripts/git-automation.sh feature user-auth

# 合并功能分支
./scripts/git-automation.sh merge

# 紧急救援
./scripts/git-rescue.sh emergency
```

### Git 别名（已配置）

```bash
git check        # ./scripts/git-check.sh
git rescue       # ./scripts/git-rescue.sh
git auto         # ./scripts/git-automation.sh
git st           # git status
git co           # git checkout
git ci           # git commit
git tree         # git log --graph --oneline --decorate --all
git uncommit     # git reset --soft HEAD~1
git dev          # 开发新功能
git done         # 完成功能开发
```

## 🛠️ 常见问题解决

### 1. 提交失败

```bash
# 情况：代码质量检查失败
pnpm lint:fix && pnpm format && git add .

# 情况：类型检查失败
pnpm typecheck && git add .

# 情况：跳过预提交钩子（不推荐）
git commit --no-verify -m "commit message"
```

### 2. 推送失败

```bash
# 情况：远程有新提交
git pull --rebase origin main
git push origin main

# 情况：网络问题
git config http.postBuffer 524288000
git push origin main

# 情况：大文件问题
./scripts/git-rescue.sh fix-large
```

### 3. 合并冲突

```bash
# 查看冲突文件
git status

# 解决冲突后标记完成
git add conflicted-file.js
git commit

# 取消合并
git merge --abort
```

### 4. 分支操作

```bash
# 创建功能分支
git checkout -b feature/new-feature

# 切换分支
git checkout main

# 删除本地分支
git branch -d feature/finished-feature

# 删除远程分支
git push origin --delete feature/finished-feature
```

## 📝 提交信息规范

### 格式

```
<类型>(<范围>): <描述>

[可选的正文]

[可选的脚注]
```

### 类型说明

- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建过程或辅助工具变动
- `perf`: 性能优化

### 示例

```bash
git commit -m "feat(video): 添加播放器控制功能"
git commit -m "fix(auth): 修复登录验证问题"
git commit -m "docs: 更新API文档"
git commit -m "perf(search): 优化搜索性能"
```

## 🔧 环境特定配置

### WSL 环境

```bash
# 行尾符处理
git config --global core.autocrlf input

# 文件权限
git config --global core.filemode false

# NTFS保护
git config --global core.protectNTFS false
```

### SSH 配置

```bash
# 生成新密钥
ssh-keygen -t ed25519 -C "your-email@example.com"

# 添加到ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 测试连接
ssh -T git@github.com

# 复制公钥
cat ~/.ssh/id_ed25519.pub
```

## 📊 项目特定文件

### 重要配置文件

- `package.json`: 项目依赖和脚本
- `.gitignore`: Git 忽略规则
- `.gitattributes`: 文件属性配置
- `.husky/`: Git hooks 配置
- `commitlint.config.js`: 提交信息规范

### 关键目录

- `node_modules/`: 依赖包（必须忽略）
- `.next/`: Next.js 构建产物（必须忽略）
- `out/`: 静态导出产物（必须忽略）
- `scripts/`: 自动化脚本
- `claudedocs/`: 项目文档

## 🚨 紧急情况处理

### 代码丢失

```bash
# 查看操作历史
git reflog

# 恢复到特定状态
git reset --hard HEAD@{5}

# 恢复丢失的分支
git checkout -b recovery-branch <commit-hash>
```

### 意外提交

```bash
# 撤销最后一次提交（保留更改）
git reset --soft HEAD~1

# 撤销最后一次提交（丢弃更改）
git reset --hard HEAD~1

# 修改最后一次提交
git commit --amend
```

### 强制推送（谨慎使用）

```bash
# 安全的强制推送
git push --force-with-lease origin main

# 完全强制推送（危险）
git push --force origin main
```

## 🎯 最佳实践

### 日常工作流

1. 开始新功能: `git dev` 或 `./scripts/git-automation.sh feature <name>`
2. 开发过程中: 频繁提交，小的更改
3. 完成功能: `git done` 或 `./scripts/git-automation.sh merge`
4. 部署准备: `./scripts/git-automation.sh deploy`

### 提交前检查

1. 运行 `./scripts/git-check.sh`
2. 检查代码格式: `pnpm format`
3. 检查代码质量: `pnpm lint`
4. 检查类型: `pnpm typecheck`
5. 运行测试: `pnpm test`

### 分支策略

- `main`: 生产环境代码
- `deploy`: 部署分支
- `feature/*`: 功能开发分支
- `fix/*`: bug 修复分支
- `hotfix/*`: 紧急修复分支

## 📞 获取帮助

### 脚本帮助

```bash
./scripts/git-check.sh --help
./scripts/git-rescue.sh --help
./scripts/git-automation.sh --help
./scripts/git-setup.sh --help
```

### Git 帮助

```bash
git help <command>
git <command> --help
```

### 项目文档

- `claudedocs/git-troubleshooting-guide.md`: 详细故障排除指南
- `claudedocs/git-quick-reference.md`: 本快速参考卡片

---

💡 **提示**: 将此文档保存在书签中，以便快速查阅！
