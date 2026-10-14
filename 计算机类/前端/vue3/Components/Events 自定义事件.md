# Events 自定义事件

> [!abstract] 一句话
> props 是父 → 子的**下行**通道（父给子数据），==自定义事件则是子 → 父的**上行**通道==：子组件用 `emit('事件名', 数据)` 抛出消息，父组件用 `@事件名="处理函数"` 接住。一上一下，才构成 Vue 单向数据流的完整闭环——**数据向下流，通知向上走**。

---

## 一、为什么需要自定义事件

子组件**改不了 props**（只读），可它总得把"发生了什么"告诉父组件——用户点了删除、输入框内容变了、翻页了。它不能"改"，只能"喊"，喊的方式就是触发事件。

```text
   父组件 ──① props 下行（只读）──▶ 子组件 props（只读，不能改）
   父组件 ◀──② emit 上行（通知）── 子组件 emit('add', 1)
     └─ @add="count += $event"     ← 父自己改自己的数据
```

> [!info] 单向数据流闭环
> 子组件**永远不碰**父的数据，只负责"报告发生了什么"；改不改、怎么改由父组件自己决定。数据来源只有一个，出问题时顺着链条往回查即可。

> [!quote] 一句话记忆
> **props 父传子，emit 子告父；子改不了父，只能通知父自己改。**

---

## 二、触发与监听：最小闭环

### 2.1 子组件：`emit` 触发

`defineEmits()` 会返回一个 **`emit` 函数**，调用它就是"抛事件"：

```vue
<!-- Child.vue -->
<script setup>
const emit = defineEmits(['add'])   // ① 声明本组件会抛哪些事件，返回 emit

function handleClick() {
  emit('add', 1)                    // ② 抛事件：事件名 + 载荷（payload）
}
</script>

<template>
  <button @click="handleClick">+1</button>
</template>
```

### 2.2 父组件：`@` 监听

```vue
<!-- Parent.vue -->
<script setup>
import { ref } from 'vue'
import Child from './Child.vue'
const count = ref(0)
</script>

<template>
  <Child @add="count += $event" />   <!-- $event = emit 的第一个参数 -->
</template>
```

> [!tip] `$event` 是什么
> 在**组件事件**里，`$event` 就是子组件 emit 时传的**第一个参数**；它与 DOM 原生事件的 `$event`（Event 对象）同名不同义。

> [!warning] 事件没有返回值
> `emit()` 不返回任何东西，父的处理结果也不会传回子组件。事件是"单向广播"而非"函数调用"——子组件要拿结果，得让父**再传一个 prop 下来**。

---

## 三、声明 emits：三种写法

`defineEmits` 是**编译宏**（不用 import，也不产生运行时代码），必须写在 `<script setup>` 的**顶层**，不能塞进函数里。

### 3.1 数组式：最简单

```vue
<script setup>
const emit = defineEmits(['change', 'update'])
emit('change'); emit('update', 42)
</script>
```

够用，但**没有类型提示，拼错事件名不会被发现**，正经项目不推荐。

### 3.2 对象式：带参数校验

键是事件名，值是校验函数（返回 `false` 会在开发环境报警告）：

```vue
<script setup>
const emit = defineEmits({
  change: (payload) => typeof payload === 'string',
  update: (id, silent) => typeof id === 'number' && typeof silent === 'boolean',
  reset: null                       // 传 null 表示这个事件不校验
})
emit('change', 'hi')                // ✅ 通过
emit('change', 123)                 // ⚠️ 开发环境警告：校验失败
</script>
```

> [!note] 校验只在开发环境跑
> 生产构建时校验函数会被**编译剔除**，不影响运行时性能。它和 props 的 `type` 是一个思路：==帮你抓 bug，不帮你拦截数据==。

### 3.3 TS 类型式：最推荐

Vue 3.3+ 用**命名元组**描述每个事件的参数列表；3.3 之前是调用签名式 `defineEmits<{ (e: 'change', p: string): void }>()`，仍兼容但已不推荐：

```vue
<script setup lang="ts">
const emit = defineEmits<{
  change: [payload: string]              // emit('change', 'hi')
  update: [id: number, silent: boolean]  // emit('update', 1, true)
  close: []                              // emit('close') —— 无参数
}>()
</script>
```

> [!success] 为什么 TS 式最好
> 编辑器里 `emit(` 一敲就自动补全事件名和参数类型；**拼错名字、少传参数、传错类型**全在编译期报错，不必等运行时。

