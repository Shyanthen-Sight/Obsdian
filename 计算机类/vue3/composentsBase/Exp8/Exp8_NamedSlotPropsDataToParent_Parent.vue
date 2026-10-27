<template>
  <Child>
    <template #user="{ user }">
      <p>姓名：{{ user.name }}，年龄：{{ user.age }}</p>
    </template>

    <template #info="{ info }">
      <p>城市：{{ info.city }}，职业：{{ info.job }}</p>
    </template>
  </Child>
</template>

<script setup>
import Child from './Exp8_NamedSlotPropsDataToParent_Child.vue'
</script>
