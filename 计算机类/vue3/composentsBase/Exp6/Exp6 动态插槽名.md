# Exp6 动态插槽名

> [!abstract] 一句话
> 插槽名也能是变量：子组件 `<slot :name="section">`，父组件 `<template #[section]>`。配合 `v-for`，就能为一组同构区域批量生成插槽。==本例的关键不在语法，而在"只遍历真正有内容的 section"，否则后备内容永远不出现。==

📁 源码：`Exp6/Exp6_DynamicSlotName_Parent.vue`、`Exp6/Exp6_DynamicSlotName_Child.vue`

---

## 一、完整源码

### 1.1 子组件

```vue
<!-- Exp6_DynamicSlotName_Child.vue -->
<template>
  <div class="panel">
    <div v-for="section in sections" :key="section" class="panel-section">
      <h4>{{ section }}</h4>

      <!-- 动态插槽名：name 由变量 section 决定 -->
      <slot :name="section">
        <!-- 后备内容：父组件没传该插槽时显示 -->
        <p class="empty">（暂无 {{ section }} 内容）</p>
      </slot>
    </div>
  </div>
</template>

<script setup>
defineProps({
  sections: {
    type: Array,
    required: true,
  },
})
</script>

<style scoped>
.panel { border: 1px solid #ddd; border-radius: 8px; padding: 12px; }
.panel-section + .panel-section {
  margin-top: 12px;
  border-top: 1px dashed #eee;
  padding-top: 12px;
}
.empty { color: #999; font-style: italic; }
</style>
```

### 1.2 父组件

```vue
<!-- Exp6_DynamicSlotName_Parent.vue -->
<template>
  <div>
    <ChildPanel :sections="sections">
      <!-- 动态插槽名：只为有内容的 section 生成插槽，没内容的交给子组件显示后备内容 -->
      <template v-for="section in availableSections" :key="section" #[section]>
        <p>{{ contentMap[section] }}</p>
      </template>
    </ChildPanel>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import ChildPanel from './Exp6_DynamicSlotName_Child.vue'

const sections = ref(['基本信息', '详细描述', '联系方式'])

// 只为前两个 section 提供内容，第三个会显示子组件的后备内容
const contentMap = {
  基本信息: '这是基本信息的内容。',
  详细描述: '这是详细描述的内容。',
}

// 关键：v-for 只遍历真正有内容的 section。
// 否则每个 section 都会向子组件传一个插槽，$slots 里存在该插槽，
// 子组件的后备内容就永远不会显示，只会渲染一个空的 <p>。
const availableSections = computed(() => sections.value.filter((section) => section in contentMap))
</script>
```

---

## 二、渲染结果

```text
┌─────────────────────────────┐
│ 基本信息                     │
│ 这是基本信息的内容。          │  ← 父组件提供了 #[基本信息]
├─────────────────────────────┤
│ 详细描述                     │
│ 这是详细描述的内容。          │  ← 父组件提供了 #[详细描述]
├─────────────────────────────┤
│ 联系方式                     │
│ （暂无 联系方式 内容）        │  ← 父组件没提供，显示子组件后备内容
└─────────────────────────────┘
```

---

## 三、动态插槽名语法

### 3.1 子组件端

```vue
<!-- 静态 -->
<slot name="header" />

<!-- 动态：name 绑定一个变量 -->
<slot :name="section" />
```

### 3.2 父组件端

```vue
<!-- 静态 -->
<template #header>…</template>

<!-- 动态：方括号里写表达式 -->
<template #[section]>…</template>

<!-- 等价的全称写法 -->
<template v-slot:[section]>…</template>
```

> [!important] 语法要点
> - `#[section]` 是 `v-slot:[section]` 的简写。
> - 方括号内是 **JS 表达式**，结果会被转成字符串作为插槽名。
> - 动态参数不能包含空格或引号，复杂表达式请先算好放进变量。
> - 插槽名区分大小写，动态生成的字符串必须与子组件 `:name` 的取值**完全一致**。

---

## 四、为什么 `v-for` 要配合动态插槽名？

需求：子组件有 N 个区域，父组件想"按区域名"分别提供内容。

```text
sections = ['基本信息', '详细描述', '联系方式']
```

如果手写：

```vue
<ChildPanel :sections="sections">
  <template #基本信息>…</template>
  <template #详细描述>…</template>
  <template #联系方式>…</template>
</ChildPanel>
```

区域一变就要改代码。用 `v-for` + 动态名，可以批量生成：

```vue
<template v-for="section in availableSections" :key="section" #[section]>
  <p>{{ contentMap[section] }}</p>
</template>
```