> [!danger] 类型参数不能"绕弯"
> 类型参数必须是**内联字面量**写法，编译器要在编译阶段静态读到它；`defineEmits` 也不能被赋值给变量再传递。

---

## 四、为什么"必须"声明 emits（重点）

不声明也能跑——但代价藏在**透传属性**里。

### 4.1 不声明：监听器变成透传属性（fallthrough attrs）

Vue 3 里，写在组件标签上、却没被 props / emits 消费的东西，会作为**透传属性**自动加到组件**根元素**上——事件监听器也不例外：

```vue
<!-- Child.vue：没有声明 emits -->
<script setup>defineProps(['count'])</script>
<template>
  <button>点我</button>   <!-- 唯一的根元素 -->
</template>
```

```vue
<!-- 父组件：@add 没被消费，被当普通 attr 透传到根元素 <button> 上 -->
<Child :count="1" @add="onAdd" />
```

| 后果 | 说明 |
| --- | --- |
| 语义错乱 | `@add` 变成了 DOM 原生事件的监听器，不再是"组件事件" |
| 触发两次 | 子组件内部也 `emit('add')` 时，父的处理函数被**原生 + 自定义**触发两次 |
| 静默失败 | 事件名不匹配任何原生事件时，监听器**悄无声息不生效**，最难排查 |

> [!warning] 触发两次的经典现场
> 子组件根元素是 `<button>`，父组件写 `@click`，子组件内部又 `emit('click')`——点一下，处理函数跑**两次**：一次来自透传到 button 的原生 click，一次来自 emit 的组件事件。

### 4.2 声明后：被当作组件事件消费

```vue
<script setup>
const emit = defineEmits(['add'])    // ① 声明后，@add 不再透传
const add = () => emit('add', 1)
</script>

<template>
  <button @click="add">+1</button>   <!-- ② 只有组件自己的 emit 触发 @add -->
</template>
```

声明之后，父组件的 `@add` **不再落到根元素**，而是注册成**组件事件监听器**，只在子组件 `emit('add')` 时触发，也不会误绑到 DOM 原生事件上。

> [!success] 记住这条
> **声明 emits 的本质，是告诉 Vue："这个名字是我的自定义事件，别当透传属性往根元素上丢。"** 声明 = 从透传 attrs 里**摘出来**，升级成正式的组件对外接口。

> [!note] 联系 [[属性继承]]
> 透传属性的完整机制、`inheritAttrs: false` 怎么关、`v-bind="$attrs"` 怎么手动接，都在 [[属性继承]] 里。这里只记住：**emits 声明是事件层面的"拦截开关"**，与 `inheritAttrs` 是同一套 attrs 分流逻辑的两面。

### 4.3 想监听原生事件怎么办？

| 需求 | 做法 |
| --- | --- |
| 就是要让 `@click` 落到根元素 | **不要**在 emits 里声明 `click`，让它透传 |
| `click` 是子组件自己的语义事件 | 在 emits 里声明 `click`，此时 `@click` 只对应 `emit('click')` |
| 想精确控制落点 | `inheritAttrs: false` + 在模板里手动 `v-bind="$attrs"` |

> [!question] 为什么在组件上写 `@click` 有时灵、有时不灵？
> **没声明 `click`**：透传到根元素——根是 `<button>` 就灵。**声明了 `click`**：不再透传，只有子组件 `emit('click')` 才触发，根元素的点击**反而不触发**了。这正是"加了 emits 声明后 `@click` 突然失灵"的原因——不是失灵，是**语义被收编了**。

---

## 五、事件名规则：声明 camelCase，监听 kebab-case

| 场景 | 推荐写法 | 例子 |
| --- | --- | --- |
| `defineEmits` 声明 | **camelCase** | `defineEmits(['itemChange'])` |
| `emit()` 调用 | **camelCase**，与声明完全一致 | `emit('itemChange', x)` |
| 父模板监听 | **kebab-case**（推荐） | `<Child @item-change="fn" />` |

```vue
<script setup>
const emit = defineEmits(['itemChange'])   // 子组件：声明与调用都用 camelCase
emit('itemChange', 42)
</script>

<template>
  <Child @item-change="onChange" />   <!-- ✅ 推荐：两种都能对上，kebab-case 最稳 -->
</template>
```

> [!warning] 为什么模板推荐 kebab-case
> HTML 属性名**天生不区分大小写**（浏览器会把 `@itemChange` 读成 `itemchange`）。SFC 编译器会把两种写法都归一到 `onItemChange`，所以 `.vue` 里 camelCase 也能跑；但 **DOM 内模板**（直接写在 `index.html` 里）或字符串模板中，只有 **kebab-case 一定不会错**。

