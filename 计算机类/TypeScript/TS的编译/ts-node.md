# ts-node

> [!abstract] 一句话
> `ts-node` 让 Node **直接运行 `.ts` 文件**，==省掉"先 `tsc` 编成 `.js`、再 `node` 跑"这两步==。它在**内存里即时**把 TS 转译成 JS 再交给 Node 执行——本质是给 `require` / `import` 注册了一个"碰到 `.ts` 就就地编译"的钩子。

---

## 一、它解决什么问题

传统流程要来回两步，写一行代码就得先编译：

```text
传统：  index.ts ──tsc──▶ index.js ──node──▶ 运行   （两段命令，产物落磁盘）
ts-node：index.ts ────────── ts-node ─────────▶ 运行   （一条命令，产物在内存）
```

> [!info] 定位：**开发/脚本期的执行器**，不是构建工具
> - 它**不产出 `.js` 文件**，转译结果只存在于内存里，跑完即弃。
> - 所以它适合**写脚本、跑 CLI、开发时启动 Node 服务**；**生产构建仍应用 [[tsc]]** 编出 `.js` 再交给 `node`。
> - 想做"前端项目里的 TS"请走打包器（Vite / esbuild），跟 ts-node 不是一条路。

---

## 二、安装与首次运行

`typescript` 是**必需的对等依赖**（peer dependency），装 ts-node 时要一并装上：

```bash
npm install -D ts-node typescript

npx ts-node src/index.ts        # 直接运行
npx ts-node -T src/index.ts     # 跳过类型检查，快很多（见第四节）
```

> [!warning] 只装 `ts-node` 会报 `Cannot find module 'typescript'`
> ts-node 自己不实现编译器，它**调用 `typescript` 包**来做转译。两个包必须同时存在。
> 版本上：ts-node 通常依赖较新的 TypeScript，别把 `typescript` 锁得过旧。

也常写进 `package.json`：

```json
{
  "scripts": {
    "dev": "ts-node src/index.ts",
    "start": "ts-node -T src/server.ts"
  }
}
```

---

## 三、工作原理（一句话版）

```text
node 运行 → require('./a.ts')
              │  ts-node 注册的钩子拦截
              ▼
        调用 typescript 编译器 API，把 a.ts 就地转译成 JS
              │  （默认顺带做类型检查）
              ▼
        Node 执行转译结果 —— 磁盘上没有 .js 落盘
```

- **CommonJS 模式**（默认）：注册 `require.extensions['.ts']`，每次 `require` 到 `.ts` 就现场编译。
- **ESM 模式**：改走 Node 的 `--loader` / `--import` 机制，由 `ts-node/esm` 承担同样的转译（见第六节）。

> [!note] 它内部用的就是 `tsc` 的编译器
> ts-node 并没有另写一个 TS 编译器，转译这一步仍由 `typescript` 包完成——这也是它"能力强但偏慢"的根源（全量类型检查很贵）。

---

## 四、最常用的选项

| 选项 | 作用 | 什么时候用 |
| --- | --- | --- |
| `-T, --transpile-only` | ==只转译、不做类型检查==，速度大幅提升 | 开发本地反复跑，类型交给编辑器/CI |
| `--swc` | 用 SWC 转译，比默认快得多 | 追求启动速度 |
| `-P, --project <路径>` | 指定用哪份 `tsconfig.json` | 多配置的项目 |
| `--compilerOptions '<json>'` | 命令行临时覆盖编译选项 | 一次性调 `module` / `target` |
| `-r, --require <模块>` | 先预加载模块再跑 | 搭 `dotenv/config` 等初始化 |
| `--files` | 按 tsconfig 的 `files` 全量加载 | 需要把 `@types` 一起带进来时 |
| `--esm` | 以 ESM 模式运行 | `type: "module"` 的项目 |
| `--logError` | 打印完整错误堆栈 | 排查编译报错 |

> [!tip] 开发就用 `-T`，把类型检查留给别处
> 默认模式下 ts-node **每次启动都做一遍完整类型检查**，大项目动辄好几秒。
> 日常迭代用 `npx ts-node -T`；真正的类型把关放在编辑器的实时提示、`tsc --noEmit` 或 CI 里——**职责分开，各快各的**。

想进交互式 REPL，直接运行 `ts-node` 不带文件名即可写 TS 试玩。

---

## 五、与 `tsconfig.json` 的关系

- ts-node **默认读取最近的 `tsconfig.json`**（查找规则同 `tsc`）。
- 最关键的一项是 **`module`**：CJS 运行方式下应让 `module` 与之一致（常见 `"commonjs"`），否则会撞上 ESM 报错。
- 可以只在 ts-node 里覆盖、不影响 `tsc`：在 tsconfig 里加一个 `"ts-node"` 字段：

