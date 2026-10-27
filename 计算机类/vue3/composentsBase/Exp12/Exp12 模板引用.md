# Exp12 模板引用

> [!abstract] 一句话
> 模板引用（template refs）是 Vue 给出的"**直接拿到 DOM 元素或子组件实例**"的官方后门：模板上写 `ref="名字"`，脚本里用同名 `ref(null)` 接住。==默认拿不到，必须等挂载完成；想拿子组件内部东西，还得子组件 `defineExpose` 主动开门。==

📁 源码：`Exp12/TemplateRefs1_RefDom.vue`、`Exp12/TemplateRefs2_RefChildComp_Child.vue`、`Exp12/TemplateRefs2_RefChildComp_Parent.vue`、`Exp12/TemplateRefs3_Ref_Vfor.vue`、`Exp12/TemplateRefs4_Ref_Function.vue`

---

## 一、四个 Demo 一览

| 文件 | 场景 | 关键写法 |
| --- | --- | --- |
| `TemplateRefs1_RefDom.vue` | 拿原生 DOM | `ref="inputRef"` + `ref(null)` |
| `TemplateRefs2_*_Child/Parent.vue` | 拿子组件实例 | 子组件 `defineExpose` |
| `TemplateRefs3_Ref_Vfor.vue` | 拿 `v-for` 的一组元素 | `ref` 指向数组 |
| `TemplateRefs4_Ref_Function.vue` | 用函数动态接引用 | `:ref="(el) => ..."` |

---

## 二、Demo 1：引用原生 DOM

```vue
<!-- TemplateRefs1_RefDom.vue -->
<template>
  <div>
    <!-- 给元素添加 ref 属性 -->
    <input ref="inputRef" type="text" placeholder="请输入内容" />
    <button @click="focusInput">聚焦输入框</button>
    <button @click="getInputValue">获取输入值</button>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

// 声明一个与 ref 属性同名的变量
// 在 Vue3中，模板引用通过 ref 属性实现，需要配合 ref() 函数使用。
const inputRef = ref(null)

// 组件挂载后可以访问到 DOM 元素
onMounted(() => {
  console.log('输入框元素:', inputRef.value)
  inputRef.value.focus() // 自动聚焦
})

function focusInput() {
  inputRef.value?.focus()
}

function getInputValue() {
  alert('输入的内容是：' + inputRef.value.value)
}
</script>
```

### 2.1 绑定规则

```text
模板：ref="inputRef"
            ↕ 同名自动绑定
脚本：const inputRef = ref(null)
```

`<script setup>` 中，**变量名必须与 `ref="..."` 的字符串一致**，Vue 才会自动把元素写进这个 ref。

### 2.2 为什么初始值是 `null`

| 阶段 | `inputRef.value` |
| --- | --- |
| `setup` 执行中 | `null`（模板还没渲染） |
| `mounted` 之后 | 真实 `<input>` 元素 |
| 元素被卸载后 | `null` |

所以：

```js
inputRef.value.focus()   // 在 mounted 里安全
inputRef.value?.focus()  // 在事件回调里用可选链更稳
```

> [!tip] 三种空值保护
> ```js
> inputRef.value?.focus()                 // 可选链，推荐
> inputRef.value && inputRef.value.focus() // 逻辑与
> if (inputRef.value) inputRef.value.focus()
> ```
> 源码注释里也列了这三种写法，效果等价。

### 2.3 拿到元素之后能做什么

```js
inputRef.value.focus()        // 聚焦
inputRef.value.value          // 读输入值
inputRef.value.scrollTop      // 滚动位置
inputRef.value.getBoundingClientRect() // 尺寸/位置
```

> [!warning] 不要用 ref 去改数据
> 能用响应式数据驱动的，就不要直接操作 DOM。模板引用适合**响应式覆盖不到**的场景：聚焦、选中、滚动、测量、播放媒体、集成第三方 DOM 库。

---

## 三、Demo 2：引用子组件实例

### 3.1 子组件：主动暴露

```vue
<!-- TemplateRefs2_RefChildComp_Child.vue -->
<template>
  <div>
    <p>子组件计数器：{{ count }}</p>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const count = ref(0)

// 必须通过 defineExpose 暴露方法/属性，父组件才能访问
function increment() {
  count.value++
}

function reset() {
  count.value = 0
}

defineExpose({
  increment,
  reset,
  count,
})
</script>
```

### 3.2 父组件：拿到实例并调用

```vue
<!-- TemplateRefs2_RefChildComp_Parent.vue -->
<template>
  <div>
    <ChildComponent ref="childRef" />
    <button @click="childRef.increment()">子组件 +1</button>
    <button @click="childRef.reset()">重置</button>
    <p>子组件当前计数：{{ childRef?.count }}</p>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import ChildComponent from './TemplateRefs2_RefChildComp_Child.vue'

const childRef = ref(null)
</script>
```

