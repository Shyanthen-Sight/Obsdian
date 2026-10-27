<template>
  <p>
    <Child id="001" :title="greeting" />
  </p>
</template>

<script setup>
import { ref } from 'vue'
import Child from './Exp1_ParentToChild_Child.vue'

// 定义响应式数据
const greeting = ref('hello')
</script>
