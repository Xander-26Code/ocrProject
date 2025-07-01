<template>
  <div class="feature-card">
    <div class="feature-icon">
      <span class="icon">{{ icon }}</span>
    </div>
    <div class="feature-content">
      <h4 class="feature-title">{{ title }}</h4>
      <p class="feature-description">{{ description }}</p>
    </div>
  </div>
</template>

<script setup>
defineProps({
  icon: {
    type: String,
    required: true
  },
  title: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  }
})
</script>

<style scoped>
.feature-card {
  background: white;
  border-radius: 12px;
  padding: 2rem;
  text-align: center;
  transition: all 0.3s ease;
  border: 1px solid #e9ecef;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.feature-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
  border-color: #667eea;
}

.feature-icon {
  margin-bottom: 1.5rem;
}

.icon {
  font-size: 3rem;
  display: inline-block;
  filter: grayscale(0.2);
  transition: filter 0.3s ease;
}

.feature-card:hover .icon {
  filter: none;
}

.feature-title {
  font-size: 1.25rem;
  color: #333;
  margin-bottom: 1rem;
  font-weight: 600;
}

.feature-description {
  color: #666;
  line-height: 1.6;
  font-size: 0.95rem;
}
</style>
