---
tags:
  - 前端/JavaScript
  - JavaScript/数组
  - 速查
---

# JavaScript 数组 API 全解：创建、查找、遍历、变异与 ES2023 新方法

> [!summary] 先记住三条主线
> - **会改原数组（变异方法，9 个）**：`push`、`pop`、`shift`、`unshift`、`splice`、`sort`、`reverse`、`fill`、`copyWithin`。
> - **返回新数组（不改原数组）**：`map`、`filter`、`slice`、`concat`、`flat`、`flatMap`、`toSorted`、`toReversed`、`toSpliced`、`with`。
> - **返回单个值 / 布尔值 / 长度**：`find`、`findIndex`、`includes`、`indexOf`、`some`、`every`、`reduce`、`join`、`at`、`push`、`unshift` 等。
>
> 判断一个方法会不会“偷偷改数据”，先看它属于哪一组。

## 最常用的 API（先看这一节）

日常业务代码真正高频的就是下面这些。先会用，再去看后面的完整说明。

### 一张表

| API                | 用途           | 示例                                           | 改原数组 |
| ------------------ | ------------ | -------------------------------------------- | ---- |
| `map`              | 把每个元素转换成新值   | `[1, 2].map((x) => x * 2)` → `[2, 4]`        | 否    |
| `filter`           | 筛出满足条件的元素    | `[1, 2, 3].filter((x) => x > 1)` → `[2, 3]`  | 否    |
| `forEach`          | 遍历执行副作用      | `arr.forEach((x) => console.log(x))`         | 回调可改 |
| `find`             | 找第一个满足条件的元素  | `users.find((u) => u.id === 2)`              | 否    |
| `findIndex`        | 找第一个满足条件的下标  | `[5, 12].findIndex((x) => x > 10)` → `1`     | 否    |
| `some`             | 是否至少一个满足     | `[1, 2].some((x) => x > 1)` → `true`         | 否    |
| `every`            | 是否全部满足       | `[1, 2].every((x) => x > 1)` → `false`       | 否    |
| `reduce`           | 归约成一个值       | `[1, 2, 3].reduce((a, b) => a + b, 0)` → `6` | 否    |
| `includes`         | 是否包含某个值      | `[1, 2].includes(2)` → `true`                | 否    |
| `indexOf`          | 值首次出现的下标     | `[1, 2].indexOf(2)` → `1`                    | 否    |
| `push` / `pop`     | 尾部增 / 删      | `arr.push(3)`；`arr.pop()`                    | 是    |
| `splice`           | 任意位置增删改      | `arr.splice(1, 1, 9)`                        | 是    |
| `sort`             | 排序           | `arr.sort((a, b) => a - b)`                  | 是    |
| `slice`            | 截取 / 浅拷贝     | `arr.slice(1, 3)`                            | 否    |
| `join`             | 拼成字符串        | `["a", "b"].join("-")` → `"a-b"`             | 否    |
| `flat` / `flatMap` | 扁平化 / 映射后扁平化 | `[[1], [2]].flat()` → `[1, 2]`               | 否    |
| `Array.from`       | 类数组 / 可迭代转数组 | `Array.from("abc")` → `["a", "b", "c"]`      | 否    |
| `Array.isArray`    | 判断是否数组       | `Array.isArray([])` → `true`                 | 否    |

> 展开运算符 `...` 不算方法，但使用频率极高：浅拷贝 `[...arr]`、合并 `[...a, ...b]`、去重 `[...new Set(arr)]`。

### 按“我想做什么”选 API

| 需求          | 用哪个                       |
| ----------- | ------------------------- |
| 把每个元素变成另一个值 | `map`                     |
| 只保留一部分元素    | `filter`                  |
| 找单个对象       | `find`                    |
| 找对象的下标      | `findIndex`               |
| 判断“有没有”     | `includes` / `some`       |
| 判断“是不是全部”   | `every`                   |
| 求和、计数、分组    | `reduce`                  |
| 遍历但不关心返回值   | `forEach`                 |
| 在末尾加 / 删    | `push` / `pop`            |
| 在任意位置增删改    | `splice`                  |
| 排序          | `sort`（不改原数组用 `toSorted`） |
| 截取一段 / 浅拷贝  | `slice`                   |
| 拼字符串        | `join`                    |
| 拉平嵌套数组      | `flat` / `flatMap`        |
| 类数组转数组      | `Array.from`              |

### 六个最常用的组合

```js
// 1. 对象数组取字段
users.map((u) => u.name);

// 2. 先筛选再映射
users.filter((u) => u.active).map((u) => u.name);

// 3. 按 id 找对象
const user = users.find((u) => u.id === id);

// 4. 求和
const total = nums.reduce((sum, n) => sum + n, 0);

// 5. 排序但不动原数组
const sorted = [...nums].sort((a, b) => a - b);
// 或（ES2023）
const sorted2 = nums.toSorted((a, b) => a - b);

// 6. 去重
const unique = [...new Set(arr)];
```

### 选择顺序

