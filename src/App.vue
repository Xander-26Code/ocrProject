<template>
  <div id="app">
    <!-- 顶部导航 -->
    <header class="header">
      <div class="container header-flex">
        <div class="logo">
          <h1>OCR Pro</h1>
          <span class="tagline">智能文字识别</span>
        </div>
        <nav class="nav">
          <a href="#features" class="nav-link">功能</a>
          <a href="#pricing" class="nav-link">定价</a>
          <a href="#about" class="nav-link">关于</a>
        </nav>
      </div>
    </header>
    <div class="header-divider"></div>

    <!-- 主要内容区域 -->
    <main class="main">
      <!-- 英雄区域 -->
      <section class="hero">
        <div class="container">
          <div class="hero-content">
            <h2 class="hero-title">批量图片文字识别</h2>
            <p class="hero-description">高精度OCR技术，支持批量处理，让文字提取变得简单高效</p>
            <div style="margin-bottom: 1rem; text-align: left;">
              <label style="font-size: 1rem; color: #333;">
                <input type="checkbox" v-model="autoDetectLang" style="margin-right: 0.5rem;" />
                自动检测图片语言
              </label>
            </div>
            <UploadArea @files-processed="handleFilesProcessed" />
          </div>
        </div>
      </section>

      <!-- 处理状态区域 -->
      <section class="processing-section" v-if="showProcessingStatus">
        <div class="container">
          <ProcessingStatus />
        </div>
      </section>

      <!-- 结果展示区域 -->
      <section class="results-section" v-if="showResults">
        <div class="container">
          <ResultsDisplay :results="results" />
        </div>
      </section>

      <!-- 功能特性 -->
      <section id="features" class="features">
        <div class="container">
          <h3 class="section-title">核心功能</h3>
          <div class="features-grid">
            <FeatureCard
              icon="⚡"
              title="高速处理"
              description="支持批量处理，大幅提升工作效率"
            />
            <FeatureCard
              icon="🎯"
              title="高精度识别"
              description="先进的OCR算法，识别准确率高达99%"
            />
            <FeatureCard
              icon="📱"
              title="多格式支持"
              description="支持JPG、PNG、PDF等多种格式"
            />
            <FeatureCard
              icon="☁️"
              title="云端处理"
              description="无需安装软件，在线即可使用"
            />
          </div>
        </div>
      </section>
    </main>

    <!-- 页脚 -->
    <footer class="footer">
      <div class="container">
        <p>&copy; 2025 OCR Pro. 保留所有权利.</p>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useAppStore } from './stores/app.js'
import UploadArea from './components/UploadArea.vue'
import ProcessingStatus from './components/ProcessingStatus.vue'
import ResultsDisplay from './components/ResultsDisplay.vue'
import FeatureCard from './components/FeatureCard.vue'
import { ocrImage, ocrAutoDetect } from './services/api.js'

// 使用状态管理
const { state, startProcessing } = useAppStore()

// 控制显示状态
const showProcessingStatus = ref(false)
const showResults = ref(false)
const autoDetectLang = ref(true) // 新增：是否自动检测语言

// 识别结果
const results = ref([])

// 监听状态变化
const handleProcessingStart = () => {
  showProcessingStatus.value = true
  showResults.value = false
}

const handleProcessingComplete = () => {
  showProcessingStatus.value = false
  showResults.value = true
}

