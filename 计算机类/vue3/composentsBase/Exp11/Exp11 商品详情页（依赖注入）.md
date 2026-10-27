# Exp11 商品详情页（依赖注入）

> [!abstract] 一句话
> 一个完整的商品详情页把前面几篇的能力串起来：`provide/inject` 跨层传数据、`props` 父子传值、动态组件 + `<keep-alive>` 切换标签、具名作用域插槽把售后文案交回父级渲染。==这是"组件组合"的综合练习，不是新 API 的单点演示。==

📁 源码：`Exp11/productDetailsPage.vue`、`Exp11/Introduce.vue`、`Exp11/IntroduceHeader.vue`、`Exp11/Pack.vue`、`Exp11/After.vue`、`Exp11/AfterTitle.vue`

---

## 一、组件树与职责

```text
productDetailsPage.vue（根，provide('tabList')）
├── 头部：商品图 / 标题 / 价格 / 促销 / 加入购物车
└── 标签区：动态组件 + keep-alive
    ├── Introduce.vue           商品详情
    │   ├── IntroduceHeader.vue  props: content
    │   └── <img :src="content.imgSrc">
    ├── Pack.vue                包装与规格
    └── After.vue               售后服务
        └── AfterTitle.vue      具名作用域插槽 → 回传 sx / cx
```

| 文件 | 职责 | 用到的能力 |
| --- | --- | --- |
| `productDetailsPage.vue` | 根组件，持有并下发 `tabList` | `provide`、动态组件、`keep-alive` |
| `Introduce.vue` | 详情页，取第 0 项数据 | `inject`、`props` |
| `IntroduceHeader.vue` | 只负责渲染规格列表 | `defineProps` |
| `Pack.vue` | 包装页，取第 1 项数据 | `inject`、`computed` |
| `After.vue` | 售后页，接收插槽数据 | 具名作用域插槽 |
| `AfterTitle.vue` | 售后标题与长文案，向外抛数据 | `inject`、`<slot :sx>` |

---

## 二、根组件：productDetailsPage.vue

### 2.1 模板

```vue
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
```

### 2.2 脚本

```vue
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
      stxt: '优理赔服务是为等级2及以上的优质客户提供的售后特色服务……',
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
```

> [!info] 样式
> 根组件还带有约 120 行 `<style>`（头部布局、购物车角标、标签按钮、选中态等），与知识点无关，完整内容见源码 `Exp11/productDetailsPage.vue`。

### 2.3 模板里的两个自动解包

```vue
v-for="tab in tabList"
:is="tabComponents[currentTab]"
```

- `tabList` 是 `ref`，**模板里自动解包**，所以直接写 `tabList` 而不是 `tabList.value`。
- `currentTab` 同理，`tabComponents[currentTab]` 实际拿到的是 `tabComponents[currentTab.value]`。

> [!tip] 记忆规则
> **`<script>` 里用 `.value`，`<template>` 里不用。** 只有一种例外：把 ref 塞进普通对象/数组再在模板里访问深层属性时，解包可能失效——这时优先把 ref 保持为顶层变量。

### 2.4 `cartnum++` 直接写在模板里

```vue
<div class="cart" @click="cartnum++">加入购物车</div>
```

模板表达式里对 ref 自增，Vue 自动处理 `.value`。点击后右上角角标同步变化。

---

## 三、跨层传数据：provide / inject

### 3.1 为什么不用 props 一层层传

`tabList` 要被 `Introduce`、`Pack`、`AfterTitle` 使用，其中 `AfterTitle` 已经隔了两层：

```text
productDetailsPage → After → AfterTitle
```

若用 props，就要 `After` 收下 `tabList` 再原样传下去——这叫 **props 逐层透传（prop drilling）**，中间组件被迫知道并使用自己根本不需要的数据。

### 3.2 provide / inject 的做法

祖先：

```js
provide('tabList', tabList)
```

后代（任意深度）：

