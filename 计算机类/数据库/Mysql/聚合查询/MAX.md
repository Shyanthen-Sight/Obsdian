# MAX —— 最大值

> [!abstract] 一句话
> `MAX` 取一组里的**最大值**，它不挑类型——**数字、字符串、日期**都能比，比的是各自的排序规则；它==**忽略 NULL**==，所以**全组都是 NULL 时返回 NULL**。真正的难点不是"取值"，而是"**想拿到最大值那一整行**"。

---

> [!example] 本篇示例数据
> 与同目录的 `COUNT` / `SUM` / `AVG` / `MIN` / `GROUP BY` / `HAVING` 各篇**共用同一张 `emp` 表**。
> 三个可比的列各有用途：`salary`（数字比大小）、`hire_date`（**日期比先后**，找最晚入职）、`bonus`（有 NULL，演示"忽略"）。

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
MAX([DISTINCT] 表达式)
```

| 要点 | 说明 |
| --- | --- |
| 参数 | 列名、常量、或表达式 |
| `DISTINCT` | 可选，但**毫无意义**（最大值去不去重都一样）——别写 |
| 忽略 NULL | ✅ 是 |
| 空集 / 全 NULL | ==**返回 `NULL`**==（不是 0） |
| 返回类型 | **和入参同类型**（日期入 → 日期出，字符串入 → 字符串出） |

```sql
SELECT
    MAX(salary)     AS 最高工资,      -- 15000.00
    MAX(bonus)      AS 最高奖金,      -- 8000.00
    MAX(hire_date)  AS 最晚入职       -- 2023-04-01
FROM emp;
```

```
+----------+----------+------------+
| 最高工资 | 最高奖金 | 最晚入职   |
+----------+----------+------------+
| 15000.00 |  8000.00 | 2023-04-01 |
+----------+----------+------------+
```

> [!info] `MAX(DISTINCT x)` 是个摆设
> `MAX` 是"挑出最大的那个值"，去重不影响谁最大。
> 写 `MAX(DISTINCT x)` 不报错、结果和 `MAX(x)` 一模一样，但会多一层排序开销。**不要写。**

---

## 二、`MAX` 能比什么：数字、字符串、日期

`MAX` 比的是**该类型定义的排序顺序**，不只是数字：

| 类型 | 比法 | 示例结果 |
| --- | --- | --- |
| 数字 | 数值大小 | `MAX(salary)` = `15000.00` |
| 日期 / 时间 | 时间先后（**越晚越大**） | `MAX(hire_date)` = `2023-04-01` |
| 字符串 | **字符集排序规则（collation）** | `MAX(gender)` = `'M'`（`M` > `F`） |
| 枚举 | 按**定义顺序** | 新值大于旧值 |

```sql
SELECT
    MAX(hire_date)  AS 最晚入职,
    MAX(gender)     AS 字母最大的性别    -- 'M' > 'F'
FROM emp;
```

```
+------------+--------------------+
| 最晚入职   | 字母最大的性别     |
+------------+--------------------+
| 2023-04-01 | M                  |
+------------+--------------------+
```

> [!warning] 字符串的 `MAX` 依赖排序规则，中文尤其"反直觉"
> 字符串比较**不是按拼音、也不是按笔画**，而是按**字符集编码 + collation**：
> - 英文在 `utf8mb4_general_ci` 下大致按字母序；
> - **中文**的排序则由 collation 决定（`utf8mb4_general_ci` 和 `utf8mb4_unicode_ci` 结果可能不同）。
>
> `MAX(name)` 这种写法**换一个 collation 结果就变**，业务上几乎没意义。
> 想按拼音/笔划排中文，得显式 `ORDER BY CONVERT(name USING gbk)` 之类的转换，别指望 `MAX(name)`。

> [!tip] 日期上的 `MAX` 很实用
> `MAX(hire_date)` 就是"**最后入职的人什么时候来的**"；换到订单表上 `MAX(created_at)` 就是"**最近一笔订单时间**"。
> 这是"取最新一条"最省事的判断方式（详细取整行见第五节）。

---

## 三、`MAX` 与 NULL

```sql
SELECT
    MAX(bonus)  AS 最高奖金         -- 8000.00（3 个 NULL 被跳过）
