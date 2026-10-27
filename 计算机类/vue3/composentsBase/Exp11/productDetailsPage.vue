<script setup>
//书本上原示例用 provide 抛出 tabList、$root 取数据，
// 这里改为 provide + inject（Vue 3 推荐），
// 并把商品信息、购物车数量做成响应式。

import { ref, provide } from 'vue'
import Introduce from './Introduce.vue'
import Pack from './Pack.vue'
import After from './After.vue'

// 购物车数量
const cartnum = ref(1)

// 商品信息
const pear = ref({
  id: 1,
  title: '河北皇冠梨生鲜水果',
  price: 39.9,
  promotion: '满99-30',
})

// tab 列表（原示例 tabList）
const tabList = ref([
  {
    title: 'introduce',
    content: {
      barnd: 'QF',
      type: '皇冠梨',
      bunmber: 123456,
      placeProduction: '河北',
      storageConditions: '冷藏',
      imgSrc: './img/pear1.jpg',
    },
    displayName: '商品详情',
  },
  {
    title: 'pack',
    content: {
      main: '皇冠梨',
      weight: '2.5kg',
      inventory: '河北皇冠梨 2.5kg装*1',
    },
    displayName: '包装与规格',
  },
  {
    title: 'after',
    content: {
      settlement: '理赔绿色通道',
      stxt: '优理赔服务是为等级2及以上的优质客户提供的售后特色服务, 符合条件的生鲜自营订单商品有破损或腐坏等问题, 可以在商品签收后48小时内提交优理赔申请,提交申请后100分钟内审核通过后即享补偿或退款,无需返回商品，为客户节省了返回商品的物流等待时间和收货检测的处理时间。',
      customer: '专业生鲜客服团队—让您售后无忧',
      ctxt: '微信在线客服：XX-fresh,生鲜客服电话：400-606-3311,服务时间：09:00-24:00。',
    },
    displayName: '售后服务',
  },
])

// 用于保存当前单击的组件名称
const currentTab = ref('introduce')

// 动态组件映射表
const tabComponents = {
  introduce: Introduce,
  pack: Pack,
  after: After,
}

// 依赖注入抛出根组件数据（与原示例 provide 对应）
provide('tabList', tabList)
</script>

<template>
  <h1>商品详情页</h1>

  <div class="headerbox">
    <img src="./img/main_img.jpg" alt="" />
    <div class="content">
      <h2>{{ pear.title }}</h2>
      <p>价格：{{ pear.price }}</p>
      <p>促销：{{ pear.promotion }}</p>
      <div class="cart" @click="cartnum++">加入购物车</div>
      <div class="cartbox">
        <img src="./img/jd2015img.png" alt="" />
        <span>{{ cartnum }}</span>
      </div>
    </div>
  </div>

  <div class="trendsComponent">
    <ul>
      <li
        v-for="tab in tabList"
        :key="tab.title"
        :class="['tab-button', { active: currentTab === tab.title }]"
        @click="currentTab = tab.title"
      >
        {{ tab.displayName }}
      </li>
    </ul>
    <keep-alive>
      <component :is="tabComponents[currentTab]" class="tab" />
    </keep-alive>
  </div>
</template>

<style>
body,
#app {
  width: 300px;
}

/* 头部 */
.headerbox {
  width: 500px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.headerbox img {
  width: 240px;
  height: 240px;
}

.content {
  display: flex;
  flex-direction: column;
  margin-left: 30px;
}

.content h2 {
  width: 300px;
}

.cart {
  width: 150px;
  background-color: #df3033;
  color: #fff;
  height: 46px;
  line-height: 46px;
  padding: 0 26px;
  font-size: 18px;
  font-family: 'microsoft yahei';
  text-align: center;
  cursor: pointer;
}

/* 购物车数量 */
.cartbox {
  position: absolute;
  top: 10px;
  right: 10px;
  display: flex;
  justify-content: center;
}

.cartbox img {
  width: 30px;
  height: 30px;
}

.cartbox span {
  background-color: #df3033;
  color: #fff;
  display: inline-block;
  border-radius: 50%;
  width: 18px;
  height: 18px;
  text-align: center;
  line-height: 16px;
}

/* 动态组件区域 */
.trendsComponent {
  width: 480px;
  margin-top: 20px;
}

.trendsComponent > ul {
  display: flex;
  margin: 0;
  padding: 0;
}

.trendsComponent > ul li {
  list-style: none;
  width: 140px;
  border-bottom: #df3033 solid 2px;
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
  text-align: center;
}

.tab-button:hover {
  background: #e0e0e0;
}

.active {
  background: #df3033;
  color: white;
}

.tab {
  border: solid 1px #ccc;
  padding: 10px;
}
</style>
