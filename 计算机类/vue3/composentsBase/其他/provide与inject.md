# provide 与 inject

> [!abstract] 一句话
> `provide` 在祖先组件的"依赖注入表"里放一份带 key 的值，任意深度的后代用同一个 key `inject` 取走，中间组件完全不用声明、不用转发。==它解决的是 props 逐层透传（prop drilling），不是全局状态管理。==

📁 实验源码：`Exp9/Exp9_ProvideInect_Parent.vue`、`Exp9/Exp9_ProvideInect_Child.vue`；综合应用见 `Exp11/`

---

## 一、结论先行

| 维度 | 结论 |
| --- | --- |
| 方向 | 祖先 → 任意后代，单向向下 |
| 查找方式 | 按 key 在祖先链上**就近查找** |
| 作用域 | 当前组件子树，不是全局 |
| key | 字符串或 `Symbol`；工程里推荐 `Symbol` + `InjectionKey` |
| 响应式 | 注入动作本身不产生响应式；提供 `ref` / `reactive` 才有 |
| 调用时机 | `setup` 同步阶段（`<script setup>` 顶层） |
| 找不到 key | 返回 `undefined`；开发环境给出警告 |
| 典型场景 | 组件库上下文（表单、主题、语言）、深层配置、跨层回调 |
| 不适合 | 全局共享状态（用 Pinia）、直接父子传值（用 props） |

> [!tip] 一句话记
> **祖先 provide，后代 inject，中间不插手；key 要对得上，值要是响应式的。**

---

## 二、心智模型：组件树上的"依赖注入表"

```text
App
└── Layout            ← 不写任何 provide / inject
    └── Page          ← 不写任何 provide / inject
        └── Card      ← inject('theme') ✅
```

`provide` 相当于在当前组件实例上挂一张"对本子树可见"的键值表；`inject` 从当前组件往父级一路找，==最近的那个提供者胜出==。

```text
App.provides       = { theme: 'dark' }
  └─ Layout.provides = Object.create(App.provides)
      └─ Page.provides = Object.create(Layout.provides)
          └─ Card 查找 theme → 沿原型链向上 → 'dark'
```

> [!info] 和 React Context 的区别
> 思路相同（都是"越过中间层传上下文"），但 Vue 的 `provide / inject` 不需要显式的 `<Provider>` 包裹，也没有 `Consumer` 组件；key 是运行时字符串或 `Symbol`，类型靠 `InjectionKey` 补。

---

## 三、最小示例：隔两层也能拿到

### 3.1 祖先：provide

```vue
<!-- GrandParent.vue -->
<script setup>
import { provide, ref } from 'vue'
import Middle from './Middle.vue'

const theme = ref('dark')
provide('theme', theme)   // 放一份 ref，后代拿到的是同一个 ref
</script>

<template>
  <Middle />
</template>
```

### 3.2 中间层：什么都不做

```vue
<!-- Middle.vue -->
<script setup>
import Leaf from './Leaf.vue'
</script>

<template>
  <Leaf />
</template>
```

### 3.3 后代：inject

```vue
<!-- Leaf.vue -->
<script setup>
import { inject } from 'vue'

const theme = inject('theme', 'light')   // 第二个参数是兜底默认值
</script>

<template>
  <!-- 顶层 ref 在模板里自动解包，直接写 theme -->
  <p>当前主题：{{ theme }}</p>
</template>
```

数据流：

```text
GrandParent  theme = ref('dark')
     │  provide('theme', theme)
     ▼
 依赖注入表（挂在本组件实例上）
     │
Middle  不声明、不转发，甚至不知道有这个 key
     │
     ▼
Leaf  inject('theme') ──▶ 同一个 ref
```

---

## 四、API 全解

### 4.1 provide(key, value)

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| `key` | `string \| symbol` | 后代查表的凭证 |
| `value` | 任意 | ref、reactive、对象、函数、基本类型都可以 |

要点：

