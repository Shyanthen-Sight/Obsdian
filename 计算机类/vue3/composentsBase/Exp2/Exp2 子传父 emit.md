
> [!abstract] 一句话
> 子组件不直接改父组件的数据，而是**"喊一声"**：`emit('事件名', 数据)`。父组件在标签上用 `@事件名="处理函数"` 接住，在**自己的作用域里**修改数据。==这就是"子传父"：事件向上、数据随事件向上。==

📁 源码：`Exp2/Exp2_ChildToParent_Parent.vue`、`Exp2/Exp2_ChildToParent_Child.vue`

---

## 一、完整源码

### 1.1 子组件（发事件）

```vue
<!-- Exp2_ChildToParent_Child.vue -->
<template>
  <button @click="handleClick">降价</button>
</template>

<script setup>
import { ref } from 'vue'

const num = ref(2)
const emit = defineEmits(['minus'])

function handleClick() {
  emit('minus', num.value)
}
</script>
```

### 1.2 父组件（收事件）

```vue
<!-- Exp2_ChildToParent_Parent.vue -->
<template>
  <p>price: {{ price }}</p>
  <Child @minus="handleMinus" />
</template>

<script setup>
import { ref } from 'vue'
import Child from './Exp2_ChildToParent_Child.vue'

const price = ref(99)

function handleMinus(params) {
  price.value = price.value - params
}
</script>
```

### 1.3 运行效果

初始 `price: 99`。每点一次"降价"：

```text
99 → 97 → 95 → 93 ...
```

每次减 `num.value`，即 `2`。

---

## 二、执行链路（重点）

```text
用户点击按钮
   │
   ▼
子组件 handleClick()
   │  emit('minus', 2)
   ▼
父组件模板 @minus="handleMinus"
   │  自动调用 handleMinus(2)
   ▼
父组件 price.value = 99 - 2 = 97
   │  price 是 ref → 触发响应式更新
   ▼
父组件重新渲染 → 把新 price 显示出来
```

> [!important] 三个"没有"
> - 子组件**没有**修改 `price`（它根本拿不到 `price`）。
> - 父组件**没有**调用子组件的方法。
> - 通信靠的是**事件**，不是共享变量。数据始终留在父组件，符合"单向数据流"。

---

## 三、`defineEmits` 的两种写法

### 3.1 数组语法（只声明事件名）

```js
const emit = defineEmits(['minus'])
```

### 3.2 对象语法（带校验）

```js
const emit = defineEmits({
  minus: (payload) => typeof payload === 'number' && payload > 0,
})
```

校验函数返回 `false` 时，开发环境会打印警告；事件仍然会派发（校验只警告，不拦截）。

### 3.3 TS 写法

```ts
const emit = defineEmits<{
  (e: 'minus', payload: number): void
}>()
```

> [!info] 必须写 `defineEmits` 吗？
> 不写也能 `emit` 吗？——**不能直接拿到 `emit`**。`emit` 由 `defineEmits` 返回。
> 声明事件名的另一个作用是：让 Vue 知道这是**组件自定义事件**，而不是普通 DOM 事件，从而不会把它当作透传属性绑定到根元素上。

---

## 四、父组件监听的写法

```vue
<!-- 常见写法 -->
<Child @minus="handleMinus" />

<!-- 内联箭头函数：需要额外参数时 -->
<Child @minus="(n) => (price -= n)" />

<!-- 直接写表达式（自动取事件参数） -->
<Child @minus="(n) => (price = price - n)" />
```

> [!warning] `@minus="handleMinus"` vs `@minus="handleMinus()"`
> - `handleMinus`：把函数引用交给 Vue，事件触发时由 Vue 调用，**自动传入 payload**。
> - `handleMinus()`：**渲染时就立即执行**，把返回值（`undefined`）当作处理函数，通常不是你要的。

---

## 五、事件参数

```js
emit('minus')             // 父处理函数收到 undefined
emit('minus', 2)          // 收到 2
emit('minus', 2, '元')    // 收到 [2, '元']（多参数变数组）
```

父组件对应：

```js
function handleMinus(n) { ... }          // 单参数
function handleMinus(n, unit) { ... }    // 多参数
function handleMinus(...args) { ... }    // 全收
```

> [!tip] 建议只传一个对象
> `emit('change', { id, value })` 比 `emit('change', id, value)` 更好扩展——以后加字段不用改父组件签名。

---

## 六、事件命名规范

```js
// 子组件：camelCase 声明与触发
defineEmits(['updatePrice'])
emit('updatePrice', 10)
```

```vue
<!-- 父组件：kebab-case 监听 -->
<Child @update-price="..." />
```

> [!warning] 大小写陷阱
> 组件事件名**不会自动大小写转换**（和 props 不同）。在 DOM 内模板（非 SFC）中，`@updatePrice` 会被浏览器转成小写而匹配失败。**统一约定：声明 camelCase，监听 kebab-case。**
> Vue 3 官方也推荐：`emit('someEvent')` 对应 `@some-event`。

---

## 七、与 `v-model` 的关系（进阶必知）

组件上的 `v-model` 本质是**一个 prop + 一个 emit** 的语法糖：

```vue
<Child v-model="price" />
```

等价于：

```vue
<Child :model-value="price" @update:model-value="price = $event" />
```

所以子组件里可以这样实现：

```js
const props = defineProps(['modelValue'])
const emit = defineEmits(['update:modelValue'])
emit('update:modelValue', 97)
```

多参数 `v-model`：

