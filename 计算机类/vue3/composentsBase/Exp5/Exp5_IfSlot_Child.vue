<template>
  <div class="card">
    <!-- 头部：如果父组件提供了 header 插槽才渲染 -->
    <header v-if="$slots.header" class="card-header">
      <slot name="header" />
    </header>

    <!-- 主体：默认插槽，始终存在 -->
    <main class="card-body">
      <slot />
    </main>

    <!-- 底部：只有父组件提供了 footer 插槽才渲染 -->
    <footer v-if="$slots.footer" class="card-footer">
      <slot name="footer" />
    </footer>
  </div>
</template>

<script setup>
//子组件定义多个具名插槽，并用 $slots 判断插槽是否存在，从而条件渲染外围结构。
</script>

<style scoped>
.card {
  border: 1px solid #ddd;
  border-radius: 8px;
  overflow: hidden;
  margin: 12px 0;
}
.card-header {
  background: #f5f5f5;
  padding: 8px 12px;
  font-weight: bold;
}
.card-body {
  padding: 12px;
}
.card-footer {
  background: #fafafa;
  padding: 8px 12px;
  text-align: right;
}
</style>
