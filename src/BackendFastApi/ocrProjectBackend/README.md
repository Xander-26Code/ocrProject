# FastAPI OCR 项目

这是一个基于 FastAPI 的 OCR（光学字符识别）项目，可以将图片中的文字识别出来，并支持输出为文本、Word 文档或 PDF 格式。

## 功能特性

- 🖼️ 支持多种图片格式的 OCR 识别
- 🌍 支持多语言识别（基于 Tesseract）
- 📝 支持输出为纯文本格式
- 📄 支持输出为 Word 文档 (.docx)
- 📋 支持输出为 PDF 文档 (.pdf)
- 🚀 基于 FastAPI 的高性能 API

## 安装依赖

1. 安装 Python 依赖：
```bash
pip install -r requirements.txt
```

2. 安装 Tesseract OCR：
```bash
# macOS
brew install tesseract

# Ubuntu/Debian
sudo apt-get install tesseract-ocr

# Windows
# 下载并安装 Tesseract: https://github.com/UB-Mannheim/tesseract/wiki
```

## 运行项目

```bash
uvicorn main:app --reload
```

服务将在 `http://127.0.0.1:8000` 启动。

## API 使用说明

### OCR 识别接口

**端点：** `POST /ocr/`

**参数：**
- `file`: 图片文件（必需）
- `lang`: 语言代码（可选，默认为 'eng'）
- `output_format`: 输出格式（可选，默认为 'text'）
  - `text`: 返回 JSON 格式的文本
  - `word`: 返回 Word 文档文件
  - `pdf`: 返回 PDF 文档文件

**示例请求：**

1. 输出为文本：
```bash
curl -X POST "http://127.0.0.1:8000/ocr/" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@your_image.jpg" \
  -F "lang=eng" \
  -F "output_format=text"
```

2. 输出为 Word 文档：
```bash
curl -X POST "http://127.0.0.1:8000/ocr/" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@your_image.jpg" \
  -F "lang=eng" \
  -F "output_format=word"
```

3. 输出为 PDF 文档：
```bash
curl -X POST "http://127.0.0.1:8000/ocr/" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@your_image.jpg" \
  -F "lang=eng" \
  -F "output_format=pdf"
```

### 其他接口

- `GET /`: 返回欢迎信息
- `GET /hello/{name}`: 返回个性化问候

## 支持的语言

项目支持 Tesseract 支持的所有语言，包括但不限于：
- `eng`: 英语
- `chi_sim`: 简体中文
- `chi_tra`: 繁体中文
- `jpn`: 日语
- `kor`: 韩语
- `fra`: 法语
- `deu`: 德语
- `spa`: 西班牙语

## 文件结构

```
FastAPIProject/
├── main.py              # FastAPI 主应用文件
├── transform.py         # OCR 转换功能模块
├── requirements.txt     # Python 依赖包
├── test_main.http      # API 测试文件
└── README.md           # 项目说明文档
```

## 注意事项

1. 确保已正确安装 Tesseract OCR 引擎
2. 图片质量会影响 OCR 识别准确率
3. 生成的临时文件会在处理完成后自动清理
4. 支持常见的图片格式：JPG、PNG、BMP、TIFF 等

## 开发说明

- 使用 `python-docx` 库生成 Word 文档
- 使用 `reportlab` 库生成 PDF 文档
- 使用 `pytesseract` 进行 OCR 识别
- 使用 `Pillow` 处理图片文件 