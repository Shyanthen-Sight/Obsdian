# Vue 中的 export（模块导出）

> [!abstract] 一句话
> `export` 是 **JavaScript 模块（ES Module）** 的语法：==每个 `.js` / `.vue` 文件默认是一个"密封的盒子"，里面的变量外面看不见；`export` 就是主动开一扇门，把想给别人用的东西交出去==，别的文件再用 `import` 把它接进来。
> Vue 项目里几乎每个文件都在 `export`：`main.js` 引 `App.vue`、页面引组件、`stores/` 导出 `useXxxStore`……本质都是这一件事。

---

## 一、为什么要"暴露"：从"全局变量"到"模块"

### 1.1 没有模块的年代：所有代码挤在一个作用域

早年页面靠一堆 `<script>` 拼接，所有代码共用**同一个全局作用域**，变量随手就能撞车：

```html
<script src="a.js"></script>  <!-- 里面写了 window.count = 1 -->
<script src="b.js"></script>  <!-- 里面又写了 window.count = 2 -->
<script>
  console.log(count)          // 到底是谁的 count？说不清
</script>
```

问题很直接：**谁都能改谁，改坏了还找不到是谁干的。**

### 1.2 ES Module 的默认规则：每个文件是一个独立作用域

现在提倡用 ES Module（ESM）——`<script type="module">`，或者任何走构建工具的项目（Vite / Webpack）默认就是它。它的第一条规则是：

> [!important] 默认是"私有"的
> ==一个文件（模块）里声明的变量、函数、常量，**默认只有它自己能看见**。==别的文件不管怎么引，都拿不到，除非你在源文件里**手动 `export`**。

```js
// utils.js
const secret = 123          // 没 export
function add(a, b) {         // 没 export
  return a + b
}
```

```js
// main.js
import { add } from './utils.js'   // ❌ 报错：utils.js 没导出 add
```

> [!success] 一句话理解
> ESM 的默认状态是 **"隔离/封闭"**，这是**好事**——它保证文件之间不会互相污染。
> 也正因为它默认封闭，**想共享就必须显式 `export`**。`export` 不是"多此一举"，而是那道必须自己开的门。

### 1.3 除了"能用"，暴露还有两个好处

| 好处 | 说明 |
| --- | --- |
| **明确对外接口** | 打开文件只扫一眼 `export`，就知道它对外提供了什么能力 |
| **保护内部实现** | 没 `export` 的就是私有细节，将来随便改名、删掉，都不会连累别人 |
| **避免命名冲突** | 两个文件都有 `format()` 也不会打架，只有 import 进来的那个才进当前作用域 |

---

## 二、两种暴露写法：`export default` 与 `export`

ESM 只有两种导出方式，初学只要记住这张表就够：

| | 具名导出（named） | 默认导出（default） |
| --- | --- | --- |
| 写法 | `export const x = 1` | `export default x` |
| 一个文件能有几个 | **多个** | **最多一个** |
| 导入写法 | `import { x } from './a.js'`（**要花括号**） | `import x from './a.js'`（**不用花括号**） |
| 导入的名字 | 必须和导出的名字**一致**（可用 `as` 改名） | **随便起** |
| 适合 | 工具函数、常量、组合式函数 | 组件、单个"主角"对象 |

### 2.1 具名导出：名字必须对得上

```js
// utils/math.js
export const PI = 3.14              // 具名导出常量
export function add(a, b) {         // 具名导出函数
  return a + b
}
```

```js
// main.js
import { PI, add } from './utils/math.js'   // ✅ 花括号 + 名字一致
console.log(add(1, 2))                       // 3

import { add as sum } from './utils/math.js' // ✅ 用 as 改名
```

> [!warning] 具名导出最容易犯的错
> 少写花括号、或名字敲错，都会直接报错：
> `SyntaxError: The requested module './utils/math.js' does not provide an export named 'add'`

### 2.2 默认导出：名字随便起

```js
// utils/user.js
const user = { name: '小明' }
export default user                 // 一个文件只能有一个 default
```

