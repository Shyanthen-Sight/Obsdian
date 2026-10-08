# JOIN —— 多表连接

> [!abstract] 一句话
> JOIN 的本质是==**双层循环 + 条件匹配**==：拿左表每一行去右表逐行比对，条件成立就把两行拼成一行输出。
> 
> ==内连接和外连接的唯一区别是 没匹配上的行要不要留下来。==

---

> [!example] 本篇示例数据
> `dept`（部门）和 `emp`（员工）。故意留了两处"不匹配"——**财务部没人**、**孙七没部门**，它们是后面每种连接的照妖镜。
> `emp.dept_id` 故意允许 `NULL`（逻辑外键，可加 [[外键约束]]，这里为了演示 NULL 没加）。

```sql
CREATE TABLE dept (
    dept_id   INT PRIMARY KEY,
    dept_name VARCHAR(20)
);

CREATE TABLE emp (
    emp_id   INT PRIMARY KEY,
    emp_name VARCHAR(20),
    dept_id  INT,              -- 故意允许 NULL，演示"没有部门的员工"
    salary   DECIMAL(10,2)
);

INSERT INTO dept VALUES (1001, '研发部'), (1002, '销售部'), (1003, '财务部');

INSERT INTO emp VALUES (1, '张三', 1001, 12000),
                       (2, '李四', 1001, 15000),
                       (3, '王五', 1002,  9000),
                       (4, '赵六', 1002,  8500),
                       (5, '孙七', NULL,  7000);
```

两张表的原始数据：

```
-- dept（3 行）
dept_id | dept_name
--------+----------
   1001 | 研发部
   1002 | 销售部
   1003 | 财务部     <-- 财务部没有任何员工

-- emp（5 行）
emp_id | emp_name | dept_id | salary
-------+----------+---------+--------
     1 | 张三     |    1001 |  12000
     2 | 李四     |    1001 |  15000
     3 | 王五     |    1002 |   9000
     4 | 赵六     |    1002 |   8500
     5 | 孙七     |    NULL |   7000   <-- 孙七没有部门
```

> [!note] 先记住这两个"异类"
> - **财务部 (1003)**：`dept` 里有，`emp` 里没人认领 → 只有**外连接**让它露脸
> - **孙七 (emp_id=5)**：`emp.dept_id IS NULL` → 只有**外连接**让他露脸
> 后面每一节的差异，都体现在"这两行在不在结果里"。

---

## 一、为什么需要连接

一张表塞下所有信息会得四种病：**数据冗余**（部门名重复 100 遍）、**更新异常**（改名漏一行就不一致）、**插入异常**（新部门没员工，无处安放）、**删除异常**（删掉最后一名员工，部门信息跟着消失）。
拆表靠范式，把表拼回来靠 `JOIN`——它的执行伪代码就是 `for 左表每行 → for 右表每行 → 条件成立就输出`。

> [!tip] 三者职责别混
> `FROM` 决定"从哪些表拿数据"（[[From]]），`JOIN` 决定"怎么拼"，`WHERE` 决定"拼完筛什么"（[[Where]]）。混在一起就会踩第六章那个大坑。

---

## 二、SQL 连接的分类全景

| 连接类型     | 关键字                  | 保留哪些行                          | MySQL |
| -------- | -------------------- | ------------------------------ | ----- |
| ==内连接==  | `INNER JOIN`         | ==只保留**两边都匹配上**的==             | ✅     |
| ==左外连接== | `LEFT [OUTER] JOIN`  | ==**左表全部** + 右表匹配的（缺的补 NULL）== | ✅     |
| ==右外连接== | `RIGHT [OUTER] JOIN` | ==**右表全部** + 左表匹配的（缺的补 NULL）== | ✅     |
| ==全外连接== | `FULL OUTER JOIN`    | ==两表**全部的并集**==                | ❌ 不支持 |
| ==交叉连接== | `CROSS JOIN`         | ==笛卡尔积，两表行的**两两组合**==          | ✅     |
| ==自连接==  | `SELF JOIN`          | ==同一张表**自己连自己**（靠别名）==         | ✅     |


用这两张表画成区域图，谁在哪一块一目了然：