```js
const tabList = inject('tabList')
```

```text
productDetailsPage ──provide('tabList')──▶ 供给
       │
       ├── Introduce ──inject──▶ 拿到
       ├── Pack      ──inject──▶ 拿到
       └── After
            └── AfterTitle ──inject──▶ 拿到（跨层）
```

> [!important] 注入的是 ref 本身
> `provide('tabList', tabList)` 传的是 **ref 对象**，不是它的值。所以：
> - 后代在 `<script>` 里必须写 `tabList.value[...]`；
> - 后代在 `<template>` 里直接写 `tabList[...]`（自动解包）。
>
> 正因为注入的是 ref，数据变化才能保持响应式。如果 `provide('tabList', tabList.value)`，后代拿到的只是快照。

### 3.3 响应式与只读

- `provide` 一个 `ref` / `reactive` 对象 → 后代读取是响应式的。
- 后代**不应该直接改**祖先数据；需要修改时，祖先应同时 provide 一个修改函数：

```js
provide('tabList', tabList)
provide('updateTab', (index, patch) => {
  Object.assign(tabList.value[index].content, patch)
})
```

> [!warning] inject 找不到 key 不会报错
> 找不到时返回 `undefined`，随后访问 `.value` 才会抛错。可用第二个参数给默认值：
> ```js
> const tabList = inject('tabList', ref([]))
> ```

---

## 四、三个子组件怎么取数据

### 4.1 Introduce：模板里直接解包

```vue
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
```

注意 `tabList[0]` 只在模板里出现，模板自动解包，所以**没有** `.value`。若把取值写进脚本，就必须 `tabList.value[0]`。

### 4.2 IntroduceHeader：纯 props 展示

```vue
<script setup>
defineProps({
  content: {
    type: Object,
    required: true,
  },
})
// 通过 props 接收 content
</script>

<template>
  <div>
    <ul class="introUl">
      <li>品牌：{{ content.barnd }}</li>
      <li>品种：{{ content.type }}</li>
      <li>编号：{{ content.bunmber }}</li>
      <li>产地：{{ content.placeProduction }}</li>
      <li>贮存条件：{{ content.storageConditions }}</li>
    </ul>
  </div>
</template>
```

`IntroduceHeader` 不关心数据从哪来，只声明"我需要一个 `content` 对象"。这是典型的**展示型组件**：数据来源与外层解耦。

> [!warning] 源文件有两处拼写错误
> - `barnd` 应为 `brand`
> - `bunmber` 应为 `number`
>
> 它们与数据定义的键名一致，所以能正常运行，但属于命名笔误。

### 4.3 Pack：脚本里用 computed + `.value`

```vue
<script setup>
import { inject, computed } from 'vue'

const tabList = inject('tabList')
const content = computed(() => tabList.value[1].content)
// 注意：inject('tabList') 拿到的是根组件的 ref，
// 所以取值时用 tabList.value。
// 这依赖根组件 provide('tabList', tabList) 提供的是 ref 本身。
</script>

<template>
  <div>
    <ul class="introUl">
      <li>主体：{{ content.main }}</li>
      <li>重量：{{ content.weight }}</li>
      <li style="width: 300px">包装清单：{{ content.inventory }}</li>
    </ul>
  </div>
</template>
```

这里 `content` 是 `computed`，模板里自动解包成对象，所以写 `content.main`。

> [!tip] 这里其实可以不做 computed
> `tabList.value[1].content` 本身在 `tabList` 变化时就会重新求值；`computed` 的价值在于把"取第 1 项内容"这个派生逻辑命名并缓存。数据是静态的，两种写法效果一样。

---

## 五、动态组件 + keep-alive

与 [[Exp10 动态组件]] 同一套模式：

```js
const currentTab = ref('introduce')
const tabComponents = {
  introduce: Introduce,
  pack: Pack,
  after: After,
}
```

```vue
<keep-alive>
  <component :is="tabComponents[currentTab]" class="tab" />
</keep-alive>
```

