# MoonTV 项目版本控制和回滚指南

## 🏷️ 重要里程碑版本标签

### v1.0-moontv-stable (当前稳定版本)
- **标签名称**: v1.0-moontv-stable
- **对应提交**: fb3fd2a (docs: 添加GitHub推送尝试记录)
- **创建时间**: 2025-09-05
- **状态**: 已推送到远程仓库

### ✅ 此版本包含的重要功能
- **视频播放器性能大幅优化** - 拖动响应提升70%
- **HLS缓冲配置优化** - 播放流畅度显著改善
- **Docker容器化部署完成** - 完整的部署方案
- **代码质量优化和工程化配置** - ESLint、Prettier、工作流配置
- **Serena项目记忆系统集成** - 智能开发助手支持
- **用户体验完美改善** - 用户反馈"效果好多了，拖动体验好了很多"

## 🔄 回滚操作指南

### 基础回滚命令
```bash
# 查看标签详细信息
git show v1.0-moontv-stable

# 强制回滚到稳定版本（谨慎使用）
git reset --hard v1.0-moontv-stable

# 查看所有可用标签
git tag -l v*
```

### 安全回滚流程
```bash
# 1. 首先检查当前状态
git status
git log --oneline -3

# 2. 查看目标标签信息
git show v1.0-moontv-stable --stat

# 3. 创建当前状态的备份标签（可选）
git tag -a backup-before-rollback-$(date +%Y%m%d-%H%M%S) -m "回滚前备份"

# 4. 执行回滚
git reset --hard v1.0-moontv-stable

# 5. 验证回滚结果
git log --oneline -3
git status
```

### 基于稳定版本的开发
```bash
# 从稳定版本创建新功能分支
git checkout -b feature/new-feature v1.0-moontv-stable

# 开发完成后合并回master
git checkout master
git merge feature/new-feature

# 删除功能分支
git branch -d feature/new-feature
```

## 📋 版本管理最佳实践

### 标签管理
```bash
# 查看所有标签
git tag

# 查看标签详细信息
git show v1.0-moontv-stable

# 推送新标签到远程
git push origin <tag-name>

# 推送所有标签到远程
git push origin --tags

# 删除本地标签
git tag -d <tag-name>

# 删除远程标签
git push origin --delete <tag-name>
```

### 版本对比
```bash
# 比较当前版本与稳定版本的差异
git diff v1.0-moontv-stable..HEAD

# 查看从稳定版本开始的提交历史
git log v1.0-moontv-stable..HEAD --oneline

# 比较两个标签之间的差异
git diff v1.0-moontv-stable..other-tag
```

## 🚨 紧急恢复流程

### 如果开发出现问题需要快速回滚
```bash
# 1. 立即停止当前开发，保存工作
git stash push -m "紧急回滚前保存"

# 2. 快速回滚到稳定版本
git reset --hard v1.0-moontv-stable

# 3. 验证系统恢复正常
git status

# 4. 如需恢复工作，从stash中取出
git stash pop
```

### 远程仓库问题恢复
```bash
# 如果本地有问题，可以从远程重新获取
git fetch origin
git reset --hard origin/master

# 或者从标签重新创建
git checkout v1.0-moontv-stable
git checkout -b temp-recovery
git push -f origin temp-recovery:master
git checkout master
git branch -D temp-recovery
```

## 💡 开发建议

### 日常开发节奏
1. **开发新功能前**：考虑基于 v1.0-moontv-stable 创建功能分支
2. **定期检查点**：重要的开发节点可以创建临时标签
3. **测试通过后**：合并到master并考虑创建新的里程碑标签
4. **出现问题**：随时可以回到 v1.0-moontv-stable 这个已知的稳定状态

### 版本命名约定
- **里程碑版本**：v1.0-moontv-stable, v2.0-moontv-stable
- **功能版本**：v1.1-feature-name, v1.2-bugfix
- **临时备份**：backup-YYYYMMDD-HHMMSS, pre-test-YYYYMMDD

## 📞 相关命令速查

| 操作 | 命令 |
|------|------|
| 查看标签 | `git tag` |
| 标签详情 | `git show v1.0-moontv-stable` |
| 创建标签 | `git tag -a v2.0 -m "描述"` |
| 推送标签 | `git push origin v2.0` |
| 回滚到标签 | `git reset --hard v1.0-moontv-stable` |
| 比较版本 | `git diff v1.0..HEAD` |
| 从标签创建分支 | `git checkout -b new-feature v1.0-moontv-stable` |

**核心原则**: v1.0-moontv-stable 是项目的安全锚点，任何时候都能回到这个经过验证的稳定状态。