```
要一个新数组？
├─ 是 → 转换用 map，筛选用 filter，截取用 slice，
│        拼接用 concat / 展开，拉平用 flat / flatMap
└─ 否 → 要一个元素？   → find
         要一个下标？   → findIndex / indexOf
         要一个布尔？   → includes / some / every
         要一个汇总值？ → reduce
         要改原数组？   → push / pop / splice / sort
```

> [!tip] 80/20 法则
> 先把 `map`、`filter`、`find`、`some`、`every`、`reduce`、`includes`、`push`、`splice`、`sort`、`slice`、`join` 这 12 个用熟，日常业务代码基本就够用了。
> 其余 API 遇到具体场景再查后面的详细说明。

---

## 〇、读法说明

每个方法按固定格式说明：

- **作用**：它解决什么问题。
- **返回**：返回值类型。
- **改原数组**：是否原地修改。
- **版本**：只标注较新的 API，未标注的基本是 ES5 及以前。
- **示例**：最短可运行代码。
- **注意**：容易踩的坑。

回调函数的通用签名：

```js
array.method((element, index, array) => {
  // element：当前元素
  // index：当前下标
  // array：正在遍历的原数组
});
```

`thisArg` 是可选参数，用来指定回调里的 `this`；箭头函数没有自己的 `this`，传了也无效。

---

## 一、创建与判断

### `Array(lengthOrElement, ...)`

**作用**：创建数组。**返回**：新数组。**改原数组**：不适用。

```js
new Array(3);        // [ <3 empty items> ]，长度 3 的空位数组
new Array(3, 4);     // [3, 4]
new Array("3");      // ["3"]
Array.of(3);         // [3]  ← 想要单个数字元素时用它
```

**注意**：
- 只传一个**数字**时，这个数字被当作长度，不是元素。
- 长度必须是 `0 ~ 2^32 - 1` 的整数，否则抛 `RangeError`。
- 空位（hole）不是 `undefined`：`0 in new Array(3)` 为 `false`。

### `Array.of(...items)`

**作用**：用参数创建数组，避免 `Array(3)` 的长度歧义。**返回**：新数组。

```js
Array.of(3);      // [3]
Array.of(1, 2);   // [1, 2]
Array.of();       // []
```

### `Array.from(arrayLike, mapFn?, thisArg?)`

**作用**：把**可迭代对象**或**类数组**转成真正的数组，可顺便映射。**返回**：新数组。

```js
Array.from("abc");                          // ["a", "b", "c"]
Array.from(new Set([1, 2, 2]));             // [1, 2]
Array.from({ length: 3 }, (_, i) => i);     // [0, 1, 2]
Array.from(document.querySelectorAll("li")); // NodeList → 数组
```

**注意**：
- 类数组必须有 `length`；没有迭代器也没有 `length` 会得到 `[]`。
- `Array.from({ length: 3 })` 生成的是 **3 个真正的 `undefined`**，不是空位。
- 第二个参数是映射函数，比 `Array.from(x).map(...)` 少一次遍历。

### `Array.fromAsync(asyncIterable, mapFn?, thisArg?)`

**作用**：异步版的 `Array.from`，支持异步迭代器、同步迭代器和类数组。**返回**：`Promise<Array>`。**版本**：较新，使用前查兼容性。

```js
async function* gen() {
  yield 1;
  yield 2;
}
await Array.fromAsync(gen()); // [1, 2]
```

### `Array.isArray(value)`

**作用**：判断是否为数组。**返回**：布尔值。

```js
Array.isArray([]);          // true
Array.isArray({ length: 0 }); // false
Array.isArray("abc");       // false
```

**注意**：比 `instanceof Array` 可靠，能跨 iframe / 不同执行上下文判断。

### `length`（属性，不是方法）

**作用**：读写数组长度。**返回**：数字。

```js
const a = [1, 2, 3];
a.length;      // 3
a.length = 1;  // 截断 → [1]
a.length = 3;  // 补空位 → [1, <2 empty items>]
```

**注意**：
- 改小会**删除**尾部元素；改大会产生空位。
- 最大长度 `2^32 - 1`。
- 清空数组可以用 `arr.length = 0`，这样其他引用也会看到清空；`arr = []` 只是让变量指向新数组。

---

## 二、读取与查找

### `at(index)`

**作用**：按索引读取，支持负数从末尾数。**返回**：元素或 `undefined`。**版本**：ES2022。

```js
const a = [10, 20, 30];
a.at(0);   // 10
a.at(-1);  // 30
a.at(9);   // undefined
```

**注意**：`arr[-1]` 取不到最后一个元素；负数索引用 `at` 或 `arr[arr.length - 1]`。

### `indexOf(searchElement, fromIndex = 0)`

**作用**：从左往右找元素首次出现的下标。**返回**：下标或 `-1`。

```js
[1, 2, 3, 2].indexOf(2);      // 1
[1, 2, 3, 2].indexOf(2, 2);   // 3
[1, 2, 3].indexOf(2, -1);     // -1（从最后一个开始找）
[NaN].indexOf(NaN);           // -1（严格相等，NaN !== NaN）
```

