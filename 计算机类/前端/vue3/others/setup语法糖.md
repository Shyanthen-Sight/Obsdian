# setup 语法糖（`<script setup>`）

> [!abstract] 一句话
> `<script setup>` 是 Vue 3 的**编译期语法糖**：==在 `<script setup>` 里声明的顶层变量、函数、`import`，会自动暴露给 `<template>` 用，不用再 `return`==。它不是新 API，而是把 `setup()` 函数里那套样板代码"抹平"的写法——编译器替你写掉了 `setup()` 包裹和 `return {}`。

---

## 一、为什么会有它：三段演进

同一个计数器组件，三种写法对比，一眼看懂它省了什么：

### 1. Options API（Vue 2 风格）

```vue
<script>
export default {
  data() {
    return { count: 0 }
  },
  methods: {
    increment() { this.count++ }
  }
}
</script>
```

### 2. 组合式 API：`setup()` 函数（Vue 3.0）

```vue
<script>
import { ref } from 'vue'

export default {
  setup() {
    const count = ref(0)
    const increment = () => count.value++
    return { count, increment }   // ← 必须手动 return 才能给模板用
  }
}
</script>
```

### 3. `<script setup>` 语法糖（Vue 3.2 稳定）

```vue
<script setup>
import { ref } from 'vue'

const count = ref(0)
const increment = () => count.value++
// 什么都不用 return，模板里直接就能用 count / increment
</script>
```

> [!success] 一句话理解
> 第 2、3 种**逻辑完全等价**，区别只是：==`<script setup>` 把"手写 `setup()` + 手动 `return`"两个动作交给编译器==。所以它叫"语法糖"，不叫新功能。

---

## 二、核心机制：顶层绑定自动暴露

在 `<script setup>` 里，**顶层的**以下东西都会自动出现在模板作用域中：

| 写了什么 | 模板里能否直接用 |
| --- | --- |
| `const / let / var` 声明的变量 | ✅ 直接可读（是 `ref` 时自动 `.value` 解包） |
| 函数声明 / 箭头函数 | ✅ 可直接调用 |
| `import` 进来的组件 / 变量 | ✅ 可直接用（组件可当标签） |
| `import` 进来的类型（TS） | ❌ 类型会被抹掉，不暴露 |
| 嵌套在函数里声明的变量 | ❌ 不是顶层，不暴露 |

```vue
<script setup>
import { ref, computed } from 'vue'
import MyHeader from './MyHeader.vue'   // ① 组件：可直接写 <MyHeader />

const msg = ref('hello')
const num = computed(() => msg.value.length)

function sayHi() { console.log(msg.value) }  // ② 顶层函数：模板可直接 @click="sayHi"

// ③ import 的 Vue API：模板里也能用（虽然少见）
</script>

<template>
  <MyHeader />                 <!-- import 的组件直接当标签 -->
  <p>{{ msg }} ({{ num }})</p> <!-- ref/computed 自动解包，无需 .value -->
  <button @click="sayHi">点我</button>
</template>
```

> [!warning] 模板里不用写 `.value`
> 在 `<script setup>` 中，模板会把顶层 `ref` **自动解包**，所以写 `{{ msg }}` 而不是 `{{ msg.value }}`。
> 但在 `<script>` 逻辑代码里**必须**写 `.value`（`msg.value`）。这是最常见的混淆点。

---

## 三、编译宏：不用 import 的"伪函数"

有一批以 `defineXxx` 开头的函数，它们**不需要 import**，且**在编译阶段就被处理掉**（不会真的出现在运行时打包产物里）。它们统称**编译宏（compiler macros）**。

### 3.1 `defineProps` —— 声明 props

```vue
<script setup lang="ts">
// 方式一：数组（最简单，无类型校验）
const props = defineProps(['title', 'count'])

// 方式二：对象（可校验类型、默认值、必填）
const props = defineProps({
  title: { type: String, required: true },
  count: { type: Number, default: 0 }
})

// 方式三：TS 类型声明（<script setup lang="ts">）
const props = defineProps<{
  title: string
  count?: number
}>()
</script>
```