| 环节 | 代码 | 说明 |
| --- | --- | --- |
| 当前标签 | `currentTab` | 点击 `<li>` 改写 |
| 状态 → 组件 | `tabComponents[currentTab]` | 对象查表，模板自动解包 |
| 缓存 | `<keep-alive>` | 切回标签时保留组件状态 |
| 高亮 | `{ active: currentTab === tab.title }` | 当前项加类名 |

> [!success] 为什么详情页要缓存
> 用户从"商品详情"切到"包装与规格"再切回来，`Introduce` 里的图片不必重新加载，组件内部状态也不会丢。商品详情页的标签切换频率高，缓存收益明显。

---

## 六、具名作用域插槽：After 与 AfterTitle

### 6.1 AfterTitle：从注入数据里取售后文案，并向外抛

```vue
<script setup>
// 含具名作用域插槽，向父组件传递数据。

import { inject } from 'vue'

const tabList = inject('tabList')
const content = tabList.value[2].content
</script>

<template>
  <div>
    <p class="after_p">{{ content.settlement }}</p>
    <slot name="settlement" :sx="content.stxt"></slot>
    <p class="after_p">{{ content.customer }}</p>
    <slot name="customer" :cx="content.ctxt"></slot>
  </div>
</template>

<style scoped>
.after_p {
  font-weight: bold;
  color: #5b595958;
}
</style>
```

这里 `content` 是在脚本里取值的，所以必须 `.value`。取完后是普通对象，模板里直接 `content.settlement`。

两个具名插槽分别携带 `sx`、`cx` 两个字段：

```vue
<slot name="settlement" :sx="content.stxt"></slot>
<slot name="customer" :cx="content.ctxt"></slot>
```

### 6.2 After：父级消费插槽数据

```vue
<script setup>
// 使用作用域插槽接收子组件数据。

import AfterTitle from './AfterTitle.vue'
</script>

<template>
  <div>
    <AfterTitle>
      <template #settlement="slotSettlement">
        <p>{{ slotSettlement.sx }}</p>
      </template>
      <template #customer="slotCustomer">
        <p>{{ slotCustomer.cx }}</p>
      </template>
    </AfterTitle>
  </div>
</template>
```

| 写法 | 含义 |
| --- | --- |
| `#settlement="slotSettlement"` | 接住整个插槽 props 对象，命名为 `slotSettlement` |
| `{{ slotSettlement.sx }}` | 取其中 `sx` 字段 |
| `#settlement="{ sx }"` | 等价写法，直接解构 |

> [!info] 与 Exp8 的关系
> 结构完全相同：子组件 `<slot name="x" :field="value">`，父组件 `<template #x="{ field }">`。
> 区别只在于本例的长文案来自 `inject`，而 Exp8 的数据来自子组件自己的 `ref`。**数据从哪来不影响插槽语法。**

### 6.3 为什么不直接在 AfterTitle 里渲染

源码把长文案通过插槽交回 `After` 渲染，实际效果与直接写在 `AfterTitle` 里一样。这种写法通常用于：

- 文案要允许外层加高亮、折叠、链接等结构；
- 同一份数据在不同页面要有不同排版；
- 组件库把"布局"与"内容"分离。

本例主要是教学演示：**跨层注入 + 具名作用域插槽可以同时存在**。

---

## 七、完整数据流

```text
productDetailsPage
│  pear / cartnum / tabList / currentTab
│  provide('tabList', tabList)
│
├── 头部直接渲染 pear、cartnum
│
├── Introduce ──inject──▶ tabList[0]
│     └── IntroduceHeader ◀──props content── 展示规格
│
├── Pack ──inject──▶ tabList.value[1]（computed）
│
└── After ──inject 间接──▶ tabList[2]
      └── AfterTitle
            ├── <slot name="settlement" :sx="stxt"> ──▶ After 渲染 sx
            └── <slot name="customer" :cx="ctxt">   ──▶ After 渲染 cx
```

