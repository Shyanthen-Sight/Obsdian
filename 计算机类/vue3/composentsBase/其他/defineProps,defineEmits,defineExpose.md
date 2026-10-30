
> [!abstract] 一句话
> 三个宏分别定义组件的三种"对外接口"：
> ==`defineProps` 管**输入**（父传子），`defineEmits` 管**输出**（子通知父），`defineExpose` 管**命令式句柄**（父组件通过 ref 调用子组件方法）==。三者都是 `<script setup>` 的编译宏，不用 `import`，编译后从代码里消失。

```text
                props（父 → 子，数据）
父组件 ──────────────────────────────▶ 子组件
   ▲                                      │
   │          emits（子 → 父，事件）        │
   └──────────────────────────────────────┘

父组件 ── ref ──▶ 子组件实例 ── defineExpose ──▶ 只交出白名单
```

> [!important] 优先级
> 能用 `props` / `emits` 解决，就不要用 `defineExpose`。前两者是数据流，后者是命令式调用，耦合度最高。

---
## 一、先看全貌

| 宏              | 方向         | 返回值         | 子组件里怎么写                                             | 父组件里怎么用                  | 对应 Options API                        |
| -------------- | ---------- | ----------- | --------------------------------------------------- | ------------------------ | ------------------------------------- |
| `defineProps`  | 父 → 子      | 只读 props 对象 | `const props = defineProps({...})`                  | `<Child title="hi" />`   | `props` 选项                            |
| `defineEmits`  | 子 → 父      | `emit` 函数   | `const emit = defineEmits([...])`、`emit('x', data)` | `<Child @x="handler" />` | `emits` + `this.$emit`                |
| `defineExpose` | 子 → 父（命令式） | `void`      | `defineExpose({ reset })`                           | `childRef.value.reset()` | `expose` 选项 / `setup(ctx)` 的 `expose` |

一句话记忆：

> **Props 进，Emits 出，Expose 是"遥控器"。**

---

## 二、编译宏：三个共同前提

三个宏都不是普通函数，而是**编译期语法**。理解这一点，就能理解它们所有的限制。

| 规则                                        | 说明                                            | 反例                                             |
| ----------------------------------------- | --------------------------------------------- | ---------------------------------------------- |
| 不用 `import`                               | <font color="#c00000">编译器直接识别名字</font>        | `import { defineProps } from 'vue'` 多余且会干扰编译识别 |
| 只能在 `<script setup>` 顶层                   | <font color="#c00000">不能放进函数、if、生命周期钩子</font> | `onMounted(() => defineProps(['id']))` ❌       |
| <font color="#c00000">一个组件每种宏只能调一次</font> | 重复声明编译报错                                      | 两处 `defineProps(...)` ❌                        |
| 不能当值使用                                    | 它不是变量，只是"声明标记"                                | `const fn = defineProps` ❌                     |
| 编译后消失                                     | 不产生运行时代码，没有运行时开销                              | —                                              |

> [!warning] 声明参数不能是运行时变量
> ```js
> const keys = ['id', 'title']
> defineProps(keys)        // ❌ 编译阶段拿不到 keys 的值
> defineProps(['id', 'title'])  // ✅ 字面量
> ```
> `defineProps` / `defineEmits` 的声明会被提升到组件选项，编译时只能处理字面量或同文件类型。`defineExpose` 的参数是普通对象，可以引用组件内的变量——这正是它的用途。

---

## 三、defineProps：声明"我要接收什么"

### 3.1 三种写法

```js
// ① 数组：只声明字段名，不做校验
const props = defineProps(['title', 'count'])

// ② 对象：可写类型、必填、默认值、自定义校验
const props = defineProps({
  title: { type: String, required: true },
  count: { type: Number, default: 0 },
})

// ③ TS 类型声明（推荐 TS 项目）
const props = defineProps<{
  title: string
  count?: number
}>()
```

TS 写法补默认值：