```
     dept 独有          dept ∩ emp           emp 独有
   ┌───────────┐   ┌──────────────────┐   ┌───────────┐
   │  财务部    │   │ 研发部 ← 张三、李四│   │   孙七     │
   │  (1003)   │   │ 销售部 ← 王五、赵六│   │(dept=NULL)│
   └───────────┘   └──────────────────┘   └───────────┘
    LEFT JOIN = 左两块     RIGHT JOIN = 右两块
    FULL JOIN = 三块全要   INNER JOIN = 只中间一块
```

> [!warning] MySQL 里没有 `FULL OUTER JOIN`
> 写了直接报语法错，**只能用 `LEFT JOIN ... UNION ... RIGHT JOIN` 模拟**（见第八章）。
> MySQL 也没有 `LEFT ANTI JOIN` 语法，"反连接"要靠 `LEFT JOIN + IS NULL` 手写（见第四章）。

> [!question] 面试高频三连
> 1. "LEFT JOIN 和 INNER JOIN 的区别？" → ==**保留行的策略不同**：左表全留 / 只留匹配上的==
> 2. "LEFT JOIN 后 WHERE 加右表条件会怎样？" → **退化成 INNER JOIN**，筛人题
> 3. "ON 和 WHERE 能互换吗？" → **不能**，同一句话写两处结果不同

---

## 三、内连接 INNER JOIN

```sql
-- INNER 可以省略，JOIN 默认就是 INNER JOIN
SELECT e.emp_name, e.salary, d.dept_name
FROM emp e
INNER JOIN dept d ON e.dept_id = d.dept_id
ORDER BY e.emp_id;
```

结果（**4 行**）：

```
emp_name | salary | dept_name
---------+--------+----------
张三     |  12000 | 研发部
李四     |  15000 | 研发部
王五     |   9000 | 销售部
赵六     |   8500 | 销售部
```

看清少了谁：**财务部**没出现（`dept` 里有、`emp` 里没人匹配），==**孙七**没出现==（`dept_id IS NULL`，NULL 跟谁都不相等）。

> [!tip] 为什么 NULL 永远匹配不上
> 对孙七来说 `ON e.dept_id = d.dept_id` 就是 `NULL = 1001`，结果是 `NULL`（未知），ON 只认 `TRUE`，所以==**内连接会自动丢掉外键为 NULL 的行**==——这是三值逻辑的必然结果，不是 bug。

### 3.1 隐式内连接（逗号 + WHERE）

```sql
-- 老写法：FROM 后用逗号列出多张表，连接条件写在 WHERE 里
SELECT e.emp_name, e.salary, d.dept_name
FROM emp e, dept d
WHERE e.dept_id = d.dept_id
ORDER BY e.emp_id;
```

结果与上面**一模一样**（同样 4 行，顺序也一致）：

```
emp_name | salary | dept_name
---------+--------+----------
张三     |  12000 | 研发部
李四     |  15000 | 研发部
王五     |   9000 | 销售部
赵六     |   8500 | 销售部
```

> [!success] 两者等价，但推荐显式 JOIN
> 隐式写法是"先做笛卡尔积再用 WHERE 筛"，显式 JOIN 是"边连边匹配"；优化器给出的执行计划通常一样，**性能没差**，差别全在**可读性和出错概率**上。

| 对比项    | 隐式（逗号 + WHERE）             | 显式（`JOIN ... ON`）        |
| ------ | -------------------------- | ------------------------ |
| 连接条件位置 | 混在 `WHERE` 里               | 独立在 `ON` 里，与过滤条件分离       |
| 漏写连接条件 | 静默变成**笛卡尔积**（3×5=15 行），不报错 | 语法上必须写 `ON`，很难漏          |
| 外连接    | ❌ 表示不了                     | ✅ `LEFT/RIGHT JOIN` 原生支持 |
| 多表时    | 条件越堆越长，容易漏                 | 一个 JOIN 跟一个 ON，链式清晰      |

> [!danger] 漏写 WHERE 的隐式连接 = 灾难
> `SELECT * FROM emp, dept;` 语法完全合法，结果却是 15 行笛卡尔积；一张 10 万行的表 × 一张 1 万行的表漏一个条件就是 **10 亿行**，数据库直接被打挂。
> 所以团队规范基本都是 **==禁止逗号连接，一律显式 JOIN==**。

---

## 四、左外连接 LEFT JOIN（重点）