// 处理文件上传和OCR识别
const handleFilesProcessed = async ({ files, outputFormat }) => {
  results.value = []
  showProcessingStatus.value = true
  showResults.value = false
  for (let i = 0; i < files.length; i++) {
    const file = files[i]
    try {
      if (outputFormat === 'text') {
        let res
        if (autoDetectLang.value) {
          res = await ocrAutoDetect(file, 'text')
        } else {
          res = await ocrImage(file, 'chi_sim', 'text')
        }
        results.value.push({
          id: i + 1,
          filename: file.name,
          text: typeof res.text === 'string' ? res.text : JSON.stringify(res.text),
          detected_language: res.detected_language || '',
          language_name: res.language_name || '',
          accuracy: 100,
          processTime: 0,
          imageUrl: '',
          expanded: false,
          editing: false
        })
      } else if (outputFormat === 'word' || outputFormat === 'pdf') {
        if (autoDetectLang.value) {
          const blob = await ocrAutoDetect(file, outputFormat)
          const url = window.URL.createObjectURL(blob)
          const a = document.createElement('a')
          a.href = url
          a.download = outputFormat === 'word' ? `${file.name}_ocr.docx` : `${file.name}_ocr.pdf`
          a.click()
          window.URL.revokeObjectURL(url)
        } else {
          const blob = await ocrImage(file, 'chi_sim', outputFormat)
          const url = window.URL.createObjectURL(blob)
          const a = document.createElement('a')
          a.href = url
          a.download = outputFormat === 'word' ? `${file.name}_ocr.docx` : `${file.name}_ocr.pdf`
          a.click()
          window.URL.revokeObjectURL(url)
        }
      }
    } catch (e) {
      results.value.push({
        id: i + 1,
        filename: file.name,
        text: '识别失败',
        detected_language: '',
        language_name: '',
        accuracy: 0,
        processTime: 0,
        imageUrl: '',
        expanded: false,
        editing: false
      })
    }
  }
  showProcessingStatus.value = false
  // 只有文本模式才展示结果栏
  showResults.value = outputFormat === 'text' && results.value.length > 0
}
</script>

<style scoped>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

#app {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  line-height: 1.6;
  color: #333;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

/* 头部样式 */
.header {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  border-bottom: 2px solid #f0f0f0;
  position: sticky;
  top: 0;
  z-index: 100;
  box-shadow: 0 2px 8px 0 rgba(60, 60, 60, 0.04);
}

.header .container,
.header-flex {
  display: flex;
  align-items: center;
  padding: 1rem 20px;
}

.header-flex {
  flex-direction: row;
  justify-content: flex-start;
}

.logo {
  margin-right: 48px;
  min-width: 180px;
}

.logo h1 {
  font-size: 1.5rem;
  font-weight: 700;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.tagline {
  font-size: 0.8rem;
  color: #666;
  margin-left: 0.5rem;
}

.nav {
  display: flex;
  gap: 2.5rem;
  flex: 1;
}

.nav-link {
  text-decoration: none;
  color: #666;
  font-weight: 500;
  transition: color 0.3s ease;
  font-size: 1.1rem;
}

.nav-link:hover {
  color: #667eea;
}

/* 主要内容区域 */
.main {
  min-height: calc(100vh - 140px);
  margin-top: 32px;
}

/* 英雄区域 */
.hero {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 4rem 0;
  text-align: center;
}

.hero-content {
  max-width: 800px;
  margin: 0 auto;
}

.hero-title {
  font-size: 3rem;
  font-weight: 700;
  margin-bottom: 1rem;
  line-height: 1.2;
}

.hero-description {
  font-size: 1.2rem;
  margin-bottom: 3rem;
  opacity: 0.9;
}

/* 处理状态和结果区域 */
.processing-section,
.results-section {
  padding: 3rem 0;
  background: #f8f9fa;
}

/* 功能特性 */
.features {
  padding: 5rem 0;
  background: white;
}

.section-title {
  text-align: center;
  font-size: 2.5rem;
  margin-bottom: 3rem;
  color: #333;
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 2rem;
  margin-top: 3rem;
}

/* 页脚 */
.footer {
  background: #afe0df;
  color: rgb(33, 32, 32);
  text-align: center;
  padding: 2rem 0;
  font-size: 1.1rem;
  font-style: normal;
  font-family: 'Times New Roman', Times, serif;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .header .container {
    flex-direction: column;
    gap: 1rem;
  }

  .hero-title {
    font-size: 2rem;
  }

  .hero-description {
    font-size: 1rem;
  }

  .features-grid {
    grid-template-columns: 1fr;
  }

  .nav {
    gap: 1rem;
  }
}

.header-divider {
  width: 100%;
  height: 16px;
  background: transparent;
}
</style>
