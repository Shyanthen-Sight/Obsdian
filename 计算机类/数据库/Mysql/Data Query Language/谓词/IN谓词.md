# IN 谓词 —— 集合成员判断

> [!abstract] 一句话
> `expr IN (值1, 值2, ...)` 判断 `expr` 是否**等于集合中的任意一个值**，等价于一串 `OR` 连接的等值比较。
> 它写起来短、读起来清楚，但==**`NOT IN` 遇到 NULL 会让整个结果变成空集**==——这是 SQL 最著名的静默陷阱之一。

> [!info] 与其它笔记的分工
> 本篇讲 `IN` / `NOT IN` 的列表形式与子查询形式、NULL 陷阱、索引与替代方案。
> 子查询的整体分类见 [[嵌套查询]]；`NOT EXISTS` 的相关写法见 [[相关子查询]]。
> 普通等值比较见 [[比较谓词]]。

---

## 一、语法：两种形态

```sql
-- 形态一：值列表
expr IN (value1, value2, ...)

-- 形态二：子查询（必须只返回一列）
expr IN (SELECT col FROM ...)
```

```sql
-- 列表
SELECT * FROM student WHERE age IN (18, 19, 20);

-- 子查询
SELECT * FROM emp WHERE dept_id IN (SELECT dept_id FROM dept WHERE dept_name LIKE '%部');
```

> [!important] 子查询必须只返回一列
> `IN (SELECT a, b FROM t)` 会报错：
> `ERROR 1241 (21000): Operand should contain 1 column(s)`
> 因为 `IN` 是"一个值是否等于集合里的某个值"，集合只能是一列。

---

## 二、等价展开：`IN` 就是多个 `OR`

```sql
WHERE age IN (18, 19, 20)
-- 等价于
WHERE age = 18 OR age = 19 OR age = 20
```

```sql
WHERE age NOT IN (18, 19, 20)
-- 等价于
WHERE age <> 18 AND age <> 19 AND age <> 20
```

> [!note] 为什么否定形式变成 `AND`
> `NOT (A OR B OR C)` 按德摩根定律等于 `NOT A AND NOT B AND NOT C`。
> 这个展开是理解 `NOT IN` NULL 陷阱的关键。

---

## 三、`NOT IN` + NULL：结果永远为空

> [!danger] 列表里只要有一个 NULL，`NOT IN` 就查不出任何数据
> ```sql
> -- 假设 sub 表的 val 列有一行是 NULL
> SELECT * FROM stu WHERE age NOT IN (SELECT val FROM sub);
> -- 结果：Empty set
> ```

推导过程：

```text
age NOT IN (1, 2, NULL)
= age <> 1 AND age <> 2 AND age <> NULL
= age <> 1 AND age <> 2 AND UNKNOWN
```

无论 `age` 是多少：

- `age` 命中 1 或 2 → 前面的 `<>` 为 FALSE → 整个 `AND` 为 FALSE；
- `age` 不命中 → 前两个为 TRUE，但 `age <> NULL` 是 **UNKNOWN** → `TRUE AND UNKNOWN` = **UNKNOWN**。

`WHERE` 只保留 TRUE，所以**一行都不会返回**。

```sql
-- ❌ 只要子查询里有 NULL，结果必空
SELECT * FROM stu WHERE age NOT IN (SELECT val FROM sub);

-- ✅ 方案一：先过滤 NULL
SELECT * FROM stu
WHERE age NOT IN (SELECT val FROM sub WHERE val IS NOT NULL);

-- ✅ 方案二：改用 NOT EXISTS（NULL 天然安全，推荐）
SELECT * FROM stu AS s
WHERE NOT EXISTS (SELECT 1 FROM sub AS b WHERE b.val = s.age);
```

> [!tip] 为什么 `NOT EXISTS` 安全
> `NOT EXISTS` 只判断"子查询有没有返回行"，返回 0 行就是 TRUE，**不涉及 `x <> NULL` 的比较**。
> 详见 [[EXISTS谓词]]。

