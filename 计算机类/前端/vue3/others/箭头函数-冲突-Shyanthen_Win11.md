# 箭头函数（Arrow Function）

> [!abstract] 一句话
> 箭头函数是 ES6 的简写函数语法 `(a, b) => a + b`。但它**不只是"写起来短"**——它是一个语义上的新东西：==箭头函数**没有自己的 `this`**，它的 `this` 直接继承外层（词法作用域）==。这一个区别，是它和 `function` 最本质的分界线，也是 Vue 里到处用它、又偶尔"不能用它"的根本原因。

---

## 一、基本语法：从 `function` 到 `=>`

### 1.1 四种常见形态

```js
// ① 完整写法
const add = (a, b) => {
  return a + b
}

// ② 一个表达式 → 省略 {} 和 return（隐式返回）
const add2 = (a, b) => a + b

// ③ 只有一个参数 → 省略括号
const double = n => n * 2

// ④ 没有参数 → 括号不能省，必须写成 ()
const say = () => console.log('hi')
```

> [!tip] 记忆点
> `=>` 左边是"参数"，右边是"函数体"。==右边如果**是一个表达式**，`{}` 和 `return` 都能省；只要是**一段语句块**，就必须乖乖写 `{}` + 手动 `return`。==

### 1.2 返回对象字面量：必须加括号（高频坑）

```js
// ❌ 报错 / 返回 undefined：{} 被当成"函数体"，不是"对象"
const f1 = () => { name: 'tom' }

// ✅ 用 () 把对象包起来，表示"这是一个要返回的表达式"
const f2 = () => ({ name: 'tom' })

// ✅ 或者老老实实写 return
const f3 = () => { return { name: 'tom' } }
```

> [!warning] 为什么是坑
> `{` 在箭头函数右边有**歧义**：解析器优先把它当成**函数体的开始**。所以 `() => { name: 'tom' }` 里的 `name:'tom'` 实际是一条带标签的语句，函数返回 `undefined`。加一层 `()` 才能消歧义。

### 1.3 换行规则：`=>` 不能单独换行

```js
const f = (a, b)
  => a + b        // ❌ 语法错误（JS 的"自动分号插入"会坏在这里）

const g = (a, b) =>
  a + b           // ✅ => 留在上一行末尾就行
```

---

## 二、核心区别：箭头函数没有自己的 `this`

### 2.1 一句话：`this` 是"词法"的，不是"运行时"的

普通函数的 `this` 由**怎么调用**决定（谁调的、`call`/`apply`/`bind` 绑了谁、是不是 `new`），是**运行时**确定的。

箭头函数**根本没有 `this` 这个绑定**。函数体里写 `this` 时，会沿着**定义位置的外层作用域**一层层往上找——这就是"**词法作用域（lexical this）**"，它**在定义的那一刻就定死了**，之后谁也改不了。

> [!important] 关键结论
> ==普通函数：`this` 看"谁调用"；箭头函数：`this` 看"在哪写"。==
> 所以箭头函数的 `this` 不能被 `call` / `apply` / `bind` 改写，也不能被 `new` 换掉。

### 2.2 对比实验：同一个对象方法

```js
const obj = {
  name: 'tom',

  normal() {
    console.log(this.name)   // ✅ 'tom'，this = 调用者 obj
  },

  arrow: () => {
    console.log(this.name)   // ❌ undefined
                             // 箭头函数定义在"模块顶层/全局"，this 就是外层那个
  }
}

obj.normal()   // tom
obj.arrow()    // undefined  ← 注意：即使写成 obj.arrow()，this 也不是 obj
```

> [!question] 如果箭头函数定义在别的函数**里面**呢？
> 那它就继承那个外层函数的 `this`——这正是它最好用的地方，见下节。

### 2.3 经典用途：回调里保住外层的 `this`

```js
const counter = {
  count: 0,

  start() {
    // ❌ 普通函数：回调被 setTimeout 调用，this 变成 window / undefined
    setTimeout(function () {
      this.count++            // 报错或改错对象
    }, 1000)

    // ✅ 箭头函数：this 继承 start() 的 this = counter
    setTimeout(() => {
      this.count++            // 正确
    }, 1000)
  }
}
```

**没有箭头函数时**，人们得这么写（现在基本不需要了）：

```js
var that = this            // 手动存一个外层 this
setTimeout(function () {
  that.count++
}.bind(this), 1000)        // 或者用 bind 硬绑
```

> [!success] 一句话理解
> 箭头函数相当于==把 `var that = this` 这件事**编译进了语法**==。凡是"在回调里想用外层 `this`"的场景，箭头函数几乎都是首选。

### 2.4 反过来：需要自己的 `this` 时，别用箭头函数

```js
const obj = {
  name: 'tom',
  greet: () => `hi ${this.name}`   // ❌ this 不是 obj
}
```

对象方法的 `this` **本来就该是对象本身**，而箭头函数恰恰不给这个 `this`——所以**对象方法、原型方法、需要 `this` 的类方法，要用普通函数**。

---

## 三、其它 6 个差异（速查表）

箭头函数不只有 `this` 不一样，以下特性它**统统没有**：

| 特性 | 普通 `function` | 箭头函数 | 说明 |
| --- | :---: | :---: | --- |
| 自己的 `this` | ✅ | ❌ | 词法继承外层 |
| `arguments` 对象 | ✅ | ❌ | 用 **rest 参数** `(...args)` 代替 |
| `prototype` 属性 | ✅ | ❌ | 所以不能被 `new` |
| 当构造函数 `new` | ✅ | ❌ | 抛 `TypeError: xxx is not a constructor` |
| `yield`（生成器） | ✅ | ❌ | 不能写 `function*` 的箭头版 |
| `super` / `new.target` | ✅ | ❌ | 类里的箭头函数只能继承外层 |