FROM emp;
```

> [!important] NULL 不参与比较，被直接跳过
> `bonus` 是 `5000, NULL, 8000, 3000, NULL, 3000, NULL, 4000`，`MAX` 只在这 5 个非 NULL 值里挑，得 `8000.00`。
> 和 `SUM` 一样，`MAX` **忽略 NULL**。

> [!danger] 全组都是 NULL → 返回 `NULL`，不是 0
> ```sql
> SELECT MAX(bonus) FROM emp WHERE bonus IS NULL;
> ```
> ```
> +-------------+
> | MAX(bonus)  |
> +-------------+
> |        NULL |
> +-------------+
> ```
> 空集也是 `NULL`。**"最高奖金"显示成空，要 `IFNULL(MAX(bonus), 0)` 兜底。**

> [!note] 一条容易搞反的点
> `MAX` 忽略 NULL，**不代表 NULL 算最小值**。
> 换 `MIN` 也一样跳过 NULL（见 [[计算机类/数据库/Mysql/聚合查询/MIN]]）——NULL 既不进"最大"的候选，也不进"最小"的候选，**它根本不在集合里**。

---

## 四、`MAX` 与 `GROUP BY`：分组取最大

```sql
SELECT dept,
       COUNT(*)       AS 人数,
       MAX(salary)    AS 最高工资
FROM emp
GROUP BY dept;
```

```
+--------+--------+----------+
| dept   | 人数   | 最高工资 |
+--------+--------+----------+
| 研发部 |      3 | 15000.00 |
| 财务部 |      2 |  9500.00 |
| 销售部 |      3 |  8000.00 |
+--------+--------+----------+
```

这是"**每个部门的最高工资 / 最新订单 / 最大金额**"这类需求的标准写法。

> [!note] `MAX` 拿到的是"值"，不是"人"
> 上面结果告诉你"研发部最高 15000"，但**没告诉你是谁**。
> 很多人以为 `MAX` 会自动带出对应那行的其他列——**不会**。想知道"谁拿了 15000"，看第五节。

> [!danger] 别用 `SELECT dept, name, MAX(salary)` 蒙
> ```sql
> SELECT dept, name, MAX(salary) FROM emp GROUP BY dept;   -- ERROR 1055（开了 only_full_group_by）
> ```
> 关掉检查后，`name` 会是**组内随机某一行**的名字，**不一定是**工资最高的那个人。
> 这种"看起来对、其实随机"的结果是报表事故的重灾区。详见 [[计算机类/数据库/Mysql/聚合查询/GROUP BY]]。

---

## 五、想拿到"最大值那一整行"（重点）

需求："**工资最高的员工是谁？**" `MAX(salary)` 只给你 `15000`，给不了 `王强`。三种正确姿势：

### 5.1 方法一：子查询（推荐，能处理并列）

```sql
SELECT * FROM emp WHERE salary = (SELECT MAX(salary) FROM emp);
```

```
+----+--------+--------+--------+----------+------------+---------+
| id | name   | dept   | gender | salary   | hire_date  | bonus   |
+----+--------+--------+--------+----------+------------+---------+
|  3 | 王强   | 研发部 | M      | 15000.00 | 2019-05-20 | 8000.00 |
+----+--------+--------+--------+----------+------------+---------+
```

> [!success] 为什么推荐它
> 它用 `salary = (最大值)` 匹配，**如果有两个人工资并列最高，会一起返回**，不会漏。

### 5.2 方法二：`ORDER BY` + `LIMIT 1`（最直观）

```sql
SELECT * FROM emp ORDER BY salary DESC LIMIT 1;
```

- 结果同上，但**并列时只返回 1 行**。
- 适合"只要一个代表"的场景；如果并列为真，需要额外规则（比如再按 `id` 兜底：`ORDER BY salary DESC, id ASC LIMIT 1`）。

### 5.3 方法三：窗口函数（每组取 Top N 的通用解）

```sql
SELECT * FROM (
    SELECT *, RANK() OVER (PARTITION BY dept ORDER BY salary DESC) AS rk
    FROM emp
) AS t
WHERE rk = 1;
```

```
+----+--------+--------+--------+----------+------------+---------+----+
| id | name   | dept   | gender | salary   | hire_date  | bonus   | rk |
+----+--------+--------+--------+----------+------------+---------+----+
|  3 | 王强   | 研发部 | M      | 15000.00 | 2019-05-20 | 8000.00 |  1 |
|  8 | 周杰   | 财务部 | M      |  9500.00 | 2020-08-22 | 4000.00 |  1 |
|  4 | 赵敏   | 销售部 | F      |  8000.00 | 2021-09-15 | 3000.00 |  1 |
+----+--------+--------+--------+----------+------------+---------+----+
```

> [!important] 三个方法怎么选
> | 需求 | 用什么 |
> | --- | --- |
> | 全表取最大那一行（含并列） | 方法一：`WHERE 列 = (SELECT MAX(...))` |
> | 全表取一条（不要并列） | 方法二：`ORDER BY ... LIMIT 1` |
> | **每组**都要取最大那一行 | 方法三：窗口函数 `RANK() OVER (PARTITION BY ...)` |
>
> `RANK()` 会把并列都标成 1；`ROW_NUMBER()` 则强行只留一个。按业务选择。

---

## 六、性能：`MAX` 走索引，非常快

> [!success] `MAX` 是"能用上索引"的聚合函数
> 如果列上有**索引**（B+ 树），求 `MAX` **不需要扫描全表**——顺着索引**最右端**看一眼就行。
> 执行计划里会出现 ==`Select tables optimized away`==，意思就是"优化器直接把答案算出来了，连表都不用读"。

```sql
-- 表上建索引
CREATE INDEX idx_salary ON emp(salary);