**注意**：
- 使用严格相等 `===`，所以找不到 `NaN`。
- 跳过空位。
- 只适合原始值；对象要按引用比较，查找对象通常用 `find`。

### `lastIndexOf(searchElement, fromIndex = length - 1)`

**作用**：从右往左找元素最后出现的下标。**返回**：下标或 `-1`。

```js
[1, 2, 3, 2].lastIndexOf(2);     // 3
[1, 2, 3, 2].lastIndexOf(2, 2);  // 1
[1, 2, 3].lastIndexOf(2, -2);    // 1
```

**注意**：同样使用严格相等，跳过空位。

### `includes(searchElement, fromIndex = 0)`

**作用**：判断数组是否包含某个元素。**返回**：布尔值。

```js
[1, 2, 3].includes(2);       // true
[1, 2, 3].includes(4);       // false
[1, 2, NaN].includes(NaN);   // true（SameValueZero，能匹配 NaN）
[1, 2, 3].includes(2, 2);    // false（从下标 2 开始找）
[1, 2, 3].includes(3, -1);   // true
```

**注意**：
- 用 `SameValueZero` 比较，`NaN` 能匹配，`-0` 与 `0` 相等。
- 空位会被当作 `undefined`：`[,].includes(undefined)` 为 `true`。
- 和 `indexOf` 的区别：`includes` 返回布尔值、能找 `NaN`；`indexOf` 返回下标、找不到 `NaN`。

### `find(callback, thisArg?)`

**作用**：找第一个满足条件的元素。**返回**：元素或 `undefined`。

```js
const users = [{ id: 1 }, { id: 2 }];
users.find((u) => u.id === 2); // { id: 2 }
users.find((u) => u.id === 9); // undefined
```

**注意**：
- 找不到返回 `undefined`，不是 `-1`。
- 空位也会进入回调（按 `undefined` 处理）。
- 只想判断“有没有”可以用 `some`，想拿全部结果用 `filter`。

### `findIndex(callback, thisArg?)`

**作用**：找第一个满足条件的元素下标。**返回**：下标或 `-1`。

```js
[5, 12, 8].findIndex((x) => x > 10); // 1
[5, 12, 8].findIndex((x) => x > 99); // -1
```

### `findLast(callback, thisArg?)`

**作用**：从右往左找第一个满足条件的元素。**返回**：元素或 `undefined`。**版本**：ES2023。

```js
[1, 2, 3, 4].findLast((x) => x % 2 === 0); // 4
```

### `findLastIndex(callback, thisArg?)`

**作用**：从右往左找第一个满足条件的元素下标。**返回**：下标或 `-1`。**版本**：ES2023。

```js
[1, 2, 3, 4].findLastIndex((x) => x % 2 === 0); // 3
```

### `keys()`

**作用**：返回下标的迭代器。**返回**：`Array Iterator`。

```js
[...["a", "b"].keys()]; // [0, 1]
```

### `values()`

**作用**：返回元素的迭代器。**返回**：`Array Iterator`。

```js
[...["a", "b"].values()]; // ["a", "b"]
```

### `entries()`

**作用**：返回 `[下标, 元素]` 的迭代器。**返回**：`Array Iterator`。

```js
[...["a", "b"].entries()]; // [[0, "a"], [1, "b"]]
```

**注意**：`keys/values/entries` 都常用于 `for...of` 和展开运算符。

---

## 三、遍历与转换

### `forEach(callback, thisArg?)`

**作用**：遍历数组，对每个元素执行回调。**返回**：`undefined`。**改原数组**：回调里可以改，但方法本身不返回新数组。

```js
[1, 2, 3].forEach((value, index) => {
  console.log(index, value);
});
// 0 1
// 1 2
// 2 3
```

**注意**：
- **不能 `break`**；`return` 只跳过当前这一次回调。
- 需要中途退出用 `for...of` 或 `some` / `every`。
- 跳过空位。

### `map(callback, thisArg?)`

**作用**：把每个元素映射成新值。**返回**：**等长的新数组**。

```js
[1, 2, 3].map((x) => x * 2); // [2, 4, 6]
[{ id: 1 }, { id: 2 }].map((u) => u.id); // [1, 2]
```

**注意**：
- 新数组长度始终等于原数组；不能靠 `map` 过滤元素。
- 跳过空位，但结果中对应位置仍是空位。
- 不会修改原数组，但如果回调返回对象，仍是浅拷贝。

### `flatMap(callback, thisArg?)`

**作用**：先 `map`，再把结果**扁平化一层**。**返回**：新数组。**版本**：ES2019。

```js
[1, 2, 3].flatMap((x) => [x, x * 2]); // [1, 2, 2, 4, 3, 6]
["a b", "c d"].flatMap((s) => s.split(" ")); // ["a", "b", "c", "d"]
```

**注意**：
- 只扁平化一层；更深层用 `flat(Infinity)`。
- 等价于 `map(...).flat(1)`，但更高效。
- 回调返回非数组值时，会原样放进结果。

