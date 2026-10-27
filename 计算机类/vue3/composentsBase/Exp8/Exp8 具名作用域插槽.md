# Exp8 具名作用域插槽

> [!abstract] 一句话
> 把 [[Exp4 具名插槽]] 的"多个坑"和 [[Exp7 作用域插槽]] 的"子传数据"合起来：子组件给**每个具名插槽分别传各自的数据**，父组件用 `#名字="{ 字段 }"` 分别接收。==一个组件、多个区域、每个区域一套数据——这是组件库中最常见的插槽形态。==

📁 源码：`Exp8/Exp8_NamedSlotPropsDataToParent_Parent.vue`、`Exp8/Exp8_NamedSlotPropsDataToParent_Child.vue`

---

## 一、完整源码

### 1.1 子组件

```vue
<!-- Exp8_NamedSlotPropsDataToParent_Child.vue -->
<template>
  <slot name="user" :user="user" />
  <slot name="info" :info="info" />
</template>

<script setup>
import { ref } from 'vue'

const user = ref({ name: '张三', age: 25 })
const info = ref({ city: '北京', job: '工程师' })
</script>
```

### 1.2 父组件

```vue
<!-- Exp8_NamedSlotPropsDataToParent_Parent.vue -->
<template>
  <Child>
    <template #user="{ user }">
      <p>姓名：{{ user.name }}，年龄：{{ user.age }}</p>
    </template>

    <template #info="{ info }">
      <p>城市：{{ info.city }}，职业：{{ info.job }}</p>
    </template>
  </Child>
</template>

<script setup>
import Child from './Exp8_NamedSlotPropsDataToParent_Child.vue'
</script>
```

### 1.3 渲染结果

```text
姓名：张三，年龄：25
城市：北京，职业：工程师
```

---

## 二、结构与数据流

```text
子组件
  user = { name:'张三', age:25 }
  info = { city:'北京', job:'工程师' }
        │
        ├── <slot name="user" :user="user" />
        │        │
        │        ▼
        │   父组件 <template #user="{ user }">  → 用 user 渲染
        │
        └── <slot name="info" :info="info" />
                 │
                 ▼
            父组件 <template #info="{ info }">  → 用 info 渲染
```

> [!important] 两套数据互不干扰
> `#user` 只拿到 `{ user }`，`#info` 只拿到 `{ info }`。每个插槽的 props 是**独立**的，不会互相混入。
> 父组件可以只解构自己需要的字段，剩下的忽略。

---

## 三、语法拆解

### 3.1 子组件：名字 + 数据

```vue
<slot name="user" :user="user" />
```

| 部分 | 作用 |
| --- | --- |
| `name="user"` | 插槽名，供父组件配对 |
| `:user="user"` | 插槽 prop，把子组件数据递给父组件 |

### 3.2 父组件：名字 + 解构

```vue
<template #user="{ user }">
  {{ user.name }}
</template>
```

| 部分 | 作用 |
| --- | --- |
| `#user` | 匹配 `name="user"` 的插槽 |
| `="{ user }"` | 解构插槽 props 中的 `user` 字段 |

> [!tip] 全称与简写
> ```vue
> <template v-slot:user="{ user }">   <!-- 全称 -->
> <template #user="{ user }">          <!-- 简写 -->
> ```
> 两者完全等价。`#` 后必须跟插槽名。

---

## 四、与 Exp7 的对比

| 对比项 | Exp7 作用域插槽 | Exp8 具名作用域插槽 |
| --- | --- | --- |
| 插槽数量 | 一个（默认） | 多个（具名） |
| 父组件写法 | `<Child v-slot="{ user }">` | `<template #user="{ user }">` |
| 子组件写法 | `<slot :user="user" />` | `<slot name="user" :user="user" />` |
| 适用 | 单一内容区 | 多区域、每区数据不同 |
| 典型 | 列表项渲染 | 用户卡片、仪表盘、详情页 |

> [!success] 组合关系
> **具名插槽解决"放哪里"，作用域插槽解决"用什么数据"，两者正交，可以自由组合。**
> Exp4 + Exp7 = Exp8。

---

## 五、多个插槽的独立性与顺序

```vue
<Child>
  <template #info="{ info }">…</template>
  <template #user="{ user }">…</template>
</Child>
```

