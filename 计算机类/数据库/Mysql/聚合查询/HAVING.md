# HAVING —— 聚合结果的过滤

> [!abstract] 一句话
> `HAVING` 是聚合查询的**过滤网**——它作用在**分组聚合之后**，面向的是"**组**"而不是"行"，所以它==**是唯一能直接拿聚合函数当条件的地方**==：`HAVING AVG(salary) > 8000` 合法，而 `WHERE AVG(salary) > 8000` 直接 `ERROR 1111`。

> [!info] 与 `DML` 版的分工
> 同名的 [[计算机类/数据库/Mysql/DML/Having]] 把 `HAVING` **对比 `WHERE` 的完整表格、报错合集、四件套配合**讲得很全。
> 这一篇**不重复那些**，专讲聚合视角下 `HAVING` 的三件事：**它是聚合查询的"组过滤"、能吃什么、以及性能代价**。两篇对照看。

---

> [!example] 本篇示例数据
> 与同目录的 `COUNT` / `SUM` / `AVG` / `MAX` / `MIN` / `GROUP BY` 各篇**共用同一张 `emp` 表**。
> 三个部门人数不等（研发 3 / 销售 3 / 财务 2），正好用来看"按组规模/组均值过滤"的效果。

```sql
CREATE TABLE emp (
    id        INT AUTO_INCREMENT PRIMARY KEY,
    name      VARCHAR(20) NOT NULL,
    dept      VARCHAR(20),      -- 部门
    gender    CHAR(1),          -- M 男 / F 女
    salary    DECIMAL(10,2),    -- 月薪
    hire_date DATE,             -- 入职日期
    bonus     DECIMAL(10,2)     -- 年终奖，有人是 NULL
);

INSERT INTO emp (name, dept, gender, salary, hire_date, bonus) VALUES
('张伟', '研发部', 'M', 12000.00, '2018-03-11', 5000.00),
('李娜', '研发部', 'F',  9000.00, '2020-07-01',    NULL),
('王强', '研发部', 'M', 15000.00, '2019-05-20', 8000.00),
('赵敏', '销售部', 'F',  8000.00, '2021-09-15', 3000.00),
('陈晨', '销售部', 'M',  6500.00, '2022-02-08',    NULL),
('刘洋', '销售部', 'F',  7500.00, '2020-11-30', 3000.00),
('孙悦', '财务部', 'F',  7000.00, '2023-04-01',    NULL),
('周杰', '财务部', 'M',  9500.00, '2020-08-22', 4000.00);
```

`SELECT * FROM emp;` 的完整数据：

```
+----+--------+--------+--------+----------+------------+---------+
| id | name   | dept   | gender | salary   | hire_date  | bonus   |
+----+--------+--------+--------+----------+------------+---------+
|  1 | 张伟   | 研发部 | M      | 12000.00 | 2018-03-11 | 5000.00 |
|  2 | 李娜   | 研发部 | F      |  9000.00 | 2020-07-01 |    NULL |
|  3 | 王强   | 研发部 | M      | 15000.00 | 2019-05-20 | 8000.00 |
|  4 | 赵敏   | 销售部 | F      |  8000.00 | 2021-09-15 | 3000.00 |
|  5 | 陈晨   | 销售部 | M      |  6500.00 | 2022-02-08 |    NULL |
|  6 | 刘洋   | 销售部 | F      |  7500.00 | 2020-11-30 | 3000.00 |
|  7 | 孙悦   | 财务部 | F      |  7000.00 | 2023-04-01 |    NULL |
|  8 | 周杰   | 财务部 | M      |  9500.00 | 2020-08-22 | 4000.00 |
+----+--------+--------+--------+----------+------------+---------+
```

---

## 一、语法与位置

```sql
SELECT   分组列, 聚合函数
FROM     表名
WHERE    行级条件
GROUP BY 分组列
HAVING   组级条件          -- ← 就在这个位置
ORDER BY 排序列
LIMIT    n;
```

> [!important] 位置是硬性的
> `HAVING` **必须写在 `GROUP BY` 之后、`ORDER BY` 之前**。
> 把 `HAVING` 提到 `GROUP BY` 前面，直接 `ERROR 1064`——这是**语法层面**的限制，不是"优化器会帮你调整"的问题。

