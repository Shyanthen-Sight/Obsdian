# defineProps() 和 defineEmits()

> [!abstract] 一句话区别
> **`defineProps` 管"进"，`defineEmits` 管"出"。**
> 父组件 → 子组件传数据用 `defineProps`；子组件 → 父组件发通知用 `defineEmits`。
> 前者返回一个**只读**的 props 对象，后者返回一个**可调用**的 `emit` 函数。

二者都是 Vue 3 `<script setup>` 中的**编译宏**（compiler macro），不需要 `import`，只能在 `<script setup>` 顶层使用，编译时会被移除，不会出现在最终运行代码里。

---

## 一、核心区别总览

| 对比项 | `defineProps` | `defineEmits` |
| --- | --- | --- |
| 数据方向 | 父 → 子（向下） | 子 → 父（向上） |
| 解决的问题 | 子组件**接收**外部数据 | 子组件**通知**父组件发生了某事 |
| 返回值 | props 对象（**只读**） | `emit` 函数（**可调用**） |
| 声明内容 | 属性名 + 类型 / 校验 | 事件名 + 参数类型 / 校验 |
| 数据流规则 | 单向数据流，子组件**不得修改** props | 事件只是消息，具体怎么改由父组件决定 |
| 在模板中 | 可直接用属性名访问 | 用 `@事件名` 监听 |
| 类比 | 函数的**入参** | 回调函数 / 事件总线 |

一句话记忆：**`props` 是"你给我什么"，`emits` 是"我告诉你发生了什么"。**

---

## 二、`defineProps` 详解

### 1. 基本用法（运行时声明）

```vue
<!-- Child.vue -->
<script setup>
const props = defineProps({
  title: String,
  count: {
    type: Number,
    default: 0,
    required: false,
    validator: (v) => v >= 0
  }
})
</script>

<template>
  <h2>{{ title }}</h2>
  <p>{{ count }}</p>
</template>
```

父组件：

```vue
<Child title="你好" :count="5" />
```

模板中访问 props 有**三种写法**，取到的值完全相同，区别只在于"有没有对应的变量可用"：

| 写法                   | 前提条件                                | 说明                                                                                    |
| -------------------- | ----------------------------------- | ------------------------------------------------------------------------------------- |
| `{{ title }}`        | 无需赋值                                | 编译器会把 props 的每个属性自动注入模板作用域，等价于 `$props.title`。<font color="#c00000">**推荐**</font>，最简洁 |
| `{{ props.title }}`  | 必须 `const props = defineProps(...)` | 就是普通变量访问，`props` 是你自己接住的返回值；变量名可改，叫 `p` 就写 `p.title`                                  |
| `{{ $props.title }}` | 总是可用                                | 模板内置的组件实例属性，不依赖任何声明；但只包含**声明过的 props**，未声明的属性在 `$attrs` 里                             |

#### 三种情况的完整示例

```vue
<script setup>
// 情况 A：把返回值赋给 props
const props = defineProps({ title: String })
</script>
<template>
  {{ title }}         <!-- ✅ 自动注入 -->
  {{ props.title }}   <!-- ✅ props 变量存在 -->
  {{ $props.title }}  <!-- ✅ 内置属性 -->
</template>
```

```vue
<script setup>
// 情况 B：只调用，不赋值
defineProps({ title: String })
</script>
<template>
  {{ title }}         <!-- ✅ -->
  {{ props.title }}   <!-- ❌ props 未定义，运行时报错/警告 -->
  {{ $props.title }}  <!-- ✅ -->
</template>
```

```vue
<script setup>
// 情况 C：换个变量名
const p = defineProps({ title: String })
</script>
<template>
  {{ p.title }}       <!-- ✅ -->
  {{ props.title }}   <!-- ❌ 没有 props 这个变量 -->
</template>
```

