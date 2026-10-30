# Lesson 9 Exercises - Document Object Model (DOM) 逐题解析

> 这组题是一条链：9a → 9b 先学会「选中元素、改元素」；9c 学会「点击 + 传参」；9d → 9e → 9f 从一个提交按钮，扩展成「按钮 + 回车都能提交」，再把重复代码抽成函数；9g 是浮点数精度陷阱；9h 学 `onkeyup` 做实时更新；9i / 9j 把第 7、8 课的项目从「打印到 console」改成「显示到页面上」。
>
> **通用前提**：`document.querySelector()` 所在的 `<script>` 必须写在 HTML 元素**后面**（或给 script 加 `defer`）。否则脚本执行时元素还不存在，拿到的是 `null`，下一行改属性就会报 `Cannot read properties of null`。

---

## 9a. 用 `querySelector` 选中按钮并打印

- [ ] 完成 9a

**要求**：创建 `<button>9a</button>`，用 `document.querySelector('button')` 把按钮从页面取出来，然后在控制台显示。

> [!success]- 答案与解析（点击展开）
> **思路**
> - `document.querySelector(选择器)` 用 **CSS 选择器语法** 在页面里找元素，返回**第一个**匹配的元素。
> - 只传标签名 `'button'` 就是「找页面里第一个 button」。
>
> ```html
> <button>9a</button>
>
> <script>
>   const button = document.querySelector('button');
>   console.log(button);
> </script>
> ```
>
> 控制台会打印出整个元素：`<button>9a</button>`，点开三角形能看到它所有的属性（`innerText`、`classList`、`onclick` 等）。
>
> **要点 / 易错点**
> - 选择器写法：`'button'`（标签）、`'.js-btn'`（class）、`'#submit'`（id），和 CSS 里一模一样。
> - **找不到元素时返回 `null`**，不会报错。所以「后面改属性时报 null 错误」基本都意味着选择器写错或 script 位置太靠前。
> - `console.log(button)` 打印的是**元素对象**；想要 HTML 字符串则用 `console.log(button.outerHTML)`。
> - 页面里有多个 button 时，`querySelector` 只给你**第一个**——这正是 9b 要解决的问题。

---

## 9b. 加 class，改第二个按钮的文字

- [ ] 完成 9b

**要求**：在 9a 下面再加一个 `<button>9b</button>`。用 JavaScript 把第二个按钮的文字改成 `'9b done!'`（提示：给按钮加 class，再用 `.querySelector`）。

> [!success]- 答案与解析（点击展开）
> **思路**
> 1. 给第二个按钮加一个 class（比如 `js-button-2`），这样就能「精准点名」，不会被第一个按钮抢走。
> 2. `querySelector('.js-button-2')` 取到它，再用 `.innerText = ...` 改写文字。
>
> ```html
> <button>9a</button>
> <button class="js-button-2">9b</button>
>
> <script>
>   const secondButton = document.querySelector('.js-button-2');
>   secondButton.innerText = '9b done!';
> </script>
> ```
>
> **为什么不能直接 `querySelector('button')`？**
> - 它永远只返回**第一个**匹配项，也就是 9a 那个按钮，改错对象。
> - 另一种可行写法：`document.querySelectorAll('button')[1]`（取第二个），但依赖「按钮顺序不变」，很脆；加 class 才是稳的。
>
> **要点 / 易错点**
> - 给 JS 专用的 class 通常带 `js-` 前缀（项目里的约定），表示「这个 class 不是给 CSS 用的，是为了让 JS 选中它」。
> - `innerText = ...` 是**整体替换**，不是追加。想追加要写 `+=`。
> - `innerText` 和 `textContent` 的区别：`textContent` 会保留隐藏文字和格式，`innerText` 更接近「人眼看到的文字」。日常改文字用 `innerText` 就够。

---

## 9c. heads / tails 两个按钮，把选择显示在段落里

- [ ] 完成 9c

**要求**：创建 `heads`、`tails` 两个按钮，下面放一个 `<p></p>`。点 heads 时段落显示 `'You chose: heads'`，点 tails 时显示 `'You chose: tails'`。

