# TypeScript vs JavaScript

> [!abstract] 一句话
> ==TypeScript 是 JavaScript 的**超集**==：**JS 有的它全有，还额外加了一套静态类型系统**。它**不能被浏览器或 Node 直接运行**，要先**编译**成普通 JS；而类型只存在于编译期，运行时被**完全擦除**（type erasure）。

---

## 一、先看关系：超集，而不是替代

```text
          TypeScript
   ┌────────────────────────────┐
   │  类型注解 / 接口 / 泛型      │  ← TS 独有的"增量"
   │  枚举 / 访问修饰符 / 装饰器   │
   │  ┌──────────────────────┐  │
   │  │      JavaScript       │  │  ← JS 原有的全部内容
   │  │  变量 · 函数 · 对象 · 类 │  │
   │  └──────────────────────┘  │
   └────────────────────────────┘
                │  tsc 编译（同时做类型擦除）
                ▼
           纯 JavaScript  ──→  浏览器 / Node 运行
```

> [!info] 三句话定性
> - **超集**：`JavaScript ⊂ TypeScript`。任何合法的 JS 基本就是合法的 TS。
> - **开发期工具**：TS 自己不被执行，**跑起来的永远是它编译出的 JS**。
> - **类型擦除**：编译后所有类型信息消失，**运行时零类型开销**，类型不会变成函数或对象。

> [!warning] 一个常见误区
> "TypeScript 是一种运行在浏览器里的语言" —— **错**。浏览器只认 JS（以及 JS 的方言如 WASM）。
> TS 只是"写 JS 时的一层检查 + 语法糖"，最终产物仍是 JS。它更像 **JavaScript + 静态类型检查（+ 未来语法）**。

---

## 二、逐项对比

| 维度 | JavaScript | TypeScript |
| --- | --- | --- |
| 类型系统 | 动态类型，运行时才查 | ==静态类型，编译期就查== |
| 能否直接运行 | ✅ 浏览器 / Node 直接执行 | ❌ 必须先编译成 JS |
| 文件后缀 | `.js` / `.mjs` / `.cjs` | `.ts` / `.tsx` |
| 类型注解 | 无 | `let n: number` |
| 接口 / 泛型 / 枚举 | 无 | `interface` / `<T>` / `enum` |
| 访问修饰符 | 无（`#private` 字段是运行时私有） | `public` / `private` / `protected` |
| 空值安全 | 无，`null`/`undefined` 随时炸 | `strictNullChecks` 把空值变成显式类型 |
| 错误发现时机 | **运行时**（用户可能先遇到） | **编译时**（保存/构建时就报） |
| IDE 补全 / 重构 | 靠推断，较弱 | 强，类型驱动 |
| 学习成本 | 低 | 多一层类型语法与概念 |
| 生态 | 全部 | ==可用，但部分老库需 `@types/xxx` 补类型== |
| 由谁维护 | ECMA（TC39 标准） | Microsoft 开源（2012 年发布，Anders Hejlsberg 主导） |

> [!tip] 一句话记差别
> **JS 把类型检查留到运行时，TS 把它提前到编译时。**
> 代价是多一个"编译"步骤，收益是把一整类 bug 挡在上线之前。

---

## 三、TypeScript 多出来的能力

这些都是 **JS 语法里没有、只有 TS 提供**的东西（且写起来像语言特性，本质仍是编译期约束）：

### 3.1 静态类型与类型推断

```ts
let n: number = 1;          // 显式注解
let s = "hello";            // 推断为 string
// s = 42;                  // ❌ 编译错误：number 不能赋给 string

function add(a: number, b: number): number {
    return a + b;
}
```

### 3.2 接口（interface）与类型别名（type）

```ts
interface User {
    id: number;
    name: string;
    email?: string;            // 可选属性
}

const u: User = { id: 1, name: "Ada" };
```

### 3.3 泛型（Generics）

```ts
function first<T>(arr: T[]): T | undefined {
    return arr[0];
}
first<number>([1, 2, 3]);      // number | undefined
first<string>(["a"]);          // string | undefined
```

### 3.4 联合类型 / 交叉类型 / 字面量类型

```ts
type Status = "idle" | "loading" | "done";   // 字面量联合，拼错就报错
type Dir = "up" | "down" | "left" | "right";
```

### 3.5 其余常用特性

- **`enum` 枚举**：给一组命名常量。
- **访问修饰符**：`private` / `protected` / `public`，以及 `readonly`。
- **抽象类 `abstract`**、**装饰器 `@decorator`**（需相应配置）。
- **类型收窄（narrowing）**：`typeof` / `instanceof` / `in` 判断后自动缩小类型。
- **`unknown` / `never` / `any`**：更精细的"类型安全出口"。

> [!note] 关键：这些"特性"大多在编译后**消失**
> `interface`、`type`、泛型参数、类型注解 —— 擦除后不产生任何运行时代码。
> 例外：`enum` 会编译出真实对象（这也是它与联合类型的一个取舍点），带装饰器的类会有额外产物。

---

## 四、TypeScript 的代价

| 代价 | 说明 | 缓解方式 |
| --- | --- | --- |
| 需要编译步骤 | 多一道 `tsc` / 打包环节 | 用 `tsx` / `esbuild` / Vite 等，快且可监听 |
| 类型报错会挡路 | 严格模式下老代码可能报一堆错 | 先用宽松配置，逐步收紧（见 [[安装与配置]]） |
| 学习曲线 | 泛型、条件类型等进阶概念较陡 | 从注解 + 接口起步 |
| 类型定义缺失 | 部分旧库没有类型 | 装 `@types/xxx` 或自己写 `.d.ts`（见 [[TS 与 JS 的互操作性]]） |
| 构建耗时 | 大型项目 `tsc` 全量检查变慢 | `incremental` / 项目引用 / 只做 `--noEmit` 检查 |

> [!success] 但总体来说
> 项目越大、参与人越多，**类型带来的收益越明显**：重构敢动、接口即文档、错误提前暴露。
> 小脚本、一次性 Demo 里，裸 JS 反而更省事——**TS 不是无条件更好，而是"规模越大越值"**。

---

## 五、它们如何"共存"

这不是二选一的阵营之争，实际项目里常是这样相处的：

- **TS 就是 JS 的扩展**：把 `x.js` 改名 `x.ts`，先不改任何代码也能用（大部分情况下）。
- **可以混用**：TS 项目里允许存在 `.js` 文件，也能反过来给 JS 加类型检查（`checkJs`）。
- **互操作**：JS 模块能被 TS 引用，TS 编译产物也能被 JS 引用——详见 [[TS 与 JS 的互操作性]]。
- **迁移是渐进的**：老 JS 项目可一个文件一个文件地改，不必推倒重来。

> [!quote] 一句话记忆
> **TypeScript = JavaScript + 静态类型系统 + 编译步骤**。
> JS 管"运行时长什么样"，TS 管"写代码时就别出错"；==类型是开发期的安全带，编译后即被摘下==。

---

## 相关笔记

- [[安装与配置]] —— 如何装 TypeScript、`tsconfig.json` 怎么配、怎么编译
- [[TS 与 JS 的互操作性]] —— 二者如何在同一项目里混用与互相引用

---

参考：TypeScript 官方手册 —— TypeScript for JavaScript Programmers / TypeScript for the New Programmer
