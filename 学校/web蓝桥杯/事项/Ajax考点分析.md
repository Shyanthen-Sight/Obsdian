---
tags:
  - 前端/Ajax
  - 前端/axios
  - 前端/JavaScript
  - 蓝桥云课
  - 学习方法
---

# Ajax 与 axios：蓝桥杯数据交互考点全解

> [!info] 这份笔记解决什么
> 蓝桥杯 Web 应用开发把「网络请求与数据交互」列为考点：AJAX 原理、axios 发请求、异步数据处理、响应渲染，以及和 Vue / ECharts / Element Plus 的组合题。
> 这份笔记按「是什么 → 怎么发 → 怎么接 → 怎么答 → 怎么不丢分」组织，考试时可以直接当开卷速查。

> [!summary] 速记版
> ```js
> // GET：查询参数放 params
> const { data } = await axios.get('/api/list', { params: { page: 1 } });
>
> // POST：请求体放第二个参数
> const { data } = await axios.post('/api/login', { username, password });
>
> // 响应对象里的 res.data 才是后端返回的内容
> ```
> - `axios.get(url, config)`：第二个参数是配置对象，查询参数写 `params`。
> - `axios.post(url, data, config)`：第二个参数是请求体，配置对象放第三个。
> - `async/await` 拿结果，`try/catch` 兜错误。
> - 在 Vue 的 `created` / `mounted` 里发请求，把结果赋给 `data`，模板自动渲染。
> - 题目若已封装 `request` 或写了拦截器，先看它返回的是 `res` 还是 `res.data`。

## 一、蓝桥杯怎么考 Ajax / axios

| 考点 | 具体要会 | 常见题型 |
| --- | --- | --- |
| AJAX 概念 | 异步、无刷新、XHR、`readyState` / `status` | 选择题、概念填空 |
| axios 基础 | `get` / `post` / `put` / `delete`、`params` / `data` | 列表加载、详情查询 |
| 异步编程 | Promise、`async/await`、`try/catch`、`Promise.all` | 数据依赖、并发请求 |
| 响应处理 | `res.data`、`res.status`、错误分支 | 渲染表格 / 卡片 / 图表 |
| 请求配置 | `headers`、`timeout`、`baseURL`、`withCredentials` | 带 token、跨域、上传 |
| 拦截器 | 请求 / 响应拦截、统一解包 | 看项目已有封装 |
| 框架结合 | Vue 生命周期、ECharts `setOption`、Element Plus 表格 | 综合大题 |
| 跨域 | 同源策略、CORS、`devServer.proxy` | 本地调试 |

> [!note] 蓝桥杯的出题方式
> 题目通常给一个**已经搭好的项目**：`index.html`、`css/`、`js/`、`axios.min.js`，以及一份**接口文档**（URL、方法、参数、返回示例）。
> 你只需要在指定文件里补全「发请求 + 处理数据 + 渲染页面」，**不要改目录结构、文件名、已有的 id / class**。
> 有些题会把后端模拟成一个函数（例如 [[3.商品销量和销售额实时展示看板]] 里的 `Ajax()`），本质仍是「返回 Promise 的异步数据源」，用 `await` 接即可。

### 学习顺序（别一上来就背 API）

```
① AJAX 是什么
      ↓
② 手写一次 XMLHttpRequest
      ↓
③ axios 发 GET / POST
      ↓
④ async/await + try/catch
      ↓
⑤ 接到 Vue 列表渲染
      ↓
⑥ 综合题：Vue + axios + ECharts
```

> [!tip] 开卷策略
> 比赛允许查文档，真正要背的是**请求方法、参数位置、响应层级**这三件事。
> 具体字段名、配置项，现场查 axios 文档即可；把本文当索引，比翻官网快。

## 二、AJAX 到底是什么

- AJAX = **A**synchronous **J**avaScript **A**nd **X**ML。
- 它不是语言，也不是框架，而是一种**用 JavaScript 在后台与服务器交换数据、局部更新页面**的技术方案。
- 名字里有 XML，但现在几乎都用 **JSON**。
- 实现 AJAX 的方式有：`XMLHttpRequest`、`fetch`、`axios`、jQuery 的 `$.ajax`。
- **axios 是 AJAX 的一种现代实现**，不是 AJAX 本身。