```vue
<Child v-model:price="price" v-model:count="count" />
<!-- 对应 prop: price / count，事件: update:price / update:count -->
```

> [!success] 记住
> `v-model` 不是"双向绑定黑魔法"，就是 **props 下行 + emit 上行的封装**。

---

## 八、`emits` 声明与"透传"的关系

```js
defineEmits(['minus'])
```

声明后：

- `@minus` 被视为**组件自定义事件**，由 `emit` 触发。
- 未声明的事件监听器会进入 `$attrs`，并**自动绑定到子组件根元素**（当作原生事件），容易产生"莫名其妙触发两次"的问题。

> [!warning] 反例
> 子组件根元素是 `<button>`，父组件写 `<Child @click="fn" />`。若子组件没声明 `click`，监听器会透传到 `<button>` 上，点击按钮就触发——这未必是 bug，但要知道它从哪来。

---

## 九、兄弟组件通信怎么办？

`props` 只能父→子，`emit` 只能子→父。两个兄弟组件要说话，标准做法是**状态提升**：

```text
       父组件（持有共享状态）
        /            \
   props↓            props↓
   子 A  --emit-->  父  --props--> 子 B
```

即：子 A `emit` 给父，父改状态，再通过 `props` 传给子 B。

> [!tip] 层级很深时
> 用 `provide/inject`（跨层级）或 Pinia（全局状态）。本项目 `src/stores/counter.js` 就是 Pinia 示例，见 [[项目结构树解析]]。

---

## 十、易错点清单

- [ ] 忘记 `const emit = defineEmits([...])`，直接写 `emit(...)` → 报错
- [ ] 父组件写 `@minus="handleMinus()"` → 渲染即执行
- [ ] 事件名大小写不一致 → 监听不到
- [ ] 传 ref 忘了 `.value` → 子组件把整个 Ref 对象传出去
- [ ] 在子组件里直接改父组件传下来的 prop → 只读警告
- [ ] 以为 `emit` 返回值能拿到父组件结果 → `emit` 没有返回值
- [ ] 声明了事件却拼错名字 → 监听器静默失效

---

## 十一、自测

1. `emit('minus', 2)` 后，父组件 `handleMinus(params)` 里的 `params` 是什么？
2. 为什么子组件不能直接 `price.value -= 2`？
3. `<Child @minus="handleMinus" />` 与 `@minus="handleMinus()"` 的区别？
4. `v-model` 展开成哪两个东西？
5. 事件名声明为 `updatePrice`，父组件应该怎么写监听？

> [!success]- 参考答案
> 1. `2`。
> 2. `price` 定义在父组件作用域，子组件拿不到；即使通过 props 传入，props 也是只读的。
> 3. 前者传函数引用，事件触发时调用；后者渲染时立即调用。
> 4. `:model-value="x"` + `@update:model-value="x = $event"`。
> 5. `@update-price="..."`。

---

## 十二、同型练习：搜索框子传父

> [!info] 题目
> 实现一个 `SearchBox` 子组件：一个输入框 + 一个"搜索"按钮。点击按钮时，把输入内容通过事件交给父组件；父组件记录并显示 `搜索：xxx`。要求：
>
> 1. 事件名 `search`，用对象语法校验参数必须是**非空字符串**；
> 2. 子组件只持有输入内容，父组件只持有搜索记录，两边都不能直接修改对方的数据；
> 3. 回答：输入为空时点击，会发生什么？父组件若写 `@search="handleSearch()"` 会怎样？

> [!success]- 参考答案
> **子组件**
>
> ```vue
> <!-- SearchBox.vue -->
> <template>
>   <div>
>     <input v-model="keyword" placeholder="输入关键字" />
>     <button @click="handleSearch">搜索</button>
>   </div>
> </template>
>
> <script setup>
> import { ref } from 'vue'
>
> const keyword = ref('')
> const emit = defineEmits({
>   search: (payload) => typeof payload === 'string' && payload.trim() !== '',
> })
>
> function handleSearch() {
>   emit('search', keyword.value)
> }
> </script>
> ```
>
> **父组件**
>
> ```vue
> <!-- SearchBoxParent.vue -->
> <template>
>   <SearchBox @search="handleSearch" />
>   <p>搜索：{{ lastKeyword }}</p>
> </template>
>
> <script setup>
> import { ref } from 'vue'
> import SearchBox from './SearchBox.vue'
>
> const lastKeyword = ref('未搜索')
>
> function handleSearch(kw) {
>   lastKeyword.value = kw
> }
> </script>
> ```
>
> **运行效果**
>
> ```text
> 初始：搜索：未搜索
> 输入 vue 并点击：搜索：vue
> ```
>
> **两个问题的答案**
> 1. 空字符串会让 `validator` 返回 `false`，开发环境打印警告，但**事件仍然会派发**。父组件收到 `''`，页面显示成 `搜索：`（后面空白）。`emits` 校验只警告、不拦截；要在空值时直接不搜，应在 `emit` 前自己判断：
>    ```js
>    if (keyword.value.trim() === '') return
>    emit('search', keyword.value)
>    ```
> 2. `@search="handleSearch()"` 会在**渲染时立即调用** `handleSearch()`，并把它的返回值 `undefined` 当作事件处理函数；之后点击按钮不会触发任何逻辑。正确写法是不带括号，或写成 `@search="(kw) => handleSearch(kw)"`。

---

## 十三、关联

- 上一篇：[[Exp1 父传子 props]]
- 下一篇：[[Exp3 默认插槽]]
- 总览：[[00 组件通信与插槽总览]]