> [!danger] 例外：`v-model` 相关事件保留 camelCase 前缀
> `update:modelValue`、`update:title` 这类带冒号的事件名，按 [[v-model]] 的约定书写，别改成 kebab-case。

> [!note] Vue 3 与 Vue 2 的差别
> Vue 2 里 `emit('itemChange')` 会**自动**匹配 `@item-change`；Vue 3 **取消了这层自动转换**。口诀：**内部一律 camelCase，模板监听写 kebab-case**。

---

## 六、事件参数

```vue
<!-- 子组件：想传几个就传几个 -->
<script setup>
const emit = defineEmits(['close', 'change', 'select'])
emit('close')                     // 无参数
emit('change', 'hello')           // 单个参数
emit('select', id, name, meta)    // 多个参数
</script>

<template>
  <!-- 父组件：对应用三种方式接住 -->
  <Child @close="onClose" />
  <Child @change="text = $event" />                           <!-- 单参数用 $event -->
  <Child @select="(id, name, meta) => log(id, name, meta)" /> <!-- 多参数用箭头函数 -->
</template>
```

> [!warning] 多参数时 `$event` 只拿第一个
> `$event` 只等于 emit 的**第一个参数**。要接住全部参数，**必须**用内联箭头函数或具名方法。

> [!tip] 载荷建议打包成一个对象
> ```js
> emit('save', id, title, content, isDraft)      // ❌ 父组件得对着顺序数位置
> emit('save', { id, title, content, isDraft })  // ✅ 语义清晰、可扩展、TS 有字段提示
> ```

---

## 七、`v-model` 与事件的渊源

`<Child v-model="text" />` 编译后等价于 `:modelValue` 传值 + `@update:modelValue` 监听回写：

```vue
<Child :modelValue="text" @update:modelValue="text = $event" />
```

==自定义事件就是 `v-model` 的地基==：`v-model` 只是把"传值 + 监听回写"这对动作缩成了一个语法糖。

### 7.1 手写一个支持 v-model 的子组件

```vue
<!-- MyInput.vue -->
<script setup>
const props = defineProps(['modelValue'])
const emit = defineEmits(['update:modelValue'])

function onInput(e) {
  emit('update:modelValue', e.target.value)   // 不直接改 props，抛事件让父去改
}
</script>

<template>
  <input :value="props.modelValue" @input="onInput" />
</template>
```

### 7.2 用 `defineModel` 一步到位（Vue 3.4+）

```vue
<script setup>
const model = defineModel()   // 自动生成 props + update 事件
</script>

<template>
  <input v-model="model" />   <!-- 直接赋值，自动 emit 同步回父 -->
</template>
```

> [!info] 引导
> 命名 v-model（`v-model:title`）对应事件 `update:title`；多个 v-model 就是多对 "prop + update 事件"。完整推导见 [[v-model]]——**把这里的事件机制看懂，那边就只剩语法糖了**。

---

## 八、完整小例子：子组件让父组件"改数据"

```vue
<!-- CounterButton.vue（子组件） -->
<script setup lang="ts">
const props = defineProps<{ count: number }>()          // 只读入参

const emit = defineEmits<{                              // 声明会抛的事件
  add: [step: number]
  reset: []
  overflow: [message: string]                            // 复杂载荷示例
}>()

function handleAdd() {
  if (props.count + 1 > 99) {
    emit('overflow', `已达上限：${props.count}`)          // 报告异常情况
    return
  }
  emit('add', 1)                                        // 只报告"要加 1"，不自己改
}
</script>

<template>
  <span>子组件看到的值：{{ props.count }}</span>
  <button @click="handleAdd">+1</button>
  <button @click="emit('reset')">重置</button>
</template>
```

```vue
<!-- Parent.vue（父组件） -->
<script setup lang="ts">
import { ref } from 'vue'
import CounterButton from './CounterButton.vue'

const count = ref(0)
const onAdd = (step: number) => (count.value += step)   // 父自己改自己的数据
const onReset = () => (count.value = 0)
const onOverflow = (msg: string) => console.warn(msg)
</script>

<template>
  <CounterButton :count="count"
                 @add="onAdd" @reset="onReset" @overflow="onOverflow" />
</template>
```

