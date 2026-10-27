<template>
  <button @click="handleClick">降价</button>
</template>

<script setup>
import { ref } from 'vue'

const num = ref(2)
const emit = defineEmits(['minus'])

function handleClick() {
  emit('minus', num.value)
}
</script>