### 3.3 `<script setup>` 默认是"封闭"的

```text
没有 defineExpose：
父组件 childRef.value = { }        ← 空对象，什么都拿不到

有 defineExpose({ increment, count })：
父组件 childRef.value.increment()  ← 可以调用
父组件 childRef.value.count        ← 自动解包为数字
```

> [!important] 为什么组件要"封闭"
> 组件内部实现细节默认不对外暴露，避免父组件随意改子组件状态、破坏封装。`defineExpose` 是**显式契约**：只暴露你愿意公开的方法和属性。

### 3.4 模板里的 `childRef?.count`

- `childRef` 是顶层 ref，模板自动解包，所以写 `childRef.count` 而不是 `childRef.value.count`。
- 暴露的 `count` 本身是 ref，Vue 在实例代理上会再次解包，所以显示的是数字，不是 `RefImpl`。
- `?.` 用于首次渲染时的保护（挂载前是 `null`）。

> [!info] 事件回调里调用
> ```js
> function add() {
>   childRef.value?.increment()
> }
> ```
> 模板里能直接 `childRef.increment()`，是因为模板自动解包并做了代理；脚本里必须 `.value`。

### 3.5 什么时候该用组件 ref

| 场景 | 是否合适 |
| --- | --- |
| 调用子组件暴露的 `focus()` / `open()` / `reset()` | ✅ 合适 |
| 读子组件内部响应式状态 | ⚠️ 能读，但优先用 props/emit |
| 父组件直接改子组件数据 | ❌ 破坏单向数据流 |
| 需要跨多层调用 | ❌ 改用 provide/inject 或状态管理 |

---

## 四、Demo 3：`v-for` 中的 ref 数组

```vue
<!-- TemplateRefs3_Ref_Vfor.vue -->
<template>
  <ul>
    <li v-for="(item, index) in list" :key="index" ref="itemRefs">
      {{ item }}
    </li>
  </ul>
  <button @click="logRefs">打印所有引用</button>
</template>

<script setup>
import { ref } from 'vue'

const list = ref(['A', 'B', 'C'])
const itemRefs = ref([]) // 注意：v-for 中 ref 会收集为数组

function logRefs() {
  itemRefs.value.forEach((el, i) => {
    console.log(`第 ${i} 项：`, el.textContent)
  })
}
</script>
```

### 4.1 规则

- 同一个 `ref="itemRefs"` 出现在 `v-for` 的多个元素上 → Vue 把它们收集进**数组**。
- 接收变量必须初始化为 `ref([])`；写成 `ref(null)` 会导致类型/使用错误。
- 数组只在挂载后填充；卸载时对应项会被移除。

> [!warning] 关于顺序
> 旧版本文档明确说明"**不保证与源数组顺序一致**"；Vue 3.5+ 已改为按源顺序收集。本项目使用 Vue 3.5.42，一般可认为顺序一致；对顺序极其敏感时，用**函数 ref** 显式按下标存储更稳妥（见 Demo 4）。

### 4.2 常见用途

```js
// 批量聚焦 / 批量测量
itemRefs.value.forEach(el => el.classList.add('checked'))
```

> [!tip] 只用下标、不用数据时
> `v-for` 的 `:key="index"` 在列表会增删/排序时不稳定。真实项目应使用唯一 id 作为 key；`ref` 数组的顺序也依赖 key 的稳定性。

---

## 五、Demo 4：函数引用

```vue
<!-- TemplateRefs4_Ref_Function.vue -->
<template>
  <input :ref="(el) => setInputRef(el)" />
</template>

<script setup>
import { ref } from 'vue'

const inputEl = ref(null)

// 每次渲染时调用，el 为元素或组件实例
function setInputRef(el) {
  inputEl.value = el
}
</script>
```

### 5.1 调用时机

| 时机 | `el` |
| --- | --- |
| 元素挂载 / 更新后 | 真实元素或组件实例 |
| 元素卸载前 | `null` |

所以函数 ref 必须能处理 `null`：

```js
function setInputRef(el) {
  inputEl.value = el
}
```

> [!important] 每次渲染都会调用
> 函数 ref 在**每次组件更新后**都会重新执行，不要在函数里做昂贵操作。它的优势是可以在函数里做任意逻辑：按下标存、存进 `Map`、过滤空值等。

### 5.2 用函数 ref 收集 `v-for`

