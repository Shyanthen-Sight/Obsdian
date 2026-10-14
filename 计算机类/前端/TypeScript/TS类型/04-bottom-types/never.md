# never

> [!abstract] 一句话定义
> `never` 是**底层类型**：它表示"**永远不会发生的值**"——==一个空集，没有任何值属于它；反过来它却可以赋给任何类型==。

---

## 一、基本用法

**场景一：抛异常 / 死循环的函数"永不返回"**

```ts
function fail(msg: string): never {
  throw new Error(msg)
}

function infinite(): never {
  while (true) {}          // 永不返回
}

// 注意区分：void 表示"返回 undefined"，never 表示"根本不返回"
```

**场景二：穷尽检查（exhaustiveness check）**——`never` 最有价值的用途：

```ts
type Shape = { kind: 'circle'; r: number } | { kind: 'square'; s: number }

function area(shape: Shape): number {
  switch (shape.kind) {
    case 'circle': return Math.PI * shape.r ** 2
    case 'square': return shape.s ** 2
    default:
      const _exhaustive: never = shape   // ✅ 全处理完时 shape 收窄为 never
      throw new Error(`unhandled: ${_exhaustive}`)
  }
}
// 将来给 Shape 加了新分支却忘了处理 → 这里立刻编译报错
```

**场景三：条件类型的"空结果"**（类型层面的运算产物）

```ts
type Exclude<T, U> = T extends U ? never : T
type A = Exclude<'a' | 'b' | 'c', 'a'>    // 'b' | 'c'
```

---

## 二、常见场景与注意事项

- **穷尽性检查**：保证 `switch`/`if` 覆盖了联合的所有分支（加一个分支，旧代码立刻报错）。
- 表达"该函数**不可能正常返回**"（抛错、断言失败、无限循环）。

> [!tip] 穷尽检查是 `never` 的头号用法
> 给 `default` 分支赋一个 `never` 变量，就把"漏处理分支"从运行时错误**提前成了编译错误**。

> [!warning] `never` 与 `void` 的区别
> - `void`：函数**会返回**，只是返回 `undefined`。
> - `never`：函数**永不返回**（抛错或死循环）。
> ```ts
> function a(): void  { /* 正常走到结尾，返回 undefined */ }
> function b(): never { throw new Error() }
> ```

> [!note] `never` 也常"意外出现"在报错里
> 当联合被排除到空、或条件类型分支取 `never` 时都会见到它。看到"类型为 `never`"往往意味着**某处收窄过度或分支写错**，值得回头查。

> [!warning] 除 `never` 外，没有类型能赋给 `never`
> 这正是它的价值：唯一能"恰好填满"一个 `never` 位置的，只有同样为 `never` 的东西。

---

## 三、与其他类型的关系

| 关系 | 说明 |
| --- | --- |
| `never` → 任意类型 | ✅（空集，不违反任何约束） |
| 任意类型 → `never` | ❌（唯一例外：`never` 自身） |
| `never` → `unknown` / `any` | ✅ |
| 联合 `T \| never` | 化简为 `T`（`never` 不贡献成员） |
| 交叉 `T & never` | 化简为 `never`（与空集相交为空） |
| 与 `void` | 都用于函数返回，但语义相反（见上） |
| 与 `any` | 两个极端：`any` 最宽、`never` 最窄 |

---

## 四、小结

| 项目 | 内容 |
| --- | --- |
| 所属层级 | 底层类型（Bottom Type） |
| 关键字 | `never` |
| 含义 | 空集：没有任何值属于它 |
| 取值 | **没有值**（不能写 `let x: never = ...`） |
| 赋值方向 | 可赋给一切；无人能赋给它 |
| 头号用途 | 穷尽性检查 |
| 常见搭档 | `switch` 的 `default`、抛错函数、条件类型 |
| 与 `void` 对比 | `void` 返回 `undefined`；`never` 根本不返回 |
| 与 `any` 对比 | `any` 是最宽端点，`never` 是最窄端点 |

---

## 相关笔记

- [[any]] / [[unknown]] —— 与之相对的顶层类型（最宽的端点）
- [[void]] —— 常被混淆的"无返回"类型
- [[string]] —— 联合类型的穷尽检查示例
- [[README|类型笔记总览]]

参考：TypeScript 官方手册 —— `never` / Exhaustiveness Checking / Conditional Types