渲染顺序仍是子组件里的 `<slot>` 顺序：

```text
user 区域 → info 区域
```

父组件书写顺序不影响布局。

> [!warning] 名字必须完全匹配
> `#User`、`#user `（带空格）、`#users` 都匹配不到 `name="user"`。匹配失败的内容不会渲染，且通常没有明显报错。

---

## 六、后备内容

子组件可以给每个具名插槽准备后备内容：

```vue
<slot name="user" :user="user">
  <p>默认用户信息</p>
</slot>
```

父组件没提供 `#user` 时显示后备内容；提供了就替换。

> [!info] 本例没有后备内容
> 父组件两个插槽都提供了，所以看不到 fallback。原理与 [[Exp3 默认插槽]] 一致。

---

## 七、插槽 props 的几种写法

### 7.1 解构单字段

```vue
<template #user="{ user }">
  {{ user.name }}
</template>
```

### 7.2 拿整个对象

```vue
<template #user="slotProps">
  {{ slotProps.user.name }}
</template>
```

### 7.3 解构 + 重命名

```vue
<template #user="{ user: person, extra }">
  {{ person.name }} / {{ extra }}
</template>
```

### 7.4 默认值

```vue
<template #user="{ user = { name: '匿名' } }">
  {{ user.name }}
</template>
```

> [!tip] 解构默认值只在"字段为 undefined"时生效；子组件若传 `null`，不会用默认值。

---

## 八、渲染函数中的等价写法（理解用）

```js
// 父组件的模板编译后，大致相当于：
h(Child, null, {
  user: ({ user }) => h('p', `姓名：${user.name}，年龄：${user.age}`),
  info: ({ info }) => h('p', `城市：${info.city}，职业：${info.job}`),
})
```

> [!info] 为什么能解构
> 每个插槽本质是一个**函数**，参数就是子组件传入的 props 对象。`v-slot="{ user }"` 就是函数参数解构。

---

## 九、典型应用：用户资料卡

```vue
<!-- UserCard.vue -->
<template>
  <div class="card">
    <header><slot name="header" :user="user" /></header>
    <main><slot name="body" :user="user" :stats="stats" /></main>
    <footer><slot name="footer" :user="user" /></footer>
  </div>
</template>
```

```vue
<!-- 使用 -->
<UserCard :user="user">
  <template #header="{ user }">
    <h3>{{ user.name }}</h3>
  </template>
  <template #body="{ user, stats }">
    <p>{{ user.bio }}</p>
    <span>粉丝 {{ stats.fans }}</span>
  </template>
  <template #footer="{ user }">
    <button>关注 {{ user.name }}</button>
  </template>
</UserCard>
```

> [!success] 组件库的设计套路
> 外壳、布局、数据由组件负责；每个区域的**具体标签和样式**交给使用者。这样同一个组件能适配无数业务场景，而不需要堆一堆 props。

---

## 十、易错点清单

- [ ] 子组件 `<slot :user="user" name="user" />` 属性顺序无所谓，但 `name` 别写成数据字段
- [ ] 父组件用 `v-slot="{ user }"` 想匹配具名插槽 → 只能匹配默认插槽
- [ ] `#user` 写成 `#User` → 匹配失败
- [ ] 解构了不存在的字段 → 得到 `undefined`，渲染空白
- [ ] 多个插槽传了同名字段 → 各自独立，不会冲突，但父组件容易看错
- [ ] 忘记 `<template>` 包裹 → 内容会落到默认插槽
- [ ] 子组件没有对应 `name` 的 `<slot>` → 父组件内容被丢弃

---

## 十一、自测

1. 子组件 `<slot name="user" :user="user" />`，父组件怎么写才能拿到 `user`？
2. Exp8 与 Exp7 的核心区别是什么？
3. 父组件只提供 `#user`、不提供 `#info`，`info` 区域会怎样？
4. `#user="{ user: person }"` 中 `person` 是什么？
5. 为什么说插槽本质是函数？

> [!success]- 参考答案
> 1. `<template #user="{ user }">…</template>`。
> 2. Exp8 是多个具名插槽，各自传各自的数据；Exp7 通常只有一个默认作用域插槽。
> 3. 若子组件没有给 `info` 准备后备内容，则什么都不渲染（`<slot>` 为空）。
> 4. 插槽 props 中 `user` 字段的别名，指向同一个对象。
> 5. 模板编译后每个插槽就是 `(props) => VNode` 的函数，`v-slot` 的值就是这个函数的参数。

