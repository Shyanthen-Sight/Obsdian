
> [!abstract] 一句话
> 二者都是把普通数据变成**响应式**的入口，区别只有一句：==`ref` 是"带 `.value` 的盒子"，什么类型都能装；`reactive` 是"给对象套一层 Proxy"，只能套对象，不用 `.value`==。Vue 官方推荐 **`ref` 作为声明响应式状态的首选**，`reactive` 只在"状态天然是一组字段、且从不整体替换"时使用。

---

## 一、结论先行

| 维度    | `ref`                                | `reactive`                |
| ----- | ------------------------------------ | ------------------------- |
| 能装什么  | **任意类型**：数字、字符串、布尔、对象、数组、`Map`、`Set` | **只能是对象类型**（对象 / 数组 / 集合） |
| 返回什么  | `RefImpl` 盒子，形如 `{ value }`          | 目标对象的 `Proxy` 代理          |
| 脚本中读写 | `count.value`                        | `state.count`             |
| 模板中使用 | 顶层自动解包，直接写 `count`                   | 直接写 `state.count`         |
| 整体替换  | ✅ `count.value = 新值`                 | ⚠️ 官方不建议替换整个对象            |
| 解构    | ✅ 解构出来还是同一个 ref，响应式不丢                | ❌ 普通解构丢响应式，必须 `toRefs`    |
| 默认深度  | 深（存的对象的子属性也跟踪）                       | 深                         |
| 官方定位  | **声明响应式状态的首选 API**                   | 成组状态的辅助手段                 |

> [!tip] 记住这一句
> `ref(对象)` 的 `.value` 里面装的东西，本质上就是 `reactive(对象)` 的代理。==`ref` 装对象 ≈ "reactive + 一层 `.value` 外壳"==；`ref` 比 `reactive` 多出来的能力，是能装**原始值**。

---

## 二、最小对照示例

同一个计数器，两种写法：

```vue
<script setup>
import { ref, reactive } from 'vue'

// ① ref 版
const count = ref(0)
function add() {
  count.value++          // 脚本里必须 .value
}

// ② reactive 版（计数器这种单值其实不该用 reactive，仅作对照）
const state = reactive({ count: 0 })
function add2() {
  state.count++          // 不需要 .value
}
</script>

<template>
  <!-- ref：模板自动解包，写 count 而不是 count.value -->
  <p>{{ count }}</p>
  <!-- reactive：按属性访问 -->
  <p>{{ state.count }}</p>
</template>
```

再看"装对象"时两者几乎一样：

```js
import { ref, reactive } from 'vue'

const userRef = ref({ name: 'Tom', age: 18 })
userRef.value.age++          // ✅ 深响应，视图更新

const userReactive = reactive({ name: 'Tom', age: 18 })
userReactive.age++           // ✅ 深响应，视图更新
```

> [!info] 为什么 `reactive` 装不了原始值
> `reactive(0)` 会直接返回 `0` 并在开发环境警告 `value cannot be made reactive`。因为 Proxy 只能代理**对象**；数字、字符串这些原始值没有"属性访问"可拦截，只能靠 `ref` 的 `.value` 容器包一层。

---

## 三、机制层面：一个盒子 vs 一层代理

### 3.1 `ref` 是"访问器盒子"

极简伪代码（真实实现是 `RefImpl` + `trackRefValue`）：

```js
class RefImpl {
  constructor(value) {
    this._value = isObject(value) ? reactive(value) : value  // 对象转代理
  }
  get value() {
    track(this, 'value')        // 读取 .value → 收集依赖
    return this._value
  }
  set value(newVal) {
    if (!Object.is(newVal, this._value)) {
      this._value = isObject(newVal) ? reactive(newVal) : newVal
      trigger(this, 'value')    // 写入 .value → 触发更新
    }
  }
}
```

要点：

- 响应式的入口只有一个——`.value` 这个属性，所以**原始值也能被跟踪**。
- 存对象时内部自动调用 `reactive()`，所以 `ref` 默认也是**深响应**。
- 整体替换只看 `.value` 有没有变，所以 `count.value = 100` 一定能触发更新。

### 3.2 `reactive` 是"Proxy 代理"

