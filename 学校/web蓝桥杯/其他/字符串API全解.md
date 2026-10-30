---
tags:
  - 前端/JavaScript
  - JavaScript/字符串
  - 速查
---

# JavaScript 字符串 API 全解：查找、截取、替换、正则与 Unicode

> [!summary] 先记住三条主线
> - **字符串不可变**：`slice`、`replace`、`trim`、`toUpperCase` 等全部返回**新字符串**，原字符串永远不变。
> - **找位置用 `indexOf` / `search`，找内容用 `match` / `matchAll`，判断存在用 `includes` / `startsWith` / `endsWith`**。
> - **取子串只用 `slice` 就够**：`substring` 会自动交换参数，`substr` 已废弃，日常不要用。
>
> 字符串没有“变异方法”，所有操作都是复制一份再改。这一点和数组最大的区别。

## 考察内容

- **字符串不可变**：所有方法返回新字符串，原字符串不变。
- **查找与判断**：`indexOf`、`lastIndexOf`、`includes`、`startsWith`、`endsWith`、`search`。
- **截取子串**：`slice`、`substring`、`substr` 的参数与负数语义差异。
- **替换与拆分**：`replace`、`replaceAll`、`split`，以及 `g` 标志的作用。
- **正则匹配**：`match`、`matchAll`、捕获组、命名分组与常用正则语法。
- **大小写、修剪与补齐**：`toUpperCase`、`toLowerCase`、`trim`、`padStart`、`padEnd`。
- **Unicode 基础**：UTF-16 码元与码点的区别，用 `[...str]` 正确处理 emoji。
- **典型题型**：回文判断、首字母大写、驼峰转换、统计频次、补零格式化。

## 最常用的 API（先看这一节）

日常业务和蓝桥杯题目真正高频的就是下面这些。先会用，再去看后面的完整说明。

### 一张表

| API | 用途 | 示例 | 返回 |
| --- | --- | --- | --- |
| `includes` | 是否包含子串 | `"abc".includes("b")` → `true` | 布尔 |
| `startsWith` / `endsWith` | 是否以某串开头 / 结尾 | `"abc".startsWith("a")` → `true` | 布尔 |
| `indexOf` | 子串首次出现的下标 | `"abcabc".indexOf("b")` → `1` | 下标 / `-1` |
| `lastIndexOf` | 子串最后出现的下标 | `"abcabc".lastIndexOf("b")` → `4` | 下标 / `-1` |
| `slice` | 截取一段 | `"abcdef".slice(1, 3)` → `"bc"` | 新字符串 |
| `split` | 拆成数组 | `"a,b,c".split(",")` → `["a","b","c"]` | 数组 |
| `replace` | 替换**第一处** | `"a-b-c".replace("-", "+")` → `"a+b-c"` | 新字符串 |
| `replaceAll` | 替换**全部** | `"a-b-c".replaceAll("-", "+")` → `"a+b+c"` | 新字符串 |
| `match` | 正则匹配 | `"a1b2".match(/\d/g)` → `["1","2"]` | 数组 / `null` |
| `trim` | 去首尾空白 | `"  a  ".trim()` → `"a"` | 新字符串 |
| `toUpperCase` / `toLowerCase` | 转大写 / 小写 | `"Ab".toLowerCase()` → `"ab"` | 新字符串 |
| `padStart` / `padEnd` | 补齐到指定长度 | `"5".padStart(2, "0")` → `"05"` | 新字符串 |
| `repeat` | 重复拼接 | `"ab".repeat(3)` → `"ababab"` | 新字符串 |
| `at` | 支持负数的读取 | `"abc".at(-1)` → `"c"` | 字符 / `undefined` |
| `charAt` | 按下标取字符 | `"abc".charAt(1)` → `"b"` | 字符 / `""` |
| `concat` | 拼接 | `"a".concat("b")` → `"ab"` | 新字符串 |
| `search` | 正则查找下标 | `"a1".search(/\d/)` → `1` | 下标 / `-1` |
| `localeCompare` | 按本地规则比较 | `"a".localeCompare("b") < 0` → `true` | 负数 / 0 / 正数 |

> 模板字符串 `` `${}` `` 不是方法，但使用频率极高：拼接、换行、嵌入表达式都靠它。

### 按“我想做什么”选 API

| 需求 | 用哪个 |
| --- | --- |
| 判断“有没有” | `includes` |
| 判断开头 / 结尾 | `startsWith` / `endsWith` |
| 找子串位置 | `indexOf` / `lastIndexOf` |
| 用正则找位置 | `search` |
| 取一段字符 | `slice` |
| 按分隔符拆分 | `split` |
| 拆成单个字符 | `split("")` 或 `[...str]` |
| 替换第一处 | `replace` |
| 替换全部 | `replaceAll` 或 `replace(/x/g)` |
| 提取匹配和分组 | `match` / `matchAll` |
| 去首尾空白 | `trim` / `trimStart` / `trimEnd` |
| 大小写转换 | `toUpperCase` / `toLowerCase` |
| 补齐位数 | `padStart` / `padEnd` |
| 重复拼接 | `repeat` |
| 中英文 / 数字排序比较 | `localeCompare` |
| 下标取字符（支持负数） | `at` |
| Unicode 码点 | `codePointAt` / `String.fromCodePoint` |

### 六个最常用的组合

```js
// 1. 模板字符串拼接
const msg = `你好，${name}，你今年 ${age} 岁。`;

// 2. 首字母大写
const cap = (s) => s.charAt(0).toUpperCase() + s.slice(1);

// 3. 驼峰 ↔ 短横线
const toKebab = (s) => s.replace(/[A-Z]/g, (m) => "-" + m.toLowerCase());
const toCamel = (s) => s.replace(/-([a-z])/g, (_, c) => c.toUpperCase());

// 4. 统计字符出现次数
const count = [...str].reduce((acc, ch) => {
  acc[ch] = (acc[ch] ?? 0) + 1;
  return acc;
}, {});

// 5. 判断回文
const isPalindrome = (s) => {
  const t = s.toLowerCase().replace(/[^a-z0-9]/g, "");
  return t === [...t].reverse().join("");
};

// 6. 数字补零
const pad = (n) => String(n).padStart(2, "0");
```