```sql
-- ✅ 正确
SELECT dept, COUNT(*) AS 人数 FROM emp GROUP BY dept HAVING COUNT(*) >= 3;

-- ❌ ERROR 1064: You have an error in your SQL syntax
SELECT dept, COUNT(*) AS 人数 FROM emp HAVING COUNT(*) >= 3 GROUP BY dept;
```

```
+--------+--------+
| dept   | 人数   |
+--------+--------+
| 研发部 |      3 |
| 销售部 |      3 |
+--------+--------+
```

（`财务部` 只有 2 人，被 `HAVING` 在分组**之后**过滤掉了。）

---

## 二、为什么 `WHERE` 代替不了 `HAVING`

这是 `HAVING` 存在的**唯一理由**：聚合的结果只有在分组之后才诞生，而 `WHERE` 在那之前就执行了。

```sql
-- ❌ ERROR 1111 (HY000): Invalid use of group function
SELECT dept, AVG(salary) AS avg_sal
FROM emp
WHERE AVG(salary) > 8000
GROUP BY dept;
```

> [!failure] 报错解读
> `WHERE` 执行时，数据还是**一行一行的原始状态，分组还没发生**。
> `AVG(salary)` 的语义是"某组内所有 salary 的平均"——此刻**不存在"组"这个东西**，函数无从下手。
> MySQL 判定"group function 用在了非法位置"，报 `ERROR 1111`。

> [!note] 同类报错
> `WHERE COUNT(*) > 1`、`WHERE SUM(salary) > 100000`、`WHERE MAX(salary) > 10000` 全都触发 `ERROR 1111`。
> **判断标准：只要 `WHERE` 里出现了聚合函数，就是这个错。**

正确写法是把它整体挪到 `HAVING`：

```sql
SELECT dept, ROUND(AVG(salary), 2) AS avg_sal
FROM emp
GROUP BY dept
HAVING AVG(salary) > 8000
ORDER BY avg_sal DESC;
```

```
+--------+----------+
| dept   | avg_sal  |
+--------+----------+
| 研发部 | 12000.00 |
| 财务部 |  8250.00 |
+--------+----------+
```

`销售部` 均薪 `(8000+6500+7500)/3 = 7333.33`，没过 8000，被过滤掉。

---

## 三、`WHERE` vs `HAVING`：一句话分工

> [!important] 记住这一句
> ==**`WHERE` 管"行"（分组前），`HAVING` 管"组"（分组后）。**==
> 判断一个条件该放哪：**它需不需要先分组算一下？**
> - 不需要（针对单个行）→ `WHERE`
> - 需要（针对整组）→ `HAVING`

| 对比维度 | `WHERE` | `HAVING` |
| --- | --- | --- |
| **执行时机** | `GROUP BY` **之前** | `GROUP BY` **之后** |
| **过滤对象** | 单个**行** | 单个**组** |
| **能否用聚合函数** | ❌ `ERROR 1111` | ✅ **能** |
| **能否用 `SELECT` 别名** | ❌ `ERROR 1054` | ✅（MySQL 扩展） |
| **能否用索引** | ✅ 能 | ❌ 不能 |
| **性能** | 更快（先减少数据量） | 更慢（分组算完再丢） |

> [!tip] 能放 `WHERE` 就一定要放 `WHERE`
> 这不是"能不能跑"的问题，是**性能问题**：`WHERE` 把 100 万行砍成 1000 行再分组，和分组完 100 万行再扔掉 99.9%，代价差几个数量级。
> 而且 **`WHERE` 能用索引，`HAVING` 永远用不上索引**——它面对的是分组后的中间结果。

> [!info] 两者不互斥，是配合关系
> 一条 SQL 里同时出现 `WHERE` 和 `HAVING` 最正常：
> - `WHERE` 决定"哪些**行**有资格参与统计"
> - `HAVING` 决定"哪些**组**有资格出现在结果里"

