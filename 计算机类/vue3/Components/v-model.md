# v-model

> [!abstract] 一句话
> `v-model` 是=="绑定值 + 监听更新事件"的语法糖==。它没有新能力，只是把"传值下去、听事件回来"合成一行：**原生元素**上展开为 `:value` + `@input`，**组件**上展开为 `:modelValue` + `@update:modelValue`。记住这个展开式，v-model 就没了神秘感。

---

## 一、本质：一行语法糖，两件事

任何 `v-model` 都能等价改写成"**一个 prop 往下传 + 一个事件往回抛**"：

```text
        父组件                        子组件 / 原生元素
   ┌──────────────┐   ── ① prop ──▶  ┌──────────────────┐
   │ v-model="x"  │   ◀─ ② emit ───  │ 用户改了，抛新值  │
   └──────────────┘    update:x      └──────────────────┘
        父收到事件 → 把 x 改成新值 → 再流下去（闭环）
```

| 场景 | `v-model="x"` 等价于 |
| --- | --- |
| 原生元素 | `:value="x"` + `@input="x = $event.target.value"` |
| 组件（默认） | `:modelValue="x"` + `@update:modelValue="x = $event"` |
| 组件（带参数 n） | `:n="x"` + `@update:n="x = $event"` |

> [!info] 为什么叫"双向"？
> 数据往下走（prop），事件往上传（emit），**两个方向各走一条路**。v-model 只是把这两条路粘成一行写法——不是"一个变量被两边共享"（见第八节）。

---

## 二、原生元素上的 v-model

在原生表单元素上，`v-model` 会按元素类型自动挑 prop 和事件：

| 元素 | prop | 事件 |
| --- | --- | --- |
| `input[type=text]` / `textarea` | `value` | `input` |
| `input[type=checkbox]` | `checked` | `change` |
| `input[type=radio]` | `checked` | `change` |
| `select` | `value` | `change` |

### 2.1 与手动写法对照

（`const text = ref('')` 的前提下：）
```vue
<input v-model="text" />                                    <!-- 语法糖 -->
<input :value="text" @input="text = $event.target.value" /> <!-- 完全等价 -->
```

### 2.2 典型用法

```vue
<!-- 前提：msg / agree / picked / gender 都已用 ref 声明 -->
<template>
  <textarea v-model="msg"></textarea>                      <!-- 多行文本 -->
  <input type="checkbox" v-model="agree" />                <!-- 单个 → 布尔 -->
  <input type="checkbox" value="Vue" v-model="picked" />   <!-- 多个 → 数组，勾中的入数组 -->
  <input type="radio" value="male" v-model="gender" />     <!-- 同一变量 → 一组单选 -->
  <input type="radio" value="female" v-model="gender" />
</template>
```

> [!warning] `textarea` 不能再写插值
> 原生的 `<textarea>{{ msg }}</textarea>` 在 Vue 里失效，必须用 `v-model`（或 `:value`）来设内容。

### 2.3 三个内置修饰符

| 修饰符 | 作用 |
| --- | --- |
| `.lazy` | 从 `input` 改听 `change`（失焦/回车才同步） |
| `.number` | 用 `parseFloat` 转数字，转不出就保留原字符串 |
| `.trim` | 自动去掉首尾空白 |

```vue
<input v-model.lazy.trim="nickname" />
<input v-model.number="age" type="number" />
```

---

## 三、组件上的 v-model：手写实现

组件不认识 `value` / `input`（那是原生元素的约定），Vue 给组件定了新约定：**默认 prop 叫 `modelValue`，事件叫 `update:modelValue`**。

```vue
<!-- 父组件：等价于 :modelValue="text" @update:modelValue="text = $event" -->
<MyInput v-model="text" />
```

子组件必须**自己把这一对声明出来**：