> [!success]- 答案与解析（点击展开）
> **思路**
> - 两个按钮做的是**同一件事**，只是文字不同 → 写一个**带参数的函数**，按钮把 `'heads'` / `'tails'` 传进去。
> - HTML 属性里传字符串要加引号；外层双引号、内层单引号。
>
> ```html
> <button onclick="choose('heads');">heads</button>
> <button onclick="choose('tails');">tails</button>
> <p class="js-result"></p>
>
> <script>
>   function choose(side) {
>     document.querySelector('.js-result').innerText = 'You chose: ' + side;
>   }
> </script>
> ```
>
> **要点 / 易错点**
> - **引号嵌套**：`onclick="choose('heads');"`。两层都用双引号会直接截断属性，是这题的高频错误。
> - 段落加 class（`.js-result`）比 `querySelector('p')` 稳：页面里再多一个 `<p>` 也不会选错。
> - 也可以不传参，读按钮自己的文字：
>
> ```js
> // 写法二：addEventListener + event.target
> document.querySelectorAll('button').forEach((button) => {
>   button.addEventListener('click', (event) => {
>     document.querySelector('.js-result').innerText =
>       'You chose: ' + event.target.innerText;
>   });
> });
> ```
>
> - 文字要和题目**一字不差**：`'You chose: heads'`（大小写、冒号后的空格都算）。

---

## 9d. 文本框 + 提交按钮，显示名字

- [ ] 完成 9d

**要求**：创建 `<input>` 和提交按钮。点 Submit 时在页面上显示 `'Your name is: ${text}'`，`${text}` 是输入框里的内容（提示：用 `.value`）。

