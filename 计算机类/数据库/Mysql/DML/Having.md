# HAVING —— 分组后过滤

> [!abstract] 一句话
> `HAVING` 是**分组之后**的过滤，作用对象是"**组**"不是"行"。所以它能直接用聚合函数（`HAVING AVG(salary) > 8000`），而 `WHERE` 不能——这就是两者的分界线。

---

> [!example] 本篇示例数据
> 与 `ORDER BY` / `GROUP BY` 两篇**共用同一张 `emp` 表**。本篇的核心是"过滤时机"，所以重点用到的列是 `salary`（做聚合判断）和 `hire_date`（做 `WHERE` 行级过滤）。

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

## 一、语法与位置

```sql
SELECT 分组列, 聚合函数
FROM 表名
WHERE 行级条件
GROUP BY 分组列
HAVING 组级条件          -- ← 就在这个位置
ORDER BY 排序列
LIMIT n;
```

> [!important] 位置是硬性的
> `HAVING` **必须写在 `GROUP BY` 之后**、`ORDER BY` 之前。
> 写成 `HAVING ... GROUP BY ...` 直接 `ERROR 1064` 语法错误——MySQL 不允许把 `HAVING` 提到分组前面，这不是"优化器会帮你调整"的问题，是**语法层面就过不去**。

```sql
-- ✅ 正确：先分组，后过滤
SELECT dept, COUNT(*) AS 人数
FROM emp
GROUP BY dept
HAVING COUNT(*) >= 3;

-- ❌ 报错：ERROR 1064 (42000): You have an error in your SQL syntax
SELECT dept, COUNT(*) AS 人数
FROM emp
HAVING COUNT(*) >= 3
GROUP BY dept;
```

正确写法的结果：

```
+--------+--------+
| dept   | 人数   |
+--------+--------+
| 研发部 |      3 |
| 销售部 |      3 |
+--------+--------+
```

（`财务部` 只有 2 人，被 `HAVING` 在**分组之后**过滤掉了。）

---

## 二、WHERE vs HAVING 完整对比

> [!important] 一句话区分
> ==**`WHERE` 管"行"，`HAVING` 管"组"。**==
> 判断一个条件该放哪：**这个条件需不需要先分组算一下？** 不需要 → `WHERE`；需要 → `HAVING`。

| 对比维度 | `WHERE` | `HAVING` |
| --- | --- | --- |
| **执行时机** | 在 `GROUP BY` **之前** | 在 `GROUP BY` **之后** |
| **过滤对象** | 单个**行** | 单个**组** |
| **能否用聚合函数** | ❌ 不能 | ✅ 能 |
| **能否用 `SELECT` 别名** | ❌ 不能 | ✅ 能（**MySQL 扩展**，非标准 SQL） |
| **能否脱离 `GROUP BY` 单独用** | ✅ 正常用 | ⚠️ 可以，但整表当一组，通常没意义 |
| **能否用索引** | ✅ 能用 | ❌ 不能（此时行已被重新组织） |
| **性能** | 更快（先减少数据量） | 更慢（分组算完再丢） |
| **典型场景** | `WHERE salary > 8000`、`WHERE hire_date > '2020-01-01'` | `HAVING AVG(salary) > 8000`、`HAVING COUNT(*) > 2` |
| **书写位置** | `FROM` 之后、`GROUP BY` 之前 | `GROUP BY` 之后、`ORDER BY` 之前 |

> [!tip] 记忆口诀
> **"先用 `WHERE` 砍行，再用 `GROUP BY` 分组，最后用 `HAVING` 挑组。"**
> 一个条件**能在 `WHERE` 里写就一定要在 `WHERE` 里写**——不是"能不能跑"的问题，是性能问题。`WHERE` 把 100 万行砍成 1000 行再分组，和分组完 100 万行再扔掉 99.9%，代价差几个数量级。
> 而且 `WHERE` 能用索引，`HAVING` **永远用不上索引**，因为它面对的是分组后的中间结果。

> [!info] 两者并不互斥，是配合关系
> 一条 SQL 里同时出现 `WHERE` 和 `HAVING` 是最正常的写法，各管各的：
> - `WHERE` 负责"哪些**行**有资格参与统计"
> - `HAVING` 负责"哪些**组**有资格出现在结果里"
>
> 完整的四子句配合见第七节。

