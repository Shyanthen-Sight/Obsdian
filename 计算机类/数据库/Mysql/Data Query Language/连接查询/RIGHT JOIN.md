# RIGHT JOIN —— 右外连接

> [!abstract] 一句话
> `RIGHT JOIN` 保留==**右表的全部行**==，左表匹配不上就补 `NULL`。
> 但它只是 `LEFT JOIN` 的**镜像**——==**把两张表调换位置，`RIGHT JOIN` 就完全等价于 `LEFT JOIN`**==，所以实战里几乎可以不用它。

> [!info] 与 DML 版的分工
> [[Join|DML/Join]] 已覆盖 `RIGHT JOIN` 的基础语法。本篇专讲它的**镜像本质**、==**翻写成 LEFT JOIN 的步骤与陷阱**==、以及==**混用 `LEFT`/`RIGHT` 的灾难**==。

---

> [!example] 本篇示例数据
> 与同目录 `INNER JOIN` / `LEFT JOIN` / `FULL OUTER JOIN` / `CROSS JOIN` 各篇**共用同一套 `dept` / `emp` 表**。
> 记住两个"异类"：**财务部没人**、**孙七没部门**——`RIGHT JOIN` 保的是**右边**那张表，所以它会让**孙七**露脸。

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
RIGHT [OUTER] JOIN 右表 [别名] ON 连接条件;
```

- `OUTER` 可省略。
- 语义：**右表全留**；左表匹配不上 → 左表**所有列**补 `NULL`。

```sql
SELECT d.dept_id, d.dept_name, e.emp_name, e.salary
FROM dept d
RIGHT JOIN emp e ON d.dept_id = e.dept_id
ORDER BY e.emp_id;
```

结果（**5 行**，这次轮到**左表**的数据为 NULL）：

```
dept_id | dept_name | emp_name | salary
--------+-----------+----------+--------
   1001 | 研发部    | 张三     |  12000
   1001 | 研发部    | 李四     |  15000
   1002 | 销售部    | 王五     |   9000
   1002 | 销售部    | 赵六     |   8500
   NULL | NULL      | 孙七     |   7000   <-- 右表这行必须留着，左表没东西就补 NULL
```

**财务部这次不见了**（它在 `dept` 里，属于"左表独有"），**孙七出现了**。

---

## 二、和 LEFT JOIN 的对照：谁是主角

| | `LEFT JOIN` | `RIGHT JOIN` |
| --- | --- | --- |
| 保留哪张表全部行 | **左表** | **右表** |
| 哪张表的列会补 NULL | **右表** | **左表** |
| `dept LEFT JOIN emp` 多出谁 | 财务部 | —— |
| `dept RIGHT JOIN emp` 多出谁 | —— | 孙七 |

> [!tip] 只记一句话
> `LEFT JOIN` 保左边、`RIGHT JOIN` 保右边。**"谁被保留"由关键字方向决定，和表本身无关。**

---

## 三、核心定理：`RIGHT JOIN` ≡ 交换表序的 `LEFT JOIN`

```sql
-- 两条语句的结果集完全相同（只有列的先后顺序可能不同）
SELECT d.dept_id, d.dept_name, e.emp_name
FROM dept d RIGHT JOIN emp e ON d.dept_id = e.dept_id;

SELECT d.dept_id, d.dept_name, e.emp_name
FROM emp e LEFT JOIN dept d ON e.dept_id = d.dept_id;
```

两者都返回 **5 行**、都包含**孙七**、财务部都不出现。

> [!important] 记成公式
> ==**`A RIGHT JOIN B ON c` ≡ `B LEFT JOIN A ON c`（连接条件一字不改）。**==
> 因为"保右边全部行"，等价于"把两张表左右一换，变成保左边全部行"。
> 推论：**任何 `RIGHT JOIN` 都能改写成 `LEFT JOIN`，反之亦然。**

---

## 四、把 `RIGHT JOIN` 翻写成 `LEFT JOIN`

标准三步：

1. **交换两张表的位置**（连同各自的别名）；
2. **`ON` 条件原样保留**（等值连接左右可互换，`a.x = b.y` 与 `b.y = a.x` 等价）；
3. 按需调整 `SELECT` 列表的列顺序。

```sql
-- 原句（RIGHT）
SELECT d.dept_name, e.emp_name
FROM dept d RIGHT JOIN emp e ON d.dept_id = e.dept_id;