### 选择顺序

```
要在字符串里找东西？
├─ 只要布尔       → includes / startsWith / endsWith
├─ 要下标         → indexOf / lastIndexOf（正则用 search）
└─ 要匹配内容     → match / matchAll（需要分组时）

要改字符串？
├─ 取一段        → slice
├─ 替换          → replace / replaceAll
├─ 拆分          → split
├─ 补长度        → padStart / padEnd
├─ 去空白        → trim / trimStart / trimEnd
└─ 改大小写      → toUpperCase / toLowerCase
```

> [!tip] 80/20 法则
> 先把 `includes`、`indexOf`、`slice`、`split`、`replace`、`replaceAll`、`trim`、`toUpperCase`、`toLowerCase`、`padStart`、`match`、`at` 这 12 个用熟，日常业务和蓝桥杯题目基本就够用了。
> 其余 API 遇到具体场景再查后面的详细说明。

---

## 〇、读法说明

每个方法按固定格式说明：

- **作用**：它解决什么问题。
- **返回**：返回值类型。
- **版本**：只标注较新的 API，未标注的基本是 ES5 及以前。
- **示例**：最短可运行代码。
- **注意**：容易踩的坑。

字符串方法**没有“改原字符串”这一列**，因为字符串是原始值、不可变，所有方法都返回新字符串：

```js
let s = "abc";
s.toUpperCase(); // "ABC"
console.log(s);  // "abc" ← 原字符串没变

s[0] = "x";      // 严格模式下抛 TypeError，非严格模式下静默失败
console.log(s);  // "abc"
```

需要“修改”时只能重新赋值：

```js
s = s.replace("a", "x"); // 变量指向新字符串
```

接受正则的方法只有这 6 个：`replace`、`replaceAll`、`match`、`matchAll`、`search`、`split`。

`includes`、`startsWith`、`endsWith` **不接受正则**，现代引擎传正则会直接抛 `TypeError`：

```js
"abc".includes(/b/); // TypeError（Chrome / Node 24 等新环境）
"abc".includes("b"); // true
```

`indexOf` / `lastIndexOf` 不抛错，但会把正则对象转成字符串再找，结果几乎总是 `-1`：

```js
"abc".indexOf(/b/); // -1（实际找的是字符串 "/b/"）
```

---

## 一、基础：不可变性与字符读取

### `length`（属性，不是方法）

**作用**：读取字符串长度。**返回**：数字。

```js
"abc".length;   // 3
"".length;      // 0
"😀".length;    // 2 ← 一个 emoji 占 2 个 UTF-16 码元
```

**注意**：
- `length` 数的是 **UTF-16 码元（code unit）**，不是“人类看到的字符数”。
- 中文常用汉字通常是 1 个码元，所以 `"你好".length` 是 `2`。
- emoji、生僻字（扩展 B 区及以后）会占 2 个码元。
- 想按“码点”数：`[...str].length` 或 `Array.from(str).length`。

### `str[index]`（属性访问）

**作用**：按下标读取字符。**返回**：字符或 `undefined`。

```js
const s = "abc";
s[0];   // "a"
s[-1];  // undefined ← 负数取不到末尾
s[9];   // undefined
```

**注意**：只读。`s[0] = "x"` 不会改变字符串。负数下标无效，用 `at(-1)`。

### `charAt(index)`

**作用**：按下标取字符。**返回**：字符；越界返回空字符串 `""`。

```js
"abc".charAt(0);   // "a"
"abc".charAt(-1);  // ""
"abc".charAt(9);   // ""
```

**注意**：和 `s[i]` 的区别是越界返回 `""` 而不是 `undefined`；和 `at` 的区别是不支持负数。

### `at(index)`

**作用**：按下标取字符，支持负数从末尾数。**返回**：字符或 `undefined`。**版本**：ES2022。

```js
const s = "abc";
s.at(0);   // "a"
s.at(-1);  // "c"
s.at(-3);  // "a"
s.at(9);   // undefined
```

**注意**：`at` 仍以 UTF-16 码元为单位，`"😀".at(0)` 只拿到半个代理项。

### `charCodeAt(index)`

**作用**：读取指定位置的 UTF-16 码元值。**返回**：`0 ~ 65535` 的整数；越界返回 `NaN`。

```js
"ABC".charCodeAt(0); // 65
"abc".charCodeAt(1); // 98
"😀".charCodeAt(0);  // 55357 ← 高代理项，不是 128512
"abc".charCodeAt(9); // NaN
```

**注意**：处理 emoji / 生僻字要用 `codePointAt`。`charCodeAt` 只能看到半个字符。

### `codePointAt(index)`

**作用**：读取指定位置的 Unicode 码点。**返回**：码点整数；越界返回 `undefined`。**版本**：ES2015。

```js
"A".codePointAt(0);     // 65
"😀".codePointAt(0);    // 128512
"😀".codePointAt(1);    // 56832 ← 落在低代理项上，只返回它自己的值
"abc".codePointAt(9);   // undefined
```

**注意**：索引仍然按 UTF-16 码元算，`codePointAt(1)` 不会自动跳到下一个字符。

### `String.fromCharCode(...codes)`

**作用**：用 UTF-16 码元创建字符串。**返回**：新字符串。

```js
String.fromCharCode(97);            // "a"
String.fromCharCode(55357, 56832);  // "😀"（高低代理项拼起来）
```

**注意**：超过 `0xFFFF` 的值会被截断成 16 位，**不能**用 `fromCharCode(128512)` 生成 emoji；用 `fromCodePoint`。

### `String.fromCodePoint(...codePoints)`

**作用**：用 Unicode 码点创建字符串。**返回**：新字符串。**版本**：ES2015。

```js
String.fromCodePoint(97);      // "a"
String.fromCodePoint(128512);  // "😀"
```

**注意**：参数必须是合法整数且在 `0 ~ 0x10FFFF` 内，否则抛 `RangeError`。

### `[Symbol.iterator]()` / 展开 `...`

**作用**：按 **码点** 迭代字符串。**返回**：字符串迭代器。

```js
[..."😀a"];        // ["😀", "a"]
Array.from("😀a"); // ["😀", "a"]
```

