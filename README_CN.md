# OCR Web 应用程序

一个现代化的基于Web的光学字符识别（OCR）系统，支持从图片中提取文字并输出多种格式的文档。

## 📖 项目简介

这是一个基于Web的智能文字识别（OCR）系统，支持从图片中提取文字并生成多种格式的文档。项目采用现代化的前后端分离架构，为用户提供简洁易用的文字识别服务。这个项目对初学者友好，适合像我这样的初学者开始第一个Web开发项目。

## ✨ 主要特性

- 🔍 **多语言识别**: 支持100多种语言，包括中文、英文、日文、韩文等
- 🎯 **自动语言检测**: 智能识别图片中的文字语言
- 📄 **多格式输出**: 支持纯文本、Word文档、PDF文档三种输出格式
- 🚀 **轻量级部署**: 基于Tesseract OCR，内存占用仅300-500MB
- 💾 **高效处理**: 适合低内存服务器(2GB, 4GB等)，支持50MB以下图片文件
- 🌐 **现代化UI**: 使用Vue3和Ant Design Vue构建美观界面

## 🛠 技术栈

- **前端**: Vue 3 + Vite + Ant Design Vue
- **后端**: FastAPI + Python
- **OCR引擎**: Pytesseract(这是Google Tesseract-OCR引擎的Python包装器)
- **Web部署**: Nginx
- **进程管理**: PM2
- **文档生成**: python-docx + reportlab
- **语言检测**: langdetect

## 🚀 快速开始

### 环境要求
- Node.js 16+ 
- Python 3.8+(推荐3.12/3.13)
- Ubuntu/Debian系统
- 无需GPU配置

### 超级简单部署
```bash
# 克隆项目
git clone https://github.com/Xander-26Code/ocrProject.git
cd ocrProject

# 完整项目部署
chmod +x deploy_full_project.sh
./deploy_full_project.sh
```

### 分步部署
```bash
# 1. 部署后端
cd src/BackendFastApi/ocrProjectBackend
chmod +x install_tesseract.sh
./install_tesseract.sh

# 2. 部署前端
cd ../../../
chmod +x deploy_frontend.sh
./deploy_frontend.sh

# 3. 配置Nginx
chmod +x setup_nginx.sh
./setup_nginx.sh
```