```js
function reactive(target) {
  return new Proxy(target, {
    get(target, key, receiver) {
      track(target, key)                       // 读了哪个属性，记下来
      return Reflect.get(target, key, receiver)
    },
    set(target, key, value, receiver) {
      const ok = Reflect.set(target, key, value, receiver)
      trigger(target, key)                     // 改了哪个属性，通知谁
      return ok
    },
  })
}
```

要点：

- 响应式入口是**每一个属性的读写**，因此目标必须先是一个对象。
- 代理的是"对象本身"：只要还持有这个代理，深层读写都能跟踪；**换掉代理（整体赋值）就脱钩**。
- 不是所有对象都能代理：`Date`、`RegExp`、`Error` 等原生对象会原样返回、不具备响应式；第三方库实例建议用 `markRaw()` 显式跳过。

### 3.3 两者关系

```text
ref(原始值)  →  { value: 0 }                    ← 盒子 + 访问器
ref(对象)    →  { value: reactive(obj) }        ← 盒子 + 代理
reactive(obj)→  Proxy(obj)                      ← 只有代理
```

所以"`ref` 和 `reactive` 谁更强"是个伪命题：`ref` 是超集式的通用容器，`reactive` 是它内部处理对象时用的那层代理。

---

## 四、模板里的自动解包规则

这是考试和实战都最爱考的一块，规则只有 4 条：

| 场景 | 是否自动解包 | 写法 |
| --- | --- | --- |
| 模板**顶层**的 ref | ✅ 是 | `{{ count }}` |
| `reactive` 对象里嵌套的 ref | ✅ 是 | `state.count` 直接当值用 |
| 数组 / `Map` / `Set` 里的 ref | ❌ 否 | `books[0].value`、`map.get('count').value` |
| 普通对象（非 reactive）里的 ref，出现在**表达式**中 | ❌ 否 | `object.id + 1` 会得到 `[object Object]1` |

```js
const count = ref(0)
const state = reactive({ count: ref(0) })

const books = reactive([ref('Vue 3')])
const map = reactive(new Map([['count', ref(0)]]))

const plain = { id: ref(1) }
```

```vue
<template>
  <p>{{ count }}</p>              <!-- 0 -->
  <p>{{ state.count }}</p>        <!-- 0（JS 里 state.count 也是 0，不用 .value） -->
  <p>{{ books[0].value }}</p>     <!-- 数组里的 ref 不会解包 -->
  <p>{{ map.get('count').value }}</p>

  <p>{{ plain.id }}</p>           <!-- 1：插值最终值会被解包 -->
  <p>{{ plain.id + 1 }}</p>       <!-- [object Object]1：表达式内不解包 -->
</template>
```

> [!warning] 别在模板里写 `.value`
> 顶层 ref 已经自动解包，`{{ count.value }}` 反而是在读一个数字的 `.value`，得到 `undefined`。==脚本里写 `.value`，模板里不写==，这是最省心的记忆法。

---

## 五、五个高频坑

### 坑 1：解构 `reactive` 丢响应式

```js
const state = reactive({ count: 0, name: 'Tom' })

const { count } = state       // ❌ count 只是 0 的拷贝，后续 state.count++ 与它无关
count++                       // 页面不会更新

const { count: countRef, name } = toRefs(state)  // ✅ 每个属性变成 ref
countRef.value++              // state.count 同步变化，视图更新

const count2 = toRef(state, 'count')             // ✅ 单个属性转 ref
```

原因：解构是**取值**，原始值取出来就是一份拷贝，和原代理再无关系。`toRefs` 把每个属性包装成指向原对象的 ref，所以读写仍然经过代理。

> [!tip] 组合式函数为什么要返回 ref
> `const { x, y } = useMouse()` 这种写法只有在返回 ref 时才安全；如果组合式函数内部用 `reactive` 存状态，记得用 `toRefs` 再返回。

### 坑 2：整体替换 `reactive` 对象

```js
let state = reactive({ count: 0, name: 'Tom' })

// ❌ 官方不推荐：oldProxy 仍是旧对象的代理
state = reactive({ count: 1, name: 'Jerry' })

// ✅ 重置就原地合并
Object.assign(state, { count: 1, name: 'Jerry' })
```

细节：在 `<script setup>` 里，模板绑定的是指向 `state` 变量的 getter，**直接重新赋值时模板往往还能跟着变**；但已经传出去的旧引用（子组件的 props、别的模块保存的代理、`toRefs` 生成的 ref）会继续指向旧代理，出现"一半新一半旧"的诡异状态。所以结论仍是：**reactive 对象只改属性，不换对象**。

