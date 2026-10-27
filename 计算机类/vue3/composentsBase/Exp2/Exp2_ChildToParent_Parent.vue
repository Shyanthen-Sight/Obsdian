<template>
  <p>price: {{ price }}</p>
  <Child @minus="handleMinus" />
</template>

<script setup>
import { ref } from 'vue'
import Child from './Exp2_ChildToParent_Child.vue'

const price = ref(99)

function handleMinus(params) {
  price.value = price.value - params
}
</script>
