<template>
  <div>
    <p>子组件计数器：{{ count }}</p>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const count = ref(0)

// 必须通过 defineExpose 暴露方法/属性，父组件才能访问
function increment() {
  count.value++
}

function reset() {
  count.value = 0
}

defineExpose({
  increment,
  reset,
  count,
})
</script>
