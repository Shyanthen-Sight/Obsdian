# SUM —— 求和

> [!abstract] 一句话
> `SUM` 把一组里的值**加起来**，它==**忽略 NULL**==（NULL 当不存在，不是当 0）——所以在**空集**上返回的是 `NULL` 而不是 `0`，这是"求和"和"计数"最大的分界线。

---

> [!example] 本篇示例数据
> 与同目录的 `COUNT` / `AVG` / `MAX` / `MIN` / `GROUP BY` / `HAVING` 各篇**共用同一张 `emp` 表**。
> 关键设计：**`bonus` 有 3 行是 `NULL`**（演示"忽略 NULL"与"空集返回 NULL"），**3 个部门**（演示分组求和）。

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

## 一、语法

```sql
SUM([DISTINCT] 表达式)
```

| 要点 | 说明 |
| --- | --- |
| 参数 | 列名、常量、或**表达式**（`salary * 12`、`price * qty`） |
| `DISTINCT` | 可选，先**去重**再求和 |
| 忽略 NULL | ✅ 是，NULL 直接跳过 |
| 空集结果 | ==**`NULL`**==（不是 `0`） |
| `GROUP BY` | 可选；不写则全表当一个组 |

基本用法：

```sql
SELECT
    SUM(salary)  AS 工资总额,     -- 74500.00
    SUM(bonus)   AS 奖金总额      -- 23000.00
FROM emp;
```

```
+----------+----------+
| 工资总额 | 奖金总额 |
+----------+----------+
| 74500.00 | 23000.00 |
+----------+----------+
```

---

## 二、`SUM` 忽略 NULL —— 但真正的坑在"空集"

`bonus` 是 `5000, NULL, 8000, 3000, NULL, 3000, NULL, 4000`：

```sql
SELECT
    SUM(bonus)             AS 直接求和,        -- 23000.00（NULL 被跳过）
    SUM(IFNULL(bonus, 0))  AS 把NULL当0求和     -- 23000.00（结果一样）
FROM emp;
```

> [!tip] 为什么"忽略 NULL"和"把 NULL 当 0"结果相同？
> 因为**加法里加不加 0 都一样**：`5000 + 0 + 8000 = 13000`，跳过 NULL 也是 `13000`。
> 所以对 `SUM` 来说，忽略 NULL 通常**不影响结果**——这和 `AVG` 完全不同（`AVG` 忽略 NULL 会**改变分母**，见 [[计算机类/数据库/Mysql/聚合查询/AVG]]）。

> [!danger] 真正的坑：空集上 `SUM` 返回 NULL，不是 0
> ```sql
> SELECT SUM(salary) FROM emp WHERE dept = '不存在的部门';
> ```
> ```
> +-------------+
> | SUM(salary) |
> +-------------+
> |        NULL |
> +-------------+
> ```
> 你以为"没数据当然加起来是 0"，但 SQL 的语义是"**没有任何值可加** → 结果未知 → NULL"。
> 前端拿到 `NULL` 直接参与加减法，整个计算链变成 `NULL`，报表一片空白——**这是报表 bug 的常客**。

> [!success] 正确做法：套一层 `IFNULL` / `COALESCE`
> ```sql
> SELECT IFNULL(SUM(salary), 0) AS 工资总额 FROM emp WHERE dept = '不存在的部门';
> -- 结果：0
> ```
> 前端展示、参与后续计算时**一律兜底**。同理适用于 `AVG` / `MAX` / `MIN`——**只有 `COUNT` 不需要兜底**，它天然返回 `0`。

---

## 三、`SUM(DISTINCT ...)`：先去重再求和

```sql
SELECT
    SUM(bonus)           AS 全部之和,     -- 23000.00（含重复的 3000、3000）
    SUM(DISTINCT bonus)  AS 去重之和      -- 15000.00（5000+8000+3000+4000）
FROM emp;
```

```
+----------+----------+
| 全部之和 | 去重之和 |
+----------+----------+
| 23000.00 | 15000.00 |
+----------+----------+
```

| 写法 | 计算 | 结果 |
| --- | --- | --- |
| `SUM(bonus)` | `5000 + 8000 + 3000 + 3000 + 4000` | `23000.00` |
| `SUM(DISTINCT bonus)` | `5000 + 8000 + 3000 + 4000`（去掉一个重复的 3000） | `15000.00` |

> [!warning] `SUM(DISTINCT)` 用错场景会闹笑话
> "去重求和"听起来对，但业务上极少需要。算"部门工资总额"时用了 `SUM(DISTINCT salary)`，只要有两个员工工资相同，就会被**少算一份**。
> **只有明确要"把不同值各算一次"时才用**，比如"统计有多少种不同的金额档位加总"。

---

## 四、`SUM` 的参数是表达式

`SUM` 求和的是**表达式的结果**，不是原始列：

```sql
SELECT
    SUM(salary)          AS 月薪合计,      -- 74500.00
    SUM(salary * 12)     AS 年薪合计,      -- 894000.00
    SUM(salary + bonus)  AS 月薪加奖金     -- 74500 + 23000 = 97500.00
FROM emp;
```

