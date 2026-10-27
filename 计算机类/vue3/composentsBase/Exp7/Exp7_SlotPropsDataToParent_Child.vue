<template>
  <ul class="todo-list">
    <li v-for="(todo, index) in todos" :key="todo.id">
      <!-- 默认插槽：把 todo 和 index 作为插槽 props 暴露给父组件 -->
      <slot :item="todo" :index="index">
        <!-- 后备内容：父组件没传插槽时显示 -->
        {{ todo.text }}
      </slot>
    </li>
  </ul>
</template>

<script setup>
import { ref } from 'vue'

const todos = ref([
  { id: 1, text: '学习 Vue 3', done: true },
  { id: 2, text: '写作用域插槽示例', done: false },
  { id: 3, text: '复习文档', done: false },
])
</script>

<style scoped>
.todo-list {
  list-style: none;
  padding: 0;
}
.todo-list li {
  padding: 6px 0;
  border-bottom: 1px dashed #eee;
}
</style>
