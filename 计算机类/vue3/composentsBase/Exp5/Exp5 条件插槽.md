# Exp5 条件插槽

> [!abstract] 一句话
> 父组件用 `v-if` 决定"要不要提供某个插槽"，子组件用 `$slots.xxx` 判断"这个插槽到底存不存在"，从而**连插槽外面的包裹层一起条件渲染**。==否则即使没有内容，`<header>` 那层空壳也会留在页面上。==

📁 源码：`Exp5/Exp5_IfSlot_Parent.vue`、`Exp5/Exp5_IfSlot_Child.vue`

---

## 一、要解决的问题

假设子组件这样写：

```vue
<header class="card-header">
  <slot name="header" />
</header>
```

如果父组件没传 `#header`：

- `<slot>` 本身不渲染内容；
- 但 `<header class="card-header">` **仍然存在**，会留下一条空白灰条和内边距。

> [!warning] 症状
> 页面出现"莫名其妙的空白区域"或"多余的分隔线"，往往就是**空插槽 + 固定外壳**造成的。

正确做法：**先判断插槽是否存在，再决定外壳渲不渲染。**

```vue
<header v-if="$slots.header" class="card-header">
  <slot name="header" />
</header>
```

---

## 二、完整源码

### 2.1 子组件

```vue
<!-- Exp5_IfSlot_Child.vue -->
<template>
  <div class="card">
    <!-- 头部：如果父组件提供了 header 插槽才渲染 -->
    <header v-if="$slots.header" class="card-header">
      <slot name="header" />
    </header>

    <!-- 主体：默认插槽，始终存在 -->
    <main class="card-body">
      <slot />
    </main>

    <!-- 底部：只有父组件提供了 footer 插槽才渲染 -->
    <footer v-if="$slots.footer" class="card-footer">
      <slot name="footer" />
    </footer>
  </div>
</template>

<script setup>
// 子组件定义多个具名插槽，并用 $slots 判断插槽是否存在，从而条件渲染外围结构。
</script>

<style scoped>
.card { border: 1px solid #ddd; border-radius: 8px; overflow: hidden; margin: 12px 0; }
.card-header { background: #f5f5f5; padding: 8px 12px; font-weight: bold; }
.card-body { padding: 12px; }
.card-footer { background: #fafafa; padding: 8px 12px; text-align: right; }
</style>
```

### 2.2 父组件

```vue
<!-- Exp5_IfSlot_Parent.vue -->
<template>
  <div>
    <label> <input type="checkbox" v-model="showHeader" /> 显示 Header </label>
    <label style="margin-left: 16px">
      <input type="checkbox" v-model="showFooter" /> 显示 Footer
    </label>

    <ChildCard>
      <!-- 条件插槽：v-if 为 false 时，该插槽内容不存在 -->
      <template #header v-if="showHeader">
        <span>标题区域</span>
      </template>

      <!-- 默认插槽：始终渲染 -->
      <p>这是卡片主体内容，始终显示。</p>

      <template #footer v-if="showFooter">
        <button>确定</button>
      </template>
    </ChildCard>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import ChildCard from './Exp5_IfSlot_Child.vue'

const showHeader = ref(true)
const showFooter = ref(false)
</script>
```

---

## 三、运行效果

初始：`showHeader = true`，`showFooter = false`。

```text
┌──────────────────────────┐
│ 标题区域                  │  ← header 存在
├──────────────────────────┤
│ 这是卡片主体内容，始终显示。│  ← 默认插槽
└──────────────────────────┘     ← 没有 footer 外壳
```

勾选 "显示 Footer" 后：

```text
┌──────────────────────────┐
│ 标题区域                  │
├──────────────────────────┤
│ 这是卡片主体内容，始终显示。│
├──────────────────────────┤
│                   [确定]  │  ← footer 外壳 + 内容出现
└──────────────────────────┘
```

取消勾选 "显示 Header" 后，连灰色标题条一起消失，而不是留下空白。

---

## 四、`$slots` 是什么

`$slots` 是组件实例上的**插槽对象**，键是插槽名，值是插槽函数。

```js
$slots = {
  header: fn,
  default: fn,
  footer: fn,   // 只有父组件提供了才有这个键
}
```

