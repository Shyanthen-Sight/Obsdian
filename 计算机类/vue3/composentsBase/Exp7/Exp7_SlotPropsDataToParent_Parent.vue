<template>
  <div>
    <h4>默认作用域插槽（简写 v-slot）</h4>
    <TodoList v-slot="{ item, index }">
      <span>[{{ index + 1 }}]</span>
      <span :class="{ done: item.done }">{{ item.text }}</span>
      <span>{{ item.done ? '✅' : '⬜' }}</span>
    </TodoList>

    <h4>显式 #default</h4>
    <TodoList>
      <template #default="{ item, index }">
        <strong>#{{ index + 1 }}</strong>
        <em>{{ item.text }}</em>
      </template>
    </TodoList>
  </div>
</template>

<script setup>
import TodoList from './Exp7_SlotPropsDataToParent_Child.vue'
</script>

<style scoped>
.done {
  color: #999;
  text-decoration: line-through;
}
</style>
