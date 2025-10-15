#!/usr/bin/env node

/**
 * Bundle 分析脚本
 * 用于分析构建产物大小和优化建议
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('🔍 开始分析构建产物...\n');

// 检查是否已构建
const buildDir = path.join(process.cwd(), '.next');
if (!fs.existsSync(buildDir)) {
  console.log('❌ 未找到构建产物，请先运行 pnpm build');
  process.exit(1);
}

// 设置环境变量启用分析
process.env.ANALYZE = 'true';
process.env.NODE_ENV = 'production';

try {
  console.log('📊 正在生成 bundle 分析报告...');

  // 使用优化配置进行分析
  execSync('cp next.config.optimized.js next.config.js', { stdio: 'inherit' });

  // 运行分析
  execSync('pnpm build', { stdio: 'inherit' });

  console.log('\n✅ Bundle 分析完成！');
  console.log('📈 分析报告已生成到 .next/static/analyze/');

  // 恢复原始配置
  execSync('git checkout next.config.js', { stdio: 'inherit' });

  // 检查文件大小
  const staticDir = path.join(buildDir, 'static');
  if (fs.existsSync(staticDir)) {
    console.log('\n📁 主要构建产物大小：');
    const files = fs.readdirSync(staticDir);

    files.forEach((file) => {
      const filePath = path.join(staticDir, file);
      const stat = fs.statSync(filePath);
      if (stat.isFile()) {
        const size = (stat.size / 1024).toFixed(2);
        console.log(`   ${file}: ${size} KB`);
      }
    });
  }
} catch (error) {
  console.error('❌ 分析过程中出现错误:', error.message);
  process.exit(1);
}

console.log('\n💡 优化建议：');
console.log('   1. 使用 next-optimized-images 优化图片');
console.log('   2. 启用动态导入减少初始包大小');
console.log('   3. 使用 next/dynamic 动态加载组件');
console.log('   4. 配置 CDN 加速静态资源');
