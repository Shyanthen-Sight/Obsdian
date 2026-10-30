# LEFT JOIN —— 左外连接

> [!abstract] 一句话
> `LEFT JOIN` 保留==**左表的全部行**==：左表每行至少出场一次，右表匹配上就拼上、匹配不上就整列补 `NULL`。
> 一句话记住角色——==**谁写在左边谁说话（谁是主角，谁的行一个都不能少）。**==

> [!info] 与 DML 版的分工
> [[Join|DML/Join]] 已经把 `LEFT JOIN` 讲得较全。本篇聚焦它作为"**最常用的外连接**"的那几件事：==**补 NULL 的机制、`ON`/`WHERE` 陷阱、反连接、统计含 0 的分组、多表级联左连接**==。

---

> [!example] 本篇示例数据
> 与同目录 `INNER JOIN` / `RIGHT JOIN` / `FULL OUTER JOIN` / `CROSS JOIN` 各篇**共用同一套 `dept` / `emp` 表**。
> 两处"不匹配"是主角：**财务部没人**（只有左连接留得住）、**孙七没部门**（`emp LEFT JOIN dept` 时才露脸）。

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

## 一、语法与语义

```sql
SELECT 列...
FROM 左表 [别名]
LEFT [OUTER] JOIN 右表 [别名] ON 连接条件;
```

- `OUTER` 可省略：`LEFT JOIN` 就是 `LEFT OUTER JOIN`。
- 语义：**左表全留**；右表匹配不上 → 右表**所有列**补 `NULL`。

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

---

## 二、和 INNER JOIN 差在哪：只差"多出来的那几行"

```sql
SELECT COUNT(*) FROM dept d JOIN      emp e ON d.dept_id = e.dept_id;   -- 4（内连接）
SELECT COUNT(*) FROM dept d LEFT JOIN emp e ON d.dept_id = e.dept_id;   -- 5（左连接）
```

| | INNER JOIN | LEFT JOIN |
| --- | --- | --- |
| 两边都匹配上的行 | ✅ 保留 | ✅ 保留 |
| **左表**匹配不上的行 | ❌ 丢掉 | ✅ ==保留，右表列补 NULL== |
| **右表**匹配不上的行 | ❌ 丢掉 | ❌ 丢掉（右表不是主角） |

> [!tip] "谁在左，谁全留"
> `dept LEFT JOIN emp` 保 dept → 多出**财务部**；
> `emp LEFT JOIN dept` 保 emp → 多出**孙七**。
> 同一对表，**左右一换，留下的人就变了**——这是左连接最容易搞反的地方。

```sql
-- 反过来：保住 emp 全部行，孙七就出现了
SELECT e.emp_id, e.emp_name, d.dept_name
FROM emp e
LEFT JOIN dept d ON e.dept_id = d.dept_id
ORDER BY e.emp_id;
```

```
emp_id | emp_name | dept_name
-------+----------+----------
     1 | 张三     | 研发部
     2 | 李四     | 研发部
     3 | 王五     | 销售部
     4 | 赵六     | 销售部
     5 | 孙七     | NULL      <-- 孙七保住了，部门列补 NULL
```

---

## 三、NULL 从哪来：补 NULL 机制

> [!important] "补 NULL"不是真的写入 NULL
> 那行在 `emp` 表里根本不存在，`NULL` 是**连接引擎为占位而填的**。因此：
> - 右表**所有列**在这行都是 `NULL`（不只是 `dept_id`）；
> - `SELECT *` 时你**分不清**"这行是匹配上了但值为 NULL"还是"压根没匹配上"——判断要看**左表主键列**（左表是主角，它一定不为 NULL）。

---

## 四、`ON` 与 `WHERE`：左连接唯一必须搞懂的坑

> [!danger] 本篇最高优先级的一节
> 下面两段 SQL **只差一个关键字的位置**，结果完全不同。这是 `LEFT JOIN` 的核心考点，也是面试最爱的筛人题。

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
> **`ON` 管"怎么连"，`WHERE` 管"连完筛什么"。**LEFT JOIN 里针对**右表**的过滤条件，**写在 `ON` 里才保留左表全部行，写在 `WHERE` 里外连接就白写了**。
> 判断窍门：写下 `WHERE 右表字段 = ...` 时先问自己——"左表那些匹配不上的行，我还要不要？"要，就把条件挪到 `ON`。

