# COUNT —— 计数

> [!abstract] 一句话
> `COUNT` 是唯一**既能数"行"、又能数"值"**的聚合函数：`COUNT(*)` 数的是"**有多少行**"（含全 NULL 的行），`COUNT(列)` 数的是"**这一列有多少个非 NULL 值**"——**两者之差，正好就是该列的 NULL 行数**。

---

> [!example] 本篇示例数据
> 与同目录的 `SUM` / `AVG` / `MAX` / `MIN` / `GROUP BY` / `HAVING` 各篇**共用同一张 `emp` 表**。
> 两个关键设计：**`bonus` 有 3 行是 `NULL`**（专门用来辨析 `COUNT(*)` 与 `COUNT(列)`），**共 3 个部门、男女齐全**（用来演示分组计数）。

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

## 一、语法与四种写法

```sql
COUNT(*)                          -- 数行数
COUNT(1)                          -- 同 COUNT(*)，数行数
COUNT(表达式)                      -- 数该表达式"非 NULL"的行数
COUNT(DISTINCT 表达式 [, 表达式2])  -- 数去重后的个数
```

同一张 `emp` 表上四种写法的结果：

```sql
SELECT
    COUNT(*)               AS c_star,
    COUNT(1)               AS c_one,
    COUNT(bonus)           AS c_bonus,
    COUNT(DISTINCT bonus)  AS c_distinct
FROM emp;
```

```
+--------+-------+---------+------------+
| c_star | c_one | c_bonus | c_distinct |
+--------+-------+---------+------------+
|      8 |     8 |       5 |          4 |
+--------+-------+---------+------------+
```

| 写法 | 统计对象 | 是否忽略 NULL | 结果 | 什么时候用 |
| --- | --- | --- | --- | --- |
| `COUNT(*)` | **行数**（整行，含全 NULL 行） | ❌ 不忽略 | `8` | 数"有多少条记录"，最常用 |
| `COUNT(1)` | 同 `COUNT(*)` | ❌ 不忽略 | `8` | 与 `COUNT(*)` 完全等价 |
| `COUNT(bonus)` | `bonus` **非 NULL** 的行数 | ✅ 忽略 | `5` | 数"有多少人填了这一项" |
| `COUNT(DISTINCT bonus)` | `bonus` 去重后的**不同值**个数 | ✅ 忽略 | `4` | 数"有几种不同的值" |

> [!important] 记住这一句
> ==**`COUNT(*)` 数行，`COUNT(列)` 数值；只有 `COUNT(*)` 不忽略 NULL。**==
> `COUNT` 是唯一**不忽略整体行数**的聚合函数——`SUM` / `AVG` / `MAX` / `MIN` 全都跳过 NULL。

---

## 二、`COUNT(*)` vs `COUNT(1)`：真的一样吗

```sql
SELECT COUNT(*) FROM emp;    -- 8
SELECT COUNT(1) FROM emp;    -- 8
```

> [!question] 面试官问：`COUNT(*)` 和 `COUNT(1)` 谁快？
> **标准答案：一样快。**
> `COUNT(*)` **不是**"把每一列都读出来再数一遍"，优化器会把它**重写**成等价逻辑，两者的执行计划完全相同（都能用最小的二级索引做扫描，不回表）。
> 网上流传的"`COUNT(1)` 更快"是**针对 Oracle 的老结论**（Oracle 里 `COUNT(*)` 要展开所有列），**在 MySQL 上不成立**。
> 惯例写 `COUNT(*)`，语义最明确、也最官方。

> [!note] 那 `COUNT(列名)` 会更快吗？
> 不。`COUNT(列)` 不但不会更快，反而要**逐行判断该列是不是 NULL**，通常比 `COUNT(*)` 更慢；而且它还有"漏掉 NULL 行"的语义差异。
> 唯一例外：如果该列上恰好有个**很小的二级索引**，优化器可能选它——但那是优化器的选择，不是你写法的功劳。

