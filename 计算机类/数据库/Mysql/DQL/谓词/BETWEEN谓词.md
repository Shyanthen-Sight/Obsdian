# BETWEEN 谓词 —— 闭区间判断

> [!abstract] 一句话
> `expr BETWEEN a AND b` 判断 `expr` 是否落在 ==**闭区间 `[a, b]`**== 内，等价于 `expr >= a AND expr <= b`。
> 语法很短，但==**日期场景的"右端点"是经典事故现场**==：`BETWEEN '2026-09-01' AND '2026-09-29'` 查不到 9 月 29 日当天 10 点的数据。

> [!info] 与其它笔记的分工
> 普通大小比较见 [[比较谓词]]；`IN` 多值匹配见 [[IN谓词]]。
> 本篇讲 `BETWEEN` 的闭区间语义、`NOT BETWEEN`、NULL 行为、日期坑和索引。

---

## 一、语法与等价展开

```sql
expr BETWEEN min AND max
```

等价于：

```sql
expr >= min AND expr <= max
```

```sql
-- 以下两条完全等价
SELECT * FROM student WHERE age BETWEEN 18 AND 25;
SELECT * FROM student WHERE age >= 18 AND age <= 25;
```

> [!important] 闭区间：两个端点都包含
> `age BETWEEN 18 AND 25` 包含 18 和 25。
> 这一点和"半开区间"（`>= 18 AND < 26`）不同，写日期时尤其要分清。

---

## 二、基本用法

```sql
-- 数值
SELECT * FROM emp WHERE salary BETWEEN 8000 AND 12000;

-- 字符串（按 collation 比较）
SELECT * FROM student WHERE name BETWEEN 'A' AND 'M';

-- 日期
SELECT * FROM `order` WHERE created_at BETWEEN '2026-09-01' AND '2026-09-30';
```

结果示意：

```sql
SELECT * FROM emp WHERE salary BETWEEN 8000 AND 12000;
```

```
emp_name | salary
---------+--------
张三     |  12000   <-- 包含上界
王五     |   9000
赵六     |   8500
-- 李四 15000 不满足；孙七 7000 不满足
```

---

## 三、`NOT BETWEEN`

```sql
expr NOT BETWEEN min AND max
-- 等价于
expr < min OR expr > max
```

```sql
SELECT * FROM emp WHERE salary NOT BETWEEN 8000 AND 12000;
-- 等价于 salary < 8000 OR salary > 12000
```

> [!warning] `NOT BETWEEN` 与 NULL
> 如果 `expr` 为 NULL，`expr NOT BETWEEN a AND b` 的结果是 **UNKNOWN**，行会被 `WHERE` 丢弃。
> 所以"不在区间内"的查询**不会**把 NULL 行算进去。需要保留 NULL 时要显式加 `OR expr IS NULL`。

---

## 四、NULL 行为

`BETWEEN` 本质上是一个 `AND` 组合，所以遵循三值逻辑：

| `expr` | `min` | `max` | 结果 |
| --- | --- | --- | --- |
| `10` | `1` | `20` | TRUE |
| `30` | `1` | `20` | FALSE |
| `NULL` | `1` | `20` | **UNKNOWN** |
| `10` | `NULL` | `20` | **UNKNOWN** |
| `10` | `1` | `NULL` | **UNKNOWN** |

```sql
SELECT NULL BETWEEN 1 AND 20;   -- NULL
SELECT 10 BETWEEN NULL AND 20;  -- NULL
```

> [!danger] 任何一个操作数为 NULL，整条 `BETWEEN` 就"不通过"
> 这就是为什么"按区间筛数据"时，NULL 行总是静默消失。
> 需要保留时：`WHERE (col BETWEEN a AND b) OR col IS NULL`。

---

## 五、日期场景：右端点的经典坑

> [!danger] `BETWEEN '2026-09-01' AND '2026-09-29'` 不包含 9 月 29 日全天
> 日期字面量 `'2026-09-29'` 会被解析成 `2026-09-29 00:00:00`。
> 所以 `BETWEEN '2026-09-01' AND '2026-09-29'` 的上界是 ==**9 月 29 日零点**==，当天 10:00 的订单查不到。

```sql
-- ❌ 漏掉 9 月 29 日 00:00:00 之后的数据
SELECT * FROM `order`
WHERE created_at BETWEEN '2026-09-01' AND '2026-09-29';

-- ✅ 方案一：右端点用"下一天零点"，并改成半开区间
SELECT * FROM `order`
WHERE created_at >= '2026-09-01'
  AND created_at <  '2026-09-30';

-- ✅ 方案二：如果坚持用 BETWEEN，右端点补到 23:59:59
SELECT * FROM `order`
WHERE created_at BETWEEN '2026-09-01 00:00:00' AND '2026-09-29 23:59:59';
```

> [!warning] 为什么不推荐方案二
> `23:59:59` 仍然漏掉 `23:59:59.500` 这类毫秒级数据（如果列是 `DATETIME(3)`）。
> **半开区间 `>= 起 AND < 次日` 才是没有漏洞的写法**，而且能走索引。

