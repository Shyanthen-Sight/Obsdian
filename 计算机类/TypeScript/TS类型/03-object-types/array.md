# array

> [!abstract] 一句话定义
> `array`（数组）表示**一组同类型元素**的有序列表，写作 `T[]` 或 `Array<T>`——==它是可变的、长度不固定的对象类型==。

---

## 一、基本用法

```ts
const nums: number[] = [1, 2, 3]
const strs: Array<string> = ['a', 'b']      // 两种写法等价

// 类型推导
const mixed = [1, 'a']                       // (string | number)[]
const inferred = [1, 2, 3]                   // number[]

// 嵌套数组
const grid: number[][] = [[1, 2], [3, 4]]

// 只读数组
const frozen: readonly number[] = [1, 2, 3]
// frozen.push(4)                            // ❌ 只读数组不可变
```

---

## 二、常见场景与注意事项

- 一切有序集合：列表、队列、批量数据。
- 需要"定长 + 每位置不同类型"时改用 [[tuple]]。

> [!tip] `T[]` 与 `Array<T>` 用哪个？
> 完全等价。简单类型用 `T[]` 更清爽；**元素本身是联合或函数**时 `Array<T>` 更清楚（`(number | string)[]` vs `Array<number | string>`，后者少一层括号心智负担）。

> [!warning] `readonly T[]` 与 `ReadonlyArray<T>`
> 只读数组**不能 `push`/`pop`/索引赋值**，但可 `map`/`filter`（它们返回新数组）。用它可以表达"这个函数不会修改传入的数组"。

> [!warning] 数组的索引访问在类型层面**不检查越界**
> `arr[999]` 的类型仍是 `T`，运行时却是 `undefined`——这是 TS 的已知妥协（除非开 `noUncheckedIndexedAccess`，那时类型变为 `T | undefined`）。

> [!note] 空数组要显式标注
> `const a = []` 推导为 `any[]`，之后 push 什么都行、也可能悄悄埋雷。请写成 `const a: string[] = []`。

> [!tip] `as const` 得到只读元组
> `[1, 2] as const` 的类型是 `readonly [1, 2]`（字面量元组），而非 `number[]`——常用于固定配置。

---

## 三、与其他类型的关系

| 关系 | 说明 |
| --- | --- |
| `T[]` → `unknown` / `any` | ✅ |
| `T[]` → `U[]` | 需 `T` 可赋给 `U`（协变） |
| 元组 → 数组 | ✅ 元组是数组的**子类型**，可赋给 `T[]` |
| 数组 → 元组 | ❌ 反向不行（长度不保证） |
| 可读数组 → 只读数组 | ✅；反向 ❌ |
| 与 `object` | 数组也是对象（`typeof [] === 'object'`） |
| 是否是原始类型 | ❌ 属于对象类型 |

---

## 四、小结

| 项目 | 内容 |
| --- | --- |
| 所属层级 | 对象类型（Object） |
| 关键字 | `T[]` / `Array<T>` / `ReadonlyArray<T>` |
| 特征 | 同类型、可变长、有序 |
| 只读形式 | `readonly T[]` |
| 越界检查 | 默认**不检查**（可开 `noUncheckedIndexedAccess`） |
| 空数组 | 需显式标注，否则是 `any[]` |
| 相关 | 定长用 [[tuple]] |

---

## 相关笔记

- [[tuple]] —— 定长定型的"数组"
- [[计算机类/TypeScript/TS类型/03-object-types/object]] —— 数组所属的大类
- [[string]] —— 常与数组方法（`split`/`join`）互转
- [[README|类型笔记总览]]

参考：TypeScript 官方手册 —— Arrays / `noUncheckedIndexedAccess`
