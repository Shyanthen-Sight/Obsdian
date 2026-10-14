# boolean

> [!abstract] 一句话定义
> `boolean` 只有 `true` 与 `false` 两个值——==它本身就是"两个字面量类型的联合" `true | false`==。

---

## 一、基本用法

```ts
let isDone: boolean = false
let isActive = true            // 类型推导为 boolean

// 字面量类型：只允许某一个值
let ok: true = true            // ✅
// let nope: true = false      // ❌ 只能是 true
type Yes = 'y' | 'n'           // 字符串字面量联合（见 [[string]]）
```

**`boolean` 常来自这些运算**

```ts
const a = 1 < 2                 // boolean
const b = !!value               // boolean（真值化）
const c = Boolean(value)        // boolean
// 注意：`&` / `|` 在位运算里返回 number，不是 boolean
const d = 1 & 1                 // number
```

---

## 二、常见场景与注意事项

- **开关、标志位**、条件判断的天然类型。
- **类型守卫**返回值：`x is T` 形式的守卫函数、谓词函数都应返回 `boolean`。

> [!warning] `Boolean`（大写）不是 `boolean`
> `Boolean` 是包装对象类型，`new Boolean(false)` 是一个**对象**，`if (new Boolean(false))` 会进 `true` 分支——**永远别用它**。绝大多数原始类型都有这个坑（见各自笔记）。

> [!tip] 用字面量类型收窄状态
> 比起一堆 `boolean`，用联合字面量更不容易出错：
> ```ts
> type Status = 'idle' | 'loading' | 'done'   // 比三个 boolean 更清晰
> ```

---

## 三、与其他类型的关系

| 关系 | 说明 |
| --- | --- |
| `true` / `false` → `boolean` | ✅ 字面量是 `boolean` 的子类型 |
| `boolean` → `true` | ❌ 宽到窄，需收窄 |
| `boolean` → `unknown` / `any` | ✅ |
| `boolean` 与 `number` | 二者**不相等也不互通**（JS 里 `true === 1` 为 false） |
| 是否原始类型 | ✅ 是原始类型，`typeof x === 'boolean'` |

---

## 四、小结

| 项目 | 内容 |
| --- | --- |
| 所属层级 | 原始类型（Primitive） |
| 关键字 | `boolean` |
| 取值 | `true`、`false`，等价于 `true \| false` |
| 包装对象 | `Boolean`（**禁用**） |
| `typeof` 结果 | `"boolean"` |
| 常见陷阱 | 用 `Boolean` 包装对象、把位运算当成布尔 |

---

## 相关笔记

- [[number]] —— 与布尔互不相同的数值类型
- [[string]] —— 字符串字面量联合同样是"收窄状态"的好工具
- [[README|类型笔记总览]]

参考：TypeScript 官方手册 —— Everyday Types / Literal Types
