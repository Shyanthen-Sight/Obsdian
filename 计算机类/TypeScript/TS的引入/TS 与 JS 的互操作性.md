# TS 与 JS 的互操作性

> [!abstract] 一句话
> 因为 ==类型在编译后被完全擦除==，TS 和 JS 本质是"同一门语言的两种写法"，所以能**在同一项目里共存、互相引用**。互操作的核心就两件事：==**让 TS 读懂 JS**（`allowJs` / `checkJs` / JSDoc / `.d.ts`）== 和 ==**让 JS 场景平滑接入 TS**（渐进迁移）==。

---

## 一、为什么能互操作：类型擦除

```text
   a.ts  ──tsc──▶  a.js         类型注解、interface、type 全被删掉
   b.ts  ──tsc──▶  b.js         （enum / 装饰器除外）
                    │
                    ▼
    运行时的世界只有 JS —— 大家讲的是同一种语言
```

> [!info] 由此推出一条铁律
> **TS 编译产物是标准 JS**，所以：
> - TS 编译出的 `.js` 能被任意 JS 引用；
> - 任意 JS 模块也能被 TS `import` —— 只是 TS 需要"知道它的类型长什么样"。
> 互操作问题的本质，就是**如何把 JS 的类型信息告诉 TS**。

---

## 二、让 TS 读懂项目里的 JS

### 2.1 `allowJs`：允许把 `.js` 一起编译

```jsonc
{
  "compilerOptions": {
    "allowJs": true   // 让 .js 参与编译并输出到 outDir
  }
}
```

- 用途：**老项目里 JS 与 TS 混装**，让整个目录都能被 `tsc` 处理。
- 注意：它**不检查** JS 里的类型，只是"让 JS 也能过一趟编译器"。

### 2.2 `checkJs`：连 JS 也检查类型

```jsonc
{
  "compilerOptions": {
    "allowJs": true,
    "checkJs": true   // 在 JS 文件里也做类型检查
  }
}
```

> [!success] 这是"给 JS 加类型安全带"的关键开关
> 打开后，`.js` 文件同样会报类型错误——但**前提是 TS 能从代码或注释里推断出类型**。
> 想让检查更准，就给 JS 加 **JSDoc 类型注释**（见下）。

### 2.3 按文件开关：`// @ts-check` 与 `// @ts-nocheck`

不想全项目 `checkJs`，可以**逐个文件**控制：

```js
// @ts-check          ← 本文件开启类型检查（即使 checkJs 未开）

/** @type {number} */
let count = 0;

// @ts-nocheck         ← 本文件跳过检查（即使 checkJs 已开）
```

### 2.4 JSDoc：给 JS 写类型，TS 看得懂

TS 能解析 JSDoc 注释里的类型，于是**不用改写成 `.ts` 也能获得类型检查与补全**：

```js
/**
 * 两数相加
 * @param {number} a
 * @param {number} b
 * @returns {number}
 */
function add(a, b) {
    return a + b;
}

/** @type {{ id: number, name: string }} */
const user = { id: 1, name: "Ada" };
```

> [!tip] JSDoc 的常见标签
> - `@param {T} name` —— 参数类型
> - `@returns {T}` —— 返回值类型
> - `@type {T}` —— 变量类型
> - `@typedef {T} Name` —— 定义类型别名
> - `@template T` —— 泛型参数
> - `{T}` 里可用 `?T`（可选）、`!T`（非空）、`T[]`、联合 `A|B`

> [!note] 什么时候用 JSDoc 而不是 `.ts`？
> - 团队/工具链暂时不能上 TS，但想先要类型检查；
> - 要发布的**纯 JS 库**，靠 JSDoc + `checkJs` 保证内部质量，同时产出 `.d.ts`。
> 需要大量类型体操时，还是 `.ts` 更顺手。

### 2.5 `.d.ts` 声明文件：只描述类型，不产代码

当 TS 引用的 JS 模块**没有类型**时，就写一个**声明文件**告诉它"这个模块长什么样"：

```ts
// types/legacy.d.ts
declare module "legacy-lib" {
    export function doThing(input: string): number;
    export const version: string;
}
```

```ts
import { doThing } from "legacy-lib";   // 有了 .d.ts，这里的用法就能被检查
```

> [!info] `.d.ts` 的特点
> - **只有类型，没有实现**，编译后不产生任何 JS。
> - 用来给**无类型的第三方库 / 全局变量 / 老代码**补类型。
> - 库作者可在 `tsconfig` 开 `"declaration": true`，让 `tsc` **自动生成** `.d.ts` 一起发布；使用者就能获得类型。

### 2.6 `@types/*`：社区已经写好的声明

大多数常用库的类型，别人已经写好并发布在 **DefinitelyTyped** 上：

```bash
npm install --save-dev @types/node       # Node 内置模块类型
npm install --save-dev @types/lodash     # lodash
npm install --save-dev @types/express    # express
```

> [!tip] 判断顺序
> 1. 包**自带**类型？→ 直接可用（看它 `package.json` 的 `types` / `typings` 字段）。
> 2. 没有？→ 装 `@types/包名`。
> 3. 也没有？→ 自己写 `xxx.d.ts`，或临时 `declare module "xxx";`（快速消错）。

### 2.7 快速消错的逃生舱

