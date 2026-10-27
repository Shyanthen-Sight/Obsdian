# 单文件组件（SFC）

> [!abstract] 一句话
> 单文件组件（Single-File Component，简称 **SFC**）就是 `.vue` 文件：==把一个组件的**视图（`<template>`）、逻辑（`<script setup>`）、样式（`<style scoped>`）三块装进同一个文件==，再用构建工具编译成一个普通的 JS 组件对象。它不是新语言，也不是浏览器能直接跑的东西，只是一种"更好写的组织方式"——本质仍是 Vue 组件。

---

## 一、为什么需要 SFC：从"散装组件"到"一个文件"

先看不使用 SFC 时，一个 Vue 组件能怎么写。下面三种都是"合法"的旧写法。

### 1.1 字符串模板（`template` 选项）

把模板写成一大坨字符串，塞进 JS 里：

```js
// 传统写法：模板只是一段字符串，编辑器帮不上忙
const MyButton = {
  props: ['label'],
  template: `
    <button class="btn" @click="onClick">
      {{ label }}
    </button>
  `,                                   // ← 没有高亮、没有补全、没有格式检查
  methods: {
    onClick() { console.log('clicked') }
  }
}
```

### 1.2 页面里的 `<script type="text/x-template">`

模板搬到 HTML 里，靠 id 关联——同样是"模板和逻辑分离在两个地方"：

```html
<script type="text/x-template" id="my-button">
  <button class="btn">{{ label }}</button>
</script>
<script>
  const MyButton = { template: '#my-button', props: ['label'] }
</script>
```

### 1.3 render 函数（`h()`）

不用模板，手写虚拟 DOM：

```js
import { h } from 'vue'

// 完全没有模板，返回什么全靠脑补
const MyButton = {
  props: ['label'],
  render() {
    return h('button', { class: 'btn' }, this.label)
  }
}
```

### 1.4 问题在哪

| 关注点 | 字符串模板 / render 函数 | 后果 |
| --- | --- | --- |
| 视图 | 混在 JS 字符串或另一个 HTML 文件里 | 没有语法高亮、没有格式化 |
| 逻辑 | 在 JS 里 | 正常 |
| 样式 | 还得另开一个 `.css` 文件，或写内联 `style` | 文件四处分散，"一个组件"要翻三个地方 |
| 复用 | 想整包复制组件？要同时拷 JS + CSS + 模板 | 极易漏文件 |

> [!warning] 核心痛点
> 这三个东西本质上属于**同一个组件**，却被拆散在不同文件、甚至不同语言里。==SFC 解决的正是"关注点被拆散"==，而不是"缺少某个功能"。

### 1.5 SFC 写法：一个文件装下三块

```vue
<!-- MyButton.vue -->
<script setup>
defineProps({ label: String })          // 逻辑
</script>

<template>
  <button class="btn" @click="onClick">{{ label }}</button>  <!-- 视图 -->
</template>

<style scoped>
.btn { padding: 4px 12px; }             /* 样式，且只作用于本组件 */
</style>
```

> [!success] 一句话理解
> 三种旧写法**都能用**，SFC 不比它们"多一个功能"，只是把**视图 / 逻辑 / 样式**按"一个组件一份文件"重新归拢，顺便换来编辑器高亮、类型提示、样式隔离等一整套工程能力。

---

## 二、三块结构：`<script setup>` / `<template>` / `<style scoped>`

一个 `.vue` 文件由三种**顶层块**组成，块名就是标签名：

```text
MyComponent.vue
├── <script setup>   ← 逻辑块：变量、函数、import（可选）
├── <template>       ← 视图块：HTML 结构（通常必需）
└── <style scoped>   ← 样式块：CSS（可选，可写多个）
```

| 块 | 职责 | 是否必须 | 数量 | 备注 |
| --- | --- | --- | --- | --- |
| `<script setup>` | 组件逻辑、props、事件、状态 | ❌ 可选（纯静态组件可不要） | 最多 1 个 | 用 `export default {}` 的普通 `<script>` 也算逻辑块 |
| `<template>` | 组件的 DOM 结构 | ✅ 基本必需 | 最多 1 个 | 除非你改用 render 函数，那就不写模板 |
| `<style>` | 组件样式 | ❌ 可选 | 可多个 | 可混用 `scoped` / 非 `scoped` / `module` |

