# FULL OUTER JOIN —— 全外连接

> [!abstract] 一句话
> `FULL OUTER JOIN` 保留==**两表的并集（A ∪ B）**==：匹配上的拼在一起，各自没匹配上的也保留、对面补 `NULL`。
> **MySQL / MariaDB 不支持它**，只能靠 ==**`LEFT JOIN` `UNION` `RIGHT JOIN`**== 来模拟。

> [!info] 与 DML 版的分工
> [[Join|DML/Join]] 已给出"用 `UNION` 模拟"的基本写法。本篇专讲它==**为什么不支持、`UNION` vs `UNION ALL` 的取舍、找两表全部差异、以及三表全外连接**==。

---

> [!example] 本篇示例数据
> 与同目录 `INNER JOIN` / `LEFT JOIN` / `RIGHT JOIN` / `CROSS JOIN` 各篇**共用同一套 `dept` / `emp` 表**。
> 全外连接要的就是**两边的独有行都出现**：**财务部**（左独有）与**孙七**（右独有）一个都不能少。

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
-- dept（3 行）                          -- emp（5 行）
dept_id | dept_name                    emp_id | emp_name | dept_id | salary
--------+----------                    -------+----------+---------+--------
   1001 | 研发部                            1 | 张三     |    1001 |  12000
   1002 | 销售部                            2 | 李四     |    1001 |  15000
   1003 | 财务部  <-- 没人认领               3 | 王五     |    1002 |   9000
                                          4 | 赵六     |    1002 |   8500
                                          5 | 孙七     |    NULL |   7000  <-- 没部门
```

---

## 一、MySQL 里直接写会报错

```sql
SELECT *
FROM dept d
FULL OUTER JOIN emp e ON d.dept_id = e.dept_id;
```

```
ERROR 1064 (42000): You have an error in your SQL syntax;
check the manual ... near 'FULL OUTER JOIN emp e ON ...' at line 1
```

> [!failure] `FULL OUTER JOIN` 是 SQL 标准，但 MySQL 没实现
> 它是标准 SQL 的连接类型，**PostgreSQL / Oracle / SQL Server 都支持**，**MySQL、MariaDB 不支持**。

各数据库支持情况：

| 数据库 | `FULL OUTER JOIN` | 备注 |
| --- | --- | --- |
| PostgreSQL | ✅ | 原生 |
| Oracle | ✅ | 原生 |
| SQL Server | ✅ | 原生 |
| **MySQL / MariaDB** | ❌ | 报 `ERROR 1064`，需 `UNION` 模拟 |
| SQLite | ✅（3.39+） | 较新版本才支持 |

---

## 二、模拟写法：`LEFT UNION RIGHT`

```sql
-- 模拟 FULL OUTER JOIN：左边全要 ∪ 右边全要
SELECT d.dept_id, d.dept_name, e.emp_id, e.emp_name
FROM dept d
LEFT JOIN emp e ON d.dept_id = e.dept_id

UNION

SELECT d.dept_id, d.dept_name, e.emp_id, e.emp_name
FROM dept d
RIGHT JOIN emp e ON d.dept_id = e.dept_id;
```

结果（**6 行** = 4 个匹配 + 财务部 + 孙七）：

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

> [!tip] 为什么是 `LEFT ∪ RIGHT` 就能凑出"并集"
> - `LEFT JOIN` 已经给了"左表全 + 匹配上的"；
> - `RIGHT JOIN` 补上了"右表独有的"；
> - 两者取并集（`UNION`），匹配上的部分重复，去重后正好 = **全部匹配 + 左独有 + 右独有**。

用区域图看这 6 行：

```
     dept 独有          dept ∩ emp           emp 独有
   ┌───────────┐   ┌──────────────────┐   ┌───────────┐
   │  财务部    │   │ 研发部 ← 张三、李四│   │   孙七     │
   │  (1003)   │   │ 销售部 ← 王五、赵六│   │(dept=NULL)│
   └───────────┘   └──────────────────┘   └───────────┘
       1 行                 4 行                1 行          → 1 + 4 + 1 = 6