| 写法 | 作用 | 场合 |
| --- | --- | --- |
| `any` | 关闭该值的类型检查 | 临时，别滥用 |
| `unknown` | 安全版 `any`，用前必须收窄 | ==更推荐== |
| `// @ts-ignore` | 忽略**下一行**的编译错误 | 应急，不推荐长期留 |
| `// @ts-expect-error` | 预期此处**应当报错**，否则反过来报警 | 测试/兼容垫片，比上一条好 |
| `// @ts-nocheck` | 整个文件不检查 | 迁移过渡期 |

> [!warning] 逃生舱是"止血"，不是"治病"
> 大量 `any` / `@ts-ignore` 会让类型系统形同虚设。每留一个，最好加注释说明原因与 TODO。

---

## 三、反向：TS 产物被 JS 使用

TS 编译出的就是普通 JS，所以 **JS 侧完全无需知道有 TS 存在**：

```text
lib.ts ──tsc（declaration: true）──▶ lib.js  +  lib.d.ts
                                       │          │
                               JS 项目直接 require/import     JS 项目靠 .d.ts 获得类型提示
```

- 做**库**时开 `declaration: true`，让消费者既有 JS 用、又有类型提示。
- 模块格式要对齐：`module` 输出 `CommonJS` 还是 `ESNext`，取决于消费者怎么引（见下节）。

---

## 四、模块格式的坑：`import` 与 `require` 互操作

JS 有 **CommonJS**（`require` / `module.exports`）和 **ES Module**（`import` / `export`）两套模块系统，TS 要能同时应付：

```jsonc
{
  "compilerOptions": {
    "esModuleInterop": true,               // ★ 让 import x from "cjs 包" 更自然
    "allowSyntheticDefaultImports": true,  // 类型层面允许"合成的默认导入"
    "module": "ESNext",                     // 产出的模块格式
    "moduleResolution": "bundler"           // 解析策略：node / node16 / bundler
  }
}
```

> [!question] 为什么开了 `esModuleInterop` 就能 `import express from "express"`？
> `express` 是 CommonJS 模块，本没有 `default` 导出。这个选项让 TS 在编译时**自动包一层互操作辅助**，把 `module.exports` 当成默认导出来对待，于是写法自然、类型也对。

> [!warning] 常见报错
> - `esModuleInterop` 关了却写 `import x from "cjs 包"` → 报"模块没有默认导出"。**开 `esModuleInterop`**。
> - Node 环境下用 `.mts` / `.cts` / `"type": "module"` 组合时，推荐 `"module": "NodeNext"` + `"moduleResolution": "NodeNext"`，让 TS 严格跟随 Node 的解析规则。

---

## 五、渐进迁移：从 JS 项目一步步走向 TS

> [!success] 迁移原则：**不求一次到位，只求始终可运行**
> 每一步结束都应能编译、能跑、能提测。逐个文件替换，而不是推倒重来。

推荐路线：

1. **打地基**：装 `typescript`，`tsc --init`；先配 **宽松** 配置（`strict: false`），确保现有 JS 全部能编译。
2. **纳入 JS**：开 `allowJs: true`，让整个目录进入 `tsc` 视野（
   `outDir` / `include` 配好，避免把无关文件卷进来）。
3. **先检查、后改动**：开 `checkJs: true`（或逐文件 `// @ts-check`），用 JSDoc 补关键类型，看看有多大窟窿。
4. **逐个改名**：挑**叶子文件**（依赖少、被依赖少）先 `.js → .ts`，一次一个，改完即验证。
5. **补类型**：给无类型依赖装 `@types/*` 或写 `.d.ts`；把 `any` 逐步换成精确类型。
6. **逐步收紧**：等报错清零，再按项打开 `strict` 子开关（先 `strictNullChecks`、`noImplicitAny`），最后整体 `strict: true`。

```text
宽松配置 ──▶ allowJs ──▶ checkJs + JSDoc ──▶ 逐文件改 .ts ──▶ 补 .d.ts ──▶ 收紧 strict
  (能跑)      (混装)         (先看见问题)         (渐进替换)      (补全类型)     (收口)
```

> [!tip] 实用技巧
> - 用 `// @ts-nocheck` 给暂时改不动的文件"打补丁"，留 TODO，别删。
> - `tsc --noEmit` 放进 CI，保证类型只向好的方向走。
> - 迁移期间 `noImplicitAny` / `strict` 可先关，**但 `strictNullChecks` 建议尽早开**，收益最大。

---

## 六、一张表看懂：谁给谁提供类型

| 场景 | 谁需要类型 | 靠什么提供 | 关键配置 / 命令 |
| --- | --- | --- | --- |
| 项目内 `.js` 被 `.ts` 引用 | TS 编译器 | 推断 + JSDoc | `allowJs` / `checkJs` |
| 引用**自带的类型**的库 | TS | 包内 `.d.ts` | 无需配置（看 `types` 字段） |
| 引用**无类型**的第三方库 | TS | `@types/*` | `npm i -D @types/xxx` |
| 引用**谁都没写**的库 | TS | 自己写 `.d.ts` | `declare module "xxx" { ... }` |
| 发布库给他人 | JS 使用者 | 编译时产 `.d.ts` | `"declaration": true` |
| CommonJS 包用 `import` | TS | 互操作辅助 | `esModuleInterop` |
| 老项目迁往 TS | 团队 | 渐进流程 | `allowJs` → `checkJs` → 改名 → 收紧 |

---

## 相关笔记

- [[TypeScript vs JavaScript]] —— 类型擦除、超集关系（互操作的地基）
- [[安装与配置]] —— `tsconfig.json` 各项配置的含义

---

参考：TypeScript 官方手册 —— Migrating from JavaScript / JSDoc Reference / Modules Reference；DefinitelyTyped 仓库
