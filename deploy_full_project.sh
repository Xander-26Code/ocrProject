#!/bin/bash

# 加载配置文件
load_config() {
    if [[ -f "config.env" ]]; then
        source config.env
        echo "✅ 已加载配置文件"
    else
        echo "⚠️  未找到config.env，使用默认配置"
    fi
}

# 自动检测服务器IP地址
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

# 加载配置
load_config
SERVER_IP=$(get_server_ip)

echo "🚀 OCR项目完整部署脚本 - 服务器: $SERVER_IP"
echo "================================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目目录
PROJECT_DIR="/home/admin/ocrProject"
BACKEND_DIR="$PROJECT_DIR/src/BackendFastApi/ocrProjectBackend"

echo -e "${BLUE}📂 项目目录: $PROJECT_DIR${NC}"

# 函数：等待用户确认
wait_for_user() {
    echo -e "${YELLOW}按Enter键继续，或Ctrl+C取消...${NC}"
    read
}

# 函数：检查命令是否成功
check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1 成功${NC}"
    else
        echo -e "${RED}❌ $1 失败${NC}"
        exit 1
    fi
}

echo -e "${YELLOW}📋 部署计划:${NC}"
echo "1. 系统环境检查和依赖安装"
echo "2. 后端服务部署"
echo "3. 前端构建和部署"
echo "4. Nginx配置"
echo "5. 服务启动和测试"
echo ""
wait_for_user

# =============================================================================
# 第1步：系统环境检查
# =============================================================================
echo -e "${YELLOW}🔧 第1步: 系统环境检查...${NC}"

# 解决apt锁定问题
echo "解决系统锁定问题..."
sudo killall unattended-upgr apt apt-get 2>/dev/null || true
sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock
sudo dpkg --configure -a

# 更新系统
sudo apt update
check_result "系统更新"

# 安装系统依赖
echo "安装系统依赖..."
sudo apt install -y python3-venv python3-dev build-essential nginx curl
sudo apt install -y tesseract-ocr tesseract-ocr-chi-sim tesseract-ocr-eng
check_result "系统依赖安装"

# 安装Node.js
if ! command -v node &> /dev/null; then
    echo "安装Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
    check_result "Node.js安装"
fi

echo -e "${GREEN}✅ 第1步完成 - 系统环境准备就绪${NC}"
echo "Node.js版本: $(node --version)"
echo "Python版本: $(python3 --version)"
echo "Tesseract版本: $(tesseract --version | head -1)"
wait_for_user

# =============================================================================
# 第2步：后端服务部署
# =============================================================================
echo -e "${YELLOW}🐍 第2步: 后端服务部署...${NC}"

# 进入后端目录
cd "$BACKEND_DIR"

# 创建虚拟环境
if [ ! -d "venv" ]; then
    python3 -m venv venv
    check_result "虚拟环境创建"
fi

# 激活虚拟环境并安装依赖
source venv/bin/activate
chmod +x install_tesseract.sh
./install_tesseract.sh
check_result "后端依赖安装"

echo -e "${GREEN}✅ 第2步完成 - 后端服务准备就绪${NC}"
wait_for_user

# =============================================================================
# 第3步：前端构建和部署
# =============================================================================
echo -e "${YELLOW}🌐 第3步: 前端构建和部署...${NC}"

# 回到项目根目录
cd "$PROJECT_DIR"

# 运行前端部署脚本
chmod +x deploy_frontend.sh
./deploy_frontend.sh
check_result "前端构建部署"

echo -e "${GREEN}✅ 第3步完成 - 前端构建部署完成${NC}"
wait_for_user

# =============================================================================
# 第4步：Nginx配置
# =============================================================================
echo -e "${YELLOW}⚙️  第4步: Nginx配置...${NC}"

# 运行Nginx配置脚本
chmod +x setup_nginx.sh
./setup_nginx.sh
check_result "Nginx配置"

echo -e "${GREEN}✅ 第4步完成 - Nginx配置完成${NC}"
wait_for_user

# =============================================================================
# 第5步：服务启动和测试
# =============================================================================
echo -e "${YELLOW}🚀 第5步: 服务启动和测试...${NC}"

# 安装PM2
if ! command -v pm2 &> /dev/null; then
    sudo npm install -g pm2
    check_result "PM2安装"
