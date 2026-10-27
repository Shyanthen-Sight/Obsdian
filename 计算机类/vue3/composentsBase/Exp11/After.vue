<script setup>
// 使用作用域插槽接收子组件数据。

import AfterTitle from './AfterTitle.vue'
</script>

<template>
  <div>
    <AfterTitle>
      <template #settlement="slotSettlement">
        <p>{{ slotSettlement.sx }}</p>
      </template>
      <template #customer="slotCustomer">
        <p>{{ slotCustomer.cx }}</p>
      </template>
    </AfterTitle>
  </div>
</template>
