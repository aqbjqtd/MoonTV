# 任务完成检查清单

## 代码变更后必须执行
1. **类型检查**: `npm run typecheck`
2. **代码检查**: `npm run lint`
3. **格式化检查**: `npm run format:check`
4. **构建测试**: `npm run build`
5. **运行测试**: `npm test` (如果有相关测试)

## 依赖管理
- 添加新依赖后运行 `npm install --legacy-peer-deps`
- 检查是否有版本冲突或安全漏洞
- 更新 package.json 后重新安装依赖

## 配置文件变更
- 修改 `config.json` 后重启开发服务器
- 修改环境变量后重新构建
- 更新 TypeScript 配置后运行类型检查

## Git 工作流
- 提交前会自动运行 lint-staged 检查
- 确保所有文件格式化正确
- 提交信息遵循 Conventional Commits 规范

## 生产部署前
1. 运行完整构建: `npm run build`
2. 检查构建输出无错误警告
3. 验证环境变量配置正确
4. 测试核心功能正常工作

## 已知问题解决
- 依赖冲突: 使用 `--legacy-peer-deps` 标志
- @types/react-dom 版本: 使用 ^18.2.25 (已修复)
- Git hooks 在非 git 环境: 正常警告，不影响构建