- 只能在 `setup` 的**同步阶段**调用（`<script setup>` 顶层，或 `setup()` 函数体的同步部分）。
- 放在 `await`、`setTimeout`、事件回调里，要么无效，要么时机已经太晚。
- 同一个组件可以多次 provide，不同 key 互不影响。

```js
// ✅
setup() {
  provide('a', 1)
}

// ❌ 组件可能已经渲染完，当前实例上下文也丢了
setTimeout(() => provide('a', 1), 0)
```

### 4.2 inject(key, defaultValue?, treatDefaultAsFactory?)

| 情况 | 返回值 |
| --- | --- |
| 祖先链找到 key | 提供的值本身（不做任何包装） |
| 没找到，没默认值 | `undefined`（开发环境警告） |
| 没找到，有默认值 | 默认值 |

如果默认值是需要"每个组件各拿一份"的对象，用工厂函数：

```js
const config = inject('config', () => ({ theme: 'light', size: 'md' }), true)
// 第三个参数 true = 把第二个参数当作工厂函数调用
```

> [!warning] 默认值不是"响应式兜底"
> `inject('x', 0)` 只是在**找不到时**返回 `0`；一旦祖先提供了值，后续祖先把它改成别的，注入方看到的是祖先提供的那个响应式容器，而不是这个默认值。

### 4.3 TypeScript：InjectionKey

字符串 key 没有类型信息。工程里用 `Symbol` + `InjectionKey<T>` 把 key 和值类型绑定在一起：

```ts
// injection-keys.ts
import type { InjectionKey, Ref } from 'vue'

export interface Product {
  name: string
  price: number
  stock: number
}

export const productKey: InjectionKey<Ref<Product>> = Symbol('product')
```

```ts
// 祖先
import { provide, ref } from 'vue'
import { productKey, type Product } from './injection-keys'

const product = ref<Product>({ name: '河北皇冠梨', price: 28.9, stock: 999 })
provide(productKey, product)
```

```ts
// 后代
import { inject } from 'vue'
import { productKey } from './injection-keys'

const product = inject(productKey)                 // Ref<Product> | undefined
const safe = inject(productKey, ref({             // Ref<Product>
  name: '',
  price: 0,
  stock: 0,
}))
```

> [!tip] 为什么用 Symbol
> 字符串 key 在多个库、多个模块里可能重名；`Symbol('product')` 每次都是唯一值，天然避免冲突。再配合 `InjectionKey`，还能获得完整的类型提示。

### 4.4 Options API 写法

```js
export default {
  inject: ['product'],   // 简单写法
}
```

```js
export default {
  inject: {
    product: {
      from: 'productProvide',
      default: () => ({ name: '默认商品' }),
    },
  },
}
```

> [!info] 两种 API 可以混用
> 祖先用组合式的 `provide()`，后代用选项式的 `inject` 也能拿到，key 仍然要对上。新项目统一用 `<script setup>` 即可。

### 4.5 应用级 provide

```js
// main.js
import { createApp } from 'vue'
import App from './App.vue'

const app = createApp(App)
app.provide('i18n', { locale: 'zh-CN' })
app.mount('#app')
```

任意组件都能 `inject('i18n')`，不需要某个祖先组件提供。插件通常这样注入配置：

```js
export default {
  install(app, options) {
    app.provide('myPlugin', options)
  },
}
```

---

## 五、响应式：注入的到底是什么

`inject` 只做一次"查表 + 返回引用"，它不会把值包成响应式。值能不能驱动视图，取决于**祖先放进去的是什么**。

| 祖先 provide 的值 | 后代脚本拿到 | 后代模板 | 祖先后续修改能否同步 |
| --- | --- | --- | --- |
| 普通值 `28.9` | 数字 | 数字 | ❌ 只是一份快照 |
| `reactive` 对象 | 代理 | 直接点属性 | ✅ 属性级修改 |
| `ref` | Ref 对象 | 顶层自动解包 | ✅ 改 `.value` 或内部属性 |
| 函数 | 函数 | 可调用 | —（函数本身不变） |

### 5.1 两种典型的"丢响应式"写法

