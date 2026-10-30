---
tags:
  - JavaScript
  - 基础
---

# 解构赋值（Destructuring）

> 一句话：解构赋值就是「**从对象或数组里把值取出来，直接赋给变量**」的语法糖。`const { message } = object4` 和 `const message = object4.message` 结果完全一样，只是写法更短。

## 从图片里的例子说起

```js
const object4 = {
    message: 'Good job!'
};

// 传统写法：一次次点出来
// const message = object4.message;

// 解构写法：一次声明，按名字自动匹配
const { message } = object4;

console.log(message); // 'Good job!'
```

两种写法做的是同一件事：

| 写法 | 含义 |
| --- | --- |
| `const message = object4.message;` | 手动指定：从 `object4` 取出 `message` 属性 |
| `const { message } = object4;` | 解构：在 `{}` 里写**想取的属性名**，JS 自动按同名去 `object4` 里找 |

关键理解：**等号左边 `{}` 里的 `message` 不是新对象，而是"我要取哪个属性"的声明**。它必须是 `object4` 里真实存在的键名。

## 基本语法

### 对象解构：按「键名」匹配

```js
const user = { name: '小明', age: 18, city: '北京' };

const { name, age } = user;
console.log(name, age); // 小明 18
```

- 按**属性名**匹配，**和书写顺序无关**。
- 解构时**没有对应键**的变量会是 `undefined`。

```js
const { name, height } = user;
console.log(height); // undefined
```

### 数组解构：按「位置」匹配

```js
const arr = [10, 20, 30];

const [a, b] = arr;
console.log(a, b); // 10 20

// 跳过某个位置用逗号占位
const [, , c] = arr;
console.log(c); // 30
```

- 对象看**名字**，数组看**顺序**。这是两者最大的区别。

## 常用进阶写法

### 1. 重命名：`{ 原键名: 新变量名 }`

```js
const { message: msg } = object4;
console.log(msg); // 'Good job!'
```

冒号左边是**源对象的键**，右边是**新变量名**。注意方向：`{ key: variable }`。

### 2. 设置默认值：`{ 键名 = 默认值 }`

当属性是 `undefined` 时（不存在或值为 `undefined`）才用默认值：

```js
const { message = '默认文案', author = '匿名' } = object4;
console.log(message); // 'Good job!'（有值，不用默认）
console.log(author);  // '匿名'（没有该键，用默认）
```

⚠️ 只有 `undefined` 会触发默认值，`null` 不会：

```js
const { x = 1 } = { x: null };
console.log(x); // null
```

### 3. 重命名 + 默认值

```js
const { message: msg = '默认' } = object4;
```

### 4. 嵌套解构

```js
const config = {
    user: { name: '小红', age: 20 },
    theme: 'dark'
};

const { user: { name }, theme } = config;
console.log(name, theme); // 小红 dark
```

### 5. 函数参数解构（实践中最常用）

```js
// 传统写法
function greet(options) {
    console.log(options.name, options.age);
}

// 参数解构：函数体里直接用 name / age
function greet({ name, age }) {
    console.log(name, age);
}

greet({ name: '小明', age: 18 }); // 小明 18
```

配合默认值，可以避免传参缺字段时报错：

```js
function greet({ name = '游客', age = 0 } = {}) {
    console.log(name, age);
}
greet(); // 游客 0（注意末尾的 = {} 防止整体 undefined）
```

### 6. 交换变量（数组解构的经典用法）

```js
let a = 1, b = 2;
[a, b] = [b, a];
console.log(a, b); // 2 1
```

### 7. 剩余元素 `...rest`

```js
const { name, ...others } = user;
console.log(others); // { age: 18, city: '北京' }

const [first, ...rest] = [1, 2, 3, 4];
console.log(first, rest); // 1 [2, 3, 4]
```

## 常见坑

1. **不能用 `const` 声明后再单独解构赋值**（`const` 必须先声明再初始化）：

   ```js
   let a, b;
   ({ a, b } = obj); // 整体解构要加圆括号，否则 `{` 被当成代码块
   ```

2. **键名必须对得上**，写错名字拿到的是 `undefined`，不会报错：

   ```js
   const { mesage } = object4; // 拼错了 → undefined，静默错误
   ```

3. **解构 `undefined` / `null` 会报错**：

   ```js
   const { x } = null; // TypeError
   ```

4. **默认值只在 `undefined` 时生效**，`null`、`0`、`''` 都不会触发。

5. **数组解构不是拷贝**，嵌套对象解构出的仍是**引用**，改它会改到原对象：

   ```js
   const { user } = config;
   user.age = 99; // config.user.age 也变成 99
   ```

## 什么时候用

- 从对象/数组里**只取几个字段**时 —— 比 `obj.a; obj.b;` 清爽。
- **函数参数很多**时 —— 用 `{ name, age }` 代替位置参数，调用方按需传。
- **处理接口返回数据**（如 `response.data`）时最常用。
- 模块导入 `import { x, y } from '...'` 本质上也是解构。
