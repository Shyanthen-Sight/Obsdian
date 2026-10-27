

> [!abstract] 一句话
> 父组件把数据写在子组件标签上，子组件用 `defineProps` 声明"我接收哪些字段"，就能在模板/脚本里当普通变量用。==props 是单向且只读的：数据从父流向子，子组件不能反向修改它。==

📁 源码：`Exp1/Exp1_ParentToChild_*.vue`（基础）、`Exp1/Exp1_Verify_ParentToChild_*.vue`（校验）

---

## 一、基础版：静态值与动态值

### 1.1 父组件

```vue
<!-- Exp1_ParentToChild_Parent.vue -->
<template>
  <p>
    <Child id="001" :title="greeting" />
  </p>
</template>

<script setup>
import { ref } from 'vue'
import Child from './Exp1_ParentToChild_Child.vue'

// 定义响应式数据
const greeting = ref('hello')
</script>
```

### 1.2 子组件

```vue
<!-- Exp1_ParentToChild_Child.vue -->
<template>
  <p>{{ id }}-{{ title }}-{{ name }}</p>
</template>

<script setup>
import { onMounted, ref } from 'vue'

// 声明 props
const props = defineProps(['id', 'title'])

// 定义响应式数据
const name = ref('张三')
onMounted(() => {
  console.log(props.title)
})
</script>
```

### 1.3 运行结果

页面显示：

```text
001-hello-张三
```

| 来源                  | 值         | 类型                | 说明                     |
| ------------------- | --------- | ----------------- | ---------------------- |
| `id="001"`          | `"001"`   | String            | **静态属性**，不写 `:`，原样当字符串 |
| `:title="greeting"` | `"hello"` | String（来自 ref 解包） | **动态绑定**，`:` 后是 JS 表达式 |
| `name`              | `"张三"`    | String            | 子组件自己的 `ref`，与父组件无关    |

---
## 二、两种写法的本质区别

```vue
<Child id="001" />          <!-- 传递字符串 "001" -->
<Child :id="1" />           <!-- 传递数字 1 -->
<Child :id="'001'" />       <!-- 传递字符串 "001" -->
<Child :title="greeting" /> <!-- 传递 greeting 的值（响应式） -->
```

> [!warning] 最容易错的一点
> `id="001"` 和 `:id="1"` **不是同一个东西**。
> - 不加 `:`：属性值是**字面量字符串**，`"001"` 就是字符串 `"001"`。
> - 加 `:`：属性值是 **JavaScript 表达式**，`1` 是数字 `1`，`greeting` 是变量。
>
> 若子组件声明 `id: Number`，却写了 `id="001"`，开发环境会警告类型不匹配。

---
## 三、`defineProps` 深入：它到底是什么

> [!abstract] 一句话
> `defineProps` 是 `<script setup>` 里的**编译宏**：你在源码里"声明"子组件接收哪些字段，Vue 编译器在打包时把这行改写成组件的 `props` 选项。它本身不产生任何运行时代码。

### 3.1 先看编译前后

源码：

```vue
<script setup>
const props = defineProps({ title: String })
console.log(props.title)
</script>
```

编译后（简化）：

```js
export default {
  props: { title: String },       // ← 你的声明被"搬"到了组件选项上
  setup(__props) {
    const props = __props          // ← const props = 拿到的是这个对象
    console.log(props.title)
    // ...
  },
}
```

从这 4 行能直接读出三件事：

1. `props` 选项来自你的声明——所谓"声明式接收"就是这个意思。
2. `const props =` 拿到的不是宏的返回值，而是**组件实例上的 props 对象**。
3. 宏在编译后消失了，所以它没有运行时开销，也**不能当普通函数用**。

### 3.2 因为是宏，所以有硬性限制

| 限制 | 说明 | 反例 |
| --- | --- | --- |
| 只能在 `<script setup>` 顶层 | 不能放进函数、`if`、生命周期钩子 | `onMounted(() => defineProps(['id']))` ❌ |
| 不需要 `import` | 编译器直接识别这个名字 | `import { defineProps } from 'vue'` 冗余，但不会报错 |
| 参数必须是字面量 | 声明要提升到模块作用域，运行时变量取不到 | `const keys = ['id']; defineProps(keys)` ❌ |
| 不能赋值给别人 | 它不是值，只是一个"标记" | `const fn = defineProps` ❌ |
| 一个组件只能调一次 | 重复调用编译报错 | 两处 `defineProps(...)` ❌ |

