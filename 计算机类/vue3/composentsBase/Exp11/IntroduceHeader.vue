<script setup>
defineProps({
  content: {
    type: Object,
    required: true,
  },
})
// 通过 props 接收 content
</script>

<template>
  <div>
    <ul class="introUl">
      <li>品牌：{{ content.barnd }}</li>
      <li>品种：{{ content.type }}</li>
      <li>编号：{{ content.bunmber }}</li>
      <li>产地：{{ content.placeProduction }}</li>
      <li>贮存条件：{{ content.storageConditions }}</li>
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