### 3.1 肯定形式 `IN` 遇到 NULL 呢

```sql
SELECT 1 IN (1, NULL);   -- 1（TRUE，命中 1）
SELECT 2 IN (1, NULL);   -- NULL（UNKNOWN，不确定是否等于 NULL）
SELECT 2 NOT IN (1, NULL); -- NULL（UNKNOWN，被 WHERE 丢弃）
```

> [!note] `IN` 的肯定形式通常"看起来正常"
> 命中时返回 TRUE，没命中但列表含 NULL 时返回 UNKNOWN（被丢弃），结果往往符合"没命中就不要"的直觉。
> **真正会咬人的是否定形式 `NOT IN`。**

---

## 四、`IN` 与子查询：半连接

```sql
-- 找出"有员工"的部门
SELECT * FROM dept
WHERE dept_id IN (SELECT dept_id FROM emp);
```

语义上等价于：

```sql
SELECT DISTINCT d.*
FROM dept d
JOIN emp e ON d.dept_id = e.dept_id;
```

> [!info] 优化器可能改写成 semi-join
> MySQL 常把 `IN (子查询)` 改写为**半连接（semi-join）**，只判断"是否存在匹配"，不产生重复行。
> 用 `EXPLAIN` 可以看到 `semi join` 或 `FirstMatch` 等策略。
> 但**不要假设一定改写**：相关子查询、`NOT IN`、含 NULL 的场景可能退化成逐行执行。

---

## 五、`IN` vs `EXISTS` vs `JOIN`

| 维度 | `IN` | `EXISTS` | `JOIN` |
| --- | --- | --- | --- |
| 关注点 | 值是否在集合中 | 是否存在匹配行 | 取两张表的列 |
| NULL 安全 | `NOT IN` 不安全 | ✅ 安全 | `LEFT JOIN ... IS NULL` 安全 |
| 重复行 | 不产生重复 | 不产生重复 | 可能产生重复，需 `DISTINCT` |
| 典型场景 | 小列表、单列子查询 | 存在性判断 | 需要另一张表的列 |
| 索引 | 外层列/子查询列都可能用 | 内层关联列建索引 | 连接列建索引 |

> [!tip] 选择建议
> 1. **小规模固定列表** → `IN (1,2,3)`，最直观。
> 2. **"有没有"的存在性判断** → `EXISTS` / `NOT EXISTS`。
> 3. **需要另一张表的多列** → `JOIN`。
> 4. **否定 + 子查询** → 优先 `NOT EXISTS`，别用 `NOT IN`。

---

## 六、行构造器形式的 `IN`

MySQL 支持"多个列一起比"：

```sql
SELECT * FROM emp
WHERE (dept_id, salary) IN ((1001, 12000), (1002, 9000));
```

等价于：

```sql
WHERE (dept_id = 1001 AND salary = 12000)
   OR (dept_id = 1002 AND salary = 9000)
```

> [!warning] 行构造器的 NULL 语义更绕
> `(a, b) IN ((1, 2), (3, 4))` 在任一列为 NULL 时可能得到 UNKNOWN。
> 业务代码里除非确实需要"整行匹配"，否则拆成普通 `AND` / `OR` 更易读。

---

## 七、`IN ()` 空列表

```sql
-- ❌ 语法错误
SELECT * FROM student WHERE age IN ();
```

MySQL 不允许空的 `IN ()`。如果列表是动态拼接的，**列表为空时要单独处理**：

```sql
-- 列表为空时，直接返回空结果，或跳过该条件
WHERE 1 = 0
```

> [!warning] 动态 SQL 的经典 bug
> 拼接 `IN (${ids})` 时，如果 `ids` 为空，会生成 `IN ()` 直接报错。
> 正确做法：为空时短路（`WHERE 1=0`），或改用 `IN (NULL)` 之类需谨慎的写法——但 `IN (NULL)` 永远不匹配，语义不等于"空列表"。

---

## 八、类型转换与索引

### 8.1 类型转换

`IN` 的每个值都会和 `expr` 做等值比较，所以**隐式转换规则同样适用**：