```sql
SELECT d.dept_id, d.dept_name, e.emp_name, e.salary
FROM dept d
LEFT JOIN emp e ON d.dept_id = e.dept_id
ORDER BY d.dept_id, e.emp_id;
```

结果（**5 行**，注意最后一行）：

```
dept_id | dept_name | emp_name | salary
--------+-----------+----------+--------
   1001 | 研发部    | 张三     |  12000
   1001 | 研发部    | 李四     |  15000
   1002 | 销售部    | 王五     |   9000
   1002 | 销售部    | 赵六     |   8500
   1003 | 财务部    | NULL     |   NULL   <-- 左表这行必须留着，右表没东西就补 NULL
```

> [!tip] 记忆法：LEFT JOIN = 左表"全员到场"
> 左表每行至少输出一次；右表匹配上就拼上，匹配不上就整列填 `NULL`。内连接 4 行、LEFT JOIN 5 行，**多出来那行就是财务部**；反过来 `emp LEFT JOIN dept` 会多出孙七——==谁写在左边谁说话==。

### 4.1 反连接：找"左表有、右表没有"的行

```sql
-- 找出"没有部门的员工"
SELECT e.emp_id, e.emp_name
FROM emp e
LEFT JOIN dept d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;      -- 右表没匹配上 → 右表主键必为 NULL
```

结果：

```
emp_id | emp_name
-------+---------
     5 | 孙七
```

> [!important] 反连接的判断键要选"右表主键"
> 主键**不允许为 NULL**，变成 NULL 只可能是"没匹配上"；若拿**本身可为空**的业务字段（如 `d.remark`）判断，匹配上了但值恰好为 NULL 就会**误判**。

### 4.2 经典应用：统计每个部门人数（含 0 人的部门）

```sql
SELECT d.dept_id, d.dept_name, COUNT(e.emp_id) AS emp_count
FROM dept d
LEFT JOIN emp e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY d.dept_id;
```

```
dept_id | dept_name | emp_count
--------+-----------+-----------
   1001 | 研发部    |         2
   1002 | 销售部    |         2
   1003 | 财务部    |         0   <-- 正确！财务部保住了
```

> [!danger] 为什么必须写 COUNT(e.emp_id)，不能写 COUNT(*)
> `COUNT(*)` 数**结果集行数**，`COUNT(列名)` 数**该列非 NULL 的个数**。财务部那行是左连接补出来的，右表字段**整行都是 NULL**：
> - `COUNT(*)` → 这行存在，数进去，得到 **1**（错的）
> - `COUNT(e.emp_id)` → 该行 `emp_id` 为 NULL，不计入，得到 **0**（对的）
> 一句话：**外连接里统计右表数量，一律 `COUNT(右表列)`**，这个坑必踩一次。

---

## 五、右外连接 RIGHT JOIN

```sql
SELECT d.dept_id, d.dept_name, e.emp_name, e.salary
FROM dept d
RIGHT JOIN emp e ON d.dept_id = e.dept_id
ORDER BY e.emp_id;
```

结果（**5 行**，这次轮到左表的数据为 NULL）：

```
dept_id | dept_name | emp_name | salary
--------+-----------+----------+--------
   1001 | 研发部    | 张三     |  12000
   1001 | 研发部    | 李四     |  15000
   1002 | 销售部    | 王五     |   9000
   1002 | 销售部    | 赵六     |   8500
   NULL | NULL      | 孙七     |   7000   <-- 右表这行必须留着，左表没东西就补 NULL
```

财务部这次**不见了**（它在 `dept` 里属于"左表独有"），孙七出现了。RIGHT JOIN 保留的是**右表全部行**。

> [!important] RIGHT JOIN 都能改写成 LEFT JOIN
> 两张表顺序一换，RIGHT JOIN 就等价于 LEFT JOIN，**结果集完全相同**（只有列的输出顺序会变）：
> `FROM dept d RIGHT JOIN emp e ON d.dept_id = e.dept_id` ≡ `FROM emp e LEFT JOIN dept d ON e.dept_id = d.dept_id`
>
> **团队规范通常只允许用 LEFT JOIN**：心智负担减一半（永远只问"谁是左表、谁全留"）；多表时混用 `LEFT`/`RIGHT` 会把"谁保留"搅成一团，是代码审查重灾区。

