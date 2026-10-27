# Exp7 作用域插槽

> [!abstract] 一句话
> 普通插槽是"父组件出结构，但只能用父组件自己的数据"；作用域插槽让**子组件把内部数据通过 `<slot :xxx="...">` 传给父组件的插槽内容**，父组件用 `v-slot="{ xxx }"` 接住。==结构仍由父组件写，数据由子组件给——这是"子传父"在模板层的另一种形态。==

📁 源码：`Exp7/Exp7_SimpleSlotPropsDataToParent_*.vue`（极简版）、`Exp7/Exp7_SlotPropsDataToParent_*.vue`（列表版）

---

## 一、极简版：传一个对象

### 1.1 子组件

```vue
<!-- Exp7_SimpleSlotPropsDataToParent_Child.vue -->
<template>
  <slot :user="user" />
</template>

<script setup>
import { ref } from 'vue'
const user = ref({ name: '张三', age: 25 })
</script>
```

### 1.2 父组件

```vue
<!-- Exp7_SimpleSlotPropsDataToParent_Parent.vue -->
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
```

### 1.3 渲染结果

```text
姓名：张三，年龄：25
```

---

## 二、核心机制

```text
子组件
  user = { name: '张三', age: 25 }
        │
        │  <slot :user="user" />
        │  （把 user 作为"插槽 prop"暴露出去）
        ▼
父组件
  <Child v-slot="{ user }">
    {{ user.name }}          ← 这里的 user 来自子组件
  </Child>
```

> [!important] 插槽 prop 不是组件的 props
> - 组件 props：父 → 子，写在组件标签上。
> - 插槽 props：子 → 父（的插槽内容），写在 `<slot>` 上。
>
> 方向相反，名字相似，别混。

### 2.1 为什么需要它

普通插槽的内容在**父组件作用域**编译，拿不到子组件内部数据：

```vue
<!-- ❌ 父组件里根本不存在 user -->
<Child>
  <p>{{ user.name }}</p>
</Child>
```

子组件必须"主动把数据递出来"，父组件才能用：

```vue
<!-- ✅ 子组件递，父组件接 -->
<slot :user="user" />
```

> [!success] 一句话
> **作用域插槽 = 父组件决定"长什么样"，子组件提供"用什么数据长"。**

---

## 三、两种接收写法

```vue
<!-- 1. 解构（推荐，字段少时清晰） -->
<Child v-slot="{ user }">
  {{ user.name }}
</Child>

<!-- 2. 拿整个对象（字段多或要传递给其他函数时） -->
<Child v-slot="slotProps">
  {{ slotProps.user.name }}
</Child>

<!-- 3. 重命名解构 -->
<Child v-slot="{ user: person }">
  {{ person.name }}
</Child>
```

> [!tip] `v-slot` 写在组件上 = 默认插槽
> `<Child v-slot="{ user }">` 等价于：
> ```vue
> <Child>
>   <template #default="{ user }">…</template>
> </Child>
> ```
> 因此它只适用于**默认插槽**；具名插槽要写 `#名字="{ ... }"`（见 [[Exp8 具名作用域插槽]]）。

---

## 四、列表版：传多个值

### 4.1 子组件

```vue
<!-- Exp7_SlotPropsDataToParent_Child.vue -->
<template>
  <ul class="todo-list">
    <li v-for="(todo, index) in todos" :key="todo.id">
      <!-- 默认插槽：把 todo 和 index 作为插槽 props 暴露给父组件 -->
      <slot :item="todo" :index="index">
        <!-- 后备内容：父组件没传插槽时显示 -->
        {{ todo.text }}
      </slot>
    </li>
  </ul>
</template>

<script setup>
import { ref } from 'vue'

const todos = ref([
  { id: 1, text: '学习 Vue 3', done: true },
  { id: 2, text: '写作用域插槽示例', done: false },
  { id: 3, text: '复习文档', done: false },
])
</script>

<style scoped>
.todo-list { list-style: none; padding: 0; }
.todo-list li { padding: 6px 0; border-bottom: 1px dashed #eee; }
</style>
```

### 4.2 父组件

