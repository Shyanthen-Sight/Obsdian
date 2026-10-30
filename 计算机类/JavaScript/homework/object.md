# Lesson 8 Exercises - Objects 逐题解析

> 这四道题是一条链：8a 建对象 → 8b 改价格 → 8c 加属性 → 8d 抽成函数。下面的代码是一个整体，`product` 对象一路沿用。

---

## 8a. 用对象表示商品并打印

- [ ] 完成 8a

**要求**：Amazon 项目里有一个篮球商品，`name` 为 `'basketball'`，`price` 为 `2095`（单位：美分）。创建对象并在控制台显示。

> [!success]- 答案与解析（点击展开）
> **思路**
> - 用**对象字面量**（object literal）`{}` 创建，键值对写成 `key: value`，多组之间用逗号分隔。
> - `console.log(product)` 直接打印对象，Node/Chrome 会显示为 `{ name: 'basketball', price: 2095 }`。
>
> ```js
> const product = {
>   name: 'basketball',
>   price: 2095
> };
>
> console.log(product);
> // { name: 'basketball', price: 2095 }
> ```
>
> **要点 / 易错点**
> - 属性之间是**逗号**不是分号；最后一个属性后面可以留逗号，但习惯上省略。
> - 字符串必须加引号，数字不加。
> - 用 `const` 声明对象是可以的：`const` 锁的是「变量指向哪个对象」，不锁对象内部属性（8b 要改价格，正好用得上这个区别）。

---

## 8b. 用点号修改价格

- [ ] 完成 8b

**要求**：把价格提高 500 美分，**必须用点号（dot notation）**，然后打印更新后的对象。

> [!success]- 答案与解析（点击展开）
> **思路**
> - 点号语法：`对象.属性名`，既能读也能写。
> - 自增写法 `product.price += 500` 等价于 `product.price = product.price + 500`。
> - 2095 + 500 = **2595**。
>
> ```js
> product.price += 500;
>
> console.log(product);
> // { name: 'basketball', price: 2595 }
> ```
>
> **要点 / 易错点**
> - 不要写成 `product.price + 500;`——那只是算了个值然后丢掉，对象没变。
> - 对象是**引用类型**：`console.log` 打印的是对象当前内容，但如果你先 `console.log(product)` 再改，某些浏览器控制台里展开看到的会是「改之后」的值（因为存的是引用）。想看到修改前后的对比，应该先 `console.log`，或打印一份副本。

---

## 8c. 用中括号添加 `delivery-time` 属性

- [ ] 完成 8c

**要求**：用**中括号（bracket notation）**添加属性 `'delivery-time'`，值为 `'3 days'`，打印更新后的对象。

> [!success]- 答案与解析（点击展开）
> **思路**
> - 中括号写法：`对象['属性名']`。属性名用引号括起来，里面可以是任意字符串。
>
> ```js
> product['delivery-time'] = '3 days';
>
> console.log(product);
> // { name: 'basketball', price: 2595, 'delivery-time': '3 days' }
> ```
>
> **为什么这题必须用中括号？**
> - 点号要求属性名是**合法的标识符**（`delivery-time` 中间的 `-` 会让 JS 把它当成减号，`product.delivery-time` 实际是「`product.delivery` 减 `time`」）。
> - 中括号里是**字符串**，什么字符都行，所以带连字符、空格、数字开头的属性名只能这样写。
>
> **要点 / 易错点**
> - 别漏引号：`product[delivery-time]` 会把 `delivery` 和 `time` 当成两个变量去减，直接报错。
> - 写入不存在的属性 = 新增属性；存在则覆盖。JS 对象没有固定结构，随时能加。
>
> | 写法 | 适用场景 |
> | --- | --- |
> | `product.name` | 属性名固定、合法标识符 |
> | `product['delivery-time']` | 带 `-`/空格、数字开头、属性名存在变量里 |

---

## 8d. 写 `comparePrice` 函数，返回更便宜的商品

- [ ] 完成 8d

**要求**：`comparePrice(product1, product2)` 接收两个带 `name`、`price` 的商品，返回**价格更低**的那个。创建 2 个商品并测试。