fi

# 创建PM2配置
cd "$PROJECT_DIR"
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'ocr-backend',
    script: '$BACKEND_DIR/venv/bin/uvicorn',
    args: 'main:app --host 127.0.0.1 --port 8000',
    cwd: '$BACKEND_DIR',
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

# 停止现有服务
pm2 delete ocr-backend 2>/dev/null || true

# 启动服务
pm2 start ecosystem.config.js
pm2 save
pm2 startup
check_result "后端服务启动"

echo -e "${GREEN}✅ 第5步完成 - 服务启动完成${NC}"

# =============================================================================
# 最终测试
# =============================================================================
echo -e "${YELLOW}🧪 最终测试...${NC}"

# 等待服务启动
sleep 5

# 测试后端
echo "测试后端API..."
BACKEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/ 2>/dev/null || echo "000")
if [ "$BACKEND_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ 后端API正常 (HTTP 200)${NC}"
else
    echo -e "${RED}❌ 后端API异常 (HTTP $BACKEND_STATUS)${NC}"
fi

# 测试前端
echo "测试前端页面..."
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")
if [ "$FRONTEND_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ 前端页面正常 (HTTP 200)${NC}"
else
    echo -e "${RED}❌ 前端页面异常 (HTTP $FRONTEND_STATUS)${NC}"
fi

# 测试API代理
echo "测试API代理..."
API_PROXY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/ 2>/dev/null || echo "000")
if [ "$API_PROXY_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ API代理正常 (HTTP 200)${NC}"
else
    echo -e "${RED}❌ API代理异常 (HTTP $API_PROXY_STATUS)${NC}"
fi

# 检查防火墙
echo -e "${YELLOW}🔥 检查防火墙设置...${NC}"
if command -v ufw &> /dev/null && sudo ufw status | grep -q "Status: active"; then
    echo -e "${YELLOW}⚠️  防火墙已启用，请确保允许80端口:${NC}"
    echo "  sudo ufw allow 80"
    echo "  sudo ufw allow 'Nginx Full'"
fi

# =============================================================================
# 部署完成
# =============================================================================
echo ""
echo -e "${GREEN}🎉 OCR项目部署完成！${NC}"
echo "================================================="
echo -e "🌐 访问地址: ${BLUE}http://$SERVER_IP${NC}"
echo -e "🔧 API地址: ${BLUE}http://$SERVER_IP/api/${NC}"
echo -e "📖 API文档: ${BLUE}http://$SERVER_IP/docs${NC}"
echo -e "💓 健康检查: ${BLUE}http://$SERVER_IP/health${NC}"
echo ""
echo -e "${YELLOW}📊 部署信息:${NC}"
echo "  服务器地址: $SERVER_IP"
echo "  项目目录: $PROJECT_DIR"
echo "  前端文件: $PROJECT_DIR/dist"
echo "  后端目录: $BACKEND_DIR"
echo "  日志目录: $PROJECT_DIR/logs"
echo ""
echo -e "${YELLOW}📋 管理命令:${NC}"
echo "  查看服务状态: pm2 status"
echo "  重启后端服务: pm2 restart ocr-backend"
echo "  查看后端日志: pm2 logs ocr-backend"
echo "  重启Nginx: sudo systemctl restart nginx"
echo "  查看Nginx日志: sudo tail -f /var/log/nginx/ocr_error.log"
echo ""
echo -e "${YELLOW}🧪 测试命令:${NC}"
echo "  curl http://$SERVER_IP/"
echo "  curl http://$SERVER_IP/api/"
echo "  curl http://$SERVER_IP/docs"
echo ""
echo -e "${YELLOW}💾 特性说明:${NC}"
echo "  ✅ 轻量级Tesseract OCR引擎"
echo "  ✅ 支持多种语言识别"
echo "  ✅ 支持文本/Word/PDF输出"
echo "  ✅ 自动语言检测功能"
echo "  ✅ 适合4GB内存服务器"
echo "  ✅ 内存占用: ~300-500MB"
echo ""
echo -e "${GREEN}✨ 部署成功！您的OCR服务已上线！${NC}"
echo -e "${BLUE}现在可以访问 http://$SERVER_IP 使用您的OCR应用${NC}" 