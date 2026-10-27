# Exp3 默认插槽

> [!abstract] 一句话
> 子组件在模板里写一个 `<slot></slot>` 当"占位符"，父组件把**一段模板结构**写在子组件标签内部，这段结构就会替换掉 `<slot>`。==`<slot>` 标签里的内容叫"后备内容"（fallback），父组件不给内容时才显示。==

📁 源码：`Exp3/Exp3_DefualtSlot_Parent.vue`、`Exp3/Exp3_DefualtSlot_Child.vue`

---

## 一、完整源码

### 1.1 子组件（挖坑）

```vue
<!-- Exp3_DefualtSlot_Child.vue -->
<template>
  <div>
    <slot>
      <h3>阿尔泰山</h3>
    </slot>
  </div>
</template>

<script setup>
// 子组件逻辑为空，仅演示默认插槽的后备内容
</script>
```

### 1.2 父组件（填坑）

```vue
<!-- Exp3_DefualtSlot_Parent.vue -->
<template>
  <!-- 第一个子组件：不传内容，显示默认的"阿尔泰山" -->
  <Exp3_DefualtSlot_Child />

  <!-- 第二个子组件：传入 img，覆盖默认内容 -->
  <Exp3_DefualtSlot_Child>
    <img :src="loadingOver" style="width: 100px; height: 100px" />
  </Exp3_DefualtSlot_Child>
</template>

<script setup>
import { ref } from 'vue'
import Exp3_DefualtSlot_Child from './Exp3_DefualtSlot_Child.vue'
import loadingOverUrl from '@/assets/img/loadingOver.jpg'

// 保存图片地址（组合式 API 中用 ref 声明响应式数据）
const loadingOver = ref(loadingOverUrl)
</script>
```

### 1.3 渲染结果

```text
第一个 <Exp3_DefualtSlot_Child />
  └── <div><h3>阿尔泰山</h3></div>          ← 后备内容

第二个 <Exp3_DefualtSlot_Child>
  └── <div><img src="..."></div>            ← 父组件内容替换了 <slot>
```

> [!warning] 示例缺一张图片
> 源码引用了 `@/assets/img/loadingOver.jpg`，但源项目 `src/assets/` 下只有 `base.css`、`logo.svg`、`main.css`，**没有 `img/loadingOver.jpg`**。直接运行会报模块找不到。
> 复现时请自行在 `src/assets/img/` 放入一张 `loadingOver.jpg`，或把 import 换成任意已有图片。

---

## 二、插槽的本质：内容分发

```text
父组件模板
┌──────────────────────────────┐
│ <Child>                      │
│   <img src="...">            │  ← 这段"结构"被抽取出来
│ </Child>                     │
└──────────────────────────────┘
                │
                │  作为插槽内容传入
                ▼
子组件模板
┌──────────────────────────────┐
│ <div>                        │
│   <slot>                     │  ← 原位置插入父组件的内容
│     <h3>阿尔泰山</h3>         │  ← 没有内容时，显示后备内容
│   </slot>                    │
│ </div>                       │
└──────────────────────────────┘
```

> [!important] 插槽传的是"模板"，不是"字符串"
> 父组件写的是 `<img>`、`<p>`、`<MyButton>` 这样的**真实模板节点**，不是 HTML 字符串。所以插槽内容可以包含组件、指令、事件、`v-if`/`v-for`。

---

## 三、后备内容（fallback）

```vue
<slot>
  <h3>阿尔泰山</h3>
</slot>
```

| 父组件写法 | 子组件渲染 |
| --- | --- |
| `<Child />` | `<h3>阿尔泰山</h3>` |
| `<Child></Child>` | `<h3>阿尔泰山</h3>` |
| `<Child><img /></Child>` | `<img />` |
| `<Child><span></span></Child>` | `<span></span>`（空元素也算"提供了内容"） |