```

---

## 三、为什么必须用 `UNION`，不能用 `UNION ALL`

```sql
-- 用 UNION ALL：4 个匹配行在 LEFT、RIGHT 里各出现一次 → 重复
--   4（LEFT 里的匹配）+ 1（财务部）+ 4（RIGHT 里的匹配）+ 1（孙七） = 10 行
```

| | `UNION` | `UNION ALL` |
| --- | --- | --- |
| 是否去重 | ✅ 按**所有列**比对去重 | ❌ 直接追加 |
| 代价 | 建临时表 / 排序，**慢** | 快 |
| 模拟 `FULL JOIN` 时的结果 | 6 行（正确） | 10 行（重复 4 行） |

> [!important] 模拟全外连接**必须用 `UNION`**
> 那 4 个匹配行在 `LEFT` 和 `RIGHT` 两个结果里都出现，`UNION ALL` 会原样堆叠成 4 + 1 + 4 + 1 = **10 行**、重复 4 行。
> 反过来记住另一半：**能确认两个结果集无交集时，一律用 `UNION ALL`** 更快。

> [!note] `UNION` 去重的判定：整行所有列相同才算重复
> 两个分支的 `SELECT` 列数必须相同、对应列类型要兼容。如果只想按"主键"去重，直接用 `UNION` 即可（主键唯一时整行必然一致）。

---

## 四、`FULL JOIN` 的典型用途：找两表全部差异

全外连接最常被拿来"对账"——找出**只在左边、或只在右边**的记录：

```sql
-- 只看"没配上"的行（两边的差异）
SELECT d.dept_id, d.dept_name, e.emp_id, e.emp_name
FROM (
    SELECT d.dept_id, d.dept_name, e.emp_id, e.emp_name
    FROM dept d LEFT JOIN emp e ON d.dept_id = e.dept_id
    UNION
    SELECT d.dept_id, d.dept_name, e.emp_id, e.emp_name
    FROM dept d RIGHT JOIN emp e ON d.dept_id = e.dept_id
) t
WHERE t.dept_id IS NULL OR t.emp_id IS NULL;
```

结果（**2 行**）：

```
dept_id | dept_name | emp_id | emp_name
--------+-----------+--------+---------
   1003 | 财务部    |   NULL | NULL      <-- 只有 dept 有
   NULL | NULL      |      5 | 孙七      <-- 只有 emp 有
```

等价写法（有时更快、更易读）：

```sql
-- 左独有
SELECT d.dept_id, d.dept_name, NULL AS emp_id, NULL AS emp_name
FROM dept d LEFT JOIN emp e ON d.dept_id = e.dept_id
WHERE e.emp_id IS NULL

UNION ALL          -- 两块天然无交集，用 UNION ALL 更快

-- 右独有
SELECT NULL, NULL, e.emp_id, e.emp_name
FROM emp e LEFT JOIN dept d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;
```

> [!tip] "找差异"不一定非要全外连接
> 只要两个方向各写一个**反连接**（`LEFT JOIN ... WHERE 右表主键 IS NULL`）再 `UNION ALL`，就能拿到同样的结果，而且**天然无交集、不需要 `UNION` 的排序去重**，往往更快。

也可以用 `NOT IN` / `NOT EXISTS`：

```sql
-- 只在 dept、不在 emp 的部门
SELECT * FROM dept d WHERE NOT EXISTS (SELECT 1 FROM emp e WHERE e.dept_id = d.dept_id);
```

---

## 五、三表全外连接

三张表要做"全外"，MySQL 里得**层层嵌套**：先把 A、B 全外成中间结果，再拿它和 C 全外。诀窍是用 `COALESCE` 把连接键统一起来。

```sql
-- 三张表：dept、emp、project；先做 dept FULL OUTER emp，再与 project 全外
SELECT COALESCE(t.dept_id, p.dept_id) AS dept_id,
       t.dept_name, t.emp_name, p.proj_name
FROM (
    -- (dept FULL OUTER emp)
    SELECT d.dept_id, d.dept_name, e.emp_name
    FROM dept d LEFT JOIN emp e ON d.dept_id = e.dept_id
    UNION
    SELECT d.dept_id, d.dept_name, e.emp_name
    FROM dept d RIGHT JOIN emp e ON d.dept_id = e.dept_id
) t
LEFT JOIN project p ON p.dept_id = t.dept_id

UNION

