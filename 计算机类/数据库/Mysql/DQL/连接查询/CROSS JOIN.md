# CROSS JOIN —— 交叉连接

> [!abstract] 一句话
> `CROSS JOIN` 就是==**笛卡尔积**==：两表每一行两两组合，结果行数 = **左表行数 × 右表行数**（3 × 5 = 15）。
> 它**不带任何连接条件**，是内连接"去掉 `ON`"后的样子；正经用途是==**造骨架**==（日期序列、序号表），不是查数据。

> [!info] 与 DML 版的分工
> [[Join|DML/Join]] 把 `CROSS JOIN` 放在六种连接里横向对比。本篇是**纵向深入**：==**笛卡尔积的数学本质、为什么会"静默爆炸"、`CROSS JOIN + WHERE = INNER JOIN`、以及生成骨架的实战套路**==。

---

> [!example] 本篇示例数据
> 与同目录 `INNER JOIN` / `LEFT JOIN` / `RIGHT JOIN` / `FULL OUTER JOIN` 各篇**共用同一套 `dept` / `emp` 表**。
> 交叉连接不看"匹配"，只看"组合"——所以 `dept_id` 有没有 NULL、财务部有没有人都无所谓，3 × 5 = 15 是必然的。

```sql
CREATE TABLE dept (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(20)
);

CREATE TABLE emp (
    emp_id   INT PRIMARY KEY,
    emp_name VARCHAR(20),
    dept_id  INT,
    salary   DECIMAL(10,2)
);

INSERT INTO dept VALUES (1001, '研发部'), (1002, '销售部'), (1003, '财务部');

INSERT INTO emp VALUES (1, '张三', 1001, 12000),
                       (2, '李四', 1001, 15000),
                       (3, '王五', 1002,  9000),
                       (4, '赵六', 1002,  8500),
                       (5, '孙七', NULL,  7000);
```

---

## 一、语法：两种等价写法

```sql
-- 写法 1：CROSS JOIN 关键字
SELECT d.dept_name, e.emp_name
FROM dept d
CROSS JOIN emp e;

-- 写法 2：逗号连接（不写任何条件）——完全等价
SELECT d.dept_name, e.emp_name
FROM dept d, emp e;
```

结果**3 × 5 = 15 行**，每个部门 × 每个员工的全部组合，前 7 行长这样：

```
dept_name | emp_name
----------+---------
研发部    | 张三
研发部    | 李四
研发部    | 王五
研发部    | 赵六
研发部    | 孙七
销售部    | 张三
销售部    | 李四
...（共 15 行：1001 / 1002 / 1003 各 5 行）
```

---

## 二、数学本质：笛卡尔积

两个集合的笛卡尔积定义为：

```
A × B = { (a, b) | a ∈ A, b ∈ B }
```

|A| = 3（三个部门）、|B| = 5（五名员工），则：

```
|A × B| = |A| × |B| = 3 × 5 = 15
```

> [!important] 行数是"相乘"不是"相加"
> 每一行左表 × 每一行右表都产生一行。三张 1000 行的表交叉，就是 **1000³ = 10 亿行**。
> 这就是为什么"漏写连接条件"是**灾难**——不报错，却可能把数据库打挂。详见 [[计算机类/数据库/Mysql/数据库概念/笛卡尔积]]。

---

## 三、为什么危险：漏条件的"静默爆炸"

```sql
-- 忘写 WHERE = 15 行（本意大概是想查 emp 和 dept 的关联）
SELECT * FROM emp e, dept d;
```

再看规模化后的后果：

| 表 A 行数 | 表 B 行数 | 笛卡尔积行数 |
| --- | --- | --- |
| 3 | 5 | 15 |
| 1,000 | 1,000 | 1,000,000（100 万） |
| 100,000 | 10,000 | **1,000,000,000（10 亿）** |

> [!danger] 逗号连接漏 `WHERE` 是线上事故常客
> 它**语法完全合法**、**不报任何错**，却让结果行数暴涨几个数量级。
> 经典场景：`SELECT ... FROM orders, order_items WHERE orders.id = ...`，某次改动把 `WHERE` 的连接条件删了——数据库瞬间被 10 亿行的中间结果拖垮。
> 所以团队规范基本都是：==**禁止逗号连接，一律显式 `JOIN ... ON`**==。