> [!tip] 反过来也一样：**左表**的条件该写 `WHERE`
> 把左表的过滤条件写进 `ON` 是另一种错。想只看研发部，却写成：
> ```sql
> -- ❌ 所有部门都留下了（左表行无论条件真假都要保留，条件只让它匹配不上右表）
> FROM dept d LEFT JOIN emp e ON d.dept_id = e.dept_id AND d.dept_id = 1001;
>
> -- ✅ 只看研发部：左表自己的过滤，放心写 WHERE
> FROM dept d LEFT JOIN emp e ON d.dept_id = e.dept_id WHERE d.dept_id = 1001;
> ```
> 口诀：**保留表自己的条件写 `WHERE`；非保留表的条件必须写 `ON`，否则外连接白写。**

---

## 五、反连接：找"左表有、右表没有"的行

`LEFT JOIN` 最常见的用法之一是"找缺失"：

```sql
-- 找出"没有部门的员工"
SELECT e.emp_id, e.emp_name
FROM emp e
LEFT JOIN dept d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;      -- 右表没匹配上 → 右表主键必为 NULL
```

```
emp_id | emp_name
-------+---------
     5 | 孙七
```

> [!important] 判断键要选"右表主键"（不可为 NULL）
> 主键**不允许为 NULL**，它变成 NULL 只可能是"没匹配上"。若拿**本身可为空**的业务字段（如 `d.remark`）判断，匹配上了、但值恰好为 NULL 就会**误判成"没匹配"**。

等价写法（各有坑）：

```sql
-- NOT EXISTS：语义最清晰，NULL 安全
SELECT e.* FROM emp e
WHERE NOT EXISTS (SELECT 1 FROM dept d WHERE d.dept_id = e.dept_id);

-- NOT IN：注意 NULL 陷阱 —— 子查询若返回 NULL，整个 NOT IN 恒为 UNKNOWN、结果空
SELECT e.* FROM emp e
WHERE e.dept_id NOT IN (SELECT dept_id FROM dept);   -- dept.dept_id 是主键不会 NULL，才安全
```

---

## 六、经典应用：统计含 0 的分组

业务要"每个部门的人数，**没人也要列出来**"，内连接做不到（财务部会消失），左连接刚好：

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
   1003 | 财务部    |         0   <-- 正确！财务部保住了，人数是 0
```

> [!danger] 为什么必须写 `COUNT(e.emp_id)`，不能写 `COUNT(*)`
> `COUNT(*)` 数**结果集行数**，`COUNT(列名)` 数**该列非 NULL 的个数**。财务部那行是左连接补出来的，右表字段**整行都是 NULL**：
> - `COUNT(*)` → 这行存在，数进去，得到 **1**（错的）
> - `COUNT(e.emp_id)` → 该行 `emp_id` 为 NULL，不计入，得到 **0**（对的）
> 一句话：**外连接里统计右表数量，一律 `COUNT(右表列)`**，这个坑必踩一次。

---

## 七、多个 LEFT JOIN 级联

再补一张 `project` 表，一次连出"员工 + 部门 + 项目"：

```sql
CREATE TABLE project (
    proj_id   INT PRIMARY KEY,
    proj_name VARCHAR(20),
    dept_id   INT
);
INSERT INTO project VALUES (201, '数据中台', 1001),
                           (202, 'CRM系统', 1002),
                           (203, '预算系统', 1003);

