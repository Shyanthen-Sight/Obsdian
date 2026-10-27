
> [!abstract] 一句话
> props 是==父组件传给子组件的单向数据通道==，也就是组件的"入参"。父组件在标签上写属性，子组件用 `defineProps` 声明它接收哪些名字——==数据只能自上而下流，子组件无权改，只能请求父组件改==。

---

## 一、定位：为什么需要 props

组件是"零件"，一个 `UserCard` 要能在十个地方复用，靠的就是**同样的模板 + 不同的数据**。这个"不同的数据"就是 props。

```text
   父组件（App.vue）                        子组件（UserCard.vue）
  <UserCard name="小明" :age="18" />   ──▶   defineProps({ name: String, age: Number })
                    单向、只读、响应式
```

> [!info] 三个关键词
> - **自上而下**：只能父 → 子。子组件没有直接改父数据的权力。
> - **声明式**：子组件必须先"声明"自己接收什么，父组件乱传的属性不进去（会落到 `attrs`，见 [[属性继承]]）。
> - **响应式**：父组件的数据变了，子组件的 props 会自动跟着更新。

> [!quote] 类比
> props 就像函数的**形参**：`defineProps` 是函数签名，父组件传值相当于**实参**。函数内部不该改传进来的参数——props 也是同样的道理。

---

## 二、声明 props：三种方式

### 2.1 数组语法（最简，不推荐生产用）

```vue
<script setup>
const props = defineProps(['title', 'likes'])   // 只声明"有哪几个"，不做任何校验
</script>
```

> [!warning] 数组写法没有类型、没有默认值、没有必填校验
> 只适合写 demo。生产代码一律用对象或 TS 泛型。

### 2.2 对象语法（含校验，Vue 3 Options 风格）

```vue
<script setup>
const props = defineProps({
  title:  { type: String,  required: true },        // 必填
  likes:  { type: Number,  default: 0 },            // 默认值 0
  author: { type: String,  default: '匿名' },
  tags:   { type: Array,   default: () => [] },     // ⚠️ 数组/对象必须用工厂函数
  isVIP:  { type: Boolean, default: false }
})
</script>
```

### 2.3 TypeScript 泛型（`<script setup lang="ts">`，最推荐）

```vue
<script setup lang="ts">
// 用类型注解声明，编译期就有校验 + 编辑器提示
const props = defineProps<{
  title: string
  likes?: number            // ? 表示可选
  author?: string
}>()
</script>
```

### 2.4 给 TS 写法补默认值：`withDefaults`

TS 泛型里写不了 `default`，要用 `withDefaults` 包一层（Vue 3.3+ 还支持直接用响应式解构默认值，见第八节）：

```vue
<script setup lang="ts">
interface Props {
  title: string
  likes?: number
  tags?: string[]
}

const props = withDefaults(defineProps<Props>(), {
  likes: 0,
  tags: () => []            // 数组/对象同样必须用工厂函数
})
</script>
```

> [!tip] 三种写法怎么选
> | 场景 | 用哪个 |
> | --- | --- |
> | 快速 demo / 原型 | 数组 |
> | JS 项目、需要精细校验 | 对象 |
> | TS 项目（推荐） | 泛型 + `withDefaults` |

---

## 三、传递 props：父组件怎么写

### 3.1 静态传递 vs 动态传递

```vue
<template>
  <!-- 静态：不写冒号，值就是字符串字面量 -->
  <BlogPost title="我的第一篇笔记" author="小明" />

  <!-- 动态：加冒号（v-bind 简写），值是"表达式"而非字符串 -->
  <BlogPost :title="postTitle" :likes="post.likes" :is-vip="user.isVIP" />
</template>
```

### 3.2 一次性传多个：`v-bind="对象"`（对象展开）

当一个对象里的字段刚好和 props 一一对应时，用 `v-bind="post"` 一把梭：

```vue
<script setup>
const post = { title: '标题', likes: 42, author: '小明' }
</script>

<template>
  <!-- 等价于 :title="post.title" :likes="post.likes" :author="post.author" -->
  <BlogPost v-bind="post" />
</template>
```