```sql
-- 等价改写：同一个结果，只用 LEFT JOIN 表达
SELECT e.emp_id, e.emp_name, e.salary, d.dept_name
FROM emp e
LEFT JOIN dept d ON e.dept_id = d.dept_id
ORDER BY e.emp_id;
```

> [!note] 那 RIGHT JOIN 什么时候用？
> 实战中基本不用，价值主要是"主表恰好写在右边时顺手"和**面试做对比**；见到 `RIGHT JOIN`，第一反应应该是"能不能翻成 LEFT JOIN"。

---

## 六、ON 和 WHERE 的位置差异 —— LEFT JOIN 最大的坑

> [!danger] 本篇最高优先级的一节
> 下面两段 SQL **只差一个关键字的位置**，结果完全不同。这是 LEFT JOIN 唯一必须搞懂的知识点，也是面试最爱考的筛人题。

```sql
-- 写法 A：过滤条件写在 ON 里（属于"连接条件"）
SELECT d.dept_name, e.emp_name, e.salary
FROM dept d
LEFT JOIN emp e ON d.dept_id = e.dept_id AND e.salary > 10000;

-- 写法 B：过滤条件写在 WHERE 里（属于"连接后的过滤"）
SELECT d.dept_name, e.emp_name, e.salary
FROM dept d
LEFT JOIN emp e ON d.dept_id = e.dept_id
WHERE e.salary > 10000;
```

**写法 A 的结果（4 行）：**

```
dept_name | emp_name | salary
----------+----------+--------
研发部    | 张三     |  12000
研发部    | 李四     |  15000
销售部    | NULL     |   NULL   <-- 王五、赵六不满足条件，但销售部这行保住了
财务部    | NULL     |   NULL   <-- 财务部本来就没人，照样在
```

**写法 B 的结果（2 行）：**

```
dept_name | emp_name | salary
----------+----------+--------
研发部    | 张三     |  12000
研发部    | 李四     |  15000
```

**销售部和财务部整行消失了。** 根本原因是条件作用的阶段不同：

| | 写法 A（条件在 ON） | 写法 B（条件在 WHERE） |
| --- | --- | --- |
| 条件作用阶段 | **连接时** | **连接完成之后** |
| 不满足条件时 | 放弃匹配该右表行，左表行**仍保留**，右表列补 NULL | 外连接先照常做完，再统一筛 |
| 对补出的 NULL 行 | **不受影响**，继续留在结果里 | `NULL > 10000` 不是真，**整行被删掉** |
| 最终效果 | 真正的左外连接 | ==**退化成内连接**== |

> [!important] 一句话结论
> **ON 管"怎么连"，WHERE 管"连完筛什么"。**LEFT JOIN 的右表过滤条件，**写在 ON 里才保留左表全部行，写在 WHERE 里外连接就白写了**。
> 判断窍门：写下 `WHERE 右表字段 = ...` 时先问自己——"左表那些匹配不上的行，我还要不要？"要，就把条件挪到 `ON`。

> [!tip] 记不住的替代办法
> 把 `LEFT JOIN` 想成"左表是主角、右表是配角"：**配角的条件写在配角介绍里（ON）**，主角不会因此被删；**写在最后的考核名单里（WHERE）**，没通过考核的直接淘汰，主角也保不住。

> [!warning] 反过来也一样：左表条件该写 WHERE
> 把**左表**的过滤条件写进 `ON` 是另一种错，比如想只看研发部、写成 `... ON d.dept_id = e.dept_id AND d.dept_id = 1001`，结果**所有部门都留下了**（左表行无论条件真假都要保留，条件只是让它匹配不上右表）。
> 口诀：**保留表自己的过滤可以放心写 WHERE；非保留表的条件必须写 ON，否则外连接白写。**

---

## 七、交叉连接 CROSS JOIN

```sql
SELECT d.dept_id, d.dept_name, e.emp_id, e.emp_name
FROM dept d
CROSS JOIN emp e
ORDER BY d.dept_id, e.emp_id;

-- 完全等价的老写法（不写任何连接条件）
SELECT d.dept_id, d.dept_name, e.emp_id, e.emp_name FROM dept d, emp e;
```

结果**3 × 5 = 15 行**，每个部门 × 每个员工的全部组合，前 6 行长这样：