-- 翻写（LEFT）：两句结果一致
SELECT d.dept_name, e.emp_name
FROM emp e LEFT JOIN dept d ON d.dept_id = e.dept_id;
```

> [!warning] 陷阱：`ON` / `WHERE` 里"非保留表"的条件要跟着挪
> 翻写时**保留的表变了**，"非保留表"也随之改变，条件放哪边会跟着变。看这个例子——想保住**全部员工**、只看**研发部**的部门信息：
>
> ```sql
> -- ❌ 错：dept 是非保留表，条件却写进 WHERE → 退化，只剩研发部的人
> SELECT e.emp_name, d.dept_name
> FROM dept d RIGHT JOIN emp e ON d.dept_id = e.dept_id
> WHERE d.dept_name = '研发部';
> -- 结果：张三、李四（2 行）——王五、赵六、孙七全被筛掉了，RIGHT 白写
>
> -- ✅ 对：dept 是非保留表，条件写进 ON
> SELECT e.emp_name, d.dept_name
> FROM dept d RIGHT JOIN emp e ON d.dept_id = e.dept_id AND d.dept_name = '研发部';
> ```
>
> 第二种结果（**5 行**，`emp` 全留，只有研发部的人配上部门）：
> ```
> emp_name | dept_name
> ---------+----------
> 张三     | 研发部
> 李四     | 研发部
> 王五     | NULL
> 赵六     | NULL
> 孙七     | NULL
> ```
> 翻写成左连接时，dept 变成**右表（非保留表）**，条件仍留在 `ON`：
> ```sql
> FROM emp e LEFT JOIN dept d ON e.dept_id = d.dept_id AND d.dept_name = '研发部';
> ```
> 规律始终是那句：**非保留表的条件写 `ON`，保留表自己的条件写 `WHERE`。**

---

## 五、什么时候真的会见到 `RIGHT JOIN`

| 场景 | 说明 |
| --- | --- |
| 主表恰好在右边 | 例如"以 `emp` 为主、`dept` 只是补充信息"，顺手把 `emp` 写在右边 |
| 老代码 / 生成器 | 某些 ORM 或 SQL 生成器拼出 `RIGHT JOIN` |
| 面试题 | 让你说明它和 `LEFT JOIN` 的关系、能否互换 |
| 从文档照抄 | 原句就是 `RIGHT JOIN`，翻写需要理解，干脆照抄 |

> [!important] 团队规范通常**只允许 `LEFT JOIN`**
> 心智负担减半——永远只问一句"**谁是左表、谁全留**"。
> 见到 `RIGHT JOIN` 的第一反应应该是：**能不能翻成 `LEFT JOIN`？**（第三章的公式一换即可。）

---

## 六、多表里混用 `LEFT` / `RIGHT` 的灾难

```sql
-- ❌ 谁是主角？读三遍也未必说清
FROM a
LEFT  JOIN b ON ...
RIGHT JOIN c ON ...
```

- `b`、`c` 里谁是"被保留"的？`a` 到底留不留？
- 混用时"谁全留"随每一个关键字变化，是**代码审查的重灾区**、也是 bug 温床。

> [!tip] 统一成 `LEFT JOIN` 的写法
> 把每个 `RIGHT JOIN` 用第三章的公式翻成 `LEFT JOIN`，全句只剩一种方向：
> ```sql
> -- 全用 LEFT，保留关系一眼看穿
> FROM c
> LEFT JOIN a ON ...
> LEFT JOIN b ON ...
> ```
> 宁可调整 `FROM` 的表顺序，也不要在一句里同时出现 `LEFT` 和 `RIGHT`。

---

## 七、常见错误合集

> [!failure] 把 `RIGHT JOIN` 当成 `LEFT JOIN` 用
> 以为"写哪个都一样"——结果保留了**错误的表**，独有行出现在**意料之外的一侧**。`LEFT` 保左、`RIGHT` 保右，别记反。

> [!failure] 非保留表条件写进 `WHERE`
> 与 `LEFT JOIN` 同一个病、方向相反：`RIGHT JOIN` 里**左表是非保留表**，左表条件写 `WHERE` 会让外连接退化（第四章）。

> [!failure] 以为"内外连接与外连接一样可交换"
> **内连接是对称的**（`a JOIN b` ≡ `b JOIN a`），**外连接是不对称的**（`a LEFT JOIN b` ≢ `b LEFT JOIN a`）。搞混就会左右颠倒。

> [!failure] `SELECT *` 后依赖列顺序
> 翻写时表的顺序变了，`SELECT *` 出来的列顺序也跟着变。**线上代码别 `SELECT *`**，显式列名。

---

## 八、速查表

| 需求 | 写法 |
| --- | --- |
| 保住右表全部行 | `左表 RIGHT JOIN 右表 ON ...` |
| 等价改写 | `右表 LEFT JOIN 左表 ON ...`（条件不变） |
| 右表（保留表）自身条件 | 写 `WHERE` |
| 左表（非保留表）条件 | 写 `ON` |
| 团队规范 | 一律用 `LEFT JOIN`，把 `RIGHT` 翻写掉 |
| 多表 | 不混用 `LEFT`/`RIGHT`，全翻成 `LEFT` |

> [!question] 自测三连
> 1. `dept RIGHT JOIN emp` 和 `emp LEFT JOIN dept` 结果一样吗？为什么？
> 2. 把 `A RIGHT JOIN B ON c` 翻成 `LEFT JOIN`，`ON` 条件要不要改？
> 3. `RIGHT JOIN` 里"左表的过滤条件"应该写 `ON` 还是 `WHERE`？

---

> [!quote] 一句话记忆
> **`RIGHT JOIN` 保右表全员、左表缺的补 NULL；它等价于"把两表左右一换的 `LEFT JOIN`"，所以规范里只写 `LEFT JOIN`；非保留表的条件写 `ON`，保留表自身的条件写 `WHERE`。**

---

## 相关笔记

- [[LEFT JOIN]] —— 保左表全员，`RIGHT JOIN` 翻写后的归宿
- [[INNER JOIN]] —— 只留匹配上的行，与外连接的分水岭
- [[FULL OUTER JOIN]] —— `LEFT` 与 `RIGHT` 一起用（`UNION`）就是全外连接
- [[CROSS JOIN]] —— 笛卡尔积
- [[SELF JOIN]] —— 自连接里同样会用到"左/右"的选择
- [[Join]] —— 六种连接的横向总览
- [[Where]] —— 三值逻辑与 NULL 判定