> [!tip] 传对象本身 ≠ 展开对象
> ```vue
> <BlogPost :post="post" />    <!-- 传的是一个整体，子组件声明 post: Object -->
> <BlogPost v-bind="post" />   <!-- 把 post 的每个键拆成独立 prop -->
> ```
> 这两行**完全不同**。`v-bind` 后面没跟属性名才是展开。也可以混搭 `v-bind="{ ...post, title: '覆盖' }"`，后面的键覆盖前面的。

---

## 四、命名规则：camelCase 声明，kebab-case 传

这是最容易踩的小坑。**HTML 属性名大小写不敏感**（浏览器会把 `postTitle` 渲染成 `posttitle`），所以历史上 Vue 约定：

| 位置 | 推荐写法 | 例子 |
| --- | --- | --- |
| 子组件**声明** | camelCase | `defineProps({ postTitle: String })` |
| 父组件**模板传**（DOM 内模板） | kebab-case | `<BlogPost post-title="hi" />` |
| 父组件**模板传**（SFC 模板） | 两种都行 | `post-title` / `postTitle` 都可以 |

> [!success] 一句话记
> **声明用 camelCase，模板里用 kebab-case 最保险。**
> 因为 SFC 的 `<template>` 会被 Vue 编译器处理（不是浏览器直接解析），所以 `postTitle` 也能识别；但写在 HTML 里的模板（`in-DOM template`）只有 kebab-case 靠谱。

---

## 五、单向数据流（重点）：props 只读

Vue 有一条铁律：**props 是只读的，子组件不得直接修改**。运行时直接赋值会报警告。

```vue
<!-- ❌ 错误示范 -->
<script setup>
const props = defineProps({ count: Number })
props.count++            // ⚠️ 控制台警告：Set operation on key "count" failed: target is readonly
</script>
```

> [!danger] 为什么必须只读？
> 父组件的数据可能同时喂给多个子组件。如果子组件能随意改，**数据流向会失控**，你根本查不出是谁改的、什么时候改的。只读保证了"数据和它的来源永远一致"，这是可维护性的底线。

### 想"改"props 的三条正当路径

```text
                       props（只读）
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
   ①本地副本 ref      ②computed 派生       ③emit 请父组件改
   const l = ref(props.x)  computed(() => ...)   emit('update:count', n)
```

#### ① 用本地 `ref` 复制一份，当作可变初始值

```vue
<script setup>
import { ref, watch } from 'vue'
const props = defineProps({ initialCount: Number })

const count = ref(props.initialCount)            // 用 props 初始化本地状态
watch(() => props.initialCount, v => count.value = v)  // 需要跟随父组件时才加
// 之后随便改 count.value，与 props 无关
</script>
```

> [!warning] 复制一份 = 放弃自动同步
> 本地副本和 props 从此是两条数据线。父组件更新 props，本地 `ref` **不会**自动变（除非你加 `watch`）。用之前想清楚谁是"唯一数据源"。

#### ② 用 `computed` 派生（读多写少场景）

如果只是想基于 props "算"出一个新值，不需要写回，那就用 `computed`：

```vue
<script setup>
import { computed } from 'vue'
const props = defineProps({ firstName: String, lastName: String })

// 派生值：只读，但会自动跟随 props 更新
const fullName = computed(() => `${props.firstName} ${props.lastName}`)
</script>
```

> [!success] 优先考虑 `computed`
> 绝大多数"想改 props"的需求，其实只是想**派生**。`computed` 会自动响应 props 变化，比手动 `ref` + `watch` 干净得多。

#### ③ 需要真正改 → 通过 emit 让父组件改

这是"双向"场景的正解：子组件不越权，只**通知**父组件，由父组件改自己的数据。

```vue
<!-- Child.vue：只发信号，不改 props -->
<script setup>
const props = defineProps({ count: Number })
const emit = defineEmits(['update:count'])
function plus() {
  emit('update:count', props.count + 1)
}
</script>
<template>
  <button @click="plus">{{ count }} +1</button>
</template>
```

