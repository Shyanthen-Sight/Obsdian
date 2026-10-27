<template>
  <slot :user="user" />
</template>

<script setup>
import { ref } from 'vue'
const user = ref({ name: '张三', age: 25 })
</script>
