#!/bin/bash

# 更新OCR项目到PaddleOCR的脚本

echo "🚀 开始更新OCR项目到PaddleOCR..."

# 检查当前目录
if [ ! -f "requirements.txt" ]; then
    echo "❌ 错误: 请在包含requirements.txt的目录中运行此脚本"
    exit 1
fi

# 激活虚拟环境
echo "📦 激活虚拟环境..."
if [ -d "venv" ]; then
    source venv/bin/activate
    echo "✅ 使用本地虚拟环境"
elif [ -d "../../../venv" ]; then
    source ../../../venv/bin/activate
    echo "✅ 使用项目虚拟环境"
else
    echo "❌ 未找到虚拟环境，请先创建虚拟环境"
    echo "💡 创建虚拟环境: python -m venv venv"
    exit 1
fi

# 卸载Tesseract相关包（如果存在）
echo "🧹 清理旧的OCR依赖..."
pip uninstall -y pytesseract 2>/dev/null || true

# 更新pip
echo "🔄 更新pip..."
pip install --upgrade pip

# 安装PaddleOCR和相关依赖
echo "📚 安装PaddleOCR依赖..."
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

# 验证PaddleOCR安装
echo "🔍 验证PaddleOCR安装..."
python -c "
try:
    from paddleocr import PaddleOCR
    print('✅ PaddleOCR安装成功')
    
    # 测试初始化
    print('🧪 测试PaddleOCR初始化...')
    ocr = PaddleOCR(use_angle_cls=True, lang='ch', use_gpu=False, show_log=False)
    print('✅ PaddleOCR初始化成功')
except Exception as e:
    print(f'❌ PaddleOCR安装或初始化失败: {e}')
    exit(1)
"

if [ $? -ne 0 ]; then
    echo "❌ PaddleOCR验证失败"
    exit 1
fi

# 停止现有的FastAPI服务
echo "🛑 停止现有服务..."
pkill -f "uvicorn.*main:app" 2>/dev/null || true
sleep 2

# 启动新的FastAPI服务
echo "🚀 启动FastAPI服务..."
nohup uvicorn main:app --host 0.0.0.0 --port 8001 --reload > fastapi.log 2>&1 &
NEW_PID=$!

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 5

# 检查服务状态
if ps -p $NEW_PID > /dev/null; then
    echo "✅ FastAPI服务启动成功 (PID: $NEW_PID)"
else
    echo "❌ FastAPI服务启动失败，检查日志:"
    tail -10 fastapi.log
    exit 1
fi

# 测试API
echo "🧪 测试API..."
sleep 2
if curl -s http://localhost:8001/ | grep -q "Hello World"; then
    echo "✅ API响应正常"
else
    echo "⚠️  API测试失败，请检查服务状态"
fi

echo ""
echo "🎉 更新完成！"
echo "📋 主要变更："
echo "   ✅ 移除了Tesseract依赖"
echo "   ✅ 集成了PaddleOCR引擎"
echo "   ✅ 支持多种语言识别"
echo "   ✅ 提升了识别准确率"
echo ""
echo "💡 PaddleOCR特性："
echo "   - 支持中文、英文、日文等80+语言"
echo "   - 更高的识别精度"
echo "   - 更快的处理速度"
echo "   - 更好的复杂图片处理能力"
echo ""
echo "📋 服务信息："
echo "   - 服务地址: http://localhost:8001"
echo "   - 日志文件: fastapi.log"
echo "   - 查看日志: tail -f fastapi.log"
echo ""
echo "🔧 如需重启服务，再次运行此脚本即可" 