---

## 三、HAVING 能用聚合函数（WHERE 不能）

这是最核心的差异，用能跑的代码证明。

### 3.1 HAVING 版本（正确）

```sql
-- 找出平均工资超过 8000 的部门
SELECT dept,
       COUNT(*)               AS 人数,
       ROUND(AVG(salary), 2)  AS avg_sal
FROM emp
GROUP BY dept
HAVING AVG(salary) > 8000
ORDER BY avg_sal DESC;
```

```
+--------+--------+----------+
| dept   | 人数   | avg_sal  |
+--------+--------+----------+
| 研发部 |      3 | 12000.00 |   (12000+9000+15000)/3 = 12000.00
| 财务部 |      2 |  8250.00 |   (7000+9500)/2       =  8250.00
+--------+--------+----------+
```

`销售部` 的平均工资是 `(8000+6500+7500)/3 = 7333.33`，没过 8000 的线，被过滤掉了。**返回 2 行**。

### 3.2 同样的条件写成 WHERE（报错）

```sql
-- ❌ 把聚合条件写进 WHERE
SELECT dept, AVG(salary) AS avg_sal
FROM emp
WHERE AVG(salary) > 8000
GROUP BY dept;
```

```
ERROR 1111 (HY000): Invalid use of group function
```

> [!failure] 为什么 `WHERE AVG(salary)` 是无效的
> `WHERE` 执行时，**数据还是一行一行的原始状态，分组还没发生**。
> `AVG(salary)` 的语义是"某个组内所有 salary 的平均值"——此时根本不存在"组"这个东西，函数无从下手。
> 所以 MySQL 直接判定为"group function 用在了非法位置"，报 `ERROR 1111`。
> 而 `HAVING` 执行时组已经分好了，每个组都有了自己的 `AVG(salary)`，拿来比较天经地义。

> [!note] 同类报错
> `WHERE COUNT(*) > 1`、`WHERE SUM(salary) > 100000`、`WHERE MAX(salary) > 10000` 全都会触发 `ERROR 1111`。
> 判断标准很简单：**只要 `WHERE` 里出现了聚合函数，就是这个错**。

---

## 四、经典误用：`HAVING salary > 8000`

> [!danger] 这是最危险的写法，重点警告
> 很多人觉得"`HAVING` 就是过滤，那我 `HAVING salary > 8000` 应该也能跑"。
> 它**确实能跑**（在某些 `sql_mode` 下），但语义完全不是你想的那样。
> `salary` 是**行级字段**，不是组级值。MySQL 面对一个组里 3 个不同的 `salary`，只能**随便挑一行**来判断——挑到谁全看运气。

```sql
-- ⚠️ 危险写法：以为在"筛工资大于 8000 的人所在部门"
SELECT dept, COUNT(*) AS 人数
FROM emp
GROUP BY dept
HAVING salary > 8000;
```

两种可能的结果：

| `sql_mode` | 行为 | 结果 |
| --- | --- | --- |
| 含 `ONLY_FULL_GROUP_BY`（5.7+ 默认） | **直接报错** | `ERROR 1055: Expression #1 of HAVING clause is not in GROUP BY clause ...` |
| 关掉该模式 | 每组**随机取一行**判断 | 见下表，**行数可能变** |

关掉模式后，MySQL 从每个组里 "indeterminate"（不确定）地取一行：

| 部门 | 组内 salary | 取到哪一行不确定 | `salary > 8000` | 该组是否保留 |
| --- | --- | --- | --- | --- |
| 研发部 | 12000 / 9000 / 15000 | 三个都 > 8000 | 都是真 | ✅ 一定保留 |
| 财务部 | 7000 / 9500 | 取到 **7000** → 假 | 取决于运气 | ⚠️ **可能保留可能不保留** |
| 销售部 | 8000 / 6500 / 7500 | `8000 > 8000` 是假 | 都是假 | ❌ 一定不保留 |

```
-- 可能的输出 A（财务部取到 9500）
+--------+--------+
| dept   | 人数   |
+--------+--------+
| 研发部 |      3 |
| 财务部 |      2 |
+--------+--------+

-- 可能的输出 B（财务部取到 7000）
+--------+--------+
| dept   | 人数   |
+--------+--------+
| 研发部 |      3 |
+--------+--------+
```