```ts
interface Props {
  title?: string
  tags?: string[]
}

const props = withDefaults(defineProps<Props>(), {
  title: '未命名',
  tags: () => [],   // 对象 / 数组默认值必须用工厂函数
})
```

Vue 3.5+ 也可以直接解构并保留响应性：

```ts
const { title = '未命名', tags = [] } = defineProps<Props>()
```

### 3.2 模板与脚本的访问方式

```vue
<script setup>
const props = defineProps({ title: String })
</script>

<template>
  <p>{{ title }}</p>        <!-- ✅ 模板自动注入，推荐 -->
  <p>{{ props.title }}</p>  <!-- ✅ 接住返回值后可用 -->
  <p>{{ $props.title }}</p> <!-- ✅ 内置属性，总是可用 -->
</template>
```

```js
// 脚本里没有模板注入，必须通过返回值访问
console.log(props.title)   // ✅
console.log(title)         // ❌ 未定义
```

> [!tip] 接不接返回值？
> **只在模板用 → 可以不接；要在 JS / computed / watch / 事件处理里用 → 必须接。** 变量名随意，习惯叫 `props`。

### 3.3 只读与单向数据流

```js
props.title = 'new'   // ❌ 开发环境警告：target is readonly
```

`props` 是**浅只读**的：顶层属性不能改，但嵌套对象 `props.obj.name = 'x'` 技术上能改，属于反模式。正确做法：

- 要改父组件数据 → 用 `defineEmits` 通知父组件；
- 要派生数据 → 用 `computed(() => props.x * 2)`；
- 要本地可变副本 → `const local = ref(props.x)`，再按需 `watch` 同步。

### 3.4 声明过的字段不再进 attrs

```js
const props = defineProps(['id'])
```

父组件写 `<Child id="001" class="box" />` 时：

- `id` 被 props 消费，进 `props.id`，**不会**透传到根元素；
- `class` 没声明，进 `$attrs`，自动透传到根元素。

> [!info] 这就是"声明即消费"
> 想让某个属性既进 props 又出现在 DOM 上，只能在子组件模板里手动绑一次，例如 `<div :title="title">`。

### 3.5 命名与布尔值

- JS 里声明 `camelCase`（`loginMethod`），模板里传 `kebab-case`（`:login-method="..."`）。
- 声明为 `Boolean` 的 prop：不传 → `false`；写空字符串 → `true`；只写属性名（`<Child disabled />`）→ `true`。

> [!tip] 完整校验规则、`default` 对 `null` / `undefined` 的差异、`validator` 细节
> 见 [[Exp1 父传子 props]] 与 [[Props 组件属性]]，这里只保留和另外两个宏对照所需的部分。

---

## 四、defineEmits：声明"我会喊什么"

### 4.1 三种写法

```js
// ① 数组：只声明事件名
const emit = defineEmits(['search', 'reset'])

// ② 对象：可校验参数
const emit = defineEmits({
  search: (payload) => typeof payload === 'string' && payload.trim() !== '',
  reset: null,   // null 表示不校验
})

// ③ TS：具名元组（推荐）
const emit = defineEmits<{
  search: [keyword: string]
  reset: []
}>()
```

也支持函数签名写法：

```ts
const emit = defineEmits<{
  (e: 'search', keyword: string): void
  (e: 'reset'): void
}>()
```

### 4.2 返回值必须接住

```js
const emit = defineEmits(['search'])

function onSearch() {
  emit('search', keyword.value)   // ✅
}
```

> [!warning] `emit` 由 `defineEmits` 返回
> 不接返回值就没有 `emit` 可调用。只声明、不发射时可以忽略返回值，但声明本身仍然有用：它告诉 Vue 这是**组件自定义事件**，不会被当作透传属性绑到根元素上。

### 4.3 参数与校验

```js
emit('reset')                 // 父处理函数收到 undefined
emit('search', 'vue')         // 收到 'vue'
emit('change', 1, 'px')       // 多参数 → 父处理函数收到多个参数
```