```js
// main.js
import u from './utils/user.js'      // ✅ 名字随便起，它是"这个文件的主角"
import user from './utils/user.js'   // ✅ 也行，同一个东西
import { user } from './utils/user.js' // ❌ 默认导出不能加花括号
```

> [!tip] 为什么默认导入"名字随便起"却还能对上？
> 因为**文件路径本身就是它的身份**：`./utils/user.js` 只有一个 default，`import 谁 from` 都指向它。所以团队里一般约定**默认导入用文件名**（`user.js` → `import user`），读代码时不迷惑。

### 2.3 两种可以同时存在

```js
// utils/index.js
export default function formatDate(d) { /* ... */ }  // 主角
export const LOCALE = 'zh-CN'                        // 顺便再导出一点常量
```

```js
import formatDate, { LOCALE } from './utils/index.js'  // 前面是 default，花括号里是具名
```

---

## 三、暴露 vs 不暴露：区别到底在哪

同一个文件里，写不写 `export` 差别只有一处，但后果差很多：

| | 不写 `export` | 写了 `export` |
| --- | --- | --- |
| 当前文件内部 | ✅ 随便用 | ✅ 随便用 |
| 别的文件 | ❌ 看不见（`undefined` 或直接报错） | ✅ `import` 后可用 |
| 定位 | 私有实现，想改就改 | 对外契约，改名字/删掉会连累调用方 |

```js
// a.js
const inner = 1              // 私有：别人拿不到
export const shared = 2      // 公开：别人能用
```

```js
// b.js
import { inner } from './a.js'    // ❌ 报错：没有导出 inner
import { shared } from './a.js'   // ✅ shared = 2
```

> [!note] 一句话
> **"不暴露" = 内部细节，"暴露" = 对外承诺。** 判断一个东西要不要 `export`，就问自己：**"这个文件以外的代码，需要用它吗？"** 需要才导出，不需要就留作私有。

---

## 四、暴露的东西在哪里可以用

### 4.1 位置：任何"别的模块"里

`export` 出来的东西，**只有通过 `import` 才能在别处用**。也就是说，"暴露在哪能用"= "谁去 `import` 它"。

- 能在 `.js` / `.ts` 文件里用
- 能在 `.vue` 文件的 `<script>` / `<script setup>` 里用
- 不能在**同一个文件**里"再 import 自己"（不需要，直接写名字就行）

### 4.2 引入路径怎么写

```js
import X from './X.js'          // 同目录/子目录：相对路径
import X from '../utils/X.js'   // 上一级
import X from '@/utils/X.js'    // @ 别名 = src/，Vue 工程里的惯例
```

> [!tip] 别写一长串 `../../..`
> Vue 工程一般配了 `@` 指向 `src/`（见 [[项目结构树解析]] 里 `vite.config.js` 与 `jsconfig.json` 的 `resolve.alias`）。用 `@/` 比数点号清楚得多。

### 4.3 Vue 项目里的"引用关系图"

如果把每个文件的 `export` / `import` 连起来，整个项目的骨架就长这样：

```text
main.js ──import App──────▶ App.vue ──import────▶ views/HomeView.vue
   │                                                   │
   │                                                   └─import─▶ components/*.vue
   │
   └──import useCounterStore──▶ stores/counter.js  ◀──import── 任何组件
```

```js
// main.js
import App from './App.vue'                    // App.vue 的"默认导出"
import { createApp } from 'vue'                // vue 包的"具名导出"

// stores/counter.js
export const useCounterStore = defineStore(...) // 具名导出，别处 import 用
```

对应到具体场景：

| 谁 export | 谁 import | 用在哪 |
| --- | --- | --- |
| `components/X.vue`（默认导出） | 页面 / 别的组件 | 当标签用 `<X />` |
| `stores/counter.js`（具名导出） | 需要共享状态的组件 | 调 `useCounterStore()` |
| `utils/format.js`（具名导出） | 任意逻辑代码 | 直接调函数 |
| `router/index.js`（默认导出） | `main.js` | `app.use(router)` |

### 4.4 动态导入：用的时候才引

除了写在顶部的静态 `import`，还能"用时才加载"：

```js
const mod = await import('./heavy.js')   // 返回一个"模块对象"
mod.doSomething()
```

