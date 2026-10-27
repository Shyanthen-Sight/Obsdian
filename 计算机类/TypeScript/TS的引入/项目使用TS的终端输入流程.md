

> [!abstract] 一句话
> 在一个**空文件夹**里从零跑起 TypeScript，终端里真正要敲的核心就四步：==`npm init` 立项目 → `npm i -D typescript` 装编译器 → `npx tsc --init` 出配置 → `npx tsc`（或 `npx tsx`）编译运行==。
> 本文按**输入顺序**把每一步的**命令、动作、终端回显与分支**串成一条流水线，作为"照着敲即可"的手册；每一步背后的配置含义另见 [[安装与配置]]。

---

## 一、全景：一条命令流水线

```text
空文件夹
   │
   │ ① node -v / npm -v        ← 确认环境（本机有没有 Node）
   ▼
npm init -y                    ← 生成 package.json
   │
   ▼
npm i -D typescript            ← 把编译器装进 devDependencies
   │
   ▼
npx tsc --init                 ← 生成 tsconfig.json
   │
   ▼
写 src/index.ts                ← 你的第一段 TS 代码
   │
   ├── npx tsc      → dist/index.js → node dist/index.js   ② 编译再跑
   ├── npx tsx src/index.ts                                ③ 直接跑
   └── 交给 Vite/webpack（tsc --noEmit 只查类型）            ④ 打包器跑
   ▼
跑起来了
```

> [!tip] 顺序背后的道理
> `npm init` 只**建立 npm 项目身份**（生成 `package.json`），有了它 `npm i` 才有依赖清单可写；编译器装好后**终端里才存在 `tsc` 命令**，也才谈得上 `tsc --init` 生成配置。
> 每一步都是下一步的前提——==顺序不能乱==。

> [!note] 命令在哪个终端敲都一样
> `node` / `npm` / `npx` 在 **CMD、PowerShell、Git Bash** 里写法相同，本文统一用 bash 代码块展示。唯一差别是**换行续行、路径写法**等 shell 细节。

> [!info] 已经用脚手架了呢？
> 若项目是 `npm create vite@latest`（或 Next、Angular CLI 等）生成的，**第 1~3 步它都替你做了**——脚手架一装好就自带 `package.json`、`typescript`、`tsconfig.json`。此时直接从**第 4 步写代码**开始；本文剩下的部分用来理解"它到底替我敲了什么"。

---

## 二、第 0 步：确认环境

```bash
node -v      # 例：v20.11.0
npm -v       # 例：10.2.4
```