---

## 三、`COUNT(*)` vs `COUNT(列)`：NULL 是分水岭

这是 `COUNT` 家族最核心的差异。用能跑的数字说话：

```sql
SELECT
    COUNT(*)      AS 总行数,          -- 8
    COUNT(bonus)  AS 有奖金的,        -- 5
    COUNT(*) - COUNT(bonus) AS 没奖金的 -- 3
FROM emp;
```

```
+--------+----------+----------+
| 总行数 | 有奖金的 | 没奖金的 |
+--------+----------+----------+
|      8 |        5 |        3 |
+--------+----------+----------+
```

`bonus` 列实际值是 `5000, NULL, 8000, 3000, NULL, 3000, NULL, 4000`：

| 表达式 | 含义 | 结果 |
| --- | --- | --- |
| `COUNT(*)` | 8 行，不论 `bonus` 是不是 NULL | `8` |
| `COUNT(bonus)` | 只数非 NULL 的 5 个 | `5` |
| `COUNT(*) - COUNT(bonus)` | 差集 = 该列 NULL 的行数 | `3` |

> [!tip] 实用技巧：用差集数 NULL
> 想知道某一列有**多少行是 NULL**，不用 `COUNT(*) ... WHERE 列 IS NULL` 再查一次：
> `SELECT COUNT(*) - COUNT(列) AS null_count FROM t;`
> 一条语句同时拿到"总数、有值数、NULL 数"三个数。

```sql
-- 等价写法：直接过滤 NULL 行
SELECT COUNT(*) FROM emp WHERE bonus IS NULL;    -- 3
```

> [!danger] 最常见的写法错误
> **想数"部门有几种"却写成裸列**，结果差得离谱：
> ```sql
> SELECT COUNT(dept) FROM emp;            -- ❌ 得到 8（dept 全都非 NULL）
> SELECT COUNT(DISTINCT dept) FROM emp;   -- ✅ 得到 3（研发部/销售部/财务部）
> ```
> 记住：`COUNT(列)` 是**数非 NULL 的行数**，不是"数不同的值"。要"数不同值"必须加 `DISTINCT`。

---

## 四、`COUNT(DISTINCT ...)`：去重计数

```sql
SELECT
    COUNT(DISTINCT bonus)  AS 奖金档次,   -- 4
    COUNT(DISTINCT dept)   AS 部门数,     -- 3
    COUNT(DISTINCT gender) AS 性别数      -- 2
FROM emp;
```

```
+----------+--------+--------+
| 奖金档次 | 部门数 | 性别数 |
+----------+--------+--------+
|        4 |      3 |      2 |
+----------+--------+--------+
```

`bonus` 去重：`{5000, 8000, 3000, 4000}` → 两个 `3000` 合成一个 → `4`（NULL 不计入）。

> [!info] 多列 `DISTINCT`
> `COUNT(DISTINCT a, b)` 是**合法**的，表示"按 `(a, b)` 这个**组合**去重"计数，不要以为它只能跟一列。
> ```sql
> -- 一个部门有几个人分布在几个城市？（这里用 dept + gender 演示组合去重）
> SELECT COUNT(DISTINCT dept, gender) FROM emp;   -- 6
> ```

### 4.1 实用场景

```sql
-- 每个部门有几名员工？覆盖了几种性别？
SELECT dept,
       COUNT(*)               AS 人数,
       COUNT(DISTINCT gender) AS 性别种类
FROM emp
GROUP BY dept;
```

```
+--------+--------+----------+
| dept   | 人数   | 性别种类 |
+--------+--------+----------+
| 研发部 |      3 |        2 |
| 财务部 |      2 |        2 |
| 销售部 |      3 |        2 |
+--------+--------+----------+
```

