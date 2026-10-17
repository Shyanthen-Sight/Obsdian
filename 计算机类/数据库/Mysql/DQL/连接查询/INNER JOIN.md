# INNER JOIN —— 内连接

> [!abstract] 一句话
> 内连接只保留==**两表都匹配上的行**==（交集 A ∩ B）；它的逻辑本质是==**先笛卡尔积、再按 `ON` 条件筛**==，所以匹配不上的行一行都留不下——这正是它和外连接唯一的区别。

> [!info] 与 DML 版的分工
> 上层的 [[Join|DML/Join]] 把**六种连接**放在一篇里横向对比。
> 本篇是**内连接的纵向深入**：只讲内连接，聚焦==**匹配的判定、逗号写法的等价性、多表链式连接、等值/非等值连接、索引与性能**==。六种连接各有一篇单讲，配合 [[LEFT JOIN]]、[[RIGHT JOIN]]、[[FULL OUTER JOIN]]、[[CROSS JOIN]]、[[SELF JOIN]] 一起看。

---

> [!example] 本篇示例数据
> 与同目录 `INNER JOIN` / `LEFT JOIN` / `RIGHT JOIN` / `FULL OUTER JOIN` / `CROSS JOIN` 各篇**共用同一套 `dept` / `emp` 表**。
> 数据里故意留了两处"不匹配"：**财务部没人**、**孙七没部门**——它们是每种连接的照妖镜。

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

---

## 一、三种等价写法

```sql
-- 写法 1：标准显式（推荐）
SELECT e.emp_name, e.salary, d.dept_name
FROM emp e
INNER JOIN dept d ON e.dept_id = d.dept_id;

-- 写法 2：INNER 可省略 —— JOIN 默认就是 INNER JOIN
SELECT e.emp_name, e.salary, d.dept_name
FROM emp e
JOIN dept d ON e.dept_id = d.dept_id;

-- 写法 3：隐式内连接 —— 逗号列出多表，连接条件写在 WHERE
SELECT e.emp_name, e.salary, d.dept_name
FROM emp e, dept d
WHERE e.dept_id = d.dept_id;
```

三种写法结果完全相同（**4 行**）：

```
emp_name | salary | dept_name
---------+--------+----------
张三     |  12000 | 研发部
李四     |  15000 | 研发部
王五     |   9000 | 销售部
赵六     |   8500 | 销售部
```

> [!tip] 结果一样，为什么还推荐显式 `JOIN ... ON`
> 差别不在性能（优化器给的执行计划通常一样），而在==**可读性与出错概率**==：`ON` 里只放连接条件、`WHERE` 里只放过滤条件，职责分离；而逗号写法一旦**漏写 WHERE**，就会**静默**变成笛卡尔积，行数暴涨还不报错。

| 对比 | 逗号 + WHERE | `JOIN ... ON` |
| --- | --- | --- |
| 连接条件位置 | 混在 `WHERE` 里 | 独立的 `ON` |
| 漏写连接条件 | 静默笛卡尔积 | 语法上几乎不可能漏（`JOIN` 必须跟 `ON`/`USING`） |
| 外连接 | ❌ 表示不了 | ✅ `LEFT/RIGHT JOIN` 原生支持 |
| 多表 | 条件越堆越长 | 一个 `JOIN` 跟一个 `ON`，链式清晰 |

---

## 二、"匹配"的判定：NULL 永远不匹配

内连接第一件要厘清的事：**什么算"匹配上"？**——`ON` 的条件求值为 `TRUE` 才算。

```sql
-- 孙七的 dept_id 是 NULL
SELECT e.emp_name, d.dept_name
FROM emp e
JOIN dept d ON e.dept_id = d.dept_id
WHERE e.emp_name = '孙七';
-- Empty set (0.00 sec)
```

