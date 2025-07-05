#!/bin/bash

echo "🚀 启动OCR后端服务"
echo "=================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查是否在虚拟环境中
if [[ "$VIRTUAL_ENV" == "" ]]; then
    echo -e "${RED}❌ 请先激活虚拟环境: source venv/bin/activate${NC}"
    exit 1
fi

# 检查依赖
echo -e "${YELLOW}🔍 检查依赖...${NC}"
python -c "
try:
    import fastapi, uvicorn, pytesseract
    from PIL import Image
    print('✅ 所有依赖已安装')
except ImportError as e:
    print(f'❌ 缺少依赖: {e}')
    print('请运行: ./install_tesseract.sh')
    exit(1)
"

if [ $? -ne 0 ]; then
    exit 1
fi

# 检查Tesseract
echo -e "${YELLOW}🔍 检查Tesseract OCR...${NC}"
if ! command -v tesseract &> /dev/null; then
    echo -e "${RED}❌ Tesseract OCR未安装${NC}"
    echo "请运行: sudo apt install tesseract-ocr"
    exit 1
fi

echo -e "${GREEN}✅ Tesseract版本: $(tesseract --version | head -1)${NC}"

# 清理临时文件
echo -e "${YELLOW}🧹 清理临时文件...${NC}"
rm -f temp_*

# 启动服务
echo -e "${GREEN}🚀 启动FastAPI服务...${NC}"
echo "访问地址: http://localhost:8000"
echo "API文档: http://localhost:8000/docs"
echo "按 Ctrl+C 停止服务"
echo ""

uvicorn main:app --host 0.0.0.0 --port 8000 --reload 