**注意**：`split("")` 按码元拆，`[...str]` 按码点拆。处理 emoji 必须用后者。

---

## 二、查找与判断

### `indexOf(searchString, position = 0)`

**作用**：从左往右找子串首次出现的下标。**返回**：下标或 `-1`。

```js
"abcabc".indexOf("b");       // 1
"abcabc".indexOf("b", 2);    // 4
"abcabc".indexOf("a", -5);   // 0 ← 负数按 0 处理
"abc".indexOf("", 99);       // 3 ← 空串被限制到 length
"abc".indexOf("x");          // -1
```

**注意**：
- 区分大小写。
- `position` 是**负数时当作 0**，这一点和 `slice` 的负数语义不同。
- 只接受字符串，不接受正则；正则请用 `search`。
- 找中文没问题，但仍是按码元匹配。

### `lastIndexOf(searchString, position = length)`

**作用**：从右往左找子串最后出现的下标。**返回**：下标或 `-1`。

```js
"abcabc".lastIndexOf("b");      // 4
"abcabc".lastIndexOf("b", 3);   // 1
"abcabc".lastIndexOf("a", -1);  // 0 ← 负数按 0 处理
"abc".lastIndexOf("x");         // -1
```

**注意**：`position` 指“从这个下标开始往左找”，同样会把负数钳到 0。

### `includes(searchString, position = 0)`

**作用**：判断是否包含子串。**返回**：布尔值。**版本**：ES2015。

```js
"abc".includes("b");      // true
"abc".includes("B");      // false（区分大小写）
"abc".includes("a", 1);   // false（从下标 1 开始找）
"abc".includes("", 99);   // true（空串总能找到）
```

**注意**：只接受字符串，现代引擎传正则抛 `TypeError`（旧环境曾转成字符串返回 `false`）。要正则判断用 `/re/.test(str)`。

### `startsWith(searchString, position = 0)`

**作用**：判断是否以某子串开头。**返回**：布尔值。**版本**：ES2015。

```js
"abc".startsWith("ab");      // true
"abc".startsWith("b", 1);    // true（从下标 1 开始看）
"abc".startsWith("a", -5);   // true（负数按 0）
"abc".startsWith(/a/);       // TypeError（现代引擎）
```

**注意**：传正则会抛 `TypeError`；大小写敏感。

### `endsWith(searchString, endPosition = length)`

**作用**：判断是否以某子串结尾。**返回**：布尔值。**版本**：ES2015。

```js
"abc".endsWith("bc");      // true
"abc".endsWith("b", 2);    // true ← 只在 "ab" 里找结尾
"abc".endsWith("c", 2);    // false
"abc".endsWith("C");       // false
```

**注意**：第二个参数是“截断位置”，不是起点。`endsWith("b", 2)` 等价于 `"ab".endsWith("b")`；传正则同样抛 `TypeError`。

### `search(regexp)`

**作用**：用正则查找第一次匹配的下标。**返回**：下标或 `-1`。

```js
"a1b2".search(/\d/);   // 1
"a1b2".search(/\d/g);  // 1 ← g 标志对 search 无效
"abc".search(/x/);     // -1
"a.b".search(".");     // 0 ← 字符串会被转成正则，"." 匹配任意字符
```

**注意**：
- 总是从开头找，忽略 `lastIndex`。
- 传入字符串时会被当成正则源码，特殊字符有含义。
- 只要位置不要内容时比 `match` 轻。

---

## 三、截取子串

### `slice(start = 0, end = length)`

**作用**：截取 `[start, end)` 区间。**返回**：新字符串。

```js
"abcdef".slice(1, 3);   // "bc"
"abcdef".slice(2);      // "cdef"
"abcdef".slice(-3);     // "def"  ← 负数从末尾数
"abcdef".slice(0, -1);  // "abcde"
"abcdef".slice(2, 1);   // ""
"abcdef".slice();       // "abcdef"
```

**注意**：
- `end` 不包含。
- 负数从末尾数，超过范围自动钳制。
- `start > end` 直接返回空串，**不会交换**。
- 日常截取优先用 `slice`，语义最稳定。

### `substring(start = 0, end = length)`

**作用**：截取 `[start, end)` 区间，参数自动修正。**返回**：新字符串。

```js
"abcdef".substring(1, 3);   // "bc"
"abcdef".substring(4, 1);   // "bcd" ← 自动交换成 substring(1, 4)
"abcdef".substring(-1, 2);  // "ab"  ← 负数当作 0
"abcdef".substring(0, -1);  // ""    ← 变成 substring(0, 0)
```

**注意**：
- 负数和 `NaN` 都当作 `0`。
- `start > end` 会自动交换，容易掩盖逻辑错误。
- 除了特殊需要，一般不用它，用 `slice`。

### `substr(start, length)`（已废弃）

**作用**：从 `start` 开始取 `length` 个字符。**返回**：新字符串。

```js
"abcdef".substr(1, 3);   // "bcd"
"abcdef".substr(-2);     // "ef"
"abcdef".substr(2, -1);  // ""（长度为负）
```

**注意**：
- **不是标准推荐 API**，MDN 标为遗留（Annex B）；不要在业务代码里用。
- 第二个参数是**长度**，不是结束下标，最容易和 `substring` 记混。

### 三者对比

| 对比 | `slice(start, end)` | `substring(start, end)` | `substr(start, length)` |
| --- | --- | --- | --- |
| 第二参数 | 结束下标（不含） | 结束下标（不含） | **长度** |
| 负数参数 | 从末尾数 | 当作 `0` | `start` 从末尾数，`length` 为负返回 `""` |
| `start > end` | 返回 `""` | 自动交换 | 不适用 |
| 是否推荐 | ✅ 推荐 | ⚠️ 少用 | ❌ 已废弃 |

```js
const s = "abcdef";
s.slice(0, -1);     // "abcde"
s.substring(0, -1); // ""
s.substr(0, -1);    // ""
```

---

## 四、替换、匹配与拆分

### `replace(pattern, replacement)`

**作用**：替换**第一处**匹配。**返回**：新字符串。

