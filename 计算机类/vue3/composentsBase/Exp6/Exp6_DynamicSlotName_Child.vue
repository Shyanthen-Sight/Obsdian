<template>
  <div class="panel">
    <div v-for="section in sections" :key="section" class="panel-section">
      <h4>{{ section }}</h4>

      <!-- 动态插槽名：name 由变量 section 决定 -->
      <slot :name="section">
        <!-- 后备内容：父组件没传该插槽时显示 -->
        <p class="empty">（暂无 {{ section }} 内容）</p>
      </slot>
    </div>
  </div>
</template>

<script setup>
//子组件渲染一组动态具名插槽，插槽名由 sections 数组决定；同时用 $slots 判断某插槽是否存在，若不存在则显示占位内容。
defineProps({
  sections: {
    type: Array,
    required: true,
  },
})
</script>

<style scoped>
.panel {
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 12px;
}
.panel-section + .panel-section {
  margin-top: 12px;
  border-top: 1px dashed #eee;
  padding-top: 12px;
}
.empty {
  color: #999;
  font-style: italic;
}
</style>
