<template>
  <div class="parent-wrapper">
    <Child :id="id" :name="name" :sex="sex" :login-method="loginMethod" />
  </div>
</template>

<script setup>
import { ref } from 'vue'
import Child from './Exp1_Verify_ParentToChild_Child.vue'

const id = ref(1) // 类型校验
const name = ref('小明') // 必填
const sex = ref(undefined) // 默认值
const loginMethod = ref('Tel') // 自定义验证
</script>

<style scoped>
.parent-wrapper {
  padding: 1.5rem;
  background: white;
  border-radius: 8px;
  border: 1px solid #e0e0e0;
}
</style>
