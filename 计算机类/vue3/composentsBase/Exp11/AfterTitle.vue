<script setup>
// 含具名作用域插槽，向父组件传递数据。

import { inject } from 'vue'

const tabList = inject('tabList')
const content = tabList.value[2].content
</script>

<template>
  <div>
    <p class="after_p">{{ content.settlement }}</p>
    <slot name="settlement" :sx="content.stxt"></slot>
    <p class="after_p">{{ content.customer }}</p>
    <slot name="customer" :cx="content.ctxt"></slot>
  </div>
</template>

<style scoped>
.after_p {
  font-weight: bold;
  color: #5b595958;
}
</style>