```vue
<!-- Exp7_SlotPropsDataToParent_Parent.vue -->
<template>
  <div>
    <h4>默认作用域插槽（简写 v-slot）</h4>
    <TodoList v-slot="{ item, index }">
      <span>[{{ index + 1 }}]</span>
      <span :class="{ done: item.done }">{{ item.text }}</span>
      <span>{{ item.done ? '✅' : '⬜' }}</span>
    </TodoList>

    <h4>显式 #default</h4>
    <TodoList>
      <template #default="{ item, index }">
        <strong>#{{ index + 1 }}</strong>
        <em>{{ item.text }}</em>
      </template>
    </TodoList>
  </div>
</template>

<script setup>
import TodoList from './Exp7_SlotPropsDataToParent_Child.vue'
</script>

<style scoped>
.done { color: #999; text-decoration: line-through; }
</style>
```

### 4.3 渲染结果

第一组：

```text
[1] 学习 Vue 3 ✅        （done 项带删除线）
[2] 写作用域插槽示例 ⬜
[3] 复习文档 ⬜
```

第二组：

```text
#1 学习 Vue 3
#2 写作用域插槽示例
#3 复习文档
```

> [!info] 同一个子组件，两种外观
> 子组件只负责"循环 + 暴露数据"，父组件决定每一项怎么排版。这就是作用域插槽最典型的价值：**逻辑复用，外观自由**。

---

## 五、子组件侧：`<slot>` 上能写什么

```vue
<slot
  :item="todo"
  :index="index"
  :done="todo.done"
/>
```

- 任意数量的 `:prop="value"`，都会合并成一个"插槽 props 对象"。
- 名字随意，父组件按名字解构。
- 传 `ref` 时，模板中会自动解包（如 `:user="user"` 传的是对象，不是 Ref）。
- 可以同时给默认插槽和具名插槽传不同的数据。

> [!warning] 不要用 `name` 作为数据字段
> `name` 是 `<slot>` 自己的保留属性（插槽名）。想传名字请改用 `:user-name`、`:title` 等，否则会被当成插槽名。

---

## 六、后备内容 + 作用域

```vue
<slot :item="todo" :index="index">
  {{ todo.text }}
</slot>
```

父组件没提供插槽内容时，显示 `todo.text`；提供了就用父组件的模板。

> [!important] 后备内容也在子组件作用域
> 后备内容写在子组件模板里，自然能访问 `todo`；父组件提供的插槽内容只能用**插槽 props** 里传出来的数据。

---

## 七、响应性

```js
const todos = ref([...])
```

- 子组件修改 `todos`（增删改）→ 列表重渲染 → 插槽 props 更新 → 父组件插槽内容自动更新。
- 父组件自己作用域内的响应式数据变化 → 插槽内容也更新。
- 插槽 props 是**每次渲染时重新传入**的，不是一次性快照。

> [!tip] 常见误解
> "插槽内容只在初始化渲染一次"——错。父子任一侧数据变化，插槽内容都会按正常响应式规则更新。

---

## 八、作用域插槽的典型用途

| 组件 | 暴露的数据 | 父组件自定义 |
| --- | --- | --- |
| 列表 / 表格 | `item`、`index`、`row` | 每行/每列的渲染 |
| 下拉选择 | `option`、`selected` | 选项模板 |
| 树形控件 | `node`、`level` | 节点内容 |
| 分页器 | `page`、`current` | 页码样式 |
| 拖拽列表 | `item`、`dragging` | 拖拽态样式 |

```vue
<!-- 通用列表：子组件只管循环 -->
<MyList :items="users" v-slot="{ item, index }">
  <UserCard :user="item" :rank="index + 1" />
</MyList>
```

---

## 九、作用域插槽 vs props vs 普通插槽

| 方案 | 数据方向 | 结构由谁定 | 适用 |
| --- | --- | --- | --- |
| props | 父 → 子 | 子 | 纯数据 |
| 普通插槽 | 父（结构） | 父 | 子组件不知道内容长什么样 |
| 作用域插槽 | 子 → 父（数据） + 父（结构） | 父 | 子组件有数据，但外观要父组件定 |

> [!success] 判断口诀
> **子组件有数据、父组件要自定义外观 → 作用域插槽。**
> 子组件既没数据、外观也固定 → 根本不需要插槽。

---

## 十、易错点清单

- [ ] 在插槽内容里直接访问子组件变量（未通过 slot props）→ 拿不到
- [ ] 写成 `v-slot="user"` 却用 `user.name` → 拿到的是整个 props 对象，应 `v-slot="{ user }"` 或 `slotProps.user`
- [ ] 在具名插槽上用 `v-slot="{ x }"` 而非 `#name="{ x }"` → 匹配到默认插槽
- [ ] `<slot name="user" :user="user" />` 里 `name` 与数据字段混淆
- [ ] 传 ref 忘了模板自动解包规则，在 JS 中误用 `.value`
- [ ] 父组件写了插槽但没用 slot props，却疑惑数据从哪来
- [ ] `v-slot` 写在普通 `<div>` 上 → 编译报错