> [!warning] "提供了内容"≠"有可见内容"
> 只要父组件给了节点（哪怕是个空 `<span>`），后备内容就**不会**出现。这正是 [[Exp6 动态插槽名]] 要过滤"没有内容"的 section 的原因。

---

## 四、插槽内容的作用域（超级重点）

父组件里：

```vue
<Exp3_DefualtSlot_Child>
  <img :src="loadingOver" />
</Exp3_DefualtSlot_Child>
```

这里的 `loadingOver` 来自**父组件**的 `setup`，不是子组件的。

> [!important] 编译作用域规则
> **插槽内容在父组件的作用域里编译。**
> - 父模板中的变量 → 父组件的数据
> - 子组件模板中的变量 → 子组件的数据
> - 插槽内容虽然"渲染在子组件内部"，但**数据来源仍是父组件**
>
> 想在插槽内容里使用子组件的数据？必须用**作用域插槽**把数据显式传出来，见 [[Exp7 作用域插槽]]。

可以用一句话记：

```text
插槽内容 = 父组件写的模板（父的数据）
slot 位置 = 子组件决定放哪（子的布局）
```

---

## 五、默认插槽的语法变体

```vue
<!-- 1. 直接写内容（最常见） -->
<Child>
  <p>内容</p>
</Child>

<!-- 2. 显式 default 模板 -->
<Child>
  <template #default>
    <p>内容</p>
  </template>
</Child>

<!-- 3. v-slot 全称 -->
<Child>
  <template v-slot:default>
    <p>内容</p>
  </template>
</Child>

<!-- 4. 作用域插槽时直接写在组件上 -->
<Child v-slot="{ user }">
  <p>{{ user.name }}</p>
</Child>
```

> [!tip] `#` 是 `v-slot:` 的简写
> `#default` = `v-slot:default`。默认插槽可以省略 `default`，直接写 `<Child>内容</Child>`。

---

## 六、多个 `<slot>` 会怎样？

```vue
<!-- 子组件 -->
<div>
  <slot />
  <slot />
</div>
```

父组件的内容会**同时出现在两个位置**（同一份插槽内容被渲染两次）。这通常不是想要的，但语法合法。

> [!warning] 默认插槽只有一个
> 所有没有 `name` 的插槽都指向同一个"默认插槽"。多个默认 `<slot>` 不是"多个坑"，而是"同一个坑挖了两次"。
> 需要多个不同位置 → 用具名插槽（[[Exp4 具名插槽]]）。

---

## 七、插槽 vs props：怎么选？

| 场景 | 选择 | 原因 |
| --- | --- | --- |
| 传一个字符串/数字/对象 | `props` | 数据用 props |
| 传一段 DOM/组件结构 | 插槽 | 结构用插槽 |
| 子组件只负责布局，内容由父决定 | 插槽 | 典型：卡片、弹窗、布局容器 |
| 内容需要子组件的数据 | 作用域插槽 | 见 Exp7 |
| 内容只是纯文本 | props 或默认插槽都行 | 纯文本用 props 更简单 |

> [!success] 判断口诀
> **"传值用 props，传结构用插槽。"** 当父组件想决定"长什么样"，而不只是"显示什么字"时，就该考虑插槽。

---

## 八、常见组件中的默认插槽

```vue
<!-- 按钮：文字由使用者决定 -->
<MyButton>提交</MyButton>

<!-- 卡片：卡片内部内容由使用者决定 -->
<MyCard>
  <h3>标题</h3>
  <p>正文</p>
</MyCard>

<!-- 弹窗：弹窗主体由使用者决定 -->
<MyDialog>确定要删除吗？</MyDialog>
```

这些组件的共同点：**外壳由子组件定，内容由父组件定**。这就是插槽最典型的价值。

---

## 九、易错点清单