> [!success] 一张图看懂
> **纵向**用 `provide/inject` 把数据送到深处，**横向**用 `props` 把数据交给展示组件，**反向**用作用域插槽把内容控制权交回父级。三种方向各司其职。

---

## 八、易错点与源码问题

| 位置 | 问题 | 说明 |
| --- | --- | --- |
| `productDetailsPage.vue` | `./img/main_img.jpg`、`./img/jd2015img.png` | 源目录 `Exp11/img/` 为空，运行会 404 |
| `productDetailsPage.vue` | `imgSrc: './img/pear1.jpg'` | 同上，图片不存在 |
| `Introduce.vue` | `tabList[0]` 无 `.value` | 只在模板中使用，自动解包，没问题；挪进脚本要补 `.value` |
| `IntroduceHeader.vue` | `barnd`、`bunmber` | 拼写错误，但键名一致，不影响运行 |
| `Pack.vue` | `tabList.value[1]` | 脚本中必须 `.value`，漏写会报错 |
| `AfterTitle.vue` | `tabList.value[2]` | 同上 |
| `productDetailsPage.vue` | `<style>` 未加 `scoped` | 全局样式，可能影响其他组件 |

> [!warning] 想直接运行
> 要么补三张图片到 `Exp11/img/`，要么把 `img` 的 `src` 换成已有资源或删掉。否则控制台会有一串资源加载失败（不影响其他逻辑）。

其他易错点：

- [ ] `provide` 放在 `await` 之后 → 必须在 `setup` 同步阶段调用
- [ ] `provide('tabList', tabList.value)` → 丢失响应式
- [ ] 后代脚本里写 `tabList[0]` → 应为 `tabList.value[0]`
- [ ] `<keep-alive>` 包在 `<component>` 内层 → 无效
- [ ] 插槽名 `#settlement` 写成 `#Settlement` → 匹配失败
- [ ] `defineProps` 写成 `const props = defineProps(...)` 却没用到 `props` → 只是冗余，不报错

---

## 九、自测

1. `provide('tabList', tabList)` 与 `provide('tabList', tabList.value)` 有什么区别？
2. `Introduce.vue` 模板里为什么可以写 `tabList[0]`，而 `Pack.vue` 脚本里必须写 `tabList.value[1]`？
3. `AfterTitle` 的两个具名插槽分别传了什么字段？父组件如何接收？
4. 如果把 `AfterTitle` 里的 `content` 改成 `computed`，模板要不要改？
5. 商品详情页切换标签时，为什么输入状态/图片不会丢？
6. `IntroduceHeader` 换成从 `inject` 直接取数据，会失去什么？

> [!success]- 参考答案
> 1. 前者注入 ref 本身，后代读取保持响应式；后者注入的是当时的值快照，后续 `tabList` 变化不会同步。
> 2. 模板里的顶层 ref 会自动解包；`<script>` 中不会，必须显式 `.value`。
> 3. `#settlement` 传 `sx="content.stxt"`，`#customer` 传 `cx="content.ctxt"`；父组件用 `<template #settlement="slotSettlement">` 接整个对象，或 `#settlement="{ sx }"` 解构。
> 4. 不用。模板会自动解包 `computed`，仍然写 `content.settlement`。
> 5. 因为外层 `<keep-alive>` 缓存了组件实例，切走只触发 `deactivated`，不销毁。
> 6. 会失去"展示型组件"的解耦：组件被迫依赖外层的注入键，复用性和可测试性下降。props 让数据来源显式化。

---

## 十、关联

- 前一篇：[[Exp10 动态组件]]
- 动态组件基础：[[Exp10 动态组件]]
- 插槽基础：[[Exp8 具名作用域插槽]]、[[Exp7 作用域插槽]]
- props：[[Exp1 父传子 props]]
- 总览：[[00 组件通信与插槽总览]]
