# GROUP BY —— 分组聚合

> [!abstract] 一句话
> `GROUP BY` 是**聚合查询的骨架**：没有它，聚合函数把**全表当成一个组**，只产出一行；有了它，才按你指定的维度**把行折叠成若干组、每组各算一次**——所以"分组"决定了聚合结果的**粒度**。

> [!info] 与 `DML` 版的分工
> 同名的 [[计算机类/数据库/Mysql/DML/Group By]] 把 `GROUP BY` **语法细节、多列分组、聚合函数速查、`GROUP_CONCAT`** 讲得很全。
> 这一篇**不重复那些**，专讲聚合视角下的三件事：**分组的定位、分组的执行机制、分组与索引/去重的关系**。两篇对照看。

---

> [!example] 本篇示例数据
> 与同目录的 `COUNT` / `SUM` / `AVG` / `MAX` / `MIN` / `HAVING` 各篇**共用同一张 `emp` 表**。
> 三个部门的**人数不等**（研发 3 / 销售 3 / 财务 2），用来演示"分组粒度"和"组内成员数不同"带来的影响。

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

## 一、聚合的两种形态

聚合函数有**两种用法**，区别就在于有没有 `GROUP BY`：

```sql
-- 形态 A：整表聚合 —— 全表当一个组，产出 1 行
SELECT COUNT(*) AS 人数, AVG(salary) AS 平均工资 FROM emp;
```

```
+--------+--------------+
| 人数   | 平均工资     |
+--------+--------------+
|      8 |      9312.50 |
+--------+--------------+
```

```sql
-- 形态 B：分组聚合 —— 按 dept 分组，产出 3 行
SELECT dept, COUNT(*) AS 人数, AVG(salary) AS 平均工资
FROM emp
GROUP BY dept;
```

```
+--------+--------+--------------+
| dept   | 人数   | 平均工资     |
+--------+--------+--------------+
| 研发部 |      3 |     12000.00 |
| 财务部 |      2 |      8250.00 |
| 销售部 |      3 |      7333.33 |
+--------+--------+--------------+
```

| 形态 | 写法 | 产出行数 | 粒度 |
| --- | --- | --- | --- |
| 整表聚合 | 只有聚合函数 | **1 行** | 全表 |
| 分组聚合 | `GROUP BY 维度` | **每组 1 行** | 每个分组键 |

> [!important] 一句话抓住 `GROUP BY` 的本质
> ==**`GROUP BY` 决定聚合的"粒度"**==：分组键 = 结果的维度，去掉它就是"全表汇总"。
> 8 行数据经过 `GROUP BY dept` 只出来 3 行，因为**一个组只产出一行**。

> [!tip] 分组的心理模型：把行"倒进篮子"
> 想象把 8 行数据倒进 3 个篮子：
> - `研发部` 篮子 3 行、`财务部` 篮子 2 行、`销售部` 篮子 3 行
>
> 之后**所有计算都在"篮子"层面进行**：`COUNT(*)` 数篮子里几个，`AVG(salary)` 把篮子里的工资求平均。
> 篮子里的**明细行不再单独可见**——这就是为什么 `SELECT` 里不能再写非分组列。

---

## 二、语法与各子句分工

```sql
SELECT   分组列, 聚合函数(列)
FROM     表名
WHERE    行级条件            -- 分组【前】过滤行
GROUP BY 分组列1 [, 分组列2]
HAVING   组级条件            -- 分组【后】过滤组
ORDER BY 排序列;
```

| 子句 | 作用对象 | 执行时机 | 说明 |
| --- | --- | --- | --- |
| `WHERE` | **行** | 分组前 | 把不要的行先扔掉，参与分组的行更少 |
| `GROUP BY` | — | — | 定义"按什么维度折叠" |
| `HAVING` | **组** | 分组后 | 把不要的组扔掉，**能用聚合函数** |
| `ORDER BY` | 结果集 | 最后 | 分组结果**默认无序**，要顺序必须显式写 |

> [!warning] 执行顺序永远是：`FROM → WHERE → GROUP BY → 聚合 → HAVING → SELECT → ORDER BY → LIMIT`
> `GROUP BY` 排在 `WHERE` 之后、`HAVING` 之前。分组的完整执行链与 `HAVING` 的配合见 [[计算机类/数据库/Mysql/聚合查询/HAVING]]。

---

## 三、分组后 `SELECT` 里能写什么