```vue
<!-- 子组件 MyInput.vue -->
<script setup>
const props = defineProps(['modelValue'])          // ① 收值
const emit  = defineEmits(['update:modelValue'])    // ② 声明更新事件

function onInput(e) {
  emit('update:modelValue', e.target.value)         // ③ 改了往回抛
}
</script>

<template>
  <input :value="props.modelValue" @input="onInput" />
</template>
```

> [!info] 和 [[Props 组件属性]] / [[Events 自定义事件]] 的关系
> v-model 就是这两篇的**组合技**：`modelValue` 走 Props 的路子下来，`update:modelValue` 走 Events 的路子上去。所以调试顺序永远一致——先看 prop 收对没，再看 emit 声明对没。

> [!warning] props 只读，别直接改
> `props.modelValue = 'x'` 会报警告。唯一正确的改法是 `emit('update:modelValue', 新值)`，让父组件去改。

TS 版：

```vue
<script setup lang="ts">
const props = defineProps<{ modelValue: string }>()
const emit = defineEmits<{ 'update:modelValue': [value: string] }>()
</script>
```

---

## 四、`defineModel()`：一行顶掉一对样板

props + emits 那两行写十个组件就烦了。**Vue 3.4+** 的编译宏 `defineModel()` 把它俩折叠成一行：

```vue
<script setup>
const model = defineModel()     // 一行搞定 props + emits
function onInput(e) {
  model.value = e.target.value  // 直接赋值 → 自动 emit 回父组件
}
</script>

<template>
  <input :value="model" @input="onInput" />
</template>
```

> [!success] 心智模型：它替你省掉了什么
> 把 `defineModel()` 返回的 `model` 当成==一个"能写透到父组件的 ref"==：读它 = 读父的值，写它 = 通知父改值。
> 手写版三件事——收值 `defineProps(['modelValue'])`、声明事件 `defineEmits(['update:modelValue'])`、触发更新 `emit('update:modelValue', v)`——现在全被折叠成"定义一次 + `model.value = v`"。

> [!note] 版本要求
> 3.3 是实验特性，**3.4 起稳定并默认可用**。低于 3.4 只能手写 props + emits，见 [[setup语法糖]] 的编译宏版本表。

带类型、默认值与自定义读写：

```vue
<script setup lang="ts">
const model = defineModel<string>({ default: '' })    // 类型 + 默认值
const count = defineModel<number>({ required: true }) // 必填
</script>
```

```js
// get / set 自定义读写：写回父组件前先 trim
const model = defineModel({ get: (v) => v, set: (v) => v.trim() })
```

---

## 五、多个 v-model

给 `v-model` 加参数即可，**参数名就是 prop 名**：

```vue
<UserName v-model:first="firstName" v-model:last="lastName" />
```

展开（**参数名就是 prop 名**）：

```text
v-model:first="firstName"  ⇔  :first="firstName" + @update:first="firstName = $event"
v-model:last="lastName"    ⇔  :last="lastName"   + @update:last="lastName = $event"
```

子组件用 `defineModel('first')` 各收各的：

```vue
<script setup>
const first = defineModel('first')
const last  = defineModel('last')
</script>

<template>
  <input v-model="first" />
  <input v-model="last" />
</template>
```

> [!warning] 用了参数就**没有** `modelValue`
> `v-model:first` 对应 prop `first`、事件 `update:first`，不再有 `modelValue`。手写版就是两组 props + emits（`defineProps(['first','last'])` + `defineEmits(['update:first','update:last'])`）。想两者并存可写 `<Child v-model="x" v-model:other="y" />`。

---

## 六、带参数的 v-model 与参数命名

参数名直接决定 prop 名和事件名，所以要选有语义的词：

```vue
<Panel v-model:expanded="isOpen" />        <!-- 折叠状态 -->
<ColorPicker v-model:color="themeColor" /> <!-- 颜色 -->
```

```vue
<!-- Panel.vue -->
<script setup lang="ts">
const expanded = defineModel<boolean>('expanded', { default: false })
// 模板里直接 <button @click="expanded = !expanded"> 即可，父组件的 isOpen 自动同步
</script>
```

