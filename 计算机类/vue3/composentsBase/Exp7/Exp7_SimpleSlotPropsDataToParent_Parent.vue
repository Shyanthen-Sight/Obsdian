<template>
  <Child v-slot="{ user }">
    <p>姓名：{{ user.name }}，年龄：{{ user.age }}</p>
  </Child>
</template>

<script setup>
import Child from './Exp7_SimpleSlotPropsDataToParent_Child.vue'
// 子组件 <slot :user="user" /> 把整个对象作为一个插槽 prop 传出去。
// 父组件 v-slot="{ user }" 解构出 user 对象，再用 user.name、user.age 访问字段。
// 运行结果：页面显示"姓名：张三，年龄：25"。
// 如果不想先解构，也可以写 v-slot="slotProps"，然后用 slotProps.user.name 访问。
</script>