> [!success] 这段代码的三个要点
> ① 子组件**从不写** `props.count++`（props 只读）；② 子组件只 `emit`，"改"的动作由父组件的 `onAdd` 完成；③ 连"超过 99 该怎么办"都由父决定，子组件只把情况报上去——**决策权始终在父组件手里**。

---

## 九、TypeScript 深入

### 9.1 把事件签名抽成类型 + 复杂载荷

```vue
<script setup lang="ts">
interface User { id: number; name: string; roles: string[] }

type Emits = {
  submit: [user: User]                            // 对象载荷
  request: [done: (ok: boolean) => void]          // 回调载荷（少见但有用）
  status: [state: 'idle' | 'loading' | 'error']   // 联合类型
}
const emit = defineEmits<Emits>()
</script>
```

> [!note] 与 `defineProps` 一样的能力边界
> Vue 3.3+ 支持从外部文件 `import type` 事件类型；更早版本要求类型**内联在 `defineEmits<>` 里**，否则编译器解析不到。同类限制见 [[setup语法糖]]。

### 9.2 类型安全的意义

```ts
emit('submit', { id: 1, name: 'A', roles: [] })   // ✅ 通过
emit('status', 'loading')                          // ✅ 通过
emit('submit', { id: 1 })                          // ❌ 缺 name / roles，编译期报错
emit('status', 'success')                          // ❌ 不在联合类型里
emit('unknownEvent')                               // ❌ 事件名根本没声明
```

> [!tip] 为什么值得多写这几行
> 组件事件是**跨组件的接口**。接口没类型就只是"口头约定"——子组件改了事件名或载荷结构，父组件只有**运行时**才知道炸了；TS 把它变成**编译期**错误。

---

## 十、常见坑 / 常见问题

> [!question] 事件为什么触发了两次？
> 最典型的原因是**没声明 emits**：父组件的 `@click` / `@xxx` 被当透传属性挂到根元素上（见第四节），同时子组件又 `emit` 了同名事件。解法是在 `defineEmits` 里**声明该事件**，它就会从透传 attrs 里被摘出来，只触发一次。

> [!question] 事件名到底该用 camelCase 还是 kebab-case？
> **声明和 `emit` 用 camelCase（两者必须完全一致），模板监听用 kebab-case。** Vue 3 不再自动转换大小写，`@itemchange` 会静默失效；DOM 内模板里只有 kebab-case 保险。

> [!question] 组件上写 `@click` 到底监听的是什么？
> **没声明 `click`**：透传到根元素，监听的是**根元素的原生点击**；**声明了 `click`**：监听的是**子组件 `emit('click')`**，根元素的点击不再触发它。所以"声明后 `@click` 失灵"不是 bug，是语义被收编。

> [!question] 能监听到子组件内部 DOM 的原生事件吗？
> Vue 3 **没有** Vue 2 的 `.native` 修饰符。要监听内部元素的原生事件，让子组件自己 `emit` 一个语义化事件（如 `submit`）出来，而不是把 DOM 事件原样透出去——这也是更好的封装。

> [!question] `emit` 有返回值吗？父处理完能告诉子组件结果吗？
> **没有返回值。** 事件是单向广播。需要"回传结果"时，父组件把结果存进 data 再通过 **props 传下来**，或让子组件传一个回调函数当载荷（见 9.1 的 `request`）。

> [!question] `defineEmits` 能放进函数里或条件里吗？
> **不能。** 它是编译宏，必须在 `<script setup>` **顶层**调用，且类型参数要能被编译器静态读到。

---

## 相关笔记

- [[Props 组件属性]] —— 下行通道；props 的只读性正是需要事件的原因
- [[属性继承]] —— 透传属性（fallthrough attrs）机制、`inheritAttrs: false`、`v-bind="$attrs"`
- [[v-model]] —— `update:modelValue` 事件如何支撑双向绑定语法糖
- [[setup语法糖]] —— `defineEmits` 作为编译宏的基础用法与其它宏一览
- [[SFC]] / [[组件注册]] —— 单文件组件结构与组件的注册引用
- [[TypeScript vs JavaScript]] —— `defineEmits<{...}>()` 泛型写法的类型基础
- [[项目结构树解析]] —— 组件放在 `src/components/` 的位置约定

---

参考：Vue 官方文档 —— Component Events（Declaring / Emitting / Validation）、Fallthrough Attributes、`<script setup>` 编译宏 `defineEmits`；Vue 3.3（命名元组式事件类型）、3.4（`defineModel`）更新日志；Vue 2 → 3 迁移指南（移除 `.native` 修饰符、不再自动转换事件名大小写）
