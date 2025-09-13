#!/usr/bin/env node

/**
 * 依赖分析和优化脚本
 * 用于识别和优化大体积依赖
 */

import fs from 'fs';

// 分析package.json中的依赖
function analyzeDependencies() {
  const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
  const dependencies = {
    ...packageJson.dependencies,
    ...packageJson.devDependencies,
  };

  // 已知的大体积依赖
  const heavyDependencies = [
    '@vidstack/react',
    'framer-motion',
    'next',
    'react',
    'react-dom',
    'swiper',
    'artplayer',
    'hls.js',
    '@heroicons/react',
    'lucide-react',
    'react-icons',
  ];

  console.log('📊 MoonTV依赖分析报告');
  console.log('========================');
  console.log(`总依赖数量: ${Object.keys(dependencies).length}`);
  console.log(
    `生产依赖: ${Object.keys(packageJson.dependencies || {}).length}`
  );
  console.log(
    `开发依赖: ${Object.keys(packageJson.devDependencies || {}).length}`
  );
  console.log('');

  console.log('🔍 大体积依赖识别:');
  heavyDependencies.forEach((dep) => {
    if (dependencies[dep]) {
      console.log(`  ⚠️  ${dep}: ${dependencies[dep]}`);
    }
  });
  console.log('');

  console.log('💡 优化建议:');
  console.log('1. 考虑tree-shaking优化');
  console.log('2. 使用动态导入减少初始包大小');
  console.log('3. 评估是否所有媒体播放器都是必需的');
  console.log('4. 考虑使用更轻量的替代方案');
  console.log('5. 实施代码分割策略');
}

// 生成优化后的package.json
function generateOptimizedPackageJson() {
  const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));

  console.log('🎯 依赖优化建议:');

  // 建议移除或替换的依赖
  const optimizationSuggestions = {
    'framer-motion': '考虑使用更轻量的动画库如react-spring或CSS动画',
    '@heroicons/react': '考虑使用lucide-react统一图标库',
    artplayer: '评估是否可以整合到@vidstack/react中',
    swiper: '考虑使用更轻量的轮播组件',
  };

  Object.entries(optimizationSuggestions).forEach(([dep, suggestion]) => {
    if (packageJson.dependencies[dep]) {
      console.log(`  🔄 ${dep}: ${suggestion}`);
    }
  });
}

if (import.meta.url === `file://${process.argv[1]}`) {
  analyzeDependencies();
  generateOptimizedPackageJson();
}

export { analyzeDependencies, generateOptimizedPackageJson };