> [!warning] 为什么参数不能是变量
> `defineProps` 的声明会被提升到组件选项（模块作用域），而 `const keys = [...]` 是 `setup` 内的局部变量。编译阶段根本拿不到它的值，只能报错。同理，TS 类型声明里也**不能引用局部变量**。

### 3.3 完整使用：声明 → 传值 → 使用

```vue
<!-- ① 子组件：声明接收哪些字段 -->
<script setup>
const props = defineProps({
  title: String,
  count: { type: Number, default: 0 },
})
</script>
```

```vue
<!-- ② 父组件：按名字把值传进去 -->
<template>
  <Child title="hi" :count="3" />
</template>
```

```vue
<!-- ③ 子组件里使用：模板直接写字段名 -->
<template>
  <p>{{ title }} / {{ count }}</p>
  <!-- 不要写 props.title，模板会自动解包 -->
</template>
```

```js
// ③ 脚本里使用：必须带 props.
console.log(props.title)   // 'hi'
```

### 3.4 返回值：接不接？

```js
// ① 不接：模板照样能用
defineProps(['title'])
// <template>{{ title }}</template>  ✅
// 但 <script setup> 里没有 title 这个变量  ❌

// ② 接：脚本里也能用
const props = defineProps(['title'])
console.log(props.title)   // ✅
```

> [!tip] 判断标准
> **只在模板里用 → 可以不接；要在 JS / computed / watch / 事件处理函数里用 → 必须接。**
> 变量名随便起，习惯叫 `props`，但你写 `const p = defineProps(...)` 也完全合法。

### 3.5 TS 下给默认值：`withDefaults`

对象语法能写 `default`，但类型声明语法里写不了，需要 `withDefaults` 补：

```ts
const props = withDefaults(
  defineProps<{
    title?: string
    tags?: string[]
  }>(),
  
  {
    title: '未命名',
    tags: () => [],   // 对象/数组仍然必须用工厂函数
  }
)
```

Vue 3.5+ 也可以直接用解构默认值（见第九节）：

```ts
const { title = '未命名' } = defineProps<{ title?: string }>()
```

### 3.6 声明过的字段不会再进 attrs

```js
const props = defineProps(['id'])
```

父组件写 `<Child id="001" class="box" />` 时：

- `id` 被 props 消费 → 进 `props.id`，**不会**落到根元素
- `class` 没声明 → 进 `attrs`，自动透传到根元素

所以"声明了却还想让属性出现在 DOM 上"是不会成立的；确实需要时，在子组件模板里手动绑一次：`<div :title="title">`。

---

## 四、`defineProps` 的三种写法

### 4.1 数组语法（只声明名字，不做校验）

```js
const props = defineProps(['id', 'title'])
```

等价于"我知道会来这两个字段"，不限制类型、不要求必填。

### 4.2 对象语法（推荐，可校验）

```js
const props = defineProps({
  id: Number,
  title: String,
})
```

### 4.3 类型声明语法（TS）

```ts
const props = defineProps<{
  id?: number
  title: string
}>()
```

> [!info] 三种写法怎么选
> - 快速原型、字段少：**数组语法**，最省事。
> - 需要类型约束和校验：**对象语法**（推荐）。
> - TS 项目：**类型声明语法** + `withDefaults` 补默认值。
>
> 宏本身的机制见上一节（三、`defineProps` 深入）。

---

## 五、props 校验完整版

### 5.1 父组件

```vue
<!-- Exp1_Verify_ParentToChild_Parent.vue -->
<template>
  <div class="parent-wrapper">
    <Child :id="id" :name="name" :sex="sex" :login-method="loginMethod" />
  </div>
</template>

<script setup>
import { ref } from 'vue'
import Child from './Exp1_Verify_ParentToChild_Child.vue'

const id = ref(1)                 // 类型校验
const name = ref('小明')          // 必填
const sex = ref(undefined)        // 默认值
const loginMethod = ref('Tel')    // 自定义验证
</script>
```

### 5.2 子组件

