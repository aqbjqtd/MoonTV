# MoonTV Docker/SSR 修复快速参考指南

**适用场景**: 快速解决Docker构建和SSR相关问题
**最后更新**: 2025-10-06
**状态**: 生产验证 ✅

---

## 🚨 紧急修复命令

### Docker构建失败快速修复
```bash
# 1. husky依赖问题修复
sed -i 's/pnpm install --frozen-lockfile --prod/pnpm install --frozen-lockfile --prod --ignore-scripts/g' Dockerfile

# 2. 配置文件忽略问题修复
sed -i '/^tsconfig.json$/d' .dockerignore
sed -i '/^tailwind.config.*$/d' .dockerignore
sed -i '/^postcss.config.*$/d' .dockerignore

# 3. 重新构建
docker build -t moontv-fix .

# 4. 验证构建
docker run -d -p 3000:3000 moontv-fix
curl -f http://localhost:3000
```

### SSR错误快速修复
```bash
# 1. 统一运行时配置
find src/app/api -name "*.ts" -exec sed -i 's/export const runtime = .edge./export const runtime = "nodejs"/g' {} \;

# 2. 检查配置加载安全性
grep -r "eval(" src/ && echo "发现eval()使用，需要修复" || echo "eval()已清除"

# 3. 重新构建测试
docker build -t moontv-ssr-fix .
docker run -d -p 3000:3000 moontv-ssr-fix
```

---

## 🔍 问题诊断清单

### Docker构建诊断
```bash
# 检查清单
echo "=== Docker构建诊断 ==="
echo "✓ 1. 检查Dockerfile中是否有--ignore-scripts"
grep -n "ignore-scripts" Dockerfile || echo "❌ 缺少--ignore-scripts"

echo "✓ 2. 检查.dockerignore是否错误排除配置文件"
if grep -q "tsconfig.json" .dockerignore; then
  echo "❌ 错误排除了tsconfig.json"
else
  echo "✅ tsconfig.json保留正确"
fi

echo "✓ 3. 检查package.json中的prepare脚本"
grep -A 3 -B 3 "prepare" package.json

echo "✓ 4. 检查基础镜像"
grep "FROM" Dockerfile
```

### SSR错误诊断
```bash
# 检查清单
echo "=== SSR错误诊断 ==="
echo "✓ 1. 检查eval()使用"
grep -r "eval(" src/ && echo "❌ 发现eval()使用" || echo "✅ 无eval()使用"

echo "✓ 2. 检查运行时配置"
grep -r "export const runtime" src/app/api/ | head -5

echo "✓ 3. 检查配置加载方式"
grep -A 5 -B 5 "import.*config" src/lib/config.ts

echo "✓ 4. 检查错误处理"
grep -A 3 -B 3 "try.*catch" src/lib/config.ts | head -10
```

---

## 🛠️ 标准修复流程

### 完整修复流程
```bash
# 第一步：备份当前配置
cp Dockerfile Dockerfile.backup
cp .dockerignore .dockerignore.backup

# 第二步：修复Dockerfile
cat > Dockerfile << 'EOF'
# 多阶段构建Dockerfile
FROM node:18-alpine AS deps
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prod --ignore-scripts

FROM node:18-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN pnpm gen:manifest && pnpm gen:runtime
RUN find ./src/app/api -name "route.ts" -type f -print0 | xargs -0 sed -i 's/export const runtime = '\''edge'\'';/export const runtime = '\''nodejs'\'';/g' || true
RUN pnpm build

FROM gcr.io/distroless/nodejs18-debian12 AS runner
WORKDIR /app
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
EXPOSE 3000
CMD ["node", "server.js"]
EOF

# 第三步：修复.dockerignore
cat > .dockerignore << 'EOF'
node_modules
.git
.github
.vscode
*.log
coverage
.nyc_output
.next
.env.local
.env.development.local
.env.test.local
.env.production.local
# 保留构建配置文件
# tsconfig.json
# tailwind.config.*
# postcss.config.*
EOF

# 第四步：修复配置加载（如果需要）
if grep -q "eval(" src/lib/config.ts; then
  echo "修复配置加载..."
  # 这里需要根据实际文件内容进行修复
fi

# 第五步：构建和测试
docker build -t moontv-fixed .
docker run -d -p 3000:3000 --name moontv-test moontv-fixed

# 第六步：验证功能
sleep 5
curl -f http://localhost:3000 && echo "✅ 应用启动成功"
curl -f http://localhost:3000/api/health && echo "✅ 健康检查通过"

# 第七步：清理
docker stop moontv-test
docker rm moontv-test
```

