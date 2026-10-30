---
tags:
  - JavaScript
  - 基础
  - 前端
---

# JSON 与 LocalStorage

> 一句话：`JSON.stringify` / `JSON.parse` 负责「数据 ↔ 字符串」的转换，`localStorage` 负责把字符串持久化在浏览器里。两者组合，就是前端最轻量的本地存储方案。

## 整体思路

`localStorage` 只能存**字符串**，所以存对象必须经过 JSON 转换；取出来时再转回对象。

```
JS 对象 / 数组
     │  JSON.stringify()
     ▼
 JSON 字符串
     │  localStorage.setItem()
     ▼
 浏览器本地磁盘
     │  localStorage.getItem()
     ▼
 JSON 字符串
     │  JSON.parse()
     ▼
JS 对象 / 数组
```

所以完整的一次「存储」是四步，缺一不可：

```js
// 存
const user = { name: '小明', age: 18 };
localStorage.setItem('user', JSON.stringify(user));

// 取
const raw = localStorage.getItem('user');
const user2 = raw ? JSON.parse(raw) : null;
```

## 一、JSON：负责「转换」

### 是什么

JSON 是一种**文本格式**，不是 JS 对象。它只有六个值类型：`string`、`number`、`boolean`、`null`、数组、对象。

和 JS 对象字面量的区别：

| 规则               | JSON  | JS 对象      |
| ---------------- | ----- | ---------- |
| 键                | 必须双引号 | 可省略引号      |
| 字符串              | 只能双引号 | 单双引号、反引号都行 |
| 注释               | 不允许   | 允许         |
| 尾逗号              | 不允许   | 允许         |
| `undefined` / 函数 | 不允许   | 允许         |

### 两个核心方法

```js
JSON.stringify(value, replacer, space); // 对象 → 字符串
JSON.parse(text, reviver);              // 字符串 → 对象
```

- `replacer`：函数或白名单数组，过滤要序列化的字段。
- `space`：缩进，`2` 表示两空格，便于调试查看。
- `reviver`：解析时逐字段处理，可把日期字符串还原成 `Date`。

```js
JSON.stringify(user, null, 2);        // 格式化输出，适合调试
JSON.stringify(user, ['name']);       // 只保留 name 字段
JSON.parse(text, (k, v) =>
  k === 'createdAt' ? new Date(v) : v
);                                    // 解析时还原日期
```

### 序列化会「丢」什么

这是存储数据时最容易踩的坑，必须记住：

| 原值 | `JSON.stringify` 后 | `JSON.parse` 读回 |
| --- | --- | --- |
| 普通对象 / 数组 | 正常 | 正常 |
| `Date` | ISO 字符串 | **字符串**，不是 `Date` |
| `undefined`（对象属性） | 整个属性被丢弃 | 属性不存在 |
| `undefined`（数组元素） | `null` | `null` |
| 函数 / `Symbol`（属性） | 整个属性被丢弃 | 属性不存在 |
| `NaN` / `Infinity` | `null` | `null` |
| `Map` / `Set` | `{}` | **空对象，数据丢失** |
| `BigInt` | 抛 `TypeError` | — |
| 循环引用 | 抛 `TypeError` | — |
| `-0` | `0` | `0` |

```js
JSON.stringify({ a: undefined, b: 1 }); // '{"b":1}'
JSON.stringify([undefined, 1]);         // '[null,1]'
JSON.stringify({ d: new Date() });      // '{"d":"2026-10-30T..."}'
JSON.stringify({ n: NaN });             // '{"n":null}'
JSON.stringify(new Map([['a', 1]]));    // '{}'
```

### 自定义序列化：`toJSON`

对象上有 `toJSON` 方法时，`stringify` 会优先调用它，可以控制自己怎么被存。

```js
const order = {
  id: 1,
  createdAt: new Date(),
  toJSON() {
    return { id: this.id, createdAt: this.createdAt.toISOString() };
  },
};
```

## 二、localStorage：负责「持久化」

### 基本 API

```js
localStorage.setItem('key', 'value'); // 增 / 改
localStorage.getItem('key');          // 查，不存在返回 null
localStorage.removeItem('key');       // 删
localStorage.clear();                 // 清空当前源的全部数据
localStorage.key(0);                  // 第 0 个键名
localStorage.length;                  // 条目数
```

> 也支持 `localStorage.foo = 'bar'` 这种属性写法，但会和内置方法名冲突，**不要用**，统一走 `setItem`。

### 五个特点

1. **同源隔离**：协议 + 域名 + 端口任一不同，就互不可见。
2. **容量约 5MB**：按 UTF-16 字符计，各浏览器略有差异。
3. **永不过期**：除非手动删除或用户清理浏览器数据。
4. **只存字符串**：写入其他类型会被隐式 `String()` 转换。
5. **同步阻塞**：读写都在主线程完成，数据大时会卡页面。

### 三种前端存储对比

|          | `localStorage` | `sessionStorage` | `cookie` |
| -------- | -------------- | ---------------- | -------- |
| 容量       | ~5MB           | ~5MB             | ~4KB     |
| 生命周期     | 永久，手动清除        | 标签页关闭即失效         | 可设过期时间   |
| 作用域      | 同源共享           | 同源 + 同标签页        | 同源 + 路径  |
| 随请求发给服务器 | 否              | 否                | 是        |
| API      | 同步，简单          | 同步，简单            | 字符串拼接，繁琐 |
| 适合存      | 偏好、缓存、草稿       | 临时表单、一次性数据       | 会话标识、小令牌 |

## 三、实战：把数据存进去

### 1. 存对象 / 数组