```js
const emit = defineEmits({
  search: (kw) => typeof kw === 'string' && kw.trim() !== '',
})
emit('search', '')   // 开发环境警告，但事件仍然会派发
```

> [!important] 校验只警告，不拦截
> 想"空值不搜"，应在 `emit` 前自己判断：
> ```js
> if (!keyword.value.trim()) return
> emit('search', keyword.value)
> ```

建议只传一个对象：`emit('change', { id, value })` 比 `emit('change', id, value)` 更好扩展。

### 4.4 命名与透传

- 声明和 `emit` 用 `camelCase`：`emit('updatePrice', 10)`。
- 模板监听用 `kebab-case`：`@update-price="..."`。
- 声明过的事件监听器不会再透传到根元素；**没声明**的 `@click` 之类会落到 `$attrs`，绑到子组件根元素上。

> [!warning] 事件名不会自动大小写转换
> 这和 props 不同。DOM 内模板（非 SFC）里 `@updatePrice` 会被浏览器转成小写而匹配失败。统一约定：声明 camelCase，监听 kebab-case。

### 4.5 与 v-model 的关系

组件上的 `v-model` 本质是一对 prop + emit：

```vue
<Child v-model="text" />
<!-- 等价于 -->
<Child :model-value="text" @update:model-value="text = $event" />
```

手写版本：

```js
const props = defineProps(['modelValue'])
const emit = defineEmits(['update:modelValue'])

emit('update:modelValue', newValue)
```

Vue 3.4+ 可以用 `defineModel()` 一步到位：

```js
const value = defineModel()   // 自动生成 prop + update 事件
value.value = 'new'           // 直接同步回父组件
```

> [!tip] `defineModel` 是 `defineProps` + `defineEmits` 的封装
> 理解前两个宏，才知道它替你省掉了哪两行。

---

## 五、defineExpose：开放"命令式接口"

### 5.1 默认是封闭的

`<script setup>` 组件默认**不向父组件暴露任何内部绑定**。父组件通过 `ref` 拿到子组件实例后，读不到子组件里的 `count`、也调不到 `reset()`。

```vue
<!-- 子组件：没有 defineExpose -->
<script setup>
const count = ref(0)
function reset() { count.value = 0 }
</script>
```

```js
// 父组件
const childRef = ref(null)
onMounted(() => {
  childRef.value.reset()   // ❌ 不存在
})
```

这是刻意的封装：组件的内部实现不应该被父组件随便伸手。

### 5.2 基本用法

```vue
<!-- 子组件 Child.vue -->
<script setup>
import { ref } from 'vue'

const count = ref(0)
function reset() {
  count.value = 0
}

defineExpose({ count, reset })   // ← 只交出这两个
</script>
```

```vue
<!-- 父组件 -->
<script setup>
import { ref, onMounted } from 'vue'
import Child from './Child.vue'

const childRef = ref(null)

onMounted(() => {
  console.log(childRef.value.count)  // ✅ 0
  childRef.value.reset()             // ✅ 调用子组件方法
})
</script>

<template>
  <Child ref="childRef" />
</template>
```

### 5.3 暴露的 ref 会自动解包

```js
const count = ref(0)
defineExpose({ count })
```

父组件访问：

```js
childRef.value.count        // 0（数字，不是 Ref）
childRef.value.count.value  // ❌ 多写了一层
```

原因：暴露对象会被 `proxyRefs` 包一层，ref 在访问时自动解包。

> [!warning] 但解构出来仍是快照
> ```js
> const { count } = childRef.value   // ❌ 取到的是当前数字
> count++                            // 与子组件无关
> ```
> 要保持响应性，继续用 `childRef.value.count`，或在父组件里 `computed(() => childRef.value?.count)`。

### 5.4 暴露什么、不暴露什么

