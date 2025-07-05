#!/bin/bash

echo "🔧 Tesseract OCR轻量级安装脚本"
echo "============================="

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

echo -e "${YELLOW}📦 安装系统依赖...${NC}"
# 安装Tesseract OCR系统包
sudo apt update
sudo apt install -y tesseract-ocr tesseract-ocr-chi-sim tesseract-ocr-chi-tra
sudo apt install -y python3-dev build-essential

# 安装常用语言包
echo -e "${YELLOW}🌐 安装多语言支持...${NC}"
sudo apt install -y tesseract-ocr-eng tesseract-ocr-fra tesseract-ocr-deu 
sudo apt install -y tesseract-ocr-spa tesseract-ocr-ita tesseract-ocr-por
sudo apt install -y tesseract-ocr-rus tesseract-ocr-jpn tesseract-ocr-kor

echo -e "${YELLOW}🔄 升级pip...${NC}"
# 升级pip
pip install --upgrade pip setuptools wheel

echo -e "${YELLOW}📚 安装Python依赖...${NC}"
# 安装Python包
pip install -r requirements.txt

echo -e "${YELLOW}🧪 测试Tesseract安装...${NC}"
# 测试Tesseract安装
tesseract --version

# 检查语言包
echo -e "${YELLOW}📋 已安装的语言包:${NC}"
tesseract --list-langs

echo -e "${YELLOW}🧪 测试Python依赖...${NC}"
# 测试关键依赖
python -c "
import sys
print(f'Python版本: {sys.version}')

try:
    import fastapi
    print(f'✅ FastAPI: {fastapi.__version__}')
except Exception as e:
    print(f'❌ FastAPI: {e}')

try:
    import uvicorn
    print(f'✅ Uvicorn: {uvicorn.__version__}')
except Exception as e:
    print(f'❌ Uvicorn: {e}')

try:
    from PIL import Image
    import PIL
    print(f'✅ Pillow: {PIL.__version__}')
except Exception as e:
    print(f'❌ Pillow: {e}')

try:
    import pytesseract
    print(f'✅ pytesseract: 已安装')
except Exception as e:
    print(f'❌ pytesseract: {e}')

try:
    import langdetect
    print(f'✅ langdetect: 已安装')
except Exception as e:
    print(f'❌ langdetect: {e}')

try:
    import docx
    print(f'✅ python-docx: 已安装')
except Exception as e:
    print(f'❌ python-docx: {e}')

try:
    import reportlab
    print(f'✅ reportlab: {reportlab.Version}')
except Exception as e:
    print(f'❌ reportlab: {e}')
"

echo -e "${YELLOW}🔥 测试OCR功能...${NC}"
# 创建简单测试图片进行OCR测试
python -c "
try:
    import pytesseract
    from PIL import Image, ImageDraw, ImageFont
    import os
    
    # 创建测试图片
    img = Image.new('RGB', (300, 100), color='white')
    draw = ImageDraw.Draw(img)
    draw.text((10, 30), 'Hello World 你好世界', fill='black')
    img.save('test_image.png')
    
    # 测试OCR
    text_eng = pytesseract.image_to_string(img, lang='eng')
    text_chi = pytesseract.image_to_string(img, lang='chi_sim')
    
    print(f'✅ 英语OCR结果: {text_eng.strip()}')
    print(f'✅ 中文OCR结果: {text_chi.strip()}')
    
    # 清理测试文件
    os.remove('test_image.png')
    print('✅ OCR功能测试完成!')
    
except Exception as e:
    print(f'❌ OCR测试失败: {e}')
    import traceback
    traceback.print_exc()
"

echo -e "${GREEN}🎉 Tesseract OCR安装完成!${NC}"
echo -e "${YELLOW}📊 内存使用情况:${NC}"
echo "Tesseract OCR: ~50-200MB (vs PaddleOCR: ~10GB+)"

echo -e "${YELLOW}📋 下一步:${NC}"
echo "1. 测试后端: python main.py"
echo "2. 启动服务: uvicorn main:app --host 0.0.0.0 --port 8000"

echo -e "${YELLOW}📝 Tesseract特性:${NC}"
echo "✅ 内存占用低 (<500MB)"
echo "✅ 启动速度快"
echo "✅ 支持80+语言"
echo "✅ 适合小内存服务器"
echo "✅ 开源免费"

echo -e "${YELLOW}🔧 如果遇到问题:${NC}"
echo "1. 检查Tesseract: tesseract --version"
echo "2. 检查语言包: tesseract --list-langs"
echo "3. 重新安装: sudo apt install --reinstall tesseract-ocr" 