### `filter(callback, thisArg?)`

**作用**：筛选出回调返回真值的元素。**返回**：新数组。

```js
[1, 2, 3, 4].filter((x) => x % 2 === 0); // [2, 4]
```

**注意**：
- 不修改原数组。
- 跳过空位。
- 回调返回真值就保留，不要求返回布尔值。

### `reduce(callback, initialValue?)`

**作用**：从左往右把数组归约成一个值。**返回**：最终累加值。

```js
[1, 2, 3].reduce((acc, cur) => acc + cur, 0); // 6
[1, 2, 3].reduce((acc, cur) => acc + cur);    // 6（以第一个元素为初始值）
```

回调参数：`(accumulator, currentValue, currentIndex, array)`。

**注意**：
- 空数组且**没有初始值**会抛 `TypeError`。
- 有初始值时，从下标 0 开始；没有初始值时，以下标 0 的元素作为初始值，从下标 1 开始。
- 跳过空位。
- 适合求和、计数、分组、数组转对象等。

### `reduceRight(callback, initialValue?)`

**作用**：从右往左归约。**返回**：最终累加值。

```js
["a", "b", "c"].reduceRight((acc, cur) => acc + cur); // "cba"
```

**注意**：参数顺序和 `reduce` 相同，只是遍历方向相反。

### `join(separator = ",")`

**作用**：把元素拼成字符串。**返回**：字符串。

```js
[1, 2, 3].join("-");          // "1-2-3"
[1, null, undefined, 2].join("-"); // "1---2"
```

**注意**：
- `null`、`undefined` 和空位都会变成空字符串。
- 不传参数默认用逗号。
- 对象元素会调用自己的 `toString()`。

### `toString()`

**作用**：等价于 `join(",")`。**返回**：字符串。

```js
[1, 2, 3].toString(); // "1,2,3"
```

### `toLocaleString()`

**作用**：按本地化规则拼接元素。**返回**：字符串。

```js
[1000, 2000].toLocaleString("zh-CN"); // "1,000,2,000"
```

**注意**：每个元素调用自己的 `toLocaleString`，适合数字、日期等本地化展示。

---

## 四、增删改（变异方法）

> 这一组都会**原地修改**原数组。需要保留原数据时，先 `slice()` / 展开拷贝一份。

### `push(...items)`

**作用**：向尾部追加一个或多个元素。**返回**：新长度。**改原数组**：是。

```js
const a = [1, 2];
a.push(3, 4); // 4
// a → [1, 2, 3, 4]
```

**注意**：`a.push([5, 6])` 会把整个数组当成一个元素，得到 `[1,2,3,4,[5,6]]`；想展开用 `a.push(...[5,6])`。

### `pop()`

**作用**：删除并返回最后一个元素。**返回**：被删除的元素或 `undefined`。**改原数组**：是。

```js
const a = [1, 2, 3];
a.pop(); // 3
// a → [1, 2]
```

### `shift()`

**作用**：删除并返回第一个元素。**返回**：被删除的元素或 `undefined`。**改原数组**：是。

```js
const a = [1, 2, 3];
a.shift(); // 1
// a → [2, 3]
```

**注意**：`shift` 需要移动后面所有元素，时间复杂度 `O(n)`；频繁从头部删除要考虑其他结构。

### `unshift(...items)`

**作用**：向头部插入一个或多个元素。**返回**：新长度。**改原数组**：是。

```js
const a = [3, 4];
a.unshift(1, 2); // 4
// a → [1, 2, 3, 4]
```

**注意**：同样需要移动元素，`O(n)`。

### `splice(start, deleteCount?, ...items)`

**作用**：在任意位置删除、插入、替换元素。**返回**：被删除元素组成的新数组。**改原数组**：是。

```js
const a = [1, 2, 3, 4];

a.splice(1, 2, 9, 9); // 返回 [2, 3]
// a → [1, 9, 9, 4]

a.splice(1, 0, 8);    // 返回 []
// a → [1, 8, 9, 9, 4]

a.splice(2);          // 返回 [9, 9, 4]，从下标 2 删到尾
// a → [1, 8]
```

**注意**：
- `start` 支持负数，从末尾数。
- `deleteCount` 省略时删除到末尾；为 `0` 时只插入不删除。
- 和 `slice` 只差一个字母：**`splice` 会改原数组，`slice` 不会**。

### `fill(value, start = 0, end = length)`

**作用**：用固定值填充指定区间。**返回**：原数组。**改原数组**：是。

```js
new Array(3).fill(0);          // [0, 0, 0]
[1, 2, 3, 4].fill(0, 1, 3);    // [1, 0, 0, 4]
```

**注意**：
- `end` 不包含。
- 填充对象时，所有位置共享**同一个引用**：
  ```js
  const a = new Array(2).fill({});
  a[0] === a[1]; // true
  ```
  需要独立对象时用 `Array.from({ length: 2 }, () => ({}))`。

### `copyWithin(target, start = 0, end = length)`