```vue
<!-- Parent.vue：监听事件，改自己的数据 → 再流回子组件 -->
<template>
  <Child :count="n" @update:count="n = $event" />
</template>
```

> [!tip] 这就是 `v-model` 的底层
> `<Child v-model="n" />` 正是 `:count="n"` + `@update:count="n = $event"` 的语法糖。
> 详见 [[Events 自定义事件]] 与 [[v-model]]。

---

## 六、prop 校验

对象写法（以及 TS 泛型）支持完整的校验规则，Vue 会在**开发环境**帮你检查并在控制台警告。

### 6.1 `type`：类型

```js
defineProps({
  a: String,
  b: Number,
  c: Boolean,
  d: Array,
  e: Object,
  f: Date,
  g: Function,
  h: Symbol,
  i: null,               // 允许任意类型
  j: [String, Number],   // 多个类型：满足其一即可
  k: Person              // 自定义构造函数，用 instanceof 校验
})
```

| 写法 | 含义 |
| --- | --- |
| `type: String` | 字符串 |
| `type: [String, Number]` | **多类型**，符合其一即通过 |
| `type: Person` | 自定义类，用 `instanceof Person` 判断 |
| `type: null` | 显式允许任意类型 |

> [!warning] `type` 只是开发期校验，不是强约束
> 校验不通过**只会打印警告**，不会中断渲染。别把 props 校验当成"运行时安全边界"，它更像是"给开发者的提醒"。真正的强约束要靠 TS。

### 6.2 `required` / `default`：必填与默认值

```js
defineProps({
  title:  { type: String, required: true },      // 不传就警告
  likes:  { type: Number, default: 0 },          // 不传时为 0
  author: { type: String, default: '匿名' }
})
```

> [!danger] 对象 / 数组的 `default` 必须用工厂函数！
> ```js
> // ❌ 危险：所有实例共享同一个数组/对象
> tags: { type: Array, default: [] }
> // ✅ 正确：每次实例化都调用函数，返回全新对象
> tags: { type: Array, default: () => [] }
> ```
> 用字面量会让**所有组件实例共享同一份引用**，一个实例往里 push，其它实例也跟着变——极难排查的 bug。原理同"函数默认参数不要用可变对象"。

### 6.3 `validator`：自定义校验函数

```js
defineProps({
  size: {
    type: String,
    validator: (value) => ['small', 'medium', 'large'].includes(value)
    // 返回 false 时，控制台警告：Invalid prop: custom validator check failed
  }
})
```

> [!note] `validator` 只在开发环境执行
> 生产构建会把这部分代码摇掉（tree-shake），不影响性能。

---

## 七、Boolean 转换（Boolean Casting）

Vue 模仿了 HTML 的布尔属性行为：**只要声明为 `Boolean`，写个没有值的属性就等于 `true`**——`<MyComp disabled />`、`<MyComp :disabled="true" />`、`<MyComp disabled="" />` 三种写法完全等价。

### 7.1 规则表

| 子组件声明 | 父组件写法 | 结果 |
| --- | --- | --- |
| `disabled: Boolean` | `<C disabled />` | `true` |
| `disabled: Boolean` | `<C disabled="" />` | `true`（空字符串被转成 true） |
| `disabled: Boolean` | `<C :disabled="false" />` | `false` |
| `disabled: Boolean` | 完全不写 | `false`（Boolean 默认 false） |
| `disabled: String` | `<C disabled />` | `""`（空字符串，**不是** true） |

> [!info] 多类型时的优先级
> 只有在**同时声明了 Boolean 和其它类型**（如 `[Boolean, String]`）、且**该 prop 没写值**时，空值才当成 `true`。若写了值，就用写进去的值。

> [!danger] 最常见的坑：`"false"` 其实是 `true`
> ```vue
> <!-- 子组件：show: Boolean -->
> <Child show="false" />   <!-- ⚠️ 字符串 "false" 是"真值"，转成了 true！ -->
> <Child :show="false" />  <!-- ✅ 加冒号，才是真的布尔 false -->
> ```
> **记住：不想被转换，就加冒号 `:` 传真正的布尔值。**

