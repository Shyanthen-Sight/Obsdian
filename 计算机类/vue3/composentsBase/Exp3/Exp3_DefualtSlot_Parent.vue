<template>
  <!-- 第一个子组件：不传内容，显示默认的"阿尔泰山" -->
  <Exp3_DefualtSlot_Child />

  <!-- 第二个子组件：传入 img，覆盖默认内容 -->
  <Exp3_DefualtSlot_Child>
    <img :src="loadingOver" style="width: 100px; height: 100px" />
  </Exp3_DefualtSlot_Child>
</template>

<script setup>
import { ref } from 'vue'
import Exp3_DefualtSlot_Child from './Exp3_DefualtSlot_Child.vue'
import loadingOverUrl from '@/assets/img/loadingOver.jpg'

// 保存图片地址（组合式 API 中用 ref 声明响应式数据）
const loadingOver = ref(loadingOverUrl)
</script>

<style scoped></style>
