<template>
  <div>
    <input v-model="username" /><br />
    <input type="password" v-model="password" />
  </div>
</template>

<script setup>
import { ref } from 'vue'

const username = ref('admin')
const password = ref(123456)
</script>
