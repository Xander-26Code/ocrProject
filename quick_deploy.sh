#!/bin/bash

# OCR项目快速部署脚本
# 这是一个简化的一键部署脚本，适合快速部署到新服务器

echo "🚀 OCR项目快速部署"
echo "===================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查是否为root用户
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ 请不要使用root用户运行此脚本${NC}"
    echo "请使用普通用户，脚本会在需要时要求sudo权限"
    exit 1
fi

# 加载配置文件
if [[ -f "config.env" ]]; then
    source config.env
    echo -e "${GREEN}✅ 已加载配置文件${NC}"
else
    echo -e "${YELLOW}⚠️  未找到config.env，使用默认配置${NC}"
    # 设置默认值
    NGINX_PORT=80
    BACKEND_PORT=8000
    PROJECT_DIR="/home/admin/ocrProject"
    AUTO_START_SERVICES=true
    INSTALL_SYSTEM_DEPS=true
fi

# 自动检测服务器IP
get_server_ip() {
    local external_ip=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || curl -s icanhazip.com 2>/dev/null)
    local local_ip=$(ip route get 1 2>/dev/null | awk '{print $7}' | head -1)
    local env_ip="${SERVER_IP:-}"
    
    if [[ -n "$env_ip" ]]; then
        echo "$env_ip"
    elif [[ -n "$external_ip" ]]; then
        echo "$external_ip"
    elif [[ -n "$local_ip" ]]; then
        echo "$local_ip"
    else
        echo "localhost"
    fi
}

SERVER_IP=$(get_server_ip)

echo -e "${BLUE}🌐 服务器IP: $SERVER_IP${NC}"
echo -e "${BLUE}📂 项目目录: $PROJECT_DIR${NC}"
echo -e "${BLUE}🔧 后端端口: $BACKEND_PORT${NC}"
echo -e "${BLUE}🌐 前端端口: $NGINX_PORT${NC}"
echo ""

# 确认部署
echo -e "${YELLOW}📋 即将执行以下操作:${NC}"
echo "1. 安装系统依赖（Python、Node.js、Nginx、Tesseract）"
echo "2. 部署后端服务（FastAPI + OCR）"
echo "3. 构建前端项目（Vue.js）"
echo "4. 配置Nginx反向代理"
echo "5. 启动所有服务"
echo ""

read -p "确认开始部署吗? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "部署已取消"
    exit 1
fi

# 函数：检查命令结果
check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1 成功${NC}"
    else
        echo -e "${RED}❌ $1 失败${NC}"
        exit 1
    fi
}

# 显示进度
show_progress() {
    echo -e "${YELLOW}🔄 $1...${NC}"
}

# =============================================================================
# 开始部署
# =============================================================================

# 1. 系统依赖安装
if [[ "$INSTALL_SYSTEM_DEPS" == "true" ]]; then
    show_progress "安装系统依赖"
    
    # 解决apt锁定问题
    sudo killall unattended-upgr apt apt-get 2>/dev/null || true
    sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock 2>/dev/null || true
    sudo dpkg --configure -a
    
    # 更新系统
    sudo apt update -y
    sudo apt install -y python3-venv python3-dev build-essential nginx curl
    sudo apt install -y tesseract-ocr tesseract-ocr-chi-sim tesseract-ocr-eng
    check_result "系统依赖安装"
    
    # 安装Node.js
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
        check_result "Node.js安装"
    fi
    
    # 安装PM2
    if ! command -v pm2 &> /dev/null; then
        sudo npm install -g pm2
        check_result "PM2安装"
    fi
fi

# 2. 后端部署
show_progress "部署后端服务"
cd "$PROJECT_DIR/src/BackendFastApi/ocrProjectBackend"

# 创建虚拟环境
if [ ! -d "venv" ]; then
    python3 -m venv venv
    check_result "虚拟环境创建"
fi

# 安装依赖
source venv/bin/activate
if [ -f "install_tesseract.sh" ]; then
    chmod +x install_tesseract.sh
    ./install_tesseract.sh
    check_result "后端依赖安装"