```js
"a-b-c".replace("-", "+");   // "a+b-c" ← 只换第一个
"a-b-c".replace(/-/g, "+");  // "a+b+c" ← 正则加 g 才全换
"abc".replace("b", "x");     // "axc"
"abc".replace(/B/i, "x");    // "axc" ← 忽略大小写
```

替换串里的特殊占位符：

| 写法 | 含义 |
| --- | --- |
| `$$` | 插入一个 `$` |
| `$&` | 插入整个匹配 |
| `` $` `` | 插入匹配之前的字符串 |
| `$'` | 插入匹配之后的字符串 |
| `$1`、`$2` | 第 n 个捕获组 |
| `$<name>` | 命名捕获组 |

```js
"abc".replace("b", "[$&]");                    // "a[b]c"
"2024-10".replace(/(\d+)-(\d+)/, "$2/$1");     // "10/2024"
"abc".replace("b", "$$");                      // "a$c"
```

替换值可以是函数：

```js
"a1b2".replace(/\d/g, (match) => `[${match}]`); // "a[1]b[2]"
```

回调参数：`(match, p1, p2, ..., offset, string, groups)`。

**注意**：
- 传字符串模式时**只替换第一处**，这是最常见的错误。
- 需要全部替换：`replaceAll` 或 `replace(/x/g, ...)`。
- 用户输入拼进正则前要转义：`str.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")`。

### `replaceAll(pattern, replacement)`

**作用**：替换**全部**匹配。**返回**：新字符串。**版本**：ES2021。

```js
"a-b-c".replaceAll("-", "+");   // "a+b+c"
"aaa".replaceAll("a", "b");     // "bbb"
"a-b-c".replaceAll(/-/g, "+");  // "a+b+c"
```

**注意**：
- 正则必须带 `g`，否则抛 `TypeError`：
  ```js
  "abc".replaceAll(/b/, "x");  // TypeError
  "abc".replaceAll(/b/g, "x"); // "axc"
  ```
- 字符串模式不需要 `g`，直接全换。
- 替换串的 `$` 规则和 `replace` 相同。

### `match(regexp)`

**作用**：用正则匹配字符串。**返回**：匹配结果数组或 `null`。

```js
// 不带 g：返回第一个匹配，附带 index、input、groups
"2024-10-27".match(/(\d+)-(\d+)-(\d+)/);
// ["2024-10-27", "2024", "10", "27", index: 0, input: "2024-10-27", groups: undefined]

// 带 g：返回所有匹配的字符串，没有分组信息
"2024-10-27".match(/\d+/g); // ["2024", "10", "27"]

// 命名分组
const m = "2024-10-27".match(/(?<year>\d+)-(?<month>\d+)-(?<day>\d+)/);
m.groups.year;  // "2024"
m.groups.month; // "10"

// 找不到
"abc".match(/x/); // null
```

**注意**：
- 找不到返回 `null`，不是 `[]`；直接取 `[0]` 会报错。
- 带 `g` 时**拿不到分组**，需要分组或 `index` 时去掉 `g`。
- 传字符串会被转成正则。

### `matchAll(regexp)`

**作用**：返回所有匹配的迭代器，保留分组信息。**返回**：迭代器。**版本**：ES2020。

```js
const str = "a1 b2 c3";
const result = [...str.matchAll(/(?<letter>[a-z])(?<num>\d)/g)];
// [
//   ["a1", "a", "1", index: 0, ...],
//   ["b2", "b", "2", index: 3, ...],
//   ["c3", "c", "3", index: 6, ...],
// ]
result[0].groups.letter; // "a"
```

**注意**：
- 正则**必须带 `g`**，否则抛 `TypeError`。
- 返回迭代器，需要 `[...]`、`Array.from` 或 `for...of` 展开。
- 需要“所有匹配 + 分组”时，`matchAll` 是标准答案；旧写法是循环 `exec`。

### `split(separator?, limit?)`

**作用**：按分隔符拆成数组。**返回**：新数组。

```js
"a,b,c".split(",");          // ["a", "b", "c"]
"a,b,c".split(",", 2);       // ["a", "b"] ← 限制个数
"abc".split("");             // ["a", "b", "c"]
"a1b2c".split(/\d/);         // ["a", "b", "c"]
"a1b2c".split(/(\d)/);       // ["a", "1", "b", "2", "c"] ← 捕获组保留
"a,b,".split(",");           // ["a", "b", ""] ← 末尾空串保留
"abc".split();               // ["abc"]
"".split("");                // []
"".split(",");               // [""]
```

**注意**：
- 不传分隔符 → 整个字符串作为唯一元素。
- 分隔符为空串 → 按码元拆，**拆不开 emoji**，用 `[...str]`。
- 正则里的**捕获组会进入结果**，不需要时用 `(?:...)`。
- `limit` 为 `0` 时返回 `[]`。
- 想拆成单词：`str.match(/[a-z]+/gi)` 通常比 `split(/\W+/)` 更干净。

### 正则速记

```js
// 标志
g  // 全局，找全部
i  // 忽略大小写
m  // 多行模式，^ $ 匹配每行
s  // dotAll，. 能匹配换行
u  // Unicode 模式，按码点处理
y  // sticky，必须从 lastIndex 处匹配
d  // 匹配结果附带索引（ES2022）

// 分组
(x)          // 捕获组
(?:x)        // 非捕获组
(?<name>x)   // 命名捕获组
(?=x)        // 先行断言：后面是 x
(?!x)        // 否定先行断言
(?<=x)       // 后行断言：前面是 x（ES2018）
(?<!x)       // 否定后行断言

// 常用类与量词
\d \D        // 数字 / 非数字
\w \W        // 字母数字下划线 / 非
\s \S        // 空白 / 非空白
.            // 除换行外任意字符（s 模式下含换行）
[abc] [^abc] // 字符集 / 排除
* + ? {n} {n,} {n,m}  // 量词，加 ? 变懒惰
^ $ \b \B    // 锚点与单词边界
```

常用校验：

```js
const isEmail = (s) => /^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(s);
const isPhone = (s) => /^1[3-9]\d{9}$/.test(s);
const hasChinese = (s) => /[\u4e00-\u9fa5]/.test(s);
```

---

## 五、拼接与填充

### `concat(...strings)`

