<template>
  <div>
    <!-- 给元素添加 ref 属性 -->
    <input ref="inputRef" type="text" placeholder="请输入内容" />
    <button @click="focusInput">聚焦输入框</button>
    <button @click="getInputValue">获取输入值</button>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

// 声明一个与 ref 属性同名的变量
// 在 Vue3中，模板引用通过 ref 属性实现，需要配合 ref() 函数使用。
const inputRef = ref(null)

// 组件挂载后可以访问到 DOM 元素
onMounted(() => {
  console.log('输入框元素:', inputRef.value)
  inputRef.value.focus() // 自动聚焦
})

function focusInput() {
  inputRef.value?.focus()
}
/*
  //通过 ?. 做空值保护，确保在 DOM 尚未渲染（value 为 null）时不会抛出错误，使代码更健壮。
  //这是 Vue 3 中操作模板引用的标准安全写法。

  // 写法一：可选链（推荐，简洁）
  inputRef.value?.focus()

  // 写法二：逻辑与短路
  inputRef.value && inputRef.value.focus()

  // 写法三：if 判断
  if (inputRef.value) {
    inputRef.value.focus()
  }
  */

function getInputValue() {
  alert('输入的内容是：' + inputRef.value.value)
}
</script>