```
+----------+-----------+--------------+
| 月薪合计 | 年薪合计  | 月薪加奖金   |
+----------+-----------+--------------+
| 74500.00 | 894000.00 |     97500.00 |
+----------+-----------+--------------+
```

> [!note] `SUM(salary + bonus)` 里的 NULL 会"吞噬"整行
> `salary + bonus` 中，只要 `bonus` 是 NULL，这个**表达式**就是 NULL（NULL 参与算术 → NULL），于是这一行被 `SUM` 跳过。
> 上面 `SUM(salary + bonus)` 只加了 5 行（有奖金的）：`(12000+15000+8000+7500+9500) + (5000+8000+3000+3000+4000) = 52000 + 23000 = 97500`。
> 那 3 个没有奖金的员工，**连底薪都被漏掉了**——这是隐蔽的算错。
>
> 正确写法：`SUM(salary + IFNULL(bonus, 0))` → 加上全部 8 个人的底薪。

---

## 五、`SUM` 与 `GROUP BY`：分组求和

```sql
SELECT dept,
       COUNT(*)      AS 人数,
       SUM(salary)   AS 工资总额
FROM emp
GROUP BY dept;
```

```
+--------+--------+--------------+
| dept   | 人数   | 工资总额     |
+--------+--------+--------------+
| 研发部 |      3 |     36000.00 |
| 财务部 |      2 |     16500.00 |
| 销售部 |      3 |     22000.00 |
+--------+--------+--------------+
```

> [!tip] 分组求和可以"对账"
> 各组 `SUM` 相加 = 全表 `SUM`：`36000 + 16500 + 22000 = 74500` ✅。
> 如果对不上，说明有行被漏掉或重复——这是排查数据问题的常用手段。

### 5.1 用 `SUM` + 条件表达式做"交叉统计"

`SUM` 配合 `CASE WHEN` 或布尔表达式，能在一行里同时算出多个维度的和（**行转列**经典手法）：

```sql
SELECT dept,
       SUM(gender = 'M')               AS 男,           -- 布尔转 1/0 再求和
       SUM(gender = 'F')               AS 女,
       SUM(CASE WHEN salary > 8000 THEN 1 ELSE 0 END) AS 高薪人数
FROM emp
GROUP BY dept;
```

```
+--------+------+------+----------+
| dept   | 男   | 女   | 高薪人数 |
+--------+------+------+----------+
| 研发部 |    2 |    1 |        3 |
| 财务部 |    1 |    1 |        1 |
| 销售部 |    1 |    2 |        0 |
+--------+------+------+----------+
```

> [!info] 为什么 `SUM(gender = 'M')` 能当计数用？
> 条件表达式在 MySQL 里返回 `1`（真）/ `0`（假），`SUM` 把 1 加起来就等于"满足条件的行数"。
> 写起来比 `SUM(CASE WHEN ... END)` 短，但可读性差一些，团队风格统一即可。

---

## 六、累计求和与窗口函数

普通 `SUM` 只能给**一个总数**。想要"**逐行的累计值**"（running total），要用窗口函数：

```sql
SELECT name, dept, salary,
       SUM(salary) OVER (ORDER BY hire_date) AS 累计工资
FROM emp
ORDER BY hire_date;
```

```
+--------+--------+----------+----------+
| name   | dept   | salary   | 累计工资 |
+--------+--------+----------+----------+
| 张伟   | 研发部 | 12000.00 | 12000.00 |
| 王强   | 研发部 | 15000.00 | 27000.00 |
| 李娜   | 研发部 |  9000.00 | 36000.00 |
| 周杰   | 财务部 |  9500.00 | 45500.00 |
| 刘洋   | 销售部 |  7500.00 | 53000.00 |
| 赵敏   | 销售部 |  8000.00 | 61000.00 |
| 陈晨   | 销售部 |  6500.00 | 67500.00 |
| 孙悦   | 财务部 |  7000.00 | 74500.00 |
+--------+--------+----------+----------+
```

| 写法 | 效果 |
| --- | --- |
| `SUM(salary)` | 全表一个总数 `74500` |
| `SUM(salary) OVER ()` | 每一行都显示总数 `74500`（不折叠行） |
| `SUM(salary) OVER (ORDER BY hire_date)` | **累计**求和，从第一行加到当前行 |
| `SUM(salary) OVER (PARTITION BY dept)` | **按部门**分别求组内总额 |

> [!important] 窗口函数和 `GROUP BY` 的关键差别
> `GROUP BY` 会把多行**折叠**成一行；`SUM(...) OVER (...)` **保留每一行**，只是额外附上一个聚合值。
> 所以"既要明细、又要汇总"的场景，用窗口函数一次搞定，不需要 `JOIN` 回group by结果。

---

## 七、返回 NULL 的坑（再强调）