| 判断 | 含义 |
| --- | --- |
| `$slots.header` | 父组件是否提供了 `header` 插槽 |
| `$slots.default` | 父组件是否提供了默认插槽内容 |
| `Object.keys($slots)` | 当前提供了哪些插槽 |

> [!important] 它判断的是"有没有提供"，不是"内容是否为空"
> - 父组件写了 `<template #header><span></span></template>` → `$slots.header` 为真。
> - 父组件写了 `<template #header></template>`（完全空） → 通常仍会创建一个空插槽函数，仍为真。
>
> 想判断"有没有实际内容"，需要自己检查 `$slots.header()` 返回的 VNode 数组是否为空——一般不这么做，约定父组件不提供就不要写空模板。

---

## 五、脚本里怎么用

```vue
<script setup>
import { useSlots } from 'vue'

const slots = useSlots()
console.log(slots.header)          // 函数或 undefined
const hasHeader = !!slots.header
</script>
```

```js
// 渲染函数 / h() 中使用
import { h, useSlots } from 'vue'
const slots = useSlots()
return h('div', slots.header ? slots.header() : null)
```

> [!warning] `$slots` 不是响应式对象
> 在模板里每次重新渲染都会读取最新的 `$slots`，所以 `v-if="$slots.header"` 能随父组件变化更新。
> 但在 `<script setup>` 里用 `computed(() => !!slots.header)` **不会**自动追踪插槽增删（slots 不是 reactive）。需要响应式判断时，用 `onUpdated` 手动读取，或改成由 props 控制显隐。

---

## 六、两种"条件"别搞混

| 写法 | 写在哪 | 控制什么 |
| --- | --- | --- |
| `<template #header v-if="show">` | **父组件** | 插槽**是否存在** |
| `<header v-if="$slots.header">` | **子组件** | 插槽**外壳是否渲染** |

> [!tip] 最佳实践
> **父组件用 `v-if` 决定给不给，子组件用 `$slots` 决定包不包外壳。** 两者配合，页面结构才干净。
> 只在子组件写 `$slots` 判断、父组件却传空模板 → 外壳仍会出现；只在父组件写 `v-if`、子组件不判断 → 没内容时可能留下空壳。两边都要做。

---

## 七、更进一步的"默认值"写法

如果希望父组件没提供时显示占位内容，可以直接用后备内容：

```vue
<slot name="header">
  <span>默认标题</span>
</slot>
```

但如果连外壳都不想要，就仍需 `v-if="$slots.header"`。**后备内容解决"显示什么"，`$slots` 解决"要不要这一块"。**

---

## 八、典型应用场景

- **卡片组件**：有 header 才显示头部，有 footer 才显示底部。
- **弹窗组件**：`#footer` 没传就不渲染按钮区。
- **表格组件**：`#empty` 没传就用默认空状态。
- **布局组件**：`#sidebar` 没传就不占侧边栏宽度。

```vue
<!-- 弹窗 -->
<div class="modal">
  <div v-if="$slots.header" class="modal-header"><slot name="header" /></div>
  <div class="modal-body"><slot /></div>
  <div v-if="$slots.footer" class="modal-footer"><slot name="footer" /></div>
</div>
```

---

## 九、易错点清单

- [ ] 只写 `<slot name="x">` 不判断 `$slots` → 空外壳残留
- [ ] `v-if` 写在 `<slot>` 上而不是包裹层 → 外壳仍在
- [ ] 以为 `$slots.x` 能判断内容是否为空 → 它只判断是否提供
- [ ] 在 JS 里用 `computed` 包 `$slots` → 不会随插槽变化更新
- [ ] 父组件传了空 `<template #x>` → `$slots.x` 仍为真
- [ ] 默认插槽也写 `v-if="$slots.default"` → 没传默认内容时主体整块消失，通常不是本意

---

## 十、自测

1. 子组件写 `<header><slot name="header" /></header>`，父组件不传 `#header`，页面会多出什么？
2. `$slots.header` 为真，能说明 header 里有可见内容吗？
3. 父组件 `v-if` 和子组件 `$slots` 判断，分别控制什么？
4. 想在 JS 中拿插槽，用哪个 API？
5. 为什么 `computed(() => !!slots.header)` 可能不更新？