> [!warning] `COUNT(DISTINCT ...)` 不统计 NULL
> 和 `COUNT(列)` 一致，`COUNT(DISTINCT bonus)` 里的 NULL **不进分母、也不计入结果**。
> 如果业务上"没填"也算一种"值"，得先 `IFNULL(bonus, '未填')` 再 `COUNT(DISTINCT ...)`，否则那 3 行 NULL 会被悄悄丢掉。

---

## 五、`COUNT` 与 `GROUP BY`：分组计数

不分组时，`COUNT` 把**全表当一个组**；加上 `GROUP BY` 后，才变成"每个组各数各的"。

```sql
-- 整表当一个组：一行结果
SELECT COUNT(*) AS 总人数 FROM emp;

-- 按部门分组：三行结果
SELECT dept, COUNT(*) AS 人数 FROM emp GROUP BY dept;
```

```
-- 分组结果
+--------+--------+
| dept   | 人数   |
+--------+--------+
| 研发部 |      3 |
| 财务部 |      2 |
| 销售部 |      3 |
+--------+--------+
```

> [!tip] 分组计数的行数取决于"组"，不是"行"
> 8 行数据按 `dept` 分组，只出来 3 行——**一个组只产出一行**。
> 每个组的 `COUNT(*)` 再单独算，加起来正好回到 8。

---

## 六、`COUNT` 与 `HAVING`：过滤"组"

`COUNT` 的结果是组级值，只能在 `HAVING` 里当条件，不能在 `WHERE` 里。（原因见 [[HAVING]]）

```sql
-- 找出人数 ≥ 3 的部门
SELECT dept, COUNT(*) AS 人数
FROM emp
GROUP BY dept
HAVING COUNT(*) >= 3;
```

```
+--------+--------+
| dept   | 人数   |
+--------+--------+
| 研发部 |      3 |
| 销售部 |      3 |
+--------+--------+
```

```sql
-- ❌ 报错 ERROR 1111：Invalid use of group function
SELECT dept, COUNT(*) FROM emp WHERE COUNT(*) >= 3 GROUP BY dept;
```

> [!important] 分界线
> `WHERE` 里**永远不能**出现 `COUNT(*)`——那时还没分组，`COUNT` 无从算起。
> 想按"组的规模"筛选，一律用 `HAVING`。

---

## 七、性能：为什么 InnoDB 的 `COUNT(*)` 慢

> [!info] 两种存储引擎的差异
> - **MyISAM** 把表的总行数**存在磁盘上**，不带 `WHERE` 的 `COUNT(*)` **直接返回**，O(1)。
> - **InnoDB** 因为支持 **MVCC**（同一时刻不同事务看到的行数可能不同），**不能存**一个"全局行数"，所以 `COUNT(*)` 必须**真的扫一遍**能覆盖的最小索引。数据越多越慢。

```sql
-- 假设表上有二级索引 idx_dept(dept)
-- InnoDB 会选最小的二级索引来扫，而不是扫整行（回表代价大）
SELECT COUNT(*) FROM emp;
```

替代方案：

| 方案 | 做法 | 代价 |
| --- | --- | --- |
| 自己维护计数表 | `INSERT/DELETE` 时同步 `UPDATE counter SET n = n + 1` | 精确，但要处理并发和事务 |
| `information_schema` | `SELECT TABLE_ROWS FROM information_schema.TABLES WHERE ...` | ==**近似值，误差可达 40%**==，只能用于估算 |
| 缓存 | `COUNT(*)` 结果缓存进 Redis，定时刷新 | 有延迟，适合报表 |

> [!warning] 别用 `information_schema.TABLES.TABLE_ROWS` 当精确值
> InnoDB 它只是一个**统计估算**，随 `ANALYZE TABLE` 和采样的波动而变。
> 拿它做"精确分页总数"会翻车。

---

## 八、常见错误合集

> [!failure] 把 NULL 当值数错了
> `COUNT(bonus)` 得 5，以为是 8——忘记了 **`COUNT(列)` 只数非 NULL**。
> 要数"总行数"用 `COUNT(*)`。

