# tsconfig.json

> [!abstract] 一句话
> `tsconfig.json` 是 TypeScript 项目的**总配置**：用一份 JSON 说明 ==**编译哪些文件**（`files` / `include` / `exclude`）、**按什么规则编译**（`compilerOptions`）、**产物放哪**（`outDir` 等）==。有它在，`tsc` 不带任何文件参数就能整体编译；没有它，只能一个个文件喂给编译器。

---

## 一、它怎么被发现：tsc 的查找规则

```text
在 D:\proj\src\deep 下敲 tsc（不带文件参数）
        │  逐级向上查找 tsconfig.json
        ▼
D:\proj\src\deep\  →  D:\proj\src\  →  D:\proj\tsconfig.json  ✅ 用它
                    （一路找到磁盘根也没有 → 报错）
```

- **不带参数** `tsc`：从当前目录向**上级**找最近的 `tsconfig.json`。
- **指定路径** `tsc -p ./configs/tsconfig.build.json`（`-p` = `--project`）：直接用它，不再向上找。
- **首先生成** `tsc --init`：产出一份带注释的配置骨架。

> [!note] 允许写注释和尾逗号
> `tsconfig.json` 实际是 **JSONC**：可以写 `//`、`/* */` 注释和结尾多余逗号——这也是 `tsc --init` 生成的模板满是注释的原因。

> [!tip] 忘了生效的到底是什么？
> `tsc --showConfig` 会打印**合并/解析之后**的最终配置（含 `extends` 展开），排查"我明明改了却没生效"最有效。

---

## 二、文件结构总览

顶层一共就这几个字段：

```jsonc
{
  "compilerOptions": { /* 编译规则：类型检查、模块、产物…… */ },
  "files":     ["src/index.ts"],       // 精确列出要编译的文件（可省）
  "include":   ["src/**/*"],           // 用 glob 圈目录（可省）
  "exclude":   ["node_modules", "dist"], // 从 include 里剔除（可省）
  "extends":   "./tsconfig.base.json", // 继承别的配置（可省）
  "references": [ { "path": "../core" } ], // 项目引用（可省）
  "watchOptions": { /* 监听模式细节，可省 */ }
}
```

> [!info] 只有 `compilerOptions` 是"实质配置"
> 其余字段都是**范围与组织**问题：编译谁（`files`/`include`/`exclude`）、继承谁（`extends`）、怎么拼装（`references`）。

---

## 三、`compilerOptions` 分类详解

官方把上百个选项分成七组。下面按组挑出**真正常用的**。

### 3.1 类型检查（Type Checking）

```jsonc
{
  "compilerOptions": {
    "strict": true,               // 一把开启下面一批严格检查（强烈建议）
    "noUnusedLocals": true,       // 声明了却没用到的局部变量 → 报错
    "noUnusedParameters": true,   // 没用到的函数参数 → 报错
    "noImplicitReturns": true,    // 有的分支 return、有的不 return → 报错
    "noFallthroughCasesInSwitch": true, // switch 分支不许"漏掉 break 直落下一分支"
    "noUncheckedIndexedAccess": true,   // arr[i] 的结果加上 undefined（更真实，但改动大）
    "exactOptionalPropertyTypes": true  // 可选属性能不能显式赋 undefined，严格区分
  }
}
```

> [!warning] 这几个**不在** `strict` 管辖内，要单独开
> `noUncheckedIndexedAccess`、`exactOptionalPropertyTypes`、`noImplicitOverride`、`noPropertyAccessFromIndexSignature`、`noUnusedLocals` / `noUnusedParameters`、`noImplicitReturns`、`noFallthroughCasesInSwitch`。
> 它们比 `strict` 更"激进"，常留到项目稳定后再逐个开。`strict` 到底包含哪些见 [[安装与配置]] 的表格。

### 3.2 语言与运行环境（Language and Environment）

```jsonc
{
  "compilerOptions": {
    "target": "ES2022",       // 产出哪个 JS 版本（决定降级程度）
    "lib": ["ES2022", "DOM"], // 写代码时可用的内置 API 类型
    "jsx": "react-jsx",       // JSX 如何处理：react-jsx / react / preserve
    "useDefineForClassFields": true, // 类字段用 [[Define]] 语义（target≥ES2022 默认开）
    "experimentalDecorators": true   // 旧式装饰器（Angular 等需要）
  }
}
```

> [!warning] `lib` 一旦显式写出，就**整套覆盖**默认
> 不写 `lib` 时，TS 按 `target` 自动带上对应标准库并含 `DOM`。
> 但你只要写了 `"lib": ["ES2022"]`，**`DOM` 就没了** —— `document` / `window` 立刻报"找不到名称"，得手动补 `"DOM"`。