```vue
<script setup>
import { ref } from 'vue'

const itemRefs = ref([])

function setItemRef(el, index) {
  if (el) itemRefs.value[index] = el
}
</script>

<template>
  <li v-for="(item, index) in list" :key="item.id" :ref="(el) => setItemRef(el, index)">
    {{ item.name }}
  </li>
</template>
```

这样能**显式保证下标对应**，比隐式数组更可控。

---

## 六、现代写法：`useTemplateRef`（Vue 3.5+）

本项目 Vue 版本为 `^3.5.42`，可以使用组合式函数：

```vue
<script setup>
import { useTemplateRef, onMounted } from 'vue'

const inputRef = useTemplateRef('inputRef')

onMounted(() => {
  inputRef.value?.focus()
})
</script>

<template>
  <input ref="inputRef" />
</template>
```

| 写法 | 特点 |
| --- | --- |
| `const x = ref(null)` + 同名 | 传统写法，兼容所有 Vue 3 版本 |
| `useTemplateRef('x')` | 3.5+，名字与变量解耦，类型推导更友好 |
| `:ref="fn"` | 需要动态逻辑时使用 |

> [!info] 源码为什么不用
> 这套示例沿用传统写法，是为了说明"同名绑定"的原理。理解原理后，新项目可优先 `useTemplateRef`。

---

## 七、ref 的完整生命周期

```text
setup()            inputRef.value === null
   │
   ▼
模板渲染
   │
   ▼
mounted            inputRef.value === <input>
   │
   ├── 更新（元素复用）→ 值不变
   ├── v-if 切换        → 卸载时变 null，重新挂载后再赋值
   ▼
unmounted          inputRef.value === null
```

> [!warning] 不要在 `setup` 顶层直接访问
> ```js
> const inputRef = ref(null)
> inputRef.value.focus() // ❌ null.focus()
> ```
> 必须放到 `onMounted` 或事件回调里。

---

## 八、易错点清单

- [ ] 模板 `ref="inputRef"`，脚本变量叫 `input` → 绑定不上，永远 `null`
- [ ] 在 `setup` 顶层访问 `ref.value` → 还是 `null`
- [ ] 子组件没写 `defineExpose` → 父组件拿到空对象
- [ ] `v-for` 的 ref 接收变量写成 `ref(null)` → 应为 `ref([])`
- [ ] 函数 ref 里没处理 `el === null` → 卸载时把 `null` 存进去，可能引发后续报错
- [ ] 以为 `childRef.value.count` 是数字就写 `childRef.value.count.value` → 实例代理已解包
- [ ] 脚本里写 `childRef.increment()` → 应为 `childRef.value?.increment()`
- [ ] 用 ref 直接改子组件内部状态 → 破坏封装与单向数据流
- [ ] 每次渲染在函数 ref 里做重计算 → 性能问题

---

## 九、自测

1. `const inputRef = ref(null)` 里的 `null` 能换成 `ref()` 吗？为什么？
2. 为什么 `onMounted` 里能拿到 DOM，`setup` 顶层拿不到？
3. 子组件不写 `defineExpose`，父组件 `childRef.value` 是什么？
4. `v-for` 上写 `ref="itemRefs"`，`itemRefs` 应该初始化成什么？
5. 函数 ref 在什么时候被调用？卸载时 `el` 是什么？
6. 模板里为什么写 `childRef?.count` 而不是 `childRef.value?.count`？
7. 有了 `ref` 之后，是不是可以随便操作 DOM 和子组件？

> [!success]- 参考答案
> 1. 可以，`ref()` 的初值就是 `undefined`，但语义上 `null` 更明确表示"还没挂载"；两者都不影响绑定。
> 2. 模板引用在**挂载后**才被赋值。`setup` 执行时模板尚未渲染，`ref.value` 仍是初始值。
> 3. 一个空对象（或仅含极少数内部属性的代理），拿不到子组件的任何自定义方法和状态。
> 4. `ref([])`，因为 Vue 会把多个元素收集成数组。
> 5. 元素挂载/更新后调用；卸载前以 `null` 调用一次。
> 6. 模板中的顶层 ref 会自动解包，`childRef` 已经是实例本身；再写 `.value` 反而是错的。
> 7. 不可以。优先用数据驱动；模板引用只用于聚焦、测量、滚动、媒体控制、第三方库集成等响应式难以覆盖的场景，且操作子组件必须遵守 `defineExpose` 契约。

---

## 十、关联

- 前一篇：[[Exp11 商品详情页（依赖注入）]]
- 总览：[[00 组件通信与插槽总览]]
- 基础回顾：[[引用注册]]、[[组件注册]]、[[setup语法糖]]
- 相关：[[Exp2 子传父 emit]]（父调子方法的另一种思路是 emit）
