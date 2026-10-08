# WHERE —— 条件过滤

> [!abstract] 一句话
> `WHERE` 在**分组之前**逐行筛掉不满足条件的行——它是"**行级过滤器**"，执行位置在 `FROM` 之后、`GROUP BY` 之前。

---

## 一、语法与执行位置

```sql
SELECT 字段列表
FROM 表名
WHERE 条件表达式
GROUP BY ...
HAVING ...
```

| 阶段 | 子句 | 过滤单位 | 典型条件 |
| --- | --- | --- | --- |
| 1 | `FROM` | — | 拿到数据源 |
| 2 | `WHERE` | ==**一行**== | `age > 18` |
| 3 | `GROUP BY` | 一组 | — |
| 4 | `HAVING` | ==**一组**== | `COUNT(*) > 5` |

> [!danger] WHERE 里不能用聚合函数
> 写 `WHERE COUNT(*) > 5` 会直接报错：
> `ERROR 1111 (HY000): Invalid use of group function`
> 因为 `WHERE` 执行时**还没有分组**，`COUNT` 根本无从算起。想按"组"过滤，那是 [[计算机类/数据库/Mysql/DML/Having]] 的活。

```sql
-- ❌ 报错 ERROR 1111
SELECT gender, COUNT(*) FROM student WHERE COUNT(*) > 2 GROUP BY gender;

-- ✅ 分组之后再过滤
SELECT gender, COUNT(*) AS cnt FROM student GROUP BY gender HAVING cnt > 2;
```

> [!tip] WHERE 和 HAVING 的分工口诀
> **WHERE 管行，HAVING 管组。**
> 能用 `WHERE` 过滤的**一定优先用 `WHERE`**——它在分组前就把行砍掉了，参与分组和聚合的数据更少，性能更好。
> 只有涉及聚合结果（`COUNT` / `SUM` / `AVG`）或分组字段时，才轮到 `HAVING`。

---

## 二、比较运算符

| 运算符 | 含义 | 示例 |
| --- | --- | --- |
| `=` | 等于 | `WHERE gender = 'M'` |
| `!=` / `<>` | 不等于（==**两者完全等价**==） | `WHERE gender <> 'M'` |
| `>` `<` `>=` `<=` | 大小比较 | `WHERE age >= 18` |
| `<=>` | **安全等于**，能拿 NULL 做比较 | `WHERE remark <=> NULL` |

> [!warning] 字符串和日期一定要加引号
> `WHERE name = 张三` 少了引号，MySQL 会把 `张三` 当成一个**列名**去找，报：
> `ERROR 1054 (42S22): Unknown column '张三' in 'where clause'`
> 日期同理：`WHERE created_at >= '2026-09-01'`。

```sql
-- ❌ 1054
SELECT * FROM student WHERE name = 张三;
-- ✅
SELECT * FROM student WHERE name = '张三';
```

日期比较（推荐用范围，别对字段套函数）：

```sql
-- ✅ 能走索引：半开区间
SELECT * FROM `order` WHERE created_at >= '2026-09-01' AND created_at < '2026-10-01';

-- ⚠️ 字段被函数包住，索引失效（原因见 §八）
SELECT * FROM `order` WHERE DATE(created_at) = '2026-09-29';
```

---

## 三、逻辑运算符 AND / OR / NOT 与优先级陷阱

> [!danger] 优先级顺序：NOT > AND > OR
> `AND` 比 `OR` **先算**，就像乘法比加法先算一样。忘了这一点，条件会**静默跑偏**——不报错，结果就是错的，属于最难查的一类 bug。

经典反例：

```sql
-- 本意：年龄 > 18 且（性别男 或 性别女）—— 也就是"所有成年人"
-- 实际：MySQL 解析成 (age > 18 AND gender = 'M') OR (gender = 'F')
SELECT * FROM stu WHERE age > 18 AND gender = 'M' OR gender = 'F';
```

后果：**未成年的女生照样被查出来**，因为 `OR gender = 'F'` 独立成立。

```sql
-- ✅ 正确：加括号，让意图和解析一致
SELECT * FROM stu WHERE age > 18 AND (gender = 'M' OR gender = 'F');
```

