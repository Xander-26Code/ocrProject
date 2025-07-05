#!/bin/bash

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

SERVER_IP=$(get_server_ip)

echo "🌐 前端构建部署脚本 - 服务器: $SERVER_IP"
echo "=============================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目目录
PROJECT_DIR="/home/admin/ocrProject"
DIST_DIR="$PROJECT_DIR/dist"

echo -e "${BLUE}📂 项目目录: $PROJECT_DIR${NC}"

# 检查是否在项目目录中
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    echo "当前目录: $(pwd)"
    echo "请执行: cd ~/ocrProject && ./deploy_frontend.sh"
    exit 1
fi

# 检查Node.js和npm
echo -e "${YELLOW}🔍 检查Node.js环境...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js未安装${NC}"
    echo "请先安装Node.js:"
    echo "  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
    echo "  sudo apt-get install -y nodejs"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm未安装${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Node.js版本: $(node --version)${NC}"
echo -e "${GREEN}✅ npm版本: $(npm --version)${NC}"

# 清理旧的构建文件
echo -e "${YELLOW}🧹 清理旧的构建文件...${NC}"
if [ -d "$DIST_DIR" ]; then
    rm -rf "$DIST_DIR"
    echo "✅ 已删除旧的dist目录"
fi

# 清理npm缓存
echo -e "${YELLOW}🔄 清理npm缓存...${NC}"
npm cache clean --force

# 检查package.json
echo -e "${YELLOW}📋 检查项目配置...${NC}"
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ package.json不存在${NC}"
    exit 1
fi

# 显示当前配置
echo "项目名称: $(grep '"name"' package.json | cut -d'"' -f4)"
echo "项目版本: $(grep '"version"' package.json | cut -d'"' -f4)"

# 安装依赖
echo -e "${YELLOW}📦 安装项目依赖...${NC}"
if [ -d "node_modules" ]; then
    echo "检测到现有node_modules，是否重新安装？"
    read -p "删除并重新安装依赖? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf node_modules
        npm install
    else
        echo "跳过依赖安装"
    fi
else
    npm install
fi

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 依赖安装失败${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 依赖安装完成${NC}"

# 环境变量配置
echo -e "${YELLOW}⚙️  配置环境变量...${NC}"
cat > .env.production << EOF
# 生产环境配置
VITE_API_URL=/api
VITE_APP_TITLE=OCR Pro
VITE_APP_DESCRIPTION=智能文字识别系统
NODE_ENV=production
EOF

echo "✅ 生产环境配置文件已创建"

# 构建项目
echo -e "${YELLOW}🔨 构建前端项目...${NC}"
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ 前端构建失败${NC}"
    echo "请检查构建错误信息"
    exit 1
fi

# 检查构建结果
if [ ! -d "$DIST_DIR" ]; then
    echo -e "${RED}❌ 构建失败：dist目录不存在${NC}"
    exit 1
fi

echo -e "${GREEN}✅ 前端构建成功${NC}"

# 显示构建信息
echo -e "${YELLOW}📊 构建信息:${NC}"
echo "构建目录: $DIST_DIR"
echo "文件总数: $(find $DIST_DIR -type f | wc -l)"
echo "目录大小: $(du -sh $DIST_DIR | cut -f1)"

# 列出主要文件
echo -e "${YELLOW}📁 主要文件:${NC}"
ls -la $DIST_DIR/

# 检查关键文件
CRITICAL_FILES=("index.html" "assets")
for file in "${CRITICAL_FILES[@]}"; do
    if [ ! -e "$DIST_DIR/$file" ]; then
        echo -e "${RED}❌ 关键文件缺失: $file${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ $file 存在${NC}"
    fi
done

# 设置正确的文件权限
echo -e "${YELLOW}🔐 设置文件权限...${NC}"
sudo chown -R admin:admin "$DIST_DIR"
chmod -R 755 "$DIST_DIR"
echo "✅ 文件权限已设置"

# 检查Nginx配置
echo -e "${YELLOW}🔍 检查Nginx配置...${NC}"
if sudo nginx -t 2>/dev/null; then
    echo -e "${GREEN}✅ Nginx配置正确${NC}"
else
    echo -e "${RED}❌ Nginx配置有误${NC}"
    echo "请检查Nginx配置或运行: ./setup_nginx.sh"
fi

# 重新加载Nginx
echo -e "${YELLOW}🔄 重新加载Nginx配置...${NC}"
if sudo systemctl is-active --quiet nginx; then
    sudo nginx -s reload
    echo -e "${GREEN}✅ Nginx配置已重新加载${NC}"
else
    echo -e "${YELLOW}⚠️  Nginx未运行，尝试启动...${NC}"
    sudo systemctl start nginx
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Nginx已启动${NC}"
    else
        echo -e "${RED}❌ Nginx启动失败${NC}"
    fi
fi

# 测试前端访问
echo -e "${YELLOW}🧪 测试前端访问...${NC}"
sleep 2

# 测试本地访问
LOCAL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")
if [ "$LOCAL_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ 本地访问正常 (HTTP 200)${NC}"
else
    echo -e "${RED}❌ 本地访问失败 (HTTP $LOCAL_STATUS)${NC}"
fi

# 测试服务器访问
SERVER_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$SERVER_IP/ 2>/dev/null || echo "000")
if [ "$SERVER_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ 服务器访问正常 (HTTP 200)${NC}"
else
    echo -e "${YELLOW}⚠️  服务器访问返回 HTTP $SERVER_STATUS${NC}"
    echo "可能需要检查防火墙设置"
fi

# 测试API连接
echo -e "${YELLOW}🔌 测试API连接...${NC}"
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/ 2>/dev/null || echo "000")
if [ "$API_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ API连接正常 (HTTP 200)${NC}"
else
    echo -e "${RED}❌ API连接失败 (HTTP $API_STATUS)${NC}"
    echo "请检查后端服务是否运行"
fi

# 创建部署信息文件
echo -e "${YELLOW}📝 创建部署信息...${NC}"
cat > "$DIST_DIR/deploy-info.json" << EOF
{
    "deployTime": "$(date -Iseconds)",
    "server": "$SERVER_IP",
    "nodeVersion": "$(node --version)",
    "npmVersion": "$(npm --version)",
    "buildSize": "$(du -sh $DIST_DIR | cut -f1)",
    "fileCount": $(find $DIST_DIR -type f | wc -l)
}
EOF

# 显示部署结果
echo ""
echo -e "${GREEN}🎉 前端部署完成！${NC}"
echo "=============================================="
echo -e "🌐 访问地址: ${BLUE}http://$SERVER_IP${NC}"
echo -e "🔧 API地址: ${BLUE}http://$SERVER_IP/api/${NC}"
echo -e "📖 API文档: ${BLUE}http://$SERVER_IP/docs${NC}"
echo ""
echo -e "${YELLOW}📊 部署统计:${NC}"
echo "  构建时间: $(date)"
echo "  文件数量: $(find $DIST_DIR -type f | wc -l)"
echo "  总大小: $(du -sh $DIST_DIR | cut -f1)"
echo ""
echo -e "${YELLOW}📁 重要文件位置:${NC}"
echo "  前端文件: $DIST_DIR"
echo "  Nginx配置: /etc/nginx/sites-available/ocr-project"
echo "  Nginx日志: /var/log/nginx/ocr_*.log"
echo ""
echo -e "${YELLOW}🔧 管理命令:${NC}"
echo "  重新构建: npm run build"
echo "  本地预览: npm run preview"
echo "  重启Nginx: sudo systemctl restart nginx"
echo "  查看日志: sudo tail -f /var/log/nginx/ocr_error.log"
echo ""
echo -e "${YELLOW}🧪 测试命令:${NC}"
echo "  curl http://$SERVER_IP/"
echo "  curl http://$SERVER_IP/api/"
echo ""
echo -e "${GREEN}✨ 前端部署成功！您现在可以访问您的OCR应用了${NC}" 