#!/bin/bash

echo "🔧 OCR项目依赖安装脚本"
echo "========================"

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
# 安装系统级依赖
sudo apt update
sudo apt install -y python3-dev build-essential
sudo apt install -y libjpeg-dev zlib1g-dev libpng-dev libtiff5-dev
sudo apt install -y libfreetype6-dev liblcms2-dev libwebp-dev
sudo apt install -y libharfbuzz-dev libfribidi-dev libxcb1-dev
sudo apt install -y pkg-config

echo -e "${YELLOW}🔄 升级pip和基础工具...${NC}"
# 升级pip和基础工具
pip install --upgrade pip
pip install --upgrade setuptools wheel

echo -e "${YELLOW}🧹 清理旧依赖...${NC}"
# 清理可能冲突的旧包
pip uninstall -y paddlepaddle paddleocr Pillow opencv-python 2>/dev/null || true

echo -e "${YELLOW}📚 分步安装核心依赖...${NC}"
# 分步安装，避免依赖冲突

# 1. 安装基础Web框架
echo "安装FastAPI..."
pip install "fastapi>=0.104.0,<0.120.0"
pip install "uvicorn[standard]>=0.24.0,<0.35.0"
pip install "python-multipart>=0.0.6,<0.1.0"

# 2. 安装图像处理库
echo "安装图像处理库..."
pip install "numpy>=1.21.0,<2.0.0"
pip install "Pillow>=10.0.0,<12.0.0"

# 3. 安装文本处理库
echo "安装文本处理库..."
pip install "langdetect>=1.0.9,<2.0.0"
pip install "python-docx>=1.1.0,<2.0.0"
pip install "reportlab>=4.0.0,<5.0.0"

# 4. 安装OpenCV (PaddleOCR依赖)
echo "安装OpenCV..."
pip install "opencv-python>=4.5.0,<5.0.0"

# 5. 安装PaddlePaddle (CPU版本)
echo "安装PaddlePaddle..."
pip install "paddlepaddle>=3.0.0,<4.0.0" -i https://pypi.tuna.tsinghua.edu.cn/simple

# 6. 安装PaddleOCR
echo "安装PaddleOCR..."
pip install "paddleocr>=3.0.0,<4.0.0" -i https://pypi.tuna.tsinghua.edu.cn/simple

echo -e "${YELLOW}🧪 测试依赖安装...${NC}"
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
    import langdetect
    print(f'✅ langdetect: {langdetect.__version__ if hasattr(langdetect, \"__version__\") else \"已安装\"}')
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

try:
    import paddle
    print(f'✅ paddlepaddle: {paddle.__version__}')
except Exception as e:
    print(f'❌ paddlepaddle: {e}')

try:
    from paddleocr import PaddleOCR
    print(f'✅ paddleocr: 已安装')
except Exception as e:
    print(f'❌ paddleocr: {e}')
"

echo -e "${YELLOW}🔥 测试PaddleOCR初始化...${NC}"
# 测试PaddleOCR初始化
python -c "
try:
    from paddleocr import PaddleOCR
    print('正在初始化PaddleOCR...')
    ocr = PaddleOCR(use_angle_cls=True, lang='ch', use_gpu=False, show_log=False)
    print('✅ PaddleOCR初始化成功!')
except Exception as e:
    print(f'❌ PaddleOCR初始化失败: {e}')
    import traceback
    traceback.print_exc()
"

echo -e "${GREEN}🎉 依赖安装完成!${NC}"
echo -e "${YELLOW}📋 下一步:${NC}"
echo "1. 测试后端: python -m main"
echo "2. 启动服务: uvicorn main:app --host 0.0.0.0 --port 8000"

echo -e "${YELLOW}📝 如果遇到问题:${NC}"
echo "1. 检查系统依赖: sudo apt install python3-dev build-essential"
echo "2. 重新安装: pip install --force-reinstall paddleocr"
echo "3. 清理缓存: pip cache purge" 