> [!question] 那 `AND` 链里混了 `NOT` 呢？
> `NOT` 优先级最高，先作用于**紧挨着它的那个条件**。
> `WHERE NOT age > 18 AND gender = 'M'` 会被解析成 `(NOT age > 18) AND gender = 'M'`，没歧义，但读起来依然费劲。
> 经验法则：**只要一条 `WHERE` 里同时出现 `AND` 和 `OR`，就给每个 `OR` 分组加括号**——哪怕不加也对，加了是给下一个人看。

真值表（三值逻辑下的 `AND` / `OR`）：

| A | B | A AND B | A OR B |
| --- | --- | --- | --- |
| TRUE | TRUE | TRUE | TRUE |
| TRUE | FALSE | FALSE | TRUE |
| TRUE | UNKNOWN | **UNKNOWN** | TRUE |
| FALSE | FALSE | FALSE | FALSE |
| FALSE | UNKNOWN | FALSE | **UNKNOWN** |
| UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |

> [!important] 只有求值结果为 TRUE 的行才会留下
> `WHERE` 条件的结果有 **TRUE / FALSE / UNKNOWN** 三种。**UNKNOWN 等同于不通过**（行被丢弃）。
> 牢牢记住这一条，§六的 NULL 陷阱就全都解释通了。

---

## 四、范围与集合

### 4.1 BETWEEN ... AND ...

```sql
-- 等价于 age >= 18 AND age <= 25
SELECT * FROM student WHERE age BETWEEN 18 AND 25;
```

> [!warning] BETWEEN 是**闭区间**，两个端点都包含
> `age BETWEEN 18 AND 25` 就是 `18 <= age <= 25`。
> **坑在日期上**：`created_at BETWEEN '2026-09-01' AND '2026-09-29'` 只能覆盖到 9 月 29 日 **00:00:00**，当天 10 点的数据**查不到**。
> 正确做法是用半开区间：`>= '2026-09-01' AND < '2026-09-30'`。写成 `'2026-09-29 23:59:59'` 也不严谨，毫秒级的数据照样漏。

### 4.2 IN / NOT IN

```sql
SELECT * FROM student WHERE age IN (18, 19, 20);
SELECT * FROM student WHERE gender NOT IN ('M');
```

> [!danger] NOT IN + NULL：结果**永远为空**
> 只要括号里出现一个 `NULL`，`NOT IN` 的结果集就是**空集**——不报错，就是什么都查不出来。

```sql
-- 假设 sub 表里有一行 val 是 NULL
SELECT * FROM stu WHERE age NOT IN (SELECT val FROM sub);
-- 结果：Empty set

-- 因为 x NOT IN (1, 2, NULL) 等价于：
--   x <> 1 AND x <> 2 AND x <> NULL
-- 而 x <> NULL 的结果是 UNKNOWN，UNKNOWN AND 任何东西都不可能是 TRUE
```

> [!danger] `IN` 遇上 NULL 也别掉以轻心
> `x IN (1, 2, NULL)`：`x` 命中 1 或 2 就是 TRUE，没问题；
> 但 `x = 3` 时结果是 `FALSE OR FALSE OR UNKNOWN` = UNKNOWN，行被丢弃——单看这个还算符合预期。
> 真正会咬人的是**否定形式** `NOT IN`。

替代写法：

```sql
-- ✅ 方案一：先把 NULL 排除掉
SELECT * FROM stu
WHERE age NOT IN (SELECT val FROM sub WHERE val IS NOT NULL);

-- ✅ 方案二：改用 NOT EXISTS（NULL 天然安全，推荐）
SELECT * FROM stu AS s
WHERE NOT EXISTS (SELECT 1 FROM sub AS b WHERE b.val = s.age);
```

> [!tip] 为什么 `NOT EXISTS` 天然安全？
> 它判断的是"**子查询有没有返回行**"，返回 0 行就是 `NOT EXISTS = TRUE`，整个过程根本不涉及 `x <> NULL` 的比较。
> 记住：**`NOT IN` 是"跟列表里每个值挨个比一遍"，`NOT EXISTS` 是"找有没有匹配的行"**，后者没有这个坑。

---

## 五、模糊查询 LIKE