SELECT p.dept_id, t.dept_name, t.emp_name, p.proj_name
FROM project p
LEFT JOIN (
    SELECT d.dept_id, d.dept_name, e.emp_name
    FROM dept d LEFT JOIN emp e ON d.dept_id = e.dept_id
    UNION
    SELECT d.dept_id, d.dept_name, e.emp_name
    FROM dept d RIGHT JOIN emp e ON d.dept_id = e.dept_id
) t ON p.dept_id = t.dept_id
WHERE t.dept_id IS NULL;
```

> [!warning] 三表全外又长又易错，能不用就别用
> 每多一张表，`UNION` 的分支数与嵌套层级都要翻倍；`UNION` 的每层都会排序去重，代价不小。
> **在 PostgreSQL / Oracle / SQL Server 上**，直接链式写 `A FULL JOIN B ON ... FULL JOIN C ON ...` 即可，不需要这些嵌套。
> 实务建议：先明确"我到底要哪几块数据"，很多需求拆成几个反连接反而更简单。

---

## 六、其它等价实现思路

| 思路 | 做法 | 说明 |
| --- | --- | --- |
| `LEFT UNION RIGHT` | 见第二章 | 最标准、最好懂 |
| 内连接 + 两个反连接 | `INNER JOIN` `UNION ALL` 左独有 `UNION ALL` 右独有 | 无交集时用 `UNION ALL`，**比 `UNION` 快** |
| `NOT EXISTS` / `NOT IN` | 分别找两侧缺失 | 只找差异时最直观；`NOT IN` 注意 NULL 陷阱 |

> [!note] 各数据库的"原生全外"更省事
> 支持 `FULL OUTER JOIN` 的库直接写即可，优化器会选合适算法；MySQL 里被模拟出来的全外连接，`EXPLAIN` 往往能看到 `UNION RESULT` 与临时表，性能要留意。

---

## 七、常见错误合集

> [!failure] 直接在 MySQL 写 `FULL OUTER JOIN`
> `ERROR 1064`——MySQL 根本不认识这个关键字。用 `LEFT UNION RIGHT` 模拟。

> [!failure] 用 `UNION ALL` 模拟，结果出现重复行
> 匹配行被算了两次（第二章已算：会得到 10 行而不是 6 行）。模拟全外**必须 `UNION`**。

> [!failure] `UNION` 两边的列数 / 类型不一致
> ```sql
> SELECT dept_id, dept_name FROM dept          -- 2 列
> UNION
> SELECT dept_id FROM emp;                     -- ERROR 1222: 列数不同
> ```
> 两个分支的列数必须相同、对应列类型兼容；补齐 `NULL` 占位列。

> [!failure] 拿可空列参与"去重/差异"判断
> 全外模拟结果里大量 `NULL`，用 `WHERE 列 = NULL`（永远是假）而非 `IS NULL`，会一个都筛不出来。

---

## 八、速查表

| 需求 | 写法 |
| --- | --- |
| 两表并集（含各自独有） | `LEFT JOIN ... UNION ... RIGHT JOIN ...` |
| 只要两表差异 | 上面结果再 `WHERE 左键 IS NULL OR 右键 IS NULL` |
| 只要差异且更快 | 两个反连接 `UNION ALL` |
| 去重 | 匹配唯一时可用 `UNION ALL`，否则 `UNION` |
| 三表全外 | 嵌套 `UNION` + `COALESCE` 统一键 |
| 别的数据库 | 直接写 `FULL OUTER JOIN` |

> [!question] 自测三连
> 1. 为什么 MySQL 里要用 `LEFT UNION RIGHT` 模拟全外连接？
> 2. 模拟时用 `UNION ALL` 会得到几行？为什么？
> 3. 想找出"两边所有的差异记录"，最少要几段 SQL？

---

> [!quote] 一句话记忆
> **`FULL OUTER JOIN` = 两表并集（A ∪ B），MySQL 不支持，用 `LEFT JOIN UNION RIGHT JOIN` 模拟；模拟时**必须**用去重的 `UNION`（匹配行会重复），要更快就用两个反连接 `UNION ALL`。**

---

## 相关笔记

- [[LEFT JOIN]] —— 全外连接的左半边
- [[RIGHT JOIN]] —— 全外连接的右半边
- [[INNER JOIN]] —— 只要交集，与全外的对照
- [[CROSS JOIN]] —— 笛卡尔积
- [[SELF JOIN]] —— 自连接
- [[Join]] —— 六种连接的横向总览
- [[计算机类/数据库/Mysql/sql运算符/集合运算符]] —— `UNION` / `UNION ALL` 的完整规则
- [[Where]] —— 三值逻辑与 NULL 判定