### 3.3 模块（Modules）

```jsonc
{
  "compilerOptions": {
    "module": "ESNext",              // 产出的模块格式
    "moduleResolution": "bundler",   // 解析策略：node10 / node16 / nodenext / bundler
    "baseUrl": ".",                  // 非相对导入的解析基准
    "paths": { "@/*": ["src/*"] },   // 路径别名
    "resolveJsonModule": true,       // 允许 import "./data.json"
    "esModuleInterop": true,         // import x from "cjs 包" 更顺
    "isolatedModules": true,         // 保证每个文件可被单独转译（esbuild/swc/babel 需要）
    "verbatimModuleSyntax": true,    // 严格区分"类型导入"与"值导入"（TS 5.0+）
    "types": ["node"],               // 只自动引入这些 @types/*（限定范围、提速）
    "typeRoots": ["./node_modules/@types"] // @types 的搜索位置（一般不用改）
  }
}
```

> [!note] `module` 与 `moduleResolution` 要**配对**
> - 打包器负责构建的前端项目 → `module: "ESNext"` + `moduleResolution: "bundler"`。
> - 直接在 Node 跑 → `module: "NodeNext"` + `moduleResolution: "NodeNext"`，让 TS 跟随 Node 的规则（`.mts`/`.cjs`/`"type": "module"`）。
> 二者错配是"模块找不到 / 导入报错"的头号来源。

> [!tip] `types` 与 `typeRoots` 的区别
> `typeRoots` 决定**去哪找** `@types`；`types` 决定**自动引入哪几个**。
> 只写 `"types": ["node"]`，其余 `@types/*` 就不会被全局塞进来，能少很多命名冲突、也更快。

### 3.4 产物（Emit）

```jsonc
{
  "compilerOptions": {
    "rootDir": "./src",           // 源码根，决定输出目录结构
    "outDir": "./dist",           // 编译产物放哪
    "declaration": true,          // 额外产出 .d.ts（做库时用）
    "declarationMap": true,       // .d.ts.map，跳转回源码
    "sourceMap": true,            // 产出 .js.map，便于调试
    "removeComments": false,      // 是否删掉注释
    "noEmit": true,               // 只检查类型、不产文件（打包器负责产出时）
    "noEmitOnError": true,        // 有类型错误就不产出（默认 false）
    "importHelpers": true,        // 复用 tslib 的辅助函数，减小体积
    "downlevelIteration": true    // 降到 ES5 时也能正确 for...of / 展开
  }
}
```

> [!warning] `outDir` 必须和 `rootDir` / `include` 错开
> 若输出目录落在源码范围里，`tsc` 可能把刚生成的 `.js` 又当成输入，报
> `Cannot write file ... because it would overwrite input file`。`exclude` 一定要带上 `outDir`。

### 3.5 JavaScript 支持（JavaScript Support）

```jsonc
{
  "compilerOptions": {
    "allowJs": true,     // 让 .js 一起参与编译
    "checkJs": true,     // 连 .js 也做类型检查
    "maxNodeModuleJsDepth": 1 // 检查 node_modules 里 JS 的深度（默认 0）
  }
}
```

这三个是 JS/TS 混装项目的关键，详见 [[TS 与 JS 的互操作性]]。

### 3.6 完整性与性能（Completeness / Performance）

```jsonc
{
  "compilerOptions": {
    "skipLibCheck": true,               // 跳过 node_modules 里 .d.ts 的检查 → 明显提速
    "forceConsistentCasingInFileNames": true, // 大小写敏感，跨平台防坑（TS 5 默认开）
    "incremental": true,                // 增量编译，写 .tsbuildinfo
    "tsBuildInfoFile": "./dist/.tsbuildinfo", // 增量信息放哪
    "composite": true                   // 项目引用必备（隐含 declaration + incremental）
  }
}
```

> [!success] `skipLibCheck` 几乎是必备项
> 第三方 `.d.ts` 之间的版本冲突很常见，检查它们既慢又常与你无关。
> 开它会**跳过所有 `.d.ts` 的类型检查**，代价是库自身的类型错误不再报出——绝大多数项目都值得。

---

## 四、`files` / `include` / `exclude`：到底编译谁

```text
        ┌── files:   精确列出文件，==不受 exclude 影响==
输入集合 ┤── include: glob 圈目录，默认 ["**/*"]，==受 exclude 过滤==
        └── 两者都没写 → 以 tsconfig 所在目录为根，整个目录树
                        │
                        ▼ 编译
                 outDir（保留相对 rootDir 的目录结构）
```

