<template>
  <div class="processing-status">
    <div class="status-header">
      <h3>处理进度</h3>
      <div class="overall-progress">
        <div class="progress-bar">
          <div class="progress-fill" :style="{ width: overallProgress + '%' }"></div>
        </div>
        <span class="progress-text">{{ processedCount }}/{{ totalCount }} 完成</span>
      </div>
    </div>

    <div class="task-list">
      <div v-for="task in tasks" :key="task.id" class="task-item" :class="task.status">
        <div class="task-info">
          <div class="task-name">{{ task.filename }}</div>
          <div class="task-status">
            <span class="status-icon">
              <span v-if="task.status === 'waiting'">⏳</span>
              <span v-else-if="task.status === 'processing'">🔄</span>
              <span v-else-if="task.status === 'completed'">✅</span>
              <span v-else-if="task.status === 'error'">❌</span>
            </span>
            <span class="status-text">{{ getStatusText(task.status) }}</span>
          </div>
        </div>

        <div class="task-progress" v-if="task.status === 'processing'">
          <div class="progress-bar small">
            <div class="progress-fill" :style="{ width: task.progress + '%' }"></div>
          </div>
        </div>

        <div class="task-time" v-if="task.completedAt">
          {{ formatTime(task.completedAt) }}
        </div>
      </div>
    </div>

    <div class="status-actions" v-if="isCompleted">
      <button @click="downloadResults" class="download-btn">
        下载所有结果
      </button>
      <button @click="viewResults" class="view-btn">
        查看详细结果
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

// 模拟任务数据
const tasks = ref([
  { id: 1, filename: 'document1.jpg', status: 'completed', progress: 100, completedAt: new Date() },
  { id: 2, filename: 'image2.png', status: 'processing', progress: 65 },
  { id: 3, filename: 'scan3.pdf', status: 'waiting', progress: 0 },
  { id: 4, filename: 'receipt4.jpg', status: 'waiting', progress: 0 },
])

const totalCount = computed(() => tasks.value.length)
const processedCount = computed(() => tasks.value.filter(t => t.status === 'completed').length)
const overallProgress = computed(() => (processedCount.value / totalCount.value) * 100)
const isCompleted = computed(() => processedCount.value === totalCount.value)

const getStatusText = (status) => {
  const statusMap = {
    waiting: '等待中',
    processing: '处理中',
    completed: '已完成',
    error: '处理失败'
  }
  return statusMap[status] || '未知状态'
}

const formatTime = (date) => {
  return new Intl.DateTimeFormat('zh-CN', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  }).format(date)
}

const downloadResults = () => {
  console.log('下载所有结果')
}

const viewResults = () => {
  console.log('查看详细结果')
}
</script>

<style scoped>
.processing-status {
  background: white;
  border-radius: 12px;
  padding: 2rem;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  max-width: 800px;
  margin: 0 auto;
}

.status-header {
  margin-bottom: 2rem;
}

.status-header h3 {
  font-size: 1.5rem;
  color: #333;
  margin-bottom: 1rem;
}

.overall-progress {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.progress-bar {
  flex: 1;
  height: 8px;
  background: #e9ecef;
  border-radius: 4px;
  overflow: hidden;
}

.progress-bar.small {
  height: 4px;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  transition: width 0.3s ease;
}

.progress-text {
  font-weight: 500;
  color: #667eea;
  min-width: 80px;
}

.task-list {
  max-height: 400px;
  overflow-y: auto;
}

.task-item {
  display: flex;
  align-items: center;
  padding: 1rem;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  margin-bottom: 0.5rem;
  transition: all 0.3s ease;
}

.task-item.completed {
  background: #f8fff8;
  border-color: #d4edda;
}

.task-item.processing {
  background: #fff8e1;
  border-color: #ffd54f;
}

.task-item.error {
  background: #fff5f5;
  border-color: #f8d7da;
}

.task-info {
  flex: 1;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.task-name {
  font-weight: 500;
  color: #333;
}

.task-status {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.status-icon {
  font-size: 1rem;
}

.status-text {
  font-size: 0.9rem;
  color: #666;
}

.task-progress {
  margin: 0 1rem;
  width: 100px;
}

.task-time {
  font-size: 0.8rem;
  color: #888;
  min-width: 80px;
  text-align: right;
}

.status-actions {
  display: flex;
  gap: 1rem;
  margin-top: 2rem;
  justify-content: center;
}

.download-btn,
.view-btn {
  padding: 0.75rem 2rem;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
  border: none;
}

.download-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.download-btn:hover {
  transform: translateY(-2px);
}

.view-btn {
  background: white;
  color: #667eea;
  border: 2px solid #667eea;
}

.view-btn:hover {
  background: #667eea;
  color: white;
}
</style>