### 同步 vs 异步

```
同步：发请求 → 页面卡住等 → 收到响应 → 继续执行
异步：发请求 → 继续执行后面的代码 → 响应回来 → 回调 / Promise 处理
```

> [!tip] 一句话理解
> AJAX 让浏览器「偷偷」发请求，页面不刷新、不跳转，只更新需要变的那一块。

### 传统表单 vs AJAX

| 方式 | 页面是否刷新 | 用户体验 | 蓝桥杯是否常用 |
| --- | --- | --- | --- |
| 传统 `form` 提交 | 整页刷新 / 跳转 | 中断操作 | 基本不用 |
| AJAX | 不刷新，局部更新 | 流畅 | **主要方式** |

### JSON 的两个方法

```js
// 对象 → JSON 字符串（发请求前）
JSON.stringify({ name: '张三', age: 18 });
// '{"name":"张三","age":18}'

// JSON 字符串 → 对象（收到响应后）
JSON.parse('{"name":"张三","age":18}');
// { name: '张三', age: 18 }
```

> [!note] axios 会自动转换
> 传对象给 axios，它会自动 `JSON.stringify` 并设置 `Content-Type: application/json`；
> 收到 JSON 响应，它会自动 `JSON.parse` 成对象。只有用原生 XHR / fetch 时才需要手动处理。

## 三、原生 XMLHttpRequest（概念题必会）

写业务代码一般用 axios，但**概念题会考 XHR**，至少要能看懂、能默写五步。

### GET 五步

```js
const xhr = new XMLHttpRequest();          // 1. 创建
xhr.open('GET', '/api/list?page=1', true); // 2. 打开，true = 异步
xhr.onreadystatechange = function () {     // 3. 监听状态
  if (xhr.readyState === 4) {              // 4. 请求完成
    if (xhr.status >= 200 && xhr.status < 300) {
      const data = JSON.parse(xhr.responseText);
      console.log(data);
    }
  }
};
xhr.send();                                // 5. 发送
```

### POST

```js
const xhr = new XMLHttpRequest();
xhr.open('POST', '/api/login', true);
xhr.setRequestHeader('Content-Type', 'application/json');
xhr.onreadystatechange = function () {
  if (xhr.readyState === 4 && xhr.status === 200) {
    console.log(JSON.parse(xhr.responseText));
  }
};
xhr.send(JSON.stringify({ username: 'admin', password: '123456' }));
```

### readyState 五个状态

| 值 | 名称 | 含义 |
| --- | --- | --- |
| 0 | UNSENT | 刚创建，未调用 `open` |
| 1 | OPENED | 已调用 `open` |
| 2 | HEADERS_RECEIVED | 已收到响应头 |
| 3 | LOADING | 正在下载响应体 |
| 4 | DONE | 请求完成 |

> [!warning] 判断顺序
> 先判断 `readyState === 4`，再判断 `status`。只看 `status` 可能读到中间状态；只看 `readyState` 会把 404 / 500 也当成功。
> `status` 在 200–299 之外不一定是「请求没发出去」，也可能是服务器明确返回了错误。

### 常用状态码

| 状态码 | 含义 | 常见原因 |
| --- | --- | --- |
| 200 | OK | 成功 |
| 201 | Created | POST 创建成功 |
| 204 | No Content | 成功但无响应体 |
| 301 / 302 | 重定向 | 地址变了 |
| 304 | Not Modified | 缓存命中 |
| 400 | Bad Request | 参数格式错 |
| 401 | Unauthorized | 未登录 / token 失效 |
| 403 | Forbidden | 无权限 |
| 404 | Not Found | URL 写错 |
| 500 | Internal Server Error | 后端异常 |

### XHR 的现代写法（了解）

