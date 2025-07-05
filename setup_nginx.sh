#!/bin/bash

echo "🔧 配置Nginx服务 - 服务器: 47.99.143.167"
echo "========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查是否为root权限
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ 请不要使用root用户运行此脚本${NC}"
    echo "请使用: sudo ./setup_nginx.sh"
    exit 1
fi

# 检查Nginx是否已安装
if ! command -v nginx &> /dev/null; then
    echo -e "${YELLOW}📦 安装Nginx...${NC}"
    sudo apt update
    sudo apt install -y nginx
    echo -e "${GREEN}✅ Nginx安装完成${NC}"
else
    echo -e "${GREEN}✅ Nginx已安装: $(nginx -v 2>&1)${NC}"
fi

# 停止Nginx服务（防止配置冲突）
echo -e "${YELLOW}🛑 停止Nginx服务...${NC}"
sudo systemctl stop nginx

# 备份现有配置
echo -e "${YELLOW}💾 备份现有配置...${NC}"
if [ -f /etc/nginx/sites-enabled/default ]; then
    sudo cp /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.backup.$(date +%Y%m%d_%H%M%S)
    echo "✅ 默认配置已备份"
fi

# 移除默认配置
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-enabled/ocr-project

# 复制新的配置文件
echo -e "${YELLOW}📝 部署OCR项目配置...${NC}"
sudo cp nginx-ocr.conf /etc/nginx/sites-available/ocr-project

# 创建软链接启用配置
sudo ln -sf /etc/nginx/sites-available/ocr-project /etc/nginx/sites-enabled/

# 测试Nginx配置
echo -e "${YELLOW}🧪 测试Nginx配置...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Nginx配置文件语法正确${NC}"
else
    echo -e "${RED}❌ Nginx配置文件语法错误${NC}"
    echo "请检查配置文件"
    exit 1
fi

# 检查项目目录是否存在
PROJECT_DIR="/home/admin/ocrProject"
DIST_DIR="$PROJECT_DIR/dist"

if [ ! -d "$DIST_DIR" ]; then
    echo -e "${YELLOW}⚠️  前端dist目录不存在: $DIST_DIR${NC}"
    echo "请先构建前端项目:"
    echo "  cd $PROJECT_DIR"
    echo "  npm run build"
    read -p "是否继续配置Nginx? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 设置目录权限
echo -e "${YELLOW}🔐 设置目录权限...${NC}"
if [ -d "$PROJECT_DIR" ]; then
    sudo chown -R admin:admin "$PROJECT_DIR"
    sudo chmod -R 755 "$PROJECT_DIR"
    echo "✅ 项目目录权限已设置"
fi

# 创建日志目录
echo -e "${YELLOW}📋 创建日志目录...${NC}"
sudo mkdir -p /var/log/nginx
sudo touch /var/log/nginx/ocr_access.log
sudo touch /var/log/nginx/ocr_error.log
sudo chown www-data:adm /var/log/nginx/ocr_*.log

# 启动Nginx服务
echo -e "${YELLOW}🚀 启动Nginx服务...${NC}"
sudo systemctl start nginx
sudo systemctl enable nginx

# 检查服务状态
if sudo systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✅ Nginx服务启动成功${NC}"
else
    echo -e "${RED}❌ Nginx服务启动失败${NC}"
    echo "查看错误日志:"
    sudo journalctl -u nginx --no-pager --lines=10
    exit 1
fi

# 检查端口监听
echo -e "${YELLOW}🔍 检查端口监听...${NC}"
if netstat -tlnp | grep -q ":80.*nginx"; then
    echo -e "${GREEN}✅ Nginx正在监听80端口${NC}"
else
    echo -e "${RED}❌ Nginx未正确监听80端口${NC}"
fi

# 测试网站访问
echo -e "${YELLOW}🌐 测试网站访问...${NC}"
sleep 2

# 测试根路径
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")
if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ 前端页面访问正常 (HTTP 200)${NC}"
elif [ "$HTTP_STATUS" = "404" ]; then
    echo -e "${YELLOW}⚠️  前端页面返回404，可能需要构建前端${NC}"
else
    echo -e "${YELLOW}⚠️  前端页面返回HTTP $HTTP_STATUS${NC}"
fi

# 防火墙检查
echo -e "${YELLOW}🔥 检查防火墙设置...${NC}"
if command -v ufw &> /dev/null; then
    if sudo ufw status | grep -q "Status: active"; then
        echo "UFW防火墙已启用，请确保允许80端口:"
        echo "  sudo ufw allow 80"
        echo "  sudo ufw allow 'Nginx Full'"
    fi
fi

# 显示配置信息
echo ""
echo -e "${GREEN}🎉 Nginx配置完成！${NC}"
echo "========================================"
echo -e "🌐 网站地址: ${BLUE}http://47.99.143.167${NC}"
echo -e "🔧 API地址: ${BLUE}http://47.99.143.167/api/${NC}"
echo -e "📖 API文档: ${BLUE}http://47.99.143.167/docs${NC}"
echo -e "💓 健康检查: ${BLUE}http://47.99.143.167/health${NC}"
echo ""
echo -e "${YELLOW}📋 管理命令:${NC}"
echo "  重启Nginx: sudo systemctl restart nginx"
echo "  查看状态: sudo systemctl status nginx"
echo "  查看日志: sudo tail -f /var/log/nginx/ocr_error.log"
echo "  测试配置: sudo nginx -t"
echo ""
echo -e "${YELLOW}📁 重要文件位置:${NC}"
echo "  配置文件: /etc/nginx/sites-available/ocr-project"
echo "  访问日志: /var/log/nginx/ocr_access.log"
echo "  错误日志: /var/log/nginx/ocr_error.log"
echo "  前端文件: /home/admin/ocrProject/dist"
echo ""
echo -e "${YELLOW}🔧 下一步操作:${NC}"
echo "1. 确保后端服务运行: cd ~/ocrProject/src/BackendFastApi/ocrProjectBackend && pm2 start"
echo "2. 如果前端404，请构建: cd ~/ocrProject && npm run build"
echo "3. 测试访问: curl http://47.99.143.167"
echo ""
echo -e "${GREEN}✨ Nginx配置部署完成！${NC}" 