else
    pip install -r requirements.txt
    check_result "后端依赖安装"
fi

# 3. 前端构建
show_progress "构建前端项目"
cd "$PROJECT_DIR"

# 安装前端依赖
if [ -f "package.json" ]; then
    npm install
    check_result "前端依赖安装"
    
    # 构建前端
    npm run build
    check_result "前端构建"
fi

# 4. 配置Nginx
show_progress "配置Nginx"

# 解决403 Forbidden问题 - 确保Nginx有权限访问项目目录
if [[ -d "$(dirname "$PROJECT_DIR")" ]]; then
    sudo chmod 755 "$(dirname "$PROJECT_DIR")"
    echo -e "${GREEN}✅ 已设置项目父目录权限: $(dirname "$PROJECT_DIR")${NC}"
fi

# 创建临时配置文件
cp nginx-ocr.conf /tmp/ocr-project.conf
sed -i "s/SERVER_IP_PLACEHOLDER/$SERVER_IP/g" /tmp/ocr-project.conf

# 备份现有配置
if [ -f /etc/nginx/sites-enabled/default ]; then
    sudo cp /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.backup.$(date +%Y%m%d_%H%M%S)
fi

# 部署新配置
sudo cp /tmp/ocr-project.conf /etc/nginx/sites-available/ocr-project
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-enabled/ocr-project
sudo ln -sf /etc/nginx/sites-available/ocr-project /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t
check_result "Nginx配置"

# 清理临时文件
rm -f /tmp/ocr-project.conf

# 重启Nginx
sudo systemctl restart nginx
check_result "Nginx重启"

# 5. 启动服务
if [[ "$AUTO_START_SERVICES" == "true" ]]; then
    show_progress "启动后端服务"
    
    # 创建PM2配置 (使用 .cjs 扩展名以兼容新版Node.js)
    cat > ecosystem.config.cjs << EOF
module.exports = {
  apps: [{
    name: 'ocr-backend',
    script: '$PROJECT_DIR/src/BackendFastApi/ocrProjectBackend/venv/bin/uvicorn',
    args: 'main:app --host 127.0.0.1 --port $BACKEND_PORT',
    cwd: '$PROJECT_DIR/src/BackendFastApi/ocrProjectBackend',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '512M',
    env: {
      NODE_ENV: 'production'
    },
    error_file: '$PROJECT_DIR/logs/err.log',
    out_file: '$PROJECT_DIR/logs/out.log',
    log_file: '$PROJECT_DIR/logs/combined.log',
    time: true
  }]
};
EOF
    
    # 创建日志目录
    mkdir -p "$PROJECT_DIR/logs"
    
    # 启动服务
    pm2 delete ocr-backend 2>/dev/null || true
    pm2 start ecosystem.config.cjs
    pm2 save
    check_result "后端服务启动"
fi

# =============================================================================
# 部署完成
# =============================================================================

echo ""
echo -e "${GREEN}🎉 OCR项目部署完成！${NC}"
echo "=============================="
echo -e "🌐 访问地址: ${BLUE}http://$SERVER_IP${NC}"
echo -e "🔧 API地址: ${BLUE}http://$SERVER_IP/api/${NC}"
echo -e "📖 API文档: ${BLUE}http://$SERVER_IP/docs${NC}"
echo -e "💓 健康检查: ${BLUE}http://$SERVER_IP/health${NC}"
echo ""
echo -e "${YELLOW}📋 管理命令:${NC}"
echo "  查看服务状态: pm2 status"
echo "  重启后端: pm2 restart ocr-backend"
echo "  查看日志: pm2 logs ocr-backend"
echo "  重启Nginx: sudo systemctl restart nginx"
echo ""
echo -e "${YELLOW}🧪 测试命令:${NC}"
echo "  curl http://$SERVER_IP/"
echo "  curl http://$SERVER_IP/api/"
echo ""
echo -e "${GREEN}✨ 部署成功！您的OCR服务已上线！${NC}" 