**作用**：拼接一个或多个字符串。**返回**：新字符串。

```js
"a".concat("b", "c"); // "abc"
"a".concat(1, null);  // "a1null" ← 非字符串会被转换
```

**注意**：日常更推荐 `+` 或模板字符串，可读性更好。

### `repeat(count)`

**作用**：把字符串重复 `count` 次。**返回**：新字符串。**版本**：ES2015。

```js
"ab".repeat(3);   // "ababab"
"ab".repeat(0);   // ""
"ab".repeat(2.9); // "abab" ← 小数被截断
"ab".repeat(-1);  // RangeError
"ab".repeat(Infinity); // RangeError
```

**注意**：
- `count` 会被转成整数并向下取整。
- 负数或 `Infinity` 抛 `RangeError`。
- 复用 `new Array(n).join("x")` 的写法已经过时。

### `padStart(targetLength, padString = " ")`

**作用**：在开头补字符直到指定长度。**返回**：新字符串。**版本**：ES2017。

```js
"5".padStart(3, "0");       // "005"
"abc".padStart(2, "0");     // "abc"（已经够长，原样返回）
"abc".padStart(6, "12345"); // "123abc"（补串被截断）
"5".padStart(3);            // "  5"（默认空格）
```

**注意**：
- 只补不截；`targetLength` 小于原长度时原样返回。
- 补串太长时只取**开头**需要的部分。
- 补串为空串时返回原字符串。

### `padEnd(targetLength, padString = " ")`

**作用**：在结尾补字符直到指定长度。**返回**：新字符串。**版本**：ES2017。

```js
"5".padEnd(3, "0");         // "500"
"abc".padEnd(6, "12345");   // "abc123"
"abc".padEnd(2, "0");       // "abc"
```

**注意**：常用于对齐输出、生成表格文本。

### 模板字符串 `` `...` ``

**作用**：字符串插值、多行文本、标签模板。**返回**：字符串。

```js
const name = "张三";
const msg = `你好，${name}！`;

const html = `
  <div>${name}</div>
`;

// 表达式
`${1 + 2}`; // "3"
```

**注意**：
- 反引号内的换行和缩进会保留。
- `${}` 里可以放任意表达式，但不能放语句。
- 需要原样输出反引号或 `${` 时用 `\``、`\${`。

### `String.raw`

**作用**：标签模板，返回未经转义的原始字符串。**返回**：字符串。**版本**：ES2015。

```js
String.raw`C:\Users\new`; // "C:\\Users\\new" ← 反斜杠不转义
String.raw`a\nb`.length;  // 4 ← 不是 3
```

**注意**：适合写 Windows 路径、正则源码；不能用于普通函数调用，必须写成标签模板。

---

## 六、大小写、比较与规范化

### `toUpperCase()` / `toLowerCase()`

**作用**：转大写 / 小写。**返回**：新字符串。

```js
"Abc".toUpperCase(); // "ABC"
"Abc".toLowerCase(); // "abc"
"Straße".toUpperCase(); // "STRASSE"
```

**注意**：
- 对中文、数字、符号无影响。
- 大小写转换可能改变长度（如 `ß` → `SS`）。
- 做“忽略大小写比较”时先统一转小写。

### `toLocaleUpperCase(locales?)` / `toLocaleLowerCase(locales?)`

**作用**：按语言规则做大小写转换。**返回**：新字符串。

```js
"i".toLocaleUpperCase("tr");  // "İ"（土耳其语）
"i".toUpperCase();            // "I"（默认规则）
```

**注意**：只有处理土耳其语等特殊语言时才需要；普通场景用 `toUpperCase`。

### `localeCompare(compareString, locales?, options?)`

**作用**：按本地化规则比较两个字符串。**返回**：负数 / `0` / 正数。

```js
"a".localeCompare("b") < 0;  // true
"b".localeCompare("a") > 0;  // true
"a".localeCompare("a");      // 0

// 数字按大小比较
["10", "2", "1"].sort();     // ["1", "10", "2"] ← 字典序
["10", "2", "1"].sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
// ["1", "2", "10"]

// 中文按拼音排序
["张三", "李四", "王五"].sort((a, b) => a.localeCompare(b, "zh"));
```

**注意**：
- **不要依赖返回值恰好是 `-1` / `1`**，标准只保证正负；用 `< 0`、`> 0` 判断。
- 中文排序、版本号排序、文件名排序都应该用它，而不是直接用 `<`。
- 常用选项：`numeric`（数字感知）、`sensitivity`（大小写/重音敏感度）、`ignorePunctuation`。

### `normalize(form = "NFC")`

**作用**：按 Unicode 规范化形式整理字符串。**返回**：新字符串。**版本**：ES2015。

```js
"e\u0301".length;                  // 2（e + 组合重音符）
"e\u0301".normalize("NFC").length; // 1（合成 é）
"e\u0301".normalize("NFC") === "é"; // true
```

**注意**：
- 四种形式：`NFC`（默认，合成）、`NFD`（分解）、`NFKC`、`NFKD`。
- 用户输入、文件名比较前先 `normalize`，避免“看起来一样但不相等”。
- 规范化不等于去掉重音；去重音还要配合正则。

### `isWellFormed()` / `toWellFormed()`

**作用**：检查 / 修复字符串中的孤立代理项。**返回**：布尔 / 新字符串。**版本**：ES2024。

```js
"😀".isWellFormed();     // true
"\uD800".isWellFormed(); // false ← 孤立的高代理项
"\uD800".toWellFormed(); // "\uFFFD"（替换字符）
```

**注意**：较新 API，旧环境可能没有；处理截断的 emoji、乱码数据时有用。

---

## 七、修剪与类型转换

### `trim()`

**作用**：去掉首尾空白。**返回**：新字符串。**版本**：ES5。

```js
"  abc  ".trim();   // "abc"
"\t\n abc \r\n".trim(); // "abc"
```

**注意**：
- 去掉的是 ECMAScript 定义的空格和行终止符，包括全角空格 `U+3000`。
- **去不掉零宽空格 `U+200B`**，需要 `replace(/\u200B/g, "")`。
- 不改变中间的空格。

### `trimStart()` / `trimEnd()`

