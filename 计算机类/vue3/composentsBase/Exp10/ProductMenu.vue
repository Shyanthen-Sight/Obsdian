<template>
  <h1>动态组件</h1>
  <div class="box">
    <ul>
      <li
        v-for="item in tabList"
        :key="item.title"
        :class="['tab-button', { active: currentTab === item.title }]"
        @click="currentTab = item.title"
      >
        {{ item.displayName }}
      </li>
    </ul>

    <keep-alive>
      <component :is="currentComponent" class="tab" />
    </keep-alive>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import Home from './Home.vue'
import User from './User.vue'
import Commodity from './Commodity.vue'
import Order from './Order.vue'

const currentTab = ref('home')

// 组件映射：title -> 组件
const componentMap = {
  home: Home,
  user: User,
  commodity: Commodity,
  order: Order,
}

const tabList = [
  { title: 'home', displayName: '首页' },
  { title: 'user', displayName: '用户管理' },
  { title: 'commodity', displayName: '商品管理' },
  { title: 'order', displayName: '订单管理' },
]

// 根据 currentTab 动态计算要渲染的组件
const currentComponent = computed(() => componentMap[currentTab.value])
</script>

<style>
.box {
  width: 300px;
  display: flex;
  justify-content: flex-start;
}
ul {
  display: flex;
  justify-content: flex-start;
  flex-direction: column;
  padding: 0;
  margin: 0;
}
.tab-button {
  padding: 6px 10px;
  border-top-left-radius: 3px;
  border-top-right-radius: 3px;
  border: solid 1px #ccc;
  cursor: pointer;
  background: #f0f0f0;
  margin-bottom: -1px;
  margin-right: -1px;
  list-style: none;
}
.tab-button:hover {
  background: #8a9dbe;
}
.active {
  background: #8a9dbe;
}
.tab {
  border: solid 1px #ccc;
  padding: 10px;
}
</style>
