// API配置和请求函数
const API_BASE_URL = import.meta.env.PROD ? '' : 'http://localhost:3000'

class ApiService {
  constructor() {
    this.baseURL = API_BASE_URL
    console.log('API Base URL:', this.baseURL) // 调试信息
  }

  // 健康检查
  async healthCheck() {
    try {
      const response = await fetch(`${this.baseURL}/api/`)
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      return await response.json()
    } catch (error) {
      console.error('Health check failed:', error)
      throw error
    }
  }
}

// 导出服务实例
export const apiService = new ApiService()

// OCR相关API函数
export async function ocrImage(file, lang = 'eng', outputFormat = 'text') {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('lang', lang);
  formData.append('output_format', outputFormat);

  const response = await fetch(`${API_BASE_URL}/api/ocr/`, {
    method: 'POST',
    body: formData,
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error || `Request failed: ${response.status}`);
  }

  if (outputFormat === 'word' || outputFormat === 'pdf') {
    const blob = await response.blob();
    return blob;
  } else {
    return response.json();
  }
}

export async function ocrAutoDetect(file, outputFormat = 'text') {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('output_format', outputFormat);

  const response = await fetch(`${API_BASE_URL}/api/ocr/auto/`, {
    method: 'POST',
    body: formData,
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error || `Request failed: ${response.status}`);
  }

  if (outputFormat === 'word' || outputFormat === 'pdf') {
    const blob = await response.blob();
    return blob;
  } else {
    return response.json();
  }
}

// 文件下载辅助函数
export function downloadFile(blob, filename) {
  const url = window.URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.style.display = 'none';
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  window.URL.revokeObjectURL(url);
  document.body.removeChild(a);
}

// 获取支持的语言列表
export const SUPPORTED_LANGUAGES = {
  'auto': '自动检测',
  'eng': 'English',
  'chi_sim': '简体中文',
  'chi_tra': '繁体中文',
  'jpn': '日本語',
  'kor': '한국어',
  'fra': 'Français',
  'deu': 'Deutsch',
  'spa': 'Español',
  'ita': 'Italiano',
  'por': 'Português',
  'rus': 'Русский',
  'ara': 'العربية'
};

export const OUTPUT_FORMATS = {
  'text': '纯文本',
  'word': 'Word文档',
  'pdf': 'PDF文档'
};
