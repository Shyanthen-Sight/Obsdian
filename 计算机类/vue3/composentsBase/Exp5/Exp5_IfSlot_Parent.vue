<template>
  <div>
    <label> <input type="checkbox" v-model="showHeader" /> 显示 Header </label>
    <label style="margin-left: 16px">
      <input type="checkbox" v-model="showFooter" /> 显示 Footer
    </label>

    <ChildCard>
      <!-- 条件插槽：v-if 为 false 时，该插槽内容不存在 -->
      <template #header v-if="showHeader">
        <span>标题区域</span>
      </template>

      <!-- 默认插槽：始终渲染 -->
      <p>这是卡片主体内容，始终显示。</p>

      <template #footer v-if="showFooter">
        <button>确定</button>
      </template>
    </ChildCard>
  </div>
</template>

<script setup>
//父组件通过 showHeader / showFooter 两个响应式变量，用 v-if 条件性地提供插槽内容。
import { ref } from 'vue'
import ChildCard from './Exp5_IfSlot_Child.vue'

const showHeader = ref(true)
const showFooter = ref(false)
</script>
