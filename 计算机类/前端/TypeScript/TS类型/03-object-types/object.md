# object

> [!abstract] 一句话定义
> 小写的 `object` 表示"**任何非原始值**"——==即除了 `boolean` / `number` / `string` / `void` / `undefined` / `null` / `symbol` / `bigint` 之外的一切==（对象、数组、函数、类实例都算）。

---

## 一、基本用法

```ts
let o: object = {}
o = []                    // ✅ 数组是对象
o = () => {}              // ✅ 函数是对象
o = new Date()            // ✅

// o = 1                  // ❌ 原始值
// o = 'str'              // ❌
// o = null               // ❌ （strict 下）
// o = undefined          // ❌

// 想访问成员？object 太宽，取不到具体属性
// o.toString            // ⚠️ 需要先收窄或断言
```

**对比：`object` vs `{}` vs `Object`**

```ts
let a: object = {}          // 非原始值（不含原始类型）
let b: {} = 1               // ⚠️ 空对象类型，几乎一切都能赋给它
let c: Object = 'str'       // ⚠️ Object 接受原始值（被装箱）
```

---

## 二、常见场景与注意事项

- 想表达"**这里要一个对象，但我不关心具体形状**"时。
- **多数情况下应改用 [[interface]] 精确描述形状**，`object` 太笼统。

> [!warning] `object` / `{}` / `Object` 三者不同，别混用
> | 写法 | 接受什么 | 建议 |
> | --- | --- | --- |
> | `object` | 仅非原始值 | 需要时用 |
> | `{}` | 几乎任何非 `null`/`undefined` 值（含 `1`、`'a'`） | ⚠️ 易误用 |
> | `Object` | 一切（原始值自动装箱） | ❌ 基本不用 |
> 三者**都取不到具体属性**，都太宽。

> [!tip] 要"任意键的字典"，用索引签名或 `Record`
> ```ts
> const dict: Record<string, number> = { a: 1, b: 2 }
> interface AnyObj { [k: string]: unknown }
> ```
> 这比 `object` 更有用，因为至少能按键取值。

> [!note] `object` 不能当索引用
> 即使它是对象，`o['x']` 也会报错——`object` 不承诺有任何成员。要按索引访问，用索引签名类型。

> [!warning] 泛型约束常写 `T extends object`
> 用来排除原始类型，保证传入的是"可挂属性的对象"：
> ```ts
> function merge<T extends object>(a: T, b: Partial<T>): T { /* ... */ }
> ```

---

## 三、与其他类型的关系

| 关系 | 说明 |
| --- | --- |
| 各种对象 / 数组 / 函数 / 实例 → `object` | ✅ |
| 原始类型 → `object` | ❌（严格模式下） |
| `object` → `unknown` / `any` | ✅ |
| `object` → 具体 interface | ❌ 需断言或收窄 |
| 与接口 `interface` | `object` 只说"是对象"，不描述形状 |
| 与 `Record` / 索引签名 | 后者更实用（可取键） |

---

## 四、小结

| 项目 | 内容 |
| --- | --- |
| 所属层级 | 对象类型（Object） |
| 关键字 | `object` |
| 含义 | 任意非原始值 |
| 不包含 | `boolean`/`number`/`string`/`void`/`undefined`/`null`/`symbol`/`bigint` |
| 能否取成员 | ❌ 太宽，取不到 |
| 常见用途 | 泛型约束 `T extends object` |
| 更好的替代 | [[interface]]（描述形状）、`Record<K, V>`（字典） |

---

## 相关笔记

- [[interface]] —— 精确描述对象形状的方式
- [[array]] / [[tuple]] —— 也都是对象
- [[any]] / [[unknown]] —— 比它更宽的顶层类型
- [[README|类型笔记总览]]

参考：TypeScript 官方手册 —— `object` vs `{}` vs `Object`；TS 2.2 Release Notes