> [!important] 三条铁律
> `GROUP BY` 之后，`SELECT` 列表里**只允许**出现：
> 1. **分组列**（出现在 `GROUP BY` 里的列）
> 2. **聚合函数**（`COUNT` / `SUM` / `AVG` / `MAX` / `MIN` / `GROUP_CONCAT` …）
> 3. **常量表达式**（`'2026 年度'`、`NOW()` 这种与行无关的值）
>
> 除此之外的**非分组列，一律不许写**。

```sql
-- ❌ ERROR 1055
SELECT dept, name, AVG(salary) FROM emp GROUP BY dept;
```
```
ERROR 1055 (42000): Expression #2 of SELECT list is not in GROUP BY clause
and contains nonaggregated column 'test.emp.name' which is not functionally
dependent on columns in GROUP BY clause; this is incompatible with
sql_mode=only_full_group_by
```

原因：`研发部` 这个组里有 3 个不同的 `name`，MySQL 不知道该给你哪一个。

### 3.1 `only_full_group_by`：拦住"语义不清"

MySQL **5.7 起默认开启** `only_full_group_by`，专门拦截上面这种写法。用 `SELECT @@sql_mode;` 查看。

> [!danger] 千万别为了"能跑"关掉它
> 关掉之后 SQL **不报错**，但 `name` 会变成组内**随机某一行**的值（官方措辞 "an indeterminate row"）。
> **不报错、有结果、结果是错的**——比 `ERROR 1055` 危险得多，生产报表算错往往就埋在这里。

### 3.2 函数依赖（functional dependency）：8.0 的放宽

`only_full_group_by` 并不是"一刀切"地拦所有非分组列。如果某列**在函数上依赖于分组键**，它其实是**唯一确定**的，可以合法写出：

```sql
-- 假设 emp 有主键 id，且 dept 表与主键一一对应时可成立
-- 更常见的例子：分组键是主键时，同表的其他列都函数依赖于它
SELECT id, name, salary FROM emp GROUP BY id;   -- ✅ 合法（id 是主键）
```

> [!info] 函数依赖的实际判断
> MySQL 5.7.5+ 会做**函数依赖检测**：如果分组键能唯一确定某列（最常见是"分组键就是主键/唯一键"），那么 `SELECT` 里带上该列**不报 1055**。
> 但这个判断有限、容易踩边界，**不要依赖它**——老老实实"分组列 + 聚合函数"，可读性和可移植性都更好。

---

## 四、多列分组：分组的"维度组合"

`GROUP BY` 后写多列，就是按**组合**分组。理论组数是各列取值个数的**乘积**：

```sql
SELECT dept, gender, COUNT(*) AS 人数, AVG(salary) AS 平均工资
FROM emp
GROUP BY dept, gender
ORDER BY dept, gender;
```

```
+--------+--------+--------+--------------+
| dept   | gender | 人数   | 平均工资     |
+--------+--------+--------+--------------+
| 研发部 | F      |      1 |      9000.00 |
| 研发部 | M      |      2 |     13500.00 |
| 财务部 | F      |      1 |      7000.00 |
| 财务部 | M      |      1 |      9500.00 |
| 销售部 | F      |      2 |      7750.00 |
| 销售部 | M      |      1 |      6500.00 |
+--------+--------+--------+--------------+
```

> [!warning] 组数不是"一定"等于乘积
> 3 部门 × 2 性别 = 理论上 6 组，这里恰好 6 组。但如果某部门**全是男性**，`(该部门, F)` 这一组**根本不存在**，不会返回一行空值。
> 想让不存在的组合也显示，得 `LEFT JOIN` 一张"全组合表"——交叉报表的常见需求。

> [!tip] 多列分组的顺序有讲究
> `GROUP BY dept, gender` 和 `GROUP BY gender, dept` 的**结果集内容相同**，但：
> 1. 默认返回顺序不同；
> 2. **能否用上索引不同**——联合索引 `(dept, gender)` 只能加速前者。
>
> 原则：**让 `GROUP BY` 的列顺序与索引列顺序一致。**

---

## 五、分组的执行机制：哈希分组 vs 排序分组

MySQL 把"分桶"这件事落地成两种算法，**结果集内容一样，但顺序和性能表现不同**：

| 算法 | 做法 | 何时用 | 结果顺序 |
| --- | --- | --- | --- |
| **哈希分组** | 建临时哈希表，按分组键算哈希落桶 | 无法利用有序索引时（**8.0 默认**） | 取决于哈希桶遍历顺序 |
| **排序分组** | 先按分组键排序，相邻同键即同组 | 能利用索引/排序时 | 按分组键有序 |

