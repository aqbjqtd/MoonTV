#!/bin/bash

# MoonTV 版本同步脚本
# 同步所有版本文件到指定版本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查参数
if [ $# -ne 1 ]; then
    echo -e "${RED}❌ 用法: $0 <version>${NC}"
    echo -e "${YELLOW}示例: $0 3.5.0${NC}"
    exit 1
fi

VERSION=$1

# 验证版本格式
if [[ ! $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
    echo -e "${RED}❌ 无效的版本格式: $VERSION${NC}"
    echo -e "${YELLOW}有效格式: X.Y.Z 或 X.Y.Z-prerelease${NC}"
    exit 1
fi

echo -e "${BLUE}🔄 MoonTV 版本同步${NC}"
echo "=================================="
echo -e "${BLUE}目标版本: $VERSION${NC}"
echo ""

# 版本文件路径
VERSION_TXT="VERSION.txt"
PACKAGE_JSON="package.json"
VERSION_TS="src/lib/version.ts"

# 备份当前版本
echo -e "${YELLOW}📦 备份当前版本...${NC}"
cp "$VERSION_TXT" "${VERSION_TXT}.backup"
cp "$PACKAGE_JSON" "${PACKAGE_JSON}.backup"
cp "$VERSION_TS" "${VERSION_TS}.backup"

# 更新 VERSION.txt
echo -e "${YELLOW}✏️  更新 VERSION.txt...${NC}"
echo "$VERSION" > "$VERSION_TXT"

# 更新 package.json
echo -e "${YELLOW}✏️  更新 package.json...${NC}"
# 使用sed替换版本号，确保精确匹配
sed -i.tmp "s/\"version\": \"[^\"]*\"/\"version\": \"$VERSION\"/" "$PACKAGE_JSON"
rm "$PACKAGE_JSON.tmp"

# 更新 version.ts
echo -e "${YELLOW}✏️  更新 src/lib/version.ts...${NC}"
sed -i.tmp "s/CURRENT_VERSION = '[^']*'/CURRENT_VERSION = '$VERSION'/" "$VERSION_TS"
rm "$VERSION_TS.tmp"

echo ""
echo -e "${GREEN}✅ 版本文件更新完成!${NC}"

# 验证更新结果
echo ""
echo -e "${BLUE}🔍 验证更新结果:${NC}"
echo "  VERSION.txt: $(cat $VERSION_TXT)"
echo "  package.json: $(grep '\"version\"' $PACKAGE_JSON | cut -d'\"' -f4)"
echo "  version.ts: $(grep 'CURRENT_VERSION' $VERSION_TS | cut -d\"'\" -f2)"

# 运行一致性检查
echo ""
echo -e "${BLUE}🔍 运行一致性检查...${NC}"
if ./scripts/check-version-consistency.sh; then
    echo ""
    echo -e "${GREEN}🎉 版本同步成功!${NC}"
    echo ""
    echo -e "${YELLOW}📋 后续步骤:${NC}"
    echo "  1. 提交变更: git add . && git commit -m \"chore: update version files for v$VERSION\""
    echo "  2. 创建标签: git tag v$VERSION"
    echo "  3. 推送变更: git push origin main --tags"
    echo "  4. 构建镜像: docker build -t aqbjqtd/moontv:v$VERSION -t aqbjqtd/moontv:latest ."
else
    echo ""
    echo -e "${RED}❌ 版本同步失败!${NC}"
    echo -e "${YELLOW}🔄 恢复备份...${NC}"

    # 恢复备份
    mv "${VERSION_TXT}.backup" "$VERSION_TXT"
    mv "${PACKAGE_JSON}.backup" "$PACKAGE_JSON"
    mv "${VERSION_TS}.backup" "$VERSION_TS"

    echo -e "${GREEN}✅ 已恢复到原始版本${NC}"
    exit 1
fi