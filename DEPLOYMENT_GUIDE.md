# OCR项目部署指南

## 🔒 安全部署说明

本项目已经过安全优化，**不包含任何硬编码的服务器IP地址**。所有脚本都会自动检测服务器环境，确保可以在任何服务器上安全部署。

## 📋 部署选项

### 1. 快速部署（推荐）
```bash
# 一键部署，适合新服务器
chmod +x quick_deploy.sh
./quick_deploy.sh
```

### 2. 分步部署
```bash
# 步骤1: 部署后端
cd src/BackendFastApi/ocrProjectBackend
chmod +x install_tesseract.sh
./install_tesseract.sh

# 步骤2: 构建前端
cd ../../../
npm install
npm run build

# 步骤3: 配置Nginx
chmod +x setup_nginx.sh
./setup_nginx.sh

# 步骤4: 启动服务
pm2 start ecosystem.config.js
```

### 3. 完整部署
```bash
# 包含所有环境检查和优化
chmod +x deploy_full_project.sh
./deploy_full_project.sh
```

## ⚙️ 自定义配置

### 配置文件 `config.env`
```bash
# 服务器IP地址（留空将自动检测）
SERVER_IP=

# 服务器端口配置
NGINX_PORT=80
BACKEND_PORT=8000

# 项目目录
PROJECT_DIR=/home/admin/ocrProject

# 部署选项
AUTO_START_SERVICES=true
INSTALL_SYSTEM_DEPS=true
SETUP_FIREWALL=false
```

### 环境变量设置
```bash
# 方法1: 通过环境变量设置
export SERVER_IP=你的服务器IP
./quick_deploy.sh

# 方法2: 修改config.env文件
echo "SERVER_IP=你的服务器IP" > config.env
./quick_deploy.sh
```

## 🔍 IP地址检测机制

脚本会按以下优先级自动检测服务器IP：

1. **环境变量**: `$SERVER_IP`
2. **外部IP**: 通过 `ifconfig.me` 等服务获取公网IP
3. **本地IP**: 通过路由表获取主要网络接口IP
4. **默认值**: `localhost`

## 🚀 快速开始

### 在新服务器上部署
```bash
# 1. 克隆项目
git clone https://github.com/your-username/ocrProject.git
cd ocrProject

# 2. 运行快速部署
chmod +x quick_deploy.sh
./quick_deploy.sh

# 3. 访问应用
# 脚本会自动显示访问地址
```

### 在现有服务器上部署
```bash
# 1. 自定义配置
cat > config.env << EOF
SERVER_IP=你的服务器IP
NGINX_PORT=80
BACKEND_PORT=8000
PROJECT_DIR=/home/admin/ocrProject
AUTO_START_SERVICES=true
INSTALL_SYSTEM_DEPS=false  # 如果已安装系统依赖
EOF

# 2. 部署
./quick_deploy.sh
```

## 🔧 部署后管理

### 服务管理
```bash
# 查看服务状态
pm2 status

# 重启后端服务
pm2 restart ocr-backend

# 查看日志
pm2 logs ocr-backend

# 重启Nginx
sudo systemctl restart nginx
```

### 测试服务
```bash
# 自动获取服务器IP并测试
SERVER_IP=$(curl -s ifconfig.me)
curl http://$SERVER_IP/
curl http://$SERVER_IP/api/
curl http://$SERVER_IP/docs
```

## 🌐 支持的部署环境

- **操作系统**: Ubuntu 18.04+, Debian 10+
- **内存要求**: 4GB+（使用轻量级Tesseract OCR）
- **网络要求**: 需要访问外网（用于安装依赖）
- **权限要求**: 普通用户 + sudo权限

## 🔒 安全特性

### 1. 无硬编码敏感信息
- ✅ 所有IP地址动态检测
- ✅ 端口可配置
- ✅ 路径可自定义

### 2. 自动环境检测
- ✅ 自动检测服务器IP
- ✅ 智能选择最佳IP地址
- ✅ 配置文件优先级支持

### 3. 安全最佳实践
- ✅ 不使用root用户运行
- ✅ 配置文件分离
- ✅ 临时文件自动清理
- ✅ 服务隔离运行

## 📁 文件结构

```
ocrProject/
├── quick_deploy.sh          # 快速部署脚本
├── deploy_full_project.sh   # 完整部署脚本
├── deploy_frontend.sh       # 前端部署脚本
├── setup_nginx.sh          # Nginx配置脚本
├── nginx-ocr.conf          # Nginx配置模板
├── config.env              # 配置文件
├── DEPLOYMENT_GUIDE.md     # 部署指南
└── src/
    ├── BackendFastApi/
    │   └── ocrProjectBackend/
    │       ├── install_tesseract.sh
    │       ├── requirements.txt
    │       └── ...
    └── ...
```

## 🆘 常见问题

### Q: 如何在云服务器上部署？
A: 直接运行 `./quick_deploy.sh`，脚本会自动检测云服务器的公网IP。

### Q: 如何部署到内网服务器？
A: 设置环境变量：`export SERVER_IP=内网IP`，然后运行部署脚本。

### Q: 如何更改端口？
A: 修改 `config.env` 文件中的 `NGINX_PORT` 和 `BACKEND_PORT`。

### Q: 如何在不同用户下部署？
A: 修改 `config.env` 中的 `PROJECT_DIR` 为对应用户的目录。

## 🔄 更新部署

如果需要更新已部署的项目：

```bash
# 1. 停止服务
pm2 stop ocr-backend

# 2. 更新代码
git pull

# 3. 重新部署
./quick_deploy.sh

# 4. 重启服务
pm2 start ocr-backend
```

## 📞 技术支持

如果遇到部署问题，请检查：

1. **网络连接**: 确保服务器可以访问外网
2. **权限问题**: 确保用户有sudo权限
3. **端口冲突**: 检查80和8000端口是否被占用
4. **内存不足**: 确保服务器有足够内存（4GB+）

## 🎯 部署完成后

部署成功后，您可以：

1. **访问应用**: http://您的服务器IP
2. **查看API文档**: http://您的服务器IP/docs
3. **健康检查**: http://您的服务器IP/health
4. **管理服务**: 使用PM2命令管理后端服务

---

**�� 恭喜！您的OCR项目已成功部署！** 