```
dept_id | dept_name | emp_id | emp_name
--------+-----------+--------+---------
   1001 | 研发部    |      1 | 张三
   1001 | 研发部    |      2 | 李四
   1001 | 研发部    |      3 | 王五
   1001 | 研发部    |      4 | 赵六
   1001 | 研发部    |      5 | 孙七
   1002 | 销售部    |      1 | 张三
...（共 15 行，1001 / 1002 / 1003 各 5 行）
```

> [!warning] 行数是"相乘"不是"相加"
> 3 行 × 5 行 = 15 行；三张 1000 行的表 CROSS JOIN 就是 **10 亿行**。忘了写 `ON` 的 JOIN、忘了写 `WHERE` 的逗号连接，都会**静默**产生笛卡尔积——不报错，但结果错得离谱，数据库还可能被打挂。

> [!info] 什么时候故意用 CROSS JOIN
> 它的正经用途是**"生成组合"**，不是查数据：生成**日期骨架**（`days` 表 × `dept` 表 → 每个部门 × 每一天），再 LEFT JOIN 真实数据，让"没数据的日期"也能出现在报表里（补 0）；用 `digits`(0~9) 自交叉两次枚举 0~99；小表 × 小表快速造测试数据。
> 关键词：CROSS JOIN 的价值在于**做骨架**，用完之后通常紧跟一个 `LEFT JOIN` 把真实数据填进去。

---

## 八、全外连接 FULL OUTER JOIN

> [!failure] MySQL 直接写 FULL OUTER JOIN 会报错
> 报错是 `ERROR 1064 (42000): You have an error in your SQL syntax ... near 'FULL OUTER JOIN emp e ON ...'`。
> `FULL OUTER JOIN` 是 **SQL 标准**写法，PostgreSQL / Oracle / SQL Server 都支持，**MySQL、MariaDB 不支持**，只能靠 `UNION` 把 LEFT 和 RIGHT 拼起来。

```sql
-- 模拟 FULL OUTER JOIN：左边全要 ∪ 右边全要
SELECT d.dept_id, d.dept_name, e.emp_id, e.emp_name
FROM dept d LEFT JOIN emp e ON d.dept_id = e.dept_id

UNION

SELECT d.dept_id, d.dept_name, e.emp_id, e.emp_name
FROM dept d RIGHT JOIN emp e ON d.dept_id = e.dept_id;
```

结果（**6 行** = 4 个匹配 + 孙七 + 财务部）：

```
dept_id | dept_name | emp_id | emp_name
--------+-----------+--------+---------
   1001 | 研发部    |      1 | 张三
   1001 | 研发部    |      2 | 李四
   1002 | 销售部    |      3 | 王五
   1002 | 销售部    |      4 | 赵六
   1003 | 财务部    |   NULL | NULL      <-- LEFT 部分带进来的
   NULL | NULL      |      5 | 孙七      <-- RIGHT 部分带进来的
```

> [!note] UNION 会去重，UNION ALL 不会
> `UNION` 按所有列比对去重（要建临时表或排序，**慢**），`UNION ALL` 直接追加（**快**）。
> 模拟 FULL JOIN 时**必须用 `UNION`**：那 4 个匹配行在 LEFT 和 RIGHT 里各出现一次，用 `UNION ALL` 会得到 4 + 4 + 2 = 10 行、重复 4 行；反过来，**能确认两个结果集无交集时一律用 `UNION ALL`**。

---

## 九、自连接 SELF JOIN

场景：员工表里有个 `manager_id` 指向**同一张表**的上级，要查"每个员工及其经理姓名"，就得让这张表**自己跟自己连**。

```sql
CREATE TABLE emp_mgr (
    emp_id     INT PRIMARY KEY,
    emp_name   VARCHAR(20),
    manager_id INT             -- 指向同表的 emp_id，老板为 NULL
);

INSERT INTO emp_mgr VALUES (1, '张总', NULL),
                           (2, '张三', 1),
                           (3, '李四', 1),
                           (4, '王五', 2),
                           (5, '赵六', 2);
```

原始数据：

```
emp_id | emp_name | manager_id
-------+----------+-----------
     1 | 张总     |       NULL
     2 | 张三     |          1
     3 | 李四     |          1
     4 | 王五     |          2
     5 | 赵六     |          2
```