```js
const xhr = new XMLHttpRequest();
xhr.open('GET', '/api/list');
xhr.responseType = 'json';
xhr.timeout = 5000;
xhr.onload = () => {
  if (xhr.status === 200) console.log(xhr.response);
};
xhr.onerror = () => console.error('网络错误');
xhr.ontimeout = () => console.error('超时');
xhr.send();
```

## 四、fetch：更现代的替代方案（了解）

```js
async function getList() {
  const res = await fetch('/api/list?page=1');
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const data = await res.json();
  return data;
}
```

### XHR / fetch / axios 对比

| 对比项 | XMLHttpRequest | fetch | axios |
| --- | --- | --- | --- |
| 语法 | 繁琐 | 简洁 | 最简洁 |
| Promise | 否（回调） | 是 | 是 |
| 自动 JSON | 否 | 否（要 `.json()`） | 是 |
| 4xx / 5xx 自动 reject | 否 | **否**（要看 `res.ok`） | **是** |
| 拦截器 | 无 | 无 | 有 |
| 浏览器兼容 | 好 | 较好 | 好 |
| 蓝桥杯 | 概念题 | 偶尔 | **主力** |

> [!warning] fetch 的坑
> `fetch` 只在**网络失败**时 reject；服务器返回 404、500 时 Promise 仍然是 resolved。必须自己判断 `res.ok`。
> axios 默认把 4xx / 5xx 视为错误，直接进 `catch`，这是考试里更容易写对的原因之一。

## 五、axios 核心用法

### 1. 引入

```html
<!-- CDN -->
<script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>

<!-- 本地文件（蓝桥杯项目常见） -->
<script src="./js/axios.min.js"></script>
```

```bash
# npm 项目
npm install axios
```

```js
import axios from 'axios';
```

> [!note] 考试时先找引入
> 打开 `index.html`，确认 `axios` 是否已经引入、路径是什么。**不要在已引入的情况下重复引入 CDN**，也不要把 `axios.min.js` 改名或移动。

### 2. 四种常用请求

```js
// GET：查询参数放 params
const res = await axios.get('/api/users', {
  params: { page: 1, size: 10, keyword: '张' },
});
// 实际请求：/api/users?page=1&size=10&keyword=张

// POST：请求体放第二个参数
const res = await axios.post('/api/users', {
  name: '张三',
  age: 18,
});

// PUT：整体更新
await axios.put('/api/users/1', { name: '李四', age: 20 });

// DELETE：删除
await axios.delete('/api/users/1');
```

### 3. 请求方法语义

| 方法 | 作用 | 参数位置 | 是否幂等 |
| --- | --- | --- | --- |
| GET | 查询 | `params`（URL） | 是 |
| POST | 新增 | `data`（body） | 否 |
| PUT | 整体更新 | `data`（body） | 是 |
| PATCH | 局部更新 | `data`（body） | 否 |
| DELETE | 删除 | `params` 或路径 | 是 |

### 4. `params` 和 `data` 的区别（高频易错）

| 位置 | 写法 | 出现在 | 常见方法 |
| --- | --- | --- | --- |
| 查询字符串 | `params: { page: 1 }` | URL 后面 `?page=1` | GET / DELETE |
| 请求体 | `data`（第二个参数） | 请求 body | POST / PUT / PATCH |

```js
// ✅ GET 用 params
axios.get('/api/list', { params: { page: 1 } });

// ❌ GET 写成 data，参数不会出现在 URL 上
axios.get('/api/list', { data: { page: 1 } });

// ✅ POST 用第二个参数
axios.post('/api/login', { username, password });

// ❌ POST 把数据塞进 params，后端读 body 读不到
axios.post('/api/login', null, { params: { username, password } });
```

### 5. 响应对象长什么样

```js
const res = await axios.get('/api/list');
```

| 字段 | 含义 |
| --- | --- |
| `res.data` | 后端返回的响应体（**最常用**） |
| `res.status` | HTTP 状态码，如 200 |
| `res.statusText` | 状态文本，如 `OK` |
| `res.headers` | 响应头 |
| `res.config` | 本次请求的配置 |
| `res.request` | 底层的 XHR / fetch 对象 |

