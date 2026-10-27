<template>
  <ul>
    <li v-for="(item, index) in list" :key="index" ref="itemRefs">
      {{ item }}
    </li>
  </ul>
  <button @click="logRefs">打印所有引用</button>
</template>

<script setup>
import { ref } from 'vue'

const list = ref(['A', 'B', 'C'])
const itemRefs = ref([]) // 注意：v-for 中 ref 会收集为数组

function logRefs() {
  itemRefs.value.forEach((el, i) => {
    console.log(`第 ${i} 项：`, el.textContent)
  })
}
</script>