### 2.1 三种写法都合法

```vue
<!-- ① 只有模板：纯静态展示组件，逻辑和样式都可省 -->
<template>
  <p>我只是一段静态 HTML</p>
</template>
```

```vue
<!-- ② 逻辑 + 模板（+ 样式）：最常见的组合，见第一节 1.5 -->
<script setup>
import { ref } from 'vue'
const count = ref(0)
</script>

<template>
  <button @click="count++">{{ count }}</button>
</template>
```

> [!info] 块的顺序无所谓
> 三块的**书写顺序不影响功能**（`<template>` 放最前、`<script setup>` 放最后都行）。但社区惯例是 `script → template → style`，读起来最顺。

### 2.2 执行顺序（什么时候跑什么）

这点常被忽略，其实分两个阶段：

| 阶段 | 发生了什么 |
| --- | --- |
| **编译期**（构建时） | `<template>` 被编译成 render 函数；`<style>` 被提取成 CSS；`<script>` 被转译成标准 JS |
| **运行时**（浏览器里） | `<script>` 普通块 → `<script setup>` 块 → 组件实例化时执行 setup → 渲染 render 函数 → 应用样式 |

```text
编译期 ──► 运行时
            │
            ├─ 普通 <script>    （模块级代码，在组件被引入时就执行一次）
            ├─ <script setup>   （每次实例化组件都执行一次）
            └─ render 函数      （响应式数据变化时重跑）
```

> [!note] `<style>` 在哪执行？
> 样式在**编译期**就被抽走了，运行时和组件的 JS 逻辑基本无关。开发环境下由 JS 动态注入 `<style>` 标签（方便 HMR 热更新）；生产构建时则合并成独立的 `.css` 文件，由页面 `<link>` 加载。

---

## 三、为什么 SFC 需要构建工具

这是初学者最容易困惑的一点。

> [!danger] 浏览器根本不认识 `.vue`
> `.vue` **不是一个"浏览器能运行的文件格式"**。浏览器只认 HTML、CSS、JavaScript 三种。你把 `.vue` 丢给浏览器，它只会把它当**纯文本**下载下来，什么都不会发生。

### 3.1 编译链路

```text
MyButton.vue                 （给人读的源文件）
      │
      │   @vitejs/plugin-vue + @vue/compiler-sfc
      ▼
MyButton.js  +  MyButton.css （浏览器能跑的产物）
      │
      ▼
   浏览器执行
```

也就是说，必须有一个**插件/编译器**把 `.vue` 翻译成 JS 组件对象和 CSS，浏览器才跑得起来。在 Vite 项目里，这个角色由 `@vitejs/plugin-vue` 担任：

```js
// vite.config.js
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'   // ★ 让 Vite 认识 .vue 文件

export default defineConfig({
  plugins: [vue()]                     // ← 少了这一行，import '*.vue' 直接报错
})
```

> [!tip] 回忆一下工程结构
> `package.json` 的 `devDependencies` 里有 `@vitejs/plugin-vue`，`vite.config.js` 里 `plugins: [vue()]`——这两处正是"`.vue` 能被编译"的全部开关。详见 [[项目结构树解析]]。

### 3.2 那"无构建"能不能用 Vue？

能，但就不能用 SFC 了：

| 方案 | 能否用 `.vue` | 说明 |
| --- | --- | --- |
| Vite / Webpack 工程 | ✅ | 插件编译，日常开发的标准姿势 |
| 纯 CDN 引入 `vue.global.js` | ❌ | 只能用字符串模板 / render 函数 |
| CDN + `vue.esm-browser.js` | ⚠️ 勉强 | 该版本带运行时编译器，但模板仍需写成字符串，用不了 SFC 单文件 |

> [!question] 那我用 CDN 时那些 `<template>` 为什么能跑？
> 那是**字符串模板 / DOM 内模板**（运行时的 `vue.esm-browser.js` 自带模板编译器），和 SFC 完全是两回事。SFC 的 `<template>` 块是在**构建期**就编译掉的，浏览器里根本看不到它。

---

## 四、`<style scoped>` 原理与样式隔离