| 字段 | 语义 | 关键点 |
| --- | --- | --- |
| `files` | 白名单，逐个列文件 | 优先级最高；**不受 `exclude` 过滤** |
| `include` | glob 圈一批 | 默认 `["**/*"]`（含 `.ts`/`.tsx`/`.d.ts`；开 `allowJs` 后含 `.js`/`.jsx`） |
| `exclude` | 从 `include` 结果里剔除 | **默认** `node_modules` / `bower_components` / `jspm_packages` / `outDir` |

**glob 语法**：`*` 匹配零或多个字符（不含目录分隔符）、`?` 匹配一个字符、`**/` 匹配任意层级子目录。

> [!warning] `exclude` 的边界：挡不住"被 import 进来的文件"
> 只写 `include` 而不写 `files` 时，**被 include 的文件所 import 的文件也会被纳入编译**，即使它在 `exclude` 里。
> `exclude` 只过滤 `include` 的**初始集合**，不是"全局禁令"。想真正隔离，得靠 `files` 或项目引用。

---

## 五、`extends`：配置继承

```text
base.json ──extends──▶ tsconfig.json ──extends──▶ tsconfig.build.json
   共享规则             项目微调              构建专用（再覆盖）
```

```jsonc
// tsconfig.json
{
  "extends": "./tsconfig.base.json",
  "compilerOptions": { "outDir": "./dist" }
}
```

- `compilerOptions` 是**逐项合并**：子配置里写了的键覆盖父配置的同名键，没写的沿用父配置。
- `files` / `include` / `exclude` **不合并**：子配置一旦写了，就整体取代父配置的那一项。
- `extends` 里若是**相对路径，以"写着它的那个配置文件"所在目录为基准**解析。
- TS 5.0 起 `extends` 可以是**数组**：`"extends": ["./base.json", "./strict.json"]`，后者覆盖前者。
- 也可直接继承 npm 包：`"extends": "@tsconfig/strictest/tsconfig.json"`（社区现成的基线配置）。

> [!tip] 常见组织方式
> `tsconfig.base.json` 放通用规则 → `tsconfig.json` 供编辑器/日常用 → `tsconfig.build.json` 收紧 `include`、关测试文件。**编辑器读哪份，由 `tsconfig.json` 决定**，所以别把日常配置写空。

---

## 六、`references` + `composite`：项目引用

大型项目（monorepo、前后端同仓）可把一个仓库切成多个小项目，各自一份 `tsconfig`：

```jsonc
// 根 tsconfig.json
{
  "files": [],
  "references": [
    { "path": "./packages/core" },
    { "path": "./packages/web" }
  ]
}
```

```jsonc
// packages/core/tsconfig.json
{
  "compilerOptions": { "composite": true, "outDir": "./dist", "rootDir": "./src" },
  "include": ["src"]
}
```

- 被引用的项目**必须** `composite: true`；它会隐含 `declaration: true` + `incremental: true`，并额外产出 `.d.ts` 供别的项目消费。
- 用 **`tsc -b`（`--build`）** 构建整条依赖链：它按依赖顺序编译，**只重编改动过的项目**，大幅提速。
- `tsc -b --clean` 清理构建产物。

> [!info] 和"一个 tsconfig 管全部"的取舍
> 项目引用换来**增量编译 + 边界清晰**，代价是多几份配置文件。小项目不值得，几十个包的仓库很值。

---

## 七、`baseUrl` 与 `paths`：路径别名

```jsonc
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@utils/*": ["src/utils/*"]
    }
  }
}
```

```ts
import { add } from "@/utils/math";   // 不再写 ../../
```

- `paths` 相对 `baseUrl` 解析；TS 4.1 起可省略 `baseUrl`，此时相对 **tsconfig 所在目录**解析。
- 目标可用多个候选（数组），TS 依次尝试；也可留一个 `"*": ["./src/types/*"]` 作兜底。

> [!warning] `paths` 只让 **TS 编译器**认识别名，运行时/打包器**不会**自动认识
> 跑了才知道 `Cannot find module '@/utils/math'`，就是这里漏配：
> - Vite → `resolve.alias`；webpack → `resolve.alias`；
> - Node 直接跑 → `tsconfig-paths`、`--import` 的 loader，或干脆用 `imports` 字段；
> - 打包器一般都读 `tsconfig` 的 `paths`（如 Vite 的 `vite-tsconfig-paths` 插件）来自动同步。
> **"编译过、运行炸"最经典的一类坑。**

---

## 八、几种场景的起步模板

### 8.1 Node 脚本 / CLI

```jsonc
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ES2022"],
    "types": ["node"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "sourceMap": true
  },
  "include": ["src"]
}
```

### 8.2 前端应用（Vite / React，由打包器产出）

