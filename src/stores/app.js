import { reactive, ref } from 'vue'
import { apiService, ocrAutoDetect } from '../services/api.js'

// 应用状态管理
export const useAppStore = () => {
  // 应用状态
  const state = reactive({
    // 当前页面状态
    currentStep: 'upload', // upload, processing, results

    // 文件相关
    selectedFiles: [],
    uploadProgress: 0,

    // 任务相关
    currentTaskId: null,
    tasks: [],

    // 结果相关
    results: [],

    // UI状态
    loading: false,
    error: null,

    // 统计信息
    stats: {
      totalFiles: 0,
      processedFiles: 0,
      totalCharacters: 0,
      averageAccuracy: 0
    }
  })

  // 设置选中的文件
  const setSelectedFiles = (files) => {
    state.selectedFiles = files
    state.stats.totalFiles = files.length
  }

  // 添加文件
  const addFiles = (newFiles) => {
    state.selectedFiles = [...state.selectedFiles, ...newFiles]
    state.stats.totalFiles = state.selectedFiles.length
  }

  // 移除文件
  const removeFile = (index) => {
    state.selectedFiles.splice(index, 1)
    state.stats.totalFiles = state.selectedFiles.length
  }

  // 清空文件
  const clearFiles = () => {
    state.selectedFiles = []
    state.stats.totalFiles = 0
  }

  // 开始处理
  const startProcessing = async () => {
    try {
      state.loading = true
      state.currentStep = 'processing'
      state.error = null

      // 初始化任务列表
      state.tasks = state.selectedFiles.map((file, index) => ({
        id: index + 1,
        filename: file.name,
        status: 'processing',
        progress: 0,
        result: null,
        error: null
      }))

      // 直接处理文件（简化版，不使用WebSocket）
      await processFilesDirectly()

    } catch (error) {
      state.error = error.message
      state.loading = false
    }
  }

  // 直接处理文件
  const processFilesDirectly = async () => {
    const results = []
    
    for (let i = 0; i < state.selectedFiles.length; i++) {
      const file = state.selectedFiles[i]
      const task = state.tasks[i]
      
      try {
        task.status = 'processing'
        task.progress = 50
        
        // 调用OCR API处理单个文件
        const result = await ocrAutoDetect(file, 'text')
        
        task.status = 'completed'
        task.progress = 100
        task.result = result
        
        results.push({
          id: i + 1,
          filename: file.name,
          text: result.text || result,
          language: result.language || 'auto',
          accuracy: result.accuracy || 85,
          processing_time: result.processing_time || 1.0
        })
        
      } catch (error) {
        task.status = 'error'
        task.error = error.message
      }
    }
    
    // 设置结果并切换到结果页面
    state.results = results.map(result => ({
      ...result,
      expanded: false,
      editing: false
    }))
    
    updateStats()
    state.currentStep = 'results'
    state.loading = false
  }

  // 加载结果 (简化版，结果已在processFilesDirectly中处理)
  const loadResults = () => {
    // 结果已经在processFilesDirectly中设置，这里只需要更新统计信息
    updateStats()
    state.currentStep = 'results'
    state.loading = false
  }

  // 更新统计信息
  const updateStats = () => {
    state.stats.processedFiles = state.results.length
    state.stats.totalCharacters = state.results.reduce((sum, result) => sum + result.text.length, 0)

    const avgAccuracy = state.results.reduce((sum, result) => sum + result.accuracy, 0) / state.results.length
    state.stats.averageAccuracy = avgAccuracy.toFixed(1)
  }

  // 重置状态
  const reset = () => {
    state.currentStep = 'upload'
    state.selectedFiles = []
    state.uploadProgress = 0
    state.currentTaskId = null
    state.tasks = []
    state.results = []
    state.loading = false
    state.error = null
    state.stats = {
      totalFiles: 0,
      processedFiles: 0,
      totalCharacters: 0,
      averageAccuracy: 0
    }
  }

  // 设置错误
  const setError = (error) => {
    state.error = error
    state.loading = false
  }

  // 清除错误
  const clearError = () => {
    state.error = null
  }

  return {
    // 状态
    state,

    // 文件操作
    setSelectedFiles,
    addFiles,
    removeFile,
    clearFiles,

    // 处理操作
    startProcessing,
    loadResults,

    // 状态操作
    reset,
    setError,
    clearError,

    // 统计信息
    updateStats
  }
}
