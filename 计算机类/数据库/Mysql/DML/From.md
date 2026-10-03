# FROM —— 数据从哪来

> [!abstract] 一句话
> `FROM` 回答"**数据从哪来**"，它是执行顺序的**第一步**：先把数据源（表、视图、派生表）准备好，后面所有子句才有东西可处理。

---

## 一、语法

```sql
SELECT 字段列表
FROM 表名 [AS 别名];

-- 库名限定
FROM 数据库名.表名 [AS 别名];
SELECT u.id, u.name FROM `mydb`.`user` AS u;
```

| 写法      | 示例                               | 说明            |
| ------- | -------------------------------- | ------------- |
| 基本      | `FROM user`                      | 最常用           |
| ==带别名== | `FROM user AS u` / `FROM user u` | `AS` ==可省略==  |
| 库限定     | `FROM mydb.user`                 | ==跨库查询，需要权限== |
| 反引号     | ``FROM `order` ``                | ==表名撞关键字时必加== |

> [!tip] 别名前的 AS 建议一直写
> `FROM user u` 和 `FROM user AS u` 完全等价，但省掉 `AS` 在**多表 + 复杂查询**里极难读，也容易和 `JOIN` 的 `ON` 混淆。
> ==团队规范里通常直接强制写 `AS`==。

---

## 二、表别名

### 2.1 为什么必须用别名

三个理由：

1. **多表时避免歧义**——两张表都有 `id`、`created_at`，不加前缀直接报 `ERROR 1052 (23000): Column 'id' in field list is ambiguous`
2. **缩短书写**——`sys_user_login_log.created_at` 对比 `l.created_at`
3. **自连接必需**——同一张表在 `FROM` 里出现两次，**不用别名根本没法区分**

```sql
-- ❌ 歧义报错 1052
SELECT id, name FROM user, `order` WHERE user.id = `order`.user_id;

-- ✅ 用别名区分
SELECT u.id, u.name, o.amount
FROM user AS u, `order` AS o
WHERE u.id = o.user_id;
```

自连接的典型场景（员工 + 他的上级）：

```sql
SELECT e.name AS 员工, m.name AS 上级
FROM employee AS e
LEFT JOIN employee AS m ON e.manager_id = m.id;
```

> [!question] 别名只在当前这条 SELECT 里有效吗？
> **是的，作用域仅限这一条语句。** 上一条 `SELECT` 里定义的 `u`，下一条语句认不出来。
> 还有一条容易忽略的规则：**表别名一旦定义，同一层里就不能再写原表名了**——`FROM user AS u WHERE user.id = 1` 会报 `ERROR 1054: Unknown column 'user.id' in 'where clause'`。

> [!note] 视图里的别名会被"固化"成字段名
> 视图的本质就是一条存起来的 [[Select]]。如果写成 `CREATE VIEW v AS SELECT u.id AS uid FROM user AS u;`，
> 视图对外暴露的字段名就是 `uid`，**表别名 `u` 不会跑出去**。改表名也不会影响视图里已经存下的别名。

---

## 三、多表 FROM = 笛卡尔积

`FROM a, b` 不带任何条件时，MySQL 会对两张表做**笛卡尔积**（全组合）：结果行数 = a 的行数 × b 的行数。

```sql
-- 3 行 × 4 行 = 12 行
SELECT t.id AS tid, s.id AS sid
FROM t_color AS t, t_size AS s;
```

两张表长这样：

```
t_color (3 行)          t_size (4 行)
+----+--------+         +----+--------+
| id | name   |         | id | name   |
+----+--------+         +----+--------+
|  1 | 红     |         |  1 | S      |
|  2 | 绿     |         |  2 | M      |
|  3 | 蓝     |         |  3 | L      |
+----+--------+         |  4 | XL     |
                        +----+--------+
```

笛卡尔积的结果（12 行）：

```
+-----+-----+
| tid | sid |
+-----+-----+
|   1 |   1 |
|   1 |   2 |
|   1 |   3 |
|   1 |   4 |
|   2 |   1 |
|   2 |   2 |
|   2 |   3 |
|   2 |   4 |
|   3 |   1 |
|   3 |   2 |
|   3 |   3 |
|   3 |   4 |
+-----+-----+
12 rows in set (0.00 sec)
```