同一个查询、同一份数据，**加个索引或者换个 MySQL 版本，结果就从 2 行变成 1 行**。报表数字对不上，往往就是这里的问题。

> [!question] 那"筛选工资大于 8000 的人所在部门"到底该怎么写？
> 先问清楚需求方的**真实意图**，两种意图对应两种完全不同的正确写法：
> - 意图一："**只看**工资大于 8000 的人，再统计各部门" → 用 `WHERE` 先砍行
> - 意图二："**整个部门**都参与统计，只要该部门**有**人超过 8000 就展示" → 用 `HAVING MAX(salary) > 8000`
>
> 两种写法结果看起来类似，数字却不一样：

```sql
-- 意图一：先用 WHERE 砍掉低薪行，再分组统计
SELECT dept, COUNT(*) AS 人数, SUM(salary) AS 工资总额
FROM emp
WHERE salary > 8000
GROUP BY dept;
```

```
+--------+--------+--------------+
| dept   | 人数   | 工资总额     |
+--------+--------+--------------+
| 研发部 |      3 |     36000.00 |   张伟 12000、李娜 9000、王强 15000
| 财务部 |      1 |      9500.00 |   只剩周杰，孙悦 7000 被砍掉
+--------+--------+--------------+
```

```sql
-- 意图二：全员参与统计，部门整体达标就展示
SELECT dept, COUNT(*) AS 人数, SUM(salary) AS 工资总额
FROM emp
GROUP BY dept
HAVING MAX(salary) > 8000;
```

```
+--------+--------+--------------+
| dept   | 人数   | 工资总额     |
+--------+--------+--------------+
| 研发部 |      3 |     36000.00 |
| 财务部 |      2 |     16500.00 |   孙悦的 7000 也算进来了
+--------+--------+--------------+
```

**同样的条件、同样的"正确"，财务部的人数一个是 1、一个是 2。** 这就是"语义先于语法"的最好例子。

> [!success] 判断法则
> 看到 `HAVING` 后面跟着一个**裸列名**（没被聚合函数包起来），先停下来问自己：
> **"我这个列是分组列吗？"**
> - 是分组列（如 `HAVING dept = '研发部'`）→ 合法，但不该写在这，挪到 `WHERE` 更快
> - 不是分组列（如 `HAVING salary > 8000`）→ **写完心里没底，一定有语义问题**
>
> 组级判断的标准形态永远是：`HAVING 聚合函数(列) 比较 值`。

---

## 五、HAVING 里用 SELECT 别名（MySQL 扩展）

```sql
SELECT dept,
       ROUND(AVG(salary), 2) AS avg_sal
FROM emp
GROUP BY dept
HAVING avg_sal > 8000          -- 直接用别名
ORDER BY avg_sal DESC;
```

```
+--------+----------+
| dept   | avg_sal  |
+--------+----------+
| 研发部 | 12000.00 |
| 财务部 |  8250.00 |
+--------+----------+
```

和 `ORDER BY` 一样，这里能用别名，是因为 **`HAVING` 的执行时机在 `SELECT` 之后**——别名已经诞生了。

> [!warning] 这是 MySQL 的"方言"，不是标准 SQL
> SQL 标准规定：`WHERE` / `GROUP BY` / `HAVING` 只能引用**表里的原始列名**，`SELECT` 别名只有 `ORDER BY` 能用。
> MySQL 为方便把 `HAVING` 的口子也放开了，但**移植到 PostgreSQL、Oracle、SQL Server 就会报错**（`column "avg_sal" does not exist`）。
> 另一层风险：如果表里**恰好有一个叫 `avg_sal` 的列**，MySQL 会优先用表里的列，而不是 `SELECT` 的别名——结果悄悄变了。
>
> **稳妥写法**：`HAVING` 里把聚合表达式**原样重写一遍**，不依赖方言：
> `HAVING ROUND(AVG(salary), 2) > 8000`

```sql
-- ❌ WHERE 里用别名：一定报错（WHERE 执行时别名还不存在）
SELECT dept, AVG(salary) AS avg_sal FROM emp WHERE avg_sal > 8000 GROUP BY dept;
-- ERROR 1054 (42S22): Unknown column 'avg_sal' in 'where clause'
```