```sql
-- 先 WHERE 砍行，再 GROUP BY 分组，最后 HAVING 挑组
SELECT dept, COUNT(*) AS 人数, ROUND(AVG(salary), 2) AS avg_sal
FROM emp
WHERE gender = 'F'                 -- 行过滤：8 行 → 4 行
GROUP BY dept
HAVING AVG(salary) > 7500          -- 组过滤
ORDER BY avg_sal DESC;
```

```
+--------+--------+----------+
| dept   | 人数   | avg_sal  |
+--------+--------+----------+
| 研发部 |      1 |  9000.00 |
| 销售部 |      2 |  7750.00 |
+--------+--------+----------+
```

`财务部` 只剩孙悦 7000 < 7500，被 `HAVING` 淘汰。

---

## 四、`HAVING` 能吃什么：三种典型条件

`HAVING` 面向"组"，标准形态是 `HAVING 聚合函数(列) 比较 值`：

| 条件类型 | 例子 | 语义 |
| --- | --- | --- |
| **组规模** | `HAVING COUNT(*) >= 3` | 人多的部门 |
| **组求和** | `HAVING SUM(salary) > 30000` | 工资总额高的部门 |
| **组均值** | `HAVING AVG(salary) > 8000` | 平均工资高的部门 |
| **组极值** | `HAVING MAX(salary) > 10000` / `HAVING MIN(salary) < 7000` | 有人超高薪 / 有人偏低 |

```sql
-- 一条语句里同时用多个聚合条件
SELECT dept,
       COUNT(*)      AS 人数,
       SUM(salary)   AS 工资总额,
       ROUND(AVG(salary), 2) AS 平均工资
FROM emp
GROUP BY dept
HAVING COUNT(*) >= 3 AND AVG(salary) > 8000;
```

```
+--------+--------+--------------+--------------+
| dept   | 人数   | 工资总额     | 平均工资     |
+--------+--------+--------------+--------------+
| 研发部 |      3 |     36000.00 |     12000.00 |
+--------+--------+--------------+--------------+
```

> [!tip] `HAVING` 条件之间可以用 `AND` / `OR`
> 和 `WHERE` 里的逻辑运算符规则一样（`AND` 优先于 `OR`，混用时给 `OR` 加括号）。
> 聚合条件与非聚合条件也能混在 `HAVING` 里，但**非聚合条件能挪到 `WHERE` 就挪过去**（更快）。

---

## 五、`HAVING` 里能用 `SELECT` 别名（MySQL 扩展）

```sql
SELECT dept, ROUND(AVG(salary), 2) AS avg_sal
FROM emp
GROUP BY dept
HAVING avg_sal > 8000          -- 直接用别名
ORDER BY avg_sal DESC;
```

```
+--------+----------+
| dept   | avg_sal  |
+--------+----------+
| 研发部 | 12000.00 |
| 财务部 |  8250.00 |
+--------+----------+
```

能这么写，是因为 **`HAVING` 的执行时机在 `SELECT` 之后**——别名已经诞生了。

> [!warning] 这是 MySQL 方言，不是标准 SQL
> SQL 标准里 `HAVING` 只能引用**表里的原始列名**，别名只有 `ORDER BY` 能用。
> MySQL 顺手把口子放开了，但**移植到 PostgreSQL / Oracle / SQL Server 会报错**（`column "avg_sal" does not exist`）。
> 另一层风险：表里若**恰好有一个叫 `avg_sal` 的列**，MySQL 会优先用表里的列而不是别名，结果悄悄变了。
>
> **稳妥写法**：`HAVING` 里把聚合表达式**原样重写一遍**：`HAVING ROUND(AVG(salary), 2) > 8000`。

| 子句 | 能用别名 | 能用聚合函数 |
| --- | --- | --- |
| `WHERE` | ❌ `ERROR 1054` | ❌ `ERROR 1111` |
| `GROUP BY` | ❌（标准）/ 部分支持 | ❌ |
| `HAVING` | ✅（MySQL 扩展） | ✅ |
| `ORDER BY` | ✅ | ✅ |

---

## 六、性能：`HAVING` 的代价与优化