| 应该暴露 | 不该暴露 |
| --- | --- |
| 父组件确实需要命令式调用的方法：`validate()`、`reset()`、`focus()`、`scrollTo()` | 所有内部状态、临时变量 |
| 需要被父组件读取的只读数据（用 `readonly` 或 `computed` 包一层） | 可被父组件随意修改的原始状态 |
| 组件库文档里承诺的公开 API | 实现细节（内部 ref、私有方法） |

```js
// 更稳妥：只读数据 + 方法
import { readonly } from 'vue'

defineExpose({
  count: readonly(count),
  reset,
})
```

> [!important] defineExpose 不是"第二套 props"
> 它只对**直接父组件通过 ref** 可见，不是全局，也不适合替代数据流。父组件需要"命令子组件做一件事"时才用它；传数据仍然用 props，通知父组件仍然用 emits。

### 5.5 时机：ref 在挂载前是 null

```js
const childRef = ref(null)

console.log(childRef.value)   // null（组件还没挂载）

onMounted(() => {
  childRef.value?.reset()     // ✅ 此时才拿得到实例
})
```

- 子组件被 `v-if` 移除后，`childRef.value` 会变回 `null`。
- 在事件处理函数、`onMounted`、`nextTick` 里访问最稳。
- 用 `v-for` 的 ref 会得到数组，注意逐个判空。

### 5.6 与内置属性的边界

`defineExpose` 控制的是 `<script setup>` 内部**绑定**的可见性；组件实例自带的公共属性（如 `$el`、`$props`、`$attrs`）不受影响。

> [!info] 不要靠 `$el` 绕过封装
> 即使能拿到 `$el`，也应优先通过暴露的方法操作，而不是直接改 DOM。封装的意义是让"对外接口"一目了然。

### 5.7 常见误解：「只要暴露了，其他组件都能拿到」

> [!warning] 这个说法半对半错
> **对的一半**：Vue 里没有固定的父 / 子身份。谁在自己的模板里写 `<Child />`，谁就是当下的父组件；同一个组件在不同页面可以有不同的父组件。
> **错的一半**：`defineExpose` 不是广播，不会让"其他组件"自动看到它。它只是把白名单挂到**组件实例**上；没有实例引用，就没有入口。

准确模型分三步：

1. `defineExpose` 只是给实例挂一个公开代理（`instance.exposed`）。
2. 拿实例的正规入口只有模板 ref。
3. 模板 ref 只注册到**渲染这个标签的组件实例**上。

| 谁                     | 能否直接拿到 | 原因                              |
| --------------------- | ------ | ------------------------------- |
| 直接父组件                 | ✅      | 它的模板里写了 `<Child ref="..." />` |
| 祖辈组件                  | ❌      | 模板里没有 `<Child>`，`$refs` 里没有该实例  |
| 兄弟组件                  | ❌      | 同样没有渲染它                         |
| 同一组件的另一次使用            | ❌      | 是另一个实例，状态和暴露各自独立                |

"其他组件能拿到"的场合，本质上都是有人**把实例或引用交出去了**：provide / inject 把子 ref 传进后代、把 `childRef` 作为 prop 往下传、或存进全局状态。这些是显式转交，不是 `defineExpose` 的自动效果。

> [!danger] 底层后门不要用
> `getCurrentInstance()`、`$parent.$refs.xxx`、`$root` 技术上能摸到实例，但都绕过封装、依赖内部结构，组件一重构就碎。跨层级共享用 `provide/inject` 或 Pinia。

一句话修正：

> `defineExpose` 暴露的对象属于"**持有该实例引用的组件**"，而不是"父组件"这个身份；只是 ref 只能由渲染它的组件注册，实际效果才看起来像"只对直接父组件开放"。

---

## 六、三者配合：一个搜索表单

