# undefined

> [!abstract] 一句话定义
> `undefined` 只有一个值 `undefined`，表示"**尚未赋值 / 不存在**"——==它是可选的默认缺席者，在 `strictNullChecks` 下成为独立类型==。

---

## 一、基本用法

```ts
let u: undefined = undefined

// 可选属性 / 可选参数：本质是类型加上 undefined
interface User {
  name: string
  age?: number                 // number | undefined
}
function f(x?: string) {}      // 参数类型为 string | undefined

// 显式联合
let maybe: string | undefined
maybe = undefined              // ✅
maybe = 'ok'                   // ✅

// 默认值与空值合并
function greet(name = 'world') {}                  // 默认参数
const v = maybe ?? 'fallback'                      // ?? 只在 null/undefined 时兜底
```

---

## 二、常见场景与注意事项

- 可选字段、可缺省参数、函数未显式返回时的返回值。
- **`undefined` vs `null`**：JS 里 `undefined` 表示"未定义/缺失"，`null` 表示"明确的空"。TS 严格模式下二者不互通。

> [!warning] `strictNullChecks` 是分水岭
> - **关闭时**：`undefined`、`null` 可赋给**任何类型**，等于没有空值保护。
> - **开启时**（`strict` 的一部分）：`undefined` 是独立类型，**必须显式写进联合**才能接受它。
> ```ts
> let s: string = undefined     // strictNullChecks 开启 → ❌
> ```

> [!tip] 用 `?.` 与 `??` 安全处理
> ```ts
> const len = user?.name?.length ?? 0   // 链上任一环节为空都不会崩
> ```
> `?.` 短路取值，`??` 提供兜底——是处理 `undefined` 的主力工具。

> [!note] `void` 类型的变量也只能是 `undefined`
> 但二者含义不同：`void` 强调"没有返回值"，`undefined` 强调"值缺失"。见 [[void]]。

> [!warning] 类型收窄不会自动推断"已定义"
> `if (maybe)` 能收窄出非空分支，但 `if (maybe !== undefined)` 更精确（空字符串、`0` 也是假值）。

---

## 三、与其他类型的关系

| 关系 | 说明 |
| --- | --- |
| `undefined` → `undefined` / `void` | ✅ |
| `undefined` → `unknown` / `any` | ✅ |
| `undefined` → `string` 等 | ❌（`strictNullChecks` 开启时） |
| `string` 等 → `undefined` | ❌ 反向不行 |
| 与可选语法 `?` | `age?: number` 即 `age: number \| undefined` |
| 与 `null` | 严格模式下互不赋值，需要 `x \| null \| undefined` 才都接受 |

---

## 四、小结

| 项目 | 内容 |
| --- | --- |
| 所属层级 | 原始类型（Primitive） |
| 关键字 | `undefined` |
| 语义 | 尚未赋值 / 不存在 |
| 取值 | 仅 `undefined` |
| 受开关影响 | `strictNullChecks`（关时形同虚设） |
| `typeof` 结果 | `"undefined"` |
| 常见搭档 | `?.`、`??`、可选属性 `?`、默认参数 |

---

## 相关笔记

- [[null]] —— 另一个空值类型，与它常一起出现
- [[void]] —— 只能持 `undefined` 的"无返回"标记
- [[interface]] —— 可选属性的写法
- [[README|类型笔记总览]]

参考：TypeScript 官方手册 —— Everyday Types / `strictNullChecks`；MDN —— undefined
