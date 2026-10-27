# Exp10 动态组件

> [!abstract] 一句话
> 用 `<component :is="组件">` 让**同一个位置**按状态切换渲染不同组件，再用 `<keep-alive>` 把切走的组件缓存起来。==后台管理系统的标签页切换，就是"动态组件 + 缓存"最典型的落地场景。==

📁 源码：`Exp10/ProductMenu.vue`、`Exp10/Home.vue`、`Exp10/User.vue`、`Exp10/Commodity.vue`、`Exp10/Order.vue`

---

## 一、完整源码

### 1.1 容器：ProductMenu

```vue
<!-- ProductMenu.vue -->
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
```

### 1.2 四个页面组件

```vue
<!-- Home.vue -->
<template>
  <div>欢迎进入后台管理系统</div>
</template>

<script setup></script>
```

```vue
<!-- Commodity.vue -->
<template>
  <div>商品管理页面</div>
</template>

<script setup></script>
```

```vue
<!-- Order.vue -->
<template>
  <div>订单管理页面</div>
</template>

<script setup></script>
```

```vue
<!-- User.vue -->
<template>
  <div>
    <input v-model="username" /><br />
    <input type="password" v-model="password" />
  </div>
</template>

<script setup>
import { ref } from 'vue'

const username = ref('admin')
const password = ref(123456)
</script>
```

---

## 二、渲染结构与数据流

```text
ProductMenu
│
├── tabList ──v-for──▶ <li> 四个标签
│                         │ click
│                         ▼
│                   currentTab = 'user'
│                         │
│                         ▼
│              currentComponent = componentMap['user']
│                         │
│                         ▼
└── <keep-alive>
      <component :is="currentComponent" />
            │
            ▼
        渲染 User.vue
```

关键点：**标签只负责改一个字符串**，真正决定渲染谁的是 `componentMap` 查表。

---

## 三、语法拆解

### 3.1 `<component :is>`

```vue
<component :is="currentComponent" class="tab" />
```

| 部分 | 作用 |
| --- | --- |
| `<component>` | Vue 内置的"占位"组件 |
| `:is` | 传组件对象、组件名或 HTML 标签名 |
| `currentComponent` | 一个**组件对象**（来自映射表） |
| `class="tab"` | 透传到被渲染组件的根元素上 |

> [!important] `:is` 的值类型
> 可以传：
> - 组件对象：`componentMap[currentTab.value]`
> - 全局注册的组件名字符串：`:is="'User'"`（需要已全局注册）
> - 原生标签名：`:is="'div'"`
>
> 本例传的是**组件对象**，所以不依赖全局注册，tree-shaking 也友好。

### 3.2 映射表 + computed

```js
const componentMap = {
  home: Home,
  user: User,
  commodity: Commodity,
  order: Order,
}

const currentComponent = computed(() => componentMap[currentTab.value])
```

`currentTab` 是 `ref`，所以 JS 里取值必须写 `currentTab.value`；`currentComponent` 用 `computed` 派生，`currentTab` 一变它就重算。

> [!tip] 为什么不用 `v-if` 链
> ```vue
> <Home v-if="currentTab === 'home'" />
> <User v-else-if="currentTab === 'user'" />
> ...
> ```
> 也能跑，但每加一个页面就要改模板，而且所有分支都写在模板里。
> **映射表把"状态 → 组件"的关系收进一个对象**，新增页面只加一行映射，模板永远不变。

### 3.3 标签的激活态

```vue
:class="['tab-button', { active: currentTab === item.title }]"
```

数组语法里混对象语法：`tab-button` 恒生效，`active` 只在当前项生效。

```js
@click="currentTab = item.title"
```

模板里直接给 `ref` 赋值，Vue 会自动写 `.value`，不用写 `currentTab.value = ...`。

---

## 四、`<keep-alive>` 在做什么

默认情况下，`<component :is>` 切换时旧组件会被**销毁**（`unmounted`），新组件**重新创建**（`mounted`）。如果组件里有输入框内容、滚动位置、请求结果，切回来就全没了。

`<keep-alive>` 把切走的组件实例缓存起来：

```text
首次进入 User  → 创建 → mounted
切到 Home      → User 触发 deactivated（不销毁）
切回 User      → User 触发 activated（不重新创建）
```

> [!info] 本例没有写生命周期钩子
> 源码只用了 `<keep-alive>` 外壳，没有 `onActivated` / `onDeactivated`。
> 你可以自己加上验证：
> ```js
> import { onActivated, onDeactivated, onMounted, onUnmounted } from 'vue'
>
> onMounted(() => console.log('mounted'))
> onActivated(() => console.log('activated'))
> onDeactivated(() => console.log('deactivated'))
> onUnmounted(() => console.log('unmounted'))
> ```
> 切换标签时会看到 `deactivated`，而不是 `unmounted`。