> [!success]- 答案与解析（点击展开）
> **思路**
> 1. 参数就是对象，直接 `product1.price` 拿价格比较。
> 2. 返回的是**整个对象**（不是名字），这样调用方还能继续访问它的其他属性。
> 3. 用 `if / else` 或三元运算符都行。
>
> ```js
> function comparePrice(product1, product2) {
>   if (product1.price < product2.price) {
>     return product1;
>   } else {
>     return product2;
>   }
> }
>
> // 简写版
> // function comparePrice(product1, product2) {
> //   return product1.price < product2.price ? product1 : product2;
> // }
>
> const productA = { name: 'basketball', price: 2595 };
> const productB = { name: 'football', price: 1595 };
>
> console.log(comparePrice(productA, productB));
> // { name: 'football', price: 1595 }
> ```
>
> **要点 / 易错点**
> - 返回对象后想拿名字要再接一层：`comparePrice(a, b).name`。
> - `return` 之后的代码不会执行，所以不用写 `else` 也可以（两个 `return` 二选一）。
> - **平局**：价格相等时上面写法会返回 `product2`。严谨一点可以显式处理：
>
> ```js
> function comparePrice(product1, product2) {
>   if (product1.price === product2.price) return '价格相同';
>   return product1.price < product2.price ? product1 : product2;
> }
> ```
>
> - 参数名不要和外面的变量重名混淆；传入的是两个**不同对象**的引用，函数内部不用复制。

---

## 完整可运行代码（8a–8d）

> [!success]- 完整代码（点击展开）
> ```js
> // 8a
> const product = {
>   name: 'basketball',
>   price: 2095
> };
> console.log(product); // { name: 'basketball', price: 2095 }
>
> // 8b
> product.price += 500;
> console.log(product); // { name: 'basketball', price: 2595 }
>
> // 8c
> product['delivery-time'] = '3 days';
> console.log(product); // { name: 'basketball', price: 2595, 'delivery-time': '3 days' }
>
> // 8d
> function comparePrice(product1, product2) {
>   return product1.price < product2.price ? product1 : product2;
> }
>
> const p1 = { name: 'basketball', price: 2595 };
> const p2 = { name: 'football', price: 1595 };
>
> console.log(comparePrice(p1, p2)); // { name: 'football', price: 1595 }
> ```

## 8e. `isSameProduct`：比较两个对象的**值**

- [ ] 完成 8e

**要求**：`isSameProduct(product1, product2)` 在两个商品的 `name` 和 `price` 都相同时返回 `true`，否则返回 `false`。提示：对象是引用，不能直接比较。

> [!success]- 答案与解析（点击展开）
> **思路**
> - 不能写 `product1 === product2`：`===` 对对象比较的是**引用（内存地址）**，两个内容一模一样的对象也不相等。
> - 正确做法：**逐个属性比较**，全部相等才算相同。
>
> ```js
> function isSameProduct(product1, product2) {
>   return product1.name === product2.name &&
>          product1.price === product2.price;
> }
>
> const productA = { name: 'basketball', price: 2095 };
> const productB = { name: 'basketball', price: 2095 };
> const productC = { name: 'football', price: 1595 };
>
> console.log(isSameProduct(productA, productB)); // true
> console.log(isSameProduct(productA, productC)); // false
> ```
>
> **要点 / 易错点**
> - 验证引用 vs 值：`productA === productB` 是 `false`，但 `productA === productA` 是 `true`——只有指向同一个对象才为真。
> - `&&` 两个条件都为真才返回 `true`；只要有一个属性不同就是 `false`。
> - 这种「手工比较」只检查题目要求的两个属性，对象多出的其他属性不影响结果。

---

## 8f. 字符串转小写

- [ ] 完成 8f

**要求**：查资料，把字符串转成全小写（`'Good Morning'` → `'good morning'`）。

> [!success]- 答案与解析（点击展开）
> **答案**：字符串方法 `toLowerCase()`。
>
> ```js
> const message = 'Good Morning';
> console.log(message.toLowerCase()); // 'good morning'
> ```
>
> **要点 / 易错点**
> - 这是**字符串方法**，不是 `console` 的方法，也不是全局函数：写成 `toLowerCase(message)` 会报错。
> - **返回新字符串，原字符串不变**（JavaScript 字符串不可变）：`message` 仍然是 `'Good Morning'`。
> - 对应的还有 `toUpperCase()` 转大写。
> - 只影响字母，数字和符号原样保留。

---