**作用**：把数组内部一段浅拷贝到另一个位置。**返回**：原数组。**改原数组**：是。

```js
[1, 2, 3, 4, 5].copyWithin(0, 3); // [4, 5, 3, 4, 5]
```

**注意**：区间是 `[start, end)`；支持负数；重叠区域会被安全处理。日常业务用得不多。

### `sort(compareFn?)`

**作用**：原地排序。**返回**：原数组。**改原数组**：是。

```js
[10, 2, 1].sort();                 // [1, 10, 2]  ← 默认按字符串排
[10, 2, 1].sort((a, b) => a - b);  // [1, 2, 10]  ← 数字升序
[10, 2, 1].sort((a, b) => b - a);  // [10, 2, 1]  ← 数字降序
```

**注意**：
- 默认会把元素转成字符串，按 UTF-16 码元比较；数字排序**必须传比较函数**。
- 比较函数返回负数表示 `a` 在前，正数表示 `b` 在前，`0` 表示相等。
- 不要返回布尔值：`(a, b) => a > b` 会被转成 `0/1`，排序结果不可靠。
- ES2019 起排序是**稳定**的。
- `undefined` 和空位会被排到末尾。

### `reverse()`

**作用**：原地反转数组。**返回**：原数组。**改原数组**：是。

```js
const a = [1, 2, 3];
a.reverse(); // [3, 2, 1]
```

---

## 五、截取、拼接与扁平化

### `slice(start = 0, end = length)`

**作用**：截取一段，返回**浅拷贝**。**返回**：新数组。**改原数组**：否。

```js
[1, 2, 3, 4].slice(1, 3);  // [2, 3]
[1, 2, 3, 4].slice(-2);    // [3, 4]
[1, 2, 3, 4].slice();      // [1, 2, 3, 4]  ← 常用作浅拷贝
```

**注意**：
- `end` 不包含。
- 负数从末尾数。
- 不传参数就是完整浅拷贝。
- 和 `splice` 的区别：`slice` 只读，`splice` 会改原数组。

### `concat(...items)`

**作用**：拼接数组或值。**返回**：新数组。**改原数组**：否。

```js
[1].concat([2, 3], 4); // [1, 2, 3, 4]
[1].concat([[2]]);     // [1, [2]]  ← 只展开一层
```

**注意**：
- 数组参数会被展开一层；非数组参数原样追加。
- 浅拷贝，不递归展开嵌套数组。
- 想扁平化用 `flat`。

### `flat(depth = 1)`

**作用**：按指定深度扁平化嵌套数组。**返回**：新数组。**改原数组**：否。**版本**：ES2019。

```js
[1, [2, [3]]].flat();            // [1, 2, [3]]
[1, [2, [3]]].flat(2);           // [1, 2, 3]
[1, [2, [3, [4]]]].flat(Infinity); // [1, 2, 3, 4]
```

**注意**：
- 默认只扁平化一层。
- 会移除空位。
- `flat(Infinity)` 可以完全摊平，但极深数组要留意性能。

---

## 六、ES2023 不可变方法

这四个方法都**不修改原数组**，返回新数组；适合 React / Vue 等强调不可变数据的场景。

### `toSorted(compareFn?)`

**作用**：返回排序后的新数组，原数组不变。**返回**：新数组。

```js
const a = [3, 1, 2];
const b = a.toSorted();
// a → [3, 1, 2]
// b → [1, 2, 3]
```

**注意**：参数和默认排序规则与 `sort` 完全一致，数字排序仍要传比较函数。

### `toReversed()`

**作用**：返回反转后的新数组，原数组不变。**返回**：新数组。

```js
const a = [1, 2, 3];
const b = a.toReversed();
// a → [1, 2, 3]
// b → [3, 2, 1]
```

### `toSpliced(start, deleteCount?, ...items)`

**作用**：返回删除/插入后的新数组，原数组不变。**返回**：新数组。

```js
const a = [1, 2, 3, 4];
const b = a.toSpliced(1, 2, 9);
// a → [1, 2, 3, 4]
// b → [1, 9, 4]
```

### `with(index, value)`

**作用**：返回替换了指定下标元素的新数组。**返回**：新数组。

```js
[1, 2, 3].with(1, 9);   // [1, 9, 3]
[1, 2, 3].with(-1, 9);  // [1, 2, 9]
[1, 2, 3].with(5, 9);   // RangeError：下标越界
```

**注意**：下标越界会抛 `RangeError`，这一点和 `arr[5] = 9` 不同。

---

## 七、相关但不算 Array 方法的 API

这些不是 `Array.prototype` 上的方法，但处理数组时经常一起用。

### 展开运算符 `...`

**作用**：把可迭代对象展开成数组元素，或做浅拷贝。

```js
const copy = [...arr];
const merged = [...a, ...b];
const max = Math.max(...nums);
```

**注意**：浅拷贝；超大数组用 `Math.max(...arr)` 可能触发调用栈上限。

### `Set` 去重

```js
const unique = [...new Set(arr)];
```