| 通配符 | 含义 |
| --- | --- |
| `%` | 匹配**任意个**（含 0 个）字符 |
| `_` | 匹配**恰好一个**字符 |

```sql
SELECT * FROM student WHERE name LIKE '张%';      -- 以"张"开头
SELECT * FROM student WHERE name LIKE '%三';      -- 以"三"结尾
SELECT * FROM student WHERE name LIKE '%三%';     -- 含"三"
SELECT * FROM student WHERE name LIKE '张_';      -- "张" + 恰好 1 个字符
SELECT * FROM student WHERE phone LIKE '138%';    -- 手机号前 3 位
```

数据与结果对照：

```
student 表
+--------+---------+-------------+
| id     | name    | phone       |
+--------+---------+-------------+
|      1 | 张三    | 13812345678 |
|      2 | 张三丰  | 13900001111 |
|      3 | 李四    | 13898765432 |
|      4 | 王小三  | 15900002222 |
+--------+---------+-------------+

WHERE name LIKE '张%'    → 张三、张三丰
WHERE name LIKE '张_'    → 张三          （张三丰是 3 个字，不匹配）
WHERE name LIKE '%三%'   → 张三、张三丰、王小三
WHERE phone LIKE '138%'  → 张三、李四
```

> [!warning] `_` 只能匹配**一个**字符
> 这是 `LIKE` 最常被搞错的地方：`'张_'` **不匹配** `'张三丰'`。
> 在 `utf8mb4` 下一个汉字算**一个字符**，所以 `'张_'` 能匹配 2 个字的 `'张三'`。
> 想匹配"张"开头的任意长度，用 `'张%'`。

转义：要查**字面量**的 `%` 或 `_`，用 `ESCAPE`：

```sql
-- 查包含"%"的备注，例如"需发票50%"
SELECT * FROM goods WHERE remark LIKE '%\%%' ESCAPE '\';

-- 查包含下划线的用户名，例如 user_name
SELECT * FROM user WHERE username LIKE '%\_%' ESCAPE '\';
```

> [!danger] 前导 `%` 会让索引直接失效
> `LIKE '%三%'` 和 `LIKE '%三'` 都以 `%` 开头，MySQL **没法用 B+ 树索引定位**（索引是按前缀有序的），只能**全表扫描**。
> 而 `LIKE '张%'` 是前缀匹配，**能走索引**。
> 大表上要做全文模糊搜索，正确工具是**全文索引**（`FULLTEXT`）或 Elasticsearch，不是硬扛 `LIKE '%...%'`。

---

## 六、NULL 判断（核心）

> [!danger] `NULL` 不是空字符串，也不是 0
> `NULL` 表示"**未知 / 没有值**"。任何拿 `NULL` 参与的算术或比较运算，结果都是 `NULL`（也就是 UNKNOWN）——**既不是 TRUE 也不是 FALSE**。

```sql
SELECT NULL = NULL;        -- 结果：NULL（不是 1！）
SELECT NULL <> NULL;       -- 结果：NULL
SELECT NULL != 1;          -- 结果：NULL
SELECT 1 = NULL;           -- 结果：NULL
SELECT NULL + 1;           -- 结果：NULL
SELECT CONCAT('a', NULL);  -- 结果：NULL（整个串变 NULL，不是 'a'）
SELECT NULL IS NULL;       -- 结果：1  ← 唯一可靠的判断方式
```

结果展示：

```
+-------------+
| NULL = NULL |
+-------------+
|        NULL |
+-------------+
1 row in set (0.00 sec)
```

> [!failure] 所以 `= NULL` 永远查不出数据
> `WHERE name = NULL` 返回 **Empty set**，哪怕表里真有 `name` 为 `NULL` 的行。
> 唯一正确的写法是 `IS NULL` / `IS NOT NULL`。

```sql
-- ❌ 永远空集
SELECT * FROM student WHERE name = NULL;

-- ✅ 正确
SELECT * FROM student WHERE name IS NULL;
SELECT * FROM student WHERE name IS NOT NULL;
```

### 6.1 安全等于 `<=>`

`<=>` 是 MySQL 的**安全等于**运算符：它能像 `=` 一样比较，但**把 NULL 当成一个普通值**，两边都是 NULL 时返回 `TRUE`（1）。

