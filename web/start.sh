#!/bin/bash

# IdeaCapture Web 查看器启动脚本

echo "🚀 启动 IdeaCapture Web 查看器..."

# 检查 Python 是否存在
if ! command -v python3 &> /dev/null; then
    echo "❌ 错误: 未找到 Python 3"
    echo "请先安装 Python 3: https://www.python.org/downloads/"
    exit 1
fi

# 检查是否在正确的目录
if [ ! -f "server.py" ]; then
    echo "❌ 错误: 请在 web 目录下运行此脚本"
    echo "cd IdeaCapture/web && ./start.sh"
    exit 1
fi

# 检查 .env 文件是否存在
ENV_FILE="../IdeaCapture/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "⚠️  警告: 未找到环境变量文件 $ENV_FILE"
    echo "请先配置 Supabase 信息"
else
    echo "✅ 找到环境变量文件"
fi

# 检查并创建虚拟环境
if [ ! -d "venv" ]; then
    echo "📦 创建虚拟环境..."
    python3 -m venv venv
    echo "✅ 虚拟环境创建成功"
fi

# 激活虚拟环境
echo "🔄 激活虚拟环境..."
source venv/bin/activate

# 检查依赖
echo "📦 检查依赖..."
if ! pip list | grep -q fastapi; then
    echo "📥 安装依赖..."
    pip install -r requirements.txt
    echo "✅ 依赖安装完成"
else
    echo "✅ 依赖已安装"
fi

# 启动服务器
echo ""
echo "========================================="
echo "  🌐 IdeaCapture Web 查看器"
echo "========================================="
echo "  访问地址: http://localhost:8080"
echo "  API文档:   http://localhost:8080/docs"
echo "========================================="
echo ""
echo "按 Ctrl+C 停止服务器"
echo ""

python server.py
