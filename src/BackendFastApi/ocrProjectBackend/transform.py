from PIL import Image
from langdetect import detect, DetectorFactory
from langdetect.lang_detect_exception import LangDetectException
from docx import Document
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import os
import time
import logging

# 导入PaddleOCR
try:
    from paddleocr import PaddleOCR
    PADDLE_OCR_AVAILABLE = True
    print("PaddleOCR imported successfully")
except ImportError:
    PADDLE_OCR_AVAILABLE = False
    print("PaddleOCR not available, please install: pip install paddleocr")

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 设置语言检测的随机种子，确保结果一致性
DetectorFactory.seed = 0

# 语言映射表：langdetect库的语言代码 -> PaddleOCR语言代码
LANG_MAP = {
    'zh-cn': 'ch',       # 简体中文
    'zh': 'ch',          # 中文（默认简体）
    'en': 'en',          # 英语
    'ja': 'japan',       # 日语
    'ko': 'korean',      # 韩语
    'fr': 'french',      # 法语
    'de': 'german',      # 德语
    'es': 'spanish',     # 西班牙语
    'it': 'italian',     # 意大利语
    'pt': 'portuguese',  # 葡萄牙语
    'ru': 'russian',     # 俄语
    'ar': 'arabic',      # 阿拉伯语
    'th': 'thai',        # 泰语
    'vi': 'vietnamese',  # 越南语
}

# Tesseract到PaddleOCR的语言映射（保持向后兼容）
TESSERACT_TO_PADDLE = {
    'chi_sim': 'ch',
    'chi_tra': 'chinese_cht',
    'eng': 'en',
    'jpn': 'japan',
    'kor': 'korean',
    'fra': 'french',
    'deu': 'german',
    'spa': 'spanish',
    'ita': 'italian',
    'por': 'portuguese',
    'rus': 'russian',
    'ara': 'arabic',
    'tha': 'thai',
    'vie': 'vietnamese',
}

# 语言名称映射表
LANG_NAMES = {
    'ch': '简体中文',
    'chinese_cht': '繁体中文',
    'en': '英语',
    'japan': '日语',
    'korean': '韩语',
    'french': '法语',
    'german': '德语',
    'spanish': '西班牙语',
    'italian': '意大利语',
    'portuguese': '葡萄牙语',
    'russian': '俄语',
    'arabic': '阿拉伯语',
    'thai': '泰语',
    'vietnamese': '越南语',
    # 保持向后兼容
    'chi_sim': '简体中文',
    'chi_tra': '繁体中文',
    'eng': '英语',
    'jpn': '日语',
    'kor': '韩语',
    'fra': '法语',
    'deu': '德语',
    'spa': '西班牙语',
    'ita': '意大利语',
    'por': '葡萄牙语',
    'rus': '俄语',
    'ara': '阿拉伯语',
    'tha': '泰语',
    'vie': '越南语',
}

# 全局PaddleOCR实例缓存
paddle_ocr_instances = {}

def get_paddle_lang(lang_code):
    """
    转换语言代码为PaddleOCR格式
    """
    # 如果是Tesseract格式，先转换
    if lang_code in TESSERACT_TO_PADDLE:
        return TESSERACT_TO_PADDLE[lang_code]
    
    # 如果已经是PaddleOCR格式，直接返回
    if lang_code in ['ch', 'en', 'japan', 'korean', 'french', 'german', 'spanish', 'russian', 'arabic']:
        return lang_code
    
    # 默认返回中文
    return 'ch'

def get_paddle_ocr_instance(lang='ch'):
    """
    获取PaddleOCR实例，使用缓存避免重复初始化
    """
    if not PADDLE_OCR_AVAILABLE:
        raise Exception("PaddleOCR not available")
    
    paddle_lang = get_paddle_lang(lang)
    
    # 如果实例已存在且语言匹配，直接返回
    if paddle_lang in paddle_ocr_instances:
        return paddle_ocr_instances[paddle_lang]
    
    try:
        logger.info(f"Initializing PaddleOCR with language: {paddle_lang}")
        
        # 创建PaddleOCR实例
        ocr = PaddleOCR(
            use_angle_cls=True,    # 使用角度分类器
            lang=paddle_lang,      # 语言
            use_gpu=False,         # 不使用GPU（兼容性更好）
            show_log=False,        # 不显示详细日志
            drop_score=0.5,        # 置信度阈值
        )
        
        # 缓存实例
        paddle_ocr_instances[paddle_lang] = ocr
        logger.info(f"PaddleOCR initialized successfully for {paddle_lang}")
        
        return ocr
        
    except Exception as e:
        logger.error(f"Failed to initialize PaddleOCR: {e}")
        raise e

def extract_text_with_paddle(image_path, lang='ch'):
    """
    使用PaddleOCR提取文本
    """
    try:
        start_time = time.time()
        
        # 获取OCR实例
        ocr = get_paddle_ocr_instance(lang)
        
        # 执行OCR识别
        result = ocr.ocr(image_path, cls=True)
        
        # 提取文本
        text_lines = []
        if result and result[0]:
            for line in result[0]:
                if len(line) >= 2 and len(line[1]) >= 2:
                    # line[1][0] 是识别的文本，line[1][1] 是置信度
                    confidence = line[1][1]
                    text = line[1][0]
                    
                    # 只保留置信度较高的文本
                    if confidence > 0.5:
                        text_lines.append(text)
        
        extracted_text = '\n'.join(text_lines)
        processing_time = time.time() - start_time
        
        logger.info(f"PaddleOCR processing time: {processing_time:.2f}s, extracted {len(text_lines)} lines")
        return extracted_text, processing_time
        
    except Exception as e:
        logger.error(f"PaddleOCR extraction failed: {e}")
        return None, 0.0

