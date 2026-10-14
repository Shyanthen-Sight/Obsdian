# number

> [!abstract] 一句话定义
> `number` 是 TypeScript 里唯一的数值类型，对应 JS 的**双精度 64 位浮点数**——==没有 int / float / double 之分，整数和小数共用它==。

---

## 一、基本用法

```ts
let int: number = 42
let float: number = 3.14
let hex: number = 0xff           // 255
let bin: number = 0b1010         // 10
let sep: number = 1_000_000      // 数字分隔符

// 字面量类型：固定某个具体数值
let dice: 6 = 6                  // 只能是 6
type Digit = 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
type Range = 1 | 2 | 3 | 4 | 5

const nan = NaN
const inf = Infinity
const negInf = -Infinity
```

---

## 二、常见场景与注意事项

- 计时、计数、坐标、数值配置等**一切数字**。
- **字面量联合**常用于限定取值范围（如颜色通道、等级）。

> [!warning] 所有 `number` 都是浮点数
> `0.1 + 0.2 !== 0.3`——这是 IEEE 754 的固有特性，**不是 TS 的问题**。做精确小数（金额）请用整数分或专门的库。

> [!warning] 大整数请用 `bigint`
> 超过 `Number.MAX_SAFE_INTEGER`（`2^53 - 1`）的整数用 `number` 会丢精度，应改用 `bigint`（字面量 `100n`）。注意 **`number` 与 `bigint` 不能直接混算**：
> ```ts
> const big: bigint = 9007199254740993n
> // big + 1            // ❌ 类型错误
> big + 1n              // ✅
> ```

> [!note] `NaN` 是 `number`
> `typeof NaN === 'number'` 为 `true`。判断它要用 `Number.isNaN(x)`，因为 `NaN === NaN` 为 `false`。

---

## 三、与其他类型的关系

| 关系 | 说明 |
| --- | --- |
| 数字字面量 → `number` | ✅（如 `42` 可赋给 `number`） |
| `number` → 字面量 | ❌ 宽到窄，需断言或收窄 |
| `number` 与 `bigint` | 不互通、不能直接混算 |
| `number` 与 `boolean` / `string` | 三者互不相等（`1 === '1'`、`1 === true` 均为 false） |
| 是否原始类型 | ✅，`typeof x === 'number'` |

---

## 四、小结

| 项目 | 内容 |
| --- | --- |
| 所属层级 | 原始类型（Primitive） |
| 关键字 | `number` |
| 本质 | IEEE 754 双精度浮点 |
| 取值范围 | 受 `MAX_SAFE_INTEGER` 限制，超限用 `bigint` |
| 特殊值 | `NaN`、`Infinity`、`-Infinity` |
| 包装对象 | `Number`（**勿用**） |
| `typeof` 结果 | `"number"` |
| 常见陷阱 | 小数精度、大整数溢出、`NaN` 比较 |

---

## 相关笔记

- [[boolean]] —— 与之互不相同的取值类型
- [[string]] —— 字符串 ↔ 数字的转换是高频操作
- [[enum]] —— 数字枚举底层就是 `number`
- [[README|类型笔记总览]]

参考：TypeScript 官方手册 —— Everyday Types / Numeric Literal Types；MDN —— Number / BigInt