**注意**：`Set` 用 `SameValueZero` 比较，能去掉重复的 `NaN`；对象按引用去重。

### `Object.groupBy(items, callback)` / `Map.groupBy(items, callback)`

**作用**：按回调返回值分组。**版本**：ES2024。

```js
Object.groupBy([1, 2, 3, 4], (x) => (x % 2 ? "odd" : "even"));
// { odd: [1, 3], even: [2, 4] }

const map = Map.groupBy([1, 2, 3, 4], (x) => (x % 2 ? "odd" : "even"));
map.get("odd"); // [1, 3]
```

**注意**：
- `Object.groupBy` 返回**无原型对象**（`Object.create(null)`）。
- 键是对象时用 `Map.groupBy`。
- 早期提案里的 `Array.prototype.group` 已改名为 `Object.groupBy`，不要用旧写法。

### `structuredClone(value)`

**作用**：深拷贝支持结构化克隆的数据。

```js
const deep = structuredClone(nestedArray);
```

**注意**：函数、`DOM` 节点、`Symbol` 等不能被克隆，会抛 `DataCloneError`。

### 其他常用配套

```js
// 类数组 / 可迭代对象 → 数组
Array.from(nodeList);

// 数组 → 字符串
arr.join(",");

// 数组 → 键值对
Object.entries(Object.fromEntries(pairs));

// 遍历
for (const item of arr) { /* 可以 break */ }
```

---

## 八、速查总表

| API | 一句话 | 返回 | 改原数组 | 版本 |
| --- | --- | --- | --- | --- |
| `Array(n)` | 创建数组 / 指定长度 | 新数组 | — | ES1 |
| `Array.of(...)` | 用参数创建数组 | 新数组 | — | ES2015 |
| `Array.from(...)` | 可迭代/类数组转数组 | 新数组 | — | ES2015 |
| `Array.fromAsync(...)` | 异步版 from | `Promise<Array>` | — | 较新 |
| `Array.isArray(x)` | 是否数组 | 布尔 | — | ES5 |
| `length` | 长度，可截断/补空位 | 数字 | 是（赋值时） | ES1 |
| `at(i)` | 支持负数的读取 | 元素 | 否 | ES2022 |
| `indexOf(x)` | 首次出现的下标 | 下标 / -1 | 否 | ES5 |
| `lastIndexOf(x)` | 最后出现的下标 | 下标 / -1 | 否 | ES5 |
| `includes(x)` | 是否包含 | 布尔 | 否 | ES2016 |
| `find(cb)` | 第一个满足条件的元素 | 元素 / undefined | 否 | ES2015 |
| `findIndex(cb)` | 第一个满足条件的下标 | 下标 / -1 | 否 | ES2015 |
| `findLast(cb)` | 从右找第一个元素 | 元素 / undefined | 否 | ES2023 |
| `findLastIndex(cb)` | 从右找第一个下标 | 下标 / -1 | 否 | ES2023 |
| `keys()` | 下标迭代器 | Iterator | 否 | ES2015 |
| `values()` | 元素迭代器 | Iterator | 否 | ES2015 |
| `entries()` | `[下标, 元素]` 迭代器 | Iterator | 否 | ES2015 |
| `forEach(cb)` | 遍历 | undefined | 回调可改 | ES5 |
| `map(cb)` | 映射成等长新数组 | 新数组 | 否 | ES5 |
| `flatMap(cb)` | map + flat(1) | 新数组 | 否 | ES2019 |
| `filter(cb)` | 筛选 | 新数组 | 否 | ES5 |
| `reduce(cb, init?)` | 从左归约 | 任意值 | 否 | ES5 |
| `reduceRight(cb, init?)` | 从右归约 | 任意值 | 否 | ES5 |
| `join(sep)` | 拼成字符串 | 字符串 | 否 | ES1 |
| `toString()` | 等价 `join(",")` | 字符串 | 否 | ES1 |
| `toLocaleString()` | 本地化拼接 | 字符串 | 否 | ES1 |
| `push(...x)` | 尾部追加 | 新长度 | 是 | ES1 |
| `pop()` | 删除尾部 | 被删元素 | 是 | ES1 |
| `shift()` | 删除头部 | 被删元素 | 是 | ES1 |
| `unshift(...x)` | 头部插入 | 新长度 | 是 | ES1 |
| `splice(...)` | 任意位置增删改 | 被删元素数组 | 是 | ES1 |
| `fill(v, s, e)` | 区间填充 | 原数组 | 是 | ES2015 |
| `copyWithin(...)` | 内部浅拷贝覆盖 | 原数组 | 是 | ES2015 |
| `sort(cmp?)` | 原地排序 | 原数组 | 是 | ES1 |
| `reverse()` | 原地反转 | 原数组 | 是 | ES1 |
| `slice(s, e)` | 截取浅拷贝 | 新数组 | 否 | ES1 |
| `concat(...x)` | 拼接 | 新数组 | 否 | ES1 |
| `flat(depth)` | 扁平化 | 新数组 | 否 | ES2019 |
| `toSorted(cmp?)` | 排序的不可变版 | 新数组 | 否 | ES2023 |
| `toReversed()` | 反转的不可变版 | 新数组 | 否 | ES2023 |
| `toSpliced(...)` | splice 的不可变版 | 新数组 | 否 | ES2023 |
| `with(i, v)` | 替换单个元素的不可变版 | 新数组 | 否 | ES2023 |
| `[Symbol.iterator]()` | 默认迭代器，同 `values()` | Iterator | 否 | ES2015 |

