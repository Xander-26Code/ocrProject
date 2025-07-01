<template>
  <div class="results-display">
    <div class="results-header">
      <h3>识别结果</h3>
      <div class="results-summary">
        <span class="summary-item">
          <strong>{{ results.length }}</strong> 个文件已处理
        </span>
        <span class="summary-item">
          <strong>{{ totalCharacters }}</strong> 个字符已识别
        </span>
        <span class="summary-item">
          平均准确率 <strong>{{ averageAccuracy }}%</strong>
        </span>
      </div>
    </div>

    <div class="results-actions">
      <button @click="downloadAll" class="action-btn primary">
        📥 下载全部结果
      </button>
      <button @click="copyAll" class="action-btn">
        📋 复制全部文本
      </button>
    </div>

    <div class="results-list">
      <div v-for="result in results" :key="result.id" class="result-item">
        <div class="result-header">
          <div class="file-info">
            <h4 class="filename">{{ result.filename }}</h4>
            <div class="file-meta">
              <span class="accuracy" :class="getAccuracyClass(result.accuracy)">
                准确率: {{ result.accuracy }}%
              </span>
              <span class="char-count">{{ result.text.length }} 字符</span>
              <span class="process-time">{{ result.processTime }}ms</span>
              <span v-if="result.language_name" class="lang-info">语言: {{ result.language_name }}</span>
            </div>
          </div>
          <div class="result-actions">
            <button @click="copyText(result.text)" class="icon-btn" title="复制文本">
              📋
            </button>
            <button @click="downloadSingle(result)" class="icon-btn" title="下载">
              📥
            </button>
            <button @click="toggleExpand(result.id)" class="icon-btn" title="展开/收起">
              {{ result.expanded ? '📄' : '📋' }}
            </button>
          </div>
        </div>

        <div class="result-content" v-show="result.expanded">
          <div class="image-preview" v-if="result.imageUrl">
            <img :src="result.imageUrl" :alt="result.filename" />
          </div>
          <div class="text-content">
            <div class="text-header">
              <span>识别文本</span>
              <button @click="editText(result)" class="edit-btn">✏️ 编辑</button>
            </div>
            <textarea
              v-model="result.text"
              class="text-area"
              :readonly="!result.editing"
              @blur="saveEdit(result)"
            ></textarea>
          </div>
        </div>
      </div>
    </div>

    <div class="results-pagination" v-if="results.length > pageSize">
      <button @click="prevPage" :disabled="currentPage === 1" class="page-btn">
        上一页
      </button>
      <span class="page-info">
        第 {{ currentPage }} 页，共 {{ totalPages }} 页
      </span>
      <button @click="nextPage" :disabled="currentPage === totalPages" class="page-btn">
        下一页
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, defineProps } from 'vue'

const props = defineProps({
  results: {
    type: Array,
    required: true,
    default: () => []
  }
})

const currentPage = ref(1)
const pageSize = ref(10)

const totalCharacters = computed(() =>
  props.results.reduce((sum, result) => sum + (result.text ? result.text.length : 0), 0)
)

const averageAccuracy = computed(() => {
  if (!props.results.length) return 0
  const avg = props.results.reduce((sum, result) => sum + (result.accuracy || 100), 0) / props.results.length
  return avg.toFixed(1)
})

const totalPages = computed(() =>
  Math.ceil(props.results.length / pageSize.value)
)

const getAccuracyClass = (accuracy) => {
  if (accuracy >= 95) return 'high'
  if (accuracy >= 85) return 'medium'
  return 'low'
}

const toggleExpand = (id) => {
  const result = props.results.find(r => r.id === id)
  if (result) {
    result.expanded = !result.expanded
  }
}

const copyText = async (text) => {
  try {
    await navigator.clipboard.writeText(text)
    console.log('文本已复制到剪贴板')
  } catch (err) {
    console.error('复制失败:', err)
  }
}

const copyAll = async () => {
  const allText = props.results.map(r => `${r.filename}:
${r.text}`).join('\n\n---\n\n')
  await copyText(allText)
}

