# null

> [!abstract] 一句话定义
> `null` 只有一个值 `null`，表示"**明确的空**"——==它是需要显式开启 `strictNullChecks` 才会被当回事的独立类型==。

---

## 一、基本用法

```ts
let n: null = null

// 想同时接受 null，必须写进联合类型
let maybe: string | null
maybe = null                  // ✅
maybe = 'ok'                  // ✅

// 与可选属性组合
interface User {
  name: string
  email: string | null        // 字段存在，但可为"空"
}

// 处理：先判断再使用
function upper(s: string | null): string {
  if (s === null) return ''
  return s.toUpperCase()
}
```

---

## 二、常见场景与注意事项

- **接口返回的"空值"**：后端常用 `null` 表示"字段存在但为空"，用 `undefined` 表示"字段没有"。二者语义要跟团队约定。
- **明确置空**：如清空 DOM 引用、断开连接后把变量设为 `null`。

> [!warning] `null` 与 `undefined` 的区别
> - `undefined`：**缺席**（没赋值、没这个字段）。`typeof undefined === 'undefined'`。
> - `null`：**明说的空**。`typeof null === 'object'`（这是 JS 的历史 bug）。
> 严格模式下**二者互不赋值**：`string | undefined` 不接受 `null`，反之亦然。

> [!tip] 用 `??` 统一兜底二者
> `??`（空值合并）只在 **`null` 或 `undefined`** 时取右值；而 `||` 会在 `0`、`''`、`false` 时也取右值——处理空值优先用 `??`。
> ```ts
> const a = value ?? 'default'    // ✅ 只兜 null/undefined
> const b = 0 || 'default'        // ⚠️ 得 'default'
> ```

> [!warning] 比较用 `===`
> `null == undefined` 为 `true`（宽松相等），`null === undefined` 为 `false`。判断"是否为空"时想两者通吃，可用 `x == null`（会同时命中 `null` 和 `undefined`），但要注意这是**罕见的有意使用宽松相等**的场景。

> [!note] `strictNullChecks` 关闭时
> `null` 可赋给任何类型，空值保护形同不存在——所以现代项目基本都开着 `strict`。

---

## 三、与其他类型的关系

| 关系 | 说明 |
| --- | --- |
| `null` → `null` | ✅ |
| `null` → `unknown` / `any` | ✅ |
| `null` → `string` 等 | ❌（`strictNullChecks` 开启时） |
| `null` 与 `undefined` | 严格模式下互不赋值；`x == null` 可同时判断 |
| 与 `void` | 无关，别混 |
| `typeof null` | `"object"`（JS 历史遗留） |

---

## 四、小结

| 项目 | 内容 |
| --- | --- |
| 所属层级 | 原始类型（Primitive） |
| 关键字 | `null` |
| 语义 | 明确的空 |
| 取值 | 仅 `null` |
| 受开关影响 | `strictNullChecks` |
| `typeof` 结果 | `"object"`（不是 `"null"`） |
| 常见搭档 | `??`、联合类型 `T \| null` |
| 易混类型 | `undefined`（缺席） |

---

## 相关笔记

- [[undefined]] —— 与之成对的"缺席"值
- [[never]] —— 底层类型，与 `null` 无赋值关系
- [[interface]] —— `T | null` 常写进对象字段
- [[README|类型笔记总览]]

参考：TypeScript 官方手册 —— `strictNullChecks`；MDN —— null