> [!tip] 这是"数据驱动 UI"在插槽上的体现
> 区域列表来自数据，插槽也由数据生成；新增一个 section，只要在 `contentMap` 里加一条，模板不用动。

---

## 五、本例真正的坑：遍历范围

### 5.1 错误写法

```vue
<template v-for="section in sections" :key="section" #[section]>
  <p>{{ contentMap[section] }}</p>
</template>
```

对 `联系方式` 来说：

- `contentMap['联系方式']` 是 `undefined`；
- 但父组件**确实提供了一个名为 `联系方式` 的插槽**，内容是 `<p></p>`；
- 子组件的 `<slot :name="section">` 发现"有插槽"，于是**不使用后备内容**；
- 页面只剩一个空白 `<p>`，看不到"（暂无 联系方式 内容）"。

### 5.2 正确写法

```js
const availableSections = computed(() =>
  sections.value.filter((section) => section in contentMap),
)
```

```vue
<template v-for="section in availableSections" :key="section" #[section]>
```

只给"真正有内容"的区域创建插槽，其余区域在 `$slots` 中不存在，子组件自然回退到后备内容。

> [!important] 一句话记住
> **插槽的"存在"由父组件是否写了 `<template #x>` 决定，与内容是否为空无关。**
> 这和 [[Exp3 默认插槽]] 中"空元素也算提供了内容"、[[Exp5 条件插槽]] 中"`$slots` 只判断存在"是同一条规律。

---

## 六、`v-for` + `v-slot` 的写法规则

```vue
<!-- ✅ 正确：v-for 和动态插槽名都写在 <template> 上 -->
<template v-for="section in availableSections" :key="section" #[section]>
  <p>{{ contentMap[section] }}</p>
</template>
```

- `v-for` 必须带 `:key`（这里用 section 字符串）。
- 动态插槽名与 `v-for` 可以同时出现在同一个 `<template>` 上。
- 不要写成 `<div v-for ... #x>`：`v-slot` 只能用于组件或 `<template>`。

---

## 七、另一种实现：子组件侧判断

除了父组件过滤，子组件也可以显式判断：

```vue
<slot v-if="$slots[section]" :name="section" />
<p v-else class="empty">（暂无 {{ section }} 内容）</p>
```

效果类似，但更啰嗦。本例选择"父组件少传 + 子组件后备内容"，模板更干净。

> [!tip] 两种思路
> - **父组件过滤**：只传有内容的，子组件用 `<slot>` 后备内容兜底。
> - **子组件判断**：父组件全传，子组件用 `$slots[name]` 决定是否显示占位。
>
> 数据来源清晰时优先前者；插槽名不可预知、需要统一兜底时用后者。

---

## 八、动态插槽名的其他用途

- **标签页组件**：`<slot :name="tab.key">`，每个 tab 一个插槽。
- **表格列**：`<slot :name="`col-${column.key}`">`，自定义每列渲染。
- **表单字段**：按字段名分发插槽，统一布局。
- **多步骤向导**：`<slot :name="step.key">`。

```vue
<!-- 表格列自定义 -->
<template v-for="col in columns" :key="col.key" #[`col-${col.key}`]="{ row }">
  <span>{{ row[col.key] }}</span>
</template>
```

---

## 九、与作用域插槽组合

动态名同样可以传数据：

```vue
<!-- 子 -->
<slot :name="section" :data="sectionData" />

<!-- 父 -->
<template #[section]="{ data }">
  {{ data }}
</template>
```

详见 [[Exp7 作用域插槽]]、[[Exp8 具名作用域插槽]]。

---

## 十、易错点清单

- [ ] 遍历全部 sections，导致空插槽顶掉后备内容
- [ ] 动态名写成 `#section`（少了方括号）→ 变成固定名字 `"section"`
- [ ] 忘了 `:key` → 列表更新错乱
- [ ] 插槽名大小写/空格不一致 → 匹配失败
- [ ] 在普通元素上写 `v-slot` → 编译报错
- [ ] `contentMap` 用 `in` 判断时，值为 `''` 也算有内容 → 需要更严格时判断 `!= null && !== ''`
- [ ] 子组件 `v-for` 的 `:key` 用索引 → 区域增删时复用错位

---

## 十一、自测

1. `#[section]` 的全称写法是什么？
2. 为什么遍历全部 `sections` 时，第三个区域不显示后备内容？
3. `availableSections` 的作用是什么？
4. 动态插槽名可以配合作用域插槽吗？
5. 如果 `contentMap` 里某区域的值是空字符串，`section in contentMap` 会怎样？

