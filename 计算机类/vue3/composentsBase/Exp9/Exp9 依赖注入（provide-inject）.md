# Exp9 依赖注入（provide-inject）

> [!abstract] 一句话
> `provide` 在祖先组件"放一份数据"，任意深度的后代用 `inject` 按 key"取这份数据"，中间组件不用经手。==它是 props 逐层透传的替代方案，适合跨层级共享同一份状态。==

📁 源码：`Exp9/Exp9_ProvideInect_Parent.vue`、`Exp9/Exp9_ProvideInect_Child.vue`

> [!warning] 文件名拼写
> 源文件名是 `ProvideInect`，正确拼写应为 `ProvideInject`（少了一个 `j`）。为了与源码保持一致，本目录保留原名，正文按正确拼写讲解。

---

## 一、完整源码

### 1.1 祖先组件：provide

```vue
<!-- Exp9_ProvideInect_Parent.vue -->
<template>
  <ChildComp />
</template>

<script setup>
import { provide, reactive } from 'vue'
import ChildComp from './Exp9_ProvideInect_Child.vue'

const product = reactive({
  name: '河北皇冠梨',
  price: 28.9,
  stock: 999,
  detail: {
    barnd: '远达',
    type: '皇冠梨',
    bunmber: 123456,
    placeProduction: '河北',
    storageConditions: '冷藏',
  },
})

provide('productProvide', product)

//查阅拓展文档，ref和reactive对比
</script>
```

### 1.2 后代组件：inject

```vue
<!-- Exp9_ProvideInect_Child.vue -->
<template>
  <h3>{{ productProvide.name }}</h3>
  <p>当前价格：{{ productProvide.price }}</p>
  <p>库存：{{ productProvide.stock }}</p>
  <hr />
  <div>
    <ul>
      <li v-for="(value, key) in productProvide.detail" :key="key">{{ key }}:{{ value }}</li>
    </ul>
  </div>
</template>

<script setup>
import { inject } from 'vue'

const productProvide = inject('productProvide')
</script>
```

### 1.3 渲染结果

```text
河北皇冠梨
当前价格：28.9
库存：999
────────────────
barnd:远达
type:皇冠梨
bunmber:123456
placeProduction:河北
storageConditions:冷藏
```

> [!info] 为什么 `detail` 里没有 `name`
> `v-for` 遍历的是 `productProvide.detail`，只包含 `barnd`、`type`、`bunmber`、`placeProduction`、`storageConditions`。外层 `name`/`price`/`stock` 已单独渲染。

---

## 二、数据流

```text
Exp9_ProvideInect_Parent
│  const product = reactive({ ... })
│  provide('productProvide', product)
│                    │
│                    ▼
│              Vue 的依赖注入表
│              key: 'productProvide'
│              value: product 代理对象
│                    │
└── ChildComp ──inject('productProvide')──▶ 拿到同一个代理
                                                │
                                                ▼
                                    模板直接 productProvide.name
```

中间即使再隔多少层组件，只要在祖先的 `provide` 作用域内，后代都能 `inject` 到。

---

## 三、语法拆解

### 3.1 provide(key, value)

```js
provide('productProvide', product)
```

| 参数      | 说明                                          |
| ------- | ------------------------------------------- |
| `key`   | 字符串或 `Symbol`，后代按它查找，（可自定义命令）               |
| `value` | 对象、`ref`、`reactive`、函数、普通变量，（往往是父组件里面存在的元素） |

`provide` 必须在 `setup` 的**同步阶段**调用；放在 `await`、`setTimeout`、事件回调里无效。

### 3.2 inject(key, defaultValue?)

```js
const productProvide = inject('productProvide')
```

| 情况       | 结果                     |
| -------- | ---------------------- |
| 找到 key   | 对应的 value              |
| 没找到且没默认值 | `undefined`（后续访问属性会报错） |
| 没找到且有默认值 | 默认值                    |

```js
const productProvide = inject('productProvide', { name: '默认商品' })
```

> [!tip] 用 Symbol 避免 key 冲突
> 大型项目里字符串 key 可能重名，可改用 Symbol：
> ```js
> // keys.js
> export const productKey = Symbol('product')
>
> // 祖先
> provide(productKey, product)
>
> // 后代
> const product = inject(productKey)
> ```

### 3.3 模板里直接访问

```vue
{{ productProvide.name }}
```

`productProvide` 是 `reactive` 代理，模板里直接点属性即可，**不需要 `.value`**。

> [!important] 与 Exp11 的差异
> - Exp9 提供的是 `reactive` 对象 → 后代脚本/模板都直接用 `productProvide.xxx`。
> - Exp11 提供的是 `ref` → 后代脚本里必须 `tabList.value[...]`，模板里自动解包。
>
> 注入什么类型，后代就按什么类型访问。

---

## 四、响应式：为什么修改能同步

```js
const product = reactive({ price: 28.9 })
provide('productProvide', product)

// 之后任何地方修改
product.price = 19.9
```

后代模板里的 `{{ productProvide.price }}` 会自动更新，因为：

1. `reactive` 返回的是**同一个代理对象**；
2. `provide` 传的是对象引用，不是快照；
3. 后代读取属性时依赖被追踪，属性变化触发重新渲染。

> [!warning] 两种会丢响应式的写法
> ```js
> // ❌ 传值快照（基本类型）
> provide('price', product.price)
>
> // ❌ 解构后传
> const { price, stock } = product
> provide('product', { price, stock })
> ```
> 基本类型传过去就是一份拷贝，后续修改不会同步。要共享响应式数据，**传 ref / reactive 对象本身**。

### 4.1 `reactive` 的解构陷阱

```js
const product = reactive({ name: '梨', price: 28.9 })

const { name } = product
name = '苹果'          // ❌ 只改了局部变量
product.name = '苹果'  // ✅ 改代理对象
```