> [!important] 为什么孙七一定出不来
> 对孙七而言，`ON e.dept_id = d.dept_id` 逐行算的是 `NULL = 1001`、`NULL = 1002`、`NULL = 1003`——按三值逻辑，**结果全是 `UNKNOWN`（既不是 `FALSE` 也不是 `TRUE`）**。
> 内连接只接受 `TRUE`，所以这 3 个组合全部被丢弃。
> ==**结论：内连接会自动"吃掉"外键为 NULL 的行，这是三值逻辑的必然，不是 bug。**==

同理，`dept` 里的**财务部**（`1003`）自身不为 NULL，但没有任何 `emp.dept_id` 等于它，也匹配不上 → 消失。

> [!note] 内连接是"两端同时丢"
> ```
>     dept 独有          dept ∩ emp           emp 独有
>    ┌───────────┐   ┌──────────────────┐   ┌───────────┐
>    │  财务部    │   │ 研发部 ← 张三、李四│   │   孙七     │
>    │  (1003)   │   │ 销售部 ← 王五、赵六│   │(dept=NULL)│
>    └───────────┘   └──────────────────┘   └───────────┘
>                     ↑ INNER JOIN 只要这一块
> ```
> 左独有（财务部）丢、右独有（孙七）丢，**只留中间的交集**。

---

## 三、内连接 = 笛卡尔积 + 过滤

这是理解连接最重要的一句话。逻辑上，`JOIN` 就是**先把两表两两组合**，再按 `ON` 把不成立的组合删掉：

```sql
-- 第一步：两表组合，3 × 5 = 15 行（笛卡尔积）
SELECT COUNT(*) FROM emp, dept;                 -- 15

-- 第二步：加连接条件筛到 4 行
SELECT COUNT(*) FROM emp e JOIN dept d ON e.dept_id = d.dept_id;   -- 4
```

15 行里，只有 4 行的 `e.dept_id = d.dept_id` 成立：

```
组合判定（节选）
emp     | dept   | e.dept_id = d.dept_id ?
--------+--------+-----------------------
张三    | 研发部 | 1001 = 1001 → TRUE  ✅ 保留
张三    | 销售部 | 1001 = 1002 → FALSE ❌
张三    | 财务部 | 1001 = 1003 → FALSE ❌
...
孙七    | 研发部 | NULL = 1001 → UNKNOWN ❌
孙七    | 销售部 | NULL = 1002 → UNKNOWN ❌
孙七    | 财务部 | NULL = 1003 → UNKNOWN ❌
```

> [!warning] 这是"逻辑模型"，不是"物理执行"
> 说"先笛卡尔积再筛"是为了**帮你理解语义**。真实执行时优化器**不会**真造出 15 行的中间结果（那太慢），而是走 ==**索引嵌套循环（NLJ）**== 等算法边连边匹配，详见第七章。

---

## 四、多表连接：一条链

连接可以把三张、四张表串起来。再补一张 `project` 表（项目也归属部门）：

```sql
CREATE TABLE project (
    proj_id   INT PRIMARY KEY,
    proj_name VARCHAR(20),
    dept_id   INT
);
INSERT INTO project VALUES (201, '数据中台', 1001),
                           (202, 'CRM系统', 1002),
                           (203, '预算系统', 1003);
```

查"员工 → 部门 → 项目"：

```sql
SELECT e.emp_name, d.dept_name, p.proj_name
FROM emp  e
JOIN dept d ON e.dept_id = d.dept_id
JOIN project p ON p.dept_id = d.dept_id;
```

```
emp_name | dept_name | proj_name
---------+-----------+---------
张三     | 研发部    | 数据中台
李四     | 研发部    | 数据中台
王五     | 销售部    | CRM系统
赵六     | 销售部    | CRM系统
```

**少了谁**：孙七（`dept_id IS NULL`，第一个 JOIN 就被淘汰）；财务部和它的"预算系统"（没人能连上来）。

> [!tip] 连接顺序怎么定：找"中间表"
> 能同时连上两边的表就是中间表——这里 `dept` 既是 `emp` 的去处、又是 `project` 的去处，两条边都落在它身上。
> 两表之间**没有直接关联字段**时（如员工 ↔ 项目），就需要一张**关联表**（`emp_project(emp_id, proj_id)`）搭桥。