### 4.1 不加 scoped 会怎样

默认 `<style>` 是**全局样式**，会污染整站。若 `A.vue` 写了 `.title { color: red }`，那么 `B.vue` 里任何 `class="title"` 的元素都会被意外染色：

```vue
<!-- A.vue：这条规则会跑到所有组件里去 -->
<style>
.title { color: red }
</style>
```

### 4.2 `scoped` 做了什么：加 `data-v-xxx` 属性

加上 `scoped` 后，编译器给**本组件模板里的每个元素**都加一个唯一属性（形如 `data-v-7ba5bd90`），同时把选择器改写成"带属性"的选择器：

```vue
<template>
  <div class="box">
    <p>文字</p>
  </div>
</template>

<style scoped>
.box { color: red }
</style>
```

编译后大致变成：

```html
<!-- DOM 结构 -->
<div class="box" data-v-7ba5bd90>
  <p data-v-7ba5bd90>文字</p>
</div>
```

```css
/* CSS 选择器 */
.box[data-v-7ba5bd90] { color: red }
```

```text
选择器 ──加属性──▶  只命中带 data-v-7ba5bd90 的元素
                    即"只属于这个组件"的元素
```

> [!success] 一句话原理
> scoped 不是真的"作用域隔离"，而是==给元素和选择器同时打上同一串唯一属性，让选择器只可能命中本组件的元素==。它靠的是 CSS 的属性选择器，不需要 Shadow DOM。

### 4.3 子组件根元素：一个必须知道的"例外"

父组件写 `<Child />`，子组件的**根元素**会同时带上父组件的 `data-v-父` 和子组件自己的 `data-v-子`：

```text
父组件模板                实际渲染出的 DOM
<Child />   ────▶   <div class="child-root"
                           data-v-父组件  ← 为了能被父组件样式命中
                           data-v-子组件  ← 自己的
                         >
                       子组件内部其他元素只带 data-v-子组件
```

后果有两个：

- 父组件的 `scoped` 样式**能**作用到子组件的根元素（这是设计如此）；
- 但**作用不到子组件内部的其它元素**——这就是"scoped 对子组件无效"的真相。

### 4.4 `:deep()` 深度选择器：穿透到子组件内部

想让父组件的样式影响子组件内部，用 `:deep()`：

```vue
<!-- 父组件 -->
<template>
  <div class="wrapper">
    <Child />
  </div>
</template>

<style scoped>
/* 编译成 .wrapper[data-v-父] .child-inner  —— 后半段不再加属性 */
.wrapper :deep(.child-inner) {
  color: blue;
}
</style>
```

> [!warning] `:deep()` 放对位置
> 正确写法是 `.wrapper :deep(.child-inner)`（`:deep()` 前要有父级选择器）。
> 写成 `:deep(.child-inner)` 会退化成全局样式，失去本意。
> 旧写法 `::v-deep`、`>>>`、`/deep/` 已废弃，Vue 3 统一用 `:deep()`。

还有两个同族伪类：

| 伪类 | 作用 |
| --- | --- |
| `:deep(sel)` | 穿透到**子组件内部**的元素 |
| `:slotted(sel)` | 作用于**插槽内容**（父组件传进来的 DOM），如 `:slotted(.slot-item) { ... }` |
| `:global(sel)` | 强制该规则**全局生效**，不加属性，如 `:global(.no-scope) { margin: 0 }` |

### 4.5 `<style module>`：CSS Modules 另一种思路

`scoped` 是"加属性"，`module` 则是"改类名"——把类名哈希化，通过 `$style` 对象引用：

```vue
<template>
  <p :class="$style.red">我是 CSS Modules</p>
</template>

<style module>
.red { color: red }        /* 编译后类名变成 ._red_1a2b3c 之类的哈希 */
</style>
```

也可以自定义注入的变量名：`<style module="classes">`，模板里就写 `:class="classes.red"`。

> [!note] `scoped` vs `module` 怎么选
> 日常用 **`scoped`** 就够了，写法直观、和普通 CSS 一致。**`module`** 更适合既要隔离、又想用 JS 动态拼接类名，或团队本来就在用 CSS Modules 的场景。两者**可以同时存在**于一个文件（分属不同 `<style>` 块）。