```sql
-- phone 是 VARCHAR
WHERE phone IN (13812345678, 13900001111)   -- ⚠️ 数字会触发转换，索引可能失效
WHERE phone IN ('13812345678', '13900001111') -- ✅ 类型对齐
```

### 8.2 索引

| 写法 | 索引 |
| --- | --- |
| `col IN (1, 2, 3)` | ✅ 多个等值查找，通常可走 |
| `col IN (SELECT ...)` | ✅ 可能走 semi-join + 索引 |
| `col NOT IN (...)` | ⚠️ 否定条件，多半全表 |
| `col IN (1, 2, ... 10000 个)` | ⚠️ 列表过大，优化器可能放弃索引 |
| `varchar_col IN (数字...)` | ⚠️ 隐式转换可能失效 |

> [!tip] 超大列表怎么办
> 几千个以上的 `IN` 值，性能通常不如**建临时表 / 用 `JOIN`**：
> ```sql
> -- 把 ID 列表灌进临时表，再 JOIN
> SELECT t.* FROM target t JOIN tmp_ids i ON t.id = i.id;
> ```
> 这样只用一次索引查找，也避免超长 SQL 解析开销。

---

## 九、常见错误合集

> [!failure] `NOT IN` 子查询含 NULL → 空集
> 最经典的坑。改 `NOT EXISTS` 或先 `WHERE col IS NOT NULL`。

> [!failure] 子查询返回多列
> `IN (SELECT a, b FROM t)` 报 `1241`。`IN` 只接受单列。

> [!failure] 空列表 `IN ()`
> 语法错误。动态拼接时先判空。

> [!failure] 字符串列表忘加引号
> `IN (张三, 李四)` 会被当成列名，报 `Unknown column`。

> [!failure] 以为 `IN` 会去重
> `IN` 只是成员判断，不改变结果行数；需要去重时用 `DISTINCT`。

> [!failure] 用 `IN` 做"全部匹配"
> `IN` 是"等于任意一个"，不是"包含所有"。要"同时包含"需用 `AND` 或多个 `EXISTS`。

---

## 十、速查表

| 需求 | 写法 |
| --- | --- |
| 属于列表 | `col IN (v1, v2, v3)` |
| 不属于列表 | `col NOT IN (v1, v2, v3)` |
| 属于子查询结果 | `col IN (SELECT c FROM t)` |
| 安全的不属于 | `NOT EXISTS (SELECT 1 FROM t WHERE t.c = outer.col)` |
| 先过滤 NULL 的 `NOT IN` | `col NOT IN (SELECT c FROM t WHERE c IS NOT NULL)` |
| 多列整体匹配 | `(a, b) IN ((1,2), (3,4))` |
| 空列表 | 不要写 `IN ()`，用 `WHERE 1=0` 短路 |
| 超大列表 | 临时表 + `JOIN` |

> [!question] 自测三连
> 1. `age NOT IN (1, 2, NULL)` 为什么一行都查不出来？展开推导一遍。
> 2. `IN`、`EXISTS`、`JOIN` 各自适合什么场景？
> 3. 动态拼接 `IN` 列表时，空列表和类型转换分别要注意什么？

---

> [!quote] 一句话记忆
> **`IN` 是多个 `OR` 等值比较；`NOT IN` 是多个 `AND` 不等比较，遇到 NULL 必成空集，所以否定子查询优先 `NOT EXISTS`；子查询只能返回一列，空列表不能写 `IN ()`。**

---

## 相关笔记

- [[比较谓词]] —— `=` 与隐式类型转换
- [[EXISTS谓词]] —— NULL 安全的存在性判断
- [[量化比较谓词]] —— `= ANY` 等价于 `IN`
- [[空值谓词]] —— NULL 与三值逻辑
- [[嵌套查询]] · [[相关子查询]] —— 子查询形态
- [[INNER JOIN]] · [[LEFT JOIN]] —— `IN` 的连接式替代
- [[Where]] —— `NOT IN` 的 NULL 陷阱