> [!warning] `CROSS JOIN` 有两个"合法但危险"的面孔
> 1. **忘了写 `ON` 的 `JOIN`** → MySQL 在语法上可能当作交叉连接处理；
> 2. **忘了写 `WHERE` 的逗号连接** → 直接就是笛卡尔积。
> 两者都不报错，结果都错得离谱。

---

## 四、`CROSS JOIN` 与 `INNER JOIN` 的关系

一句话：==**`INNER JOIN` = `CROSS JOIN` + `WHERE`/`ON`**==。

```sql
-- 二者结果完全相同（都是 4 行）
SELECT e.emp_name, d.dept_name
FROM emp e CROSS JOIN dept d
WHERE e.dept_id = d.dept_id;

SELECT e.emp_name, d.dept_name
FROM emp e JOIN dept d ON e.dept_id = d.dept_id;
```

15 行的笛卡尔积，加上 `e.dept_id = d.dept_id` 过滤后，正好剩 4 行。

> [!note] MySQL 里 `CROSS JOIN ... ON` 也合法
> MySQL 把 `JOIN`、`INNER JOIN`、`CROSS JOIN` 视为**语法等价**，所以 `CROSS JOIN dept ON ...` 语法上也通过。
> 但**语义混乱**：交叉连接本义是"无条件的笛卡尔积"。**只要你打算写连接条件，就直接用 `INNER JOIN`**，别用 `CROSS JOIN`。

---

## 五、正经用途 1：生成序号 / 数字序列

先造一张 0~9 的 `digits` 小表，交叉两次就能得到 **0~99**：

```sql
CREATE TABLE digits (d INT);
INSERT INTO digits VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

-- 0 ~ 99
SELECT a.d * 10 + b.d AS n
FROM digits a
CROSS JOIN digits b
ORDER BY n;
-- 结果：100 行（0 到 99）
```

要 0~999，再交叉一次 `digits c` 即可（1000 行）：

```sql
SELECT a.d*100 + b.d*10 + c.d AS n
FROM digits a CROSS JOIN digits b CROSS JOIN digits c
ORDER BY n;   -- 1000 行
```

> [!tip] 为什么用"交叉"而不是循环
> SQL 无法直接写循环，但**笛卡尔积天然就是"嵌套循环"**——`digits` 三次交叉，等于三层循环，正好枚举 000~999。
> 这是纯 SQL **造序列**的标准手法。

---

## 六、正经用途 2：日期骨架 + `LEFT JOIN` 补 0

报表最常见的需求："每个部门 × 每一天的销售额，**没数据的补 0**"。做法是先用 `CROSS JOIN` 造出**完整骨架**，再 `LEFT JOIN` 填真实数据。

```sql
-- 真实销售数据（稀疏：只有三笔）
CREATE TABLE sales (
    dept_id INT,
    day     DATE,
    amt     DECIMAL(10,2)
);
INSERT INTO sales VALUES (1001, '2026-10-14', 100),
                         (1001, '2026-10-16', 300),
                         (1002, '2026-10-15', 200);

-- 日期骨架
CREATE TABLE days (day DATE);
INSERT INTO days VALUES ('2026-10-14'), ('2026-10-15'), ('2026-10-16');

-- 每个部门 × 每一天，用 LEFT JOIN 填数据，缺的补 0
SELECT d.dept_name, dy.day, IFNULL(s.amt, 0) AS amt
FROM dept d
CROSS JOIN days dy
LEFT JOIN sales s
       ON s.dept_id = d.dept_id AND s.day = dy.day
ORDER BY d.dept_id, dy.day;
```

骨架 3 个部门 × 3 天 = **9 行**，结果：

```
dept_name | day        | amt
----------+------------+-----
研发部    | 2026-10-14 | 100
研发部    | 2026-10-15 |   0    <-- 骨架里补出来的
研发部    | 2026-10-16 | 300
销售部    | 2026-10-14 |   0    <-- 骨架里补出来的
销售部    | 2026-10-15 | 200
销售部    | 2026-10-16 |   0    <-- 骨架里补出来的
财务部    | 2026-10-14 |   0
财务部    | 2026-10-15 |   0
财务部    | 2026-10-16 |   0    <-- 财务部没数据，仍完整列出
```

> [!important] 套路口诀：**`CROSS JOIN` 造骨架 → `LEFT JOIN` 填数据 → `IFNULL` 补 0**
> 没有骨架，`GROUP BY` 出来的日期/部门会**缺行**（没数据的日期整行不存在）；有了骨架，再稀疏的数据也能铺成"整齐的网格"。
> 这是报表、看板、Excel 透视的通用 SQL 套路。