**作用**：只去开头 / 只去结尾空白。**返回**：新字符串。**版本**：ES2019。

```js
"  abc  ".trimStart(); // "abc  "
"  abc  ".trimEnd();   // "  abc"
```

**注意**：别名是 `trimLeft` / `trimRight`，新代码用新名字。

### `toString()` / `valueOf()`

**作用**：返回字符串原始值。**返回**：字符串。

```js
const s = "abc";
s.toString(); // "abc"
s.valueOf();  // "abc"
```

**注意**：对字符串原始值调用时结果就是它自己；主要意义在于包装对象。

### `String(value)`

**作用**：把任意值转成字符串。**返回**：字符串。

```js
String(123);        // "123"
String(true);       // "true"
String(null);       // "null"
String(undefined);  // "undefined"
String([1, 2]);     // "1,2"
String({});         // "[object Object]"
String(Symbol("a")); // "Symbol(a)"
```

**注意**：
- `String(Symbol())` 是合法的，而 `"" + Symbol()` 会抛 `TypeError`。
- `String(null)` 和 `String(undefined)` 分别得到 `"null"`、`"undefined"`，不是空串。

### 字符串 ↔ 数字

```js
// 数字 → 字符串
String(255);          // "255"
(255).toString(16);   // "ff"
(5).toString(2);      // "101"
`${255}`;             // "255"

// 字符串 → 数字
Number("12");         // 12
Number("");           // 0
Number("  ");         // 0
Number("12px");       // NaN
+"3.14";              // 3.14
parseInt("12px");     // 12
parseInt("0x10");     // 16
parseInt("10", 2);    // 2
parseFloat("3.14abc"); // 3.14
```

**注意**：
- `Number` 要求整串都是合法数字，`parseInt` / `parseFloat` 解析到非法字符就停。
- `parseInt` 遇到前导零或十六进制会按规则解析，建议**总是传基数**。
- `Number("")` 是 `0`，不是 `NaN`；判空要单独处理。

---

## 八、速查总表

| API | 一句话 | 返回 | 版本 |
| --- | --- | --- | --- |
| `length` | 字符串长度（UTF-16 码元） | 数字 | ES1 |
| `str[i]` | 下标读字符 | 字符 / `undefined` | ES5 |
| `at(i)` | 支持负数的读取 | 字符 / `undefined` | ES2022 |
| `charAt(i)` | 下标读字符 | 字符 / `""` | ES1 |
| `charCodeAt(i)` | UTF-16 码元值 | 数字 / `NaN` | ES1 |
| `codePointAt(i)` | Unicode 码点 | 数字 / `undefined` | ES2015 |
| `String.fromCharCode(...)` | 码元建字符串 | 字符串 | ES1 |
| `String.fromCodePoint(...)` | 码点建字符串 | 字符串 | ES2015 |
| `String.raw` | 原始字符串标签模板 | 字符串 | ES2015 |
| `indexOf(s, pos)` | 首次出现下标 | 下标 / -1 | ES1 |
| `lastIndexOf(s, pos)` | 最后出现下标 | 下标 / -1 | ES1 |
| `includes(s, pos)` | 是否包含 | 布尔 | ES2015 |
| `startsWith(s, pos)` | 是否以某串开头 | 布尔 | ES2015 |
| `endsWith(s, pos)` | 是否以某串结尾 | 布尔 | ES2015 |
| `search(re)` | 正则查找下标 | 下标 / -1 | ES3 |
| `match(re)` | 正则匹配 | 数组 / `null` | ES3 |
| `matchAll(re)` | 所有匹配（含分组） | 迭代器 | ES2020 |
| `replace(pat, rep)` | 替换第一处 | 新字符串 | ES3 |
| `replaceAll(pat, rep)` | 替换全部 | 新字符串 | ES2021 |
| `split(sep, limit)` | 拆成数组 | 数组 | ES3 |
| `slice(start, end)` | 截取 | 新字符串 | ES3 |
| `substring(start, end)` | 截取（自动交换） | 新字符串 | ES3 |
| `substr(start, len)` | 截取（按长度，废弃） | 新字符串 | ES3 |
| `concat(...)` | 拼接 | 新字符串 | ES3 |
| `repeat(n)` | 重复 | 新字符串 | ES2015 |
| `padStart(len, pad)` | 头部补齐 | 新字符串 | ES2017 |
| `padEnd(len, pad)` | 尾部补齐 | 新字符串 | ES2017 |
| `trim()` | 去首尾空白 | 新字符串 | ES5 |
| `trimStart()` | 去头部空白 | 新字符串 | ES2019 |
| `trimEnd()` | 去尾部空白 | 新字符串 | ES2019 |
| `toUpperCase()` | 转大写 | 新字符串 | ES1 |
| `toLowerCase()` | 转小写 | 新字符串 | ES1 |
| `toLocaleUpperCase()` | 本地化大写 | 新字符串 | ES3 |
| `toLocaleLowerCase()` | 本地化小写 | 新字符串 | ES3 |
| `localeCompare(s)` | 本地化比较 | 负数 / 0 / 正数 | ES3 |
| `normalize(form)` | Unicode 规范化 | 新字符串 | ES2015 |
| `isWellFormed()` | 是否含孤立代理项 | 布尔 | ES2024 |
| `toWellFormed()` | 修复孤立代理项 | 新字符串 | ES2024 |
| `toString()` | 原始字符串 | 字符串 | ES1 |
| `valueOf()` | 原始字符串 | 字符串 | ES1 |
| `[Symbol.iterator]()` | 按码点迭代 | 迭代器 | ES2015 |

---

## 九、最容易混淆的几组

### 1. `slice` vs `substring` vs `substr`

| 对比 | `slice` | `substring` | `substr` |
| --- | --- | --- | --- |
| 负数 | 从末尾数 | 当作 0 | `start` 从末尾数 |
| 第二参数 | 结束下标 | 结束下标 | **长度** |
| `start > end` | `""` | 自动交换 | — |
| 状态 | 推荐 | 少用 | 废弃 |

记忆：**slice 最“正常”**；substring 会“自作主张”交换；substr 的第二个参数是长度。

### 2. `replace` vs `replaceAll`