---

## 十二、同型练习：用户资料卡

> [!info] 题目
> 子组件 `UserCard` 持有用户信息和统计数据：
>
> ```js
> const user = ref({ name: '李四', bio: '前端开发' })
> const stats = ref({ fans: 128, posts: 36 })
> ```
>
> 它提供三个具名作用域插槽：
>
> 1. `header`：传 `user`；
> 2. `body`：传 `user` 和 `stats`；
> 3. `footer`：传 `user`，并有后备内容 `<button>默认操作</button>`。
>
> 父组件要求：
> - `#header` 显示用户名；
> - `#body` 显示简介、粉丝数、文章数；
> - `#footer` 显示"关注 李四"按钮，点击调用父组件的 `follow(name)`；
> - 回答：三个插槽的数据能互相访问吗？父组件只提供 `#header`、`#body`、不提供 `#footer` 时，footer 区域显示什么？`#body="{ user, stats }"` 与 `#body="slotProps"` 有什么区别？`#User` 能匹配 `name="user"` 吗？子组件 `:user="user"` 传的是 ref，父组件拿到的是 Ref 还是普通对象？

> [!success]- 参考答案
> **子组件**
>
> ```vue
> <!-- UserCard.vue -->
> <template>
>   <div class="user-card">
>     <header>
>       <slot name="header" :user="user" />
>     </header>
>
>     <main>
>       <slot name="body" :user="user" :stats="stats" />
>     </main>
>
>     <footer>
>       <slot name="footer" :user="user">
>         <button>默认操作</button>
>       </slot>
>     </footer>
>   </div>
> </template>
>
> <script setup>
> import { ref } from 'vue'
>
> const user = ref({ name: '李四', bio: '前端开发' })
> const stats = ref({ fans: 128, posts: 36 })
> </script>
> ```
>
> **父组件**
>
> ```vue
> <!-- UserCardParent.vue -->
> <template>
>   <UserCard>
>     <template #header="{ user }">
>       <h3>{{ user.name }}</h3>
>     </template>
>
>     <template #body="{ user, stats }">
>       <p>{{ user.bio }}</p>
>       <span>粉丝 {{ stats.fans }} · 文章 {{ stats.posts }}</span>
>     </template>
>
>     <template #footer="{ user }">
>       <button @click="follow(user.name)">关注 {{ user.name }}</button>
>     </template>
>   </UserCard>
> </template>
>
> <script setup>
> import UserCard from './UserCard.vue'
>
> function follow(name) {
>   console.log('关注了', name)
> }
> </script>
> ```
>
> **渲染结果**
>
> ```text
> 李四
> 前端开发
> 粉丝 128 · 文章 36
> [关注 李四]
> ```
>
> 点击按钮后控制台输出：`关注了 李四`。
>
> **逐问回答**
> 1. 不能。每个具名插槽的 props 是独立的：`#header` 只拿到 `{ user }`，`#body` 拿到 `{ user, stats }`，`#footer` 只拿到 `{ user }`。`#header` 里写 `stats` 会得到 `undefined`。
> 2. 显示子组件给 `footer` 准备的后备内容：`<button>默认操作</button>`。父组件没有提供 `#footer`，`<slot name="footer">` 就渲染自己的后备内容。
> 3. 前者直接解构出 `user`、`stats`；后者拿到整个插槽 props 对象，需要写 `slotProps.user`、`slotProps.stats`。两者等价，只是取值方式不同。
> 4. 不能。插槽名区分大小写，`#User`、`#user `（带空格）、`#users` 都匹配不到 `name="user"`；匹配失败的内容不会渲染，通常也没有明显报错。
> 5. 父组件模板里拿到的是**普通对象**，不是 Ref。模板会自动解包 ref，所以 `user.name` 就能直接访问，不要写 `user.value.name`；只有在 JS 中直接操作子组件暴露的原始 ref 时才需要 `.value`。

---

## 十三、关联

- 上一篇：[[Exp7 作用域插槽]]
- 总览：[[00 组件通信与插槽总览]]
- 基础回顾：[[Exp4 具名插槽]]