```jsonc
{
  "compilerOptions": {
    "module": "commonjs",
    "target": "ES2020",
    "strict": true
  },
  "ts-node": {
    "transpileOnly": true,           // 等价于命令行 -T
    "swc": true,                     // 用 SWC 加速
    "compilerOptions": {             // 仅 ts-node 生效的覆盖
      "module": "commonjs"
    }
  }
}
```

> [!info] 这份 `"ts-node"` 配置只对 ts-node 生效
> `tsc` 会忽略它，所以你可以在其中放心地放宽某些选项（如 `module: "commonjs"`）而不污染真正的构建配置。详见 [[tsconfig.json]]。

---

## 六、ESM 的坑：`Unknown file extension ".ts"`

当 `package.json` 里写了 `"type": "module"`（或文件是 `.mts`），再用老办法跑，Node 会直接甩出：

```text
TypeError [ERR_UNKNOWN_FILE_EXTENSION]: Unknown file extension ".ts"
```

原因：Node 自己的模块加载器不认识 `.ts`，得**显式挂上 ts-node 的 ESM 加载器**：

```bash
# 方式一：--loader（Node 20 之前常见）
node --loader ts-node/esm ./src/index.ts

# 方式二：--import（较新 Node 推荐）
node --import ts-node/esm ./src/index.ts

# 方式三：声明后直接用 ts-node
npx ts-node --esm ./src/index.ts
```

```json
// package.json 里声明，后续 `ts-node x.ts` 自动走 ESM
{ "ts-node": { "esm": true } }
```

> [!warning] ESM 模式下还有两条约束
> - **导入路径要带扩展名**（写 `./util.js` 或 `.ts`，不能像 CJS 那样省略）。
> - ts-node 的 ESM 支持对 `moduleResolution` 很挑，建议 `"moduleResolution": "node16"` / `"nodenext"`。

---

## 七、性能问题与替代方案

ts-node 的默认行为是"**每次运行都把整个项目类型检查一遍**"，于是启动慢成了它最出名的缺点。三条思路：

| 方案 | 做法 | 特点 |
| --- | --- | --- |
| 跳过检查 | `ts-node -T` | 一行开关，立竿见影 |
| 换引擎 | `ts-node --swc` | SWC 转译，更快 |
| 换工具 | ==`tsx`== | esbuild 驱动，几乎零配置、开箱即快，如今多数场景的**首选** |

```bash
npx tsx src/index.ts     # 现代替代：快、简单、CJS/ESM 都能跑
```

其它常见选择：

- **`ts-node-dev` / `nodemon`**：监听改动自动重启，做 Node 服务的热重载。
- **Node 原生类型剥离**：Node 22.6 起可用 `node --experimental-strip-types` 直接运行 TS（Node 23.6 起默认开启）。但它**只支持可擦除语法**（`enum`、`namespace`、参数属性等会报错），且不做类型检查——属于"能跑就行"的轻量方案。

> [!tip] 选型速记
> **本地脚本 / 快速跑一把 → `tsx`；有历史包袱、需要复杂 tsconfig 行为 → `ts-node`；生产构建 → `tsc`。**

---

## 八、常见问题

> [!question] 报 `Cannot use import statement outside a module`？
> 说明 `import` 语句出现在了 CJS 上下文里。设置 tsconfig 的 `"module": "commonjs"`（CJS 运行），或确实要用 ESM 就按第六节挂 `ts-node/esm` 加载器。

> [!question] `ERR_UNKNOWN_FILE_EXTENSION: Unknown file extension ".ts"`？
> 典型的 **ESM 未挂加载器**。用 `node --import ts-node/esm ...`，或在 `package.json` 里 `"ts-node": { "esm": true }`。

> [!question] 只装了 `ts-node`，报 `Cannot find module 'typescript'`？
> ts-node 靠 `typescript` 包来做编译。补装：`npm i -D typescript`。

> [!question] 启动太慢，或者一行类型错误就不让跑？
> 用 `-T`（`--transpile-only`）跳过类型检查，或加 `--swc`。类型问题交给编辑器与 CI。

> [!question] 生产环境能不能直接 `ts-node` 启动？
> **不建议**。它每次启动都要转译（还可能全量类型检查），冷启动慢、内存占用高。生产应 `tsc` 编出 `.js` 后 `node dist/index.js`。

> [!question] ts-node 和 [[tsc]] 到底什么关系？
> 都基于同一套 TypeScript 编译器。区别在**产物去向**：`tsc` 把 `.js` **写到磁盘**（用于构建/发布），ts-node **只在内存里转译**（用于直接运行）。

---

## 相关笔记

- [[tsc]] —— 官方编译器：把 TS 编译成 `.js` 的标准方式
- [[安装与配置]] —— 装 TypeScript、写 `tsconfig.json`、编译与运行
- [[tsconfig.json]] —— `module` / `moduleResolution` 等关键选项
- [[TS 与 JS 的互操作性]] —— `.d.ts`、`allowJs` 与渐进迁移

---

参考：ts-node 官方文档 —— Overview / Options / ESM support；Node.js 官方文档 —— Modules: TypeScript / `--experimental-strip-types`
