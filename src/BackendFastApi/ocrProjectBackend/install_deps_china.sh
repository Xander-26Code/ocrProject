#!/bin/bash

echo "🔧 Python依赖安装脚本 - 中国镜像源"
echo "================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查虚拟环境
if [[ "$VIRTUAL_ENV" == "" ]]; then
    echo -e "${RED}❌ 请先激活虚拟环境${NC}"
    echo "执行: source venv/bin/activate"
    exit 1
fi

echo -e "${BLUE}📂 当前虚拟环境: $VIRTUAL_ENV${NC}"

# 配置pip镜像源
echo -e "${YELLOW}⚙️  配置pip镜像源...${NC}"
mkdir -p ~/.pip
cat > ~/.pip/pip.conf << EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
timeout = 120
retries = 5

[install]
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF

echo -e "${GREEN}✅ pip镜像源配置完成${NC}"

# 升级pip和基础工具
echo -e "${YELLOW}🔄 升级pip和基础工具...${NC}"
python -m pip install --upgrade pip setuptools wheel
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 基础工具升级成功${NC}"
else
    echo -e "${RED}❌ 基础工具升级失败${NC}"
    exit 1
fi

# 定义要安装的包
packages=(
    "fastapi>=0.104.0,<0.120.0"
    "uvicorn[standard]>=0.24.0,<0.35.0"
    "python-multipart>=0.0.6,<0.1.0"
    "Pillow>=10.0.0,<12.0.0"
    "pytesseract>=0.3.10,<1.0.0"
    "langdetect>=1.0.9,<2.0.0"
    "python-docx>=1.1.0,<2.0.0"
    "reportlab>=4.0.0,<5.0.0"
)

# 逐个安装包
echo -e "${YELLOW}📦 开始安装Python包...${NC}"
for package in "${packages[@]}"; do
    echo -e "${BLUE}正在安装: $package${NC}"
    pip install "$package"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $package 安装成功${NC}"
    else
        echo -e "${RED}❌ $package 安装失败${NC}"
        echo -e "${YELLOW}尝试单独安装...${NC}"
        pip install --no-deps "$package"
    fi
    echo "---"
done

# 验证安装
echo -e "${YELLOW}🧪 验证安装结果...${NC}"

python << 'EOF'
import sys
print(f"Python版本: {sys.version}")
print("=" * 40)

modules = [
    ('fastapi', 'FastAPI'),
    ('uvicorn', 'Uvicorn'), 
    ('pytesseract', 'pytesseract'),
    ('PIL', 'Pillow'),
    ('langdetect', 'langdetect'),
    ('docx', 'python-docx'),
    ('reportlab', 'reportlab'),
    ('multipart', 'python-multipart')
]

success_count = 0
for module, name in modules:
    try:
        __import__(module)
        print(f"✅ {name}: OK")
        success_count += 1
    except ImportError as e:
        print(f"❌ {name}: {e}")

print("=" * 40)
print(f"安装成功: {success_count}/{len(modules)}")

if success_count == len(modules):
    print("🎉 所有依赖安装成功！")
    exit(0)
else:
    print("⚠️  部分依赖安装失败")
    exit(1)
EOF

install_result=$?

if [ $install_result -eq 0 ]; then
    echo -e "${GREEN}🎉 所有Python依赖安装完成！${NC}"
    echo -e "${YELLOW}📋 下一步操作:${NC}"
    echo "1. 测试后端: python main.py"
    echo "2. 启动服务: uvicorn main:app --host 0.0.0.0 --port 8000"
    echo "3. 访问API文档: http://localhost:8000/docs"
else
    echo -e "${RED}❌ 依赖安装失败，请检查错误信息${NC}"
    exit 1
fi 