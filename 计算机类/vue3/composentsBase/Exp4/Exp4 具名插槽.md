# Exp4 具名插槽

> [!abstract] 一句话
> 子组件有多个"坑"时，给每个 `<slot>` 起个 `name`；父组件用 `<template #名字>` 分别填坑。==名字负责"配对"，位置仍由子组件模板决定==——父组件写得再早，也不会改变渲染顺序。

📁 源码：`Exp4/Exp4_NamedSlot_Parent.vue`、`Exp4/Exp4_NamedSlot_Child.vue`

---

## 一、完整源码

### 1.1 子组件（定义三个坑）

```vue
<!-- Exp4_NamedSlot_Child.vue -->
<template>
  <div>
    <slot name="title"></slot>
    <slot name="author"></slot>
    <slot></slot>
  </div>
</template>

<script setup>
// 子组件无逻辑，仅作为具名插槽的容器
</script>
```

### 1.2 父组件（分别填坑）

```vue
<!-- Exp4_NamedSlot_Parent.vue -->
<template>
  <h3>具名插槽</h3>
  <Poetry>
    <template v-slot:title>
      <h3>行路难·其一</h3>
    </template>

    <template #author>
      <p>李白</p>
    </template>

    <template #default>
      <div>行路难，行路难，多岐路，今安在？</div>
      <div>长风破浪会有时，直挂云帆济沧海。</div>
    </template>
  </Poetry>
</template>

<script setup>
import Poetry from './Exp4_NamedSlot_Child.vue'
</script>
```

### 1.3 渲染结果

```html
<div>
  <h3>行路难·其一</h3>                    <!-- title -->
  <p>李白</p>                             <!-- author -->
  <div>行路难，行路难，多岐路，今安在？</div> <!-- default -->
  <div>长风破浪会有时，直挂云帆济沧海。</div> <!-- default -->
</div>
```

---

## 二、配对关系

```text
子组件（定义）                父组件（填充）
<slot name="title" />   ←→   <template #title>…</template>
<slot name="author" />  ←→   <template #author>…</template>
<slot />                ←→   <template #default>…</template>
                             或直接写在 <Poetry> 里的内容
```

| 子组件 | 父组件 | 说明 |
| --- | --- | --- |
| `name="title"` | `#title` / `v-slot:title` | 具名 |
| `name="author"` | `#author` / `v-slot:author` | 具名 |
| 不写 `name` | `#default` / `v-slot:default` / 直接内容 | 默认插槽 |

> [!important] 三个要点
> 1. `<slot>` 不写 `name`，等价于 `name="default"`。
> 2. `#` 是 `v-slot:` 的缩写，`#title` = `v-slot:title`。
> 3. 具名插槽的填充**必须写在 `<template>` 上**（或使用 `<template #x>`），普通元素上没有 `v-slot`。

---

## 三、渲染顺序由谁决定？

父组件里 `title` 写在最前，`default` 写在最后。假设父组件把顺序打乱：

```vue
<Poetry>
  <template #default>正文</template>
  <template #author>李白</template>
  <template #title>标题</template>
</Poetry>
```

渲染结果**仍然是**：

```text
标题 → 李白 → 正文
```

因为顺序由**子组件的 `<slot>` 排列**决定：

```vue
<slot name="title" />
<slot name="author" />
<slot />
```

> [!tip] 一句话
> **父组件决定"每块内容是什么"，子组件决定"每块内容放哪里"。** 布局权在子组件，内容权在父组件。

---

## 四、默认插槽的三种写法

```vue
<!-- 写法 1：直接写内容 -->
<Poetry>
  <p>正文</p>
</Poetry>

<!-- 写法 2：显式 #default -->
<Poetry>
  <template #default>
    <p>正文</p>
  </template>
</Poetry>

<!-- 写法 3：v-slot:default -->
<Poetry>
  <template v-slot:default>
    <p>正文</p>
  </template>
</Poetry>
```

> [!warning] 混用时的归属
> 在 `<Poetry>` 内、所有 `<template #x>` **之外**的节点，都会进入默认插槽。
> ```vue
> <Poetry>
>   <p>我会进默认插槽</p>
>   <template #title>标题</template>
> </Poetry>
> ```
> 不要既写游离内容又写 `#default`，否则默认插槽内容会叠加，容易看花眼。

---

## 五、具名插槽的后备内容

子组件同样可以给具名插槽准备后备内容：

```vue
<slot name="title">
  <h3>默认标题</h3>
</slot>
```

父组件没提供 `#title` 时显示 `<h3>默认标题</h3>`；提供了就替换。

> [!info] 本例没有后备内容
> Exp4 的三个 `<slot>` 都是空的，父组件全提供了，所以看不到后备效果。原理与 [[Exp3 默认插槽]] 完全一致，只是多了个名字。

---

## 六、插槽名可以是什么？

```vue
<slot name="header" />
<slot name="main-content" />
<slot name="footer" />
```

- 任意字符串都行，推荐 kebab-case。
- 名字**区分大小写**：`#Header` ≠ `#header`。
- 不要用 `default` 以外的保留字？——`default` 本身就是保留名，表示默认插槽。

动态名字：

```vue
<template #[slotName]>…</template>
```

见 [[Exp6 动态插槽名]]。

---

## 七、具名插槽 + 条件渲染

父组件可以按需提供某个插槽：

```vue
<template #header v-if="showHeader">
  <h3>标题</h3>
</template>
```

`v-if` 为假时，这个插槽**根本不存在**；子组件若用 `$slots.header` 判断，就能连外壳一起隐藏。详见 [[Exp5 条件插槽]]。

---

## 八、具名插槽 vs 默认插槽