```js
const product = reactive({ name: '梨', price: 28.9 })

// ❌ 传的是 28.9 这个数字的拷贝
provide('price', product.price)

// ❌ 解构后再组装，也是普通快照
const { name, price } = product
provide('product', { name, price })
```

✅ 正确做法：

```js
provide('product', product)                      // 整个代理
provide('price', toRef(product, 'price'))        // 单个字段用 toRef
provide('price', computed(() => product.price))  // 或 computed
```

### 5.2 注入 ref 后，脚本里别忘 `.value`

```js
// 祖先
provide('count', ref(0))

// 后代
const count = inject('count')
count.value++        // ✅ 脚本里要 .value
```

```vue
<template>
  <p>{{ count }}</p> <!-- ✅ 模板顶层自动解包 -->
</template>
```

### 5.3 注入 reactive 后，别写 `.value`

```js
const product = inject('product')
product.price = 19.9    // ✅ reactive：直接点属性
product.value.price     // ❌ reactive 没有 .value
```

> [!warning] 记住"注入什么类型，就按什么类型访问"
> 提供 `ref` → 脚本 `.value`；提供 `reactive` → 直接点属性。模板对**顶层 ref** 自动解包，对 reactive 本来就是直接访问。

### 5.4 单向数据流：不要让后代直接改

技术上，注入的 `reactive` 对象在后代里可以直接改，而且会同步；但这会让"谁改了数据"变得难以追踪。推荐两种做法。

**做法一：提供只读数据 + 修改函数**

```js
// 祖先
import { provide, readonly, reactive } from 'vue'

const product = reactive({ name: '梨', price: 28.9 })

function updatePrice(newPrice) {
  product.price = newPrice
}

provide('product', readonly(product))
provide('updatePrice', updatePrice)
```

```js
// 后代
const product = inject('product')           // 只读代理
const updatePrice = inject('updatePrice')   // 修改入口
updatePrice(19.9)                           // ✅ 通过祖先改
```

**做法二：只提供只读数据，禁止后代写**

```js
provide('product', readonly(product))
```

> [!warning] `readonly` 默认是深层只读
> 后代改任何嵌套属性都会在开发环境警告。如果确实需要"外层只读、内层可写"，用 `shallowReadonly`。

---

## 六、原理：为什么能跨层，为什么必须在 setup 同步阶段

### 6.1 provides 是一条原型链

每个组件实例上都有一个 `provides` 对象。创建实例时它先直接指向父级的表，第一次 `provide` 时才分叉出自己的表：

```js
// 简化后的内部逻辑
instance.provides = parent ? parent.provides : Object.create(appContext.provides)

// 第一次 provide：创建自己的表，原型指向父级
if (instance.provides === parent.provides) {
  instance.provides = Object.create(parent.provides)
}
instance.provides[key] = value

// inject：从父级 provides 开始，用 in 沿原型链查找
const provides = instance.parent
  ? instance.parent.provides
  : appContext.provides

if (key in provides) {
  return provides[key]
}
```

这解释了三件事：

1. **能跨任意层级**：原型链把所有祖先串起来了。
2. **就近原则**：`in` 从最近的父级开始找，第一个命中就返回。
3. **自己 provide 的 key 自己 inject 不到**：查找从 `instance.parent` 开始，不包含自己的 `provides`。要在同一组件里复用，直接用本地变量。

### 6.2 为什么必须在 setup 同步阶段

`provide` / `inject` 依赖"当前组件实例"（`currentInstance`）。这个指针只在组件 `setup` 执行期间存在：

- 在 `setup` 顶层调用 → 能拿到当前实例，正常写入 / 查找。
- 在 `await` 之后、`setTimeout`、事件回调里调用 → 当前实例已经清空，`inject` 拿不到上下文，`provide` 也写不到正确的实例上。

```js
// ❌ 异步 setup 里 await 之后才 provide，子组件可能已经创建
async setup() {
  const data = await fetchData()
  provide('data', data)   // 太晚了
}

// ✅ 先 provide 一个 ref，再把异步结果写进去
setup() {
  const data = ref(null)
  provide('data', data)
  fetchData().then(res => { data.value = res })
}
```