```vue
<!-- Exp1_Verify_ParentToChild_Child.vue -->
<template>
  <p class="child-info">{{ id }} - {{ name }} - {{ sex }} - {{ loginMethod }}</p>
</template>

<script setup>
// 定义 props 及校验规则
const props = defineProps({
  // 基础类型校验，null 和 undefined 会通过任何类型的校验
  id: Number,
  // 必填性验证
  name: {
    type: [String, Number], // 多类型
    required: true,
  },
  // 默认值设置
  sex: {
    type: String,
    default: '男',
  },
  // 自定义验证函数
  loginMethod: {
    validator: function (value) {
      return ['Tel', 'QQ', 'WeChat'].indexOf(value) !== -1
    },
  },
})
</script>
```

### 5.3 校验项逐条拆解

| 配置 | 代码 | 作用 | 本例结果 |
| --- | --- | --- | --- |
| 类型 | `id: Number` | 值必须是数字 | `1` ✅ |
| 多类型 | `type: [String, Number]` | 满足其一即可 | `'小明'` ✅ |
| 必填 | `required: true` | 不传会警告 | 已传 ✅ |
| 默认值 | `default: '男'` | 父传 `undefined` 时启用 | 显示 `男` |
| 自定义 | `validator(value)` | 返回 `true` 才通过 | `'Tel'` ✅ |

最终渲染：

```text
1 - 小明 - 男 - Tel
```

---

## 六、校验规则的准确行为

> [!important] 必须知道的边界
> 1. **`null` / `undefined` 绕过类型校验**：它们不会触发 `type` 警告。（`required` 仍会检查 `undefined`）
> 2. **`default` 只在值为 `undefined` 时生效**；传 `null` 不会用默认值。
> 3. **对象/数组的默认值必须用工厂函数**：
>    ```js
>    default: () => []      // ✅ 每次拿到新数组
>    default: []            // ❌ 所有实例共享同一个引用
>    ```
> 4. **`validator` 里拿不到 `this`**：它在组件实例创建前执行，只能用参数 `value`。
> 5. **校验失败只警告，不阻断渲染**：生产环境警告会被移除，所以不能拿 props 校验做业务校验。
> 6. **Boolean 特殊转换**：声明为 `Boolean` 的 prop，不传 → `false`；传空字符串 `""` → `true`；传同名属性 `disabled` → `true`。

---

## 七、prop 命名：camelCase ↔ kebab-case

```js
// 子组件声明
defineProps({ loginMethod: String })
```

```vue
<!-- 父组件传：HTML 不区分大小写，模板里必须用 kebab-case -->
<Child login-method="Tel" />
<Child :login-method="loginMethod" />
```

> [!tip] 记法
> **JS 里驼峰，模板里短横。** Vue 会自动把 `login-method` 映射到 `loginMethod`；反过来在模板写 `:loginMethod` 在 DOM 模板中会失效（SFC 模板通常没事，但统一用 kebab 最稳）。

---

## 八、props 是只读的

```js
const props = defineProps(['title'])

props.title = 'new'   // ❌ 开发环境警告：Set operation on key "title" failed: target is readonly
```

正确做法：**子组件发事件，请父组件改**（见 [[Exp2 子传父 emit]]）。

```js
const emit = defineEmits(['update:title'])
emit('update:title', 'new')
```

> [!warning] 浅只读
> `props` 是**浅只读**（`shallowReadonly`）：`props.obj.name = 'x'` 不会报错，但这是反模式——数据源仍在父组件，容易造成"看不出谁改的"bug。需要派生数据请用 `computed`。

---

## 九、props 解构与响应性

```js
// Vue 3.5+：响应式解构可用（编译期转换）
const { title } = defineProps(['title'])
```

```js
// 3.5 之前：解构会丢失响应性
const { title } = defineProps(['title'])   // title 只是普通常量
```

> [!tip] 稳妥写法
> 需要响应性就保留 `props.title`，或用 `const title = computed(() => props.title)`；需要解构时确认项目 Vue 版本 ≥ 3.5（本项目 `vue: ^3.5.42`）。

---

## 十、数据流图

```text
父组件
  greeting = ref('hello')
        │
        │  <Child :title="greeting" id="001" />
        ▼
子组件
  defineProps(['id', 'title'])
        │
        ├── 模板：{{ id }} / {{ title }}      → 渲染 001-hello
        └── 脚本：props.title                  → 'hello'
```

单向箭头是重点：**父变 → 子自动更新；子改 props → 警告**。

---

## 十一、易错点清单

