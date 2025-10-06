#!/bin/bash

echo "=== MoonTV Docker 构建修复验证 ==="

echo "1. 检查关键文件是否存在..."
files=("src/lib/config.ts" "src/lib/auth.ts" "src/lib/db.ts" "tsconfig.json" "config.json")
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file 存在"
    else
        echo "❌ $file 不存在"
    fi
done

echo
echo "2. 检查 package.json prepare 脚本..."
if grep -q "prepare.*husky" package.json; then
    echo "✅ prepare 脚本存在，包含 husky install"
else
    echo "❌ prepare 脚本不存在"
fi

echo
echo "3. 检查 Dockerfile 修复..."
if grep -q "ignore-scripts" Dockerfile; then
    echo "✅ Dockerfile 已添加 --ignore-scripts 参数"
else
    echo "❌ Dockerfile 缺少 --ignore-scripts 参数"
fi

echo
echo "4. 检查 .dockerignore 修复..."
if ! grep -q "^tsconfig.json$" .dockerignore; then
    echo "✅ tsconfig.json 已从 .dockerignore 中移除"
else
    echo "❌ tsconfig.json 仍在 .dockerignore 中"
fi

echo
echo "5. 运行 gen:runtime 脚本测试..."
node scripts/generate-runtime.js
if [ $? -eq 0 ]; then
    echo "✅ gen:runtime 脚本运行成功"
    if [ -f "src/lib/runtime.ts" ]; then
        echo "✅ runtime.ts 文件生成成功"
    else
        echo "❌ runtime.ts 文件未生成"
    fi
else
    echo "❌ gen:runtime 脚本运行失败"
fi

echo
echo "=== 修复验证完成 ==="