### 6.3 注入只解析一次

`inject` 在 `setup` 执行时查一次表，拿到的是当时的引用。之后祖先再用同一个 key `provide` 一个新值，已经注入过的后代**不会自动更新**——除非你提供的本来就是 `ref` / `reactive` 容器，通过改容器内部让依赖失效。

```js
// ❌ 后代拿到的是旧值
let theme = 'dark'
provide('theme', theme)
theme = 'light'          // 后代仍是 'dark'

// ✅ 用 ref 承载变化
const theme = ref('dark')
provide('theme', theme)
theme.value = 'light'    // 后代模板更新
```

---

## 七、工程化写法

### 7.1 key 集中管理

```js
// injection-keys.js
export const productKey = Symbol('product')
export const themeKey = Symbol('theme')
```

```js
// 祖先
import { productKey } from './injection-keys'
provide(productKey, product)

// 后代
import { productKey } from './injection-keys'
const product = inject(productKey)
```

避免到处写魔法字符串 `'productProvide'`；拼错时是运行时静默失败，很难查。

### 7.2 provide / use 成对封装（组件库常用）

```js
// useProduct.js
import { inject, provide, readonly, ref } from 'vue'

const productKey = Symbol('product')

export function provideProduct() {
  const product = ref({
    name: '河北皇冠梨',
    price: 28.9,
    stock: 999,
  })

  provide(productKey, readonly(product))
  return product
}

export function useProduct() {
  const product = inject(productKey)
  if (!product) {
    throw new Error('useProduct() 必须在 provideProduct() 的后代组件中使用')
  }
  return product
}
```

```vue
<!-- 祖先 -->
<script setup>
import { provideProduct } from './useProduct'
provideProduct()
</script>

<!-- 后代 -->
<script setup>
import { useProduct } from './useProduct'
const product = useProduct()   // 类型和错误信息都在封装里处理掉了
</script>
```

> [!tip] 这个模式的价值
> 后代不需要知道 key 长什么样，也不会拼错；找不到时立刻抛错，而不是在模板里渲染 `undefined.name` 才炸。Element Plus、Vuetify 等组件库的表单 / 主题上下文基本都是这个结构。

### 7.3 用 provide 传"向上"的能力

`provide / inject` 常被误解为只能向下传数据。把函数 provide 下去，后代调用它，就实现了跨层"向上通知"：

```js
// 祖先
function onSelect(id) {
  selectedId.value = id
}
provide('onSelect', onSelect)

// 后代
const onSelect = inject('onSelect')
onSelect(item.id)
```

这相当于一个"只对子树开放"的事件通道，比全局事件总线可控。

---

## 八、易错点清单

- [ ] `provide` 和 `inject` 的 key 不一致（大小写、连字符、拼写）
- [ ] `inject` 写在 `await` 之后、`setTimeout`、事件回调里
- [ ] `provide` 写在 `await` 之后，子组件已经创建
- [ ] `provide` 基本类型，指望后代跟着变
- [ ] 解构 `reactive` 后再 provide，响应式丢失（应传 `toRef` / `toRefs`）
- [ ] 注入 `ref` 后脚本里忘写 `.value`
- [ ] 注入 `reactive` 后多写 `.value`
- [ ] 把 `inject` 的返回值当成一定存在，`undefined` 时才报错
- [ ] 自己 provide 的 key 自己 inject，拿不到
- [ ] 多个祖先提供同一个字符串 key，误以为拿到的是自己以为的那个
- [ ] `inject` 默认值传模块级对象，多个后代共享同一份引用
- [ ] 用 `provide / inject` 承担全局状态，组件树一改就崩
- [ ] 后代直接改注入对象，数据变更来源无法追踪

---

## 九、选型：props / provide-inject / Pinia