- **两个都出版本号** → 环境就绪，进下一步。
- 报 `不是内部或外部命令` / `command not found` → 本机还没装 Node.js，去 [nodejs.org](https://nodejs.org) 装 **LTS** 版。

> [!warning] 装完 Node 记得**重开终端**
> 安装程序改的是系统 PATH，**已经打开的终端窗口读不到新值**。
> 关掉重开（或重启编辑器），`node -v` 才会生效。

---

## 三、第 1 步：初始化项目

```bash
npm init -y
```

生成的 `package.json`（节选）：

```json
{
  "name": "my-ts-app",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "license": "ISC"
}
```

> [!tip] `-y` 是什么
> `-y`（= `--yes`）表示**全部接受默认值**，不再逐项询问包名、版本、入口……
> 想交互式逐项填写，就敲裸 `npm init`。

> [!warning] 已有 `package.json` 时**直接跳过本步**
> 重复 `npm init` 会覆盖现有文件。判断方法：`ls package.json`（或 `dir`）看它是否已存在。

---

## 四、第 2 步：安装 TypeScript

```bash
npm i -D typescript        # 等价于 npm install --save-dev typescript
```

终端回显大致：

```text
added 1 package, and audited 2 packages in 1s
found 0 vulnerabilities
```

装完后两处变化：
1. `package.json` 多出 `"devDependencies": { "typescript": "^5.4.5" }`；
2. 编译器落地在 `node_modules/typescript`，`tsc` 命令随之可用。

**验证：**

```bash
npx tsc --version          # Version 5.4.5
```

> [!tip] 为什么用 `-D`（devDependencies）
> TS 只在**开发和构建期**干活，产物是 `.js`，**运行时不需要它** → 放 `devDependencies`。
> 同理 `npx tsc` **优先用本地版本**，不会误用全局的旧版。

> [!warning] 统一敲 `npx tsc`，别敲裸 `tsc`
> 本地安装的编译器**不会进入全局 PATH**，直接敲 `tsc` 很可能报"不是内部或外部命令"。
> 两种正解：用 `npx tsc`；或把命令写进 `package.json` 的 `scripts` 再用 `npm run`。

---

## 五、第 3 步：生成配置文件

```bash
npx tsc --init
```

- 在当前目录生成一份**带注释的** `tsconfig.json`。
- 想确认实际生效内容：`npx tsc --showConfig`（会展开 `extends`，显示合并后的最终配置）。

> [!warning] `--init` **不会覆盖**已存在的 `tsconfig.json`
> 目录里已有同名文件时它会直接跳过。想换配置要么手动改，要么删掉重建。

> [!question] 装完包，为什么没自动生成 `tsconfig.json`？
> ==因为"装包"和"生成配置"是两件事==。`npm i typescript` 只装编译器，**tsconfig 是可选的**。
> 要它就得**显式**敲 `npx tsc --init`；或干脆自己新建一份粘贴进去（起步模板见 [[安装与配置]] 与 [[tsconfig.json]]）。

---

## 六、第 4 步：写第一个 TS 文件

```bash
mkdir src
```

```ts
// src/index.ts
const greet = (name: string): string => `Hello, ${name}!`;
console.log(greet("TypeScript"));
```

> [!note] 哪些文件算"用了 TS"
> 后缀是 `.ts` / `.tsx` / `.mts` / `.cts` 的都算；`.d.ts` 只描述类型、不产 JS。
> 项目里**源码、配置、脚本、测试**都能是 TS——完整清单见 [[安装与配置]] 第三节。

---

## 七、第 5 步：跑起来——三条分支

> [!info] 核心前提
> **TS 不能被 Node / 浏览器直接运行**，必须先"过一道"。区别只在于==这一道由谁来做==，于是分三条分支。

### 7.1 分支 A：`tsc` 编译 → 再运行

```bash
npx tsc                    # 按 tsconfig 编译 → 产出 dist/index.js
node dist/index.js         # 运行产物 → 输出 Hello, TypeScript!
```

```text
src/index.ts ──tsc──▶ dist/index.js ──node──▶ 运行
                └── 同时做类型检查、可产出 .js.map / .d.ts
```

适合**库、Node 服务、CI 构建**——自己掌控 `.ts → .js` 全过程，产物是真实文件、可发布。

### 7.2 分支 B：`tsx` 直接跑（不落盘）

```bash
npm i -D tsx               # 先装执行器（一次性）
npx tsx src/index.ts       # 直接运行 .ts，不产生 .js 文件
```

适合**本地脚本、开发调试、后端小服务**——省掉"先编译再运行"两步。
注意：它在**内存里转译**，==默认不做完整类型检查==；类型把关另跑 `npx tsc --noEmit`。

### 7.3 分支 C：交给打包器，`tsc` 只查类型

```bash
npx tsc --noEmit           # 只做"类型门禁"，不产文件
```

适合**前端应用（Vite / Next / webpack）**——产出由打包器（esbuild / swc）负责，TS 只当类型检查器。
tsconfig 里通常设 `"noEmit": true`，避免两套输出打架。

### 7.4 三条分支对照

| 分支 | 终端输入 | 产出 `.js` | 类型检查 | 典型场景 |
| --- | --- | --- | --- | --- |
| A `tsc` | `npx tsc` + `node dist/index.js` | ✅ 落盘 | ✅ 完整 | 库、Node、CI |
| B `tsx` | `npx tsx src/index.ts` | ❌ 不落盘 | ⚠️ 默认不做 | 脚本、开发调试 |
| C 打包器 | `npx tsc --noEmit` | ✅（bundle） | ✅ 靠 `--noEmit` | 前端应用 |

> [!success] 选型口诀
> **自己发产物 → `tsc`；只想直接跑 → `tsx`；前端打包 → 打包器 + `tsc --noEmit`。**

---

## 八、收尾：写进 `scripts`，以后不用记长命令

```json
{
  "scripts": {
    "build": "tsc",
    "dev": "tsx src/index.ts",
    "watch": "tsc --watch",
    "typecheck": "tsc --noEmit"
  }
}
```

之后只敲别名即可：

```bash
npm run build       # 编译
npm run dev         # 直接跑
npm run typecheck   # 只查类型
```

> [!tip] 团队协作的加分项
> 命令进了 `scripts`，==新人 clone 下来只需 `npm install` 再 `npm run dev`==，不必理解 `npx tsc` 的细节。
> 把 `typecheck` 接进 CI，类型就只会往好的方向走。

---

## 九、终端速查表

```bash
# ── 环境 ──────────────────────────────
node -v / npm -v                     # 确认 Node / npm

# ── 初始化与安装 ──────────────────────
npm init -y                          # 生成 package.json
npm i -D typescript                  # 装编译器
npm i -D tsx                         # 装"直跑"执行器（可选）

# ── 配置 ──────────────────────────────
npx tsc --init                       # 生成 tsconfig.json
npx tsc --showConfig                 # 打印实际生效的配置

# ── 编译 / 运行 ───────────────────────
npx tsc                              # 按 tsconfig 整体编译
npx tsc src/index.ts                 # 编译单个文件
npx tsc --watch                      # 监听变化，自动重编
npx tsc --noEmit                     # 只查类型，不产文件
npx tsx src/index.ts                 # 直接运行 .ts
node dist/index.js                   # 运行编译产物
```

> [!note] 更完整的选项
> `--outDir` / `--incremental` / `-b` 等编译器细节见 [[tsc]]；`tsconfig.json` 的字段分类见 [[tsconfig.json]]。

---

## 十、终端常见报错与应对

> [!question] `'node' 不是内部或外部命令`（或 `command not found`）
> 没装 Node，或装了但**没重开终端**。装 LTS 版后重开终端再试。

> [!question] `'tsc' 不是内部或外部命令`
> 只本地装了却敲了裸 `tsc`。改用 `npx tsc`，或写进 `scripts` 用 `npm run`。

> [!question] 跑了 `npx tsc` 却没有输出文件？
> 多半配置里是 `"noEmit": true`（只做类型检查）。用 `npx tsc --showConfig` 确认；要产物就去掉 `noEmit`。
> 另一种情况：`outDir` 没设置，产物散在源码旁——显式配 `"outDir": "./dist"`。

> [!question] `Cannot find module 'xxx' or its corresponding type declarations`
> 缺类型声明。装 `npm i -D @types/xxx`，或自己写 `xxx.d.ts`——详见 [[TS 与 JS 的互操作性]]。

> [!question] `Cannot write file ... because it would overwrite input file`
> `outDir` 落在了源码范围里。把 `outDir` 指到独立目录（如 `./dist`），并把它加进 `exclude`。

> [!question] 编辑器报错但终端能编译（或反过来）？
> 编辑器缓存了旧配置。VS Code 里用命令面板执行 `TypeScript: Restart TS Server`。

---

## 相关笔记

- [[安装与配置]] —— 安装、`tsc --init`、编译运行方式与编辑器配置
- [[tsconfig.json]] —— 配置文件完整字段、`extends` / `references` 与场景模板
- [[tsc]] —— 编译器命令行的完整选项与常见坑
- [[ts-node]] —— 另一种"不落盘直接跑"的执行器（与 `tsx` 对比）
- [[TypeScript vs JavaScript]] —— 为什么需要编译、类型擦除是什么
- [[TS 与 JS 的互操作性]] —— 混装项目、`@types` 与渐进迁移

---

参考：TypeScript 官方手册 —— TypeScript Tooling in 5 minutes / tsc CLI Options；npm 官方文档 —— npm-init / npm-install