| 父组件写法 | prop | 事件 |
| --- | --- | --- |
| `v-model="x"` | `modelValue` | `update:modelValue` |
| `v-model:title="x"` | `title` | `update:title` |
| `v-model:expanded="x"` | `expanded` | `update:expanded` |

> [!tip] 命名建议
> 用小驼峰、表意明确的词（`first`、`expanded`、`color`）。别用会和默认约定混淆的 `value` / `model`，也别用带连字符的 `v-model:foo-bar`。

---

## 七、组件 v-model 的自定义修饰符

原生元素有 `.lazy` / `.number` / `.trim`；**组件的修饰符要自己实现**。

```text
<Child v-model.trim="x" />
        └─ .trim 作为名为 modelModifiers 的 prop 传入
           → props.modelModifiers === { trim: true }
```

| 写法 | 存放修饰符的 prop |
| --- | --- |
| `v-model.trim="x"` | `modelModifiers` |
| `v-model:title.trim="x"` | `titleModifiers` |

规律：**默认 → `modelModifiers`；带参数 `xxx` → `xxxModifiers`**。

### 7.1 手写实现：首字母大写

父组件：`<Child v-model.capitalize="text" />`

```vue
<!-- 子组件 Child.vue -->
<script setup>
const props = defineProps({
  modelValue: String,
  modelModifiers: { default: () => ({}) }   // ① 接收修饰符对象
})
const emit = defineEmits(['update:modelValue'])

function onInput(e) {
  let val = e.target.value
  if (props.modelModifiers.capitalize) {     // ② 按修饰符决定行为
    val = val.charAt(0).toUpperCase() + val.slice(1)
  }
  emit('update:modelValue', val)
}
</script>

<template><input :value="modelValue" @input="onInput" /></template>
```

### 7.2 `defineModel` 版

```vue
<script setup>
// 第二个解构出来的是"修饰符对象"
const [model, modifiers] = defineModel({
  set(value) {
    return modifiers.capitalize
      ? value.charAt(0).toUpperCase() + value.slice(1)
      : value
  }
})
</script>
<!-- 模板里：<input v-model="model" /> -->
```

> [!success] `set` 里为什么 `return` 而不是赋值？
> `set` 的返回值就是**最终要 emit 出去的值**，Vue 拿它去更新父组件——比手动 `.value =` 更清晰，也避免"改完又触发 get"的绕圈。

> [!warning] 修饰符名别撞内置的
> 组件上的 `.trim` / `.number` / `.lazy` **不会自动生效**——子组件不读 `modelModifiers`，它就是个被忽略的 prop，不报错但也没效果。

---

## 八、v-model 与单向数据流

Vue 的规矩是**单向数据流**：数据从父流到子，子不能直接改父的东西。v-model 并不违反它：

```text
❌ 破坏单向：props.modelValue = 'x'
   → 改的是父传来的引用，父不知情，警告 readonly

✅ v-model：子只"提议"，父来"执行"
   子: emit('update:modelValue', 'x')    ← 只是发消息
   父: text = 'x'（编译器生成的监听器）   ← 真正改的是父自己的 ref
```

> [!quote] 一句话点破
> `v-model` ==把"一个 setter 函数"交给子组件==。变量始终住在父组件那里，子只是拿到了"申请改它"的权限——改动的执行者永远是数据的所有者。
> 对比：想让**父主动调子**的方法 → `defineExpose`；想让**子主动通知父改数据** → `emit` / `v-model`（见 [[setup语法糖]]）。职责不同，别混用。

---

## 九、完整示例：一个自定义输入组件

把 `defineModel` + 修饰符 + TS 串起来：