```js
// 方式一：先拿 res，再取 data
const res = await axios.get('/api/list');
console.log(res.data);

// 方式二：直接解构（最常用）
const { data } = await axios.get('/api/list');
console.log(data);
```

> [!warning] 最常见的丢分点
> `await axios.get(...)` 拿到的是**响应对象**，不是后端数据。
> 直接 `console.log(res)` 会看到 `{ data, status, headers, config, request }`。
> 真正要渲染的通常是 `res.data`；如果后端还包了一层，可能是 `res.data.data`。**以接口文档的返回示例为准。**

### 6. async/await + try/catch

```js
async function loadList() {
  try {
    const { data } = await axios.get('/api/list');
    console.log(data);
  } catch (error) {
    console.error('请求失败', error);
  }
}
```

等价写法（`.then/.catch`）：

```js
axios
  .get('/api/list')
  .then((res) => {
    console.log(res.data);
  })
  .catch((error) => {
    console.error(error);
  });
```

> [!tip] 考试选哪种
> 题目已有 `async` 函数就用 `await`；题目给的是 `.then` 链式结构就顺着写。**两种都能得分，别混着写一半。**

### 7. 错误对象怎么读

```js
try {
  await axios.get('/api/list');
} catch (error) {
  if (error.response) {
    // 服务器有响应，但状态码不是 2xx
    console.log('状态码', error.response.status);
    console.log('错误数据', error.response.data);
  } else if (error.request) {
    // 请求发出去了，但没有响应：断网、跨域、超时
    console.log('没有收到响应', error.request);
  } else {
    // 请求配置阶段就出错了
    console.log('请求配置错误', error.message);
  }
}
```

| 分支 | 含义 | 常见原因 |
| --- | --- | --- |
| `error.response` | 有响应且状态码非 2xx | 401、404、500 |
| `error.request` | 有请求无响应 | 跨域、断网、超时 |
| 都没有 | 配置 / 代码错误 | URL 非法、参数写错 |

### 8. 并发请求：Promise.all

```js
// 两个接口互不依赖，可以同时发
const [usersRes, ordersRes] = await Promise.all([
  axios.get('/api/users'),
  axios.get('/api/orders'),
]);

const users = usersRes.data;
const orders = ordersRes.data;
```

```js
// 有依赖关系时必须串行
const userRes = await axios.get('/api/user/1');
const orderRes = await axios.get(`/api/orders?userId=${userRes.data.id}`);
```

> [!tip] 什么时候用 Promise.all
> 两个请求**互不依赖** → 并行，快；
> 第二个请求需要第一个的结果 → 必须串行 `await`。
> 注意：`Promise.all` 里只要有一个 reject，整体就会 reject；需要「全部成功才继续」时正合适。

### 9. 创建实例：baseURL、timeout

```js
const request = axios.create({
  baseURL: 'http://localhost:3000',
  timeout: 5000,
  headers: { 'Content-Type': 'application/json' },
});

const { data } = await request.get('/api/list');
```

| 配置 | 作用 |
| --- | --- |
| `baseURL` | 所有请求的公共前缀 |
| `timeout` | 超时时间（毫秒），超时进 `catch` |
| `headers` | 默认请求头 |
| `withCredentials` | 是否携带 cookie（跨域时用） |
| `responseType` | `json` / `text` / `blob`（下载文件） |

> [!note] 实例 vs 全局
> `axios.create()` 创建的实例有**自己的一套拦截器和默认配置**，和全局 `axios` 互不影响。
> 蓝桥杯题目若给了 `request.js`，大概率已经创建好实例，直接在页面里 `import request from './request'` 用即可。

### 10. 拦截器：项目里很常见，考试先看懂

```js
// 请求拦截：统一加 token
axios.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// 响应拦截：统一解包 / 统一报错
axios.interceptors.response.use(
  (response) => response.data,
  (error) => {
    if (error.response && error.response.status === 401) {
      // token 失效，跳登录
    }
    return Promise.reject(error);
  }
);
```