配合 `withDefaults` 给 TS 写法补默认值：

```vue
<script setup lang="ts">
interface Props {
  title: string
  count?: number
}
const props = withDefaults(defineProps<Props>(), {
  count: 0
})
</script>
```

> [!note] props 是**只读**的
> 不要直接改 `props.xxx`。想基于它变化，用 `computed` 派生一份：
> ```js
> const double = computed(() => props.count * 2)
> ```
> 需要"可写"的双向绑定场景，用下面的 `defineModel`。

### 3.2 `defineEmits` —— 声明自定义事件

```vue
<script setup lang="ts">
// 数组
const emit = defineEmits(['change', 'update'])

// 对象（可对事件参数做校验）
const emit = defineEmits({
  change: (payload) => typeof payload === 'string'
})

// TS 类型（最推荐，参数类型有提示）
const emit = defineEmits<{
  change: [payload: string]
  update: [id: number]
}>()
</script>

<template>
  <button @click="emit('change', 'hi')">触发</button>
</template>
```

### 3.3 `defineExpose` —— 暴露给父组件（配合 ref）

`<script setup>` 默认**完全封死**内部变量，父组件通过 `ref` 拿不到任何东西。要暴露必须显式声明：

```vue
<!-- 子组件 Child.vue -->
<script setup>
import { ref } from 'vue'
const count = ref(0)
function reset() { count.value = 0 }

defineExpose({ count, reset })   // ← 只有这两个能被父组件访问
</script>
```

```vue
<!-- 父组件 -->
<script setup>
import { ref } from 'vue'
import Child from './Child.vue'
const childRef = ref(null)

function onClick() {
  childRef.value.reset()          // ✅ 可调用
  console.log(childRef.value.count) // ✅ 可读
}
</script>

<template>
  <Child ref="childRef" />
</template>
```

> [!tip] 为什么默认不暴露？
> 显式 `defineExpose` 让组件的"对外接口"一目了然，避免父组件随意伸手进子组件内部，破坏封装。

### 3.4 其它编译宏

| 宏 | 作用 | 起始版本 |
| --- | --- | --- |
| `defineProps` | 声明 props | 3.2 |
| `defineEmits` | 声明自定义事件 | 3.2 |
| `defineExpose` | 暴露实例给父组件 | 3.2 |
| `withDefaults` | 给 TS 版 props 补默认值 | 3.3 |
| `defineOptions` | 声明 `inheritAttrs`、`name` 等选项 | 3.3 |
| `defineSlots` | 声明插槽类型（TS） | 3.3 |
| `defineModel` | 声明 `v-model` 双向绑定 | 3.4 |

```vue
<!-- defineOptions：以前写 name / inheritAttrs 只能靠"再开一个 <script>"，现在直接写 -->
<script setup>
defineOptions({
  name: 'MyComponent',
  inheritAttrs: false
})
</script>
```

```vue
<!-- defineModel：子组件里实现 v-model，不用再 props + emit 手写一对 -->
<script setup>
const modelValue = defineModel()   // 父组件写 <Child v-model="text" />
// 直接 modelValue.value = 'x' 就能同步回父组件，全自动
</script>
```

---

## 四、`<script setup>` 里能用的"进阶"玩法

### 4.1 顶层 `await`（异步组件）

```vue
<script setup>
const res = await fetch('/api/user')
const user = await res.json()
</script>
```

> [!warning] 顶层 await 需要 `<Suspense>`
> 加了顶层 `await` 后，该组件变成 **async setup**，必须被父级 `<Suspense>` 包裹才能渲染，否则会报错。

```vue
<template>
  <Suspense>
    <AsyncUser />
    <template #fallback>加载中…</template>
  </Suspense>
</template>
```

### 4.2 组件自动注册 + 递归引用

`import` 进来的组件**无需** `components: {}` 注册，直接当标签用。而且组件可以用**自己的文件名**递归引用自己：