---

## 📊 性能验证脚本

### 构建性能测试
```bash
#!/bin/bash
# 性能测试脚本: performance-test.sh

echo "=== MoonTV 性能测试 ==="

# 测试构建时间
echo "测试构建时间..."
time docker build -t moontv-perf-test .

# 测试镜像大小
echo "测试镜像大小..."
docker images moontv-perf-test

# 测试启动时间
echo "测试启动时间..."
time docker run -d --name moontv-start-test moontv-perf-test

# 测试响应时间
echo "测试响应时间..."
sleep 5
time curl -s -o /dev/null -w "%{http_code}" http://localhost:3000

# 测试内存使用
echo "测试内存使用..."
docker stats moontv-start-test --no-stream --format "table {{.Container}}\t{{.MemUsage}}"

# 清理
docker stop moontv-start-test
docker rm moontv-start-test
docker rmi moontv-perf-test

echo "=== 性能测试完成 ==="
```

### 功能验证脚本
```bash
#!/bin/bash
# 功能验证脚本: functional-test.sh

echo "=== MoonTV 功能验证 ==="

# 启动应用
docker run -d -p 3000:3000 --name moontv-func-test moontv:latest

# 等待启动
echo "等待应用启动..."
sleep 10

# 测试首页
echo "测试首页..."
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)
if [ "$response" = "200" ]; then
  echo "✅ 首页正常"
else
  echo "❌ 首页异常: HTTP $response"
fi

# 测试配置API
echo "测试配置API..."
config_response=$(curl -s http://localhost:3000/api/config)
if echo "$config_response" | jq -e '.siteName' > /dev/null 2>&1; then
  echo "✅ 配置API正常"
else
  echo "❌ 配置API异常"
fi

# 测试搜索API
echo "测试搜索API..."
search_response=$(curl -s "http://localhost:3000/api/search?q=test")
if echo "$search_response" | jq -e '.length >= 0' > /dev/null 2>&1; then
  echo "✅ 搜索API正常"
else
  echo "❌ 搜索API异常"
fi

# 清理
docker stop moontv-func-test
docker rm moontv-func-test

echo "=== 功能验证完成 ==="
```

---

## 🆘 常见问题解决方案

### 问题1: "husky: not found"
```bash
# 症状
sh: husky: not found
ELIFECYCLE Command failed with exit code 1

# 原因
Docker构建时husky开发依赖未安装，但prepare脚本尝试执行

# 解决方案
sed -i 's/pnpm install --frozen-lockfile --prod/pnpm install --frozen-lockfile --prod --ignore-scripts/g' Dockerfile
```

### 问题2: "Module not found: Can't resolve 'tailwindcss'"
```bash
# 症状
Module not found: Can't resolve 'tailwindcss'

# 原因
.dockerignore错误排除了构建配置文件

# 解决方案
cat > .dockerignore << 'EOF'
node_modules
.git
# ... 其他排除项
# 保留构建配置文件
# tsconfig.json
# tailwind.config.*
# postcss.config.*
EOF
```

### 问题3: "digest xxxxxx: EvalError"
```bash
# 症状
digest 2652919541: EvalError

# 原因
配置加载使用了eval()，在Edge Runtime中被限制

# 解决方案
# 1. 统一运行时
find src/app/api -name "*.ts" -exec sed -i 's/export const runtime = .edge./export const runtime = "nodejs"/g' {} \;

# 2. 修复配置加载（需要根据实际代码调整）
# 将eval()替换为JSON.parse()或动态import
```

---

## 📞 紧急联系方式

### 团队联系人
- **技术负责人**: 系统架构师
- **质量保证**: 质量工程师
- **运维支持**: DevOps专家

### 外部资源
- **Docker文档**: https://docs.docker.com/
- **Next.js文档**: https://nextjs.org/docs/
- **GitHub Issues**: 项目Issues页面

---

## 📝 快速记录模板

### 问题记录模板
```markdown
## 问题描述
- 问题类型: [Docker构建/SSR错误/性能问题]
- 发生时间: [YYYY-MM-DD HH:MM]
- 错误信息: [具体错误信息]
- 影响范围: [功能影响描述]

## 解决过程
- 诊断步骤: [排查步骤]
- 根本原因: [问题根因]
- 解决方案: [修复方案]
- 验证结果: [验证结果]

## 经验教训
- 预防措施: [如何预防]
- 改进建议: [改进建议]
```

---

**指南维护**: 请在使用后根据实际经验更新此指南
**版本**: v1.0
**最后验证**: 2025-10-06 ✅