| 对比项 | 默认插槽 | 具名插槽 |
| --- | --- | --- |
| 数量 | 逻辑上只有一个 | 任意多个 |
| 子组件写法 | `<slot />` | `<slot name="x" />` |
| 父组件写法 | 直接内容 / `#default` | `<template #x>` |
| 适用 | 单一内容区 | 多区域布局（头/身/尾） |
| 典型组件 | 按钮、卡片正文 | 弹窗、布局容器、表格 |

> [!success] 选择建议
> 只有一个内容区 → 默认插槽；两个以上明确分区 → 具名插槽。**不要为了"看起来高级"硬拆具名插槽。**

---

## 九、常见组件结构示例

```vue
<!-- 布局组件 -->
<Layout>
  <template #header>导航栏</template>
  <template #sidebar>侧边栏</template>
  <template #default>主内容</template>
  <template #footer>页脚</template>
</Layout>
```

```vue
<!-- 弹窗组件 -->
<Modal>
  <template #header>提示</template>
  <p>确定要删除吗？</p>          <!-- 默认插槽 -->
  <template #footer>
    <button>取消</button>
    <button>确定</button>
  </template>
</Modal>
```

---

## 十、易错点清单

- [ ] 把 `#title` 写在普通 `<div>` 上 → 只能写在 `<template>` 或组件上
- [ ] 名字大小写不一致 → 配对失败，内容落到默认插槽或丢失
- [ ] 以为父组件顺序决定渲染顺序 → 顺序由子组件 `<slot>` 决定
- [ ] 忘记 `#` 后面的名字 → `#` 必须带参数
- [ ] 具名插槽内容没包 `<template>` → 会被当成默认插槽内容
- [ ] 子组件没有对应 `name` 的 `<slot>` → 父组件提供的内容无处可去，被丢弃

---

## 十一、自测

1. `<slot name="title" />` 在父组件里对应的两种写法是什么？
2. 父组件先写 `#footer` 再写 `#header`，渲染顺序会变吗？
3. 不写 `name` 的 `<slot>` 名字是什么？
4. 父组件提供的具名插槽，子组件没有对应 `<slot>`，会怎样？
5. `#default` 与直接写内容有什么区别？

> [!success]- 参考答案
> 1. `<template #title>` 或 `<template v-slot:title>`。
> 2. 不会，顺序由子组件模板中的 `<slot>` 位置决定。
> 3. `default`。
> 4. 内容不会被渲染（无处安放）。
> 5. 语义相同；`#default` 更显式，适合与其他具名插槽并列书写。

---

## 十二、同型练习：页面布局组件

> [!info] 题目
> 子组件 `PageLayout` 按以下顺序定义四个坑：
>
> ```vue
> <header><slot name="header" /></header>
> <aside><slot name="sidebar" /></aside>
> <main><slot /></main>
> <footer><slot name="footer" /></footer>
> ```
>
> 父组件**故意打乱顺序**填写：
>
> ```vue
> <PageLayout>
>   <template #footer>© 2026</template>
>   <p>主内容</p>
>   <template #sidebar>侧边栏</template>
>   <template #header v-if="showHeader">导航</template>
> </PageLayout>
> ```
>
> 其中 `showHeader = ref(false)`。
>
> 回答：
> 1. 初始渲染时页面从上到下的内容是什么？
> 2. 勾选后 `showHeader` 变为 `true`，顺序会变成什么？父组件的书写顺序有影响吗？
> 3. 初始状态下 `<header>` 元素本身还在吗？为什么？
> 4. 如果父组件在 `<PageLayout>` 里直接写一段 `<p>备注</p>`（不在任何 `<template #x>` 中），它会去哪个插槽？

> [!success]- 参考答案
> **子组件**
>
> ```vue
> <!-- PageLayout.vue -->
> <template>
>   <div class="layout">
>     <header><slot name="header" /></header>
>     <aside><slot name="sidebar" /></aside>
>     <main><slot /></main>
>     <footer><slot name="footer" /></footer>
>   </div>
> </template>
> ```
>
> **父组件**
>
> ```vue
> <!-- PageLayoutParent.vue -->
> <template>
>   <label><input type="checkbox" v-model="showHeader" /> 显示头部</label>
>   <PageLayout>
>     <template #footer>© 2026</template>
>     <p>主内容</p>
>     <template #sidebar>侧边栏</template>
>     <template #header v-if="showHeader">导航</template>
>   </PageLayout>
> </template>
>
> <script setup>
> import { ref } from 'vue'
> import PageLayout from './PageLayout.vue'
>
> const showHeader = ref(false)
> </script>
> ```
>
> **逐问回答**
> 1. 初始 `showHeader = false`，`#header` 插槽根本不存在，页面从上到下是：**空 header → 侧边栏 → 主内容 → © 2026**。
> 2. 勾选后变成：**导航 → 侧边栏 → 主内容 → © 2026**。父组件把 `#footer` 写在最前面也不会改变顺序，因为顺序由子组件里 `<slot>` 的排列决定。
> 3. 还在。子组件只写了 `<header><slot name="header" /></header>`，没有用 `$slots.header` 判断，所以外壳 `<header>` 始终渲染，只是里面为空。要连外壳一起去掉，需要 `v-if="$slots.header"`（见 [[Exp5 条件插槽]]）。
> 4. 会进入**默认插槽**（`<slot />`），和 `<p>主内容</p>` 一起渲染在 `<main>` 中。

---

## 十三、关联

- 上一篇：[[Exp3 默认插槽]]
- 下一篇：[[Exp5 条件插槽]]
- 总览：[[00 组件通信与插槽总览]]
