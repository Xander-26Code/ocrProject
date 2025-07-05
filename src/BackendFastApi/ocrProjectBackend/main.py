from fastapi import FastAPI, File, UploadFile, Form, HTTPException, APIRouter
from fastapi.responses import JSONResponse, FileResponse
from PIL import Image
import io
import transform
import os
from fastapi.middleware.cors import CORSMiddleware
import logging
from transform import ocr_image, save_to_text, save_to_word, save_to_pdf, detect_language, get_tesseract_path, find_tesseract_path, get_installed_languages
import uuid
import time
from typing import Dict, Any, Optional

# 初始化FastAPI应用
app = FastAPI(
    title="OCR Web Service",
    description="A modern web-based OCR system with multi-language support.",
    version="1.1.0",
)

# 创建一个带/api前缀的路由器
api_router = APIRouter(prefix="/api")

# 文件大小限制 (50MB)
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB in bytes

# 配置CORS中间件
origins = [
    "http://localhost",
    "http://localhost:8080",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 定义临时文件目录
TEMP_DIR = "temp_files"
os.makedirs(TEMP_DIR, exist_ok=True)

# 智能查找Tesseract路径
try:
    tesseract_path = find_tesseract_path()
    if tesseract_path:
        get_tesseract_path(tesseract_path)
        logger.info(f"✅ Tesseract path configured: {tesseract_path}")
    else:
        logger.warning("⚠️ Tesseract command not found. Please install Tesseract or check your PATH.")
except Exception as e:
    logger.error(f"❌ Error finding Tesseract: {e}")

async def validate_file_size(file: UploadFile):
    """验证文件大小"""
    contents = await file.read()
    file_size = len(contents)
    
    if file_size > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=413,
            detail=f"文件过大。最大允许大小: {MAX_FILE_SIZE // (1024*1024)}MB，当前文件大小: {file_size // (1024*1024)}MB"
        )
    
    await file.seek(0)
    return contents

@api_router.get("/", tags=["General"])
async def read_root():
    """
    Root endpoint for health check.
    """
    return {"message": "Welcome to the OCR Web Service!"}

@api_router.get("/health", tags=["General"])
async def health_check():
    """
    Health check endpoint.
    """
    return JSONResponse(content={"status": "ok"})

@api_router.get("/config", tags=["General"])
async def get_config() -> Dict[str, Any]:
    """
    Get server configuration and capabilities.
    """
    return {
        "tesseract_version": get_tesseract_path(None) or "Not Found",
        "supported_languages": get_installed_languages(),
        "max_file_size_mb": 50
    }

@api_router.post("/ocr", tags=["OCR"])
async def perform_ocr(
    file: UploadFile = File(...), 
    lang: str = Form("eng"),
    output_format: str = Form("text")
) -> FileResponse | JSONResponse:
    """
    Perform OCR on an uploaded image.
    - **file**: Image file to process.
    - **lang**: Recognition language (e.g., 'eng', 'chi_sim').
    - **output_format**: 'text', 'word', or 'pdf'.
    """
    start_time = time.time()
    
    # 检查文件大小
    if file.size and file.size > 50 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="File size exceeds 50MB limit.")
        
    file_extension = os.path.splitext(file.filename)[1].lower()
    if file_extension not in ['.png', '.jpg', '.jpeg', '.bmp', '.tiff']:
        raise HTTPException(status_code=400, detail="Invalid file type. Please upload an image.")

    file_path = os.path.join(TEMP_DIR, f"{uuid.uuid4()}{file_extension}")
    
    try:
        with open(file_path, "wb") as buffer:
            buffer.write(await file.read())
        
        logger.info(f"Performing OCR with lang='{lang}' and format='{output_format}'")
        text_result = ocr_image(file_path, lang=lang)
        
        output_filename = f"{uuid.uuid4()}"
        
        if output_format == 'text':
            output_path = save_to_text(text_result, os.path.join(TEMP_DIR, f"{output_filename}.txt"))
            return JSONResponse(content={"text": text_result, "filename": os.path.basename(output_path)})
        
        elif output_format == 'word':
            output_path = save_to_word(text_result, os.path.join(TEMP_DIR, f"{output_filename}.docx"))
            return FileResponse(output_path, media_type='application/vnd.openxmlformats-officedocument.wordprocessingml.document', filename=f"{output_filename}.docx")
            
        elif output_format == 'pdf':
            output_path = save_to_pdf(text_result, os.path.join(TEMP_DIR, f"{output_filename}.pdf"))
            return FileResponse(output_path, media_type='application/pdf', filename=f"{output_filename}.pdf")
            
        else:
            raise HTTPException(status_code=400, detail="Invalid output format specified.")

    except Exception as e:
        logger.error(f"OCR processing failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))
        
    finally:
        if os.path.exists(file_path):
            os.remove(file_path)
        logger.info(f"Processing time: {time.time() - start_time:.2f}s")

@api_router.post("/ocr/auto", tags=["OCR"])
async def perform_ocr_auto_detect(
    file: UploadFile = File(...),
    output_format: str = Form("text")
) -> FileResponse | JSONResponse:
    """
    Perform OCR with automatic language detection.
    - **file**: Image file to process.
    - **output_format**: 'text', 'word', or 'pdf'.
    """
    start_time = time.time()
    
    if file.size and file.size > 50 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="File size exceeds 50MB limit.")
        
    file_extension = os.path.splitext(file.filename)[1].lower()
    if file_extension not in ['.png', '.jpg', '.jpeg', '.bmp', '.tiff']:
        raise HTTPException(status_code=400, detail="Invalid file type. Please upload an image.")

    file_path = os.path.join(TEMP_DIR, f"{uuid.uuid4()}{file_extension}")

    try:
        with open(file_path, "wb") as buffer:
            buffer.write(await file.read())
            
        # 初始识别以检测语言
        initial_text = ocr_image(file_path, lang='eng') # Use English for initial pass
        detected_lang_code, detected_lang_name = detect_language(initial_text)
        logger.info(f"Language detected: {detected_lang_name} ({detected_lang_code})")
        
        # 使用检测到的语言进行完整OCR
        final_text = ocr_image(file_path, lang=detected_lang_code)

        output_filename = f"{uuid.uuid4()}"

        if output_format == 'text':
            output_path = save_to_text(final_text, os.path.join(TEMP_DIR, f"{output_filename}.txt"))
            return JSONResponse(content={"text": final_text, "detected_lang": detected_lang_name, "filename": os.path.basename(output_path)})
            
        elif output_format == 'word':
            output_path = save_to_word(final_text, os.path.join(TEMP_DIR, f"{output_filename}.docx"))
            return FileResponse(output_path, media_type='application/vnd.openxmlformats-officedocument.wordprocessingml.document', filename=f"{output_filename}.docx")
            
        elif output_format == 'pdf':
            output_path = save_to_pdf(final_text, os.path.join(TEMP_DIR, f"{output_filename}.pdf"))
            return FileResponse(output_path, media_type='application/pdf', filename=f"{output_filename}.pdf")
            
        else:
            raise HTTPException(status_code=400, detail="Invalid output format specified.")

    except Exception as e:
        logger.error(f"Auto-detect OCR failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))
        
    finally:
        if os.path.exists(file_path):
            os.remove(file_path)
        logger.info(f"Processing time: {time.time() - start_time:.2f}s")

# 将路由器包含到主应用中
app.include_router(api_router)
