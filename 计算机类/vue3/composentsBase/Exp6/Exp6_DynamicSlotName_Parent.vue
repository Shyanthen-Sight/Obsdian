<template>
  <div>
    <ChildPanel :sections="sections">
      <!-- 动态插槽名：只为有内容的 section 生成插槽，没内容的交给子组件显示后备内容 -->
      <template v-for="section in availableSections" :key="section" #[section]>
        <p>{{ contentMap[section] }}</p>
      </template>
    </ChildPanel>
  </div>
</template>

<script setup>
//父组件用 v-for 遍历同一个 sections 数组，通过 #[section] 动态绑定插槽名，为每个 section 生成一个插槽。
import { computed, ref } from 'vue'
import ChildPanel from './Exp6_DynamicSlotName_Child.vue'

const sections = ref(['基本信息', '详细描述', '联系方式'])

// 只为前两个 section 提供内容，第三个会显示子组件的后备内容
const contentMap = {
  基本信息: '这是基本信息的内容。',
  详细描述: '这是详细描述的内容。',
}

// 关键：v-for 只遍历真正有内容的 section。
// 否则每个 section 都会向子组件传一个插槽，$slots 里存在该插槽，
// 子组件的后备内容就永远不会显示，只会渲染一个空的 <p>。
const availableSections = computed(() => sections.value.filter((section) => section in contentMap))
</script>
