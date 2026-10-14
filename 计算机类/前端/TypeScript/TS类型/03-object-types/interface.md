# interface

> [!abstract] 一句话定义
> `interface` 用来**描述一个对象应该长什么样**（有哪些属性、什么类型、能调用什么）——==它是"结构契约"，只看形状、不看来源==（结构类型 / 鸭子类型）。

---

## 一、基本用法

```ts
interface User {
  id: number
  name: string
  age?: number                 // 可选属性
  readonly createdAt: string   // 只读属性
  greet(msg: string): void     // 方法
}

const u: User = {
  id: 1,
  name: 'Alice',
  createdAt: '2026-01-01',
  greet(msg) { console.log(msg) },
}

// 扩展
interface Admin extends User {
  permissions: string[]
}

// 函数类型也可用 interface 描述
interface Comparator {
  (a: number, b: number): number
}
// 或用更常见的类型别名写法
type Comparator2 = (a: number, b: number) => number
```

---

## 二、常见场景与注意事项

- **给对象、函数、类形状**命名；团队协作里充当"数据结构约定"。
- 描述"只要满足这些成员就接受"的参数（**结构类型**）：

```ts
function print(p: { x: number; y: number }) {}
print({ x: 1, y: 2, extra: 3 })   // ⚠️ 对象字面量会做多余属性检查 → 报错
```

> [!tip] `interface` vs `type`
> 二者绝大多数场景可互换。差异点：
> - `interface` **可声明合并**（同名 interface 自动合并）、可 `extends` 多个；
> - `type` 能表示**联合、交叉、条件、映射**等 interface 表示不了的类型。
> 约定：描述对象形状用 `interface`，需要联合/别名/高级类型用 `type`。

> [!warning] 多余属性检查只针对字面量
> 直接传对象字面量时，多出的属性会报错；但先把对象赋给变量再传，就**不检查多余属性**了（结构类型只要求"至少有"）。

> [!note] `interface` 描述的是**形状**而非**实现**
> 任何恰好满足这些成员的普通对象，都能赋给该 interface——不需要 `new`、不需要继承关系。

> [!tip] 只读与索引签名
> ```ts
> interface Dict {
>   readonly [key: string]: number   // 任意字符串键 → number
> }
> ```

---

## 三、与其他类型的关系

| 关系 | 说明 |
| --- | --- |
| 结构匹配的对象 → `interface` | ✅ 只要成员"至少齐备"即可 |
| `interface` → 其成员更少的对象类型 | ✅（协变放宽） |
| `interface` → `unknown` / `any` | ✅ |
| `interface` 与 `class` | 类可 `implements` 接口；类的实例满足接口形状 |
| `interface` 与 `object` | 都描述非原始值；`object` 只说"非原始"，`interface` 精确描述形状 |
| 与联合 / 映射类型 | ❌ interface 不能表达，需改用 `type` |

---

## 四、小结

| 项目 | 内容 |
| --- | --- |
| 所属层级 | 对象类型（Object） |
| 关键字 | `interface` |
| 用途 | 描述对象/函数/类的结构契约 |
| 结构类型 | 是（鸭子类型，只看形状） |
| 可扩展 | `extends`（多继承）、声明合并 |
| 可选 / 只读 | `?` / `readonly` |
| 与 `type` 的取舍 | 对象形状用 `interface`，高级类型用 `type` |

---

## 相关笔记

- [[class]] —— 类可实现接口
- [[object]] —— "任意非原始值"的粗略类型
- [[array]] —— 数组也是对象类型
- [[README|类型笔记总览]]

参考：TypeScript 官方手册 —— Interfaces / Type Aliases
