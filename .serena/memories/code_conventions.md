# MoonTV 代码规范约定

## ESLint 规则要点
- 使用 TypeScript ESLint 插件
- 禁止未使用的变量和导入
- 简单导入排序规则
- React 组件规则：
  - 关闭 `react/display-name` 检查
  - 强制 JSX 花括号风格（props 和 children 都不要不必要的花括号）
  - 关闭 `react/no-unescaped-entities` 检查

## Prettier 配置
- 箭头函数总是带括号
- 使用单引号
- JSX 使用单引号
- 2 个空格缩进
- 使用分号

## 代码结构
- 使用 Next.js App Router
- 组件放在 `src/components` 目录
- 工具函数放在 `src/lib` 目录
- 样式使用 Tailwind CSS
- 支持暗黑模式

## 命名约定
- 组件：PascalCase
- 文件名：kebab-case 或 PascalCase（组件）
- 变量：camelCase
- 常量：UPPER_SNAKE_CASE
- 类型：PascalCase

## Git 工作流
- 使用 Husky 进行 Git hooks
- 使用 CommitLint 规范提交信息
- 使用 lint-staged 进行预提交检查