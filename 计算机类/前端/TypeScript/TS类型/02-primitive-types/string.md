# string

> [!abstract] 一句话定义
> `string` 是文本类型，由 UTF-16 码元序列组成——==它的字面量类型与模板字面量类型，是 TS 里表达"限定取值"最趁手的工具==。

---

## 一、基本用法

```ts
let name: string = 'Alice'
let greeting = "hello"           // 推导为 string
let raw = `line1
line2`                           // 模板字符串
let tpl = `Hi ${name}!`          // 插值，结果仍是 string

// 字符串字面量类型：只允许特定取值
let dir: 'left' | 'right' = 'left'
type Status = 'idle' | 'loading' | 'done' | 'error'
```

**模板字面量类型**（TS 4.1+，能在**类型层面**拼接字符串）：

```ts
type Greeting = `hello ${string}`
const g: Greeting = 'hello world'      // ✅

type Side = 'left' | 'right'
type Margin = `margin-${Side}`         // 'margin-left' | 'margin-right'
```

---

## 二、常见场景与注意事项

- 文本、URL、枚举式常量（用字面量联合替代）。
- **联合 + 字面量**常用来替代 [[enum]]，更轻、更贴近 JS。

> [!tip] 字面量联合 vs enum
> 若只是"一组固定字符串"，优先用 `type X = 'a' | 'b'`：产物为零、可读性好。需要反向映射或独立运行时对象时再考虑 [[enum]]。

> [!warning] 别混用 `String`（大写）
> `String` 是包装对象类型，`let s: String` 会让 `s` 接受包装对象——应始终用小写 `string`。

> [!warning] 字符串比较区分大小写
> `'A' === 'a'` 为 `false`。需要不区分时先 `toLowerCase()`，并注意这会影响**类型层面的字面量匹配**（类型系统不帮你做归一化）。

> [!note] `string` 与 `String`、字面量的关系
> `'abc'`（字面量）可赋给 `string`；`string` 不可赋给 `'abc'`。
> `string` 与 `String` 在多数场景互相兼容，但**永远用小写**。

---

## 三、与其他类型的关系

| 关系 | 说明 |
| --- | --- |
| 字符串字面量 → `string` | ✅ |
| `string` → 字面量 / 字面量联合 | ❌ 宽到窄，需收窄 |
| 模板字面量类型 | 是 `string` 的**子类型**，可赋给 `string` |
| `string` 与 `number` | 不相等、不自动转换（`1 === '1'` 为 false） |
| 是否原始类型 | ✅，`typeof x === 'string'` |

---

## 四、小结

| 项目 | 内容 |
| --- | --- |
| 所属层级 | 原始类型（Primitive） |
| 关键字 | `string` |
| 特殊类型 | 字符串字面量、模板字面量类型 |
| 包装对象 | `String`（**用小写**） |
| `typeof` 结果 | `"string"` |
| 常见陷阱 | 大小写敏感、误用 `String`、把数字当字符串比较 |

---

## 相关笔记

- [[enum]] —— 字符串枚举与字面量联合的取舍
- [[number]] —— 字符串 ↔ 数字转换
- [[boolean]] —— 状态表达的另一条路
- [[README|类型笔记总览]]

参考：TypeScript 官方手册 —— Everyday Types / Template Literal Types