## 8g. 重复字符串

- [ ] 完成 8g

**要求**：查资料，把字符串重复多次（`'test'` 重复 2 次 → `'testtest'`）。

> [!success]- 答案与解析（点击展开）
> **答案**：字符串方法 `repeat()`。
>
> ```js
> console.log('test'.repeat(2)); // 'testtest'
> console.log('test'.repeat(0)); // ''（空字符串）
> ```
>
> **要点 / 易错点**
> - 参数是**重复次数**，`repeat(2)` 表示总共出现 2 次（不是额外加 2 次）。
> - 次数为 0 返回空字符串；次数为负数会抛 `RangeError`。
> - 等价于循环拼接 `result += 'test'`，但 `repeat` 更简洁。

---

## 8h. 计算器项目接入 localStorage

- [ ] 完成 8h

**要求**：从 7j 复制计算器项目，之后：
- 每次更新计算式时用 `.setItem()` 保存；
- 页面首次加载时用 `.getItem()` 读取；
- 读取不到时用默认值 `''`。

> [!success]- 答案与解析（点击展开）
> **思路**
> 1. **先读**：`calculation` 改为从 localStorage 取，取不到就用空串：
>
> ```js
> let calculation = localStorage.getItem('calculation') || '';
> ```
>
> 2. **后写**：每次 `updateCalculation` 改完计算式，顺手存一份：
>
> ```js
> function updateCalculation(value) {
>   calculation += value;                       // 更新计算式
>   document.querySelector('.js-calculation').innerText = calculation; // 改页面
>   localStorage.setItem('calculation', calculation); // 存起来
> }
> ```
>
> **要点 / 易错点**
> - `getItem` 找不到 key 时返回 `null`，`null || ''` 得到 `''`，这就是「默认值」的写法（`||` 会跳过所有 falsy 值）。
> - key 名随便起（这里叫 `'calculation'`），但**读写必须用同一个** key，否则读不到。
> - `setItem` 要在**每次**修改后调用，不能只在最后一次调用——否则中途刷新就丢了。
> - 刷新页面后计算式还在，这就是「持久化」的效果。

---

## Challenge Exercises

## 8i. 掷硬币游戏改成按钮版

- [ ] 完成 8i

**要求**：复制 6j 的代码，做石头剪刀布那样的交互：
- 两个按钮 `heads` / `tails`；
- 点 `heads` 时 `guess = 'heads'`，点 `tails` 时 `guess = 'tails'`；
- 抽出 `playGame(guess)` 复用逻辑。

> [!success]- 答案与解析（点击展开）
> **HTML**
>
> ```html
> <button onclick="playGame('heads');">heads</button>
> <button onclick="playGame('tails');">tails</button>
> <p class="js-result"></p>
> ```
>
> **JavaScript**
>
> ```js
> function playGame(guess) {
>   const randomNumber = Math.random();
>   const result = randomNumber < 0.5 ? 'heads' : 'tails';
>
>   const message = guess === result ? 'You win!' : 'You lose!';
>   document.querySelector('.js-result').innerText = message;
>   console.log(message);
> }
> ```
>
> **要点 / 易错点**
> - **引号嵌套**：HTML 属性用双引号，里面就写单引号 `onclick="playGame('heads');"`，反过来也可以，但不能两层都用双引号。
> - 按钮传的是**字符串** `'heads'`，所以 `guess` 是字符串；`Math.random() < 0.5` 二选一得到 `'heads'` / `'tails'`，再用 `===` 比较。
> - 函数参数化后，点两个按钮走的是同一段逻辑，不用复制两遍代码——这就是「复用」。
> - `message` 变量先算再显示，方便同时 `console.log` 和写到页面上。

---

## 8j. score 对象记录胜负

- [ ] 完成 8j

**要求**：创建 `{ wins: 0, losses: 0 }`，每次游戏后更新，并在控制台显示。

