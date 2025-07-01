import { reactive, ref } from 'vue'
import { apiService, wsService } from '../services/api.js'

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

      // 上传文件
      const uploadResult = await apiService.uploadFiles(
        state.selectedFiles,
        (progress) => {
          state.uploadProgress = progress
        }
      )

      state.currentTaskId = uploadResult.task_id

      // 初始化任务列表
      state.tasks = state.selectedFiles.map((file, index) => ({
        id: index + 1,
        filename: file.name,
        status: 'waiting',
        progress: 0,
        result: null,
        error: null
      }))

      // 连接WebSocket获取实时更新
      wsService.connect(state.currentTaskId)
      wsService.subscribe('task_update', handleTaskUpdate)
      wsService.subscribe('task_completed', handleTaskCompleted)

      // 开始OCR处理
      await apiService.startOcrProcessing(state.currentTaskId)

    } catch (error) {
      state.error = error.message
      state.loading = false
    }
  }

  // 处理任务更新
  const handleTaskUpdate = (data) => {
    const task = state.tasks.find(t => t.id === data.task_id)
    if (task) {
      task.status = data.status
      task.progress = data.progress
    }
  }

  // 处理任务完成
  const handleTaskCompleted = (data) => {
    const task = state.tasks.find(t => t.id === data.task_id)
    if (task) {
      task.status = 'completed'
      task.progress = 100
      task.result = data.result
    }

    // 检查是否所有任务都完成
    const allCompleted = state.tasks.every(t => t.status === 'completed' || t.status === 'error')
    if (allCompleted) {
      loadResults()
    }
  }

  // 加载结果
  const loadResults = async () => {
    try {
      const results = await apiService.getResults(state.currentTaskId)
      state.results = results.map(result => ({
        ...result,
        expanded: false,
        editing: false
      }))

      // 更新统计信息
      updateStats()

      state.currentStep = 'results'
      state.loading = false

      // 断开WebSocket连接
      wsService.disconnect()

    } catch (error) {
      state.error = error.message
      state.loading = false
    }
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

    wsService.disconnect()
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