> [!note] `ON` 只能引用"前面已出现的表"
> `... JOIN b ON ... JOIN c ON ...` 里，`c` 的 `ON` 只能引用 `a`、`b`；逻辑上先连出 `a⋈b` 的中间结果，再拿它去连 `c`。
> 但**物理顺序优化器会重排**，`EXPLAIN` 里表的先后常和写法不同——你只管把条件写对。

---

## 五、连接条件不只"相等"：等值 / 非等值 / USING

`ON` 里写的是**任意布尔表达式**，不限于等号。

### 5.1 非等值连接

```sql
CREATE TABLE salary_grade (
    grade VARCHAR(5),
    lo    DECIMAL(10,2),
    hi    DECIMAL(10,2)      -- 区间 [lo, hi)
);
INSERT INTO salary_grade VALUES
('A', 10000, 99999),
('B',  8000, 10000),
('C',     0,  8000);
```

给每个员工按工资套等级：

```sql
SELECT e.emp_name, e.salary, g.grade
FROM emp e
JOIN salary_grade g
  ON e.salary >= g.lo AND e.salary < g.hi
ORDER BY e.salary DESC;
```

```
emp_name | salary | grade
---------+--------+------
李四     |  15000 | A
张三     |  12000 | A
王五     |   9000 | B
赵六     |   8500 | B
孙七     |   7000 | C
```

注意这次**孙七也进来了**——因为他连的是 `salary_grade`，跟 `dept_id` 是不是 NULL 无关。

> [!question] 非等值连接会更快还是更慢？
> 更慢。等值连接能**用索引**（B-Tree 直接定位），而 `>=`/`<` 这种区间一般只能**范围扫描**甚至全表扫描。
> 区间还能"重叠"导致**一行匹配多行**：若 `[0,10000)` 和 `[8000,20000)` 同时存在，工资 9000 的人会**匹配两条等级**、结果里出现两次——设计区间表务必保证==**互斥且不重不漏**==。

### 5.2 `USING` 与 `NATURAL JOIN`

两表关联字段**恰好同名**时的简写：

```sql
-- ON：结果里 dept_id 出现两次
FROM dept d JOIN emp e ON d.dept_id = e.dept_id;

-- USING：只写一次字段名，结果里 dept_id 合并成一列
FROM dept d JOIN emp e USING (dept_id);
```

> [!danger] 生产代码禁用 `NATURAL JOIN`
> `FROM dept NATURAL JOIN emp` 会自动把**所有同名列**都拿去当连接条件。某天有人给两张表都加一个 `remark` 列，连接条件就**静默变化**、结果直接错。
> 完整对比见 [[Join]] 第十一章。

---

## 六、常见错误合集

> [!failure] 漏写连接条件 → 静默笛卡尔积
> ```sql
> SELECT * FROM emp e JOIN dept d;   -- ERROR 1064：JOIN 必须跟 ON/USING
> SELECT * FROM emp e, dept d;       -- 合法！但结果 15 行，不是你想要的
> ```
> 逗号写法漏 `WHERE` 不报错、结果错，是线上事故的常客。

> [!failure] `Column ... is ambiguous`（ERROR 1052）
> ```sql
> SELECT dept_id FROM emp e JOIN dept d ON e.dept_id = d.dept_id;
> -- ERROR 1052: Column 'dept_id' in field list is ambiguous
> ```
> 两张表都有 `dept_id`，必须用 `e.dept_id` / `d.dept_id` 限定。

> [!failure] 把"过滤条件"塞进 `ON`（内连接里结果无害，但别养成习惯）
> 内连接中 `ON` 与 `WHERE` 写过滤**结果一样**（反正不匹配的都丢），但换到 `LEFT JOIN` 就是灾难。**统一规范：连接条件写 `ON`，过滤条件写 `WHERE`。**

