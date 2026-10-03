# SELECT —— 查询的核心

> [!abstract] 一句话
> `SELECT` 是**声明式查询**的门面：你只写"**要什么**"（要哪些列、什么条件、怎么排），不写"**怎么拿**"（走不走索引、先读哪张表）——执行计划交给优化器去定。

---

## 一、语法骨架

```sql
SELECT   [DISTINCT] 字段列表
FROM     表名
WHERE    行级过滤          -- 分组前，逐行筛
GROUP BY 分组字段
HAVING   组级过滤          -- 分组后，逐组筛
ORDER BY 排序字段 [ASC|DESC]
LIMIT    [偏移量,] 条数;
```

> [!info] 七个位置，顺序是死的
> 只有 `SELECT` 是必须的，其余都可省，但**顺序不能换**。把 `WHERE` 写到 `ORDER BY` 后面、把 `LIMIT` 写到 `ORDER BY` 前面，一律 `ERROR 1064 (42000): You have an error in your SQL syntax`。

各子句分工一览：

| 子句 | 干什么 | 处理单位 | 能用聚合函数 | 能用 SELECT 别名 |
| --- | --- | --- | --- | --- |
| `SELECT` | 挑列 / 算表达式 | 列 | ✅ | —（自己就是） |
| `FROM` | 指定数据源 | 表 | ❌ | ❌ |
| `WHERE` | 过滤**行** | 一行 | ❌ | ❌ |
| `GROUP BY` | 把行折叠成组 | 一组 | ❌ | ❌ |
| `HAVING` | 过滤**组** | 一组 | ✅ | ✅ |
| `ORDER BY` | 排序 | 结果集 | ✅ | ✅ |
| `LIMIT` | 截断 | 结果集 | ❌ | ❌（只吃数字） |

---

## 二、书写顺序 vs 执行顺序（本篇最重要）

**你写的顺序 ≠ MySQL 真正跑的顺序。**

| 步骤 | 你写的顺序 | 实际执行顺序 | 这一步发生了什么 |
| --- | --- | --- | --- |
| 1 | `SELECT` | `FROM` | 先确定数据源，拿到"一张虚拟大表" |
| 2 | `FROM` | `WHERE` | 逐行过滤，行数开始变少 |
| 3 | `WHERE` | `GROUP BY` | 剩下的行开始折叠成组 |
| 4 | `GROUP BY` | `HAVING` | 淘汰不满足条件的**组** |
| 5 | `HAVING` | `SELECT` | 这才算列、算聚合、**起别名** |
| 6 | `ORDER BY` | `ORDER BY` | 拿到别名后才能按别名排序 |
| 7 | `LIMIT` | `LIMIT` | 最后截断 |

> [!tip] 为什么 SELECT 排在第五步？
> 因为 `SELECT` 这一行干的活最多：算表达式、跑聚合函数、**给列起别名**。
> 而这些都得等 `FROM` / `WHERE` / `GROUP BY` / `HAVING` 把"数据集合"准备好之后才能算。
> 一句话：**别名是 SELECT 的产物，产物不可能在产生它的步骤之前被使用。**

### 2.1 结论一：别名只能在 SELECT **之后**的子句里用

| 位置 | 能用别名吗 | 原因 |
| --- | --- | --- |
| `WHERE` | ❌ | 执行在 SELECT 之前，别名还不存在 |
| `GROUP BY` | ❌ | 同上（MySQL 私自放宽了，标准 SQL 不允许，别依赖） |
| `HAVING` | ✅ | 执行在 SELECT 之后 |
| `ORDER BY` | ✅ | 同上，最常用 |
| `LIMIT` | ❌ | 只接受数字字面量 |

```sql
-- ✅ 正确：HAVING / ORDER BY 都能用别名
SELECT gender, AVG(score) AS avg_score
FROM student
GROUP BY gender
HAVING avg_score > 80
ORDER BY avg_score DESC;

-- ❌ 报错：ERROR 1054 (42S22): Unknown column 'avg_score' in 'where clause'
SELECT gender, AVG(score) AS avg_score
FROM student
WHERE avg_score > 80
GROUP BY gender;
```

### 2.2 结论二：SELECT 里没出现的字段，照样能拿来过滤

`WHERE` 执行得比 `SELECT` 早，所以它拿到的是**表里的所有字段**，哪怕你最后根本不查它。