```sql
SELECT NULL <=> NULL;    -- 结果：1
SELECT NULL <=> 1;       -- 结果：0
SELECT 1 <=> 1;          -- 结果：1
```

| 表达式 | `=` 的结果 | `<=>` 的结果 |
| --- | --- | --- |
| `NULL = NULL` | `NULL` | **`1`** |
| `NULL = 1` | `NULL` | **`0`** |
| `1 = 1` | `1` | `1` |
| 能否用上索引 | ✅ | ⚠️ 一般可以，但语义反直觉，少用 |

> [!tip] `<=>` 的实用场景
> 比较两个可空字段是否"**真的相同**"（含都为 NULL 的情况）：`WHERE a.col <=> b.col`。
> 用 `a.col = b.col` 时两边都是 NULL 会得到 UNKNOWN，行被丢掉。
> 注意：`<=>` **不是标准 SQL**，是 MySQL / PostgreSQL 的方言，别写进需要跨库的代码里。

### 6.2 把 NULL 转成可比较的值

```sql
SELECT IFNULL(name, '匿名') FROM student;                 -- 两参，为 NULL 时取第二个
SELECT COALESCE(name, nickname, '匿名') FROM student;     -- 多参，返回第一个非 NULL
SELECT IF(gender IS NULL, '未知', gender) FROM student;   -- 条件式
```

> [!info] 什么时候该转换，什么时候不该
> - **展示层**：转。`IFNULL(remark, '')`，避免前端拿到 `null` 直接崩
> - **过滤层**：==**不要转**==。`WHERE IFNULL(name, '') = ''` 既让索引失效，又把"未知"和"空串"混为一谈
> - **分组统计**：留意 `COUNT(col)` **不数 NULL**，而 `COUNT(*)` 数。两者之差就是该列的 NULL 行数

---

## 七、别名不能用在 WHERE

```sql
-- ❌ 报错：ERROR 1054 (42S22): Unknown column 'next_age' in 'where clause'
SELECT name, age + 1 AS next_age
FROM student
WHERE next_age > 18;
```

> [!warning] 为什么？因为执行顺序
> `WHERE` 在 `SELECT` **之前**执行，`next_age` 这个别名**还没被创建出来**，MySQL 自然找不到它。
> 详见 [[Select]] 的"书写顺序 vs 执行顺序"章节。
> 能引用别名的子句只有 `HAVING` 和 `ORDER BY`——它们排在 `SELECT` 之后。

三种改法：

```sql
-- ✅ 方案一：把表达式重写一遍（最简单，代价是重复）
SELECT name, age + 1 AS next_age FROM student WHERE age + 1 > 18;

-- ✅ 方案二：套一层派生表，外层就能用别名了
SELECT * FROM (SELECT name, age + 1 AS next_age FROM student) AS t
WHERE t.next_age > 18;

-- ⚠️ 方案三：改用 HAVING（能跑，但语义模糊，不推荐）
SELECT name, age + 1 AS next_age FROM student HAVING next_age > 18;
```

> [!tip] 顺带一提：MySQL 允许 `GROUP BY` 用别名
> 这是 MySQL 的**扩展**，标准 SQL 不允许，可移植性差。而 `WHERE` 用别名，**任何版本都不允许**。

---

## 八、常用函数过滤：为什么别把函数套在字段上

```sql
-- ❌ 索引失效：字段被函数包住，B+ 树用不上
SELECT * FROM `order` WHERE DATE(created_at) = '2026-09-29';
SELECT * FROM `order` WHERE YEAR(created_at) = 2026;
SELECT * FROM user WHERE LEFT(phone, 3) = '138';

-- ✅ 改成范围 / 前缀，索引可用
SELECT * FROM `order`
WHERE created_at >= '2026-09-29 00:00:00' AND created_at < '2026-09-30 00:00:00';

SELECT * FROM `order` WHERE created_at >= '2026-01-01' AND created_at < '2027-01-01';
SELECT * FROM user WHERE phone LIKE '138%';
```

