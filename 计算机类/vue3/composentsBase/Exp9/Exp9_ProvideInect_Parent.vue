<template>
  <ChildComp />
</template>

<script setup>
import { provide, reactive } from 'vue'
import ChildComp from './Exp9_ProvideInect_Child.vue'

const product = reactive({
  name: '河北皇冠梨',
  price: 28.9,
  stock: 999,
  detail: {
    barnd: '远达',
    type: '皇冠梨',
    bunmber: 123456,
    placeProduction: '河北',
    storageConditions: '冷藏',
  },
})

provide('productProvide', product)

//查阅拓展文档，ref和reactive对比
</script>
