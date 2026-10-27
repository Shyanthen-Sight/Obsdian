<script setup>
import { inject, computed } from 'vue'

const tabList = inject('tabList')
const content = computed(() => tabList.value[1].content)
// 注意：inject('tabList') 拿到的是根组件的 ref，
// 所以取值时用 tabList.value。
// 这依赖根组件 provide('tabList', tabList) 提供的是 ref 本身。
</script>

<template>
  <div>
    <ul class="introUl">
      <li>主体：{{ content.main }}</li>
      <li>重量：{{ content.weight }}</li>
      <li style="width: 300px">包装清单：{{ content.inventory }}</li>
    </ul>
  </div>
</template>

<style scoped>
.introUl {
  display: flex;
  justify-content: flex-start;
  flex-wrap: wrap;
  padding: 0;
  margin: 0;
}

.introUl li {
  list-style: none;
  width: 200px;
  height: 30px;
}
</style>
