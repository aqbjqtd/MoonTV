#!/bin/bash
set -e

# Docker Hub 推送脚本 - MoonTV 企业级镜像
# 支持 dev 标签本地开发模式

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
REGISTRY="docker.io"
NAMESPACE="aqbjqtd"
IMAGE_NAME="moontv"
VERSION_TAG=$(cat VERSION.txt 2>/dev/null || echo "v3.3.0")
COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "local")
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo -e "${BLUE}🐳 MoonTV Docker Hub 推送脚本${NC}"
echo "========================================"

# 参数解析
PUSH_LATEST=${PUSH_LATEST:-"true"}
PUSH_DEV=${PUSH_DEV:-"true"}
PUSH_VERSION=${PUSH_VERSION:-"false"}

while [[ $# -gt 0 ]]; do
  case $1 in
    --no-latest)
      PUSH_LATEST="false"
      shift
      ;;
    --no-dev)
      PUSH_DEV="false"
      shift
      ;;
    --version)
      PUSH_VERSION="true"
      shift
      ;;
    --all)
      PUSH_LATEST="true"
      PUSH_DEV="true"
      PUSH_VERSION="true"
      shift
      ;;
    -h|--help)
      echo "用法: $0 [选项]"
      echo ""
      echo "选项:"
      echo "  --no-latest   不推送 latest 标签"
      echo "  --no-dev      不推送 dev 标签"
      echo "  --version     推送版本标签"
      echo "  --all         推送所有标签"
      echo "  -h, --help    显示帮助信息"
      echo ""
      echo "环境变量:"
      echo "  DOCKER_USERNAME  Docker Hub 用户名"
      echo "  DOCKER_PASSWORD  Docker Hub 密码或 Access Token"
      exit 0
      ;;
    *)
      echo -e "${RED}❌ 未知参数: $1${NC}"
      echo "使用 -h 或 --help 查看帮助"
      exit 1
      ;;
  esac
done

# 检查必要工具
command -v docker >/dev/null 2>&1 || { echo -e "${RED}❌ Docker 未安装${NC}"; exit 1; }

# 检查本地镜像
LOCAL_IMAGE="moontv:test"
if ! docker image inspect "$LOCAL_IMAGE" >/dev/null 2>&1; then
    echo -e "${RED}❌ 本地镜像 $LOCAL_IMAGE 不存在${NC}"
    echo "请先运行: ./scripts/docker-build-optimized.sh -t test"
    exit 1
fi

echo -e "${GREEN}✅ 找到本地镜像: $LOCAL_IMAGE${NC}"

# 镜像信息
echo -e "${BLUE}📋 镜像信息:${NC}"
echo "- 应用版本: $VERSION_TAG"
echo "- 提交 SHA: $COMMIT_SHA"
echo "- 构建时间: $BUILD_DATE"
echo "- 推送策略: latest=$PUSH_LATEST, dev=$PUSH_DEV, version=$PUSH_VERSION"
echo ""

# 登录 Docker Hub
if [ -n "$DOCKER_USERNAME" ] && [ -n "$DOCKER_PASSWORD" ]; then
    echo -e "${BLUE}🔐 登录 Docker Hub...${NC}"
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    echo -e "${GREEN}✅ 登录成功${NC}"
else
    echo -e "${YELLOW}⚠️  未设置 Docker Hub 凭据，使用本地登录${NC}"
    if ! docker info | grep -q "Username"; then
        echo -e "${RED}❌ 未登录 Docker Hub${NC}"
        echo "请先运行: docker login"
        exit 1
    fi
fi

# 构建标签列表
TAGS=()

if [ "$PUSH_LATEST" = "true" ]; then
    TAGS+=("latest")
fi

if [ "$PUSH_DEV" = "true" ]; then
    TAGS+=("dev")
fi

if [ "$PUSH_VERSION" = "true" ]; then
    TAGS+=("$VERSION_TAG")
    TAGS+=("app-$VERSION_TAG")
fi

# 添加开发标签
TAGS+=("dev-$COMMIT_SHA")
TAGS+=("build-$(date +%Y%m%d)")

echo -e "${BLUE}🏷️  将推送以下标签:${NC}"
for tag in "${TAGS[@]}"; do
    echo "- $REGISTRY/$NAMESPACE/$IMAGE_NAME:$tag"
done
echo ""

# 推送镜像
echo -e "${BLUE}🚀 开始推送镜像...${NC}"
PUSHED_TAGS=()
FAILED_TAGS=()

for tag in "${TAGS[@]}"; do
    FULL_TAG="$REGISTRY/$NAMESPACE/$IMAGE_NAME:$tag"
    echo -e "${YELLOW}推送: $FULL_TAG${NC}"

    # 标记镜像
    docker tag "$LOCAL_IMAGE" "$FULL_TAG"

    # 推送镜像
    if docker push "$FULL_TAG"; then
        echo -e "${GREEN}✅ 成功: $tag${NC}"
        PUSHED_TAGS+=("$tag")
    else
        echo -e "${RED}❌ 失败: $tag${NC}"
        FAILED_TAGS+=("$tag")
    fi

    echo ""
done

# 推送结果
echo -e "${BLUE}📊 推送结果:${NC}"
echo "========================================"
if [ ${#PUSHED_TAGS[@]} -gt 0 ]; then
    echo -e "${GREEN}✅ 成功推送 (${#PUSHED_TAGS[@]} 个):${NC}"
    for tag in "${PUSHED_TAGS[@]}"; do
        echo "  - $REGISTRY/$NAMESPACE/$IMAGE_NAME:$tag"
    done
fi

if [ ${#FAILED_TAGS[@]} -gt 0 ]; then
    echo -e "${RED}❌ 推送失败 (${#FAILED_TAGS[@]} 个):${NC}"
    for tag in "${FAILED_TAGS[@]}"; do
        echo "  - $REGISTRY/$NAMESPACE/$IMAGE_NAME:$tag"
    done
fi

echo ""
echo -e "${GREEN}🎉 Docker Hub 推送完成！${NC}"
echo -e "${BLUE}📖 使用示例:${NC}"
echo "docker run -d -p 3000:3000 \\"
echo "  -e PASSWORD=yourpassword \\"
echo "  -e NEXT_PUBLIC_STORAGE_TYPE=localstorage \\"
echo "  $REGISTRY/$NAMESPACE/$IMAGE_NAME:latest"