```sql
-- 只查姓名，却用 age / score 过滤 → 完全合法
SELECT name FROM student WHERE age > 18 AND score >= 80;
```

> [!question] 那"没查出来的字段"能用来排序吗？
> 也能。`ORDER BY age` 一样合法，因为 `ORDER BY` 同样能访问 `FROM` 阶段那张虚拟表。
> 真正受限的只有一件事：**你没法在 `WHERE` 里引用 SELECT 起出来的别名**——因为那个"列"在那一步还不存在。

### 2.3 结论三：LIMIT 最后执行，所以能"截断"

`LIMIT` 排在 `ORDER BY` 之后，说明它拿到的是**已经排好序的完整结果**，然后才切掉多余的部分。

```sql
-- 先按分数全局降序，再取前 3 名
SELECT name, score FROM student ORDER BY score DESC LIMIT 3;
```

> [!warning] LIMIT 和 ORDER BY 拆开就是耍流氓
> 只写 `LIMIT 3` 而不写 `ORDER BY`，返回的 3 行**顺序不确定**（取决于存储引擎和索引的读取顺序）。
> 分页查询里"第 2 页和第 1 页出现重复行"，十有八九是漏了 `ORDER BY`，或者排序字段**不唯一**（比如好几个人都是 92 分，得补个 `, id` 兜底）。

---

## 三、查询常量与表达式（无 FROM 的 SELECT）

`SELECT` 后面不一定是列名，可以是常量、函数、算式。不需要表时 `FROM` 可以整个省掉——**这是调试函数最快的办法**。

```sql
SELECT 1 + 1;                  -- 结果：2
SELECT 'hello';                -- 结果：hello
SELECT NOW();                  -- 结果：2026-09-29 10:30:00
SELECT 7 / 2;                  -- 结果：3.5000（MySQL 的 / 是小数除法）
SELECT 7 DIV 2;                -- 结果：3（DIV 才是整数除法）
SELECT CONCAT('a', 'b', 'c');  -- 结果：abc
SELECT IFNULL(NULL, '兜底');    -- 结果：兜底
```

结果长这样：

```
+---------+
| 1 + 1   |
+---------+
|       2 |
+---------+
1 row in set (0.00 sec)
```

> [!example] 无 FROM 的 SELECT 有什么用？
> - **当计算器**：`SELECT 100 * 1.13;`
> - **试函数**：不确定 `DATE_FORMAT` 的格式串怎么写，先 `SELECT DATE_FORMAT(NOW(), '%Y-%m-%d');` 试出来
> - **验字符集**：`SELECT '😀';` 能不能跑，直接暴露 `utf8` / `utf8mb4` 的坑
> - **探时区**：`SELECT NOW(), UTC_TIMESTAMP();` 一眼看出会话时区
> - **造测试数据**：`SELECT 1 AS id UNION ALL SELECT 2;`

---

## 四、列别名 AS

```sql
SELECT name AS 姓名, age AS 年龄, score * 1.1 AS 提分后 FROM student;
```

| 写法 | 示例 | 说明 |
| --- | --- | --- |
| 完整写法 | `age AS 年龄` | 推荐，语义清楚 |
| 省略 AS | `age 年龄` | 合法，但可读性差 |
| 带引号 | `score AS '总分(含加分)'` | ==**含空格 / 括号时必须加引号**== |
| 带反引号 | ``score AS `desc` `` | 别名撞关键字时用 |

> [!tip] 别名加引号的两个理由
> 1. 别名里有**空格、连字符、括号**：写成 `AS 'total score'`，不加引号直接 1064
> 2. 别名本身就是**保留字**：写成 ``AS `desc` ``
>
> MySQL 里单引号也能给别名用；如果开了 `ANSI_QUOTES` 模式，就改用双引号。

> [!note] 表别名和列别名是两回事
> `SELECT s.name FROM student AS s` 里的 `s` 是**表别名**，作用域覆盖整条语句，`WHERE s.age > 18` 也能用。
> `SELECT name AS n` 里的 `n` 是**列别名**，只在 `HAVING` / `ORDER BY` 里可见。
> 表别名的细节放在 [[From]] 里讲。

---

## 五、DISTINCT 去重

```sql
SELECT DISTINCT gender FROM student;           -- 结果：M, F
SELECT DISTINCT gender, age FROM student;      -- 组合去重
SELECT COUNT(DISTINCT gender) FROM student;    -- 结果：2
```