### 4.1 常用属性

| 属性 | 作用 |
| --- | --- |
| `include` | 只缓存名字匹配的组件（字符串 / 正则 / 数组） |
| `exclude` | 排除不缓存的组件 |
| `max` | 最多缓存几个实例，超出按 LRU 淘汰 |

```vue
<keep-alive :include="['User']" :max="5">
  <component :is="currentComponent" />
</keep-alive>
```

> [!warning] `include` 匹配的是组件 `name`
> `<script setup>` 组件默认没有显式 `name`，需要 `defineOptions({ name: 'User' })` 才能被 `include` 稳定匹配。

### 4.2 缓存不是越多越好

缓存会保留组件实例及其数据，长期不清理会占用内存。后台系统通常配合 `max` 或只缓存关键页面。

---

## 五、`User.vue` 里的 `v-model`

```vue
<input v-model="username" />
<input type="password" v-model="password" />
```

`v-model` 在原生输入框上是 `:value` + `@input` 的语法糖。`password` 初始值是数字 `123456`，输入后会被替换成字符串——这是输入框的正常行为，不是 bug。

> [!tip] 密码框只做展示
> 这里没有登录逻辑，`username` / `password` 只是演示"组件内部自己的状态"。切换到别的标签再切回来，因为 `keep-alive`，输入内容仍然保留。

---

## 六、与路由的关系

动态组件和 Vue Router 经常被拿来对比：

| 对比项 | 动态组件 | Vue Router |
| --- | --- | --- |
| 切换依据 | 组件内一个变量 | URL |
| 是否改地址栏 | 否 | 是 |
| 是否可前进/后退 | 否 | 是 |
| 适用 | 页内标签页、向导步骤 | 真正的页面导航 |

> [!info] `<router-view>` 本质也是动态组件
> 路由出口内部同样用 `<component :is>` 渲染匹配到的路由组件，并常配合 `<keep-alive>` 缓存页面。

---

## 七、易错点清单

- [ ] `:is="componentMap[currentTab]"` → `currentTab` 是 ref，脚本里必须写 `.value`（模板里会自动解包）
- [ ] 映射表里写成 `home: 'Home'` 但组件没全局注册 → 渲染失败
- [ ] 把 `<keep-alive>` 写在 `<component>` 里面 → 无效，它必须是外层
- [ ] `include` 用文件名匹配 → 实际匹配组件 `name`，`<script setup>` 需 `defineOptions`
- [ ] 切换后数据丢失 → 忘了 `<keep-alive>`
- [ ] `v-for` 的 `:key` 用了 `displayName` → 应使用稳定唯一值（本例 `title`）
- [ ] 在 `computed` 里写 `currentTab = ...` → 只读派生值，不能赋值

---

## 八、自测

1. `<component :is="currentComponent" />` 中 `currentComponent` 可以是什么类型？
2. 为什么 `currentComponent` 要用 `computed`，直接写 `componentMap[currentTab]` 行不行？
3. `<keep-alive>` 缓存后，组件切换时会触发哪些生命周期？
4. `include="User"` 为什么可能不生效？
5. 新增一个"设置"页面，需要改哪些地方？

> [!success]- 参考答案
> 1. 组件对象、全局注册的组件名字符串、或原生标签名字符串。
> 2. 直接写 `componentMap[currentTab]` 拿到的是 ref 对象本身，不是当前值；而且它不是响应式的派生值，`currentTab` 变化不会触发重新渲染。`computed` 会自动追踪 `currentTab.value` 并缓存结果。
> 3. 首次 `mounted`；切走 `deactivated`；切回 `activated`；只有从缓存中移除/组件卸载时才 `unmounted`。
> 4. `include` 匹配组件的 `name` 选项，`<script setup>` 默认没有稳定 `name`，需要 `defineOptions({ name: 'User' })`。
> 5. 新建 `Settings.vue`；在 `componentMap` 加 `settings: Settings`；在 `tabList` 加 `{ title: 'settings', displayName: '设置' }`；模板不用改。

---

## 九、关联

- 前一篇：[[Exp8 具名作用域插槽]]
- 下一篇：[[Exp11 商品详情页（依赖注入）]]
- 总览：[[00 组件通信与插槽总览]]
- 基础回顾：[[组件注册]]、[[引用注册]]