```vue
<script setup>
// 情况 D：Vue 3.5+ 响应式解构
const { title } = defineProps<{ title: string }>()
</script>
<template>
  {{ title }}         <!-- ✅ -->
  {{ props.title }}   <!-- ❌ props 变量不存在 -->
  {{ $props.title }}  <!-- ✅ -->
</template>
```

#### 补充说明

- 三种写法编译后都是对**同一个 props 对象**的访问，**没有性能差异**，纯风格选择。社区惯例是直接用 `title`，只有在想强调"这是 props"或避免与本地变量重名时才写 `props.title`。
- `<script setup>` 的 JS 部分没有这层模板注入，所以必须写 `props.title`（或解构出来的 `title`）。
- 未在 `defineProps` 中声明的属性（如 `class`、`style`、`id`、未声明的事件监听）不会出现在 `props` / `$props` 中，而是落到 `$attrs`，可通过 `useAttrs()` 或 `$attrs` 访问。
- `$props` 只在**模板**中可用，`<script setup>` 里没有这个变量。
- 声明了但父组件没传且无 `default` 时，值为 `undefined`（布尔类型除外，见下方注意）。

### 2. 类型声明（TypeScript）

```vue
<script setup lang="ts">
interface Props {
  title?: string
  count?: number
  list: string[]
}

const props = defineProps<Props>()
</script>
```

配合 `withDefaults` 给默认值（Vue 3.5 之前）：

```ts
const props = withDefaults(defineProps<Props>(), {
  title: '默认标题',
  count: 0,
  list: () => []      // 对象/数组默认值必须用工厂函数
})
```

> [!tip] Vue 3.5+ 的响应式 Props 解构
> Vue 3.5 起支持直接解构并保持响应性：
> ```ts
> const { title, count = 0 } = defineProps<Props>()
> ```
> 而在旧版本中解构会**丢失响应性**，这是经典坑。

### 3. props 是只读的

```ts
props.count++          // ❌ 警告：Set operation on key "count" failed: target is readonly
```

子组件不能直接改 props，这是**单向数据流**的保证。需要修改时：

1. 用 `defineEmits` 通知父组件去改；或
2. 在子组件内用 `computed` / 本地 `ref` 做派生副本：
   ```ts
   const localCount = ref(props.count)
   ```

### 4. 布尔类型的特殊行为

```ts
defineProps({ disabled: Boolean })
```

```vue
<Child disabled />        <!-- 等价于 :disabled="true" -->
```

只写属性名不赋值 = `true`，这是 HTML 属性风格的延续。

### 5. 命名约定

- JS 中声明：`camelCase`（如 `userName`）
- 模板中传值：`kebab-case`（如 `:user-name="name"`），Vue 会自动转换，两者都能用，但推荐 kebab-case，避免大小写歧义。

---

## 三、`defineEmits` 详解

### 1. 基本用法（运行时声明）

```vue
<!-- Child.vue -->
<script setup>
const emit = defineEmits(['update', 'delete'])

function handleClick() {
  emit('update', 123)          // 触发 update 事件，携带参数 123
}

function handleDelete() {
  emit('delete')
}
</script>

<template>
  <button @click="handleClick">更新</button>
  <button @click="handleDelete">删除</button>
</template>
```

父组件监听：

```vue
<Child @update="onUpdate" @delete="onDelete" />
```

### 2. 带参数校验的写法

```js
const emit = defineEmits({
  // 返回 false 会在开发环境警告，但不会阻止事件
  submit: (payload) => {
    if (!payload.id) {
      console.warn('缺少 id')
      return false
    }
    return true
  },
  cancel: null   // null 表示不校验
})
```

### 3. 类型声明（TypeScript）

```vue
<script setup lang="ts">
// 方式一：具名元组（更推荐，参数名有意义）
const emit = defineEmits<{
  update: [id: number, name: string]
  delete: [id: number]
  close: []
}>()

// 方式二：函数签名
const emit = defineEmits<{
  (e: 'update', id: number, name: string): void
  (e: 'delete', id: number): void
  (e: 'close'): void
}>()

emit('update', 1, 'Tom')   // ✅ 类型检查通过
emit('update', '1')        // ❌ TS 报错
</script>
```