> [!warning] 拦截器会改变返回值
> 如果响应拦截器写了 `return response.data`，那么调用处 `await axios.get(...)` 拿到的**直接就是 data**，不能再写 `.data`。
> 看到项目里有 `request.js` / `http.js`，先读它的拦截器，再决定怎么取值。

### 11. 取消请求（了解）

```js
const controller = new AbortController();

axios.get('/api/search', {
  params: { q: 'vue' },
  signal: controller.signal,
});

// 需要取消时
controller.abort();
```

> [!note] 版本差异
> axios 1.x 推荐 `signal`；旧版 0.x 用 `CancelToken`（已废弃）。
> 蓝桥杯很少直接考取消请求，但「搜索框快速输入导致旧结果覆盖新结果」的竞态问题可能以场景题出现。

## 六、和 Vue 结合：最常考的组合

### 1. 标准模板（Vue 2）

```js
new Vue({
  el: '#app',
  data() {
    return {
      list: [],
      loading: false,
      keyword: '',
    };
  },
  async created() {
    await this.fetchList();
  },
  methods: {
    async fetchList() {
      this.loading = true;
      try {
        const { data } = await axios.get('/api/list', {
          params: { keyword: this.keyword },
        });
        // 接口可能直接返回数组，也可能包一层 { code, data }
        this.list = Array.isArray(data) ? data : data.data;
      } catch (error) {
        console.error('加载失败', error);
      } finally {
        this.loading = false;
      }
    },
  },
});
```

```html
<div id="app">
  <input v-model="keyword" @input="fetchList" placeholder="搜索" />
  <ul v-if="!loading">
    <li v-for="item in list" :key="item.id">{{ item.name }}</li>
  </ul>
  <p v-else>加载中...</p>
</div>
```

### 2. 生命周期怎么选

| 钩子 | DOM 是否可用 | 适合做什么 |
| --- | --- | --- |
| `created` | 否 | **发请求拿数据**（最常用） |
| `mounted` | 是 | 需要操作 DOM / 初始化图表 |
| `beforeDestroy` | 是 | 清理定时器、取消请求 |

> [!tip] 数据请求放 `created`
> `created` 时 `data` 已初始化，越早发请求越早渲染。
> 但 ECharts 初始化需要 DOM，必须在 `mounted` 里 `echarts.init`，或者等数据回来后再 `init`。

### 3. 和 ECharts 结合

```js
async function renderChart() {
  const { data } = await axios.get('/api/sales');

  const chart = echarts.init(document.getElementById('main'));
  chart.setOption({
    xAxis: { type: 'category', data: data.map((item) => item.time) },
    yAxis: { type: 'value' },
    series: [{ type: 'bar', data: data.map((item) => Number(item.value)) }],
  });
}
```

图表配置详见 [[Echart考点分析]]，异步数据案例见 [[3.商品销量和销售额实时展示看板]]。

### 4. 和 Element Plus 结合（了解）

```html
<el-table :data="tableData" v-loading="loading">
  <el-table-column prop="name" label="姓名" />
  <el-table-column prop="age" label="年龄" />
</el-table>

<el-pagination
  layout="prev, pager, next"
  :total="total"
  :page-size="pageSize"
  @current-change="handlePageChange"
/>
```

```js
async handlePageChange(page) {
  const { data } = await axios.get('/api/users', {
    params: { page, size: this.pageSize },
  });
  this.tableData = data.list;
  this.total = data.total;
}
```

## 七、蓝桥杯答题流程（拿到题就按这个走）

1. **读接口文档**：URL、方法、请求参数、返回示例，逐字抄下来。
2. **看项目结构**：`index.html` 是否引入 axios？有没有 `request.js` / 拦截器？`baseURL` 是什么？
3. **找 TODO**：题目只允许改哪个文件？其余文件一律不动。
4. **先跑通请求**：在 `created` / `mounted` 里 `console.log(res)`，Network 面板确认请求发出、状态 200。
5. **确认取值层级**：`res.data` 还是 `res.data.data`？字段名大小写是否一致？
6. **渲染页面**：`this.list = ...`，模板用 `v-for` / `v-if` / `{{ }}`。
7. **补边界**：空数据、加载中、错误提示、分页 / 搜索参数。
8. **自测**：刷新页面、点分页、输入关键字、提交表单，看 Network 和页面是否同步。
9. **提交检测**：保持服务运行，点「提交检测」。