| 对比 | `replace` | `replaceAll` |
| --- | --- | --- |
| 字符串模式 | 只换第一处 | 换全部 |
| 正则模式 | 看有没有 `g` | **必须**有 `g` |
| 无 `g` 的正则 | 换第一处 | 抛 `TypeError` |
| 版本 | ES3 | ES2021 |

```js
"a-a-a".replace("a", "b");    // "b-a-a"
"a-a-a".replaceAll("a", "b"); // "b-b-b"
"a-a-a".replace(/a/g, "b");   // "b-b-b"
```

### 3. `indexOf` vs `search` vs `includes`

| 对比 | `indexOf` | `search` | `includes` |
| --- | --- | --- | --- |
| 参数 | 字符串 | 正则 / 字符串 | 字符串 |
| 返回 | 下标 / -1 | 下标 / -1 | 布尔 |
| 用途 | 找子串位置 | 用正则找位置 | 判断存在 |
| 特殊字符 | 按字面匹配 | 按正则解释 | 按字面匹配 |

### 4. `charAt` vs `[]` vs `at`

| 写法 | 越界 | 负数 | 说明 |
| --- | --- | --- | --- |
| `s[i]` | `undefined` | `undefined` | 属性访问，最快 |
| `s.charAt(i)` | `""` | `""` | 老 API，永远返回字符串 |
| `s.at(i)` | `undefined` | 从末尾数 | 需要 `-1` 时用 |

### 5. `length` vs 实际字符数

```js
"😀".length;        // 2
[..."😀"].length;   // 1
"👨‍👩‍👧".length;       // 8（码元）
[..."👨‍👩‍👧"].length;  // 5（码点，仍不是 1 个“视觉字符”）
```

| 层级 | 计数方式 | 例子结果 |
| --- | --- | --- |
| UTF-16 码元 | `str.length` | `"😀"` → 2 |
| Unicode 码点 | `[...str].length` | `"😀"` → 1 |
| 字素簇（视觉字符） | `Intl.Segmenter` | `"👨‍👩‍👧"` → 1 |

```js
const graphemes = [...new Intl.Segmenter("zh", { granularity: "grapheme" }).segment(str)];
graphemes.length;
```

### 6. `match` vs `matchAll` vs `exec`

| 对比 | `match` | `matchAll` | `exec` |
| --- | --- | --- | --- |
| 输入 | 正则 / 字符串 | 正则，**必须带 g** | 正则 |
| 返回 | 数组 / `null` | 迭代器 | 数组 / `null` |
| 分组 | 不带 g 时有 | 有 | 有 |
| 全部匹配 | 带 g 时返回字符串数组 | ✅ | 需循环 |
| 状态 | 无 | 无 | 依赖 `lastIndex` |

```js
// 需要“全部匹配 + 分组”时
const all = [...str.matchAll(/(\d+)/g)].map((m) => Number(m[1]));
```

### 7. `String()` vs `new String()`

| 写法 | `typeof` | 是否对象 | 判等 |
| --- | --- | --- | --- |
| `String("a")` | `"string"` | 否 | `=== "a"` 为 `true` |
| `new String("a")` | `"object"` | 是 | `=== "a"` 为 `false` |

```js
new String("") ? "真" : "假"; // "真" ← 空字符串包装对象是 truthy
Boolean(new String(""));      // true
typeof new String("a");       // "object"
```

**注意**：永远不要用 `new String()`。

### 8. `toUpperCase` vs `toLocaleUpperCase`

| 对比 | `toUpperCase` | `toLocaleUpperCase` |
| --- | --- | --- |
| 规则 | 默认 Unicode 规则 | 指定语言规则 |
| 土耳其语 `i` | `"I"` | `"İ"` |
| 用途 | 通用 | 本地化文本 |

### 9. `trim` vs `replace(/\s+/g, "")`

| 对比 | `trim` | `replace(/\s+/g, "")` |
| --- | --- | --- |
| 范围 | 只去首尾 | 去掉全部空白 |
| 中间空格 | 保留 | 删除 |
| 零宽空格 | 去不掉 | 也去不掉（`\s` 不含 `U+200B`） |

### 10. `split("")` vs `[...str]`

```js
"😀a".split("");   // ["\uD83D", "\uDE00", "a"] ← 拆坏代理项
[..."😀a"];        // ["😀", "a"] ← 正确
```

**注意**：任何“按字符拆分 / 反转 / 统计”都优先用 `[...str]`。

---

## 十、常见坑

1. **以为字符串能原地修改**
   ```js
   let s = "abc";
   s[0] = "x"; // 无效
   s;          // "abc"
   ```

2. **`replace` 只替换第一处**
   ```js
   "a-a-a".replace("a", "b"); // "b-a-a"
   "a-a-a".replaceAll("a", "b"); // "b-b-b"
   ```

3. **`replaceAll` 配了不带 `g` 的正则**
   ```js
   "abc".replaceAll(/b/, "x"); // TypeError
   ```

4. **`split("")` 拆坏 emoji / 生僻字**
   用 `[...str]` 或 `Array.from(str)`。

5. **`length` 当成“字数”**
   `"😀".length` 是 2；按码点数用 `[...str].length`。

6. **用 `charCodeAt` 处理 emoji**
   `"😀".charCodeAt(0)` 是高位代理项；用 `codePointAt`。

7. **`String.fromCharCode` 生成不了 emoji**
   ```js
   String.fromCharCode(128512);  // ""（高位的 1 被截掉）
   String.fromCodePoint(128512); // "😀"
   ```

8. **`indexOf` 的负数位置被当作 0**
   ```js
   "abcabc".indexOf("c", -1); // 2，不是从末尾找
   ```
   取末尾字符用 `at(-1)`。

9. **`substring` 自动交换参数**
   ```js
   "abcdef".substring(4, 1); // "bcd"，不是 ""
   ```
   需要严格语义用 `slice`。

10. **`slice` 与 `substring` 对负数处理不同**
    ```js
    "abcdef".slice(0, -1);     // "abcde"
    "abcdef".substring(0, -1); // ""
    ```

11. **`match` 找不到返回 `null`**
    ```js
    "abc".match(/x/)[0]; // TypeError
    ```

