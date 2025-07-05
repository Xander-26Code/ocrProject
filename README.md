# OCR Web Application

A modern web-based Optical Character Recognition (OCR) system for extracting text from images with multi-language support and multiple output formats. 

## 📖 Project Overview

This is a web-based intelligent OCR system that extracts text from images and generates documents in multiple formats. The project adopts a modern frontend-backend separation architecture, providing users with a clean and easy-to-use text recognition service. This project is beginner-friendly, it is easy for beginners like me to start our first web development project.

## ✨ Key Features

- 🔍 **Multi-language Recognition**: Supports 100 languages including Chinese, English, Japanese, Korean, etc.
- 🎯 **Auto Language Detection**: Intelligently detects the language of text in images
- 📄 **Multiple Output Formats**: Supports plain text, Word documents, and PDF documents
- 🚀 **Lightweight Deployment**: Based on Tesseract OCR with only 300-500MB memory usage
- 💾 **Efficient Processing**: Suitable for low memory servers(2GB, 4GB .etc), supports image files up to 50MB
- 🌐 **Modern UI**: Built with Vue3 and Ant Design Vue for beautiful interface

## 🛠 Tech Stack

- **Frontend**: Vue 3 + Vite + Ant Design Vue
- **Backend**: FastAPI + Python
- **OCR Engine**: Pytesseract(This is a wrapper for Google’s Tesseract-OCR Engine.)
- **Web deployment**: Nginx
- **Process Management**: PM2
- **Document Generation**: python-docx + reportlab
- **Language Detection**: langdetect

## 🚀 Quick Start

### Prerequisites
- Node.js 16+ 
- Python 3.8+(recommand 3.12/3.13)
- Ubuntu/Debian system
- No requirement for gpu configuration

### Super easy Deployment
```bash
# Clone the project
git clone https://github.com/Xander-26Code/ocrProject.git
cd ocrProject

# Full project deployment
chmod +x deploy_full_project.sh
./deploy_full_project.sh
```