---

## 九、最容易混淆的几组

### 1. `slice` vs `splice`

| 对比 | `slice(start, end)` | `splice(start, deleteCount, ...items)` |
| --- | --- | --- |
| 是否改原数组 | 否 | 是 |
| 返回什么 | 截取的新数组 | 被删除元素的新数组 |
| 用途 | 拷贝、截取、分页 | 删除、插入、替换 |
| 记忆 | **slice 像切片，只读** | **splice 像手术，动刀** |

```js
const a = [1, 2, 3, 4];
a.slice(1, 3);   // [2, 3]，a 不变
a.splice(1, 2);  // [2, 3]，a 变成 [1, 4]
```

### 2. `map` vs `forEach`

| 对比 | `map` | `forEach` |
| --- | --- | --- |
| 返回 | 等长新数组 | `undefined` |
| 用途 | 转换数据 | 执行副作用（打印、请求等） |
| 能否链式继续 | 能 | 不能 |
| 是否改原数组 | 否 | 回调里可能改 |

### 3. `filter` vs `find`

| 对比 | `filter` | `find` |
| --- | --- | --- |
| 返回 | 所有满足条件的元素（数组） | 第一个满足条件的元素 |
| 找不到 | `[]` | `undefined` |
| 用途 | 列表筛选 | 查找单个对象 |

### 4. `includes` vs `indexOf`

| 对比 | `includes` | `indexOf` |
| --- | --- | --- |
| 返回 | 布尔 | 下标 / -1 |
| `NaN` | 能匹配 | 不能匹配 |
| 空位 | 当作 `undefined` | 跳过 |
| 用途 | 判断存在 | 需要下标 |

### 5. `sort` vs `toSorted`

| 对比 | `sort` | `toSorted` |
| --- | --- | --- |
| 改原数组 | 是 | 否 |
| 返回 | 原数组 | 新数组 |
| 兼容性 | 所有环境 | 较新环境 |

### 6. `push/pop` vs `shift/unshift`

| 操作 | 位置 | 返回 | 性能 |
| --- | --- | --- | --- |
| `push` | 尾部加 | 新长度 | `O(1)` 均摊 |
| `pop` | 尾部删 | 被删元素 | `O(1)` |
| `unshift` | 头部加 | 新长度 | `O(n)` |
| `shift` | 头部删 | 被删元素 | `O(n)` |

### 7. `flat` vs `flatMap`

| 对比 | `flat` | `flatMap` |
| --- | --- | --- |
| 输入 | 已经是嵌套数组 | 回调返回数组 |
| 深度 | 可指定 | 固定一层 |
| 等价写法 | — | `map(...).flat(1)` |

### 8. `some` vs `every`

| 对比 | `some` | `every` |
| --- | --- | --- |
| 条件 | 至少一个满足 | 全部满足 |
| 空数组 | `false` | `true` |
| 短路 | 遇到 `true` 停止 | 遇到 `false` 停止 |

### 9. `at(-1)` vs `arr[arr.length - 1]`

两者结果相同；`at` 更短，且对 `-1` 以外的负下标也统一。`arr[-1]` 是普通属性访问，不是倒数第一个元素。

### 10. `arr.length = 0` vs `arr = []`

| 写法 | 效果 |
| --- | --- |
| `arr.length = 0` | 清空**原数组**，其他引用同步看到 |
| `arr = []` | 变量指向新数组，原数组和其他引用不变 |

---

## 十、常见坑

1. **数字排序不传比较函数**
   ```js
   [10, 2, 1].sort(); // [1, 10, 2]
   [10, 2, 1].sort((a, b) => a - b); // [1, 2, 10]
   ```

2. **比较函数返回布尔值**
   ```js
   arr.sort((a, b) => a > b);   // ❌ 布尔被转成 0/1
   arr.sort((a, b) => a - b);   // ✅ 返回数字
   ```

3. **`splice` 和 `slice` 记反**
   `splice` 改原数组并返回被删元素；`slice` 不改原数组并返回截取结果。

4. **以为 `forEach` 能 `break`**
   `forEach` 里 `return` 只跳过当前回调，不能终止循环。需要中断用 `for...of`、`some` 或 `every`。

5. **用 `map` 做过滤**
   `map` 返回等长数组，不能减少元素。过滤用 `filter`，过滤后再转换用 `filter(...).map(...)`。

6. **`reduce` 空数组不传初始值**
   ```js
   [].reduce((a, b) => a + b); // TypeError
   [].reduce((a, b) => a + b, 0); // 0
   ```