12. **带 `g` 的 `match` 拿不到分组**
    ```js
    "a1".match(/([a-z])(\d)/g); // ["a1"] ← 没有 "a"、"1"
    ```

13. **`matchAll` 忘了 `g`**
    ```js
    "a1".matchAll(/\d/); // TypeError
    ```

14. **`split` 的捕获组会进入结果**
    ```js
    "a1b2".split(/(\d)/); // ["a", "1", "b", "2", ""]
    "a1b2".split(/\d/);   // ["a", "b", ""]
    ```

15. **`endsWith` 的第二个参数是截断位置**
    ```js
    "abc".endsWith("b", 2); // true ← 在 "ab" 里找
    "abc".endsWith("c", 2); // false
    ```

16. **`includes` / `startsWith` / `endsWith` 传正则**
    ```js
    "abc".includes(/b/); // TypeError（现代引擎）
    /b/.test("abc");     // true ← 正则判断用 test
    ```
    旧环境不会抛错，而是把正则转成字符串 `"/b/"` 再比较，返回 `false`，同样不是想要的结果。

17. **`parseInt` 不传基数**
    ```js
    parseInt("010");     // 10（现代环境，但别依赖）
    parseInt("010", 10); // 10
    parseInt("10", 2);   // 2
    ```

18. **`Number("")` 是 `0`，`Number("  ")` 也是 `0`**
    判空要另外写：`s.trim() === ""`。

19. **用 `<` 比较中文字符串**
    按 Unicode 码点比，不是拼音；排序用 `localeCompare`。
    ```js
    ["张三", "李四"].sort(); // 码点序，不是拼音序
    ["张三", "李四"].sort((a, b) => a.localeCompare(b, "zh"));
    ```

20. **复用带 `g` 的正则做 `test` / `exec`**
    ```js
    const re = /\d/g;
    re.test("1"); // true，lastIndex 变成 1
    re.test("1"); // false ← 从下标 1 开始找不到
    re.lastIndex = 0; // 每次复用前重置
    ```
    只做布尔判断时去掉 `g`。

21. **`trim` 去不掉零宽空格**
    ```js
    "\u200Babc".trim(); // "\u200Babc"
    "\u200Babc".replace(/\u200B/g, ""); // "abc"
    ```

22. **`new String()` 是对象**
    ```js
    Boolean(new String("")); // true
    typeof new String("a");  // "object"
    ```

23. **模板字符串里的 `$` 和反引号需要转义**
    ```js
    `\${notInterpolated}`; // "${notInterpolated}"
    ```

24. **用户输入直接拼进正则**
    ```js
    const safe = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    new RegExp(safe(userInput));
    ```

25. **`toUpperCase` 可能改变长度**
    ```js
    "ß".toUpperCase(); // "SS"
    ```

---

## 十一、场景速查（蓝桥杯常用）

### 反转字符串（Unicode 安全）

```js
[...str].reverse().join("");
```

### 判断回文

```js
const isPalindrome = (s) => {
  const t = s.toLowerCase().replace(/[^a-z0-9]/g, "");
  return t === [...t].reverse().join("");
};
```

### 首字母大写

```js
const capitalize = (s) => s.charAt(0).toUpperCase() + s.slice(1);
```

### 驼峰转短横线

```js
"backgroundColor".replace(/[A-Z]/g, (m) => "-" + m.toLowerCase());
// "background-color"
```

### 短横线转驼峰

```js
"background-color".replace(/-([a-z])/g, (_, c) => c.toUpperCase());
// "backgroundColor"
```

### 统计字符频次

```js
const count = [...str].reduce((acc, ch) => {
  acc[ch] = (acc[ch] ?? 0) + 1;
  return acc;
}, {});
```

### 补零 / 格式化时间

```js
const pad = (n) => String(n).padStart(2, "0");
const time = `${pad(h)}:${pad(m)}:${pad(s)}`;
```

### 千分位

```js
(1234567).toLocaleString("zh-CN"); // "1,234,567"

// 或纯字符串写法
String(1234567).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
```

### 截断加省略号

```js
const truncate = (s, n) => ([...s].length > n ? [...s].slice(0, n).join("") + "…" : s);
```

### 手机号 / 身份证脱敏

```js
"13812345678".replace(/(\d{3})\d{4}(\d{4})/, "$1****$2");
// "138****5678"
```

### 去掉所有空白

```js
str.replace(/\s+/g, "");
```

### 统计单词

```js
const words = str.toLowerCase().match(/[a-z]+/g) ?? [];
words.length;
```

### 忽略大小写查找

```js
str.toLowerCase().includes(keyword.toLowerCase());
```

### 解析 URL 查询参数

```js
const params = Object.fromEntries(new URLSearchParams(location.search));
```

### 版本号比较

```js
"1.10.0".localeCompare("1.9.0", undefined, { numeric: true }) > 0; // true
```

### 提取所有数字

```js
str.match(/\d+/g)?.map(Number) ?? [];
```

### 判断中文

```js
/[\u4e00-\u9fa5]/.test(str);
```

### 生成随机字符串

```js
const randomStr = (n) =>
  Array.from({ length: n }, () => Math.random().toString(36)[2]).join("");
```

### 字符串 ↔ 数组

```js
[...str];              // 字符串 → 字符数组
arr.join("");          // 数组 → 字符串
str.split(",");        // 按分隔符拆分
```

### 大小写互换

```js
str.replace(/[a-zA-Z]/g, (c) =>
  c === c.toLowerCase() ? c.toUpperCase() : c.toLowerCase()
);
```

---

## 十二、记忆口诀

> **字符串不可变，方法全返新；**
> **slice 取一段，substring 会调换；**
> **replace 换一处，replaceAll 才换完。**

> **indexOf 找位置，includes 给真假；**
> **match 抓内容，matchAll 抓全部；**
> **split 拆成串，join 再拼回。**

> **length 数码元，码点用展开；**
> **charCodeAt 半个人，codePointAt 才完整；**
> **emoji 要反转，`[...str]` 最稳当。**

> **补零 padStart，重复用 repeat；**
> **去空白 trim，比大小 localeCompare。**

---

## 相关笔记

- [[数组 API 全解]]
