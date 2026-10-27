# void

> [!abstract] 一句话定义
> `void` 表示"**没有有意义的返回值**"——==它几乎只用在函数的返回类型上==，值本身只能是 `undefined`。

---

## 一、基本用法

```ts
function log(msg: string): void {
  console.log(msg)
  // 没有 return；即便 `return;` 也只能是裸 return
}

const f = (): void => {}          // 返回 void 的箭头函数

// void 类型的变量只能接 undefined
let v: void = undefined
// let bad: void = null            // strict 下报错

// 泛型参数里的 void（如 Promise<void>）
function save(): Promise<void> {
  return Promise.resolve()
}
```

---

## 二、常见场景与注意事项

- **只为副作用的函数**：日志、事件处理、`setTimeout` 回调。
- **`Promise<void>`**：只关心"完成了"、不关心结果。

> [!tip] `void` 让回调"不关心返回值"成为合法
> 因为 `void` 作为**回调返回类型**时有一条特殊规则：**任何返回值都会被忽略**，所以下面这种写法合法——
> ```ts
> type Handler = () => void
> const h: Handler = () => 123      // ✅ 返回 number 也允许
> // 常用于 Array.prototype.forEach 之类"返回值没意义"的场景
> ```
> 这条规则是 `void` 最容易被误解的地方：**它放宽的是"函数作为值时"的返回类型兼容**，而不是普通赋值。

> [!warning] `void` 变量不等于 `undefined` 类型
> `let v: void` 只能赋 `undefined`；但 `undefined` 是独立类型（见 [[undefined]]）。二者在返回位置上关联，在赋值位置上不等价。

> [!note] `void` 不能当真"用"
> 对 `void` 类型的值做属性访问、运算都不行——它就是个"这里没有值"的标记。

---

## 三、与其他类型的关系

| 关系 | 说明 |
| --- | --- |
| `undefined` → `void` | ✅（`void` 变量可赋 `undefined`） |
| `void` → `undefined` | ❌ |
| `void` → `unknown` / `any` | ✅（当作一个值传递时，实际是 `undefined`） |
| 函数返回 `void` | 可被赋给返回任意类型的函数变量（见上 tip） |
| 与 `never` 的区别 | `void` 函数**会返回**（返回 `undefined`）；`never` 函数**永不返回** |

---

## 四、小结

| 项目 | 内容 |
| --- | --- |
| 所属层级 | 原始类型（Primitive） |
| 关键字 | `void` |
| 主要用途 | 函数返回类型（无返回值） |
| 变量取值 | 仅 `undefined` |
| 特殊规则 | 作为回调返回类型时，任意返回值均被允许 |
| 常见搭档 | `Promise<void>` |
| 易混类型 | `undefined`（独立类型）、`never`（永不返回） |

---

## 相关笔记

- [[undefined]] —— `void` 变量实际持有的值
- [[never]] —— "永不返回"，与 `void` 相对
- [[README|类型笔记总览]]

参考：TypeScript 官方手册 —— Function Types / Returning void
