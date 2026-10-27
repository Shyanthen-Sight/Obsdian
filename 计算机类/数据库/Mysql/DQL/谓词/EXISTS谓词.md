# EXISTS 谓词 —— 存在性判断

> [!abstract] 一句话
> `EXISTS (子查询)` 只问一件事：==**子查询有没有返回至少一行**==。有就是 `TRUE`，没有就是 `FALSE`，**永远不会返回 UNKNOWN**。
> 它天生适合"有没有 / 是不是空"这类判断，而且==**`NOT EXISTS` 是 NULL 安全的反连接写法**==。

> [!info] 与其它笔记的分工
> 子查询的分类见 [[嵌套查询]]；相关子查询的执行模型见 [[相关子查询]]。
> `IN` 的 NULL 陷阱见 [[IN谓词]]；`NOT IN` 的替代写法也在这里。
> 本篇聚焦 `EXISTS` 作为**谓词**的语义、相关写法与性能。

---

## 一、语法与语义

```sql
EXISTS (subquery)
NOT EXISTS (subquery)
```

```sql
SELECT * FROM dept d
WHERE EXISTS (SELECT 1 FROM emp e WHERE e.dept_id = d.dept_id);
```

> [!important] `EXISTS` 只看"有没有行"，不看"选了什么列"
> 内层写 `SELECT 1`、`SELECT *`、`SELECT NULL` 完全等价。
> 因为 `EXISTS` 的判断依据是**结果集是否为空**，不是列的值。
> 约定俗成写 `SELECT 1`，最省事、最不容易误解。

```sql
-- 以下三条完全等价
WHERE EXISTS (SELECT 1 FROM emp e WHERE e.dept_id = d.dept_id)
WHERE EXISTS (SELECT * FROM emp e WHERE e.dept_id = d.dept_id)
WHERE EXISTS (SELECT NULL FROM emp e WHERE e.dept_id = d.dept_id)
```

---

## 二、相关 vs 非相关

### 2.1 相关 `EXISTS`（最常见）

内层引用外层列，外层每行执行一次：

```sql
-- 找出"有员工"的部门
SELECT d.dept_name
FROM dept d
WHERE EXISTS (SELECT 1 FROM emp e WHERE e.dept_id = d.dept_id);
-- → 研发部、销售部
```

执行模型：

```text
for 外层 dept 的每一行 d:
    执行内层: SELECT 1 FROM emp e WHERE e.dept_id = d.dept_id
    只要内层返回 >= 1 行，就保留 d
```

### 2.2 非相关 `EXISTS`

内层不引用外层，只算一次：

```sql
-- 只要 emp 表非空，所有部门都返回
SELECT * FROM dept
WHERE EXISTS (SELECT 1 FROM emp);
```

> [!warning] 非相关 `EXISTS` 常是"逻辑写错"的信号
> 它要么恒真（子查询非空），要么恒假（子查询为空），和外表没有关系。
> 除非你确实想表达"表非空时执行某查询"，否则检查是不是漏写了关联条件。

---

## 三、`NOT EXISTS`：NULL 安全的反连接

```sql
-- 找出"没有员工"的部门
SELECT d.dept_name
FROM dept d
WHERE NOT EXISTS (SELECT 1 FROM emp e WHERE e.dept_id = d.dept_id);
-- → 财务部
```

> [!tip] 为什么 `NOT EXISTS` 天然 NULL 安全
> 它只判断"内层有没有行"：
> - 内层返回 0 行 → `NOT EXISTS` = TRUE；
> - 内层返回 ≥1 行 → `NOT EXISTS` = FALSE。
> 整个过程**不涉及 `x <> NULL` 的比较**，所以不会被 NULL 搞成 UNKNOWN。
> 对比 `NOT IN`：后者要逐个比较值，遇到 NULL 就完蛋。见 [[IN谓词]]。

### 3.1 三种"找缺失"的写法

```sql
-- ① NOT EXISTS（推荐）
SELECT d.* FROM dept d
WHERE NOT EXISTS (SELECT 1 FROM emp e WHERE e.dept_id = d.dept_id);

-- ② LEFT JOIN + IS NULL（反连接）
SELECT d.* FROM dept d
LEFT JOIN emp e ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;

-- ③ NOT IN（要记得过滤 NULL）
SELECT d.* FROM dept d
WHERE d.dept_id NOT IN (
    SELECT dept_id FROM emp WHERE dept_id IS NOT NULL
);
```