```vue
<!-- FancyInput.vue —— 子组件 -->
<script setup lang="ts">
// 双向绑定值 + 注入 trim 修饰符：写回前自动去首尾空格
const [value, modifiers] = defineModel<string>({
  default: '',
  set(v) { return modifiers.trim ? v.trim() : v }
})
defineProps<{ placeholder?: string }>()    // 额外的普通 prop
</script>

<template>
  <!-- 内部依旧是原生 v-model，绑的正是上面拿到的 value -->
  <input v-model="value" :placeholder="placeholder" />
  <small>当前：{{ value }}</small>
</template>
```

```vue
<!-- 父组件 -->
<script setup lang="ts">
import { ref } from 'vue'
import FancyInput from './FancyInput.vue'
const keyword = ref('')
</script>

<template>
  <FancyInput v-model.trim="keyword" placeholder="搜索关键词" />
  <p>父组件收到的值：「{{ keyword }}」</p>
</template>
```

数据流闭环：

```text
用户输入 "  hi  " → 原生 @input → 子组件 value.value = "  hi  "
   │ defineModel 的 set 触发（modifiers.trim === true）
   ▼ 返回 "hi" → emit('update:modelValue', 'hi')
父组件 keyword = 'hi'（编译器生成的监听器）
   │ prop 重新流下（modelValue="hi"）
   ▼
子组件 <input> 显示 "hi"   ← 闭环
```

> [!success] 这个例子体现三件事
> ① `defineModel` 让子组件像用本地 ref 一样操作绑定值；② 修饰符语义收拢在**子组件内部**，父组件只管写 `.trim`；③ 父组件的 `keyword` 始终是唯一数据源。

---

## 十、常见坑 / 常见问题

> [!question] 子组件改了值，父组件没反应？
> 多半是**没声明对应的 emit**。手写版必须 `defineEmits(['update:modelValue'])`，否则 `emit(...)` 什么都不做（只有警告）。

> [!question] 把 `modelValue` 改名后 v-model 就不灵了？多个 v-model 的事件名怎么记？
> `v-model="x"` **固定**对应 `modelValue` + `update:modelValue`，改名必须用参数写法 `v-model:myname="x"`（prop `myname`、事件 `update:myname`）。
> 记法一句话：**事件名 = `update:` + 参数名**。`v-model:first` → `update:first`；无参数则 `update:modelValue`。

> [!question] 组件上写了 `.trim` 为什么没效果？
> 组件的修饰符**不会自动生效**，它只是以 `xxxModifiers` 的 prop 传进来，得自己读并实现语义。不读就没效果，且不报错。

> [!question] `defineModel` 编译报错 / is not defined？直接改 `props.modelValue` 又报 readonly？
> 前者是版本问题：`defineModel` 需 **3.4+**（3.3 要手动开启实验特性），低版本请升级 `vue` 与 `@vitejs/plugin-vue`，或回到手写 props + emits。
> 后者是 props 只读，改法只有一条：`emit('update:modelValue', 新值)` 或 `defineModel` 的 `model.value = 新值`（详见 [[Props 组件属性]]）。

> [!danger] 别在子组件"偷偷"缓存一份再改
> ```js
> const local = ref(props.modelValue)   // ❌ 父后续更新，local 不会跟着变
> ```
> 这是最常见的"数据不同步"来源。真要本地副本用 `computed` 派生，或 `watch` 双向同步；能用 `defineModel` 就别绕这条路。

---

## 相关笔记

- [[setup语法糖]] —— `defineProps` / `defineEmits` / `defineModel` 等编译宏全景
- [[Props 组件属性]] —— `modelValue` 从哪来、props 为什么只读
- [[Events 自定义事件]] —— `update:modelValue` 如何声明与触发
- [[SFC]] —— 单文件组件里各块的分工
- [[属性继承]] —— 未声明为 prop 的属性（含 `modelModifiers`）如何落到根元素
- [[组件注册]] —— 用 v-model 之前，子组件得先能被认出来

---

参考：Vue 官方文档 —— Component v-model / Form Input Bindings / `defineModel()` 编译宏（3.3 实验、3.4 稳定）；`v-model` 参数与自定义修饰符（`modelModifiers` / `xxxModifiers`）