### 坑 3：脚本里忘了 `.value`

```js
const count = ref(0)

count++          // ❌ 给 ref 对象本身加了个无意义属性，视图不动
count.value++    // ✅

const user = ref({ name: 'Tom' })
user.name = 'Jerry'      // ❌ 改的是 RefImpl 上的 name 属性
user.value.name = 'Jerry' // ✅
```

### 坑 4：`watch` 的默认深度不同

```js
const state = reactive({ a: 1, b: { c: 2 } })
const obj = ref({ a: 1, b: { c: 2 } })

watch(state, () => {})                 // ✅ 隐式 deep，任意层级变化都触发
watch(obj, () => {})                   // ⚠️ 只有 obj.value 整体替换才触发
watch(obj, () => {}, { deep: true })   // ✅ 子属性变化也触发
watch(() => obj.value.a, () => {})     // ✅ 或精确监听某个字段（更省性能）
```

记住：**直接监听 reactive 对象 = 自动 deep；监听 ref 的 `.value` = 只看替换**。

### 坑 5：把原始值"顺手"取出来再用

```js
const state = reactive({ count: 0, profile: { name: 'Tom' } })

const c = state.count      // ❌ 取到的是数字拷贝，之后 state.count++ 与 c 无关
const p = state.profile    // ✅ 取到的是嵌套代理，p.name 改动仍然响应式
```

取**原始值属性**会断链，取**对象属性**拿到的是代理、不会断链。这解释了为什么"解构 reactive"只在原始值上翻车得最明显。

---

## 六、还在踩的边界

### 6.1 `reactive` 传原始值

```js
reactive(1)        // 返回 1，开发环境警告
reactive('abc')    // 返回 'abc'
reactive(null)     // 返回 null
```

一律用 `ref`。这也是"统一用 ref"最实在的理由：不用每次判断"这个状态会不会是数字"。

### 6.2 `shallowRef` / `shallowReactive`

```js
const list = shallowRef([1, 2, 3])
list.value.push(4)        // ❌ 不触发更新（只跟踪 .value 替换）
list.value = [1, 2, 3, 4] // ✅ 整体替换才触发

const state = shallowReactive({ nested: { a: 1 } })
state.nested.a++          // ❌ 不触发
state.nested = { a: 2 }   // ✅ 第一层属性替换触发
```

适合：大列表、第三方实例、只需要整体替换的数据。`shallowRef` 还可用 `triggerRef(list)` 手动触发。

### 6.3 不需要响应式的对象：`markRaw`

```js
const chart = markRaw(new Chart(...))   // 永远不转代理，省开销也避免 Proxy 破坏内部实现
const state = reactive({ chart })
```

### 6.4 只读：`readonly`

```js
const state = reactive({ count: 0 })
const ro = readonly(state)   // ro.count 只读，写入会警告；底层 state 改动仍会反映到 ro
```

---

## 七、怎么选：官方建议 + 决策树

> [!important] Vue 官方立场
> `reactive()` 有几条硬限制（只能对象、不能整体替换、解构不友好），因此**推荐把 `ref()` 作为声明响应式状态的主要 API**。`reactive()` 适合"一组强相关字段"且"不会整体替换"的场景，例如表单对象、画布配置。

```text
要存的是原始值（数字/字符串/布尔）？            → ref
需要整体替换（接口返回新对象直接赋值）？          → ref
希望解构后依然响应式（组合式函数返回值）？        → ref（或 toRefs(reactive)）
状态天然是一组字段，只改属性不换对象（表单）？    → reactive
状态要给子组件 / 跨模块传递？                    → ref（引用稳定，替换 .value 所有人同步）
```

实践建议：

1. **默认 `ref`**，需要拆字段时用 `toRefs`，一个项目里保持统一比"局部最优"更重要。
2. `reactive` 只用于**字段多、结构稳定**的表单/配置对象，能少写很多 `.value`。
3. 不要把 `reactive` 对象整个塞进 `ref`：`ref(reactive(obj))` 是多余的套娃，`ref` 内部本来就会代理对象。
4. 从 `reactive` 里往外传值，传 `toRef` / `toRefs`，不要传解构出来的原始值。
5. Pinia 的 setup store 里两者都能用，但返回 `ref` 更利于解构和类型推导。

---

## 八、周边 API 速查