| 写法 | NULL 安全 | 可读性 | 性能 |
| --- | --- | --- | --- |
| `NOT EXISTS` | ✅ | 好 | 好（内层关联列有索引时） |
| `LEFT JOIN ... IS NULL` | ✅ | 中 | 好 |
| `NOT IN` | ❌（除非过滤 NULL） | 好 | 可能差 |

---

## 四、查询逻辑过程梳理

一条 `EXISTS` 查询，从"人话"到"结果"要经过四层：**自然语言 → 形式逻辑 → SQL → 逐行判定**。按这个顺序过一遍，逻辑就不会糊。

### 4.1 从需求到逻辑式

需求：**找出有员工的部门**。

```text
自然语言：部门表里，凡"存在"至少一名员工的部门
形式逻辑：{ d ∈ dept | ∃ e ∈ emp : e.dept_id = d.dept_id }
```

`∃`（存在量词）就是 `EXISTS` 这个名字要表达的东西：不关心"有几个、是谁"，只关心"存不存在"。

| 层次 | 对应内容 |
| --- | --- |
| 自然语言 | 有员工的部门 |
| 形式逻辑 | 存在 `e ∈ emp`，使 `e.dept_id = d.dept_id` |
| SQL 外层 | `FROM dept d` —— 遍历候选行 |
| SQL 内层 | `WHERE e.dept_id = d.dept_id` —— 每行代入的关联条件 |
| SQL 谓词 | `WHERE EXISTS (...)` —— 把"存在"折算成 TRUE / FALSE |

### 4.2 逐行推导（用示例数据跑一遍）

```sql
SELECT d.dept_name FROM dept d
WHERE EXISTS (SELECT 1 FROM emp e WHERE e.dept_id = d.dept_id);
```

```text
for 外层每一行 d:
    取 d.dept_id，代入内层
    内层在 emp 里找 e.dept_id = d.dept_id 的第一行
    找到  → EXISTS = TRUE，保留 d，并停止内层扫描（短路）
    找不到 → EXISTS = FALSE，丢弃 d
```

| 外层行 `d` | 代入后的内层条件 | 内层命中 | `EXISTS` | 动作 |
| --- | --- | --- | --- | --- |
| 1001 研发部 | `e.dept_id = 1001` | 张三（第一行，短路） | TRUE | 保留 |
| 1002 销售部 | `e.dept_id = 1002` | 王五（第一行，短路） | TRUE | 保留 |
| 1003 财务部 | `e.dept_id = 1003` | 无 | FALSE | 丢弃 |

→ 结果：**研发部、销售部**。

> [!important] 孙七在哪一步被排除的
> 孙七的 `dept_id` 是 `NULL`，`NULL = 1003` 得到 `UNKNOWN`，这一行**不算匹配**。
> 但关键在于：这个 `UNKNOWN` 只发生在**内层的行过滤**里，==**不会传到外层**==——内层最终是"0 行"还是"若干行"，是确定的。
> `EXISTS` 问的是"集合空不空"，不是"某个值等不等于 NULL"，所以 NULL 污染不了它。

### 4.3 反过来的 `NOT EXISTS`

内层一模一样，只是把判定取反：

| 外层行 `d` | 内层行数 | `EXISTS` | `NOT EXISTS` | 结果 |
| --- | --- | --- | --- | --- |
| 1001 研发部 | 2 | TRUE | FALSE | 不保留 |
| 1002 销售部 | 2 | TRUE | FALSE | 不保留 |
| 1003 财务部 | 0 | FALSE | TRUE | **保留** |

→ 结果：**财务部**。逻辑上就是 `∃` 的否定 `¬∃`，全程没有"值比较"参与，NULL 无从下手。

### 4.4 这套推导的三个不变量

