#!/bin/bash

# 简化的项目激活流程示例
# 用于演示新的3步激活机制

echo "🚀 项目简化激活流程演示"
echo "================================"

# 步骤1: 快速项目识别
echo "📋 步骤1: 快速项目识别"
PROJECT_ROOT=$(pwd)
SERENA_CONFIG="$PROJECT_ROOT/.serena/project.yml"

if [ -f "$SERENA_CONFIG" ]; then
    PROJECT_NAME=$(grep "project_name:" "$SERENA_CONFIG" | cut -d"'" -f2)
    LANGUAGE=$(grep "language:" "$SERENA_CONFIG" | cut -d" " -f2)
    echo "✅ 项目识别成功: $PROJECT_NAME ($LANGUAGE)"
else
    echo "❌ 未找到.serena/project.yml配置文件"
    exit 1
fi

# 步骤2: 核心信息加载
echo ""
echo "📋 步骤2: 核心信息加载"
MEMORIES_DIR="$PROJECT_ROOT/.serena/memories"

if [ -d "$MEMORIES_DIR" ]; then
    MEMORY_COUNT=$(ls "$MEMORIES_DIR" | wc -l)

    # 查找核心项目信息文件（最多3个）
    CORE_INFO=$(find "$MEMORIES_DIR" -name "*core_info*" -o -name "*project_info*" | head -3)
    echo "✅ 找到 $MEMORY_COUNT 个记忆文件"

    if [ -n "$CORE_INFO" ]; then
        echo "✅ 核心信息文件:"
        echo "$CORE_INFO" | while read file; do
            echo "  - $(basename "$file")"
        done
    fi
else
    echo "⚠️  未找到记忆目录"
fi

# 步骤3: 状态报告
echo ""
echo "📋 步骤3: 状态报告"
echo "📊 项目状态:"
echo "  - 项目名称: $PROJECT_NAME"
echo "  - 开发语言: $LANGUAGE"
echo "  - 记忆数量: $MEMORY_COUNT"
echo "  - 激活状态: ✅ 就绪"

echo ""
echo "🎯 快速访问建议:"
echo "  - 查看记忆: list_memories"
echo "  - 读取核心信息: read_memory <memory_name>"
echo "  - 开始工作: 直接提出需求"

echo ""
echo "✨ 简化激活完成! 耗时: ~3秒"