> [!warning] DISTINCT 作用于**整行**，不是某一列
> `SELECT DISTINCT gender, age` 去重的是 **(gender, age) 这个组合**，不是"先按 gender 去重、再顺便带出 age"。
> 所以只要有一列不同，整行就不算重复。想要"每个性别只留一行"，那是 `GROUP BY` 的活。

```sql
-- 原始数据
-- gender | age
--   M    | 18
--   M    | 19
--   F    | 18
--   F    | 18   ← 与上一行完全相同

SELECT DISTINCT gender, age FROM student;
```

结果：

```
+--------+-----+
| gender | age |
+--------+-----+
| M      |  18 |
| M      |  19 |
| F      |  18 |
+--------+-----+
3 rows in set (0.00 sec)
```

> [!danger] NULL 在 DISTINCT 里被视为"相同"
> 有 3 行 `gender` 都是 `NULL`，`SELECT DISTINCT gender` 只会输出**一个** `NULL`。
> 这和 `NULL = NULL` 返回 `UNKNOWN` 的直觉相反——去重走的是"分组"语义，把所有 `NULL` 归进同一组。
> 另外 `COUNT(DISTINCT col)` **不统计 NULL**（和 `COUNT(col)` 一致）。NULL 的完整讨论见 [[Where]]。

> [!tip] DISTINCT 的性能代价
> 它需要给结果集建**临时表或排序**来判重，不是白拿的。能在 `WHERE` 里先收窄就先收窄。
> 还有个暗坑：`DISTINCT` 和 `ORDER BY` 一起用时，`ORDER BY` 的字段**必须在 SELECT 列表里**，否则报 `ERROR 3065: Expression #1 of ORDER BY clause is not in SELECT list`。

---

## 六、`SELECT *` 的四个代价

```sql
SELECT * FROM student;   -- 看着省事，坑全在后面
```

> [!danger] 为什么生产代码基本禁用 `SELECT *`
> 1. **隐式依赖列顺序**——有人执行了 `ALTER TABLE ... ADD COLUMN x FIRST`，你代码里的 `rs.getString(3)` 就静默取错了值，不报错、最难查
> 2. **多传无用字段**——宽表上一行几百字节变几 KB，网络和内存成倍浪费；带上 `TEXT` / `BLOB` 更致命
> 3. **覆盖索引直接失效**——本来索引里就有你要的列、不用回表；`SELECT *` 一写，必然要去读整行
> 4. **表结构变更后静默出错**——新增字段可能覆盖了原有变量的语义，程序照跑但结果是错的
>
> 临时看看数据，`SELECT *` 没问题；**写进代码、进 ORM、进接口返回，一律写明字段。**

```sql
-- 表：student(id, name, gender, age)，有索引 idx_name_age(name, age)

-- ✅ 覆盖索引：所需字段全在索引里，不回表
SELECT name, age FROM student WHERE name = '张三';

-- ❌ 索引退化成回表：为了拿 id / gender，必须回聚簇索引读整行
SELECT * FROM student WHERE name = '张三';
```

> [!failure] 反过来说，也有必须用 `SELECT *` 的时候
> - 建表 / 导数据的中间步骤：`CREATE TABLE t2 AS SELECT * FROM t1;`
> - 临时排查、命令行里看数据
>
> 除此之外，把"用得到的字段写全"永远不亏。相关：[[Create Table]] 的"复制一张表"。

---

## 七、LIMIT 分页

三种写法，含义相同：

```sql
SELECT * FROM student ORDER BY id LIMIT 10;             -- 前 10 条
SELECT * FROM student ORDER BY id LIMIT 20, 10;         -- 跳过 20 条，取 10 条
SELECT * FROM student ORDER BY id LIMIT 10 OFFSET 20;   -- 同上，推荐这种
```

| 写法 | 语义 | 可读性 |
| --- | --- | --- |
| `LIMIT n` | 取前 n 条 | ✅ |
| `LIMIT offset, size` | 先 offset 后 size，==**顺序容易写反**== | ⚠️ |
| `LIMIT size OFFSET offset` | 先 size 后 offset | ✅ 推荐 |

第 `page` 页（从 1 开始）、每页 `size` 条：

```sql
-- 第 3 页，每页 10 条 → offset = (3 - 1) * 10 = 20
SELECT * FROM student ORDER BY id LIMIT 10 OFFSET 20;
```

