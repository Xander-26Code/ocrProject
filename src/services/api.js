// API配置和请求函数
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

class ApiService {
  constructor() {
    this.baseURL = API_BASE_URL
  }

  // 通用请求方法
  async request(endpoint, options = {}) {
    const url = `${this.baseURL}${endpoint}`
    const config = {
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
      ...options,
    }

    try {
      const response = await fetch(url, config)

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      return await response.json()
    } catch (error) {
      console.error('API request failed:', error)
      throw error
    }
  }

  // 文件上传
  async uploadFiles(files, onProgress = null) {
    const formData = new FormData()

    files.forEach((file, index) => {
      formData.append(`files`, file)
    })

    try {
      const response = await fetch(`${this.baseURL}/upload`, {
        method: 'POST',
        body: formData,
      })

      if (!response.ok) {
        throw new Error(`Upload failed: ${response.status}`)
      }

      return await response.json()
    } catch (error) {
      console.error('Upload failed:', error)
      throw error
    }
  }

  // 开始OCR处理
  async startOcrProcessing(taskId) {
    return this.request(`/process/${taskId}`, {
      method: 'POST'
    })
  }

  // 获取任务状态
  async getTaskStatus(taskId) {
    return this.request(`/status/${taskId}`)
  }

  // 获取处理结果
  async getResults(taskId) {
    return this.request(`/results/${taskId}`)
  }

  // 下载结果文件
  async downloadResults(taskId, format = 'txt') {
    const response = await fetch(`${this.baseURL}/download/${taskId}?format=${format}`)

    if (!response.ok) {
      throw new Error(`Download failed: ${response.status}`)
    }

    return response.blob()
  }

  // 获取文件预览
  getPreviewUrl(fileId) {
    return `${this.baseURL}/preview/${fileId}`
  }
}

// WebSocket连接用于实时状态更新
class WebSocketService {
  constructor() {
    this.ws = null
    this.callbacks = new Map()
  }

  connect(taskId) {
    const wsURL = `${API_BASE_URL.replace('http', 'ws')}/ws/${taskId}`
    this.ws = new WebSocket(wsURL)

    this.ws.onopen = () => {
      console.log('WebSocket connected')
    }

    this.ws.onmessage = (event) => {
      const data = JSON.parse(event.data)
      this.handleMessage(data)
    }

    this.ws.onclose = () => {
      console.log('WebSocket disconnected')
    }

    this.ws.onerror = (error) => {
      console.error('WebSocket error:', error)
    }
  }

  handleMessage(data) {
    const callback = this.callbacks.get(data.type)
    if (callback) {
      callback(data)
    }
  }

  subscribe(eventType, callback) {
    this.callbacks.set(eventType, callback)
  }

  disconnect() {
    if (this.ws) {
      this.ws.close()
      this.ws = null
    }
  }
}

// 导出服务实例
export const apiService = new ApiService()
export const wsService = new WebSocketService()

// 导出常用的API方法
export {
  ApiService,
  WebSocketService
}

export async function ocrImage(file, lang = 'eng', outputFormat = 'text') {
  const formData = new FormData();
  formData.append('file', file);
  formData.append('lang', lang);
  formData.append('output_format', outputFormat);

  const response = await fetch('/ocr/', {
    method: 'POST',
    body: formData,
  });

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

  const response = await fetch('/ocr/auto/', {
    method: 'POST',
    body: formData,
  });

  if (outputFormat === 'word' || outputFormat === 'pdf') {
    const blob = await response.blob();
    return blob;
  } else {
    return response.json();
  }
}