```jsonc
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "jsx": "react-jsx",
    "strict": true,
    "esModuleInterop": true,
    "isolatedModules": true,
    "skipLibCheck": true,
    "noEmit": true,          // 产出交给 Vite，tsc 只做类型检查
    "baseUrl": ".",
    "paths": { "@/*": ["src/*"] }
  },
  "include": ["src"]
}
```

### 8.3 发布 npm 库

```jsonc
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2020"],
    "rootDir": "./src",
    "outDir": "./dist",
    "declaration": true,      // ★ 消费方才能拿到类型
    "declarationMap": true,
    "sourceMap": true,
    "strict": true,
    "skipLibCheck": true
  },
  "include": ["src"],
  "exclude": ["**/*.test.ts"]  // 不把测试打进产物
}
```

### 8.4 老项目渐进迁移（先能编译、再收紧）

```jsonc
{
  "compilerOptions": {
    "target": "ES2019",
    "module": "CommonJS",
    "allowJs": true,          // 先让 JS 一起进来
    "checkJs": false,         // 暂不检查 JS，先看得见范围
    "strict": false,          // 先别开，只求编译过
    "strictNullChecks": true, // 但这一项建议尽早开，收益最大
    "skipLibCheck": true,
    "outDir": "./dist",
    "sourceMap": true
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
```

收紧节奏见 [[TS 与 JS 的互操作性]] 的渐进迁移一节。

---

## 九、常用命令

```bash
npx tsc --init                  # 生成带注释的 tsconfig.json
npx tsc                         # 按当前找到的 tsconfig 整体编译
npx tsc -p tsconfig.build.json  # 指定配置文件
npx tsc --showConfig            # 打印解析后的最终配置（含 extends 展开）
npx tsc --noEmit                # 只做类型检查，不产文件（放进 CI）
npx tsc --watch                 # 监听变化，自动重编
npx tsc -b                      # 按项目引用构建整条依赖链
npx tsc -b --clean              # 清理项目引用的构建产物
npx tsc --target ES2020 ...     # 命令行参数可临时覆盖配置文件里的同名项
```

> [!tip] 命令行参数优先于配置文件
> `tsc --someFlag` 只在`--` 后的这次运行里覆盖配置，**不改文件**。适合一次性验证。

---

## 十、常见问题

> [!question] 改了 `tsconfig.json`，但报错/行为没变？
> 先 `tsc --showConfig` 看**实际生效**的配置（可能被 `extends` 覆盖，或编辑器缓存了旧配置）。
> VS Code 里还可用命令面板 `TypeScript: Restart TS Server` 让语言服务重新读取。

> [!question] `Cannot write file ... because it would overwrite input file`？
> 输出目录和输入范围重叠了。检查 `outDir` 是否落在 `include` 覆盖的路径里，并把 `outDir` 加进 `exclude`。

> [!question] `exclude` 里的文件还是被编译了？
> `exclude` 只过滤 `include` 的初始集合。**被 include 文件 import 的文件不受它约束**，两个都 include 的目录也会相互带入。要用 `files` 或项目引用做真正的隔离。

> [!question] 编译通过，跑起来却 `Cannot find module`？
> 多半是 `paths` 别名：TS 认识，运行时/打包器不认识。去 bundler 或 Node 侧配对应的 alias / loader。

> [!question] `document` / `console` / `Promise` 报"找不到名称"？
> `lib` 的问题。显式写了 `lib` 就会覆盖默认，记得按需补 `"DOM"`（以及 `"DOM.Iterable"` 等）。

> [!question] 生成的 `.d.ts` 目录结构很奇怪？
> 通常是 `rootDir` 没设，TS 只能按"所有输入文件的公共父目录"推断根，导致结构偏移。显式设 `rootDir`。

> [!question] 老项目一开 `strict` 满屏红？
> 别硬扛。先关或调松（可只留 `strictNullChecks`），保证能编译能跑，再配合 `allowJs` / `checkJs` 逐个文件收紧——见 [[TS 与 JS 的互操作性]]。

> [!question] `module` 和 `moduleResolution` 到底怎么配？
> 看**谁来处理模块**：打包器接管 → `ESNext` + `bundler`；Node 原生运行 → `NodeNext` + `NodeNext`；老 CommonJS 项目 → `CommonJS` + `node10`。两者错配是各类"导入报错"的根源。

---

## 相关笔记

- [[安装与配置]] —— 安装 TypeScript、`tsc --init`、编译运行与编辑器配置
- [[TS 与 JS 的互操作性]] —— `allowJs` / `checkJs` / `.d.ts` 与渐进迁移
- [[TypeScript vs JavaScript]] —— 为什么需要编译、类型擦除是什么

---

参考：TypeScript 官方手册 —— tsconfig.json Reference / What is a tsconfig.json / Project References / Module Resolution；`@tsconfig/bases` 社区基线配置
