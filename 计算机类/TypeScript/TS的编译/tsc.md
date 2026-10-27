# tsc

> [!abstract] 一句话
> `tsc` 是 TypeScript 官方的**编译器命令行工具**：它把 `.ts` **类型检查 + 转译**成浏览器/Node 能跑的 `.js`。==单个文件直接喂给它，整个项目则靠 `tsconfig.json` 指挥==。它只**产出** `.js`，**不负责运行**。

---

## 一、它到底做两件事

```text
              ┌─ ① 类型检查：按 tsconfig 的 strict 等规则静态查错
index.ts ─tsc─┤
              └─ ② 转译降级：ESNext 语法 → target 版本，擦除全部类型注解
                    │
                    ▼
             index.js  (+ index.js.map  + index.d.ts)
                    │
                  node 运行（tsc 自己不做这步）
```

> [!info] 分清"编译"与"运行"
> - `tsc` 是**编译期**工具：输入 `.ts`，输出 `.js`，**类型信息在产物里被彻底擦除**。
> - 要跑起来还得 `node dist/index.js`。想**省掉编译、直接跑 `.ts`**，用 [[ts-node]] 或 `tsx`。

> [!warning] 最反直觉的一点：有类型错误，`tsc` 默认**照样产出文件**
> 命令行会报错、退出码非 0，但 `.js` 还是写出来了——因为历史上"能编尽编"对老 JS 项目更友好。
> 想让"有错就不产出"，必须显式设 `"noEmitOnError": true`（见第五节）。**CI 里务必注意**。

---

## 二、最常见的几条命令

```bash
npx tsc src/index.ts          # 编译单个文件 → 同目录生成 index.js
npx tsc                       # 按最近的 tsconfig.json 整体编译
npx tsc --init                # 生成一份带注释的 tsconfig.json
npx tsc -p tsconfig.build.json   # 指定用哪份配置文件（-p = --project）
npx tsc --watch               # 监听文件变化，改动即重编（-w）
npx tsc --noEmit              # 只做类型检查，不产出任何文件
npx tsc -b                    # 构建模式：编译项目引用（-b = --build）
```

> [!tip] 永远用 `npx tsc`
> 项目里本地装了 `typescript` 时，`npx tsc` 会**优先用本地版本**，避免误用全局的旧编译器。裸敲 `tsc` 常报"不是内部或外部命令"。

---

## 三、单文件模式 vs 项目模式

| | 单文件模式 | 项目模式 |
| --- | --- | --- |
| 命令 | `tsc a.ts` | `tsc`（或 `tsc -p xxx.json`） |
| 依据 | 命令行参数 | `tsconfig.json` |
| 编译范围 | 只编你给的（及其 import 的）文件 | 按 `files` / `include` / `exclude` 圈定 |
| 输出 | 默认与源文件同目录 | 按 `outDir` 输出 |
| 适用 | 临时试一下、写个小脚本 | 真实项目 |

> [!info] `tsc` 不带参数时会**向上找** `tsconfig.json`
> 从当前目录逐级往上级查找最近的一份；也可用 `-p` 直接指定。查找规则详见 [[tsconfig.json]]。

---

## 四、常用命令行选项

命令行传入的选项会**覆盖** `tsconfig.json` 里的同名项。

**输出相关**

```bash
--outDir ./dist          # 输出目录
--rootDir ./src          # 源码根目录（决定产物目录结构）
--outFile bundle.js      # 合并成单文件（⚠ 仅限 amd / system 模块，见第八节）
--declaration            # 同时产出 .d.ts 类型声明（-d）
--declarationMap         # 产 .d.ts.map
--sourceMap              # 产 .js.map，便于调试 TS 源码
--removeComments         # 去掉注释
```

**检查与目标**

```bash
--strict                 # 开启全部严格检查
--noEmit                 # 不产出文件，只检查
--noEmitOnError          # 有类型错误就不产出文件
--target ES2020          # 转译目标版本
--module ESNext          # 模块格式
--moduleResolution bundler
--lib ES2020,DOM         # 可用的内置 API 类型
--jsx react-jsx          # JSX 处理方式
```

**诊断与排查**

```bash
--showConfig             # 打印合并解析后的最终配置（查"改了为啥没生效"）
--listFiles              # 列出参与编译的所有文件
--explainFiles           # 说明每个文件为何被纳入
--diagnostics           # 打印编译耗时等诊断信息
--pretty                 # 彩色输出（默认开）
--watch, -w              # 监听模式
--incremental            # 增量编译，用 .tsbuildinfo 缓存
```

