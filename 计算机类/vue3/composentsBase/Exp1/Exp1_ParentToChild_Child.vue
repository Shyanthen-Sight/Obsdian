<template>
  <p>{{ id }}-{{ title }}-{{ name }}</p>
</template>

<script setup>
import { onMounted, ref } from 'vue'

// 声明 props
const props = defineProps(['id', 'title'])

// 定义响应式数据
const name = ref('张三')
onMounted(() => {
  console.log(props.title)
})
</script>