> [!important] 核心原则：**索引列上不要做运算**
> 不只是函数——`WHERE id + 1 = 100` 同样失效（应改成 `WHERE id = 99`）。
> 本质原因：B+ 树里存的是**字段的原始值**，你套了函数之后，树上的顺序和你要比的值对不上，只能一行行算。
> MySQL 8.0 支持**函数索引**（`CREATE INDEX idx ON t ((DATE(created_at)));`）能救回来，但那是最后的补丁，能改写法就改写法。

---

## 九、综合示例

### 9.1 建表 + 插数据

```sql
DROP TABLE IF EXISTS `orders`;
CREATE TABLE `orders` (
    id          BIGINT        NOT NULL AUTO_INCREMENT,
    order_no    CHAR(20)      NOT NULL,
    user_id     BIGINT        NOT NULL,
    amount      DECIMAL(10,2) NOT NULL,
    status      TINYINT       NOT NULL DEFAULT 0 COMMENT '0待付 1已付 2已发 3完成 4取消',
    remark      VARCHAR(100)  DEFAULT NULL,
    created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `orders` (order_no, user_id, amount, status, remark, created_at) VALUES
('NO20260901001', 1,  199.00, 3, NULL,        '2026-09-01 10:00:00'),
('NO20260901002', 1,   88.50, 1, '加急',      '2026-09-01 15:30:00'),
('NO20260902001', 2, 1299.00, 2, NULL,        '2026-09-02 09:10:00'),
('NO20260929001', 2,  520.00, 0, '需发票50%', '2026-09-29 11:20:00'),
('NO20260929002', 3,   60.00, 4, '客户取消',  '2026-09-29 18:45:00');
```

### 9.2 多条件组合查询

需求：查 **9 月 1 日到 9 月 30 日**之间、**已付 / 已发 / 完成**（status 1~3）、**金额 50 以上**的订单，按金额降序。

```sql
SELECT order_no, user_id, amount, status
FROM `orders`
WHERE created_at >= '2026-09-01 00:00:00'
  AND created_at <  '2026-10-01 00:00:00'
  AND status IN (1, 2, 3)
  AND amount >= 50
ORDER BY amount DESC;
```

各条件各过滤掉了哪些行：

| 条件 | 过滤掉的行 |
| --- | --- |
| `created_at >= '2026-09-01' AND < '2026-10-01'` | 无（5 行都在 9 月） |
| `status IN (1, 2, 3)` | `NO20260929001`（status 0）、`NO20260929002`（status 4） |
| `amount >= 50` | 无 |
| **最终保留** | **3 行** |

结果：

```
+----------------+---------+---------+--------+
| order_no       | user_id | amount  | status |
+----------------+---------+---------+--------+
| NO20260902001  |       2 | 1299.00 |      2 |
| NO20260901001  |       1 |  199.00 |      3 |
| NO20260901002  |       1 |   88.50 |      1 |
+----------------+---------+---------+--------+
3 rows in set (0.00 sec)
```

### 9.3 同一条 SQL 的"陷阱版"改写

```sql
-- 本意：查备注不在黑名单里的订单
-- ❌ 结果空集（因为括号里带了 NULL）
SELECT * FROM `orders` WHERE remark NOT IN ('加急', NULL);
-- ✅ 正确：把 NULL 单独处理
SELECT * FROM `orders` WHERE remark IS NULL OR remark NOT IN ('加急');
```

---

> [!quote] 一句话记忆
> **WHERE 管行、HAVING 管组**；**NOT > AND > OR**，混用时一定给 `OR` 加括号；**`= NULL` 查不出任何东西**，只能 `IS NULL`；**`NOT IN` 带 NULL 结果必空**，换 `NOT EXISTS`；**别在索引列上套函数**，`%` 开头会让索引失效。

---

## 相关笔记

- [[Select]] —— 全子句与执行顺序（别名为什么不能在 WHERE 里用）
- [[From]] —— 数据源从哪来
- [[计算机类/数据库/Mysql/DML/Having]] —— 分组之后的过滤
- [[计算机类/数据库/Mysql/DML/Group By]] —— 分组统计
- [[Order By]] —— 结果集排序
- [[Join]] —— 多表连接的连接条件
- [[Update]] · [[Delete]] —— 同样带 WHERE，写错就是全表事故