- [ ] 以为插槽内容能访问子组件变量 → 只能访问父组件变量
- [ ] 父组件给了空元素，却疑惑后备内容没出现 → 空元素也算"提供了"
- [ ] 在子组件里写多个无名 `<slot>` 想放多个位置 → 应该用具名插槽
- [ ] 把插槽当字符串拼接 → 插槽是模板节点
- [ ] 在 `<template>` 外写 `v-slot` → 报错，`v-slot` 只能用于组件或 `<template>`
- [ ] 忘记放图片资源导致编译报错 → 见本文开头的警告

---

## 十、自测

1. `<Child />` 与 `<Child></Child>` 在后备内容上表现一样吗？
2. 父组件插槽内容里的 `loadingOver` 来自哪个组件？
3. 子组件写两个 `<slot />`，父组件传一段 `<p>`，会渲染几次？
4. 什么时候该用插槽而不是 props？
5. 后备内容在什么情况下显示？

> [!success]- 参考答案
> 1. 一样，都显示后备内容。
> 2. 父组件。
> 3. 两次（同一份内容被渲染到两个位置）。
> 4. 需要传"结构/模板"而非纯数据时。
> 5. 父组件没有为该插槽提供任何内容时。

---

## 十一、同型练习：提示框默认插槽

> [!info] 题目
> 实现一个 `TipBox` 提示框组件，模板结构为：
>
> ```vue
> <div class="tip">
>   <slot>
>     <p>暂无提示</p>
>   </slot>
> </div>
> ```
>
> 父组件按下面三种方式使用：
>
> ```vue
> <TipBox />
> <TipBox><p>{{ message }}</p></TipBox>
> <TipBox><button @click="count++">点击 {{ count }}</button></TipBox>
> ```
>
> 其中 `message = ref('操作成功')`、`count = ref(0)` 都定义在父组件。
>
> 回答：
> 1. 三个实例分别渲染什么？
> 2. `message` 和 `count` 来自哪个组件？点击按钮后 `count` 会变吗？
> 3. 如果第二个实例写成 `<TipBox><span></span></TipBox>`，后备内容会显示吗？
> 4. 如果子组件里写两个 `<slot />`，父组件传一段内容，会渲染几次？

> [!success]- 参考答案
> **子组件**
>
> ```vue
> <!-- TipBox.vue -->
> <template>
>   <div class="tip">
>     <slot>
>       <p>暂无提示</p>
>     </slot>
>   </div>
> </template>
> ```
>
> **父组件**
>
> ```vue
> <!-- TipBoxParent.vue -->
> <template>
>   <TipBox />
>   <TipBox><p>{{ message }}</p></TipBox>
>   <TipBox><button @click="count++">点击 {{ count }}</button></TipBox>
> </template>
>
> <script setup>
> import { ref } from 'vue'
> import TipBox from './TipBox.vue'
>
> const message = ref('操作成功')
> const count = ref(0)
> </script>
> ```
>
> **渲染结果**
>
> ```text
> ① 暂无提示                 ← 父组件没给内容，显示后备内容
> ② 操作成功                 ← 父组件内容替换了 <slot>
> ③ [点击 0]                 ← 按钮；点击后变成 点击 1、2、3…
> ```
>
> **逐问回答**
> 1. 见上面的运行结果。
> 2. 都来自**父组件**。插槽内容在父组件的作用域里编译，即使被渲染到子组件内部，`message`、`count` 和 `@click` 仍然指向父组件的数据与方法，所以 `count++` 能正常触发父组件更新。
> 3. 不会。`<span></span>` 虽然不可见，但它是一个真实节点，代表"父组件提供了内容"，后备内容因此被替换。
> 4. 两次。两个无名 `<slot>` 都指向同一个默认插槽，同一份内容会在两个位置各渲染一次。

---

## 十二、关联

- 上一篇：[[Exp2 子传父 emit]]
- 下一篇：[[Exp4 具名插槽]]
- 总览：[[00 组件通信与插槽总览]]
