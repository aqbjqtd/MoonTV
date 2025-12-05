#!/bin/bash

# MoonTV 版本一致性检查脚本
# 检查所有版本文件是否同步

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 版本文件路径
VERSION_TXT="VERSION.txt"
PACKAGE_JSON="package.json"
VERSION_TS="src/lib/version.ts"

echo -e "${BLUE}🔍 MoonTV 版本一致性检查${NC}"
echo "=================================="

# 检查文件是否存在
if [ ! -f "$VERSION_TXT" ]; then
    echo -e "${RED}❌ VERSION.txt 文件不存在${NC}"
    exit 1
fi

if [ ! -f "$PACKAGE_JSON" ]; then
    echo -e "${RED}❌ package.json 文件不存在${NC}"
    exit 1
fi

if [ ! -f "$VERSION_TS" ]; then
    echo -e "${RED}❌ src/lib/version.ts 文件不存在${NC}"
    exit 1
fi

# 读取版本号
VERSION_TXT_CONTENT=$(cat "$VERSION_TXT" | tr -d '\n\r')
PACKAGE_JSON_VERSION=$(grep '"version"' "$PACKAGE_JSON" | cut -d'"' -f4 | tr -d '\n\r')
VERSION_TS_CURRENT=$(grep "const CURRENT_VERSION" "$VERSION_TS" | cut -d"'" -f2 | tr -d '\n\r')

echo -e "${BLUE}📋 版本文件状态:${NC}"
echo "  VERSION.txt: ${YELLOW}$VERSION_TXT_CONTENT${NC}"
echo "  package.json: ${YELLOW}$PACKAGE_JSON_VERSION${NC}"
echo "  version.ts: ${YELLOW}$VERSION_TS_CURRENT${NC}"
echo ""

# 检查版本一致性
if [ "$VERSION_TXT_CONTENT" = "$PACKAGE_JSON_VERSION" ] && [ "$PACKAGE_JSON_VERSION" = "$VERSION_TS_CURRENT" ]; then
    echo -e "${GREEN}✅ 版本一致性检查通过: $VERSION_TXT_CONTENT${NC}"

    # 检查Git标签是否匹配
    if git rev-parse "v$VERSION_TXT_CONTENT" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Git标签 v$VERSION_TXT_CONTENT 存在${NC}"
    else
        echo -e "${YELLOW}⚠️  Git标签 v$VERSION_TXT_CONTENT 不存在${NC}"
    fi

    # 检查Docker镜像
    if docker images "aqbjqtd/moontv:v$VERSION_TXT_CONTENT" --format "{{.Repository}}:{{.Tag}}" | grep -q "aqbjqtd/moontv:v$VERSION_TXT_CONTENT"; then
        echo -e "${GREEN}✅ Docker镜像 aqbjqtd/moontv:v$VERSION_TXT_CONTENT 存在${NC}"
    else
        echo -e "${YELLOW}⚠️  Docker镜像 aqbjqtd/moontv:v$VERSION_TXT_CONTENT 不存在${NC}"
    fi

    exit 0
else
    echo -e "${RED}❌ 版本不一致!${NC}"
    echo ""
    echo -e "${RED}详细对比:${NC}"

    # 详细比较
    if [ "$VERSION_TXT_CONTENT" != "$PACKAGE_JSON_VERSION" ]; then
        echo -e "  ${RED}VERSION.txt ($VERSION_TXT_CONTENT) ≠ package.json ($PACKAGE_JSON_VERSION)${NC}"
    fi

    if [ "$PACKAGE_JSON_VERSION" != "$VERSION_TS_CURRENT" ]; then
        echo -e "  ${RED}package.json ($PACKAGE_JSON_VERSION) ≠ version.ts ($VERSION_TS_CURRENT)${NC}"
    fi

    if [ "$VERSION_TXT_CONTENT" != "$VERSION_TS_CURRENT" ]; then
        echo -e "  ${RED}VERSION.txt ($VERSION_TXT_CONTENT) ≠ version.ts ($VERSION_TS_CURRENT)${NC}"
    fi

    echo ""
    echo -e "${YELLOW}💡 修复建议:${NC}"
    echo "  1. 确定正确的版本号"
    echo "  2. 更新所有版本文件到相同版本"
    echo "  3. 运行: ./scripts/sync-version.sh <version>"

    exit 1
fi