SELECT e.emp_name, d.dept_name, p.proj_name
FROM emp  e
LEFT JOIN dept    d ON e.dept_id  = d.dept_id
LEFT JOIN project p ON p.dept_id  = d.dept_id
ORDER BY e.emp_id;
```

```
emp_name | dept_name | proj_name
---------+-----------+---------
张三     | 研发部    | 数据中台
李四     | 研发部    | 数据中台
王五     | 销售部    | CRM系统
赵六     | 销售部    | CRM系统
孙七     | NULL      | NULL      <-- 全程 LEFT，孙七一路保到底
```

> [!warning] 千万别在中间插内连接
> `emp LEFT JOIN dept ... JOIN project ...` 里那个内连接会把孙七补出的 `NULL` 行**又筛掉**，前面白 `LEFT` 了。
> 要么全用 `LEFT JOIN`，要么把内连接的过滤条件并入 `ON`，例如 `LEFT JOIN project p ON p.dept_id = d.dept_id AND p.proj_id = 201`。

---

## 八、`LEFT JOIN` 何时"变回"内连接

以下情况左连接会**退化成内连接**（左表独有行被筛掉）：

| 退化写法 | 原因 |
| --- | --- |
| `WHERE 右表.列 = 某值` | 补出的 NULL 行不满足 `=`，被删 |
| `WHERE 右表.列 > 某值` / `LIKE` 等 | 同上，NULL 参与比较恒不为真 |
| `WHERE 右表.列 IS NOT NULL` | 明确排除补出的行 |
| 连接链中出现 `INNER JOIN` | 内连接筛掉补出的 NULL 行 |

> [!tip] `WHERE 右表.列 IS NULL` 不是退化，而是**反连接**（第五章）
> 判断"退化"还是"反连接"，看条件是不是 `IS NULL`：是 → 专门找缺失；不是 → 基本是误伤。

> [!note] 反过来：怎么把内连接"升"成左连接
> 把 `JOIN` 换成 `LEFT JOIN`，再把**所有针对右表的 `WHERE` 条件挪进 `ON`**。两处都改，缺一不可。

---

## 九、性能

| 关注点 | 说明 |
| --- | --- |
| 执行方式 | 本质是"内连接 + 保底行"；NLJ / BNL / Hash Join 的取舍同 [[INNER JOIN]] |
| 索引 | **被驱动表的关联列要建索引**（`ALTER TABLE emp ADD INDEX idx_dept_id (dept_id)`） |
| 驱动表 | 小表当驱动表；左连接里"左表全留"但**未必要当驱动表**，优化器会判断 |
| 结果放大 | 一对多时**结果行数会大于左表行数**，别以为"左表全留"就等于"行数不变" |

> [!warning] 一对多会放大行数
> `dept LEFT JOIN emp` 里，有 2 名员工的研发部**输出 2 行**。所以 3 个部门得到 **5 行**，不是 3 行。
> 若只是想"每个部门一行"，必须配合 `GROUP BY` 聚合，否则左表行会按右表匹配数**成倍重复**。

---

## 十、常见错误合集

> [!failure] 把右表过滤写进 `WHERE`（最致命）
> 见第四章——`LEFT JOIN` 静默退化成内连接，多出来的行没了，还很难发现。

> [!failure] `COUNT(*)` 数错含 0 的分组
> 财务部得到 1 而不是 0，原因是数了"结果行数"而不是"非 NULL 的右表列"。用 `COUNT(e.emp_id)`。

> [!failure] 反连接用错判断列
> 拿可为空的业务字段 `IS NULL` 判断，会把"匹配上但值为 NULL"的行误判为缺失。**一律用右表主键判断。**

> [!failure] 以为左连接行数一定等于左表行数
> 一对多时会放大（3 部门 → 5 行）。要"一行一个"请 `GROUP BY`。

> [!failure] 混用 `LEFT`/`INNER` 导致补 NULL 行塌陷
> 多表级联里一个内连接就能把前面 `LEFT` 保下来的行全筛掉。

---

## 十一、速查表

| 需求 | 写法 |
| --- | --- |
| 保住左表全部行 | `左表 LEFT JOIN 右表 ON ...` |
| 保住右表全部行 | 换成 `RIGHT JOIN`，或左右调换表序 |
| 找缺失（反连接） | `LEFT JOIN ... WHERE 右表主键 IS NULL` |
| 右表条件不破坏外连接 | 写进 `ON`，别写 `WHERE` |
| 左表自身条件 | 写进 `WHERE` |
| 统计含 0 的分组 | `LEFT JOIN` + `GROUP BY` + `COUNT(右表列)` |
| 多表级联 | 一叠 `LEFT JOIN`，别插 `INNER JOIN` |

> [!question] 自测三连
> 1. `dept LEFT JOIN emp` 为什么是 5 行？多出来那行是谁？
> 2. `ON` 里写 `e.salary > 10000` 和 `WHERE` 里写，结果差多少行？为什么？
> 3. 想统计"每个部门人数、含 0 人部门"，为什么必须 `COUNT(e.emp_id)`？

---

> [!quote] 一句话记忆
> **`LEFT JOIN` 保左表全员、右表缺的补 NULL；右表条件写 `ON`、左表条件写 `WHERE`——写反了外连接就退化成内连接；统计右表数量用 `COUNT(右表列)`，找缺失用 `WHERE 右表主键 IS NULL`。**

---

## 相关笔记

- [[INNER JOIN]] —— 只留匹配上的行，左连接的对照面
- [[RIGHT JOIN]] —— 保右表全员，最常见用法是翻成左连接
- [[FULL OUTER JOIN]] —— 两表并集，`LEFT ∪ RIGHT`
- [[CROSS JOIN]] —— 笛卡尔积，左连接常配合它补骨架
- [[SELF JOIN]] —— 常常也是"左连接自己"
- [[Join]] —— 六种连接的横向总览
- [[COUNT]] —— `COUNT(*)` 与 `COUNT(列)` 的区别
- [[Where]] —— 三值逻辑与 NULL 判定