```vue
<!-- SearchForm.vue -->
<script setup>
import { ref } from 'vue'

// ① 输入：父组件传进来的初始值和占位符
const props = defineProps({
  keyword: { type: String, default: '' },
  placeholder: { type: String, default: '请输入关键字' },
})

// ② 输出：搜索、重置两个事件
const emit = defineEmits({
  search: (kw) => typeof kw === 'string' && kw.trim() !== '',
  reset: null,
})

const inputRef = ref(null)
const inner = ref(props.keyword)

// ③ 命令式接口：父组件可以主动聚焦、重置
function focus() {
  inputRef.value?.focus()
}

function reset() {
  inner.value = ''
  emit('reset')
  focus()
}

defineExpose({ focus, reset })
</script>

<template>
  <input ref="inputRef" v-model="inner" :placeholder="placeholder" />
  <button @click="emit('search', inner)">搜索</button>
</template>
```

```vue
<!-- 父组件 -->
<script setup>
import { ref, onMounted } from 'vue'
import SearchForm from './SearchForm.vue'

const formRef = ref(null)
const lastKeyword = ref('')

function handleSearch(kw) {
  lastKeyword.value = kw
}

onMounted(() => {
  formRef.value.focus()   // 命令式：进入页面自动聚焦
})
</script>

<template>
  <SearchForm
    ref="formRef"
    keyword="vue"
    placeholder="搜索组件"
    @search="handleSearch"
    @reset="lastKeyword = ''"
  />
  <button @click="formRef.reset()">清空</button>
  <p>最近搜索：{{ lastKeyword }}</p>
</template>
```

三条通道各司其职：

```text
keyword / placeholder  ──props──▶  SearchForm
search / reset         ◀─emits──  SearchForm
focus() / reset()      ◀─expose─  SearchForm（父组件通过 ref 主动调用）
```

---

## 七、Options API 对照

| 需求                          | Options API                                      | `<script setup>`                 |
| --------------------------- | ------------------------------------------------ | -------------------------------- |
| 接收 props                    | `props: { title: String }`                       | `defineProps({ title: String })` |
| 访问 props                    | `this.title`                                     | `props.title` / 模板 `title`       |
| 声明事件                        | `emits: ['search']`                              | `defineEmits(['search'])`        |
| 触发事件                        | `this.$emit('search', kw)`                       | `emit('search', kw)`             |
| 暴露实例                        | `expose: ['reset']` 或 `setup(props, { expose })` | `defineExpose({ reset })`        |
| 自定义 `name` / `inheritAttrs` | `name` / `inheritAttrs` 选项                       | `defineOptions({ ... })`         |
| 双向绑定                        | `modelValue` prop + `update:modelValue`          | `defineModel()`                  |

> [!info] 两种 API 可以混用
> 父组件用 `<script setup>`、子组件用 Options API（或反过来）都能正常通信，协议是一样的：props 向下、事件向上、expose 供 ref 调用。

---

## 八、易错点清单

- [ ] `defineProps` / `defineEmits` 写进函数、`if`、生命周期钩子 → 只能顶层
- [ ] 先把字段数组存进变量再传给宏 → 参数必须是字面量
- [ ] 从 `vue` 手动 `import { defineProps }` → 多余，且可能干扰编译识别
- [ ] `defineEmits` 不接返回值却直接 `emit(...)` → `emit` 未定义
- [ ] 事件声明 `updatePrice`，父组件写 `@updatePrice` → DOM 模板大小写失效，统一 kebab-case
- [ ] 父组件写 `@search="handleSearch()"` → 渲染时立即执行，应传函数引用
- [ ] 子组件直接改 `props.x` → 只读警告，改用 emit
- [ ] Vue 3.5 之前解构 props → 丢响应性，用 `props.x` 或 `toRefs`
- [ ] 对象 / 数组默认值写成 `default: []` → 必须 `default: () => []`
- [ ] 父组件 `ref` 拿到子组件后直接调用方法 → 子组件没 `defineExpose`
- [ ] `defineExpose` 暴露普通变量 `let count = 0` → 父组件读不到后续变化，应暴露 ref
- [ ] 把 `defineExpose` 暴露的 ref 解构出来 → 变成快照，丢响应性
- [ ] 在 `onMounted` 之前访问 `childRef.value` → 还是 `null`
- [ ] 用 `defineExpose` 传数据、代替 props / emits → 耦合高，方向也反了
- [ ] 以为 `defineExpose` 对所有组件开放 → 只有持有实例引用的组件能访问，通常仅直接父组件
- [ ] 声明了 `click` 事件又指望它透传到根元素 → 已声明就被当作自定义事件消费

