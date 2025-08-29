#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// API文件路径列表（从前面的grep结果）
const apiFiles = [
  'src/app/api/skipconfigs/route.ts',
  'src/app/api/server-config/route.ts', 
  'src/app/api/searchhistory/route.ts',
  'src/app/api/register/route.ts',
  'src/app/api/playrecords/route.ts',
  'src/app/api/douban/recommends/route.ts',
  'src/app/api/cron/route.ts',
  'src/app/api/change-password/route.ts',
  'src/app/api/admin/user/route.ts',
  'src/app/api/admin/source/route.ts',
  'src/app/api/admin/site/route.ts',
  'src/app/api/admin/config/route.ts',
  'src/app/api/admin/category/route.ts'
];

// 获取API文件名（用于日志器名称）
function getApiName(filePath) {
  const parts = filePath.split('/');
  if (parts.includes('admin')) {
    return 'admin-' + parts[parts.length - 2]; // admin-user, admin-config等
  }
  return parts[parts.length - 2]; // favorites, search等
}

// 处理单个文件
function processFile(filePath) {
  const fullPath = path.join(process.cwd(), filePath);
  
  if (!fs.existsSync(fullPath)) {
    console.log(`跳过不存在的文件: ${filePath}`);
    return;
  }

  let content = fs.readFileSync(fullPath, 'utf8');
  const apiName = getApiName(filePath);
  
  // 检查是否需要处理
  if (!content.includes('console.')) {
    console.log(`跳过无console调用的文件: ${filePath}`);
    return;
  }

  console.log(`处理文件: ${filePath} (${apiName})`);
  
  // 移除eslint禁用console的规则
  content = content.replace(/\/\* eslint-disable.*no-console.*\*\/\n?/g, '');
  content = content.replace(/\/\/ eslint-disable-next-line no-console\n?/g, '');
  
  // 检查是否已经有日志导入
  if (!content.includes('createApiLogger')) {
    // 找到第一个import语句后添加日志导入
    const importIndex = content.lastIndexOf("import");
    const lineEnd = content.indexOf('\n', importIndex);
    
    const logImports = `import { createApiLogger } from '@/lib/request-logger';
import { handleError } from '@/lib/error-handler';

const ${apiName.replace(/-/g, '')}Logger = createApiLogger('${apiName}');

`;
    
    content = content.slice(0, lineEnd + 1) + logImports + content.slice(lineEnd + 1);
  }
  
  // 替换console.error调用
  content = content.replace(
    /console\.error\(['"]([^'"]+)['"],?\s*([^)]*)\);?/g, 
    (match, message, error) => {
      const cleanError = error.trim();
      if (cleanError && cleanError !== 'err' && cleanError !== 'error') {
        return `${apiName.replace(/-/g, '')}Logger.logError(${cleanError} as Error, { context: '${message}' });`;
      } else {
        return `${apiName.replace(/-/g, '')}Logger.logError(err as Error);`;
      }
    }
  );
  
  // 替换console.warn调用
  content = content.replace(
    /console\.warn\(['"]([^'"]+)['"],?\s*([^)]*)\);?/g,
    (match, message, params) => {
      return `${apiName.replace(/-/g, '')}Logger.logError(new Error('${message}'), ${params ? `{ ${params} }` : '{}'});`;
    }
  );
  
  // 替换console.log调用
  content = content.replace(
    /console\.log\(['"]([^'"]+)['"],?\s*([^)]*)\);?/g,
    (match, message, params) => {
      return `${apiName.replace(/-/g, '')}Logger.logInfo('${message}', ${params ? `{ ${params} }` : '{}'});`;
    }
  );
  
  // 写回文件
  fs.writeFileSync(fullPath, content, 'utf8');
  console.log(`✅ 完成处理: ${filePath}`);
}

// 处理所有文件
console.log('🚀 开始批量更新API文件中的console日志...\n');

apiFiles.forEach(processFile);

console.log('\n✅ 批量更新完成！');