> [!tip] 开卷考试的黄金习惯
> 每道题先 `console.log` 完整响应，确认结构再写渲染逻辑。**猜字段名是丢分重灾区。**

## 八、常见题型与代码骨架

### 1. 列表加载

```js
async created() {
  const { data } = await axios.get('/api/list');
  this.list = data;
}
```

### 2. 条件搜索

```js
async search() {
  const { data } = await axios.get('/api/list', {
    params: { keyword: this.keyword },
  });
  this.list = data;
}
```

### 3. 分页

```js
async loadPage(page) {
  const { data } = await axios.get('/api/list', {
    params: { page, size: this.pageSize },
  });
  this.list = data.list;
  this.total = data.total;
}
```

### 4. 表单提交

```js
async submit() {
  try {
    const { data } = await axios.post('/api/users', {
      name: this.form.name,
      age: this.form.age,
    });
    if (data.code === 200) {
      this.$message.success('保存成功'); // Element UI；Element Plus 用 ElMessage.success
      await this.fetchList();
    }
  } catch (error) {
    this.$message.error('保存失败');
  }
}
```

### 5. 详情查询

```js
async loadDetail(id) {
  const { data } = await axios.get(`/api/users/${id}`);
  this.detail = data;
}
```

### 6. 删除

```js
async remove(id) {
  await axios.delete(`/api/users/${id}`);
  await this.fetchList();
}
```

> [!note] 接口路径以文档为准
> 上面是常见写法，实际 URL、方法、字段名**必须照题目接口文档**，不要凭经验改。

## 九、跨域：本地调试常见问题

### 什么是同源

同源 = 协议 + 域名 + 端口三者完全相同。

```
http://localhost:8080  →  http://localhost:3000   ❌ 端口不同
https://a.com           →  http://a.com            ❌ 协议不同
https://a.com           →  https://b.com           ❌ 域名不同
```

### 三种解决方式

| 方式 | 做法 | 适用 |
| --- | --- | --- |
| CORS | 后端响应头 `Access-Control-Allow-Origin` | 后端可控 |
| 代理 | 开发服务器转发请求 | 本地开发 |
| JSONP | 只支持 GET，已过时 | 老项目 |

Vue CLI 代理：

```js
// vue.config.js
module.exports = {
  devServer: {
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        pathRewrite: { '^/api': '' },
      },
    },
  },
};
```

Vite 代理：

```js
// vite.config.js
export default {
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
    },
  },
};
```

> [!tip] 蓝桥杯环境
> 比赛项目通常已经配好跨域或使用同源模拟接口，**优先照题目给的地址请求**。
> 只有本地自己调试、遇到 CORS 报错时，才需要看这一节。

## 十、常见坑（按丢分频率排序）

1. **把响应对象当数据**
   ```js
   const res = await axios.get('/api/list');
   this.list = res;        // ❌ 渲染出来是 { data, status, ... }
   this.list = res.data;   // ✅
   ```

2. **GET 用 `data`，POST 用 `params`**
   GET 的查询参数必须放 `params`；POST 的请求体放第二个参数。

3. **忘记 `await`**
   ```js
   const data = axios.get('/api/list'); // ❌ 拿到的是 Promise
   const { data } = await axios.get('/api/list'); // ✅
   ```

4. **响应层级猜错**
   后端可能返回 `{ code, msg, data }`，真正的列表在 `res.data.data`。**先 `console.log` 再取值。**

5. **字段名拼错 / 大小写不一致**
   `userName` vs `username`、`list` vs `data`，以接口文档为准。

6. **Vue 2 响应式陷阱**
   ```js
   this.obj.newKey = 1;              // ❌ 视图不更新
   this.$set(this.obj, 'newKey', 1); // ✅

   this.arr[0] = 'x';                // ❌ 视图不更新
   this.$set(this.arr, 0, 'x');      // ✅
   ```
   整体替换数组（`this.list = newList`）是响应式的。