---

## 六、字符串与排序规则

`BETWEEN` 对字符串按 **collation** 比较，不是按"字典顺序"想当然：

```sql
SELECT * FROM student WHERE name BETWEEN 'A' AND 'M';
```

- 默认 `utf8mb4_0900_ai_ci` 下大小写不敏感、重音不敏感；
- 中文按字符集排序规则比较，不一定等于拼音顺序；
- 想按二进制比较，用 `BINARY name BETWEEN ...`。

> [!tip] 字符串区间查询很少见
> 真正需要"按姓名字母范围"查的场景不多。大多数"范围"需求是数值和日期。
> 如果业务需要按拼音/笔画排序，应该在设计层加排序字段，而不是依赖 `BETWEEN`。

---

## 七、边界写反了会怎样

```sql
SELECT * FROM emp WHERE salary BETWEEN 12000 AND 8000;
```

不会报错，只会返回**空集**，因为展开后是：

```sql
salary >= 12000 AND salary <= 8000
```

不可能同时成立。

> [!warning] 动态拼接时尤其要小心
> 如果上下界来自用户输入或变量，务必先保证 `min <= max`，否则查询"静默为空"，很难排查。

---

## 八、`BETWEEN` 与索引

```sql
-- ✅ 能走索引：本质是范围扫描
SELECT * FROM emp WHERE salary BETWEEN 8000 AND 12000;

-- ✅ 日期半开区间也能走
SELECT * FROM `order`
WHERE created_at >= '2026-09-01' AND created_at < '2026-10-01';

-- ❌ 列上套函数，索引失效
SELECT * FROM `order`
WHERE DATE(created_at) BETWEEN '2026-09-01' AND '2026-09-30';
```

| 写法 | 索引 |
| --- | --- |
| `col BETWEEN a AND b` | ✅ 范围扫描 |
| `col NOT BETWEEN a AND b` | ⚠️ 多半全表 |
| `DATE(col) BETWEEN ...` | ❌ 失效 |
| `col BETWEEN a AND b OR col IS NULL` | ⚠️ 可能失效，看优化器 |

> [!important] `BETWEEN` 和 `>= AND <=` 的执行计划通常一样
> 优化器会把它们改写成同一种范围条件。选哪个更多是**可读性**问题：
> - 区间端点都包含、语义明确 → `BETWEEN` 更紧凑；
> - 日期右端点要开区间 → `>= AND <` 更安全。

---

## 九、常见错误合集

> [!failure] 日期右端点漏掉当天
> `BETWEEN '2026-09-01' AND '2026-09-29'` 只到 29 日零点。改用半开区间。

> [!failure] 以为 `BETWEEN` 是开区间
> 它是闭区间，两个端点都包含。

> [!failure] 上下界写反
> 不报错，返回空集。动态拼接时先校验 `min <= max`。

> [!failure] 忽略 NULL
> 任一操作数为 NULL → UNKNOWN → 行被丢弃。需要保留 NULL 时显式处理。

> [!failure] 在列上套函数
> `DATE(col) BETWEEN ...` 索引失效，改成对原始列做范围过滤。

---

## 十、速查表

| 需求 | 写法 |
| --- | --- |
| 闭区间 | `col BETWEEN a AND b` |
| 等价展开 | `col >= a AND col <= b` |
| 不在区间 | `col NOT BETWEEN a AND b` |
| 不在区间（含 NULL） | `col NOT BETWEEN a AND b OR col IS NULL` |
| 日期整天（推荐） | `col >= '2026-09-01' AND col < '2026-09-30'` |
| 日期整天（BETWEEN 写法） | `col BETWEEN '2026-09-01 00:00:00' AND '2026-09-29 23:59:59'` |
| 检查上下界 | 确保 `min <= max` |

> [!question] 自测三连
> 1. `BETWEEN` 是开区间还是闭区间？展开成比较运算怎么写？
> 2. 为什么 `BETWEEN '2026-09-01' AND '2026-09-29'` 查不到 29 日 10 点的数据？
> 3. `NOT BETWEEN` 会把 NULL 行查出来吗？为什么？

---

> [!quote] 一句话记忆
> **`BETWEEN` 是闭区间，等价于 `>= AND <=`；日期右端点只到当天零点，整天查询用 `>= 起 AND < 次日`；任一操作数为 NULL 就 UNKNOWN，上下界别写反。**

---

## 相关笔记

- [[比较谓词]] —— `>=`、`<=` 等基础比较
- [[IN谓词]] —— 多值等值匹配
- [[空值谓词]] —— NULL 与三值逻辑
- [[Where]] —— 条件过滤
- [[计算机类/数据库/Mysql/进阶函数与功能/日期与时间|日期与时间]] —— 日期格式化与范围查询
- [[计算机类/数据库/Mysql/DDL/索引/查询优化|查询优化]] —— 范围条件与索引