### 4. 事件名命名

- 声明和 `emit` 时用 `camelCase`（如 `emit('itemClick')`）。
- 模板监听时用 `kebab-case`（`@item-click`），Vue 会自动匹配。
- 但**强烈建议风格统一**：全用 camelCase 声明 + kebab-case 监听，或自定义事件统一 kebab-case。

> [!warning] 不要与原生事件混淆
> ```vue
> <Child @click="handler" />
> ```
> 如果子组件没有 `defineEmits(['click'])` 且根元素是原生元素，`@click` 作为**透传属性（fallthrough attrs）**会绑定到子组件根节点上，监听的是原生点击，不是自定义事件。想自定义 `click` 事件，必须在 `defineEmits` 中声明它。

### 5. v-model 的本质

`v-model` 在组件上就是 `:modelValue` + `@update:modelValue` 的语法糖：

```vue
<!-- 等价写法 -->
<Child :modelValue="val" @update:modelValue="val = $event" />
```

子组件内部：

```ts
const props = defineProps<{ modelValue: string }>()
const emit = defineEmits<{ 'update:modelValue': [value: string] }>()

function onInput(e) {
  emit('update:modelValue', e.target.value)
}
```

Vue 3.4+ 可用更简洁的 `defineModel()` 同时完成这两件事：

```ts
const value = defineModel<string>()   // 自动定义 prop + emit
```

> `defineModel` 本质是 `defineProps` + `defineEmits` 的封装，理解前两者才能理解它。

---

## 四、完整父子通信示例

```vue
<!-- Parent.vue -->
<script setup>
import { ref } from 'vue'
import Counter from './Counter.vue'

const total = ref(0)

function handleAdd(step) {
  total.value += step
}
</script>

<template>
  <!-- 父 → 子：通过 props -->
  <Counter :step="2" :total="total" @add="handleAdd" />
</template>
```

```vue
<!-- Counter.vue -->
<script setup>
// 接收父组件数据（只读）
const props = defineProps({
  step: { type: Number, default: 1 },
  total: { type: Number, required: true }
})

// 声明要派发的事件
const emit = defineEmits(['add'])

function click() {
  // 不直接改 props.total，而是通知父组件
  emit('add', props.step)
}
</script>

<template>
  <p>当前：{{ total }}</p>
  <button @click="click">+{{ step }}</button>
</template>
```

数据流闭环：父传 `step`/`total` → 子点击 → `emit('add', step)` → 父的 `handleAdd` 修改 `total` → 新值再通过 props 流回子组件。

---

## 五、常见坑与最佳实践

1. **props 解构丢响应性**（Vue 3.5 之前）：用 `props.xxx` 或 `toRefs`。
   ```ts
   const { title } = toRefs(props)   // 旧版本写法
   ```
2. **直接修改 props**：永远不要。改数据要么走事件，要么在子组件里建本地副本。
3. **忘记声明事件**：未声明也能 `emit`，但没有类型/校验提示，且容易与透传 attrs 冲突。
4. **事件名大小写**：`emit('updateValue')` 在模板中用 `@update-value` 监听；如果写 `@updateValue`，在 DOM 模板（非 SFC）中会因为 HTML 大小写不敏感而失效。
5. **默认值是对象/数组**：必须用工厂函数 `() => ({})`，否则所有实例共享同一个引用。
6. **宏不能引用外部变量**：`defineProps` / `defineEmits` 编译期处理，参数必须是字面量或同文件内声明的类型，不能引用 `import` 进来的运行时变量（类型导入可以）。
7. **`defineEmits` 的返回值必须接收**：`const emit = defineEmits([...])`，否则没法派发。

---

## 六、记忆口诀

> **Props 进，Emits 出；**
> **Props 只读，Emits 只喊；**
> **数据往下走，事件往上报；**
> **子想改父，先 emit 再说。**
