from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.responses import JSONResponse, FileResponse
from PIL import Image
import io
import transform
import os
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# 文件大小限制 (50MB)
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB in bytes

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

@app.get("/")
async def root():
    return {"message": "Hello World"}

@app.post("/ocr/auto/")
async def ocr_auto_detect(
    file: UploadFile = File(...),
    output_format: str = Form('text')
):
    """
    自动检测图片中文字的语言并进行OCR识别
    :param file: 上传的图片文件
    :param output_format: 输出格式，可选值：'text', 'word', 'pdf'
    """
    try:
        contents = await validate_file_size(file)
        image = Image.open(io.BytesIO(contents))

        # 保存临时图片文件
        temp_path = f"temp_{file.filename}"
        image.save(temp_path)

        # 自动检测语言并进行OCR识别
        text, detected_lang = transform.auto_detect_and_ocr(temp_path)

        if text is None:
            return JSONResponse(content={"error": "OCR识别失败"}, status_code=500)

        # 根据输出格式处理
        if output_format == 'text':
            # 清理临时文件
            if os.path.exists(temp_path):
                os.remove(temp_path)
            return JSONResponse(content={
                "text": text,
                "detected_language": detected_lang,
                "language_name": transform.get_language_name(detected_lang)
            })

        elif output_format == 'word':
            # 生成Word文档
            base_name = file.filename.rsplit('.', 1)[0] if file.filename and '.' in file.filename else 'document'
            word_filename = f"ocr_result_{base_name}.docx"
            word_path = f"temp_{word_filename}"

            if transform.text_to_word(text, word_path):
                # 清理临时图片文件
                if os.path.exists(temp_path):
                    os.remove(temp_path)

                # 返回Word文档文件
                return FileResponse(
                    path=word_path,
                    filename=word_filename,
                    media_type='application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                )
            else:
                return JSONResponse(content={"error": "生成Word文档失败"}, status_code=500)

        elif output_format == 'pdf':
            # 生成PDF文档
            base_name = file.filename.rsplit('.', 1)[0] if file.filename and '.' in file.filename else 'document'
            pdf_filename = f"ocr_result_{base_name}.pdf"
            pdf_path = f"temp_{pdf_filename}"

            if transform.text_to_pdf(text, pdf_path):
                # 清理临时图片文件
                if os.path.exists(temp_path):
                    os.remove(temp_path)

                # 返回PDF文档文件
                return FileResponse(
                    path=pdf_path,
                    filename=pdf_filename,
                    media_type='application/pdf'
                )
            else:
                return JSONResponse(content={"error": "生成PDF文档失败"}, status_code=500)

        else:
            return JSONResponse(content={"error": "不支持的输出格式"}, status_code=400)

    except Exception as e:
        # 清理临时文件
        if 'temp_path' in locals() and os.path.exists(temp_path):
            os.remove(temp_path)
        return JSONResponse(content={"error": f"处理失败: {str(e)}"}, status_code=500)

@app.post("/ocr/")
async def ocr_trans(
    file: UploadFile = File(...), 
    lang: str = Form('eng'),
    output_format: str = Form('text')
):
    """
    OCR识别图片中的文字，支持输出为文本、Word文档或PDF
    :param file: 上传的图片文件
    :param lang: 语言代码，默认为'eng'，使用'auto'进行自动检测
    :param output_format: 输出格式，可选值：'text', 'word', 'pdf'
    """
    try:
        # 验证文件大小
        contents = await validate_file_size(file)
        image = Image.open(io.BytesIO(contents))
        
        # 保存临时图片文件
        temp_path = f"temp_{file.filename}"
        image.save(temp_path)
        
        # OCR识别文字
        if lang == 'auto':
            text, detected_lang = transform.auto_detect_and_ocr(temp_path)
            used_lang = detected_lang
        else:
            text = transform.image_to_text(temp_path, lang=lang)
            used_lang = lang

        if text is None:
            return JSONResponse(content={"error": "OCR识别失败"}, status_code=500)
        
        # 根据输出格式处理
        if output_format == 'text':
            # 清理临时文件
            if os.path.exists(temp_path):
                os.remove(temp_path)

            response_data = {"text": text}
            if lang == 'auto':
                response_data["detected_language"] = used_lang
                response_data["language_name"] = transform.get_language_name(used_lang)

            return JSONResponse(content=response_data)

        elif output_format == 'word':
            # 生成Word文档
            base_name = file.filename.rsplit('.', 1)[0] if file.filename and '.' in file.filename else 'document'
            word_filename = f"ocr_result_{base_name}.docx"
            word_path = f"temp_{word_filename}"
            
            if transform.text_to_word(text, word_path):
                # 清理临时图片文件
                if os.path.exists(temp_path):
                    os.remove(temp_path)
                
                # 返回Word文档文件
                return FileResponse(
                    path=word_path,
                    filename=word_filename,
                    media_type='application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                )
            else:
                return JSONResponse(content={"error": "生成Word文档失败"}, status_code=500)
        
        elif output_format == 'pdf':
            # 生成PDF文档
            base_name = file.filename.rsplit('.', 1)[0] if file.filename and '.' in file.filename else 'document'
            pdf_filename = f"ocr_result_{base_name}.pdf"
            pdf_path = f"temp_{pdf_filename}"
            
            if transform.text_to_pdf(text, pdf_path):
                # 清理临时图片文件
                if os.path.exists(temp_path):
                    os.remove(temp_path)
                
                # 返回PDF文档文件
                return FileResponse(
                    path=pdf_path,
                    filename=pdf_filename,
                    media_type='application/pdf'
                )
            else:
                return JSONResponse(content={"error": "生成PDF文档失败"}, status_code=500)
        
        else:
            return JSONResponse(content={"error": "不支持的输出格式"}, status_code=400)

    except Exception as e:
        # 清理临时文件
        if 'temp_path' in locals() and os.path.exists(temp_path):
            os.remove(temp_path)
        return JSONResponse(content={"error": f"处理失败: {str(e)}"}, status_code=500)