> [!danger] `HAVING` 永远用不上索引
> 因为它在分组**之后**执行，面对的是"已经算好的组"这张**中间结果**，索引（建在原始表上）对它无能为力。
> 所以**能写进 `WHERE` 的条件，绝不要留给 `HAVING`**。

优化的三步思路：

```sql
-- ❌ 差：全表分组后再过滤
SELECT dept, COUNT(*) AS 人数
FROM emp
GROUP BY dept
HAVING COUNT(*) >= 3;     -- 先把 8 行分完组（3 组），再扔掉 1 组

-- ✅ 好（当条件本就针对"行"时）：先 WHERE 砍行
SELECT dept, COUNT(*) AS 人数
FROM emp
WHERE ...                 -- 能在行级过滤的先在这里过滤
GROUP BY dept
HAVING COUNT(*) >= 3;
```

| 做法 | 代价 |
| --- | --- |
| 行级条件放 `WHERE` | ✅ 走索引，参与分组的行更少 |
| 行级条件误放 `HAVING` | ❌ 全部分组算完再丢，且结果可能是**随机的**（见下） |
| 组级条件放 `HAVING` | ✅ 这是它的本职，无替代 |

> [!warning] 把行级条件挪到 `HAVING` 不只是"慢"，还会"错"
> ```sql
> -- ⚠️ hire_date 不是分组列，HAVING 里比较的是"组内随机一行的 hire_date"
> ... GROUP BY dept HAVING hire_date > '2020-01-01';
> ```
> 开了 `only_full_group_by` 会报 `ERROR 1055`；关掉则**结果不可预测**。
> 行级条件必须放 `WHERE`。

> [!note] 想加速"组过滤"的正道
> 1. **先 `WHERE` 后 `HAVING`**，把行数降到最低；
> 2. 让 `GROUP BY` 走索引（联合索引列顺序 = 分组列顺序），分组本身快了，`HAVING` 的输入就小；
> 3. 数据量极大时，考虑**物化中间结果**（临时表 + 索引）或交给 OLAP / BI 工具，而不是硬扛。

---

## 七、经典陷阱：`HAVING` 后面跟裸列名

> [!danger] 这是最危险的写法
> 很多人以为"`HAVING` 就是过滤，那 `HAVING salary > 8000` 应该也能跑"。
> 它**确实能跑**（某些 `sql_mode` 下），但语义完全不是你想的那样——`salary` 是**行级字段**，MySQL 面对组里多个不同的 `salary`，只能**随便挑一行**来判断。

```sql
-- ⚠️ 危险写法
SELECT dept, COUNT(*) AS 人数
FROM emp
GROUP BY dept
HAVING salary > 8000;
```

| `sql_mode` | 行为 | 结果 |
| --- | --- | --- |
| 含 `ONLY_FULL_GROUP_BY`（5.7+ 默认） | **直接报错** `ERROR 1055` | — |
| 关掉该模式 | 每组**随机取一行**判断 | **行数可能变** |

关掉模式后：研发部组里 3 个都 > 8000 → 必留；财务部组里 7000/9500 → **取决于运气**；销售部 8000/6500/7500 → 大概率不留。**加个索引或换版本，结果就从 2 行变 1 行。**

> [!success] 判断法则
> 看到 `HAVING` 后面跟着一个**裸列名**（没被聚合函数包起来），先问自己：
> **"我这个列是分组列吗？"**
> - 是分组列（如 `HAVING dept = '研发部'`）→ 合法，但**挪到 `WHERE` 更快**
> - 不是分组列（如 `HAVING salary > 8000`）→ **写完心里没底，一定有语义问题**
>
> 组级判断的标准形态永远是：`HAVING 聚合函数(列) 比较 值`。

> [!question] 那"筛选工资大于 8000 的人所在部门"到底怎么写？
> 先问清需求方的**真实意图**：
> ```sql
> -- 意图一：只看高薪的人，再统计各部门 → 用 WHERE
> SELECT dept, COUNT(*), SUM(salary) FROM emp WHERE salary > 8000 GROUP BY dept;
>
> -- 意图二：整个部门参与统计，只要该部门有人超过 8000 就展示 → 用 HAVING MAX
> SELECT dept, COUNT(*), SUM(salary) FROM emp GROUP BY dept HAVING MAX(salary) > 8000;
> ```
> 两种写法"看起来类似"，**数字却不一样**（财务部人数一个是 1、一个是 2）。这就是"语义先于语法"的典型例子。