`reactive` 对象解构出来的属性会失去响应式；需要解构时用 `toRefs`：

```js
import { toRefs } from 'vue'

const { name, price } = toRefs(product)
```

### 4.2 `ref` 与 `reactive` 对比（源码末尾的拓展问题）

| 对比项 | `ref` | `reactive` |
| --- | --- | --- |
| 可包装类型 | 任意类型（基本类型、对象、数组） | 只能是对象/数组/Map/Set |
| 访问方式 | 脚本 `.value`，模板自动解包 | 直接访问属性 |
| 整体替换 | `x.value = 新值` ✅ | `Object.assign(x, 新值)`，直接赋值会丢响应式 ❌ |
| 解构 | 解构后仍是 ref（可 `toRefs`） | 直接解构丢响应式 |
| 推荐场景 | 基本类型、需要整体替换 | 一组相关字段的表单/实体 |

```js
// ref 整体替换没问题
const product = ref({ price: 28.9 })
product.value = { price: 19.9 }

// reactive 直接替换会断开代理
let product = reactive({ price: 28.9 })
product = { price: 19.9 } // ❌ 模板仍指向旧代理
```

---

## 五、provide/inject vs props

| 对比项 | props | provide/inject |
| --- | --- | --- |
| 传递方向 | 父 → 直接子 | 祖先 → 任意后代 |
| 中间组件 | 必须逐层声明并传递 | 不用经手 |
| 数据来源 | 显式、易追踪 | 隐式，需要知道 key |
| 类型检查 | `defineProps` 完整支持 | 无内置校验 |
| 适用 | 直接父子、展示型组件 | 主题、配置、跨层共享状态 |
| 耦合度 | 低 | 较高（后代依赖 key） |

> [!important] 不要滥用
> `provide/inject` 让依赖关系变得"看不见"：后代组件离开特定祖先就无法工作。它适合：
> - 组件库内部（表单、主题、语言包）；
> - 深层嵌套但确实需要共享的配置；
> - 不想引入 Pinia 的小型跨层状态。
>
> 普通父子传值仍应优先 `props` / `emit`。

---

## 六、单向数据流与修改权限

本例只读展示，没有修改。真实项目中，后代**不应直接改**注入的对象，否则数据变更来源难以追踪。推荐祖先同时提供修改函数：

```js
// 祖先
function updatePrice(newPrice) {
  product.price = newPrice
}
provide('productProvide', product)
provide('updatePrice', updatePrice)

// 后代
const updatePrice = inject('updatePrice')
updatePrice(19.9)
```

或者把注入值设为只读：

```js
import { readonly } from 'vue'
provide('productProvide', readonly(product))
```

> [!warning] readonly 是浅层还是深层
> `readonly(product)` 默认是**深层只读**：后代改任何嵌套属性都会在开发环境警告。若确实需要局部可写，用 `shallowReadonly`。

---

## 七、易错点清单

- [ ] `inject` 写在 `await` / 事件回调里 → 必须在 `setup` 同步阶段调用
- [ ] `provide` 的 key 与 `inject` 的 key 不一致 → 拿到 `undefined`
- [ ] key 写成 `'product-provide'` 与 `'productProvide'` → 不匹配
- [ ] 注入 `reactive` 后写 `.value` → 错误，直接访问属性
- [ ] 注入 `ref` 后在脚本里不写 `.value` → 拿到 Ref 对象，取值错误
- [ ] `provide('product', product.value)` → 丢失响应式
- [ ] 解构 `reactive` 对象 → 丢失响应式，需 `toRefs`
- [ ] 把 `inject` 结果当真值判断 → `undefined` 时静默失败，建议给默认值
- [ ] 文件名 / 组件名拼写 `Inect` → 与正确拼写 `Inject` 不一致，检索时容易漏
- [ ] 数据键名 `barnd`、`bunmber` → 应为 `brand`、`number`（键名一致所以能运行）

---

## 八、自测

1. `provide('productProvide', product)` 中 `product` 是 `reactive` 对象，后代模板为什么不用 `.value`？
2. 中间再插一层组件，`inject` 还能拿到吗？需要中间组件做什么吗？
3. 如果祖先写 `provide('productProvide', product.value)` 会怎样？
4. `inject('x')` 找不到 key 时返回什么？如何避免报错？
5. 后代想修改商品价格，推荐怎么做？
6. `ref` 和 `reactive` 在这个场景下分别怎么选？
7. 为什么文件名里的 `Inect` 不影响运行？

> [!success]- 参考答案
> 1. `reactive` 返回的是代理对象，属性访问本身就是响应式的，没有 `.value` 这一层。
> 2. 能。`provide/inject` 不受层级限制，中间组件不需要声明或传递任何东西。
> 3. 注入的是当时的普通对象快照，后续 `product` 的属性变化不会同步到后代。
> 4. 返回 `undefined`；给第二个参数默认值，或先判断再使用。
> 5. 祖先 provide 一个修改函数（如 `updatePrice`），后代 inject 后调用；或提供 `readonly` 数据，禁止后代直接改。
> 6. 一组相关字段、整体作为实体共享 → `reactive`；需要整体替换、或包含基本类型 → `ref`。本例是一组商品字段，`reactive` 合适。
> 7. 文件名不参与运行时解析，只要 import 路径与实际文件名一致即可；它只影响可读性和检索。

---

## 九、关联

- 上一篇：[[Exp8 具名作用域插槽]]
- 下一篇：[[Exp10 动态组件]]
- 综合应用：[[Exp11 商品详情页（依赖注入）]]
- 总览：[[00 组件通信与插槽总览]]
- 基础回顾：[[Props 组件属性]]、[[setup语法糖]]
