<template>
  <input :ref="(el) => setInputRef(el)" />
</template>

<script setup>
import { ref } from 'vue'

const inputEl = ref(null)

// 每次渲染时调用，el 为元素或组件实例
function setInputRef(el) {
  inputEl.value = el
}
</script>