> [!failure] 关联字段类型/字符集不一致，索引失效
> `emp.dept_id`(INT) 对上 `dept.dept_code`(VARCHAR) → 隐式类型转换 → 字段被函数包裹 → **索引失效、退化成全表扫描**。建表时就要对齐**类型、长度、字符集、排序规则**。

---

## 七、性能：连接到底怎么执行

| 算法 | 触发条件 | 一句话原理 |
| --- | --- | --- |
| Nested-Loop Join（NLJ） | 被驱动表**关联字段有索引** | 驱动表每读一行，去被驱动表**走索引**找匹配 |
| Block NLJ（BNL） | 被驱动表**没索引** | 把驱动表塞进 `join_buffer`，**整块**扫被驱动表 |
| Hash Join | 等值连接 + 无可用索引 | 给小表建**哈希表**，大表逐行探测，**8.0.18+ 自动启用** |

```sql
-- 看执行计划
EXPLAIN SELECT e.emp_name, d.dept_name
FROM emp e JOIN dept d ON e.dept_id = d.dept_id;
```

> [!tip] 铁律：**被驱动表的关联字段必须建索引**
> `ON a.dept_id = b.dept_id` 里给被驱动表的连接列加索引：`ALTER TABLE emp ADD INDEX idx_dept_id (dept_id);`
> 有索引走 NLJ，每次查找 ≈ O(log n)；没索引只能 BNL / Hash Join，数据一大就是断崖式变慢。
> **物理外键会自动建索引；逻辑外键（只写字段不加约束）必须自己建**——这是最常见的遗漏。

> [!info] 小表驱动大表
> "驱动表"是外层循环那张。**小表当驱动表** → 外层行数少 → 内层查找次数少 → 总代价低。
> 优化器一般会自动选，**不要手写** `STRAIGHT_JOIN`；统计信息过期时才手动 `ANALYZE TABLE` 纠正。

`EXPLAIN` 里 `type` 一列（被驱动表最好 `ref` / `eq_ref`）：

| `type` | 含义 | 好坏 |
| --- | --- | --- |
| `const` / `eq_ref` | 主键/唯一索引定位 | 最好 |
| `ref` | 普通索引等值匹配（JOIN 常见） | 好 |
| `range` / `index` | 范围扫描 / 扫整棵索引树 | 一般 |
| ==`ALL`== | ==全表扫描== | ==最差== |

---

## 八、速查表

| 需求             | 写法                                   |
| -------------- | ------------------------------------ |
| 两表都有对应关系的数据    | `INNER JOIN` / `JOIN` / 逗号 + `WHERE` |
| 三表串联           | `JOIN b ON ... JOIN c ON ...`        |
| 关联字段同名         | `USING (字段)`                         |
| 区间/范围匹配（非等值）   | `ON a.x >= b.lo AND a.x < b.hi`      |
| 结果里"没对应关系"的行丢了 | 正常——那是外连接该做的事                        |

> [!question] 自测三连
> 1. `emp JOIN dept` 的结果是几行？为什么既不是 5 行、也不是 15 行？
> 2. 孙七为什么在内连接里一定查不到？
> 3. 想让"没部门的员工"也出现，应该把 `JOIN` 改成什么？

---

> [!quote] 一句话记忆
> **内连接只留两表都匹配上的行（A ∩ B），NULL 永不匹配；逻辑上等于"笛卡尔积 + `ON` 筛选"；要保住某张表的全部行，那就不是内连接了——得用外连接。**

---

## 相关笔记

- [[LEFT JOIN]] —— 保住左表全部行，解释内连接解释不了的"缺失行"
- [[RIGHT JOIN]] —— 保住右表全部行，内连接的镜像
- [[FULL OUTER JOIN]] —— 两表并集，MySQL 要用 `UNION` 模拟
- [[CROSS JOIN]] —— 内连接的"前身"：纯笛卡尔积
- [[SELF JOIN]] —— 同一张表自己连自己
- [[Join]] —— 六种连接的横向总览
- [[计算机类/数据库/Mysql/数据库概念/笛卡尔积]] —— 连接背后的数学基础
- [[Where]] —— 三值逻辑与 NULL 判定