> [!success]- 参考答案
> 1. 会留下 `<header>` 外壳（背景、内边距等），只是里面没有内容。
> 2. 不能，只说明父组件提供了该插槽。
> 3. 父组件控制插槽是否存在；子组件控制外壳是否渲染。
> 4. `useSlots()`（模板中用 `$slots`）。
> 5. `slots` 对象不是响应式的，`computed` 追踪不到插槽的增删。

---

## 十一、同型练习：弹窗条件插槽

> [!info] 题目
> 实现一个 `Modal` 弹窗组件，结构如下：
>
> ```vue
> <div class="modal">
>   <div v-if="$slots.header" class="modal-header">
>     <slot name="header" />
>   </div>
>   <div class="modal-body"><slot /></div>
>   <div v-if="$slots.footer" class="modal-footer">
>     <slot name="footer" />
>   </div>
> </div>
> ```
>
> 父组件用 `showFooter` 控制是否提供底部按钮区：
>
> ```vue
> <Modal>
>   <template #header>提示</template>
>   <p>确定要删除吗？</p>
>   <template #footer v-if="showFooter">
>     <button>取消</button>
>     <button>确定</button>
>   </template>
> </Modal>
> ```
>
> 回答：
> 1. `showFooter = false` 时，页面上还能看到 `modal-footer` 这一块吗？
> 2. `$slots.footer` 为真，是否代表 footer 里有可见内容？
> 3. 父组件写了一个完全空的 `<template #footer></template>`，`modal-footer` 外壳会渲染吗？
> 4. 如果把 `v-if` 写在 `<slot>` 上而不是外壳上，会怎样？
> 5. 为什么在 `<script setup>` 里写 `computed(() => !!slots.footer)` 可能不更新？

> [!success]- 参考答案
> **子组件**
>
> ```vue
> <!-- Modal.vue -->
> <template>
>   <div class="modal">
>     <div v-if="$slots.header" class="modal-header">
>       <slot name="header" />
>     </div>
>     <div class="modal-body"><slot /></div>
>     <div v-if="$slots.footer" class="modal-footer">
>       <slot name="footer" />
>     </div>
>   </div>
> </template>
>
> <script setup>
> // 使用 $slots 判断插槽是否存在，从而条件渲染外围结构。
> </script>
> ```
>
> **父组件**
>
> ```vue
> <!-- ModalParent.vue -->
> <template>
>   <label><input type="checkbox" v-model="showFooter" /> 显示底部</label>
>   <Modal>
>     <template #header>提示</template>
>     <p>确定要删除吗？</p>
>     <template #footer v-if="showFooter">
>       <button>取消</button>
>       <button>确定</button>
>     </template>
>   </Modal>
> </template>
>
> <script setup>
> import { ref } from 'vue'
> import Modal from './Modal.vue'
>
> const showFooter = ref(false)
> </script>
> ```
>
> **逐问回答**
> 1. 看不到。父组件没有提供 `#footer`，`$slots.footer` 为 `undefined`，`v-if` 为假，整个 `.modal-footer`（包括背景、内边距、边框）都不会出现在 DOM 中。
> 2. 不能。它只表示"父组件提供了这个插槽"，不表示插槽内容非空或可见。父组件写一个空元素甚至空模板，`$slots.footer` 都可能为真。
> 3. 会。空的 `<template #footer></template>` 仍会创建一个 footer 插槽函数，`$slots.footer` 为真，于是外壳照常渲染，只是里面什么都没有——这正是"莫名空白条"的来源。
> 4. 外壳会永远存在。写成 `<div class="modal-footer"><slot v-if="$slots.footer" name="footer" /></div>` 时，`v-if` 只控制 `<slot>` 要不要渲染，`.modal-footer` 这个 div 不受影响，没内容时仍会留下空白区域。
> 5. `useSlots()` 返回的 `slots` 对象不是响应式对象，`computed` 无法追踪插槽的增删。模板里的 `$slots` 会在每次渲染时读取最新值，所以 `v-if="$slots.footer"` 能正常更新；在 JS 中需要响应式判断时，应改用 props 控制显隐，或在 `onUpdated` 中手动读取。

---

## 十二、关联

- 上一篇：[[Exp4 具名插槽]]
- 下一篇：[[Exp6 动态插槽名]]
- 总览：[[00 组件通信与插槽总览]]