> [!success]- 参考答案
> 1. `v-slot:[section]`。
> 2. 父组件仍为该名字创建了插槽（内容是空 `<p>`），子组件认为插槽存在，不使用 fallback。
> 3. 过滤出真正有内容的区域，只为它们创建插槽。
> 4. 可以，`<slot :name="x" :data="d" />` + `#[x]="{ data }"`。
> 5. 返回 `true`，仍会创建插槽（可能渲染空内容）。

---

## 十二、同型练习：动态 Tab 插槽

> [!info] 题目
> 实现一个 `Tabs` 面板组件：接收 `tabs` 数组（每项含 `key`、`label`），循环渲染每个区域，并用动态插槽名把内容区交给父组件：
>
> ```vue
> <section v-for="tab in tabs" :key="tab.key">
>   <h4>{{ tab.label }}</h4>
>   <slot :name="tab.key">
>     <p>暂无 {{ tab.label }} 内容</p>
>   </slot>
> </section>
> ```
>
> 父组件的数据：
>
> ```js
> const tabs = [
>   { key: 'profile', label: '个人资料' },
>   { key: 'security', label: '安全设置' },
>   { key: 'notice', label: '消息通知' },
> ]
>
> const contentMap = {
>   profile: '这里是个人资料',
>   security: '这里是安全设置',
> }
> ```
>
> 要求：
> 1. 只为 `contentMap` 中存在的 tab 创建插槽；
> 2. 未提供内容的 tab 显示子组件后备内容；
> 3. 回答：`#[tab.key]` 的全称是什么？如果直接 `v-for="tab in tabs"` 会怎样？如果 `contentMap` 中某个值是空字符串 `''`，过滤条件会怎样？

> [!success]- 参考答案
> **子组件**
>
> ```vue
> <!-- Tabs.vue -->
> <template>
>   <div class="tabs">
>     <section v-for="tab in tabs" :key="tab.key" class="tab-section">
>       <h4>{{ tab.label }}</h4>
>       <slot :name="tab.key">
>         <p class="empty">暂无 {{ tab.label }} 内容</p>
>       </slot>
>     </section>
>   </div>
> </template>
>
> <script setup>
> defineProps({
>   tabs: {
>     type: Array,
>     required: true,
>   },
> })
> </script>
> ```
>
> **父组件**
>
> ```vue
> <!-- TabsParent.vue -->
> <template>
>   <Tabs :tabs="tabs">
>     <template v-for="tab in filledTabs" :key="tab.key" #[tab.key]>
>       <p>{{ contentMap[tab.key] }}</p>
>     </template>
>   </Tabs>
> </template>
>
> <script setup>
> import { computed, ref } from 'vue'
> import Tabs from './Tabs.vue'
>
> const tabs = ref([
>   { key: 'profile', label: '个人资料' },
>   { key: 'security', label: '安全设置' },
>   { key: 'notice', label: '消息通知' },
> ])
>
> const contentMap = {
>   profile: '这里是个人资料',
>   security: '这里是安全设置',
> }
>
> // 关键：只遍历真正有内容的 tab，否则 notice 也会创建插槽，顶掉后备内容。
> const filledTabs = computed(() => tabs.value.filter((tab) => tab.key in contentMap))
> </script>
> ```
>
> **渲染结果**
>
> ```text
> 个人资料
> 这里是个人资料
> 安全设置
> 这里是安全设置
> 消息通知
> 暂无 消息通知 内容        ← 父组件没提供 notice 插槽，显示后备内容
> ```
>
> **逐问回答**
> 1. `#[tab.key]` 的全称是 `v-slot:[tab.key]`。方括号内是 JS 表达式，结果转成字符串后作为插槽名，必须与子组件 `:name` 的取值完全一致（区分大小写）。
> 2. 直接 `v-for="tab in tabs"` 时，`notice` 也会生成一个名为 `notice` 的插槽，内容是 `<p>{{ contentMap.notice }}</p>`，即 `<p></p>`。子组件发现插槽存在，就不会使用后备内容，页面只剩空白，看不到"暂无 消息通知 内容"。
> 3. `tab.key in contentMap` 只检查**键是否存在**，不检查值。若 `contentMap.notice = ''`，条件仍为 `true`，仍会创建插槽并渲染空内容。需要把空字符串也视为"没内容"时，应改成更严格的判断：
>    ```js
>    const filledTabs = computed(() =>
>      tabs.value.filter((tab) => {
>        const value = contentMap[tab.key]
>        return value != null && value !== ''
>      }),
>    )
>    ```

---

## 十三、关联

- 上一篇：[[Exp5 条件插槽]]
- 下一篇：[[Exp7 作用域插槽]]
- 总览：[[00 组件通信与插槽总览]]