> [!danger] 深分页：越翻越慢
> `LIMIT 1000000, 20` 会让 MySQL **先扫描并丢掉前 100 万行**，只为了给你 20 行。offset 越大越慢，耗时基本和 offset 成正比。
> 优化思路：**别用 offset，用"上一页的最后一条"当游标。**

```sql
-- ❌ 深分页：扫 1000020 行，丢弃 1000000 行
SELECT * FROM `order` ORDER BY id LIMIT 1000000, 20;

-- ✅ 游标分页：上一页最后一条 id = 1000000，直接定位，扫 20 行
SELECT * FROM `order` WHERE id > 1000000 ORDER BY id LIMIT 20;
```

> [!success] 游标分页的三个前提
> 1. 排序字段**唯一且单调**（主键 `id` 最合适）
> 2. 只能"上一页 / 下一页"，**不能跳页**——所以它适合无限滚动列表，不适合"跳到第 500 页"
> 3. 前端要把上一页最后一条的 id 带过来
>
> 有跳页需求 + 数据量大，就该考虑搜索引擎（ES）而不是硬扛 MySQL 了。

---

## 八、完整综合示例

### 8.1 建表 + 插数据

```sql
DROP TABLE IF EXISTS student;
CREATE TABLE student (
    id     BIGINT       NOT NULL AUTO_INCREMENT,
    name   VARCHAR(50)  NOT NULL,
    gender CHAR(1)      NOT NULL COMMENT 'M 男 / F 女',
    age    TINYINT      NOT NULL,
    score  DECIMAL(5,2) NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO student (name, gender, age, score) VALUES
('张三', 'M', 18, 88.50),
('李四', 'M', 19, 92.00),
('王五', 'F', 18, 76.00),
('赵六', 'F', 20, 92.00),
('钱七', 'M', 21, 60.50),
('孙八', 'F', 19, 84.00);
```

### 8.2 一条语句用全七个位置

```sql
SELECT gender AS 性别,
       COUNT(*) AS 人数,
       ROUND(AVG(score), 2) AS 平均分
FROM student
WHERE age >= 18
GROUP BY gender
HAVING COUNT(*) >= 2
ORDER BY 平均分 DESC
LIMIT 2;
```

各子句在这里的分工：

| 子句 | 这一步干了什么 |
| --- | --- |
| `FROM student` | 拿到 6 行原始数据 |
| `WHERE age >= 18` | 6 行年龄都 ≥ 18，**一行没滤掉** |
| `GROUP BY gender` | 折叠成 M / F 两组 |
| `HAVING COUNT(*) >= 2` | 两组人数都是 3，**两组都留** |
| `SELECT ... AS 平均分` | 这才开始算人数、算平均分，并起别名 |
| `ORDER BY 平均分 DESC` | 用别名排序，女生组在前 |
| `LIMIT 2` | 只有两组，原样返回 |

结果：

```
+--------+--------+----------+
| 性别   | 人数   | 平均分   |
+--------+--------+----------+
| F      |      3 |    84.00 |
| M      |      3 |    80.33 |
+--------+--------+----------+
2 rows in set (0.00 sec)
```

验算一下：女生 `(76 + 92 + 84) / 3 = 84.00`；男生 `(88.5 + 92 + 60.5) / 3 = 80.333...`，经 `ROUND(..., 2)` 得到 `80.33`。

> [!success] 把 LIMIT 改成 1 会怎样
> 只剩 `F | 3 | 84.00` 这一行——因为 `ORDER BY 平均分 DESC` 已经把它排到了第一位，`LIMIT 1` 拿到的是**排好序之后**的结果。
> 这正是"LIMIT 最后执行"的直接体现。

---

> [!quote] 一句话记忆
> **写的顺序是 SELECT→FROM→WHERE→GROUP BY→HAVING→ORDER BY→LIMIT，跑的顺序是 FROM→WHERE→GROUP BY→HAVING→SELECT→ORDER BY→LIMIT**；因为 SELECT 排在第五，所以**别名只能用在后半段（HAVING / ORDER BY）**，`WHERE` 里用别名必定 1054。

---

## 相关笔记

- [[From]] —— 数据从哪来，执行顺序的第一步
- [[Where]] —— 分组前逐行过滤
- [[Group By]] —— 把行折叠成组
- [[Having]] —— 分组之后再过滤
- [[Order By]] —— 结果集排序
- [[Join]] —— 多表查询
- [[Insert]] —— 数据怎么进去
- [[Create Table]] —— 建表与约束