### Step-by-Step Deployment
```bash
# 1. Deploy backend
cd src/BackendFastApi/ocrProjectBackend
chmod +x install_tesseract.sh
./install_tesseract.sh

# 2. Deploy frontend
cd ../../../
chmod +x deploy_frontend.sh
./deploy_frontend.sh

# 3. Configure Nginx
chmod +x setup_nginx.sh
./setup_nginx.sh
```
### Normal Deployment
```bash
# 1. install basic packages
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
# 2. start Backend
cd ~/ocrProject/src/BackendFastApi/ocrProjectBackend
# set virture environment
python3 -m venv venv
# activate virture environment
source venv/bin/activate
# install packages
pip install --upgrade pip
pip install -r requirements.txt

# check packages
python -c "import fastapi; print('FastAPI OK')"
python -c "import pytesseract; print('Tesseract OK')"
python -c "import PIL; print('Pillow OK')"
#start backend session
uvicorn main:app --reload --host 0.0.0.0 --port 8000
# 3. Start Frontend
cd ./src
# set environment
cat > .env.production << EOF
VITE_API_URL=/api
VITE_APP_TITLE=OCR Pro
VITE_APP_DESCRIPTION=Intelligent ocr project
NODE_ENV=production
EOF
#set npm
npm install
npm run build
# 4. Configure Nginx
# Step 4.1: Create Nginx configuration file
sudo nano /etc/nginx/sites-available/ocr-project

# Add the following configuration to the file:
```nginx
# OCR Project Nginx Configuration
server {
    listen 80;
    server_name your-server-ip;  # Replace with your actual server IP
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Frontend static files
    location / {
        root /home/admin/ocrProject/dist;  # Adjust path as needed
        index index.html index.htm;
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            access_log off;
        }
        
        # HTML files - no cache
        location ~* \.html$ {
            expires -1;
            add_header Cache-Control "no-cache, no-store, must-revalidate";
        }
    }

    # Backend API proxy
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
        
        # File upload size limit
        client_max_body_size 50M;
        
        # Timeout settings (OCR processing may take longer)
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        
        # Buffer settings
        proxy_buffering off;
        proxy_request_buffering off;
    }

    # API documentation
    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # API OpenAPI specification
    location /openapi.json {
        proxy_pass http://127.0.0.1:8000/openapi.json;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check
    location /health {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host $host;
        access_log off;
    }

    # Prevent access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Prevent access to backup files
    location ~ ~$ {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Gzip compression
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

    # Log configuration
    access_log /var/log/nginx/ocr_access.log;
    error_log /var/log/nginx/ocr_error.log;
}
```

# Step 4.2: Enable the site
sudo ln -s /etc/nginx/sites-available/ocr-project /etc/nginx/sites-enabled/

# Step 4.3: Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Step 4.4: Test configuration
sudo nginx -t

# Step 4.5: Restart Nginx
sudo systemctl restart nginx

# Step 4.6: Enable Nginx to start on boot
sudo systemctl enable nginx

# 5. Install and configure PM2 for process management
sudo npm install -g pm2

# 6. Create PM2 configuration file
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

# 7. Create logs directory and start services
mkdir -p ~/ocrProject/logs
pm2 start ecosystem.config.js
pm2 save
pm2 startup


## 📁 Project Structure

```
ocrProject/
├── src/
│   ├── components/          # Vue components
│   ├── services/           # API services
│   ├── stores/             # State management
│   └── BackendFastApi/     # Backend code
│       └── ocrProjectBackend/
│           ├── main.py     # FastAPI main program
│           ├── transform.py # OCR processing logic
│           └── requirements.txt
├── public/                 # Static assets
├── deploy_full_project.sh  # Complete deployment script
├── deploy_frontend.sh      # Frontend deployment script
├── setup_nginx.sh          # Nginx configuration script
└── nginx-ocr.conf         # Nginx configuration file
```

## 🎮 How to Use

1. Visit `http://your-server-ip` to open the web interface
2. Click the upload button to select an image file
3. Choose recognition language (or use auto-detection)
4. Select output format (Text/Word/PDF)
5. Click "Start Recognition" button
6. Wait for processing to complete and download results

## 🌍 Supported Languages

- Auto Detection (auto)
- Simplified Chinese (chi_sim)
- Traditional Chinese (chi_tra)
- English (eng)
- Japanese (jpn)
- Korean (kor)
- French (fra)
- German (deu)
- Spanish (spa)
- Italian (ita)
- Portuguese (por)
- Russian (rus)
- Arabic (ara)

## 🔧 Configuration

- **Server Address**: Configured in `nginx-ocr.conf`
- **API Address**: Uses `/api` relative path in production
- **File Upload Limit**: Maximum 50MB
- **Memory Limit**: Backend service maximum 512MB memory

## 📝 API Documentation

After deployment, you can access:
- **API Documentation**: `http://your-server-ip/docs`
- **Health Check**: `http://your-server-ip/api/`

## 🐛 Troubleshooting

1. **Tesseract not installed**: Run `./install_tesseract.sh` to install
2. **Port conflict**: Check if port 8000 is occupied
3. **Permission issues**: Ensure scripts have execution permissions `chmod +x script.sh`
4. **Insufficient memory**: Recommend at least 4GB memory, or adjust PM2 configuration

## 📊 Performance Optimization

- Use Nginx for static file caching
- Enable Gzip compression to reduce transfer size
- PM2 process management for auto-restart and load balancing
- Image preprocessing to optimize recognition accuracy

## 🧪 Testing

### Basic API Testing
```bash
# Test frontend
curl http://your-server-ip/

# Test API
curl http://your-server-ip/api/

# Test API documentation
curl http://your-server-ip/docs
```

### OCR Testing
```bash
# Upload and test OCR functionality
curl -X POST -F "file=@test.jpg" -F "lang=eng" http://your-server-ip/api/ocr/
```

## 🚀 Deployment Architecture

```
[User] → [Nginx:80] → [Frontend:dist files] 
                   → [/api/*] → [Backend:8000]
```

## 📊 System Requirements

- **Minimum**: 2GB RAM, 1 CPU core
- **Recommended**: 4GB RAM, 2 CPU cores
- **Storage**: 2GB free space
- **Network**: 100Mbps bandwidth

## 🔒 Security Features

- File type validation
- File size limits
- Input sanitization
- Rate limiting
- CORS configuration

## 🤝 Contributing

1. Fork the project
2. Create a feature branch `git checkout -b feature/AmazingFeature`
3. Commit your changes `git commit -m 'Add some AmazingFeature'`
4. Push to the branch `git push origin feature/AmazingFeature`
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 📧 Contact

For questions or suggestions, please create an Issue or contact the maintainer.

## 🌟 Acknowledgments

- [Tesseract OCR](https://github.com/tesseract-ocr/tesseract) for the OCR engine
- [Vue.js](https://vuejs.org/) for the frontend framework
- [FastAPI](https://fastapi.tiangolo.com/) for the backend framework
- [Ant Design Vue](https://antdv.com/) for the UI components

---

## 🌐 Multi-language Documentation

- [中文文档](README_CN.md)
- [English Documentation](README.md)

---

## Development Guide

### Customize Configuration

See [Vite Configuration Reference](https://vitejs.dev/config/).

### Project Setup

```sh
npm install
```

### Compile and Hot-Reload for Development

```sh
npm run dev
```

### Compile and Minify for Production

```sh
npm run build
```

### Backend Development

```sh
# Navigate to backend directory
cd src/BackendFastApi/ocrProjectBackend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run development server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Environment Variables

Create `.env` file in the root directory:
```
VITE_API_URL=http://localhost:8000
VITE_APP_TITLE=OCR Web App
```

### Docker Deployment (Optional)

```bash
# Build Docker image
docker build -t ocr-web-app .

# Run container
docker run -d -p 80:80 --name ocr-app ocr-web-app
```