> [!warning] 忘了连接条件 = 灾难
> 两张 1 万行的表做笛卡尔积是 **1 亿行**，三张就是万亿级——查询直接把数据库拖死。
> 这是新手最容易犯、后果最严重的错误之一。**凡是 `FROM` 里挂了多张表，就必须检查有没有连接条件。**

> [!note] 这就是"隐式连接"的写法
> `FROM a, b WHERE a.id = b.a_id` 与 `FROM a JOIN b ON a.id = b.a_id` **在 MySQL 里是等价的**，都是内连接。
> `FROM a, b`（后面不接 WHERE）等价于 `FROM a CROSS JOIN b`，也就是显式笛卡尔积。
> 两种语法都合法，但推荐用 `JOIN ... ON`，理由见 §六。

---

## 四、派生表：子查询当表用

`FROM` 后面除了表名，还能跟一个**括号包起来的 SELECT**——它叫**派生表**（derived table）。

```sql
SELECT ...
FROM (SELECT ... FROM ...) AS 别名;
```

> [!danger] MySQL 强制要求派生表必须有别名
> 少了别名直接报：
> `ERROR 1248 (42000): Every derived table must have its own alias`
> 这是 MySQL 特有的硬性要求。**写完右括号立刻补上 `AS 别名`**，就不会忘。

```sql
-- ✅ 正确：求"每个性别的平均分"里高于 80 的那个
SELECT t.gender, t.avg_score
FROM (
    SELECT gender, ROUND(AVG(score), 2) AS avg_score
    FROM student
    GROUP BY gender
) AS t
WHERE t.avg_score > 80;
```

结果：

```
+--------+-----------+
| gender | avg_score |
+--------+-----------+
| F      |     84.00 |
+--------+-----------+
1 row in set (0.00 sec)
```

> [!example] 派生表的典型用途
> - **先聚合再过滤**：`WHERE` 里不能写聚合函数，把聚合结果塞进派生表，外层就能用 `WHERE` 了（上面的例子正是这个套路，效果等价于 `HAVING`）
> - **先算再连接**：把统计结果当成一张"临时表"去 JOIN 主表
> - **限制排序规模**：先在派生表里 `ORDER BY ... LIMIT`，外层再 JOIN
>
> 性能上要留意：早期 MySQL 会把派生表**物化成无索引的临时表**；5.7 起有了 `derived_merge` 优化，简单的派生表会被**合并进外层查询**，不再落地。写复杂派生表前先用 `EXPLAIN` 看一眼。

---

## 五、FROM 视图 / FROM 临时表

`FROM` 后面能跟的东西，本质上是"**任何能产出结果集的东西**"：

```sql
-- 普通表
SELECT * FROM user;

-- 视图：本质是一条存起来的 SELECT
SELECT * FROM v_user_order;

-- 临时表：只在当前会话可见
CREATE TEMPORARY TABLE tmp_top AS
    SELECT id, score FROM student ORDER BY score DESC LIMIT 3;
SELECT * FROM tmp_top;

-- 派生表
SELECT * FROM (SELECT 1 AS n) AS t;
```

| 数据源 | 生命周期 | 数据存在哪 | 典型用途 |
| --- | --- | --- | --- |
| 普通表 | 永久 | 磁盘 | 业务数据 |
| 视图 | 永久（只是定义） | ==**不存数据**==，每次现算 | 简化复杂查询、权限隔离 |
| 临时表 | 会话结束即消失 | 内存 / 临时区 | 中间结果、跑批统计 |
| 派生表 | 语句结束即消失 | 通常不落盘 | 子查询当表用 |

> [!info] 视图和派生表到底差在哪
> 视图是**建好放在那里、可以反复引用**的"命名查询"，`SHOW CREATE VIEW v;` 能看到它的定义；
> 派生表是**写在语句里、用完就扔**的临时结果。
> 一句话：**视图 = 有名字的派生表，派生表 = 一次性的视图。**

---

## 六、FROM 与 JOIN 的关系

| 对比项 | `FROM a, b WHERE ...`（隐式连接） | `FROM a JOIN b ON ...`（显式连接） |
| --- | --- | --- |
| 可读性 | ❌ 连接条件混在过滤条件里 | ✅ 连接和过滤一眼分清 |
| 漏写条件的后果 | 静默变成==**笛卡尔积**==，结果爆炸 | 语法报错（除非故意写 `CROSS JOIN`） |
| 能否写外连接 | ❌ **写不出来** | ✅ `LEFT` / `RIGHT` JOIN |
| 标准兼容 | 老式写法 | ✅ ANSI 标准 |
| MySQL 执行计划 | 通常相同 | 通常相同 |