### 4.6 多个 `<style>` 块与预处理器

一个文件里可以写多个样式块，各自独立配置：

```vue
<!-- 全局样式：影响整站 -->
<style>
body { margin: 0 }
</style>

<!-- 局部样式：用 SCSS，需要安装 sass -->
<style scoped lang="scss">
$primary: #42b883;

.btn {
  color: $primary;
  &:hover { color: darken($primary, 10%); }
}
</style>

<!-- CSS Modules -->
<style module>
.red { color: red }
</style>
```

---

## 五、`lang` 属性：换一门语言来写这一块

每个块都可以用 `lang` 指定它内部用的是什么语言，SFC 负责把它转成浏览器认识的东西。

| 块 | `lang` 值 | 含义 | 需要额外安装 |
| --- | --- | --- | --- |
| `<script>` | `ts` | 用 TypeScript 写逻辑 | TypeScript（Vite 内置转译；类型检查靠 `vue-tsc`） |
| `<template>` | `pug` | 用 Pug 模板语法 | `pug` |
| `<style>` | `scss` / `sass` | 用 SCSS 语法 | `sass` |
| `<style>` | `less` | 用 Less | `less` |
| `<style>` | `stylus` | 用 Stylus | `stylus` |
| `<script>` | `tsx` / `jsx` | 用 JSX 写渲染逻辑 | 需额外配置（见第七节） |

```vue
<script setup lang="ts">
import { ref } from 'vue'

interface User { id: number; name: string }
const user = ref<User | null>(null)
</script>

<template>
  <p>{{ user?.name }}</p>
</template>

<style scoped lang="scss">
p { color: #333; }
</style>
```

> [!warning] `lang` 只声明"语法"，依赖得自己装
> `lang="scss"` 只是告诉编译器"这里按 SCSS 解析"，==并不自带 SCSS 编译器==。少了 `sass` 这个包，构建会直接报错（`Preprocessor dependency "sass" not found`）。`lang="ts"` 同理，依赖工程里已配好 TypeScript——可参考 [[安装与配置]]、[[tsconfig.json]]。

---

## 六、SFC 是怎么被编译的

> [!quote] 核心认知
> `.vue` 只是一个**打包前的中间格式**。编译完成后，它就消失了——留下的只是一个普通的 JS 模块（`export default { ... }`）加一份 CSS。Vue 运行时看到的组件对象，和用 `defineComponent({})` 手写的**没有任何区别**。

### 6.1 整体流程

```text
Hello.vue
   │
   │ ① parse：把文件拆成 SFCDescriptor
   │    { template, script, scriptSetup, styles, customBlocks }
   ▼
┌──────────────────────────────────────────────┐
│ <template>  → @vue/compiler-dom → render 函数 │
│ <script>    → esbuild / TS 转译  → 组件选项     │
│ <style>     → PostCSS + scoped 改写 → CSS      │
└──────────────────────────────────────────────┘
   │
   │ ② 拼装成一个 JS 模块
   ▼
Hello.js  （export default 组件对象）   +   Hello.css
```

### 6.2 一个简化的"编译产物"示意

源文件：

```vue
<script setup>
import { ref } from 'vue'
const count = ref(0)
</script>

<template>
  <button @click="count++">{{ count }}</button>
</template>
```

编译后（**大幅简化的示意，真实产物使用 `_createElementVNode` 等内部渲染 API**）：

```js
// 概念上等价于下面这样
import { defineComponent, ref } from 'vue'

export default defineComponent({
  setup() {
    const count = ref(0)             // ① <script setup> 的逻辑
    return { count }                 // ② 自动 return，模板才能用
  },
  render() {
    // ③ <template> 编译成的渲染函数
    return h('button', { onClick: () => this.count++ }, this.count)
  }
})
```

> [!info] 三个关键结论
> 1. `<script setup>` 里的"自动暴露"是**编译器补的 `return`**（详见 [[setup语法糖]]）。
> 2. `<template>` 在构建期就变成了 render 函数，运行时不解析 HTML 字符串。
> 3. 最终产物是**普通 JS 组件对象**，所以 `import` 来的 `.vue` 和 `defineComponent()` 写的组件可以随意混用、嵌套。

