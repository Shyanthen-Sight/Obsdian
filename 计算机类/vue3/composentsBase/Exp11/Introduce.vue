<script setup>
import { inject } from 'vue'
import IntroduceHeader from './IntroduceHeader.vue'

const tabList = inject('tabList')
// 用 inject 拿 tabList
</script>

<template>
  <div>
    <IntroduceHeader :content="tabList[0].content" />
    <img :src="tabList[0].content.imgSrc" class="introImg" />
  </div>
</template>

<style scoped>
.introImg {
  width: 100%;
}
</style>