| 不变量 | 含义 | 写错时的表现 |
| --- | --- | --- |
| **外层驱动** | 外层每行把值代入内层重算一次 | 漏写关联条件 → 内层变成常量（见 2.2 的非相关 `EXISTS`） |
| **只看有无** | 内层有 ≥1 行即 TRUE，不看列、不看行数 | 纠结 `SELECT 1` 与 `SELECT *` 的区别 |
| **短路** | 命中第一行就停 | 用 `COUNT(*) > 0` 代替，白扫全量 |

> [!note] 逻辑过程 ≠ 实际执行
> 上面推导的是**逻辑语义**，保证结果正确；真实执行可能被优化器改写成 semi-join，一次扫描完成（见「性能」一节）。
> 先按逻辑想清楚"该保留哪些行"，再用 `EXPLAIN` 验证性能。

---

## 五、`EXISTS` vs `IN` vs `JOIN`

| 维度 | `EXISTS` | `IN` | `JOIN` |
| --- | --- | --- | --- |
| 判断依据 | 子查询是否有行 | 值是否在集合中 | 两表是否匹配 |
| NULL 安全 | ✅（包括 `NOT EXISTS`） | `NOT IN` 不安全 | ✅（配合 `LEFT JOIN`） |
| 是否产生重复 | 否 | 否 | 可能，需要 `DISTINCT` |
| 是否需要取内层列 | 否 | 否 | 是 |
| 典型场景 | 存在性、反连接 | 小列表、单列集合 | 需要多列 |
| 短路 | ✅ 找到一行即停止 | 不一定 | 不适用 |

```sql
-- 需求：找出有员工的部门（三种写法）
-- EXISTS
SELECT d.* FROM dept d
WHERE EXISTS (SELECT 1 FROM emp e WHERE e.dept_id = d.dept_id);

-- IN
SELECT d.* FROM dept d
WHERE d.dept_id IN (SELECT e.dept_id FROM emp e);

-- JOIN + DISTINCT
SELECT DISTINCT d.* FROM dept d
JOIN emp e ON e.dept_id = d.dept_id;
```

> [!note] 优化器可能把它们改写成同一种计划
> MySQL 常把 `IN` 子查询和 `EXISTS` 改写成 **semi-join**。
> 但语义上仍有差别：`NOT IN` 的 NULL 陷阱不会因为优化器而消失。
> **写对语义优先，性能交给 `EXPLAIN` 验证。**

---

## 六、性能：`EXISTS` 为什么常常不慢

### 6.1 短路特性

```sql
EXISTS (SELECT 1 FROM emp e WHERE e.dept_id = d.dept_id)
```

内层只要找到**第一行匹配**就返回 TRUE，不再继续扫描。
对于"有大量匹配"的存在性判断，这比 `COUNT(*) > 0` 快得多：

```sql
-- ❌ 要数完所有匹配行
WHERE (SELECT COUNT(*) FROM emp e WHERE e.dept_id = d.dept_id) > 0

-- ✅ 找到一行就停
WHERE EXISTS (SELECT 1 FROM emp e WHERE e.dept_id = d.dept_id)
```

### 6.2 索引是关键

```sql
-- 内层关联列建索引
ALTER TABLE emp ADD INDEX idx_dept (dept_id);
```

没有索引时，外层每一行都要全表扫描 `emp`，复杂度是 `外层行数 × 内层行数`。

### 6.3 看执行计划

```sql
EXPLAIN SELECT d.dept_name FROM dept d
WHERE EXISTS (SELECT 1 FROM emp e WHERE e.dept_id = d.dept_id);
```

关注：

- `select_type` 是否出现 `DEPENDENT SUBQUERY`（逐行执行）；
- 是否被改写为 `semi join`；
- 内层是否用上了 `idx_dept`。

> [!warning] `DEPENDENT SUBQUERY` 不一定是坏事
> 对"存在性"判断，逐行 + 短路 + 索引查找，往往已经足够快。
> 真正要警惕的是**内层没有索引 + 外层行数很大**。

---

## 七、常见错误合集

> [!failure] 在 `EXISTS` 内层写 `SELECT` 多列并以为有意义
> `EXISTS` 不看列，写 `SELECT *` 也不会多传数据。写 `SELECT 1` 是约定。