```vue
<!-- Tree.vue -->
<script setup>
import Tree from './Tree.vue'   // 自己引自己，做递归树
</script>

<template>
  <ul>
    <li v-for="node in nodes" :key="node.id">
      {{ node.label }}
      <Tree v-if="node.children" :nodes="node.children" />
    </li>
  </ul>
</template>
```

### 4.3 命名空间组件

```vue
<script setup>
import * as Form from './form'
</script>

<template>
  <Form.Input />
  <Form.Select />
</template>
```

### 4.4 `useSlots()` / `useAttrs()`

它们是**真正的函数**（要 import），对应原来 `setup(props, ctx)` 里的 `slots`、`attrs`：

```vue
<script setup>
import { useSlots, useAttrs } from 'vue'

const slots = useSlots()
const attrs = useAttrs()
</script>
```

---

## 五、对比速查：普通 `<script>` vs `<script setup>`

| 需求 | 普通 `setup()` 写法 | `<script setup>` 写法 |
| --- | --- | --- |
| 暴露给模板 | `return { a, b }` | 无需，顶层自动暴露 |
| 注册子组件 | `components: { Child }` | `import Child` 即可 |
| 声明 props | `props: {}` 或 `setup(props)` | `defineProps(...)` |
| 声明事件 | `emits: []` 或 `ctx.emit` | `defineEmits(...)` |
| 暴露实例 | `setup(props, { expose })` | `defineExpose(...)` |
| 自定义 `name` | `name: 'X'` | `defineOptions({ name: 'X' })` |
| 双向绑定 | `props` + `emit('update:x')` | `defineModel('x')` |

---

## 六、两个 `<script>` 混用（少见但要认识）

`<script setup>` 可以和普通 `<script>` **同时存在**，普通块用于需要"每次实例化外的模块级代码"或导出额外内容：

```vue
<script>
// 普通块：这些代码在模块作用域执行，只跑一次
export const sharedConstant = 123
</script>

<script setup>
// 语法糖块：组件逻辑
</script>
```

> [!note] 执行顺序
> 普通 `<script>` 先于 `<script setup>` 执行。日常几乎用不到，知道有这回事即可。

---

## 七、常见坑

> [!question] 模板里访问 ref 要用 `.value` 吗？
> **不用。** 模板对顶层 ref 会自动解包，写 `{{ count }}`。但 `<script>` 里的逻辑代码必须写 `count.value`。这是最容易出错的地方。

> [!question] 为什么父组件 `ref` 拿到子组件后什么都访问不到？
> 因为 `<script setup>` **默认不对外暴露**。子组件必须 `defineExpose({ ... })` 显式声明要暴露的内容。

> [!question] 改了 props 报错 "Set operation on key failed: target is readonly"？
> props 是**只读**的。要派生 → `computed`；要双向 → `defineModel`；要本地可变副本 → `const local = ref(props.xxx)` 再 watch 同步。

> [!question] `defineProps` 里的 TS 类型能 import 进来用吗？
> Vue 3.3+ 支持从外部文件导入类型了；更早版本里 `defineProps<Props>()` 的类型必须**在当前文件内联声明**，否则编译器解析不到。

> [!question] 编译宏为什么不用 import？
> 因为它们在**编译阶段就被替换掉了**，不产生运行时代码。所以从 `vue` 里手动 `import { defineProps }` 反而会报错——它们是"语法"，不是"函数"。

---

## 相关笔记

- [[项目结构树解析]] —— `App.vue` / `stores` 里看到的 `<script setup>` 长这样就看懂了
- [[tsconfig.json]] —— `lang="ts"` 时类型从哪来、`paths` 别名怎么配
- [[TypeScript vs JavaScript]] —— `defineProps<Props>()` 泛型写法的类型基础
- [[安装与配置]] —— 起一个能手写 `<script setup>` 的 Vue 3 工程

---

参考：Vue 官方文档 —— `<script setup>` / Composition API / 编译宏（Compiler Macros）；Vue 3.2（语法糖稳定）、3.3（`defineOptions`/`defineSlots`）、3.4（`defineModel` 稳定）更新日志