| API | 作用 | 小例子 |
| --- | --- | --- |
| `toRef(obj, key)` | 把对象的某个属性转成 ref，双向同步 | `toRef(state, 'count')` |
| `toRefs(obj)` | 把整个对象的所有属性转成 ref 对象 | `const { a, b } = toRefs(state)` |
| `isRef(x)` | 判断是不是 ref | `isRef(count)` → `true` |
| `isReactive(x)` | 判断是不是 reactive 代理 | `isReactive(state)` → `true` |
| `isProxy(x)` | 判断是不是 `reactive` 或 `readonly` 代理 | `isProxy(refObj.value)` → `true` |
| `unref(x)` | 是 ref 就取 `.value`，否则原样返回 | `unref(count)` → `0` |
| `shallowRef(x)` | 只跟踪 `.value` 替换的浅层 ref | 大列表、第三方实例 |
| `shallowReactive(x)` | 只跟踪第一层属性的 reactive | 嵌套大对象 |
| `triggerRef(r)` | 手动触发 `shallowRef` 更新 | `triggerRef(list)` |
| `toRaw(x)` | 取回代理背后的原始对象（不可用于响应式） | `toRaw(state)` |
| `markRaw(x)` | 标记对象永不转代理 | `markRaw(instance)` |
| `readonly(x)` | 创建只读代理 | `readonly(state)` |

> [!tip] 类型速记
> `ref<T>()` 返回 `Ref<T>`（对象会自动 `UnwrapRef`）；`reactive<T>()` 返回 `UnwrapNestedRefs<T>`。在 TypeScript 里 `ref` 的泛型更直观，也是它更适合做"统一状态容器"的原因之一。

---

## 九、自测

> [!question]- 1. `const state = reactive({ count: 0 }); const { count } = state; count++`，视图会更新吗？
> 不会。解构拿到的是 `0` 的拷贝，已经和 `state` 的代理脱钩。改成 `const { count } = toRefs(state); count.value++`，或用 `state.count++`。

> [!question]- 2. `ref` 和 `reactive` 都能存对象，本质联系是什么？
> `ref(对象)` 内部会调用 `reactive()` 处理 `.value`，即 `.value` 就是一个 reactive 代理。`ref` 多出来的是"盒子 + `.value` 访问器"，因此还能装原始值、能整体替换。

> [!question]- 3. 模板里 `plain.id + 1`（`plain` 是普通对象，`id` 是 `ref(1)`）输出什么？
> `[object Object]1`。普通对象里的 ref 在**表达式求值时不自动解包**；只有插值最终值 `{{ plain.id }}` 会被解包成 `1`。想参与运算就写 `plain.id.value + 1`，或把 `plain` 改成 `reactive`。

> [!question]- 4. 为什么 `watch(reactiveObj)` 默认是深度监听，而 `watch(refObj)` 不是？
> 监听 reactive 对象时，Vue 直接遍历/递归访问它的属性来建立依赖，天然是 deep；监听 ref 时只跟踪 `.value` 这一个访问器，所以只有整体替换才触发，要深入子属性必须显式 `{ deep: true }`。

> [!question]- 5. 什么时候应该用 `reactive` 而不是 `ref`？
> 状态是一组强相关字段（如表单）、只做属性级修改、从不需要整体替换、也不需要把字段解构出去时。此时 `reactive` 能省掉满屏 `.value`；其余情况优先 `ref`。

---

## 十、相关笔记

- [[setup语法糖]] —— `<script setup>` 顶层绑定自动暴露、模板自动解包的前提
- [[附 基础组件与工程配置]] —— `ref` / `reactive` 在 `computed`、`watch`、`onMounted` 中的基础用法
- [[00 组件通信与插槽总览]] —— props 向下、emit 向上，以及响应式状态在父子间的流动方式
- [[v-model]] —— 模板里 `v-model` 绑定 ref 时的自动解包行为
- [[Props 组件属性]] —— props 本身是只读的响应式数据，和 `ref` / `reactive` 的边界

> [!success] 一句话收尾
> **`ref` 用盒子包住任意值，靠 `.value` 的 getter/setter 收集和触发依赖；`reactive` 用 Proxy 代理对象，按属性读写收集依赖。** 默认选 `ref`，成组且不替换的对象状态才交给 `reactive`；脚本里记得 `.value`，模板里别写 `.value`。