---

## 十一、自测

1. 子组件 `<slot :user="user" />` 中，父组件如何拿到 `user`？
2. `v-slot="{ user }"` 与 `v-slot="slotProps"` 有什么区别？
3. 作用域插槽的数据方向是什么？
4. 父组件不提供插槽时，`<slot :item="todo">{{ todo.text }}</slot>` 显示什么？
5. 为什么普通插槽拿不到子组件的数据？

> [!success]- 参考答案
> 1. `<Child v-slot="{ user }">` 或 `<template #default="{ user }">`。
> 2. 前者解构出 `user`；后者拿整个插槽 props 对象，需 `slotProps.user`。
> 3. 子组件 → 父组件的插槽内容（数据上行）。
> 4. 显示后备内容 `todo.text`。
> 5. 插槽内容在父组件作用域编译，只能访问父组件数据；子组件数据必须通过 slot props 显式传出。

---

## 十二、同型练习：商品列表作用域插槽

> [!info] 题目
> 子组件 `ProductList` 内部持有商品数据并循环，把 `product` 和 `index` 通过默认插槽暴露出去，同时准备后备内容：
>
> ```js
> const products = [
>   { id: 1, name: '键盘', price: 299, stock: 3 },
>   { id: 2, name: '鼠标', price: 99, stock: 0 },
> ]
> ```
>
> 父组件要求：
> 1. 每行显示序号、名称；
> 2. 显示打八折后的价格，保留两位小数；
> 3. 库存为 `0` 时显示"已售罄"；
> 4. 回答：父组件如何拿到子组件的 `product` / `index`？`v-slot="{ product, index }"` 与 `v-slot="slotProps"` 有什么区别？若子组件暴露的字段叫 `item`，父组件却解构 `{ product }`，会发生什么？子组件增删商品后，父组件的插槽内容会更新吗？

> [!success]- 参考答案
> **子组件**
>
> ```vue
> <!-- ProductList.vue -->
> <template>
>   <ul class="product-list">
>     <li v-for="(product, index) in products" :key="product.id">
>       <slot :product="product" :index="index">
>         {{ product.name }}
>       </slot>
>     </li>
>   </ul>
> </template>
>
> <script setup>
> import { ref } from 'vue'
>
> const products = ref([
>   { id: 1, name: '键盘', price: 299, stock: 3 },
>   { id: 2, name: '鼠标', price: 99, stock: 0 },
> ])
> </script>
> ```
>
> **父组件**
>
> ```vue
> <!-- ProductListParent.vue -->
> <template>
>   <ProductList v-slot="{ product, index }">
>     <span>{{ index + 1 }}. {{ product.name }}</span>
>     <span>¥{{ (product.price * 0.8).toFixed(2) }}</span>
>     <span v-if="product.stock === 0">已售罄</span>
>   </ProductList>
> </template>
>
> <script setup>
> import ProductList from './ProductList.vue'
> </script>
> ```
>
> **渲染结果**
>
> ```text
> 1. 键盘 ¥239.20
> 2. 鼠标 ¥79.20 已售罄
> ```
>
> **逐问回答**
> 1. 子组件在 `<slot :product="product" :index="index" />` 上把数据作为**插槽 props** 递出去，父组件用 `v-slot="{ product, index }"` 接收。`v-slot` 写在组件标签上，等价于 `<template #default="{ product, index }">`。
> 2. 前者直接解构出 `product` 和 `index` 两个变量；后者拿到整个插槽 props 对象，需要写 `slotProps.product`、`slotProps.index`。字段少用解构，字段多或要把整个对象传给函数时用后者。
> 3. 父组件解构出的 `product` 是 `undefined`（名字对不上），模板里再访问 `product.name` 会报"读取 undefined 的属性"错误，该行内容渲染失败。插槽 props 按名字匹配，不会自动改名。
> 4. 会更新。插槽 props 是每次渲染时重新传入的，不是初始化快照；子组件对 `products` 增删改，或父组件自身响应式数据变化，插槽内容都会按正常响应式规则重新渲染。

---

## 十三、关联

- 上一篇：[[Exp6 动态插槽名]]
- 下一篇：[[Exp8 具名作用域插槽]]
- 总览：[[00 组件通信与插槽总览]]