> [!failure] 忘了写关联条件
> ```sql
> -- ❌ 非相关：emp 非空时恒真，所有部门都返回
> WHERE EXISTS (SELECT 1 FROM emp)
> ```
> 检查内层是否引用了外层别名。

> [!failure] 用 `NOT IN` 代替 `NOT EXISTS`
> 子查询含 NULL 时 `NOT IN` 恒为空集。见 [[IN谓词]]。

> [!failure] 用 `COUNT(*) > 0` 代替 `EXISTS`
> 前者要数完，后者找到一行就停。存在性判断优先 `EXISTS`。

> [!failure] 以为 `EXISTS` 会返回 UNKNOWN
> 不会。它只有 TRUE / FALSE，这是它 NULL 安全的根本原因。

> [!failure] 在 `NOT EXISTS` 里把条件写到外面
> ```sql
> -- ❌ 条件写错位置，逻辑变了
> WHERE NOT EXISTS (SELECT 1 FROM emp e) AND e.dept_id = d.dept_id
> ```
> 关联条件必须在子查询内部。

---

## 八、速查表

| 需求 | 写法 |
| --- | --- |
| 存在匹配行 | `EXISTS (SELECT 1 FROM t WHERE t.k = outer.k)` |
| 不存在匹配行 | `NOT EXISTS (SELECT 1 FROM t WHERE t.k = outer.k)` |
| 判断子查询非空 | `EXISTS (SELECT 1 FROM t)` |
| 找"有员工的部门" | `WHERE EXISTS (...)` |
| 找"没员工的部门" | `WHERE NOT EXISTS (...)` |
| 替代 `NOT IN` | `NOT EXISTS`（NULL 安全） |
| 替代 `COUNT(*) > 0` | `EXISTS`（短路更快） |
| 检查是否逐行 | `EXPLAIN` 看 `DEPENDENT SUBQUERY` |

> [!question] 自测三连
> 1. `EXISTS` 的内层写 `SELECT 1` 和 `SELECT *` 有区别吗？为什么？
> 2. 为什么 `NOT EXISTS` 是 NULL 安全的，而 `NOT IN` 不是？
> 3. `EXISTS` 为什么通常比 `COUNT(*) > 0` 快？

---

> [!quote] 一句话记忆
> **`EXISTS` 只问子查询有没有行，永远 TRUE/FALSE，内层写 `SELECT 1` 即可；`NOT EXISTS` 是 NULL 安全的反连接首选；存在性判断靠短路，内层关联列要建索引。**

---

## 九、双层嵌套实例

需求：**找出至少有两名员工的部门**。这是"至少 N 个"的典型写法——要找 N 个不同的行，就套 N 层 `EXISTS`。

```sql
SELECT d.dept_name
FROM dept d
WHERE EXISTS (                                   -- 第一层：存在员工 e
    SELECT 1
    FROM emp e
    WHERE e.dept_id = d.dept_id
      AND EXISTS (                               -- 第二层：存在"另一个"员工 x
          SELECT 1
          FROM emp x
          WHERE x.dept_id = e.dept_id
            AND x.emp_id <> e.emp_id
      )
);
```

### 9.1 结构拆解

| 层 | 位置 | 引用谁 | 回答的问题 |
| --- | --- | --- | --- |
| 外层 | `FROM dept d` | — | 哪些部门？ |
| 第一层 | `EXISTS (FROM emp e ...)` | `d.dept_id` | 这个部门有没有员工？ |
| 第二层 | `EXISTS (FROM emp x ...)` | `e.dept_id`、`e.emp_id` | 除这名员工外，还有没有别人？ |

> [!important] 作用域由内向外可见
> `x` 能看见 `e` 和 `d`，`e` 能看见 `d`，反过来不行。
> 两层查的是同一张 `emp`，必须用**不同别名**（`e` / `x`）区分，否则没法表达"另一名员工"。

### 9.2 逐层求值

```text
外层 d 取 1001 研发部
└─ 第一层：在 emp 里找 e.dept_id = 1001
   ├─ e = 张三（emp_id 1）
   │  └─ 第二层：找 x.dept_id = 1001 且 x.emp_id <> 1
   │     └─ 命中 李四（emp_id 2）→ 第二层 TRUE，停止扫描
   └─ 第一层 TRUE → 停止扫描
→ 保留 1001
```

