# MoonTV 代码风格与约定

## 代码风格工具
- **ESLint**: 代码质量检查 (.eslintrc.js)
- **Prettier**: 代码格式化 (.prettierrc.js)
- **TypeScript**: 严格类型检查 (tsconfig.json)
- **Husky**: Git hooks 自动化
- **lint-staged**: 提交前代码检查

## 命名约定
- **文件名**: kebab-case (如: video-player.tsx)
- **组件名**: PascalCase (如: VideoPlayer)
- **变量/函数**: camelCase (如: getUserData)
- **常量**: UPPER_SNAKE_CASE (如: API_BASE_URL)
- **类型/接口**: PascalCase (如: UserProfile, ApiResponse)

## 项目特定约定
- **API 路由**: `/api/` 目录下使用 REST 风格
- **组件结构**: 按功能模块组织 (如: components/player/, components/search/)
- **样式**: 优先使用 Tailwind CSS 类名
- **状态管理**: 使用 React Context + useReducer 模式
- **错误处理**: 统一使用 try-catch + toast 提示

## TypeScript 配置
- 启用严格模式
- 路径别名: `@/` 指向 `src/`
- 增量编译支持
- JSX 支持 React 17+ 自动导入

## Git 提交约定
- 使用 Conventional Commits 规范
- 提交前自动运行 ESLint + Prettier
- 支持的提交类型: feat, fix, docs, style, refactor, test, chore

## 测试约定
- 使用 Jest + React Testing Library
- 测试文件命名: `*.test.ts` 或 `*.test.tsx`
- 测试配置: jest.config.js + jest.setup.js