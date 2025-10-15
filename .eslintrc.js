/** @type {import("eslint").Linter.Config} */
module.exports = {
  root: true,
  extends: [
    'eslint:recommended',
    'next/core-web-vitals',
  ],
  parserOptions: {
    ecmaVersion: 2022,
    sourceType: 'module',
    ecmaFeatures: {
      jsx: true,
    },
  },
  rules: {
    // 通用规则
    'no-console': process.env.NODE_ENV === 'production' ? 'warn' : 'off',
    'no-debugger': process.env.NODE_ENV === 'production' ? 'error' : 'warn',
    'prefer-const': 'error',
    'no-var': 'error',
    'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],

    // Next.js规则
    '@next/next/no-img-element': 'error',
    '@next/next/no-page-custom-font': 'warn',

    // 安全规则
    'no-eval': 'error',
    'no-implied-eval': 'error',
    'no-new-func': 'error',
    'no-script-url': 'error',
  },
  env: {
    browser: true,
    es2022: true,
    node: true,
  },
  ignorePatterns: [
    'node_modules/',
    '.next/',
    'out/',
    'build/',
    'dist/',
    'coverage/',
    '.git/',
    '*.min.js',
    'public/sw.js',
    'scripts/',
    'jest.config.js',
    'next.config.js',
  ],
};