7. **`find` 找不到时按 `-1` 处理**
   `find` 返回 `undefined`；返回下标的是 `findIndex`。

8. **用 `indexOf` 找 `NaN`**
   `[NaN].indexOf(NaN)` 是 `-1`；判断存在用 `includes`。

9. **空位不是 `undefined`**
   ```js
   const a = new Array(3);
   0 in a;              // false
   a.includes(undefined); // true
   a.map((x) => 1);     // [ <3 empty items> ]
   ```

10. **`delete arr[i]` 留下空位**
    ```js
    const a = [1, 2, 3];
    delete a[1]; // [1, <1 empty item>, 3]，长度仍是 3
    a.splice(1, 1); // [1, 3]，真正删除
    ```

11. **遍历时修改数组**
    在 `forEach` / `map` 过程中 `push`、`splice` 可能导致跳过元素或死循环。需要修改时先拷贝，或从后往前遍历。

12. **`concat` 不会深度扁平化**
    ```js
    [1].concat([[2, [3]]]); // [1, [2, [3]]]
    ```

13. **`fill` 填对象共享引用**
    ```js
    const a = new Array(2).fill({});
    a[0] === a[1]; // true
    ```

14. **`Array(3)` 和 `Array.of(3)` 不同**
    ```js
    Array(3);    // 长度 3 的空位数组
    Array.of(3); // [3]
    ```

15. **`arr = []` 清空不了其他引用**
    只改当前变量的指向；要清空原数组用 `arr.length = 0`。

16. **`Math.max(...arr)` 遇到超大数组**
    展开参数过多会触发调用栈上限；用 `arr.reduce((a, b) => Math.max(a, b))`。

17. **用 `for...in` 遍历数组**
    `for...in` 会枚举可枚举属性（包括自定义属性），不是为数组设计的；用 `for...of`、`forEach` 或经典 `for`。

18. **`toSorted` / `toReversed` / `toSpliced` / `with` 兼容性**
    这些是 ES2023 方法，旧浏览器 / 旧 Node 可能没有；线上项目先确认目标环境。

19. **`sort` 会改原数组**
    不想改原数组用 `toSorted`，或先 `slice()` / `[...arr]` 拷贝。

20. **`splice` 的 `deleteCount` 省略**
    `arr.splice(2)` 会从下标 2 删到末尾；只想插入不删除要写 `arr.splice(2, 0, item)`。

---

## 十一、场景速查

### 去重

```js
const unique = [...new Set(arr)];
```

### 对象数组按字段去重

```js
const seen = new Set();
const unique = users.filter((u) => {
  if (seen.has(u.id)) return false;
  seen.add(u.id);
  return true;
});
```

### 扁平化

```js
const flat = arr.flat(Infinity);
```

### 按字段分组

```js
const grouped = Object.groupBy(users, (u) => u.city);
// 或
const grouped2 = users.reduce((acc, u) => {
  (acc[u.city] ??= []).push(u);
  return acc;
}, {});
```

### 对象数组排序

```js
users.sort((a, b) => a.age - b.age);
```

### 求和 / 最大 / 最小

```js
const sum = arr.reduce((a, b) => a + b, 0);
const max = arr.reduce((a, b) => Math.max(a, b), -Infinity);
const min = arr.reduce((a, b) => Math.min(a, b), Infinity);
```

### 生成 0 ~ n-1

```js
const seq = Array.from({ length: n }, (_, i) => i);
```

### 分页

```js
const page = arr.slice((pageNo - 1) * pageSize, pageNo * pageSize);
```

### 拷贝

```js
const shallow = [...arr];
const shallow2 = arr.slice();
const deep = structuredClone(arr);
```

### 清空

```js
arr.length = 0; // 保留原数组引用
```

### 随机取一个

```js
const item = arr[Math.floor(Math.random() * arr.length)];
```

### 交换两个元素

```js
[arr[i], arr[j]] = [arr[j], arr[i]];
```

### 统计频次

```js
const count = arr.reduce((acc, x) => {
  acc[x] = (acc[x] ?? 0) + 1;
  return acc;
}, {});
```

### 交集 / 并集 / 差集

```js
const setA = new Set(a);
const setB = new Set(b);

const intersection = [...setA].filter((x) => setB.has(x));
const union = [...new Set([...a, ...b])];
const difference = [...setA].filter((x) => !setB.has(x));
```

### 类数组转数组

```js
const list = Array.from(document.querySelectorAll("li"));
```

### 数组转对象

```js
const map = Object.fromEntries(arr.map((x) => [x.id, x]));
```

---

## 十二、记忆口诀

> **变异九兄弟：push、pop、shift、unshift、splice、sort、reverse、fill、copyWithin。**
> **新数组十兄弟：map、filter、slice、concat、flat、flatMap、toSorted、toReversed、toSpliced、with。**

> **slice 切片不动刀，splice 手术改原表；**
> **sort 数字传比较，includes 能把 NaN 找。**

> **map 等长做转换，filter 瘦身做筛选；**
> **find 只取第一个，reduce 万能将值攒。**