---

## 九、自测

> [!question]- 1. 三个宏分别对应组件的什么"接口"？
> `defineProps` 是输入接口（父 → 子数据），`defineEmits` 是输出接口（子 → 父事件），`defineExpose` 是命令式接口（父组件通过 ref 调用子组件方法）。前两者是数据流，后者是"遥控器"。

> [!question]- 2. 父组件通过 `ref` 拿到子组件，为什么调不到子组件的 `reset()`？怎么解决？
> `<script setup>` 组件默认封闭，内部绑定不会暴露给父组件。子组件需要 `defineExpose({ reset })` 显式开放；父组件在 `onMounted` 之后通过 `childRef.value.reset()` 调用。

> [!question]- 3. `defineExpose` 暴露 `count`（ref）和 `let count = 0`（普通变量）有什么区别？
> 暴露 ref 时，父组件访问 `childRef.value.count` 会自动解包，并且子组件后续修改能反映出来；暴露普通变量只是暴露了当时的值的拷贝，后续变化父组件看不到。要响应式就暴露 ref / reactive。

> [!question]- 4. 为什么 `defineProps` 的参数不能是外部变量？
> 它是编译宏，声明会在编译阶段被提升到组件选项；`const keys = [...]` 是运行时的局部变量，编译时取不到值。整个参数必须是字面量（或同文件 / 导入的类型）。

> [!question]- 5. `defineEmits(['search'])` 声明之后，父组件的 `@search` 监听器还会透传到根元素吗？
> 不会。声明过的事件会被当作组件自定义事件消费，不再进入 `$attrs`；未声明的事件监听器才会透传到根元素，可能造成"原生事件也触发"的意外。

> [!question]- 6. 子组件想修改父组件的数据，应该用 `defineExpose` 还是 `defineEmits`？
> 用 `defineEmits`。子组件 `emit('update', newValue)`，父组件监听后在自己的作用域里修改数据，保持单向数据流。`defineExpose` 是父组件主动命令子组件的通道，方向相反，也不适合传数据。

> [!question]- 7. 为什么 `defineProps` / `defineEmits` 不需要 import，而 `ref` 需要？
> `defineProps` / `defineEmits` 是编译宏，编译器在编译阶段识别并改写成组件选项，运行时代码里不存在；`ref` 是真正的运行时 API，必须从 `vue` 导入才能使用。

---

## 十、相关笔记

- [[defineProps() 和 defineEmits()]] —— props / emits 的详细展开与三种模板访问写法
- [[setup语法糖]] —— 编译宏的全家桶、顶层绑定自动暴露、`defineOptions` / `defineModel`
- [[Exp1 父传子 props]] —— 实验版：props 声明、校验、静态值与动态值
- [[Exp2 子传父 emit]] —— 实验版：emit 链路、事件参数、事件命名
- [[引用注册]] —— 模板 ref 与 `defineExpose` 的配合、`$el` 的边界
- [[Props 组件属性]] —— props 的系统性说明
- [[Events 自定义事件]] —— 自定义事件的完整规则与 `v-model`
- [[00 组件通信与插槽总览]] —— 组件通信全景

> [!success] 一句话收尾
> **`defineProps` 收数据，`defineEmits` 发通知，`defineExpose` 交遥控器；三者都是编译宏，只能在 `<script setup>` 顶层写。** 优先用数据流（props / emits），只有父组件确实需要"命令子组件做事"时，才用 ref + defineExpose 开一个小口。
