<template>
  <h3>{{ productProvide.name }}</h3>
  <p>当前价格：{{ productProvide.price }}</p>
  <p>库存：{{ productProvide.stock }}</p>
  <hr />
  <div>
    <ul>
      <li v-for="(value, key) in productProvide.detail" :key="key">{{ key }}:{{ value }}</li>
    </ul>
  </div>
</template>

<script setup>
import { inject } from 'vue'

const productProvide = inject('productProvide')
</script>