```sql
SELECT e.emp_name AS 员工, m.emp_name AS 经理
FROM emp_mgr e
LEFT JOIN emp_mgr m              -- 同一张表连两次，必须起两个不同的别名
       ON e.manager_id = m.emp_id
ORDER BY e.emp_id;
```

结果（**必须用 LEFT JOIN**，否则老板张总就消失了）：

```
员工   | 经理
-------+------
张总   | NULL     <-- 老板没有上级，用 LEFT JOIN 才留得下来
张三   | 张总
李四   | 张总
王五   | 张三
赵六   | 张三
```

> [!danger] 自连接别名绝对不能省
> 不起别名直接连会报 `ERROR 1066 (42000): Not unique table/alias: 'emp_mgr'`——同一张表在 `FROM` 里出现两次，MySQL 无法区分"哪个是员工、哪个是经理"，必须靠别名（这里是 `e` 和 `m`）把它**变成两张逻辑表**。
> 另外两张表有同名列时会报 `ERROR 1052 Column ... is ambiguous`，所以自连接一定要 `SELECT e.xxx, m.xxx` 显式列名 + `AS` 起别名。

> [!tip] 自连接的三种典型场景
> 1. **层级结构**：员工-经理、分类-父分类、评论-父评论（本节例子）
> 2. **同表行间比较**：查"比本部门平均工资高的人"、和上一条记录比
> 3. **成对匹配**：找"同部门的任意两人组合"，记得加 `a.emp_id < b.emp_id` 避免自己配自己、也避免重复配对

---

## 十、多表连接

再加一张 `project` 表（项目也归属部门），要查"**员工 → 部门 → 项目**"三张表串起来的信息。

```sql
CREATE TABLE project (
    proj_id   INT PRIMARY KEY,
    proj_name VARCHAR(20),
    dept_id   INT
);

INSERT INTO project VALUES (201, '数据中台', 1001),
                           (202, 'CRM系统', 1002),
                           (203, '预算系统', 1003);   -- 财务部的项目，但财务部没人
```

```sql
SELECT e.emp_name, d.dept_name, p.proj_name
FROM emp e
JOIN dept    d ON e.dept_id = d.dept_id
JOIN project p ON p.dept_id = d.dept_id
ORDER BY e.emp_id;
```

结果（**4 行**）：

```
emp_name | dept_name | proj_name
---------+-----------+---------
张三     | 研发部    | 数据中台
李四     | 研发部    | 数据中台
王五     | 销售部    | CRM系统
赵六     | 销售部    | CRM系统
```

**少了谁**：孙七（`dept_id IS NULL`，第一个 JOIN 就被内连接淘汰）；财务部和它的"预算系统"（没有员工能连上来）。

> [!info] 连接就是一条链
> - **写法**：`FROM a JOIN b ON ... JOIN c ON ...`，一个 JOIN 紧跟属于它的 `ON`
> - **顺序**：`ON` 只能引用**它前面已经出现过**的表；逻辑上 a 和 b 先连成中间结果，再拿这个结果去连 c
> - **物理顺序**：优化器**会重排**连接顺序（`EXPLAIN` 里表出现的顺序常常和写法不同），你只管把条件写清楚
>
> **混用内外连接要极其小心**：`a LEFT JOIN b ON ... JOIN c ON ...` 里第二个内连接会**把左连接补出来的 NULL 行又过滤掉**，等于白写。多表混合时要么全用 LEFT JOIN，要么把内连接写成 `LEFT JOIN ... AND` 的形式。

> [!question] 三张表以上，怎么判断该谁连谁？
> 找**中间表**：能同时连上两边的表。本节里 `dept` 就是——`emp.dept_id → dept.dept_id`、`project.dept_id → dept.dept_id`，两条边都落在 `dept` 上。
> 两表之间**没有直接关联字段**时（比如员工和项目之间没有通路），需要一张**关联表**（`emp_project(emp_id, proj_id)`）来搭桥，那也是三表连接的经典形态。

---

## 十一、`ON` vs `USING`

两表的关联字段**恰好同名**（都叫 `dept_id`）时，可以用 `USING` 少写一点。

```sql
-- 写法一：ON
SELECT * FROM dept d JOIN emp e ON d.dept_id = e.dept_id;

-- 写法二：USING，括号里只写一次字段名
SELECT * FROM dept d JOIN emp e USING (dept_id);
```