> [!danger] 为什么"同一个查询换个环境顺序就变了"
> 8.0 默认用**哈希分组**，5.7 常用**排序分组**；再叠加"数据量、是否命中索引"的变化，MySQL 可能**在两种算法间切换**。
> 于是**你以为"它本来就该是那个顺序"的结果突然变了**。
> **结论：只要顺序对业务有意义，必须显式写 `ORDER BY`。**（详见 [[计算机类/数据库/Mysql/DML/Order By]]）

```sql
-- ❌ 顺序不可依赖
SELECT dept, COUNT(*) FROM emp GROUP BY dept;

-- ✅ 顺序有保证
SELECT dept, COUNT(*) FROM emp GROUP BY dept ORDER BY dept;
```

---

## 六、分组与索引：松散索引扫描

`GROUP BY` 不一定慢，**关键在于索引能不能"喂饱"它**。当索引的列顺序**正好覆盖分组列**时，MySQL 可以走 `Using index for group-by`（**松散索引扫描**），不必把整表读出来再分桶。

```sql
CREATE INDEX idx_dept_salary ON emp(dept, salary);

EXPLAIN SELECT dept, MAX(salary) FROM emp GROUP BY dept;
-- Extra: Using index for group-by   ← 松散索引扫描，很快
```

| 情况 | 执行方式 | 速度 |
| --- | --- | --- |
| 分组列 = 索引最左列（或前缀） | `Using index for group-by`（松散扫描） | ✅ 快，无需临时表 |
| 分组列是索引前缀但要用到非索引列 | 紧凑索引扫描 + 回表 | ⚠️ 一般 |
| 分组列没有可用索引 | 临时表 / 文件排序 | ❌ 慢 |

> [!success] 让 `GROUP BY` 走索引的三条经验
> 1. **联合索引列顺序 = 分组列顺序**（`(dept, salary)` 支持 `GROUP BY dept`，反过来不行）；
> 2. **分组列尽量是索引最左前缀**；
> 3. `WHERE` 里先过滤能减少参与分组的行，**先过滤再分组**永远更快。

> [!note] `GROUP BY` 常常自带一次隐式排序
> 在旧版本/排序分组下，`GROUP BY` 会隐式按分组键排序；**MySQL 8.0 已移除这个隐式 `ORDER BY`**，加上哈希分组成为默认，**顺序变得更不可依赖**——又一次强调：要顺序就写 `ORDER BY`。

---

## 七、`GROUP BY` 与 `DISTINCT`：其实是"同一种运算"

> [!important] 一个常被忽略的等价关系
> ==**`GROUP BY` 与 `DISTINCT` 在底层常被优化成同一套去重逻辑。**==
> "按 `dept` 去重"和"按 `dept` 分组"结果集一样：

```sql
SELECT DISTINCT dept FROM emp;            -- 3 行：研发部、财务部、销售部
SELECT dept FROM emp GROUP BY dept;       -- 3 行，同上
```

| 维度 | `DISTINCT` | `GROUP BY` |
| --- | --- | --- |
| 目的 | 去重 | 分组以便聚合 |
| 能否跟聚合函数 | ❌（`DISTINCT` 是修饰 SELECT 的） | ✅ |
| 结果 | 去重后的行 | 每组一行 |
| 性能 | 相近（都可能走索引或临时表） | 相近 |

> [!tip] 怎么选
> 只要"去重后不同的组合" → `DISTINCT` 更贴合语义；
> 还要"顺便算个 `COUNT` / `SUM`" → 直接用 `GROUP BY`，一举两得。
> 注意 `DISTINCT` 作用于**整行/整个列组合**（详见 [[计算机类/数据库/Mysql/DML/Select]] 的 `DISTINCT` 章节）。

---

## 八、`WITH ROLLUP`：给分组结果加"小计/总计"

`WITH ROLLUP` 在分组的末尾**追加汇总行**（`NULL` 即汇总标记），一步拿到"明细 + 小计 + 总计"：

```sql
SELECT dept, SUM(salary) AS 工资总额
FROM emp
GROUP BY dept WITH ROLLUP;
```

```
+--------+--------------+
| dept   | 工资总额     |
+--------+--------------+
| 研发部 |     36000.00 |
| 财务部 |     16500.00 |
| 销售部 |     22000.00 |
| NULL   |     74500.00 |   <- 全表总计
+--------+--------------+
```

> [!warning] `ROLLUP` 的 `NULL` 会和真实 `NULL` 混在一起
> 如果 `dept` 本身有真实的 `NULL`（"未分配部门"），你分不清哪个 `NULL` 是小计行。
> MySQL 提供 `GROUPING(列)` 来区分：**返回 `1` 是 ROLLUP 生成的 NULL，返回 `0` 是数据本身的 NULL**。
> ```sql
> SELECT IF(GROUPING(dept), '总计', dept) AS 部门, SUM(salary)
> FROM emp GROUP BY dept WITH ROLLUP;
> ```