> [!success]- 答案与解析（点击展开）
> **思路**
> - 输入框里的文字**不是** `innerText`，要用 `.value` 读。
> - 字符串拼接用**模板字符串**（反引号 + `${}`），就是题目里 `${text}` 的由来。
>
> ```html
> <input class="js-name-input" type="text">
> <button onclick="submitName();">Submit</button>
> <p class="js-output"></p>
>
> <script>
>   function submitName() {
>     const text = document.querySelector('.js-name-input').value;
>     document.querySelector('.js-output').innerText = `Your name is: ${text}`;
>   }
> </script>
> ```
>
> **要点 / 易错点**
> - `.value` 读到的**永远是字符串**，即使输入的是 `123`。
> - 模板字符串用**反引号** `` ` ``，不是单引号；`${text}` 里面不要多打空格。
> - 输入框什么都不填时，显示的是 `'Your name is: '`——想更友好可以加个判断。
> - 如果按钮包在 `<form>` 里，点它会**提交表单并刷新页面**，一闪就没了。解决办法：`<button type="button">`，或在处理函数里 `event.preventDefault()`。

---

## 9e. 按 Enter 也能提交

- [ ] 完成 9e

**要求**：改造 9d，在 `<input>` 里按 `Enter` 时也显示同样的信息（提示：用 `onkeydown` 和 event 对象）。

> [!success]- 答案与解析（点击展开）
> **思路**
> - 键盘事件的处理函数可以接收一个 **event 对象**，里面记录了「按了哪个键」等信息。
> - 判断 `event.key === 'Enter'`，为真就调用和按钮一样的逻辑。
>
> ```html
> <input class="js-name-input" type="text" onkeydown="handleKey(event);">
> ```
>
> ```js
> function handleKey(event) {
>   if (event.key === 'Enter') {
>     submitName();   // 复用 9d 的显示逻辑
>   }
> }
> ```
>
> **要点 / 易错点**
> - HTML 里必须显式写 `event`：`onkeydown="handleKey(event);"`。不传的话函数里的 `event` 是 `undefined`。
> - `event.key` 是**字符串**，回车是 `'Enter'`（大写 E），不是 `'enter'`。
> - 旧写法 `event.keyCode === 13` 还能用，但已被废弃，新代码用 `event.key`。
> - 不要写成 `onkeydown="submitName();"`——那样**任何**按键（包括打字）都会触发，输入框还没输完就刷屏。
> - `keydown` 在字符**写入输入框之前**触发。对 Enter 没影响（文字早就输完了），但如果你想在 keydown 里读「刚敲的那个字符」，会读到旧值——这种情况要用 `keyup`（9h 用的就是 keyup）。

---

## 9f. 抽成函数复用

- [ ] 完成 9f

**要求**：把 9e 里重复的代码抽成一个函数复用（如果 9e 已经这么写了，可跳过）。

> [!success]- 答案与解析（点击展开）
> **思路**
> 「按钮点击」和「按回车」最终都要执行同一段「读 value → 写段落」，所以把这段单独做成 `displayName()`，两边都调它。
>
> ```html
> <input class="js-name-input" type="text" onkeydown="handleKey(event);">
> <button onclick="displayName();">Submit</button>
> <p class="js-output"></p>
>
> <script>
>   function displayName() {
>     const text = document.querySelector('.js-name-input').value;
>     document.querySelector('.js-output').innerText = `Your name is: ${text}`;
>   }
>
>   function handleKey(event) {
>     if (event.key === 'Enter') {
>       displayName();
>     }
>   }
> </script>
> ```
>
> **要点 / 易错点**
> - 这就是 **DRY**（Don't Repeat Yourself）：改需求时只改一处，两个入口不会不同步。
> - 函数名用动词开头（`displayName` / `submitName`），一看就知道干什么。
> - 函数声明会被**提升**，`displayName` 写在 `handleKey` 后面、甚至在调用它的代码后面也能用（但为了可读性，按「先定义后使用」排列）。
> - 分层：`displayName` 只负责「显示」，`handleKey` 只负责「判断按键」，职责分开。

---

## 9g.（Challenge）运费计算器的浮点精度问题

- [ ] 完成 9g

**要求**：新建 `9g.html`，把 `09-dom-projects.html` 的代码复制进去。在 Amazon 运费计算器里输入 `7.99` 点 Calculate，看到了什么问题？找出修复方法。

> [!success]- 答案与解析（点击展开）
> **看到的问题**
> 结果不是 `$17.99`，而是 `$17.990000000000002`——**浮点数精度误差**（floating point error）。
>
> **原因**
> - JavaScript 的所有数字都是 IEEE 754 **双精度浮点数**，用二进制表示，而 `7.99` 这种十进制小数在二进制里是**无限循环**的，只能存一个近似值（约 `7.990000000000000213…`）。
> - 再加上运费（截图里的结果约等于 `7.99 + 10`），误差被「放大」显形了：`7.9900000000000002 + 10 = 17.990000000000002`。
> - 这不是 JS 的 bug，是二进制浮点的通病：`0.1 + 0.2 === 0.30000000000000004`。
>
> **修复：只在对用户显示时四舍五入**
>
> ```js
> function calculateTotal() {
>   const cost = Number(document.querySelector('.js-cost-input').value);
>   const total = cost + 10;   // 这里的 10 是运费，具体数值以你项目代码为准
>
>   document.querySelector('.js-total').innerText =
>     `$${total.toFixed(2)}`;   // 17.990000000000002 → "17.99"
> }
> ```
>
> **要点 / 易错点**
> - `.toFixed(2)` **返回字符串**，保留两位小数，正好适合显示金额；不要拿它的结果继续做算术（要转回数字用 `Number(...)` 或 `parseFloat(...)`）。
> - 返回数字的写法：`Math.round(total * 100) / 100`。
> - 更彻底的做法：**全程用「分」做整数运算**，最后只在显示时除 100，可彻底避开误差（金额系统的常见做法）。
> - `toFixed` 自己也有小坑：`(1.005).toFixed(2)` 得到 `"1.00"` 而不是 `"1.01"`（同样是二进制近似导致的）。日常练习够用，金额系统要更严谨。
> - **`input.value` 是字符串！** 必须先 `Number(...)`，否则 `'7.99' + 10` 会拼成 `'7.9910'`（另一个常见错误）。
> - 只在「显示」这一步取整；如果后面还要参与计算，保留原始数值。

---

## 9h.（Challenge）输入框实时更新页面文字

- [ ] 完成 9h

**要求**：做一个项目：文本框里每打一个字，页面上的文字就同步更新。用 `<input onkeyup="...">`——按键**松开**后触发。

> [!success]- 答案与解析（点击展开）
> **思路**
> - 用 `onkeyup` 监听输入框，事件触发时 `.value` 已经是**最新内容**（这正是它和 `keydown` 的关键区别）。
> - 读到 value，写进段落。
>
> ```html
> <input class="js-input" type="text" onkeyup="updateText();">
> <p class="js-text"></p>
>
> <script>
>   function updateText() {
>     const text = document.querySelector('.js-input').value;
>     document.querySelector('.js-text').innerText = text;
>   }
> </script>
> ```
>
> **要点 / 易错点**
> - **`keyup` 在按键松开后触发，此时 value 已更新**；`keydown` 在字符写入前触发，会慢一个字。所以「实时同步输入内容」要用 `keyup`（或下面说的 `input` 事件）。
> - 更语义化的写法是监听 `input` 事件，它同时覆盖键盘、粘贴、拖拽、语音输入：
>
> ```js
> document.querySelector('.js-input').addEventListener('input', () => {
>   document.querySelector('.js-text').innerText =
>     document.querySelector('.js-input').value;
> });
> ```
>
> - 用中文输入法（IME）打字时，`keyup` 只在候选词上屏后才拿到完整内容，中间过程可能不触发；`input` 事件表现更自然。做真实项目优先用 `input`。
> - 删除文字也会触发 `keyup`，所以段落会跟着变短，符合预期。
> - 初始状态段落是空的，不用额外初始化。

---

## 9i. 改造购物车数量项目（显示到页面）

- [ ] 完成 9i

**要求**：复制 7l 的 Cart Quantity 项目，做三件事：
- 加一个 `<p></p>` 显示数量；
- 每次数量变化时更新**页面**（不再是 console）；
- 页面**首次加载**时也显示一次数量。

> [!success]- 答案与解析（点击展开）
> **思路**
> 1. 状态（`cartQuantity`）放在函数**外面**，全项目共用。
> 2. 写一个 `updateDisplay()` 专门负责「把数字写到段落」，所有改数量的地方最后都调它。
> 3. 在 script 末尾**调用一次** `updateDisplay()`，解决「首次加载显示」。
>
> **HTML**
>
> ```html
> <button onclick="showQuantity();">Show Quantity</button>
> <button onclick="addToCart();">Add to Cart</button>
> <button onclick="updateQuantity(2);">+2</button>
> <button onclick="updateQuantity(3);">+3</button>
> <button onclick="updateQuantity(4);">+4</button>
> <button onclick="updateQuantity(5);">+5</button>
> <button onclick="removeFromCart();">Remove from cart</button>
> <button onclick="updateQuantity(-2);">-2</button>
> <button onclick="updateQuantity(-3);">-3</button>
>
> <p class="js-quantity"></p>
> ```
>
> **JavaScript**
>
> ```js
> let cartQuantity = 0;
>
> function updateDisplay() {
>   document.querySelector('.js-quantity').innerText =
>     `Cart quantity: ${cartQuantity}`;
> }
>
> function showQuantity() {
>   updateDisplay();
> }
>
> function addToCart() {
>   cartQuantity += 1;
>   updateDisplay();
> }
>
> function removeFromCart() {
>   cartQuantity -= 1;
>   updateDisplay();
> }
>
> function updateQuantity(change) {
>   cartQuantity += change;
>   updateDisplay();
> }
>
> // 页面首次加载时显示
> updateDisplay();
> ```
>
> **要点 / 易错点**
> - **`+2` 这类按钮用参数化函数** `updateQuantity(2)`，比写 5 个几乎一样的函数干净（和 9c 传参是同一个思路）。
> - 先复制 7l 的代码再改，不要从零重写——原项目里如果有「不能小于 0 / 不能超过 10」之类的限制，要**保留**：
>
> ```js
> function updateQuantity(change) {
>   cartQuantity += change;
>   if (cartQuantity < 0) cartQuantity = 0;   // 7l 若有上下限就照搬
>   if (cartQuantity > 10) cartQuantity = 10;
>   updateDisplay();
> }
> ```
>
> - 「首次加载显示」= 在 script 末尾**无条件**调一次 `updateDisplay()`。放在函数定义外面，脚本跑一次就执行一次。
> - 不要再直接 `console.log(cartQuantity)` 就完事——题目要求显示在页面上；`showQuantity` 里保留 console 也无妨。
> - `innerText` 每改一次就重绘一次，但这点量完全无所谓，不用做性能优化。

---

## 9j. 改造计算器项目（显示到页面 + 首次加载读 localStorage）

- [ ] 完成 9j

**要求**：复制 8h 的计算器项目：
- 每次更新计算式时，显示在**页面**上（不是 console）；
- 页面首次加载时，如果 localStorage 里有计算式，就显示出来。

> [!success]- 答案与解析（点击展开）
> **思路**
> 8h 的代码本来就有「读 localStorage + 每次修改保存」。这题只需要把「打印」换成「写段落」，并把初始化也交给同一个显示函数。
>
> ```html
> <p class="js-calculation"></p>
>
> <button onclick="updateCalculation('1');">1</button>
> <button onclick="updateCalculation('2');">2</button>
> <button onclick="updateCalculation('3');">3</button>
> <button onclick="updateCalculation('+');">+</button>
>
> <script>
>   let calculation = localStorage.getItem('calculation') || '';
>
>   function displayCalculation() {
>     document.querySelector('.js-calculation').innerText = calculation;
>   }
>
>   function updateCalculation(value) {
>     calculation += value;
>     displayCalculation();                                // 改页面
>     localStorage.setItem('calculation', calculation);    // 存 localStorage
>   }
>
>   displayCalculation();   // 页面首次加载就显示已保存的计算式
> </script>
> ```
>
> **要点 / 易错点**
> - 执行顺序必须是：**读 localStorage → 显示 → 用户点击 → 更新 + 保存**。script 放在 HTML 后面，`displayCalculation()` 才能找到 `<p>`。
> - `getItem` 找不到 key 返回 `null`，`null || ''` 得到空字符串，这就是默认值。
> - 写入格式要和 8h 完全一致（key 用 `'calculation'`），否则 8h 存的读不出来。
> - 刷新页面后计算式还在 → 说明「读 + 首屏显示」两件事都做对了。
> - 页面刚打开、localStorage 里没东西时，段落是空的；想显示 `0` 可以写 `localStorage.getItem('calculation') || '0'`。
> - `displayCalculation` 被「首个加载」和「每次更新」两处调用，这就是 9f 讲的复用思想。

---

## 一页速记

- 选元素：`document.querySelector('.js-xxx')`，用 CSS 选择器语法，只返回第一个，找不到是 `null`
- `<script>` 放在元素后面（或 `defer`），否则 `querySelector` 拿到 null
- 改文字：`.innerText = '...'`；读输入框：`.value`（永远是字符串，算数先 `Number(...)`）
- 点击传参：`onclick="fn('heads');"`，外双内单，别两层双引号
- 键盘：`onkeydown="handleKey(event);"`，判断 `event.key === 'Enter'`
- `keydown` 在字符写入前触发；`keyup` 在之后 → 读最新输入用 `keyup`，实际项目用 `input` 事件
- 金额显示：`total.toFixed(2)`；浮点误差来自二进制表示，取整只发生在显示环节
- 状态变量放函数外，改完统一调 `updateDisplay()`；script 末尾调一次 = 首屏显示
- localStorage：`getItem(...) || 默认值` 读，每次修改后 `setItem` 写
- 重复逻辑抽成函数，点击 / 回车 / 首屏加载都复用它（DRY）

---

## 考点对照表

| 题号 | 核心考点 |
| --- | --- |
| 9a | `querySelector` 按标签选中元素、`console.log` 元素 |
| 9b | 加 class 精准选中、`innerText` 改写文字 |
| 9c | `onclick` 传参、引号嵌套、写段落 |
| 9d | `input.value`、模板字符串 `${}` |
| 9e | `onkeydown`、event 对象、`event.key` |
| 9f | 抽函数复用（DRY） |
| 9g | 浮点数精度、`toFixed(2)`、`Number()` 转换 |
| 9h | `onkeyup` 实时更新、与 `keydown` 的时机差异 |
| 9i | 项目改造：状态 → 页面、参数化函数、首屏初始化 |
| 9j | localStorage 读 → 显示 → 更新保存、首屏显示 |