def detect_language(text):
    """
    检测文本的语言
    :param text: 要检测的文本
    :return: 检测到的语言代码（PaddleOCR格式）
    """
    if not text or len(text.strip()) < 3:
        return 'ch'  # 默认返回中文

    try:
        # 使用langdetect检测语言
        detected_lang = detect(text)
        print(f"检测到的语言: {detected_lang}")

        # 转换为PaddleOCR语言代码
        paddle_lang = LANG_MAP.get(detected_lang, 'ch')
        print(f"转换为PaddleOCR语言代码: {paddle_lang}")

        return paddle_lang
    except LangDetectException:
        print("语言检测失败，使用默认语言: ch")
        return 'ch'

def auto_detect_and_ocr(image_path):
    """
    自动检测图片中的语言并进行OCR识别
    :param image_path: 图片路径
    :return: tuple (识别的文本, 检测到的语言代码)
    """
    try:
        # 首先用中文进行初步OCR识别，获取文本样本用于语言检测
        initial_text, _ = extract_text_with_paddle(image_path, 'ch')

        if not initial_text or not initial_text.strip():
            # 如果中文识别不出内容，尝试英语
            initial_text, _ = extract_text_with_paddle(image_path, 'en')

        if not initial_text or not initial_text.strip():
            logger.warning("No text detected in initial OCR")
            return None, None

        print(f"初步OCR结果: {initial_text[:100]}...")

        # 检测语言
        detected_lang = detect_language(initial_text)

        # 如果检测到的语言与初始使用的不同，重新进行OCR
        if detected_lang not in ['ch', 'en']:
            print(f"重新使用检测到的语言进行OCR: {detected_lang}")
            final_text, _ = extract_text_with_paddle(image_path, detected_lang)
        else:
            final_text = initial_text

        return final_text, detected_lang

    except Exception as e:
        print(f"自动语言检测OCR失败: {str(e)}")
        return None, None

def image_to_text(image_path, lang=None):
    """
    将图片转换为文本，支持自动语言检测
    :param image_path: 图片路径
    :param lang: 指定语言代码，如果为None则自动检测
    :return: 识别的文本
    """
    try:
        if lang is None or lang == 'auto':
            # 自动检测语言
            text, detected_lang = auto_detect_and_ocr(image_path)
            print(f"自动检测结果 - 语言: {detected_lang}, 文本长度: {len(text) if text else 0}")
            return text
        else:
            # 使用指定语言
            paddle_lang = get_paddle_lang(lang)
            text, processing_time = extract_text_with_paddle(image_path, paddle_lang)
            print(f"指定语言OCR结果 - 语言: {paddle_lang}, 文本长度: {len(text) if text else 0}")
            return text

    except Exception as e:
        print(f"图片文字识别失败: {str(e)}")
        return None

def text_to_word(text, output_path):
    """
    将文本保存为Word文档
    :param text: 要保存的文本
    :param output_path: 输出文件路径
    :return: 是否成功
    """
    try:
        doc = Document()
        doc.add_heading('OCR识别结果', 0)
        doc.add_paragraph(text)
        doc.save(output_path)
        return True
    except Exception as e:
        print(f"生成Word文档失败: {str(e)}")
        return False

def text_to_pdf(text, output_path):
    """
    将文本保存为PDF文档
    :param text: 要保存的文本
    :param output_path: 输出文件路径
    :return: 是否成功
    """
    try:
        c = canvas.Canvas(output_path, pagesize=A4)
        width, height = A4
        
        # 设置字体（支持中文）
        try:
            # 尝试注册中文字体
            font_path = "/System/Library/Fonts/PingFang.ttc"  # macOS系统字体
            if os.path.exists(font_path):
                pdfmetrics.registerFont(TTFont('PingFang', font_path))
                c.setFont('PingFang', 12)
            else:
                c.setFont('Helvetica', 12)
        except:
            c.setFont('Helvetica', 12)

        # 添加标题
        c.setFont('Helvetica-Bold', 16)
        c.drawString(50, height - 50, 'OCR Recognition Result')

        # 添加文本内容
        c.setFont('PingFang' if os.path.exists("/System/Library/Fonts/PingFang.ttc") else 'Helvetica', 12)

        # 处理文本换行
        lines = text.split('\n')
        y_position = height - 100
        line_height = 20

        for line in lines:
            if y_position < 50:  # 如果页面空间不够，创建新页面
                c.showPage()
                y_position = height - 50
            
            # 处理长行的换行
            if len(line) > 80:
                words = line.split(' ')
                current_line = ''
                for word in words:
                    if len(current_line + word) < 80:
                        current_line += word + ' '
                    else:
                        c.drawString(50, y_position, current_line.strip())
                        y_position -= line_height
                        current_line = word + ' '
                        if y_position < 50:
                            c.showPage()
                            y_position = height - 50
                if current_line:
                    c.drawString(50, y_position, current_line.strip())
                    y_position -= line_height
            else:
                c.drawString(50, y_position, line)
                y_position -= line_height
        
        c.save()
        return True
    except Exception as e:
        print(f"生成PDF文档失败: {str(e)}")
        return False

def get_language_name(lang_code):
    """
    获取语言代码对应的中文名称
    :param lang_code: 语言代码
    :return: 语言的中文名称
    """
    return LANG_NAMES.get(lang_code, '未知语言')