| 对比项 | props | provide / inject | Pinia |
| --- | --- | --- | --- |
| 传递方向 | 父 → 直接子 | 祖先 → 任意后代 | 任意组件 |
| 中间组件 | 必须逐层声明转发 | 不用经手 | 不用经手 |
| 显式程度 | 高，看模板就知道 | 低，要追 key | 中，看 store |
| 类型检查 | `defineProps` 完整 | 靠 `InjectionKey` 补 | 完整 |
| 作用域 | 单个子组件 | 当前子树 | 整个应用 |
| Devtools | 有 | 无 | 完整 |
| 典型场景 | 直接父子、展示组件 | 组件库上下文、深层配置 | 全局业务状态 |

决策树：

```text
只是父传子？                          → props
跨多层，但只在某棵子树里共享？          → provide / inject
需要全局共享、跨路由、要 devtools？     → Pinia
只是兄弟组件通信？                      → 提升到共同父级，用 props + emit
```

> [!important] 不要用 provide / inject 替代 Pinia
> 它没有 devtools、没有时间旅行、没有持久化，作用域还绑在组件树上。它的定位是"组件库级别的隐式上下文"，不是"应用级状态仓库"。

---

## 十、自测

> [!question]- 1. 中间隔了三层组件，`inject` 还能拿到祖先的 provide 吗？中间组件要做什么？
> 能。`provide / inject` 沿组件实例的 `provides` 原型链查找，不受层数限制；中间组件不需要声明、转发，甚至不需要知道这个 key 存在。

> [!question]- 2. `inject('x')` 找不到 key 时返回什么？怎么避免报错？
> 返回 `undefined`，开发环境会警告。给第二个参数默认值即可：`inject('x', defaultValue)`；如果默认值是需要每个组件各建一份的对象，用工厂形式 `inject('x', () => ({ ... }), true)`。

> [!question]- 3. 祖先 `provide('price', 28.9)`，之后把价格改成 19.9，后代为什么不变？怎么改？
> 提供的是数字快照，后代拿到的是拷贝，和祖先变量没有关联。改成提供 `ref` / `reactive` 容器（或 `toRef(product, 'price')`），后代读取容器才能跟随变化。

> [!question]- 4. 两个祖先都 provide 了同一个 key，后代拿到哪一个？
> 最近的祖先。`inject` 从父级 `provides` 开始沿原型链向上找，第一个命中的就是结果。

> [!question]- 5. 为什么不能在 `setTimeout` 里调用 `inject`？
> `inject` 依赖 `currentInstance`（当前组件实例），这个指针只在 `setup` 同步执行期间有效。异步回调执行时实例上下文已经清空，`inject` 无法确定"从哪个组件往上找"。

> [!question]- 6. 后代想修改注入的数据，推荐怎么做？
> 祖先提供 `readonly` 的数据 + 一个修改函数（如 `updatePrice`），后代 `inject` 后调用函数；或者只提供只读代理，禁止后代直接写。核心是保持单向数据流，让修改入口集中在祖先。

> [!question]- 7. `provide / inject` 能替代 Pinia 吗？
> 不能。它没有 devtools、持久化、跨应用共享等能力，作用域是组件子树而不是整个应用。它适合组件库上下文和深层配置；全局业务状态用 Pinia。

---

## 十一、相关笔记

- [[Exp9 依赖注入（provide-inject）]] —— 实验版：完整源码、逐段拆解、数据流
- [[Exp11 商品详情页（依赖注入）]] —— 综合应用：provide/inject + props + 作用域插槽 + 动态组件
- [[00 组件通信与插槽总览]] —— 组件通信全景：props / emit / 插槽 / 依赖注入
- [[reactive与ref的区别]] —— 为什么 provide 基本类型会丢响应式、`toRef` / `toRefs` 怎么用
- [[Props 组件属性]] —— 最常规的父传子方式，与 provide/inject 的分工
- [[setup语法糖]] —— `<script setup>` 顶层为什么能直接调用 `provide` / `inject`

> [!success] 一句话收尾
> **`provide` 往当前组件的 provides 表里写，`inject` 沿父级原型链就近查找，中间层零感知。** 值要传 `ref` / `reactive` 才有响应式，修改要通过祖先提供的函数或只读代理，作用域只限当前子树——把它当"组件库上下文"，而不是"全局 store"。