差别就在**结果集的列**上：

```
-- ON 的 SELECT *（6 列，dept_id 出现两次）
dept_id | dept_name | emp_id | emp_name | dept_id | salary

-- USING 的 SELECT *（5 列，dept_id 只出现一次）
dept_id | dept_name | emp_id | emp_name | salary
```

| 对比项 | `ON d.dept_id = e.dept_id` | `USING (dept_id)` |
| --- | --- | --- |
| 字段名要求 | 可以不同名，任意表达式都行 | **必须两表同名字段** |
| 结果里的关联列 | **出现两列**（`d.dept_id`、`e.dept_id`） | **只出现一列**（合并成一个） |
| 外连接时该列的值 | 两列各填各的（可能是 NULL） | 自动取有值的那个（LEFT JOIN 时取左表值） |
| 连接条件范围 | 支持非等值（`>`、`BETWEEN`） | **只支持等值** |
| 可读性 | 显式、通用 | 简洁，字段多时括号很长 |

> [!tip] 什么时候用 USING
> 两表字段同名且做等值连接（最常见的 `xxx_id` 场景）时用它最省事，尤其是想 `SELECT *` 又要**避免重复列**（`INSERT INTO ... SELECT`、导出结果集）。
> 复杂查询里建议**还是写 `ON`**：一眼看出用的是哪两张表的哪个字段，`USING` 只写一个名字，得靠猜。

> [!note] 还有个更"自动"的 NATURAL JOIN
> `FROM dept NATURAL JOIN emp` 会自动把**所有同名列**当连接条件。听起来省事，实际**没人敢用**——改表时加一个同名字段（比如两边都加个 `remark`），连接条件会**静默变化**，结果就错了。**生产代码禁用 `NATURAL JOIN`。**

---

## 十二、性能：连接是怎么执行的

| 算法 | 触发条件 | 一句话原理 | 版本 |
| --- | --- | --- | --- |
| `Nested-Loop Join`（NLJ） | 被驱动表**关联字段有索引** | 驱动表每读一行，就去被驱动表**走索引**找匹配 | 一直有，最快 |
| `Block Nested-Loop`（BNL） | 被驱动表**没索引** | 把驱动表数据读进 `join_buffer`，**整块**去扫被驱动表 | 8.0.20 起被 Hash Join 取代 |
| `Hash Join` | 等值连接 + 无可用索引 | 给小表建**哈希表**，大表逐行探测，命中即匹配 | **8.0.18+ 自动启用** |

> [!tip] 铁律：关联字段必须建索引
> `ON a.dept_id = b.dept_id` 里，**被驱动表的 `dept_id` 上一定要有索引**：有索引走 `NLJ`，每次查找近似 O(log n)，几十万行也很快；没索引只能 `BNL` / `Hash Join`，被驱动表**反复全表扫描**，数据量一大就是断崖式变慢。
> 做法就是给被驱动表（本例的 `emp`）加索引：`ALTER TABLE emp ADD INDEX idx_dept_id (dept_id);`
> 注意：**物理外键会自动创建索引**，有外键的表通常不用担心；**逻辑外键（只写字段不加约束）必须自己建**，这是最常见的遗漏。

> [!info] 驱动表：小表驱动大表
> "驱动表"是外层循环那张表，被驱动表是被反复查的那张。**小表当驱动表** → 外层行数少 → 内层查找次数少 → 总代价低。
> 优化器一般会自动选，**不用手写** `STRAIGHT_JOIN` 强制顺序；但**统计信息过期**时它会选错，此时可以 `ANALYZE TABLE emp;` 更新统计信息。

```sql
-- 看执行计划：重点看 type 和 rows 两列
EXPLAIN SELECT e.emp_name, d.dept_name
FROM emp e JOIN dept d ON e.dept_id = d.dept_id;
```

`type` 一列的好坏排序（JOIN 里被驱动表最好是 `ref` / `eq_ref`）：

| `type` | 含义 | 好坏 |
| --- | --- | --- |
| `const` / `eq_ref` | 主键或唯一索引定位（JOIN 最佳状态） | 最好 |
| `ref` | 走**普通索引**等值匹配（JOIN 常见状态） | 好 |
| `range` / `index` | 范围扫描 / 扫整棵索引树 | 一般 |
| **`ALL`** | **全表扫描**，JOIN 里出现就要警惕 | ==最差== |