> [!info] 更细的展开请看 DML 版
> 多列分组的**逐级汇总**、`GROUPING SETS` / `CUBE` 的缺失（**MySQL 到 8.0 仍未原生支持，只能用 `UNION ALL` 手写**），在 [[计算机类/数据库/Mysql/DML/Group By]] 里有完整示例。

---

## 九、常见错误合集

> [!failure] ERROR 1055 —— 非分组列出现在 SELECT / HAVING
> ```sql
> SELECT dept, name, AVG(salary) FROM emp GROUP BY dept;
> ```
> 改法三选一：① 把列加进 `GROUP BY`；② 套聚合函数（`MAX(name)`）；③ 用窗口函数替代分组。
> **不要**用 `SET sql_mode = ''` 关掉检查。

> [!failure] ERROR 1111 —— 聚合函数写进 `WHERE`
> ```sql
> SELECT dept, AVG(salary) FROM emp WHERE AVG(salary) > 8000 GROUP BY dept;   -- ERROR 1111
> ```
> 挪到 `HAVING`：`... GROUP BY dept HAVING AVG(salary) > 8000`。

> [!failure] ERROR 1064 —— 子句顺序错
> `HAVING` 跑到了 `GROUP BY` 前面：
> ```sql
> SELECT dept, COUNT(*) FROM emp HAVING COUNT(*) > 1 GROUP BY dept;   -- ERROR 1064
> ```

> [!failure] 结果顺序"随机"
> 没写 `ORDER BY`，8.0 哈希分组下顺序不可依赖。要顺序就显式 `ORDER BY`。

> [!failure] 误以为组数 = 乘积
> 某些组合不存在时不会补空行。要做"全组合"得 `LEFT JOIN` 维度表。

---

## 十、速查表

| 需求 | 写法 |
| --- | --- |
| 全表汇总（1 行） | 只写聚合函数，不写 `GROUP BY` |
| 按维度汇总 | `GROUP BY dept` |
| 多维度组合 | `GROUP BY dept, gender` |
| 分组前过滤行 | `WHERE ... GROUP BY ...` |
| 分组后过滤组 | `GROUP BY ... HAVING ...` |
| 分组结果排序 | `GROUP BY ... ORDER BY ...` |
| 追加小计/总计 | `GROUP BY 列 WITH ROLLUP` |
| 区分 ROLLUP 的 NULL | `GROUPING(列)` |
| 去重（不需聚合） | `SELECT DISTINCT 列`（与 `GROUP BY` 等价） |
| 走索引分组 | 联合索引列顺序 = `GROUP BY` 列顺序 |

> [!question] 自测三连
> 1. 8 行数据 `GROUP BY dept` 为什么只出来 3 行？
> 2. `GROUP BY dept, gender` 一定返回 6 行吗？为什么？
> 3. `SELECT DISTINCT dept FROM emp` 和 `SELECT dept FROM emp GROUP BY dept` 有什么区别？

---

> [!quote] 一句话记忆
> **`GROUP BY` 决定聚合的粒度**：没有它全表算一组，有了它每维度一组、一组只出一行；`SELECT` 里只能留"**分组列 + 聚合函数 + 常量**"，多了就是 `ERROR 1055`；分组结果**默认无序**，要顺序必须 `ORDER BY`。

---

## 相关笔记

- [[计算机类/数据库/Mysql/DML/Group By]] —— **完整版**：语法细节、聚合函数速查、`GROUP_CONCAT`、`ROLLUP` 逐级汇总
- [[计算机类/数据库/Mysql/聚合查询/HAVING]] —— 分组之后过滤**组**
- [[计算机类/数据库/Mysql/DML/Select]] —— 各子句执行顺序、`DISTINCT` 与别名
- [[计算机类/数据库/Mysql/DML/Where]] —— 分组**前**过滤行
- [[计算机类/数据库/Mysql/DML/Order By]] —— 分组结果排序
- [[计算机类/数据库/Mysql/聚合查询/COUNT]] · [[计算机类/数据库/Mysql/聚合查询/SUM]] · [[计算机类/数据库/Mysql/聚合查询/AVG]] · [[计算机类/数据库/Mysql/聚合查询/MAX]] · [[计算机类/数据库/Mysql/聚合查询/MIN]] —— 五个聚合函数
