<template>
  <div>
    <ChildComponent ref="childRef" />
    <button @click="childRef.increment()">子组件 +1</button>
    <button @click="childRef.reset()">重置</button>
    <p>子组件当前计数：{{ childRef?.count }}</p>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import ChildComponent from './TemplateRefs2_RefChildComp_Child.vue'

const childRef = ref(null)
</script>