-- 带上 WHERE 限定范围时，也能利用索引定位
EXPLAIN SELECT MAX(salary) FROM emp;
```

| 情况 | 是否走索引 | 说明 |
| --- | --- | --- |
| `MAX(salary)`，`salary` 有索引 | ✅ 极快 | 取 B+ 树最右端，`Select tables optimized away` |
| `MAX(salary)`，`salary` 无索引 | ❌ 全表扫 | 老老实实扫一遍 |
| `MAX(salary) WHERE dept='研发部'`，只有 `salary` 单列索引 | ⚠️ 部分 | 可走索引扫，但要回表查 `dept` |
| 有联合索引 `(dept, salary)` | ✅ 快 | 每个 `dept` 分组也能走索引取各自的最大值 |

> [!tip] 想更快就建"带方向的联合索引"
> `GROUP BY dept` 同时取 `MAX(salary)` 时，联合索引 `(dept, salary)` 让"按部门分组 + 取组内最大"一次索引扫完，避免分组时的临时表/排序。
> 列顺序要**先分组列、后聚合列**。

> [!warning] `MAX` 快，但"取整行"可能不快
> 第五节方法一的子查询本身很快（走索引），可外层 `WHERE salary = 15000` 若没索引仍需扫表。
> 方法二的 `ORDER BY salary DESC LIMIT 1` 在 `salary` 有索引时也是"读最右一行"，非常快。

---

## 七、`MAX` 与 `HAVING`

`MAX` 的结果是**组级值**，只能进 `HAVING`：

```sql
-- 只要"有人工资超过 10000"的部门
SELECT dept, MAX(salary) AS 最高工资
FROM emp
GROUP BY dept
HAVING MAX(salary) > 10000;
```

```
+--------+----------+
| dept   | 最高工资 |
+--------+----------+
| 研发部 | 15000.00 |
+--------+----------+
```

> [!important] 常见误用
> `WHERE MAX(salary) > 10000` 会报 `ERROR 1111`（分组还没发生，`MAX` 无从算起）。
> 判断标准：**`WHERE` 里只放行级条件，组级条件一律 `HAVING`。** 详见 [[计算机类/数据库/Mysql/聚合查询/HAVING]]。

---

## 八、常见错误合集

> [!danger] 坑一：以为 `MAX` 会带出整行
> `SELECT dept, MAX(salary) FROM emp GROUP BY dept;` 只给值不给行。
> 要整行用第五节三种方法。

> [!danger] 坑二：`MAX` + 裸列 = 随机结果
> `SELECT name, MAX(salary) FROM emp;` 拿到的 `name` 不保证是最高工资那位。
> 详见第四节。

> [!failure] 坑三：空集 / 全 NULL 返回 `NULL`
> 展示前 `IFNULL(MAX(x), 0)` 兜底。

> [!failure] 坑四：字符串 `MAX` 结果依赖 collation
> 中文名上做 `MAX(name)` 意义不大，换 collation 结果就变。

> [!failure] 坑五：ERROR 1111 —— `MAX` 进了 `WHERE`
> 改到 `HAVING`。

> [!failure] 坑六：ERROR 1055 —— `MAX` 和裸列混用
> 要么把裸列加进 `GROUP BY`，要么别 SELECT 它。见 [[计算机类/数据库/Mysql/聚合查询/GROUP BY]]。

---

## 九、速查表

| 需求 | 写法 | `emp` 表结果 |
| --- | --- | --- |
| 全表最大工资 | `MAX(salary)` | `15000.00` |
| 最晚入职日期 | `MAX(hire_date)` | `2023-04-01` |
| 忽略 NULL 取最大 | `MAX(bonus)` | `8000.00` |
| 各分组最大值 | `GROUP BY dept` + `MAX(salary)` | 每部门最高 |
| 最大那一整行（含并列） | `WHERE salary = (SELECT MAX(salary) ...)` | 王强 |
| 最大那一行（只取一条） | `ORDER BY salary DESC LIMIT 1` | 王强 |
| 每组最大那一行 | `RANK() OVER (PARTITION BY dept ORDER BY salary DESC)` | 每组 Top1 |
| 空集兜底 | `IFNULL(MAX(x), 0)` | `0` |

> [!question] 自测三连
> 1. `SELECT dept, name, MAX(salary) FROM emp GROUP BY dept;` 关掉 `only_full_group_by` 后，`name` 会是最高工资的那个人吗？
> 2. 想"取工资最高的那整行"，子查询 `WHERE salary = (SELECT MAX(...))` 和 `ORDER BY ... LIMIT 1` 有什么区别？
> 3. `MAX(bonus)` 在有 3 个 NULL 的列上，结果是几？全列都是 NULL 呢？

---

> [!quote] 一句话记忆
> **`MAX` 取最大、忽略 NULL、全 NULL 或空集返回 `NULL`**；它比数字/日期/字符串都行，但**字符串比法依赖 collation**；**`MAX` 只给值不给行**——想拿整行，用 `WHERE 列 = (SELECT MAX(列))`。

---

## 相关笔记

- [[计算机类/数据库/Mysql/聚合查询/MIN]] —— 最小值，`MAX` 的镜像
- [[计算机类/数据库/Mysql/聚合查询/COUNT]] · [[计算机类/数据库/Mysql/聚合查询/SUM]] · [[计算机类/数据库/Mysql/聚合查询/AVG]] —— 其余聚合函数
- [[计算机类/数据库/Mysql/聚合查询/GROUP BY]] —— 分组取最大
- [[计算机类/数据库/Mysql/聚合查询/HAVING]] —— 按最大值过滤组
- [[计算机类/数据库/Mysql/DML/Order By]] —— `ORDER BY` + `LIMIT 1` 取最大那一行
- [[计算机类/数据库/Mysql/DML/Group By]] —— 分组子句完整版