---

## 八、只写 `HAVING` 不写 `GROUP BY`

> [!info] 合法，但只有一行结果
> 不写 `GROUP BY` 时，SQL 标准规定**整个结果集视为一个组**，于是 `HAVING` 变成"对全表聚合后的结果做一次判断"——要么返回 1 行，要么返回 0 行。

```sql
SELECT ROUND(AVG(salary), 2) AS avg_sal
FROM emp
HAVING AVG(salary) > 8000;
```

```
+----------+
| avg_sal  |
+----------+
|  9312.50 |
+----------+
```

全公司 8 人工资总额 `74500`，`74500 / 8 = 9312.50`，过 8000，返回 1 行。
把阈值改成 `10000` → `Empty set`（空结果集，不是 NULL 行）。**它的价值是"整表级门槛判断"：不达标就干脆不返回任何行。**

> [!warning] 两条限制
> 1. `SELECT` 里只能有聚合函数和常量，出现任何裸列都报 `ERROR 1055`（唯一一组里有很多不同的 `name`）；
> 2. **结果永远不超过 1 行**。如果你期望多行，说明**漏写了 `GROUP BY`**——很常见的低级失误。

> [!tip] 这种写法可读性差，团队里建议规避
> 等价且更清晰的写法是加一个恒真的 `GROUP BY 1`，或者直接在应用层判断。

---

## 九、完整配合：`WHERE` + `GROUP BY` + `HAVING` + `ORDER BY`

**需求**：筛选 **2020 年后入职**的员工，按**部门**统计平均工资，只保留平均工资**超过 8000** 的部门，按平均工资**降序**排列。

```sql
SELECT dept,
       COUNT(*)               AS 人数,
       ROUND(AVG(salary), 2)  AS avg_sal
FROM emp
WHERE hire_date > '2020-01-01'      -- ① 行过滤
GROUP BY dept                       -- ② 分组
HAVING AVG(salary) > 8000           -- ③ 组过滤
ORDER BY avg_sal DESC;              -- ④ 排序
```

```
+--------+--------+----------+
| dept   | 人数   | avg_sal  |
+--------+--------+----------+
| 研发部 |      1 |  9000.00 |
| 财务部 |      2 |  8250.00 |
+--------+--------+----------+
```

| 步骤 | 子句 | 动作 | 数据量 |
| --- | --- | --- | --- |
| ① | `FROM emp` | 取全表 | 8 行 |
| ② | `WHERE hire_date > '2020-01-01'` | 砍行 | 8 → **6 行** |
| ③ | `GROUP BY dept` | 分 3 个桶 | 6 行 → 3 组 |
| ④ | 聚合 `COUNT` / `AVG` | 每组算值 | 3 组 → 3 行 |
| ⑤ | `HAVING AVG(salary) > 8000` | 销售部 7333.33 出局 | 3 → **2 组** |
| ⑥ | `SELECT` | 选列、起别名 | 2 行 |
| ⑦ | `ORDER BY avg_sal DESC` | 研发部 9000 > 财务部 8250 | 2 行 |

> [!important] 执行顺序链（背下来，报错就能自己诊断）
> **`FROM → WHERE → GROUP BY → 聚合 → HAVING → SELECT → ORDER BY → LIMIT`**
> - `WHERE` 报"未知列" → 你用了别名（还没诞生）
> - `WHERE` 报 "Invalid use of group function" → 你用了聚合（组还没诞生）
> - `HAVING` 能用别名和聚合 → 因为它在 `SELECT` 和分组之后
> - `ORDER BY` 什么都能用 → 它在最后

---

## 十、常见报错合集

> [!failure] ERROR 1111：Invalid use of group function
> **原因**：聚合函数写进了 `WHERE`（或 `GROUP BY`，或 `ON`）。
> **改法**：整体挪到 `HAVING`。