---

## 七、正经用途 3：造测试数据

小表交叉几次就能快速产出大量行：

```sql
-- 用 digits 三次交叉造 1000 行测试数据
INSERT INTO t (id, name)
SELECT a.d*100 + b.d*10 + c.d + 1 AS id,
       CONCAT('user_', a.d*100 + b.d*10 + c.d + 1) AS name
FROM digits a CROSS JOIN digits b CROSS JOIN digits c;
```

---

## 八、性能与警告

> [!warning] `CROSS JOIN` 的行数是指数级
> 2 张表是 n²，3 张就是 n³。即使每张表很小，组合数也可能大到超出预期。**执行前先心算行数。**

| 注意点 | 说明 |
| --- | --- |
| 条件不可省 | 一旦加了条件就不是交叉连接了，改用 `INNER JOIN` |
| 紧跟 `LEFT JOIN` | 骨架造好后通常马上 `LEFT JOIN` 真实数据 |
| 看 `EXPLAIN` | `rows` 会显示估算的组合数，暴涨要警惕 |
| 团队规范 | 禁用"逗号连接"，`CROSS JOIN` 只在**有意造骨架**时显式使用 |

```sql
EXPLAIN SELECT * FROM dept d CROSS JOIN emp e;   -- rows ≈ 3 × 5 = 15
```

---

## 九、常见错误合集

> [!failure] 忘写 `WHERE`，逗号连接变成笛卡尔积
> `FROM emp e, dept d;` 得 15 行。改 `FROM emp e JOIN dept d ON e.dept_id = d.dept_id;`。

> [!failure] 以为 `CROSS JOIN` 比逗号连接更快
> 两者**完全等价**（MySQL 里就是同一个东西），性能没差别。要不要用 `CROSS JOIN` 取决于"是否故意要笛卡尔积"。

> [!failure] 在 `CROSS JOIN` 后写 `ON` 当内连接用
> `CROSS JOIN` 的语义就是"无条件组合"，硬塞 `ON` 语句虽合法却让人看不懂。**有连接条件就写 `INNER JOIN`。**

> [!failure] 拿笛卡尔积结果去"对数"却不知道行数应为 n×m
> 交叉连接的结果行数必须是两表行数之积；对不上说明有一侧被别的因素影响，值得排查。

---

## 十、速查表

| 需求 | 写法 |
| --- | --- |
| 两表两两组合（笛卡尔积） | `CROSS JOIN` 或逗号连接 |
| 结果行数 | = 左表行数 × 右表行数 |
| 内连接 | `CROSS JOIN` + `WHERE`，或直接 `INNER JOIN ... ON` |
| 造序号序列 | `digits` 表交叉若干次 |
| 日期/维度骨架 | `CROSS JOIN` 造网格 + `LEFT JOIN` 填数 + `IFNULL` 补 0 |
| 造测试数据 | `digits` 多次交叉后 `INSERT ... SELECT` |

> [!question] 自测三连
> 1. `dept CROSS JOIN emp` 得到几行？为什么？
> 2. `CROSS JOIN` 加上一个 `WHERE` 条件后，等价于什么？
> 3. "每个部门每天都要有记录、没数据的补 0"，为什么需要 `CROSS JOIN`？

---

> [!quote] 一句话记忆
> **`CROSS JOIN`（= 逗号连接）就是笛卡尔积，行数 = 两表行数相乘，漏写条件会静默爆炸；它的正经用法是"造骨架"——`CROSS JOIN` 铺网格、`LEFT JOIN` 填数据、`IFNULL` 补 0。**

---

## 相关笔记

- [[INNER JOIN]] —— `CROSS JOIN` 加 `WHERE` 即内连接
- [[LEFT JOIN]] —— 骨架造好后，用它填充真实数据
- [[RIGHT JOIN]] —— 保右表全员
- [[FULL OUTER JOIN]] —— 两表并集，`UNION` 模拟
- [[SELF JOIN]] —— 同一张表自己连自己，也常造组合
- [[计算机类/数据库/Mysql/数据库概念/笛卡尔积]] —— 笛卡尔积的数学定义与灾难
- [[Join]] —— 六种连接的横向总览
- [[COUNT]] —— 计数，验证笛卡尔积行数