> [!danger] 三类"看起来该是 0，其实是 NULL"的情况
> 1. **空集**：`SELECT SUM(salary) FROM emp WHERE 1 = 0;` → `NULL`
> 2. **全组都是 NULL**：`SELECT SUM(bonus) FROM emp WHERE bonus IS NULL;` → `NULL`
> 3. **表达式里混入 NULL**：`SUM(salary + bonus)` 会漏掉 `bonus` 为 NULL 的行（见第四节）
>
> 兜底三件套：`IFNULL(SUM(x), 0)`、`COALESCE(SUM(x), 0)`、`SUM(IFNULL(x, 0))`（最后一个是"把 NULL 当 0 参与求和"，语义与前两者不同）。

```sql
SELECT
    IFNULL(SUM(salary), 0)          AS 兜底总额,       -- 空集时给 0
    SUM(IFNULL(bonus, 0))           AS 奖金按0算        -- NULL 当 0
FROM emp
WHERE dept = '不存在的部门';
```

---

## 八、常见错误合集

> [!failure] 忘了兜底，`NULL` 传到了前端
> 报表上"总金额"一栏空白。根因：条件筛完没有匹配行，`SUM` 返回 `NULL`。
> 改法：`IFNULL(SUM(...), 0)`。

> [!failure] 精度丢失：用 `FLOAT` / `DOUBLE` 存金额
> ```sql
> -- ⚠️ 浮点数累加会有误差：0.1 + 0.2 = 0.30000000000000004
> SELECT SUM(amount) FROM orders;   -- 金额字段应使用 DECIMAL
> ```
> **金额、单价、税率一律用 `DECIMAL`**，`SUM` 才有精确结果。

> [!failure] 整型溢出
> `SUM` 的结果类型会**向上升级**（`INT` 求和 → `BIGINT` / `DECIMAL`），一般安全。
> 但给 MySQL 传结果的应用端变量如果是 `INT`，`SUM` 一旦超过 21 亿就溢出——**接收 `SUM` 的变量要用 `long` / `BIGINT`**。

> [!failure] ERROR 1111：把 `SUM` 写进 `WHERE`
> ```sql
> SELECT dept, SUM(salary) FROM emp WHERE SUM(salary) > 100000 GROUP BY dept;
> -- ERROR 1111 (HY000): Invalid use of group function
> ```
> 聚合条件只能进 `HAVING`：
> ```sql
> SELECT dept, SUM(salary) FROM emp GROUP BY dept HAVING SUM(salary) > 30000;
> ```

> [!failure] ERROR 1055：`SUM` 和裸列一起 SELECT
> ```sql
> SELECT dept, name, SUM(salary) FROM emp GROUP BY dept;
> -- ERROR 1055: ... 'emp.name' ... not functionally dependent ...
> ```
> `name` 既不是分组列也不是聚合，MySQL 不知道给哪个。详见 [[计算机类/数据库/Mysql/聚合查询/GROUP BY]]。

---

## 九、速查表

| 需求 | 写法 | `emp` 表结果 |
| --- | --- | --- |
| 全表求和 | `SUM(salary)` | `74500.00` |
| 忽略 NULL 求和 | `SUM(bonus)` | `23000.00` |
| 把 NULL 当 0 求和 | `SUM(IFNULL(bonus, 0))` | `23000.00` |
| 去重求和 | `SUM(DISTINCT bonus)` | `15000.00` |
| 对表达式求和 | `SUM(salary * 12)` | `894000.00` |
| 分组求和 | `GROUP BY dept` + `SUM(salary)` | 每部门总额 |
| 空集兜底 | `IFNULL(SUM(x), 0)` | `0` |
| 累计求和 | `SUM(x) OVER (ORDER BY ...)` | 逐行累加 |
| 行转列计数 | `SUM(条件表达式)` | 各维度计数 |

> [!question] 自测三连
> 1. `SELECT SUM(bonus) FROM emp WHERE bonus IS NULL;` 返回什么？为什么不是 0？
> 2. `SUM(salary)` 和 `SUM(salary + bonus)` 的分母行数一样吗？为什么？
> 3. "部门工资总额"为什么不能用 `SUM(DISTINCT salary)`？

---

> [!quote] 一句话记忆
> **`SUM` 忽略 NULL、在空集上返回 `NULL`（记得 `IFNULL`）**；`SUM(DISTINCT)` 先去重再求和，多数场景会算少；`SUM(表达式)` 遇到 NULL 会**整行漏加**；要"累计"必须上窗口函数 `SUM(...) OVER (...)`。

---

## 相关笔记

- [[计算机类/数据库/Mysql/聚合查询/COUNT]] —— 计数，空集返回 0 的对照
- [[计算机类/数据库/Mysql/聚合查询/AVG]] —— 平均值，NULL 与分母的关系
- [[计算机类/数据库/Mysql/聚合查询/MAX]] · [[计算机类/数据库/Mysql/聚合查询/MIN]] —— 最大 / 最小
- [[计算机类/数据库/Mysql/聚合查询/GROUP BY]] —— 分组求和
- [[计算机类/数据库/Mysql/聚合查询/HAVING]] —— 按求和结果过滤组
- [[计算机类/数据库/Mysql/DML/Group By]] —— 分组子句完整版