> [!success]- 答案与解析（点击展开）
> **思路**
> - 对象**只创建一次**，放在函数外面；每局只修改属性值。
> - 赢了 `score.wins += 1`，输了 `score.losses += 1`。
>
> ```js
> const score = { wins: 0, losses: 0 };
>
> function playGame(guess) {
>   const randomNumber = Math.random();
>   const result = randomNumber < 0.5 ? 'heads' : 'tails';
>
>   if (guess === result) {
>     score.wins += 1;
>   } else {
>     score.losses += 1;
>   }
>
>   console.log(score); // { wins: 1, losses: 0 }
> }
> ```
>
> **要点 / 易错点**
> - 如果把 `const score = {...}` 写在 `playGame` **里面**，每次点击都会重置成 0——这是最常见的错误。
> - `const` 只禁止「重新赋值整个对象」，`score.wins = 1` 这种**改属性**完全允许。
> - `score.wins += 1` 就是 `score.wins = score.wins + 1`。

---

## 8k. 用 localStorage 保存分数

- [ ] 完成 8k

**要求**：存取 score 对象，提示：用 `JSON.stringify()` 把对象转成字符串。

> [!success]- 答案与解析（点击展开）
> **思路**
> - localStorage **只能存字符串**。直接存对象会被转成 `"[object Object]"`，读回来完全没用。
> - 存：`JSON.stringify(score)` 把对象 → JSON 字符串。
> - 读：`JSON.parse(...)` 把字符串 → 对象。
>
> ```js
> // 页面加载时：读 + 转回对象，读不到就用默认值
> const score = JSON.parse(localStorage.getItem('score')) ||
>               { wins: 0, losses: 0 };
>
> function playGame(guess) {
>   // ...判断输赢，更新 score.wins / score.losses
>
>   console.log(score);
>   localStorage.setItem('score', JSON.stringify(score)); // 存
> }
> ```
>
> **要点 / 易错点**
> - `JSON.stringify({ wins: 2, losses: 1 })` → `'{"wins":2,"losses":1}'`（字符串）。
> - 第一次运行时 `getItem` 返回 `null`，`JSON.parse(null)` 返回 `null`，所以 `|| { wins: 0, losses: 0 }` 能兜底。
> - 读取时**必须** `JSON.parse`，否则拿到的是字符串，`score.wins` 会是 `undefined`。
> - 重置分数：`score.wins = 0; score.losses = 0; localStorage.removeItem('score');`
> - 注意区分 key：`'calculation'`（计算器）和 `'score'`（游戏）互不影响。

---

## 完整示例（8i–8k 合并版）

> [!success]- 完整代码（点击展开）
> ```html
> <!DOCTYPE html>
> <html>
> <body>
>   <button onclick="playGame('heads');">heads</button>
>   <button onclick="playGame('tails');">tails</button>
>   <p class="js-result"></p>
>   <p class="js-score"></p>
>
>   <script>
>     // 8k：读取并解析分数，默认值为 0:0
>     const score = JSON.parse(localStorage.getItem('score')) ||
>                   { wins: 0, losses: 0 };
>
>     displayScore();
>
>     // 8i：参数化后的游戏逻辑
>     function playGame(guess) {
>       const randomNumber = Math.random();
>       const result = randomNumber < 0.5 ? 'heads' : 'tails';
>
>       // 8j：更新分数对象
>       if (guess === result) {
>         score.wins += 1;
>         document.querySelector('.js-result').innerText = 'You win!';
>       } else {
>         score.losses += 1;
>         document.querySelector('.js-result').innerText = 'You lose!';
>       }
>
>       displayScore();
>       console.log(score);
>
>       // 8k：保存分数
>       localStorage.setItem('score', JSON.stringify(score));
>     }
>
>     function displayScore() {
>       document.querySelector('.js-score').innerText =
>         'Wins: ' + score.wins + ', Losses: ' + score.losses;
>     }
>   </script>
> </body>
> </html>
> ```

---

## 一页速记

- 建对象：`const obj = { key1: 值1, key2: 值2 };`
- 读/写：`obj.key`（合法标识符）；`obj['key']`（任意字符串）
- 增属性：直接赋值即可，不存在的 key 会被创建
- 对象是引用：变量存的是「地址」，传参传的也是地址
- 函数返回对象，比返回字符串更好用
- 比较对象内容要**逐个属性**比；`===` 比的是引用
- 字符串：`toLowerCase()` / `toUpperCase()` / `repeat(n)`
- localStorage 只能存字符串：对象用 `JSON.stringify` 存、`JSON.parse` 读
- 页面加载读 + `|| 默认值`；每次修改后立即 `setItem`
- 状态对象（score）定义在函数**外面**，只改属性不重建