| 子句 | 能用 `SELECT` 别名吗 | 能用聚合函数吗 | 原因 |
| --- | --- | --- | --- |
| `WHERE` | ❌ `ERROR 1054` | ❌ `ERROR 1111` | 执行在 `SELECT` 和 `GROUP BY` 之前 |
| `GROUP BY` | ❌（标准）/ 部分支持 | ❌ | 分组时 `SELECT` 还没跑 |
| `HAVING` | ✅（MySQL 扩展） | ✅ | 执行在两者之后 |
| `ORDER BY` | ✅ | ✅ | 执行在最后 |

---

## 六、只写 HAVING 不写 GROUP BY

> [!info] 合法，但只有一行结果
> 不写 `GROUP BY` 时，SQL 标准规定：**整个结果集被视为一个组**。
> 于是 `HAVING` 就变成了"对全表聚合后的结果做一次判断"——要么返回 1 行，要么返回 0 行。

```sql
-- 全公司平均工资超过 8000 吗？超过就把这个数字给我
SELECT ROUND(AVG(salary), 2) AS avg_sal
FROM emp
HAVING AVG(salary) > 8000;
```

```
+----------+
| avg_sal  |
+----------+
|  9312.50 |
+----------+
```

全公司 8 人工资总额 = `12000+9000+15000+8000+6500+7500+7000+9500 = 74500`，`74500 / 8 = 9312.50`，过了 8000，所以返回这 1 行。

把阈值改成 10000：

```sql
SELECT ROUND(AVG(salary), 2) AS avg_sal
FROM emp
HAVING AVG(salary) > 10000;
-- Empty set (0.00 sec)      ← 空结果集，不是 NULL 行
```

> [!tip] 这种写法什么时候有用
> 它的真正价值是**"整表级的门槛判断"**：数据不达标时**干脆不返回任何行**，而不是返回一个不达标的小数字。
> 等价写法（更易读，也更通用）：
> - 上面的例子 → `SELECT ROUND(AVG(salary),2) FROM emp HAVING AVG(salary) > 10000;`
> - 更常见的做法是**加一个恒真的 `GROUP BY`**：`GROUP BY 1` 或 `GROUP BY 'x'`，效果一样但可读性好
> - 或者直接在应用层判断，`HAVING` 不写 `GROUP BY` 在团队协作中容易被误读

> [!warning] 不写 GROUP BY 时的两条限制
> 1. **`SELECT` 里只能有聚合函数和常量**，不能出现任何裸列，否则报 `ERROR 1055`（只有一个组，这个组里有 8 个不同的 `name`）
> 2. **结果永远不超过 1 行**。如果你期望多行，说明漏写了 `GROUP BY`——这是很常见的低级失误

---

## 七、四件套完整配合：WHERE + GROUP BY + HAVING + ORDER BY

**需求**：筛选出 **2020 年之后入职**的员工，按**部门**统计平均工资，只保留平均工资**超过 8000** 的部门，最后按平均工资**降序**排列。

### 7.1 完整 SQL

```sql
SELECT dept,
       COUNT(*)               AS 人数,
       ROUND(AVG(salary), 2)  AS avg_sal
FROM emp
WHERE hire_date > '2020-01-01'
GROUP BY dept
HAVING AVG(salary) > 8000
ORDER BY avg_sal DESC;
```

```
+--------+--------+----------+
| dept   | 人数   | avg_sal  |
+--------+--------+----------+
| 研发部 |      1 |  9000.00 |
| 财务部 |      2 |  8250.00 |
+--------+--------+----------+
```

### 7.2 逐子句拆解

| 子句 | 内容 | 作用 | 数据量变化 |
| --- | --- | --- | --- |
| `FROM emp` | 取全表 | 数据源 | 8 行 |
| `WHERE hire_date > '2020-01-01'` | 留下 2020 年后入职的 | **砍行** | 8 → **6 行** |
| `GROUP BY dept` | 按部门分 3 个桶 | **分组** | 6 行 → 3 组 |
| 聚合 `COUNT` / `AVG` | 每组算人数和均薪 | **算组值** | 3 组 → 3 行 |
| `HAVING AVG(salary) > 8000` | 销售部均薪 7333.33 出局 | **挑组** | 3 → **2 组** |
| `SELECT` | 选出最终列、起别名 | 投影 | 保持 2 行 |
| `ORDER BY avg_sal DESC` | 研发部 9000 > 财务部 8250 | **排序** | 2 行 |
| `LIMIT`（本例没写） | 截断 | 取前 N | — |

