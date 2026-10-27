<template>
  <p class="child-info">{{ id }} - {{ name }} - {{ sex }} - {{ loginMethod }}</p>
</template>

<script setup>
// 定义 props 及校验规则
const props = defineProps({
  // 基础类型校验，null 和 undefined 会通过任何类型的校验
  id: Number,
  // 必填性验证
  name: {
    type: [String, Number], // 多类型
    required: true,
  },
  // 默认值设置
  sex: {
    type: String,
    default: '男',
  },
  // 自定义验证函数
  loginMethod: {
    validator: function (value) {
      return ['Tel', 'QQ', 'WeChat'].indexOf(value) !== -1
    },
  },
})
</script>

<style scoped>
.child-info {
  font-size: 1.2rem;
  color: #42b983;
  font-weight: 600;
  margin: 0;
}
</style>