> [!warning] 连接字段的类型 / 字符集必须完全一致
> 不一致时 MySQL 要**隐式类型转换**，字段一旦被函数包裹，**索引直接失效**：
> - `INT` 对 `VARCHAR`（`emp.dept_id = d.dept_code`）→ 字符串被转成数字，索引失效，退化为全表扫描
> - `utf8mb4` 对 `utf8`（两表字段字符集不同）→ 走不了索引，`EXPLAIN` 里 `type=ALL`
> - `BIGINT` 对 `INT`、`SIGNED` 对 `UNSIGNED` → 隐式转换，同样可能失效，外键还会直接建不上
>
> 建表时就对齐：**类型、长度、字符集、排序规则全一致**——这既是 [[外键约束]] 能建上的前提，也是 JOIN 快的隐形条件。

---

## 十三、各连接一句话速查表

| 连接 | 关键字 | 保留哪些行 | 典型用途 | 示例行数 |
| --- | --- | --- | --- | --- |
| **内连接** | `JOIN` / `INNER JOIN` | 两边都匹配上的（A ∩ B） | 常规多表查询 | 4 行 |
| **左外连接** | `LEFT JOIN` | 左表全部 + 右表匹配的 | 主表列表、**统计含 0 的分组**、**反连接找缺失** | 5 行 |
| **右外连接** | `RIGHT JOIN` | 右表全部 + 左表匹配的 | 可用 LEFT JOIN 改写，**规范里通常禁用** | 5 行 |
| **全外连接** | `FULL OUTER JOIN` | 两表全部的并集（A ∪ B） | 找两表**全部差异**；**MySQL 不支持**，用 `UNION` 模拟 | 6 行 |
| **交叉连接** | `CROSS JOIN` | 笛卡尔积，两两组合 | 生成**日期/序号骨架**、造测试数据 | 15 行 |
| **自连接** | `JOIN` 同一张表两次 | 看用内还是外连接 | **层级结构**（员工-经理）、同表行间比较 | 5 行 |

> [!success] 选择连接的决策树
> 1. 只要**有对应关系**的数据 → `INNER JOIN`
> 2. 要**保住某张表的全部行** → 那张表放左边，`LEFT JOIN`
> 3. 统计分组**可能为空**（部门没人、商品没销量）→ `LEFT JOIN` + `COUNT(右表列)`
> 4. 要**找差异 / 找缺失**（没部门的员工、没下单的用户）→ `LEFT JOIN` + `WHERE 右表主键 IS NULL`
> 5. 要**两边的差异全都要** → 模拟 `FULL OUTER JOIN`
> 6. 要**表自己跟自己比** → 自连接 + 两个别名

> [!failure] JOIN 报错速查
> - `ERROR 1064` → 写了 MySQL 不支持的 `FULL OUTER JOIN`，改用 `LEFT JOIN ... UNION ... RIGHT JOIN`
> - `ERROR 1066 Not unique table/alias` → 自连接没给同一张表起两个别名
> - `ERROR 1054 Unknown column` → `ON` 里引用了还没出现的表，或字段名/别名打错
> - `ERROR 1052 Column ... is ambiguous` → 两张表有同名列，`SELECT` 时没加表前缀
> - **结果行数暴涨** → 忘了写 `ON` 或 `WHERE`，产生了笛卡尔积

---

> [!quote] 一句话记忆
> **内连接只留匹配上的；LEFT JOIN 保左表全员（右表缺的补 NULL）；RIGHT JOIN 保右表全员（能翻成 LEFT JOIN）；ON 管连接条件、WHERE 管连完的过滤——右表条件写进 WHERE，LEFT JOIN 就退化成内连接。**

---

## 相关笔记

- [[From]] —— JOIN 写在 FROM 子句里，决定数据来源
- [[Where]] —— 连接完成之后的过滤，第六章的坑就在这里
- [[Select]] —— 连接后取哪些列，用表别名限定同名字段
- [[计算机类/数据库/Mysql/DML/Group By]] —— JOIN 之后按维度分组，配合 `COUNT(右表列)` 统计
- [[外键约束]] —— `dept_id` 的参照完整性，也是 JOIN 的天然索引