### 手动部署
```bash
# 1. 安装基础包
sudo apt update
sudo apt upgrade -y

sudo apt install -y curl wget git vim

sudo apt install -y python3 python3-pip python3-venv python3-dev

sudo apt install -y build-essential

sudo apt install -y nginx

sudo apt install -y tesseract-ocr 
sudo apt install -y tesseract-ocr-chi-sim tesseract-ocr-chi-tra
sudo apt install -y tesseract-ocr-jpn tesseract-ocr-kor
sudo apt install -y tesseract-ocr-fra tesseract-ocr-deu
sudo apt install -y tesseract-ocr-spa tesseract-ocr-ita
sudo apt install -y tesseract-ocr-por tesseract-ocr-rus
sudo apt install -y tesseract-ocr-ara

# 2. 启动后端
cd ~/ocrProject/src/BackendFastApi/ocrProjectBackend
# 设置虚拟环境
python3 -m venv venv
# 激活虚拟环境
source venv/bin/activate
# 安装依赖包
pip install --upgrade pip
pip install -r requirements.txt

# 检查包安装
python -c "import fastapi; print('FastAPI OK')"
python -c "import pytesseract; print('Tesseract OK')"
python -c "import PIL; print('Pillow OK')"
# 启动后端服务
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# 3. 启动前端
cd ./src
# 设置环境变量
cat > .env.production << EOF
VITE_API_URL=/api
VITE_APP_TITLE=OCR Pro
VITE_APP_DESCRIPTION=智能OCR项目
NODE_ENV=production
EOF
# 设置npm
npm install
npm run build

# 4. 配置Nginx
# 步骤 4.1: 创建Nginx配置文件
sudo nano /etc/nginx/sites-available/ocr-project

# 添加以下配置内容到文件中:
```nginx
# OCR项目Nginx配置
server {
    listen 80;
    server_name your-server-ip;  # 替换为您的实际服务器IP
    
    # 安全头部
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # 前端静态文件
    location / {
        root /home/admin/ocrProject/dist;  # 根据实际情况调整路径
        index index.html index.htm;
        try_files $uri $uri/ /index.html;
        
        # 缓存静态资源
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            access_log off;
        }
        
        # HTML文件 - 不缓存
        location ~* \.html$ {
            expires -1;
            add_header Cache-Control "no-cache, no-store, must-revalidate";
        }
    }

    # 后端API代理
    location /api/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # 文件上传大小限制
        client_max_body_size 50M;
        
        # 超时设置（OCR处理可能需要较长时间）
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        
        # 缓冲区设置
        proxy_buffering off;
        proxy_request_buffering off;
    }

    # API文档
    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # API OpenAPI规范
    location /openapi.json {
        proxy_pass http://127.0.0.1:8000/openapi.json;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # 健康检查
    location /health {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host $host;
        access_log off;
    }

    # 防止访问隐藏文件
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # 防止访问备份文件
    location ~ ~$ {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;

    # 日志配置
    access_log /var/log/nginx/ocr_access.log;
    error_log /var/log/nginx/ocr_error.log;
}
```

# 步骤 4.2: 启用站点
sudo ln -s /etc/nginx/sites-available/ocr-project /etc/nginx/sites-enabled/

# 步骤 4.3: 移除默认站点
sudo rm -f /etc/nginx/sites-enabled/default

# 步骤 4.4: 测试配置
sudo nginx -t

# 步骤 4.5: 重启Nginx
sudo systemctl restart nginx

# 步骤 4.6: 设置Nginx开机启动
sudo systemctl enable nginx

# 5. 安装和配置PM2进程管理
sudo npm install -g pm2

# 6. 创建PM2配置文件
cd ~/ocrProject
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'ocr-backend',
    script: '/home/admin/ocrProject/src/BackendFastApi/ocrProjectBackend/venv/bin/uvicorn',
    args: 'main:app --host 127.0.0.1 --port 8000',
    cwd: '/home/admin/ocrProject/src/BackendFastApi/ocrProjectBackend',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '512M',
    env: {
      NODE_ENV: 'production'
    },
    error_file: '/home/admin/ocrProject/logs/err.log',
    out_file: '/home/admin/ocrProject/logs/out.log',
    log_file: '/home/admin/ocrProject/logs/combined.log',
    time: true
  }]
};
EOF

# 7. 创建日志目录并启动服务
mkdir -p ~/ocrProject/logs
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

## 📁 项目结构

```
ocrProject/
├── src/
│   ├── components/          # Vue组件
│   ├── services/           # API服务
│   ├── stores/             # 状态管理
│   └── BackendFastApi/     # 后端代码
│       └── ocrProjectBackend/
│           ├── main.py     # FastAPI主程序
│           ├── transform.py # OCR处理逻辑
│           └── requirements.txt
├── public/                 # 静态资源
├── deploy_full_project.sh  # 完整部署脚本
├── deploy_frontend.sh      # 前端部署脚本
├── setup_nginx.sh          # Nginx配置脚本
└── nginx-ocr.conf         # Nginx配置文件
```

## 🎮 使用方法

1. 访问 `http://your-server-ip` 打开Web界面
2. 点击上传按钮选择图片文件
3. 选择识别语言（或使用自动检测）
4. 选择输出格式（文本/Word/PDF）
5. 点击"开始识别"按钮
6. 等待处理完成并下载结果

## 🌍 支持的语言

- 自动检测 (auto)
- 简体中文 (chi_sim)
- 繁体中文 (chi_tra)
- English (eng)
- 日本語 (jpn)
- 한국어 (kor)
- Français (fra)
- Deutsch (deu)
- Español (spa)
- Italiano (ita)
- Português (por)
- Русский (rus)
- العربية (ara)

## 🔧 配置说明

- **服务器地址**: 配置在 `nginx-ocr.conf` 中
- **API地址**: 生产环境使用 `/api` 相对路径
- **文件上传限制**: 最大50MB
- **内存限制**: 后端服务最大512MB内存

## 📝 API文档

部署完成后可访问：
- **API文档**: `http://your-server-ip/docs`
- **健康检查**: `http://your-server-ip/api/`

## 🐛 常见问题

1. **Tesseract未安装**: 运行 `./install_tesseract.sh` 安装
2. **端口冲突**: 检查8000端口是否被占用
3. **权限问题**: 确保脚本有执行权限 `chmod +x script.sh`
4. **内存不足**: 建议至少4GB内存，或调整PM2配置

## 📊 性能优化

- 使用Nginx进行静态文件缓存
- 启用Gzip压缩减少传输大小
- PM2进程管理自动重启和负载均衡
- 图片预处理优化识别准确率

## 🧪 测试

### 基础API测试
```bash
# 测试前端
curl http://your-server-ip/

# 测试API
curl http://your-server-ip/api/

# 测试API文档
curl http://your-server-ip/docs
```

### OCR功能测试
```bash
# 上传并测试OCR功能
curl -X POST -F "file=@test.jpg" -F "lang=eng" http://your-server-ip/api/ocr/
```

## 🚀 部署架构

```
[用户] → [Nginx:80] → [前端:dist文件] 
                   → [/api/*] → [后端:8000]
```

## 📊 系统要求

- **最低配置**: 2GB内存，1个CPU核心
- **推荐配置**: 4GB内存，2个CPU核心
- **存储空间**: 2GB可用空间
- **网络带宽**: 100Mbps带宽

## 🔒 安全特性

- 文件类型验证
- 文件大小限制
- 输入数据清理
- 访问频率限制
- CORS配置


## 📄 许可证

本项目基于MIT许可证开源。

## 📧 联系方式

如有问题或建议，请创建Issue或联系我。
本新手小白极其需要各位大佬开发者们都意见，无论是对项目代码的批评和项目想法的指正都可以告诉我。

## 🌟 致谢

- [Tesseract OCR](https://github.com/tesseract-ocr/tesseract) 提供OCR引擎
- [Vue.js](https://vuejs.org/) 提供前端框架
- [FastAPI](https://fastapi.tiangolo.com/) 提供后端框架
- [Ant Design Vue](https://antdv.com/) 提供UI组件

---

## 🌐 多语言文档

- [中文文档](README_CN.md)
- [英文文档](README.md)

---

## 开发指南

### 自定义配置

参考 [Vite配置文档](https://vitejs.dev/config/)。

### 项目安装

```sh
npm install
```

### 开发环境编译和热重载

```sh
npm run dev
```

### 生产环境编译和压缩

```sh
npm run build
```

### 后端开发

```sh
# 进入后端目录
cd src/BackendFastApi/ocrProjectBackend

# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt

# 运行开发服务器
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 环境变量

在项目根目录创建 `.env` 文件：
```
VITE_API_URL=http://localhost:8000
VITE_APP_TITLE=OCR Web App
```

### Docker部署（可选）

```bash
# 构建Docker镜像
docker build -t ocr-web-app .

# 运行容器
docker run -d -p 80:80 --name ocr-app ocr-web-app
```