7. **在 `data()` 里发请求**
   `data()` 只应该返回初始数据，请求放 `created` / `mounted`。

8. **普通函数丢失 `this`**
   ```js
   // ❌ this 不是 Vue 实例
   this.list.forEach(function (item) { this.doSomething(item); });
   // ✅ 箭头函数
   this.list.forEach((item) => this.doSomething(item));
   ```

9. **拦截器已经解包，还写 `.data`**
   项目里 `response => response.data` 之后，调用处直接拿 data。

10. **`Content-Type` 与后端不匹配**
    对象默认发 JSON；后端要表单格式时用 `URLSearchParams` 或 `qs`：
    ```js
    const params = new URLSearchParams();
    params.append('username', 'admin');
    params.append('password', '123456');
    await axios.post('/api/login', params);
    ```

11. **文件上传手动设 `Content-Type`**
    用 `FormData` 时**不要**手写 `Content-Type`，浏览器会自动加 boundary。

12. **分页从 0 还是 1 开始**
    后端文档写 `page=1` 就从 1 开始，别按数组下标习惯从 0 传。

13. **搜索竞态**
    快速输入时，先发的请求可能后返回，覆盖新结果。可用防抖、请求序号或 `AbortController`。

14. **超时设置过短**
    `timeout: 100` 在慢网络下必失败，一般 5000–10000ms。

15. **改错文件 / 改结构**
    题目只让改 `js/index.js` 就只改它；不要动文件名、目录、已有 id / class。

16. **把 axios 和 jQuery.ajax 混用**
    `$.ajax` 的回调参数是 `(data, status, xhr)`，axios 是 Promise，写法完全不同。

## 十一、自检清单

- [ ] 能说出 AJAX 的含义，以及它和 axios 的关系
- [ ] 能默写 XHR 的 GET 五步和 `readyState` 四个关键值
- [ ] 知道 200 / 401 / 404 / 500 分别代表什么
- [ ] 能写出 `axios.get` 带 `params` 的请求
- [ ] 能写出 `axios.post` 带请求体的请求
- [ ] 分得清 `params` 和 `data`
- [ ] 知道 `res.data` 才是后端数据
- [ ] 会用 `async/await` + `try/catch`
- [ ] 知道 `Promise.all` 的使用场景
- [ ] 看得懂请求 / 响应拦截器，知道它会不会改变返回值
- [ ] 会在 Vue 的 `created` 里发请求并渲染列表
- [ ] 会把 axios 数据接到 ECharts 的 `setOption`
- [ ] 知道同源策略和代理的基本配置
- [ ] 能说出至少 5 个常见坑

## 十二、30 分钟上手路径

| 时间 | 做什么 |
| --- | --- |
| 0–5 min | 读本文第二、三节，理解 AJAX 与 XHR |
| 5–15 min | 在空 HTML 里引入 axios，用公共测试接口发一次 GET，`console.log(res)` |
| 15–25 min | 把返回数组渲染成 `ul`，加一个输入框做 `params` 搜索 |
| 25–30 min | 改写成 `async/await` + `try/catch`，打开 Network 面板看请求 |

> [!tip] 练习接口
> 可以用 `https://jsonplaceholder.typicode.com/posts`、`https://httpbin.org/get` 这类公共接口练手；蓝桥杯考试时换成题目给的地址。

## 参考链接

- [MDN：AJAX 入门](https://developer.mozilla.org/zh-CN/docs/Web/Guide/AJAX/Getting_Started)
- [MDN：XMLHttpRequest](https://developer.mozilla.org/zh-CN/docs/Web/API/XMLHttpRequest)
- [MDN：Fetch API](https://developer.mozilla.org/zh-CN/docs/Web/API/Fetch_API)
- [MDN：HTTP 响应状态码](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Status)
- [axios 官方文档](https://axios-http.com/zh/docs/intro)
- [axios GitHub](https://github.com/axios/axios)
- [蓝桥云课](https://www.lanqiao.cn/)