Vue Router 的懒加载就是它：

```js
{ path: '/about', component: () => import('@/views/AboutView.vue') }  // 访问时才下载
```

---

## 五、Vue 里"暴露"这件事，其实有 4 个层面（关键辨析）

初学者最容易混的，就是把下面 4 件事当成一件事。它们都叫"暴露"，但**根本不是同一个层次**：

### 层面 1：JS 模块导出 —— 文件 ↔ 文件

就是前面讲的 `export` / `export default`。作用范围是**模块之间**。

### 层面 2：`.vue` 编译产物 —— 其实也是一个模块

`.vue` 文件经过编译，产出的就是**一个普通 JS 模块**，而且它的**默认导出**就是组件对象：

```js
// UserCard.vue 编译后（概念上）
import { defineComponent } from 'vue'
export default defineComponent({ /* ... */ })
```

> [!success] 所以这两句才成立
> ```js
> import UserCard from './UserCard.vue'   // 拿到的正是它的"默认导出"
> ```
> 参数名 `UserCard` 随便起也能跑，因为 `.vue` 是**默认导出**。详见 [[SFC]] 第六节的"编译产物"。

### 层面 3：`<script setup>` —— 不用你写 `export`

用 `<script setup>` 后，`export default` 由**编译器自动生成**，你不用写；而且**这里也不能写**：

```vue
<script setup>
export const foo = 1      // ❌ 报错：`<script setup>` cannot contain ES module exports
</script>
```

想在这个文件里做**模块级导出**，就另外开一个普通 `<script>` 块：

```vue
<script>
export const SHARED = 123   // ✅ 普通块可以导出，给别的文件 import
</script>

<script setup>
// 组件逻辑，不需要 export default
</script>
```

> [!note] 别把"模板能用"当成"导出"
> 在 `<script setup>` 里，顶层变量**不用 export 就能给模板用**——那是编译器的另一套机制（自动 `return`），和 `export` 无关。细节见 [[setup语法糖]]。

### 层面 4：`defineExpose` —— 组件实例 ↔ 组件实例

这是**另一个**"暴露"：`<script setup>` 默认把组件内部**对外封死**，父组件用 `ref` 拿到子组件后什么都读不到。要开放，得用 `defineExpose`：

```vue
<!-- 子组件 Child.vue -->
<script setup>
import { ref } from 'vue'
const count = ref(0)
function reset() { count.value = 0 }
defineExpose({ count, reset })   // ← 只有这两个能被父组件通过 ref 访问
</script>
```

### 4 个层面放一起对比

| | `export` / `export default` | `defineExpose` |
| --- | --- | --- |
| **谁在用** | 别的**文件** `import` | **父组件**通过模板 `ref` 拿到实例后 |
| **作用范围** | 模块 ↔ 模块 | 组件实例 ↔ 组件实例 |
| **写在哪** | 普通 `<script>` 顶层 | 只能在 `<script setup>` |
| **解决什么** | 文件之间共享代码 | 父组件调用子组件内部方法/读状态 |
| **典型** | `export const useStore = ...` | `defineExpose({ reset })` |

> [!quote] 记这一句就够
> **`export` 管"文件给文件"，`defineExpose` 管"子组件给父组件"。** 两者互不相干，别混。

---

## 六、一个完整的小例子

三个文件，串起前面所有概念：

```js
// src/utils/format.js —— 具名导出
export const CURRENCY = '¥'

export function formatPrice(n) {
  return CURRENCY + n.toFixed(2)
}
```

```vue
<!-- src/components/PriceTag.vue —— .vue 的默认导出（编译器自动生成） -->
<script setup>
import { formatPrice } from '@/utils/format.js'   // 引入具名导出

defineProps({ price: Number })
</script>

<template>
  <span>{{ formatPrice(price) }}</span>           <!-- 模板能直接用，靠的是自动暴露 -->
</template>

<style scoped>
span { color: #e74c3c; }
</style>
```

```vue
<!-- src/App.vue —— 引入组件 -->
<script setup>
import PriceTag from '@/components/PriceTag.vue'  // 拿到 .vue 的默认导出
</script>

<template>
  <PriceTag :price="99.5" />                      <!-- 渲染 ¥99.50 -->
</template>
```

