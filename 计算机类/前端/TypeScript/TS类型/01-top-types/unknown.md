# unknown

> [!abstract] 一句话定义
> `unknown` 是**类型安全的"任何值"**：什么都能赋给它，但在**使用之前必须先收窄**成具体类型——==它是 `any` 的安全版替代品==。

---

## 一、基本用法

```ts
let u: unknown = 1
u = 'hello'          // ✅ 换类型没问题
u = { a: 1 }         // ✅

// u.foo              // ❌ 报错：对象类型为 unknown
// u()                // ❌ 报错：不能调用 unknown
// u + 1              // ❌ 报错：不能算术运算
```

**用之前必须先收窄**（类型守卫）：

```ts
let u: unknown = getInput()

if (typeof u === 'string') {
  u.toUpperCase()          // ✅ 收窄成 string 了
}

if (typeof u === 'number') {
  u.toFixed(2)             // ✅ 收窄成 number
}

if (Array.isArray(u)) {
  u.length                 // ✅ 收窄成 any[]（配合断言可更精确）
}
```

也可以**断言**（由你担保类型，编译器不再追问）：

```ts
const u: unknown = JSON.parse(json)
const user = u as { name: string }
user.name
```

---

## 二、常见场景与注意事项

**典型场景**

- **接收外部输入**：`JSON.parse`、接口响应、`localStorage`、用户输入——先用 `unknown` 兜住，再校验。
- **catch 子句变量**：`catch (e: unknown)`（TS 4.4+ 默认即 `unknown`），逼你先判断 `e instanceof Error`。
- **泛型/工具类型**里的安全占位。

> [!tip] 处理 `unknown` 的推荐姿势
> 写一个**类型守卫函数**把 `unknown` 收窄，而不是到处 `as`：
> ```ts
> function isUser(v: unknown): v is { name: string } {
>   return typeof v === 'object' && v !== null && 'name' in v
> }
> if (isUser(u)) u.name   // ✅
> ```

**注意事项**

> [!warning] `unknown` 不能直接参与任何操作
> 除赋值、收窄、断言外，属性访问、调用、运算**全部报错**——这正是它安全的原因：==不检查清楚就不让你用==。

> [!note] `unknown` 也可以被"缩小"
> `unknown & { a: number }` 会变成 `{ a: number }`（交叉类型收窄未知值），这是高级写法，少用。

---

## 三、与其他类型的关系

| 关系 | 说明 |
| --- | --- |
| 任意类型 → `unknown` | ✅ 都能赋进来（它是所有类型的"上游"） |
| `unknown` → `any` | ✅ |
| `unknown` → `unknown` | ✅ |
| `unknown` → 具体类型 | ❌ **必须先收窄或断言** |
| `unknown` → `never` | ❌ |
| 与 `any` 的差别 | 都能接任何值；但 `any` 可**直接用**，`unknown` **必须先收窄** |

> [!tip] 一句话记牢
> **收进来看 `any` 和 `unknown` 一样宽；取出来用 `any` 随便用、`unknown` 得先证明。**

---

## 四、小结

| 项目 | 内容 |
| --- | --- |
| 所属层级 | 顶层类型（Top Type） |
| 关键字 | `unknown` |
| 核心特征 | 可接收一切，使用前须收窄 |
| 与 `any` 的关键差别 | 安全性：`unknown` 用前必须收窄 |
| 常见场景 | 外部输入、`catch (e)`、动态数据校验 |
| 推荐替代 | 优先用 `unknown` 取代 `any` |
| 相关开关 | `useUnknownInCatchVariables`（`strict` 的一部分） |

---

## 相关笔记

- [[any]] —— 关掉检查的版本，`unknown` 的风险对照
- [[never]] —— 底层类型，`unknown` 的"反极"
- [[README|类型笔记总览]]

参考：TypeScript 官方手册 —— `unknown` / Type Guards；TS 4.4 Release Notes —— `useUnknownInCatchVariables`