const downloadSingle = (result) => {
  const blob = new Blob([result.text], { type: 'text/plain' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `${result.filename}_ocr.txt`
  a.click()
  URL.revokeObjectURL(url)
}

const downloadAll = () => {
  const allText = props.results.map(r => `${r.filename}:
${r.text}`).join('\n\n---\n\n')
  const blob = new Blob([allText], { type: 'text/plain' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = 'ocr_results_all.txt'
  a.click()
  URL.revokeObjectURL(url)
}

const exportExcel = () => {
  console.log('导出Excel功能')
}

const editText = (result) => {
  result.editing = !result.editing
}

const saveEdit = (result) => {
  result.editing = false
  console.log('保存编辑:', result.filename)
}

const prevPage = () => {
  if (currentPage.value > 1) currentPage.value--
}

const nextPage = () => {
  if (currentPage.value < totalPages.value) currentPage.value++
}
</script>

<style scoped>
.results-display {
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  max-width: 1000px;
  margin: 0 auto;
}

.results-header {
  padding: 2rem;
  border-bottom: 1px solid #e9ecef;
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
}

.results-header h3 {
  font-size: 1.5rem;
  color: #333;
  margin-bottom: 1rem;
}

.results-summary {
  display: flex;
  gap: 2rem;
  flex-wrap: wrap;
}

.summary-item {
  color: #666;
  font-size: 0.9rem;
}

.results-actions {
  padding: 1.5rem 2rem;
  border-bottom: 1px solid #e9ecef;
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.action-btn {
  padding: 0.5rem 1rem;
  border-radius: 6px;
  border: 1px solid #ddd;
  background: white;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 0.9rem;
}

.action-btn.primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
}

.action-btn:hover {
  transform: translateY(-1px);
}

.results-list {
  max-height: 600px;
  overflow-y: auto;
}

.result-item {
  border-bottom: 1px solid #e9ecef;
}

.result-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem 2rem;
  cursor: pointer;
}

.file-info {
  flex: 1;
}

.filename {
  font-size: 1.1rem;
  color: #333;
  margin-bottom: 0.5rem;
}

.file-meta {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.file-meta span {
  font-size: 0.8rem;
  padding: 0.25rem 0.5rem;
  border-radius: 12px;
  background: #f8f9fa;
}

.accuracy.high { background: #d4edda; color: #155724; }
.accuracy.medium { background: #fff3cd; color: #856404; }
.accuracy.low { background: #f8d7da; color: #721c24; }

.result-actions {
  display: flex;
  gap: 0.5rem;
}

.icon-btn {
  background: none;
  border: none;
  font-size: 1.2rem;
  cursor: pointer;
  padding: 0.5rem;
  border-radius: 6px;
  transition: background 0.3s ease;
}

.icon-btn:hover {
  background: #f8f9fa;
}

.result-content {
  padding: 0 2rem 2rem;
  display: flex;
  gap: 2rem;
}

.image-preview {
  flex-shrink: 0;
  width: 200px;
}

.image-preview img {
  width: 100%;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.text-content {
  flex: 1;
}

.text-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}

.edit-btn {
  background: none;
  border: none;
  color: #667eea;
  cursor: pointer;
  font-size: 0.9rem;
}

.text-area {
  width: 100%;
  min-height: 150px;
  padding: 1rem;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-family: inherit;
  font-size: 0.9rem;
  line-height: 1.5;
  resize: vertical;
}

.text-area:focus {
  outline: none;
  border-color: #667eea;
}

.results-pagination {
  padding: 1.5rem 2rem;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 1rem;
  border-top: 1px solid #e9ecef;
}

.page-btn {
  padding: 0.5rem 1rem;
  border: 1px solid #ddd;
  background: white;
  border-radius: 6px;
  cursor: pointer;
}

.page-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.page-info {
  color: #666;
  font-size: 0.9rem;
}

.lang-info {
  background: #e3f2fd;
  color: #1976d2;
  font-size: 0.8rem;
  padding: 0.25rem 0.5rem;
  border-radius: 12px;
}
</style>