逐行验证：

| 外层 d | 第一层命中 `e` | 第二层命中 `x` | 第一层 | 结果 |
| --- | --- | --- | --- | --- |
| 1001 研发部 | 张三 | 李四（`2 ≠ 1`） | TRUE | 保留 |
| 1002 销售部 | 王五 | 赵六（`4 ≠ 3`） | TRUE | 保留 |
| 1003 财务部 | 无 | — | FALSE | 丢弃 |

→ 结果：**研发部、销售部**。

> [!note] 本例结果与"有员工的部门"相同，但逻辑不同
> 因为两个有人的部门都恰好有 2 名员工。把研发部改成只剩张三：第一层仍命中，但第二层找不到 `emp_id <> 1` 的人 → 研发部就会消失。
> **结果相同不代表逻辑相同**——第二层管的是"人数够不够"，不是"有没有人"。

### 9.3 第二层换成标量子查询

第二层不一定是 `EXISTS`，也可以是一个**返回单值**的子查询。例如"至少有一名员工工资高于全表平均工资"：

```sql
SELECT d.dept_name
FROM dept d
WHERE EXISTS (
    SELECT 1
    FROM emp e
    WHERE e.dept_id = d.dept_id
      AND e.salary > (SELECT AVG(salary) FROM emp)   -- 第二层：标量，只算一次
);
```

全表平均 = `(12000+15000+9000+8500+7000) / 5 = 10300`。

| 外层 d | 内层候选 | `salary > 10300` | `EXISTS` | 结果 |
| --- | --- | --- | --- | --- |
| 1001 研发部 | 张三 12000 | ✓（命中即停） | TRUE | 保留 |
| 1002 销售部 | 王五 9000 / 赵六 8500 | ✗ / ✗ | FALSE | 丢弃 |
| 1003 财务部 | 无 | — | FALSE | 丢弃 |

→ 结果：**研发部**。

> [!tip] 两层子查询，要分清"相关"和"非相关"
> `EXISTS` 那层引用了 `d.dept_id`，是**相关**的，外层每行重算一次；
> `AVG` 那层谁都不引用，是**非相关**的，整个查询只算一次（逻辑上先算成常量 10300）。
> 混在一起时，==**先找能独立跑的那层当常量，再逐层向外看谁引用了谁**==，顺序就不会乱。

### 9.4 嵌套时最容易踩的坑

> [!failure] 第二层返回多行，却用标量比较
> ```sql
> -- ❌ 子查询返回 5 行，`>` 无法比较
> ... AND e.salary > (SELECT salary FROM emp)
> ```
> 要么用聚合/`MAX` 压成单值，要么改用 `EXISTS` / `IN` / `ANY` / `ALL`（见 [[嵌套查询]] 的分类表）。
> 一句话：**子查询的返回形态必须匹配外面的用法**。

> [!failure] 内层漏写别名，关联条件悄悄失效
> ```sql
> -- ❌ 本意是 x.dept_id = e.dept_id；右边没写别名，
> --    按"就近原则"解析成 x.dept_id，条件变成 x.dept_id = x.dept_id（非 NULL 行恒真）
> WHERE x.dept_id = dept_id
> ```
> 内外层同时出现同名列时，**引用外层就显式写外层别名**，别依赖解析规则。

> [!warning] 层数不是越多越好
> 每多一层相关子查询，就多一层"外层每行 × 内层"的放大。能改成 `JOIN` / `GROUP BY` / 窗口函数的优先改写；
> 双层 `EXISTS` 直观，但性能仍要看 `EXPLAIN`（见「性能」一节）。

---

## 相关笔记

- [[IN谓词]] —— `IN` / `NOT IN` 与 NULL 陷阱
- [[量化比较谓词]] —— `ANY` / `ALL` 与 `EXISTS` 的区别
- [[嵌套查询]] —— 子查询的分类与形态
- [[相关子查询]] —— 相关执行模型与性能
- [[LEFT JOIN]] · [[INNER JOIN]] —— 半连接/反连接的 JOIN 写法
- [[空值谓词]] —— NULL 与三值逻辑
- [[Where]] —— 条件过滤