### 6.3 编译发生在什么时候

| 环境 | 时机 | 谁来做 |
| --- | --- | --- |
| 开发（`npm run dev`） | 请求到某个 `.vue` 时才按需编译 | Vite 开发服务器 + `@vitejs/plugin-vue` |
| 生产（`npm run build`） | 打包时一次性全部编译 | Vite（Rollup）+ 同一插件 |

> [!tip] 这也是 HMR 快的原因
> Vite 只重编译**改动的那一个 `.vue`** 模块（及其样式），不重新打包整站。所以改一个组件样式，页面几乎是瞬间更新——原理见 [[项目结构树解析]] 里的 `vite.config.js` 一节。

---

## 七、常见坑与常见问题

> [!question] 为什么不能直接在浏览器里跑 `.vue`？
> 因为 `.vue` 不是浏览器认识的格式。浏览器只认 HTML / CSS / JS，`.vue` 必须经 `@vitejs/plugin-vue` 编译成 JS + CSS 才能执行。想"无构建"用 Vue，只能用字符串模板或 render 函数，写不了 SFC。

> [!question] 为什么 `import Foo from './Foo.vue'` 报错 "Failed to parse source"？
> 通常是 `vite.config.js` 里**漏了 `plugins: [vue()]`**，Vite 把 `.vue` 当普通文本处理了。加上插件即可。

> [!question] `scoped` 样式为什么改不动子组件内部的元素？却又会"漏"到子组件根元素上？
> 子组件**内部**的元素带的是它自己的 `data-v-xxx`，父组件选择器命中不了，要用 `:deep(选择器)` 穿透。而**根元素**会同时带父、子两个 `data-v`，所以父组件能直接命中它——这是有意设计，方便父组件调整子组件的外层布局（如 `margin`）。想严格控制见 [[属性继承]]。

> [!question] `.jsx` / `.tsx` 写的组件也算 SFC 吗？
> 严格说不算，它们是**另一种组件书写格式**。Vue 官方支持 `.vue` 和 `.jsx`/`.tsx` 两种，但 `.jsx`/`.tsx` 需要**额外配置**（`@vitejs/plugin-vue-jsx`），不像 `.vue` 那样开箱即用。日常优先用 `.vue`。

> [!question] `<script setup>` 和普通 `<script>` 能同时写吗？
> 可以，但最多各一个。普通块用于模块级代码（如 `export const xxx`）或 `defineOptions` 覆盖不了的场景，**先于** `<script setup>` 执行。细节见 [[setup语法糖]]。

> [!question] `<template>` 里能直接写多个根元素吗？
> 可以。Vue 3 支持**多根节点（Fragment）**，不再要求唯一根元素。但多根组件无法被父组件自动继承 `class`/属性（因为不知道往哪个根上挂），这时需要显式指定——见 [[属性继承]]。

---

## 相关笔记

- [[setup语法糖]] —— `.vue` 里 `<script setup>` 那块的完整机制与编译宏
- [[项目结构树解析]] —— `vite.config.js` 的 `plugins: [vue()]` 与整棵树的关系
- [[组件注册]] —— `.vue` 编译成组件对象后，怎么在别处注册与使用
- [[Props 组件属性]] —— `<script setup>` 中 `defineProps` 声明属性
- [[Events 自定义事件]] —— 组件间通信的另一半
- [[v-model]] —— 双向绑定在 SFC 中的写法
- [[属性继承]] —— 多根节点 / `inheritAttrs` 与 `scoped` 的配合
- [[安装与配置]] —— `lang="ts"` / `lang="scss"` 所需的依赖与环境
- [[tsconfig.json]] —— `lang="ts"` 时类型从哪来、路径别名怎么配
- [[TypeScript vs JavaScript]] —— `.vue` 中 TS 与 JS 的关系
- [[TS 与 JS 的互操作性]] —— 混用两种语言时的边界与规则

---

参考：Vue 官方文档 —— Single-File Components / `<style>` Features（Scoped CSS、CSS Modules）/ SFC Spec；`@vue/compiler-sfc`、`@vitejs/plugin-vue` 文档；Vite 官方文档 —— Plugins / Hot Module Replacement