`WHERE` 过滤后留下 6 行（李娜、赵敏、陈晨、刘洋、孙悦、周杰），砍掉了张伟（2018-03-11）和王强（2019-05-20）。分组与过滤：

| 部门 | 组内成员 | 人数 | 平均工资 | `HAVING > 8000` |
| --- | --- | --- | --- | --- |
| 研发部 | 李娜 9000 | 1 | `9000.00` | ✅ 保留 |
| 财务部 | 孙悦 7000、周杰 9500 | 2 | `8250.00` | ✅ 保留 |
| 销售部 | 赵敏 8000、陈晨 6500、刘洋 7500 | 3 | `7333.33` | ❌ 过滤 |

> [!success] 换成 HAVING 会怎样（反例）
> 如果把 `WHERE hire_date > '2020-01-01'` 挪到 `HAVING`：`HAVING hire_date > '2020-01-01'`
> 结果**完全不可预测**——`hire_date` 不是分组列，MySQL 会从每个组里随机挑一行的 `hire_date` 来比较。
> 而且此时**全表 8 行都参与了 `AVG`**，研发部会变成 `12000.00`（含张伟、王强），数字全错。
> 这就是"行级条件必须放 `WHERE`"的实际代价。

### 7.3 执行顺序图（务必背下来）

| 序号 | 子句 | 做什么 | 能否用聚合 | 能否用别名 | 索引 |
| --- | --- | --- | --- | --- | --- |
| ① | `FROM` / `JOIN` | 确定数据来源，拼出原始行集合 | — | — | — |
| ② | `WHERE` | **行级过滤** | ❌ | ❌ | ✅ 能用 |
| ③ | `GROUP BY` | 把剩下的行按分组键分桶 | ❌ | ❌ | 部分能用 |
| ④ | 聚合函数 | 每个桶算出一个值 | — | — | — |
| ⑤ | `HAVING` | **组级过滤** | ✅ | ✅ | ❌ 用不了 |
| ⑥ | `SELECT` | 选出最终列，**别名在这一步诞生** | ✅ | — | — |
| ⑦ | `DISTINCT` | 去重 | — | — | — |
| ⑧ | `ORDER BY` | 排序 | ✅ | ✅ | 部分能用 |
| ⑨ | `LIMIT` | 截断取前 N 行 | — | — | — |

> [!important] 记住这条顺序，SQL 报错就能自己诊断
> - `WHERE` 里报"未知列" → 你用了 `SELECT` 别名（别名还没诞生）
> - `WHERE` 里报 "Invalid use of group function" → 你用了聚合函数（组还没诞生）
> - `HAVING` 里能用别名和聚合 → 因为它在 `SELECT` 和分组之后
> - `ORDER BY` 什么都能用 → 它在最后
>
> 顺口溜：**From → Where → Group → 聚合 → Having → Select → Distinct → Order → Limit**。

---

## 八、常见报错合集

> [!failure] ERROR 1111：Invalid use of group function
> **原因**：把聚合函数写进了 `WHERE`（或 `GROUP BY`）：`SELECT dept FROM emp WHERE AVG(salary) > 8000 GROUP BY dept;`
> **改法**：把这段条件整体挪到 `HAVING`：`SELECT dept FROM emp GROUP BY dept HAVING AVG(salary) > 8000;`
> 注意 `ON` 子句里写聚合函数也是同一个错，外连接时很容易犯。

> [!failure] ERROR 1055：... not in GROUP BY clause
> 完整报错长这样：`ERROR 1055 (42000): Expression #N of SELECT list is not in GROUP BY clause and contains nonaggregated column 'test.emp.xxx' which is not functionally dependent on columns in GROUP BY clause; this is incompatible with sql_mode=only_full_group_by`
> **原因**：`SELECT` 或 `HAVING` 里出现了**既不在 `GROUP BY` 里、也没被聚合函数包起来**的列。两种典型触发：
> - ❌ `SELECT dept, name, COUNT(*) FROM emp GROUP BY dept;` —— `name` 不是分组列
> - ❌ `SELECT dept, COUNT(*) FROM emp GROUP BY dept HAVING salary > 8000;` —— 错误发生在 `HAVING`
> **改法**三选一：① 把该列加进 `GROUP BY`；② 给它套一个聚合函数（`MAX(name)`）；③ 用窗口函数替代分组。
> **千万别**用 `SET sql_mode = ''` 关掉检查——那会从"报错"退化成"静默返回随机值"，更糟。

