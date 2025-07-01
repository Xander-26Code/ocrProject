<template>
  <div class="upload-area">
    <div class="upload-container"
         :class="{ 'drag-over': isDragOver }"
         @drop="handleDrop"
         @dragover.prevent="isDragOver = true"
         @dragleave="isDragOver = false">

      <div class="upload-icon">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
          <polyline points="7,10 12,15 17,10"/>
          <line x1="12" y1="15" x2="12" y2="3"/>
        </svg>
      </div>

      <div class="upload-text">
        <h3>拖拽图片到此处或点击上传</h3>
        <p>支持 JPG、PNG、PDF 格式，最大支持 100MB</p>
      </div>

      <input
        ref="fileInput"
        type="file"
        multiple
        accept="image/*,.pdf"
        @change="handleFileSelect"
        class="file-input"
      >

      <button @click="$refs.fileInput.click()" class="upload-btn">
        选择文件
      </button>
    </div>

    <!-- 文件列表 -->
    <div class="file-list" v-if="selectedFiles.length > 0">
      <h4>已选择的文件 ({{ selectedFiles.length }})</h4>
      <div class="file-items">
        <div v-for="(file, index) in selectedFiles" :key="index" class="file-item">
          <div class="file-info">
            <span class="file-name">{{ file.name }}</span>
            <span class="file-size">{{ formatFileSize(file.size) }}</span>
          </div>
          <button @click="removeFile(index)" class="remove-btn">×</button>
        </div>
      </div>

      <div class="output-format">
        <label>输出格式：</label>
        <select v-model="outputFormat">
          <option value="text">文本</option>
          <option value="word">Word</option>
          <option value="pdf">PDF</option>
        </select>
      </div>

      <div class="upload-actions">
        <button @click="clearAll" class="clear-btn">清空全部</button>
        <button @click="startProcessing" class="process-btn" :disabled="selectedFiles.length === 0">
          开始处理 ({{ selectedFiles.length }} 个文件)
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, defineEmits } from 'vue'

const emit = defineEmits(['files-processed'])

const selectedFiles = ref([])
const isDragOver = ref(false)
const outputFormat = ref('text')

const handleDrop = (e) => {
  e.preventDefault()
  isDragOver.value = false

  const files = Array.from(e.dataTransfer.files)
  addFiles(files)
}

const handleFileSelect = (e) => {
  const files = Array.from(e.target.files)
  addFiles(files)
}

const addFiles = (files) => {
  const validFiles = files.filter(file => {
    const isValidType = file.type.startsWith('image/') || file.type === 'application/pdf'
    const isValidSize = file.size <= 100 * 1024 * 1024 // 100MB
    return isValidType && isValidSize
  })

  selectedFiles.value = [...selectedFiles.value, ...validFiles]
}

const removeFile = (index) => {
  selectedFiles.value.splice(index, 1)
}

const clearAll = () => {
  selectedFiles.value = []
}

const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

const startProcessing = () => {
  emit('files-processed', { files: selectedFiles.value, outputFormat: outputFormat.value })
}
</script>

<style scoped>
.upload-area {
  max-width: 600px;
  margin: 0 auto;
}

.upload-container {
  border: 2px dashed rgba(255, 255, 255, 0.3);
  border-radius: 12px;
  padding: 3rem 2rem;
  text-align: center;
  transition: all 0.3s ease;
  cursor: pointer;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
}

.upload-container:hover,
.upload-container.drag-over {
  border-color: rgba(255, 255, 255, 0.6);
  background: rgba(255, 255, 255, 0.15);
}

.upload-icon {
  color: rgba(255, 255, 255, 0.8);
  margin-bottom: 1rem;
}

.upload-text h3 {
  font-size: 1.2rem;
  margin-bottom: 0.5rem;
  color: white;
}

.upload-text p {
  color: rgba(255, 255, 255, 0.7);
  font-size: 0.9rem;
  margin-bottom: 2rem;
}

.file-input {
  display: none;
}

.upload-btn {
  background: rgba(255, 255, 255, 0.2);
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.3);
  padding: 0.75rem 2rem;
  border-radius: 8px;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.3s ease;
}

.upload-btn:hover {
  background: rgba(255, 255, 255, 0.3);
}

/* 文件列表样式 */
.file-list {
  margin-top: 2rem;
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
}

.file-list h4 {
  color: #333;
  margin-bottom: 1rem;
}

.file-items {
  max-height: 300px;
  overflow-y: auto;
}

.file-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem;
  border: 1px solid #e1e5e9;
  border-radius: 8px;
  margin-bottom: 0.5rem;
  background: #f8f9fa;
}

.file-info {
  display: flex;
  flex-direction: column;
  flex: 1;
}

.file-name {
  font-weight: 500;
  color: #333;
  margin-bottom: 0.25rem;
}

.file-size {
  font-size: 0.85rem;
  color: #666;
}

.remove-btn {
  background: #ff4757;
  color: white;
  border: none;
  width: 24px;
  height: 24px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 1rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.upload-actions {
  display: flex;
  gap: 1rem;
  margin-top: 1.5rem;
  justify-content: space-between;
}

.clear-btn {
  background: #6c757d;
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  cursor: pointer;
  transition: background 0.3s ease;
}

.clear-btn:hover {
  background: #5a6268;
}

.process-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  padding: 0.75rem 2rem;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 500;
  transition: transform 0.3s ease;
}

.process-btn:hover:not(:disabled) {
  transform: translateY(-2px);
}

.process-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.output-format {
  margin: 1rem 0 1.5rem 0;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.output-format label {
  font-size: 1rem;
  color: #333;
}

.output-format select {
  padding: 0.3rem 1rem;
  border-radius: 6px;
  border: 1px solid #ccc;
  font-size: 1rem;
}
</style>