> [!failure] 想数不同值却忘了 DISTINCT
> `SELECT COUNT(dept) FROM emp;` 得 8（数行），不是 3（数部门）。
> 改成 `COUNT(DISTINCT dept)`。

> [!failure] `COUNT(NULL)` 恒等于 0
> ```sql
> SELECT COUNT(NULL);            -- 0（常量 NULL，没有任何非 NULL 值可数）
> SELECT COUNT('abc');           -- 8（常量非 NULL，每行算 1）
> SELECT COUNT(1);               -- 8
> ```
> 常量是"每行都算一次"还是"永远不算"，取决于它是不是 NULL。

> [!failure] 空结果集返回的是 0，不是 NULL
> ```sql
> SELECT COUNT(*) FROM emp WHERE dept = '不存在的部门';
> -- 结果：0     ← 注意：COUNT 是唯一在空集上返回 0 的聚合函数
> ```
> 对比：`SUM` / `AVG` / `MAX` / `MIN` 在空集上**全部返回 NULL**。
> 所以前端做除法时 `COUNT(*)` 天然安全，其他几个要 `IFNULL`。

> [!failure] ERROR 1055：`COUNT` 和裸列一起 SELECT
> ```sql
> SELECT dept, name, COUNT(*) FROM emp GROUP BY dept;
> -- ERROR 1055: Expression #2 of SELECT list is not in GROUP BY clause ...
> ```
> `name` 不是分组列也不是聚合函数。要么加进 `GROUP BY`，要么换成 `COUNT(name)`。详见 [[计算机类/数据库/Mysql/聚合查询/GROUP BY]]。

---

## 九、速查表

| 需求 | 写法 | `emp` 表结果 |
| --- | --- | --- |
| 数总行数 | `COUNT(*)` | `8` |
| 数某列非 NULL 的行数 | `COUNT(bonus)` | `5` |
| 数某列 NULL 的行数 | `COUNT(*) - COUNT(bonus)` | `3` |
| 数不同的值有几种 | `COUNT(DISTINCT bonus)` | `4` |
| 按组合去重计数 | `COUNT(DISTINCT a, b)` | 组合数 |
| 分组内计数 | `GROUP BY dept` + `COUNT(*)` | 每部门人数 |
| 过滤组规模 | `HAVING COUNT(*) >= 3` | 人多的部门 |
| 空集上的结果 | `COUNT(*)` → `0`（唯一一个） | `0` |

> [!question] 自测三连
> 1. `emp` 表上 `COUNT(*)`、`COUNT(bonus)`、`COUNT(DISTINCT bonus)` 分别是多少？
> 2. `COUNT(*) - COUNT(某列)` 得到的是什么？
> 3. `SELECT COUNT(dept) FROM emp;` 想数部门数，结果为什么是错的？怎么改？

---

> [!quote] 一句话记忆
> **`COUNT(*)` 数行、`COUNT(列)` 数值、`COUNT(DISTINCT 列)` 数不同值**；三者差集就是 NULL 行数；**只有 `COUNT(*)` 不忽略 NULL，也只有它在空集上返回 `0`**。

---

## 相关笔记

- [[计算机类/数据库/Mysql/聚合查询/SUM]] —— 求和，空集返回 NULL 的对照
- [[计算机类/数据库/Mysql/聚合查询/AVG]] —— 平均值，分母也是"非 NULL 行数"
- [[计算机类/数据库/Mysql/聚合查询/MAX]] · [[计算机类/数据库/Mysql/聚合查询/MIN]] —— 最大 / 最小
- [[计算机类/数据库/Mysql/聚合查询/GROUP BY]] —— 分组计数的主场
- [[计算机类/数据库/Mysql/聚合查询/HAVING]] —— 用 `COUNT` 过滤组
- [[计算机类/数据库/Mysql/DML/Group By]] —— 分组子句的完整版
- [[计算机类/数据库/Mysql/DML/Where]] —— NULL 的三值逻辑
