<template>
  <slot name="user" :user="user" />
  <slot name="info" :info="info" />
</template>

<script setup>
import { ref } from 'vue'

const user = ref({ name: '张三', age: 25 })
const info = ref({ city: '北京', job: '工程师' })
</script>