> [!failure] ERROR 1055：... not in GROUP BY clause
> **原因**：`SELECT` 或 `HAVING` 里出现**既不在 `GROUP BY`、又没被聚合包起来**的列。
> 典型：`HAVING salary > 8000`（`salary` 非分组列）。
> **改法**：① 加进 `GROUP BY`；② 套聚合函数（`MAX(salary)`）；③ 用窗口函数替代分组。
> **千万别** `SET sql_mode = ''` 关检查——那会从"报错"退化成"静默返回随机值"。

> [!failure] ERROR 1064：You have an error in your SQL syntax
> **原因**：子句顺序错，最常见是 `HAVING` 跑到了 `GROUP BY` 前面。

> [!failure] ERROR 1054：Unknown column
> `HAVING` 里引用了不存在的列；在别名场景下，常见是**别名和表里某列重名**导致指向错误。把表达式重写一遍最稳妥。

> [!danger] 最后的忠告
> `ERROR 1055` 和 `ERROR 1111` 是**"好报错"**——它们替你拦住了语义不清的写法。
> 真正要命的是**关掉 `sql_mode` 后不报错但结果乱飘**。见到 `only_full_group_by`，正确反应是"**改我的 SQL**"，不是"关掉这个模式"。

---

## 十一、速查表

| 需求 | 该用哪个 | 写法 |
| --- | --- | --- |
| 过滤某个员工 / 入职年份 | `WHERE` | `WHERE salary > 8000` / `WHERE hire_date > '2020-01-01'` |
| 过滤部门平均工资 | `HAVING` | `HAVING AVG(salary) > 8000` |
| 过滤部门人数 | `HAVING` | `HAVING COUNT(*) >= 3` |
| 过滤部门工资总额 | `HAVING` | `HAVING SUM(salary) > 30000` |
| 过滤部门极值 | `HAVING` | `HAVING MAX(salary) > 10000` |
| 部门名称筛选 | `WHERE`（别写 `HAVING`） | `WHERE dept = '研发部'` |

判断流程：

| 问自己 | 答 | 结论 |
| --- | --- | --- |
| 条件里用了聚合函数吗？ | 用了 | 只能写 `HAVING` |
| | 没用 | 往下问 |
| 条件是针对单个行的吗？ | 是 | 写 `WHERE`（更快） |
| | 不是，是分组列 | 也能写 `HAVING`，但写 `WHERE` 更好 |

> [!question] 自测三连
> 1. `SELECT dept, AVG(salary) FROM emp WHERE AVG(salary) > 8000 GROUP BY dept;` 报什么错？改怎么写？
> 2. `HAVING salary > 8000` 和 `WHERE salary > 8000` 的语义差异是什么？为什么前者"结果不可预测"？
> 3. `HAVING` 里能用 `SELECT` 别名，是标准 SQL 还是 MySQL 扩展？有什么风险？

---

> [!quote] 一句话记忆
> **`WHERE` 砍行、`HAVING` 挑组**：`HAVING` 在分组后执行、面向整个组、**必须用聚合函数才有意义**，也是唯一能直接吃聚合函数的地方；`HAVING` **永远用不上索引**，所以能进 `WHERE` 的行级条件一定要放 `WHERE`。

---

## 相关笔记

- [[计算机类/数据库/Mysql/DML/Having]] —— **完整版**：`WHERE`/`HAVING` 完整对比表、报错合集、四件套配合
- [[计算机类/数据库/Mysql/聚合查询/GROUP BY]] —— `HAVING` 的前置：分完组才有"组"可挑
- [[计算机类/数据库/Mysql/DML/Where]] —— 分组**前**的行级过滤，能用索引
- [[计算机类/数据库/Mysql/DML/Select]] —— 各子句执行顺序与别名生效时机
- [[计算机类/数据库/Mysql/DML/Order By]] —— 对分组结果排序
- [[计算机类/数据库/Mysql/聚合查询/COUNT]] · [[计算机类/数据库/Mysql/聚合查询/SUM]] · [[计算机类/数据库/Mysql/聚合查询/AVG]] · [[计算机类/数据库/Mysql/聚合查询/MAX]] · [[计算机类/数据库/Mysql/聚合查询/MIN]] —— `HAVING` 里常用的聚合函数