- [ ] `id="001"` 以为是数字 → 实际是字符串，需要数字请 `:id="1"`
- [ ] 模板写 `:loginMethod` → 统一改用 `login-method`
- [ ] 对象默认值写成 `default: {}` → 必须 `default: () => ({})`
- [ ] 在子组件里 `props.x = ...` → 只读，改用 emit
- [ ] 以为校验失败会阻止渲染 → 只警告
- [ ] 声明了 `id` 又想让它落到 DOM 上 → 已声明就被 props 消费，不会透传
- [ ] 解构 props 后发现不更新 → 版本 < 3.5 或写法不当，用 `props.x`
- [ ] `const keys = ['id']; defineProps(keys)` → 编译宏参数必须是字面量
- [ ] 把 `defineProps` 写进函数/钩子里 → 只能在 `<script setup>` 顶层

---

## 十二、自测

1. 父组件写 `<Child id="001" />`，子组件声明 `id: Number`，会发生什么？
2. `sex` 传 `null` 而不是 `undefined`，默认值 `'男'` 会生效吗？
3. 子组件想改 `title`，正确流程是什么？
4. 为什么 `validator` 里不能用 `this`？
5. 不写 `const props =`，还能在 `<script setup>` 里访问 props 吗？

> [!success]- 参考答案
> 1. 开发环境警告类型不匹配（字符串 vs Number），但仍渲染 `001`。
> 2. 不会，`default` 只对 `undefined` 生效。
> 3. `defineEmits` 发事件 → 父组件监听并修改自己的数据。
> 4. 校验发生在组件实例创建之前，此时没有 `this`。
> 5. 不能。模板可直接用字段名，但 JS 中必须通过 `defineProps` 的返回值访问。

---

## 十三、同型练习：商品卡片 props 校验

> [!info] 题目
> 实现一个 `ProductCard` 商品卡片组件，父组件这样使用：
>
> ```vue
> <ProductCard
>   title="机械键盘"
>   :price="299"
>   :tags="['无线', 'RGB']"
> />
> ```
>
> 要求：
> 1. `title`：String，必填；
> 2. `price`：Number，默认 `0`；
> 3. `tags`：Array，默认空数组；
> 4. `status`：String，默认 `'on'`，只允许 `'on'` / `'off'`；
> 5. 子组件按 `标题 - ¥价格 - 标签/标签 - 上架/下架` 的格式渲染；
> 6. 回答：为什么 `tags` 的默认值要写成 `() => []`？若父组件把 `:price="299"` 写成 `price="299"`，会怎样？

> [!success]- 参考答案
> **父组件**
>
> ```vue
> <!-- ProductCardParent.vue -->
> <template>
>   <ProductCard title="机械键盘" :price="299" :tags="['无线', 'RGB']" />
> </template>
>
> <script setup>
> import ProductCard from './ProductCard.vue'
> </script>
> ```
>
> **子组件**
>
> ```vue
> <!-- ProductCard.vue -->
> <template>
>   <p>{{ title }} - ¥{{ price }} - {{ tags.join('/') }} - {{ status === 'on' ? '上架' : '下架' }}</p>
> </template>
>
> <script setup>
> defineProps({
>   title: {
>     type: String,
>     required: true,
>   },
>   price: {
>     type: Number,
>     default: 0,
>   },
>   tags: {
>     type: Array,
>     default: () => [],
>   },
>   status: {
>     type: String,
>     default: 'on',
>     validator: (value) => ['on', 'off'].includes(value),
>   },
> })
> </script>
> ```
>
> **渲染结果**
>
> ```text
> 机械键盘 - ¥299 - 无线/RGB - 上架
> ```
>
> **两个问题的答案**
> 1. 对象/数组的默认值必须用工厂函数。`default: []` 会让所有组件实例共享同一个数组引用，一个实例 `push` 会污染另一个实例；开发环境也会直接警告。`default: () => []` 则每次创建新数组。
> 2. `price="299"` 传的是字面量字符串 `"299"`，与声明的 `Number` 不符；开发环境会警告类型不匹配，但页面仍会渲染 `¥299`。需要数字就写 `:price="299"`。

---

## 十四、关联

- 下一篇：[[Exp2 子传父 emit]]
- 总览：[[00 组件通信与插槽总览]]
- 语法基础：[[setup语法糖]]