```js
// arguments 的替代
const sum = (...nums) => nums.reduce((a, b) => a + b, 0)
sum(1, 2, 3)   // 6

// 不能 new
const F = () => {}
new F()        // ❌ TypeError: F is not a constructor

// 没有 prototype
console.log(F.prototype)   // undefined
```

> [!warning] 一个容易忽略的点
> 因为没有 `arguments`、也没有 `this`，**箭头函数不能被 `bind` 改这几个东西**——`f.bind(obj)` 会返回一个新函数，但里面的 `this` / 参数列表不受影响（`this` 该是啥还是啥）。

---

## 四、Vue 里的箭头函数

### 4.1 为什么 Vue 项目里"到处都是箭头函数"

Vue 3 的 `<script setup>` 里**根本没有组件实例的 `this`**（`this` 是 `undefined`），所有状态都靠闭包里的变量。这种情况下：

- 箭头函数没有 `this` 的负担 → 写起来最自然；
- 回调（`setTimeout`、`Promise.then`、`watch`、事件处理）里能直接闭包访问 `ref` / `reactive` 变量。

```vue
<script setup>
import { ref } from 'vue'

const count = ref(0)

// 顶层箭头函数 = 模板里可直接点的方法
const increment = () => count.value++

// 异步里的回调也能直接摸到 count
const load = async () => {
  const data = await fetchData()
  setTimeout(() => {
    count.value = data.length   // ✅ 闭包直接拿到，无需 this
  }, 300)
}
</script>
```

### 4.2 反而**不能**用箭头函数的地方（Options API 时代的老坑）

在 Options API 里，`this` 就是**组件实例**，此时箭头函数会把这个 `this` 弄丢：

```js
export default {
  data() {
    return { count: 1 }
  },

  methods: {
    // ❌ methods 里用箭头函数：this 不是组件实例，拿不到 this.count
    bad: () => {
      this.count++
    },
    // ✅ 用普通函数（简写）
    good() {
      this.count++
    }
  },

  computed: {
    // ❌ 计算属性用箭头函数 → this 丢失
    doubleBad: () => this.count * 2,
    // ✅
    doubleGood() {
      return this.count * 2
    }
  },

  watch: {
    // ❌ watch 处理函数用箭头函数 → this 丢失
    countBad: () => { /* this 不是组件 */ },
    // ✅
    countGood(newVal, oldVal) {
      // this 是组件实例
    }
  },

  mounted() {
    // ✅ 但"回调里"用箭头函数是对的：this 继承 mounted 的组件实例
    setInterval(() => {
      this.count++
    }, 1000)
  }
}
```

> [!important] Vue 里的一条判断口诀
> ==凡是"这个函数本身要当组件的方法/钩子被 Vue 调用"→ 用**普通函数**；凡是"这个函数是**回调**、只想借外层的 `this`"→ 用**箭头函数**。==
> 判断标准就一句：**这个 `this` 到底该是谁？**

### 4.3 Vue 3 `<script setup>` 的建议

既然没有 `this`，就**统一用箭头函数**，风格更一致：

| 场景 | 推荐写法 |
| --- | --- |
| 顶层事件处理函数 | 箭头函数 ✅ |
| `computed(() => ...)` | 箭头函数 ✅（本来就是回调） |
| `watch(source, () => ...)` | 箭头函数 ✅ |
| 生命周期钩子 `onMounted(() => ...)` | 箭头函数 ✅ |
| Options API 的 `methods` / `computed` / `watch` 选项 | **普通函数**（需要 `this`） |

---

## 五、什么时候用、什么时候别用

> [!success] 优先用箭头函数
> - 回调：`setTimeout` / `Promise.then` / `map` / `filter` / `forEach` / 事件监听
> - 需要一个"纯函数"，不关心 `this`
> - `<script setup>` 里的一切
> - 想沿用外层 `this` 时（是它最大的价值）

> [!danger] 别用箭头函数
> - **对象方法**、**原型方法**、需要自己的 `this` 的**类方法**
> - 需要 `arguments` 对象时（改用 rest 参数）
> - 需要 `new` 时（做不了构造函数）
> - 需要 `yield` 的生成器
> - Options API 的 `methods` / `computed` / `watch` 选项（会丢 `this`）

---

## 六、常见坑清单

1. **返回对象忘了括号**：`() => { a: 1 }` 返回 `undefined`，要写 `() => ({ a: 1 })`。
2. **把对象方法写成箭头函数**：`this` 不再指向对象。
3. **以为 `obj.arrow()` 就能把 `this` 变成 `obj`**：不行，箭头函数不吃"谁调用"这一套。
4. **`bind` 想改 `this`**：箭头函数改不动。
5. **`new` 箭头函数**：直接报错。
6. **在箭头函数里用 `arguments`**：它是外层的 `arguments`（甚至报错），要用 rest 参数。
7. **Vue Options API 里把 `methods` 写成箭头函数**：`this` 丢失，Vue 官方文档专门提醒过这一点。
8. **`=>` 后面换行**：会触发语法错误。

---

## 小结

- 箭头函数 = 简写语法 **＋** 语义变化（**词法 `this`**）。
- 记住一句话：==普通函数 `this` 看"谁调用"，箭头函数 `this` 看"在哪写"。==
- 因为"在定义时定死 `this`"，它天然适合**回调**，天然不适合**需要自己 `this` 的方法**。
- Vue 3 `<script setup>` 没有 `this`，所以箭头函数基本通吃；Vue 2 / Options API 的 `methods`、`computed`、`watch` 选项则要留给普通函数。

---

**相关笔记**：[[setup语法糖]] ｜ [[vue中的export]]