---

## 八、TS 写法深入

### 8.1 泛型 + `withDefaults` + 类型导入

写法见 2.4。补充一点：Vue **3.3+ 支持从外部文件导入类型**，直接 `defineProps<Props>()` 即可：

```ts
// types.ts
export interface Props { title: string; likes?: number }
```

```vue
<script setup lang="ts">
import type { Props } from './types'   // 3.3+ 才允许
const props = withDefaults(defineProps<Props>(), { likes: 0 })
</script>
```

更早的版本类型必须**当前文件内联声明**，否则编译器解析不到，报"无法解析类型"。

### 8.2 响应式 props 解构（Vue 3.5+）

早期版本里，**直接解构 props 会丢失响应性**，这是经典坑：

```vue
<script setup>
const props = defineProps({ count: Number })
const { count } = props   // ❌ Vue 3.4 及以前：count 是普通数字，props.count 变了它不会变
</script>
```

Vue 3.5 引入了 **响应式 props 解构（Reactive Props Destructure）**，编译器自动处理，解构后仍保持响应，还能直接写默认值：

```vue
<script setup lang="ts">
interface Props { count?: number; title?: string }
const { count = 0, title = '标题' } = defineProps<Props>()  // ✅ Vue 3.5+
</script>
```

> [!warning] 低版本不要直接解构
> Vue < 3.5 请老老实实用 `props.count`，或者用 `toRefs(props)` 包一层（`count` 会变成 ref，模板里自动解包）。升级前先确认版本号。

---

## 九、常见坑 / FAQ

> [!question] 报错 `Set operation on key "xxx" failed: target is readonly`？
> 你在子组件里直接改 props 了。props 永远只读。改法：派生用 `computed`，本地可变量用 `ref` 复制，要真正同步给父组件用 `emit`（见第五节）。

> [!question] 数组 / 对象默认值多个实例"串味"了？
> `default: []` 写成了字面量。**对象和数组必须用工厂函数** `default: () => []`，否则所有实例共享同一份引用（见 6.3）。

> [!question] 明明传了 `false`，子组件里却是 `true`？
> 你写的是 `show="false"`（字符串），不是 `:show="false"`（布尔）。字符串 `"false"` 是**真值**。加冒号，或改用 `v-bind`。

> [!question] 父组件传的属性子组件拿不到？
> 检查三点：① 命名是否 camelCase ↔ kebab-case 对应（`postTitle` ↔ `post-title`）；② 子组件是否 `defineProps` 声明了它；③ 没声明的属性会掉进 `attrs`，见 [[属性继承]]。

> [!question] props 能在 `defineProps` 里用 `import` 的类型吗？`undefined` 和 `null` 走默认值有区别吗？
> 类型导入：Vue 3.3+ 可以，更早版本必须内联声明（见 [[TS 与 JS 的互操作性]]）。默认值：传 `undefined` **会**走 `default`，传 `null` **不会**——`null` 是一个有效的显式值。

---

## 相关笔记

- [[setup语法糖]] —— `defineProps` 编译宏的完整语境与其它宏
- [[SFC]] —— props 写在单文件组件的哪一块
- [[组件注册]] —— 子组件怎么被父组件引进来
- [[Events 自定义事件]] —— "想改 props"的正解：emit 通知父组件
- [[v-model]] —— `props` + `update:xxx` 事件的语法糖封装
- [[属性继承]] —— 没被声明为 prop 的属性去哪了（`attrs`）
- [[TypeScript vs JavaScript]] —— TS 泛型 `defineProps<T>()` 的类型基础
- [[tsconfig.json]] —— `lang="ts"` 的类型来源与配置

---

参考：Vue 官方文档 —— Props（Props Declaration / One-Way Data Flow / Prop Validation / Boolean Casting）、`<script setup>` 编译宏、Vue 3.3 `withDefaults` 与类型导入、Vue 3.5 响应式 props 解构（Reactive Props Destructure）