> [!failure] ERROR 1064：You have an error in your SQL syntax
> **原因**：子句顺序写错了，最常见的就是 `HAVING` 跑到了 `GROUP BY` 前面。
> - ❌ `SELECT dept, COUNT(*) FROM emp HAVING COUNT(*) > 1 GROUP BY dept;`
> - ✅ `SELECT dept, COUNT(*) FROM emp GROUP BY dept HAVING COUNT(*) > 1;`
> `ERROR 1064` 是"万金油语法错误"，`HAVING` 相关的还有：`HAVING` 写在了 `ORDER BY` 后面、`HAVING` 条件里括号没配对、`HAVING` 后面直接跟了 `ORDER BY` 忘了写条件。

> [!note] ERROR 1054：Unknown column
> `WHERE` 或 `HAVING` 里引用了不存在的列名。在 `HAVING` 场景下，通常有两种情况：
> ① 列名拼错；② **想用 `SELECT` 别名，但别名和表里的列重名了**，导致 MySQL 指向了另一列。
> 遇到第二种，把表达式在 `HAVING` 里重写一遍最稳妥。

> [!danger] 最后的忠告
> 上面四个报错里，**`ERROR 1055` 和 `ERROR 1111` 是"好报错"**——它们替你拦住了语义不清的写法。
> 真正要命的是**关掉 `sql_mode` 之后不报错但结果乱飘**的情况。
> 见到 `only_full_group_by`，正确反应是"改我的 SQL"，不是"关掉这个模式"。

---

## 九、速查表

| 需求       | 该用哪个                 | 写法                               |
| -------- | -------------------- | -------------------------------- |
| 过滤单个员工   | `WHERE`              | `WHERE salary > 8000`            |
| 过滤入职年份   | `WHERE`              | `WHERE hire_date > '2020-01-01'` |
| 过滤部门平均工资 | `HAVING`             | `HAVING AVG(salary) > 8000`      |
| 过滤部门人数   | `HAVING`             | `HAVING COUNT(*) >= 3`           |
| 过滤部门最高工资 | `HAVING`             | `HAVING MAX(salary) > 10000`     |
| 部门名称筛选   | `WHERE`（别写 `HAVING`） | `WHERE dept = '研发部'`             |

判断流程：

| 问自己 | 答 | 结论 |
| --- | --- | --- |
| 条件里用了聚合函数吗？ | 用了 | 只能写 `HAVING` |
| | 没用 | 往下问 |
| 条件是针对单个行的吗？ | 是 | 写 `WHERE`（更快） |
| | 不是，是分组列 | 也能写 `HAVING`，但写 `WHERE` 更好 |

> [!question] 自测三连
> 1. `SELECT dept, AVG(salary) FROM emp WHERE AVG(salary) > 8000 GROUP BY dept;` 报什么错？数字是多少？
> 2. `HAVING salary > 8000` 和 `WHERE salary > 8000` 的语义差异是什么？为什么前者"结果不可预测"？
> 3. `HAVING` 里能用 `SELECT` 别名，这是标准 SQL 还是 MySQL 扩展？有没有风险？

---

> [!quote] 一句话记忆
> **`WHERE` 砍行、`HAVING` 挑组**：`WHERE` 在分组前执行、面向单个行、不能碰聚合函数；`HAVING` 在分组后执行、面向整个组、必须用聚合函数才有意义。
> 记住那条顺序链——**From → Where → Group → 聚合 → Having → Select → Order → Limit**，SQL 报错就能自己诊断。

---

## 相关笔记

- [[Where]] —— 分组**前**的行级过滤，能用索引
- [[计算机类/数据库/Mysql/DML/Group By]] —— `HAVING` 的前置条件，分完组才有"组"可挑
- [[Order By]] —— 四件套的最后一环，对分组结果排序
- [[Select]] —— 各子句的执行顺序与别名生效时机
- [[From]] —— 数据来源与连接
- [[Join]] —— 多表连接后的分组与过滤，`ON` 里同样不能写聚合函数
- [[Create Table]] —— 建表时定好索引，决定 `WHERE` 能有多快