---

## 五、`--noEmit` 与 `--noEmitOnError`（两个容易混的选项）

```text
--noEmit        ：压根不产出任何 .js —— 纯"类型检查器"模式
--noEmitOnError ：产出照旧，但一旦有类型错误就一个都不产出
```

> [!tip] 现代前端项目的典型分工
> 打包交给 Vite / webpack / esbuild，TypeScript 只当"类型检查器"：
> - 开发时：编辑器实时提示；
> - CI 里：`tsc --noEmit` 卡一道类型门禁。
> 这样构建快、检查全，各司其职。详见 [[安装与配置]] 的 `noEmit` 说明。

---

## 六、`--watch` 与 `--build`：两种"更快"

**监听重编**——改一个文件就增量重编：

```bash
npx tsc --watch          # 常驻后台，配合 ts-node/nodemon 做开发
```

**构建模式**——面向**项目引用（project references）**，按依赖顺序增量构建：

```bash
npx tsc -b               # 编译本项目及其引用的所有子项目
npx tsc -b --clean       # 清理构建产物与缓存
```

```jsonc
// 根 tsconfig 用 references 指向子项目，各自带 "composite": true
{
  "references": [{ "path": "./packages/core" }, { "path": "./packages/web" }]
}
```

> [!note] 增量编译靠 `.tsbuildinfo` 缓存
> `--incremental` 与 `-b` 都依赖它记录"上次编到哪"。大项目里能把二次全量从分钟级降到秒级。

---

## 七、把 `tsc` 变成一行脚本

写进 `package.json`，团队/CI 一致，不必背 `npx` 那串：

```json
{
  "scripts": {
    "build": "tsc",
    "watch": "tsc --watch",
    "typecheck": "tsc --noEmit",
    "clean": "tsc -b --clean"
  }
}
```

之后 `npm run build`、`npm run typecheck` 即可。

---

## 八、常见问题

> [!question] 报了类型错误，为什么还生成了 `.js`？
> 这是 `tsc` 的默认行为——**有错也照常产出**（退出码非 0 供 CI 判断）。想禁止产出，设 `"noEmitOnError": true`。

> [!question] `--outFile` 报 `Only 'amd' and 'system' modules can be used with --outFile`？
> `--outFile` **只兼容 AMD / System 模块**，用来把多个文件合成一个。用 `module: "ESNext"` / `"CommonJS"` 时不能这么用。
> 想打成一个 bundle，请用打包器：`esbuild`、`rollup`、Vite 等。

> [!question] 产物目录结构莫名其妙多了一层 `src/`？
> 通常是**没设 `rootDir`**：`tsc` 会取所有源文件的公共父目录作为根，从而带上多余层级。显式写 `"rootDir": "./src"` 即对齐。

> [!question] 报 `Cannot write file ... because it would overwrite input file`（TS5055）？
> `outDir` 指到了源码目录里，产物会覆盖源文件。把 `outDir` 指到独立的 `./dist`。

> [!question] `tsc : 无法将"tsc"项识别为 cmdlet / 不是内部或外部命令`？
> 用的是全局命令却没装全局，或全局版本不在 PATH。**改用 `npx tsc`**（走本地版本），或写进 `scripts` 再 `npm run`。

> [!question] 想让 `tsc` 只检查、不要任何输出？
> `tsc --noEmit`，或在 tsconfig 里设 `"noEmit": true`。

> [!question] 为什么构建慢？能不能更快？
> 官方 `tsc` 全量类型检查本身就慢。可：开 `--incremental` / 项目引用拆包；或开发期改用快工具（[[ts-node]] 的 `-T`/`--swc`、`tsx`、esbuild）——**构建交给快工具，类型把关交给 `tsc --noEmit`**。

---

## 相关笔记

- [[ts-node]] —— 不产出文件、直接在内存里跑 `.ts` 的执行器
- [[安装与配置]] —— 装 TypeScript、写 `tsconfig.json`、编译与运行
- [[tsconfig.json]] —— 各编译选项的完整分类详解
- [[TypeScript vs JavaScript]] —— 为什么必须编译、类型擦除是什么

---

参考：TypeScript 官方文档 —— tsc CLI Options / Compiler Options；TypeScript 手册 —— Project References