> [!info] 从这三个文件看
> `format.js` 用**具名导出**（多个工具函数）→ `PriceTag.vue` 是**默认导出**（一个组件）→ `App.vue` 把两者 **import** 进来用。这就是 Vue 项目里 90% 的 `export` / `import` 的模样。

### 附：`index.js` 中转（barrel）—— 进阶但常见

把一堆导出集中到一个入口，引入时更干净：

```js
// src/components/index.js
export { default as PriceTag } from './PriceTag.vue'
export { default as UserCard } from './UserCard.vue'
```

```js
import { PriceTag, UserCard } from '@/components'   // 统一从一个口子引
```

---

## 七、TS 里还有个"只导出类型"

TypeScript 里，类型也能导出，但它是**编译期的东西**，运行时不存在：

```ts
// types/user.ts
export interface User { id: number; name: string }
export type ID = string | number
```

```ts
import type { User } from '@/types/user'   // 只引类型时建议加 type
```

> [!note] `<script setup>` 的例外
> 前面说 `<script setup>` 里不能用 `export`，**但 `export type` / `export interface` 除外**（它们编译后会被抹掉，不产生运行时代码）。更清楚的做法仍是放普通 `<script>` 块或单独的 `.ts` 文件。

---

## 八、常见坑

> [!question] `does not provide an export named 'xxx'` 报错？
> **导出/导入写法没配对。** 检查三处：
> ① 源文件是 `export`（具名）还是 `export default`；
> ② 导入端有没有写花括号（具名要，default 不要）；
> ③ 名字有没有敲错（具名必须一致，或 `as` 改名）。

> [!question] `import X from './X.js'` 拿到 `undefined`？
> 多半是你写成了 `export const X = ...`（具名），却用**默认导入**的写法去接。
> 要么改成 `import { X } from ...`，要么把源文件改成 `export default X`。

> [!question] 明明在文件里定义了变量，别的文件却用不了？
> 因为它**没被 `export`**。ESM 默认私有，必须显式导出后才可被 import。

> [!question] 在 `<script setup>` 里写 `export` 直接编译报错？
> 语法糖块里**不允许 ES 模块导出**（`export default` 由编译器管，`export const` 也不让写）。做模块级导出就**另开一个普通 `<script>` 块**，或放进单独的 `.js` / `.ts` 文件。

> [!question] 父组件 `ref` 拿到子组件却读不到任何东西？
> 那是 `defineExpose` 的问题，不是 `export`。`<script setup>` 组件默认对外封死，子组件要显式 `defineExpose({ ... })`。见 [[setup语法糖]]。

> [!question] `export default` 到底什么时候要写？
> **普通 `<script>` 写 Options API 组件时**必须写：`export default { ... }`（`.vue` 编译后需要一个默认导出当组件）。
> **`<script setup>` 时**不用写、也不能写——编译器替你生成。

> [!question] 两个文件互相 import 会不会死循环？
> 会（**循环依赖**）。表现常是某个值是 `undefined`、或执行顺序诡异。尽量让依赖**单向**（`A → B` 就不要 `B → A`）；确实要互相用，抽到一个第三方文件里。

---

## 相关笔记

- [[setup语法糖]] —— `<script setup>` 的自动暴露机制、编译宏与 `defineExpose`
- [[SFC]] —— `.vue` 编译成"带默认导出的普通模块"的全过程
- [[项目结构树解析]] —— `main.js` / `App.vue` 的 import 关系与 `@/` 别名配置
- [[组件注册]] —— 组件被 import 后怎么注册与使用
- [[Props 组件属性]] —— 组件间传值的另一半
- [[Events 自定义事件]] —— 子组件向父组件通信
- [[TypeScript vs JavaScript]] —— `export type` / 类型导出在 TS 里的位置

---

参考：MDN —— JavaScript modules / `export` / `import`；Vue 官方文档 —— `<script setup>`（ES module 导出限制）、SFC Spec、`defineExpose`；`eslint-plugin-vue` 规则 `vue/no-export-in-script-setup`
