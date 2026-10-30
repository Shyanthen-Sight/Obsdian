# tuple

> [!abstract] 一句话定义
> `tuple`（元组）是**长度固定、每个位置类型可不同**的数组——==它是"数组"的特例：一旦声明了形状，长度和各位置的类型都被锁死==。

---

## 一、基本用法

```ts
let pair: [string, number] = ['age', 30]

// 各位置类型独立
let rgb: [number, number, number] = [255, 128, 0]

// 具名元组（TS 4.0+，纯为可读性）
let point: [x: number, y: number] = [1, 2]

// 可选元素（只能出现在末尾）
let opt: [string, number?] = ['a']

// rest 元素
let rest: [string, ...number[]] = ['label', 1, 2, 3]

// 只读元组
const ro: readonly [number, number] = [0, 0]
```

**常见于"就俩/仨值"的返回**：

```ts
function minMax(nums: number[]): [number, number] {
  return [Math.min(...nums), Math.max(...nums)]
}
const [lo, hi] = minMax([3, 1, 2])   // 解构，类型精确
```

---

## 二、常见场景与注意事项

- **多返回值**、`useState` 式 `[value, setter]`、坐标、RGB、键值对。
- 希望"长度和每位置类型都被约束"时。

> [!warning] 长度是被约束的
> ```ts
> let p: [number, number] = [1, 2, 3]   // ❌ 长度不符
> let q: [number, number] = [1]         // ❌ 缺元素
> ```

> [!tip] `as const` 常用来"造"元组
> ```ts
> const args = [1, 'a'] as const        // readonly [1, 'a']，字面量元组
> ```
> 直接写 `[1, 'a']` 会推导成 `(string | number)[]`，加 `as const` 才锁成元组。

> [!note] 元组与数组的关系是"子类型"
> 元组可以赋给**元素类型一致的数组**（`[string, number]` → `(string|number)[]`），反之不行（数组长度不被保证）。见 [[array]]。

> [!warning] 可变元组与 `readonly` 权衡
> 用 `readonly` 元组能防止被 `push` 破坏长度约定；跨函数传递固定结构时值得多写这两个字。

---

## 三、与其他类型的关系

| 关系 | 说明 |
| --- | --- |
| 元组 → 数组 | ✅（元组是数组的子类型） |
| 数组 → 元组 | ❌（长度不保证） |
| 元组 → `unknown` / `any` | ✅ |
| `readonly` 元组 → 可变元组 | ❌；反向 ✅ |
| 与 `object` | 元组也是对象类型 |
| 与 `interface` | 用 `[k: string, v: number]` 表达"固定结构"，比 interface 更紧凑 |

---

## 四、小结

| 项目 | 内容 |
| --- | --- |
| 所属层级 | 对象类型（Object） |
| 关键字 | `[T1, T2, ...]` |
| 特征 | 定长、每位置类型独立 |
| 可选 / rest | `[T, U?]` / `[T, ...U[]]` |
| 只读形式 | `readonly [T, U]` |
| 快速构造 | `[...] as const` |
| 常见用途 | 多返回值、`[value, setter]`、坐标 |

---

## 相关笔记

- [[array]] —— 元组的"父类型"，可变长同类型
- [[计算机类/TypeScript/TS类型/03-object-types/object]] —— 元组所属的大类
- [[interface]] —— 表达"固定结构"的另一条路
- [[README|类型笔记总览]]

参考：TypeScript 官方手册 —— Tuples / Variadic Tuple Types