```js
// 对象
localStorage.setItem('user', JSON.stringify({ name: '小明', age: 18 }));

// 数组
localStorage.setItem('cart', JSON.stringify([
  { id: 1, title: '书', count: 2 },
]));

// 读
const cart = JSON.parse(localStorage.getItem('cart') || '[]');
```

### 2. 存日期：读回来要手动还原

```js
const order = { id: 1, createdAt: new Date() };
localStorage.setItem('order', JSON.stringify(order));

const data = JSON.parse(localStorage.getItem('order'));
data.createdAt instanceof Date; // false，只是字符串

const order2 = { ...data, createdAt: new Date(data.createdAt) };
```

### 3. 封装一个存储工具（推荐）

真实项目里不要到处手写 `JSON.stringify`，统一封装，顺带处理前缀、默认值、异常。

```js
const store = {
  prefix: 'app:',

  set(key, value) {
    try {
      localStorage.setItem(this.prefix + key, JSON.stringify(value));
      return true;
    } catch (err) {
      // 循环引用 → TypeError；容量满 → QuotaExceededError
      console.error(`[storage] 写入 ${key} 失败`, err);
      return false;
    }
  },

  get(key, fallback = null) {
    const raw = localStorage.getItem(this.prefix + key);
    if (raw === null) return fallback;
    try {
      return JSON.parse(raw);
    } catch {
      console.warn(`[storage] ${key} 数据损坏，已忽略`);
      return fallback;
    }
  },

  remove(key) {
    localStorage.removeItem(this.prefix + key);
  },

  // 只清自己的命名空间，避免误删别人的数据
  clear() {
    Object.keys(localStorage)
      .filter((k) => k.startsWith(this.prefix))
      .forEach((k) => localStorage.removeItem(k));
  },
};

// 用法
store.set('user', { name: '小明', age: 18 });
store.get('user');                          // { name: '小明', age: 18 }
store.get('user', {}).name;                 // 小明
store.get('missing', { name: '默认值' });   // { name: '默认值' }
```

要点：

- **加前缀**：同一域名下可能有很多应用共用 `localStorage`，前缀能避免 key 冲突。
- **读失败给默认值**：数据损坏、被手工改坏时不至于让页面崩溃。
- **写失败返回 `false`**：容量满或隐私模式时调用方可以降级处理。

### 4. 数据版本：结构变了怎么办

存进去的数据可能长期存在，字段结构升级后旧数据会「不认识」。两种做法：

```js
// 做法一：key 里带版本
const KEY = 'app:v2:user';

// 做法二：值里带版本，读取时迁移
const saved = store.get('user');
if (saved && saved.version !== 2) {
  // 旧结构 → 新结构
}
```

### 5. 跨标签页同步

一个标签页修改后，**其他**标签页会收到 `storage` 事件（当前页不触发）。

```js
window.addEventListener('storage', (e) => {
  if (e.key === 'app:theme') {
    console.log('其他标签页改了主题', e.oldValue, '→', e.newValue);
  }
  if (e.key === null) {
    console.log('其他标签页调用了 clear()');
  }
});
```

### 6. 容量检测

```js
function isStorageFull() {
  try {
    localStorage.setItem('__test__', '1');
    localStorage.removeItem('__test__');
    return false;
  } catch {
    return true;
  }
}
```

## 四、常见坑

1. **直接存对象**：`localStorage.setItem('u', {})` 会存成 `"[object Object]"`，取回来无法还原。必须 `JSON.stringify`。
2. **`getItem` 返回 `null` 而不是 `undefined`**：判断「有没有」应写 `raw !== null`，别用 `!raw`（空字符串会被误判）。统一用封装里的 `fallback`。
3. **`JSON.parse` 会抛错**：空串、`undefined`、被改坏的数据都会抛 `SyntaxError`，必须 `try/catch`。
4. **类型退化**：不经 JSON 直接 `setItem('age', 18)`，读出来是字符串 `"18"`；全程使用 JSON 才能保住 `number` / `boolean`。
5. **容量超限**：超出配额抛 `QuotaExceededError`，写入前最好估算大小。
6. **隐私模式 / 禁用存储**：部分浏览器访问 `localStorage` 本身就抛 `SecurityError`，需要兜底。
7. **同步阻塞**：几 MB 的 JSON 做 `stringify` + `parse` 会明显卡顿，不要存大对象。
8. **XSS 可读**：`localStorage` 无任何加密，同源脚本都能读，**密码、密钥、敏感 token 不要明文存**。
9. **数据可能被用户清掉**：它只是缓存，不能当作唯一数据源。
10. **`Map` / `Set` / `undefined` / 函数会丢**：需要先手动转成普通对象或数组再存。
11. **同名 key 直接覆盖**：没有「合并」语义，写之前先读出来改再写。
12. **`storage` 事件不在本标签页触发**：本页改完要自己同步更新 UI。

## 五、实践建议

- **统一封装**：前缀 + `JSON` + `try/catch` + 默认值，一处维护。
- **只存小数据**：偏好设置、主题、草稿、少量缓存；超过 1MB 考虑 IndexedDB。
- **大文件、大量结构化数据用 `IndexedDB`**：异步、容量大，不阻塞主线程。
- **会话级数据用 `sessionStorage`**：关掉标签页自动清理，适合临时表单。
- **敏感数据不入库**：真要存 token，考虑 HttpOnly Cookie 或后端会话。
- **结构变更加版本号**：给 key 或数据加 `version`，读取时迁移旧数据。
- **不要把它当数据库**：没有查询、没有事务、用户随时能清空。

> 记忆口诀：**JSON 管转换，localStorage 管落地；存前 stringify，取后 parse，永远 try/catch。**