> [!important] 结论：一律用 `JOIN ... ON`
> 隐式写法唯一的好处是少打字，代价是**漏条件时不会有任何提示**。
> 显式 `JOIN` 把职责分开了：`ON` 只写两张表怎么对上，`WHERE` 只写你要筛什么。

```sql
-- 隐式：连接条件 (u.id = o.user_id) 和过滤条件 (o.amount > 100) 混在一起
SELECT u.name, o.amount
FROM user AS u, `order` AS o
WHERE u.id = o.user_id AND o.amount > 100;

-- 显式：职责分明，推荐
SELECT u.name, o.amount
FROM user AS u
JOIN `order` AS o ON u.id = o.user_id
WHERE o.amount > 100;
```

两种写法结果完全一致：

```
+--------+---------+
| name   | amount  |
+--------+---------+
| 张三   |  199.00 |
| 李四   |  520.00 |
+--------+---------+
2 rows in set (0.00 sec)
```

表多于两张就一直往后挂：

```sql
SELECT u.name, o.amount, p.product_name
FROM user AS u
JOIN `order` AS o  ON u.id = o.user_id
JOIN order_item AS oi ON o.id = oi.order_id
JOIN product AS p  ON oi.product_id = p.id
WHERE o.status = 1;
```

更细的连接类型（`LEFT` / `RIGHT` / 自连接 / `USING` / 连接算法）见 [[Join]]。

---

## 七、FROM 后面的表越多越慢

> [!warning] 表数量带来的不是线性增长
> MySQL 优化器要为每张表选一个"访问顺序"，表越多，**可能的连接顺序组合呈阶乘增长**（n 张表最多 n! 种）。
> 表一多，优化器可能来不及穷举，改用启发式规则，**选出的执行计划就不再是最优的**。
> 经验值：**单条 SQL 的 JOIN 表数量控制在 5 张以内**，更多就该拆查询或用中间表落地。

**驱动表**（driving table）：多表连接时，MySQL 通常先读的那张表。它决定了后面每张表要被探测多少次。

```sql
-- 假设 user 10 万行、order 100 行，且 order.user_id 上有索引
SELECT u.name, o.amount
FROM user AS u JOIN `order` AS o ON u.id = o.user_id;

-- 优化器大概率选 order 当驱动表：
--   读 100 行 order → 每行的 user_id 去 user 主键上查 1 次 → 共 100 次探测
-- 反过来若让 user 驱动：
--   读 10 万行 user → 每行去 order 上按索引查 → 10 万次探测
```

> [!tip] "小表驱动大表"的直觉
> 驱动表每多一行，就要多探测一次被驱动表。所以**让行数少的那张当驱动表**，总探测次数才少。
> 注意这里的"小"指的是**过滤后实际参与连接的行数**，不是表的物理行数。
> `EXPLAIN` 结果里排在第一行的，就是驱动表。

> [!failure] 常见误区：`FROM` 里表多就一定慢
> 不一定。**有合适的索引 + 过滤条件足够强**，10 张表也能毫秒级返回。
> 真正致命的是这几种：**连接字段没有索引**（逼出全表扫描的嵌套循环）、**漏写连接条件**（笛卡尔积）、**驱动表选错**（优化器统计信息过期，`ANALYZE TABLE t;` 刷新一下）。

---

> [!quote] 一句话记忆
> **FROM 是执行的第一步**：`FROM a, b` 不给条件就是**笛卡尔积**（行数相乘），派生表**必须起别名**（否则 1248），多表连接**一律写 `JOIN ... ON`**，并且尽量让**小表当驱动表**。

---

## 相关笔记

- [[Select]] —— SELECT 全子句与执行顺序
- [[Where]] —— 连接之后的过滤条件
- [[Join]] —— 内连接、外连接、自连接、连接算法
- [[Group By]] —— 分组统计
- [[Having]] —— 分组后的过滤
- [[Insert]] —— 往表里写数据
- [[Create Table]] —— 数据源是怎么建出来的
