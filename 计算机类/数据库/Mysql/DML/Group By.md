# GROUP BY —— 分组

> [!abstract] 一句话
> `GROUP BY` 把行**按某个标准归类成若干组**，之后所有操作的对象就从"行"变成了"组"。所以 `SELECT` 里只能出现分组列和聚合函数——**你没法给一个组指定单个名字**。

---

> [!example] 本篇示例数据
> 与 `ORDER BY` / `HAVING` 两篇**共用同一张 `emp` 表**，三篇对照着看效果最好。
> 两个关键设计：**`bonus` 有 3 行是 `NULL`**（用来辨析 `COUNT` 家族和 `AVG` 的分母），**共 3 个部门、男女齐全**（用来演示多列分组）。

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

## 一、语法骨架

```sql
SELECT 分组列, 聚合函数(列)
FROM 表名
WHERE 行级条件            -- 分组前过滤
GROUP BY 分组列1, 分组列2
HAVING 组级条件           -- 分组后过滤
ORDER BY 排序列;
```

| 子句 | 必须写吗 | 作用对象 | 说明 |
| --- | --- | --- | --- |
| `WHERE` | 可选 | **行** | 在分组**前**把不要的行扔掉 |
| `GROUP BY` | 用了聚合就建议写 | — | 定义"按什么归类" |
| `HAVING` | 可选 | **组** | 在分组**后**把不要的组扔掉 |
| `ORDER BY` | 可选 | 结果集 | 分组结果**默认无序**，要排序必须显式写 |

最简单的分组统计：

```sql
SELECT dept, COUNT(*) AS 人数, SUM(salary) AS 工资总额
FROM emp
GROUP BY dept;
```

```
+--------+--------+--------------+
| dept   | 人数   | 工资总额     |
+--------+--------+--------------+
| 研发部 |      3 |     36000.00 |
| 财务部 |      2 |     16500.00 |
| 销售部 |      3 |     22000.00 |
+--------+--------+--------------+
```

> [!tip] 分组的心理模型
> 想象把 8 行数据**倒进 3 个篮子**：`研发部` 篮子 3 行、`财务部` 篮子 2 行、`销售部` 篮子 3 行。
> 之后所有计算都在"篮子"层面进行——`COUNT(*)` 数篮子里有几个，`SUM(salary)` 把篮子里的工资加起来。
> **一个篮子只能产出一行结果**，所以 8 行进去、3 行出来。

---

## 二、分组后 SELECT 里能写什么（核心规则）

> [!important] 三条铁律
> `GROUP BY` 之后，`SELECT` 列表里**只允许出现三种东西**：
> 1. **分组列**（写在 `GROUP BY` 里的列）
> 2. **聚合函数**（`COUNT` / `SUM` / `AVG` / `MAX` / `MIN` / `GROUP_CONCAT` …）
> 3. **常量表达式**（`1`、`'总计'`、`NOW()` 这类与行无关的值）
>
> 除此之外的**非分组列，一律不许写**。

### 2.1 写了会怎样：ERROR 1055

```sql
-- ❌ 想同时看部门和员工姓名
SELECT dept, name, AVG(salary) FROM emp GROUP BY dept;
```

```
ERROR 1055 (42000): Expression #2 of SELECT list is not in GROUP BY clause
and contains nonaggregated column 'test.emp.name' which is not functionally
dependent on columns in GROUP BY clause; this is incompatible with
sql_mode=only_full_group_by
```

报错原因很直白：`研发部` 这个组里有 **3 个** `name`（张伟、李娜、王强），MySQL 不知道该给你哪一个。

> [!info] `only_full_group_by` 是什么
> 它是 MySQL 5.7 起**默认开启**的 `sql_mode` 选项，专门用来拦住上面这种"语义不明确"的写法。
> 用 `SELECT @@sql_mode;` 查看，能改但我劝你别改——见下一节。

### 2.2 关掉模式后：更可怕的静默错误

> [!danger] 这才是真正的坑
> 把 `only_full_group_by` 去掉，上面那条 SQL **不报错了**，但它返回的 `name` 是**组内随机某一行的值**——MySQL 官方文档的措辞是 "the values are chosen from **an indeterminate row**"。
> **不报错、有结果、结果是错的**，这种错误比 ERROR 1055 危险一百倍。生产环境的统计报表算错，往往就是这里埋的雷。

```sql
-- ⚠️ 只为演示，不要在生产环境这么干
SET SESSION sql_mode = '';   -- 关掉 only_full_group_by

SELECT dept, name, salary FROM emp GROUP BY dept;
```

```
+--------+--------+----------+
| dept   | name   | salary   |          <- 结果可能变成右边这样
+--------+--------+----------+
| 研发部 | 张伟   | 12000.00 |   或 李娜 9000.00 或 王强 15000.00
| 财务部 | 孙悦   |  7000.00 |   或 周杰 9500.00
| 销售部 | 赵敏   |  8000.00 |   或 陈晨 6500.00 或 刘洋 7500.00
+--------+--------+----------+
```

同一个查询在这台机器上返回 `张伟`，换台机器可能返回 `王强`，改动一下索引又变回 `李娜`——**存储引擎、分组算法（8.0 默认哈希分组）、MySQL 版本升级都会改变结果，官方明确说过"不保证"**。

> [!success] 正确做法
> 想要"组内某一行"，就用**聚合函数把意图写清楚**，或者用窗口函数点名：
> - 想要工资最高的那个人 → `MAX(salary)` 只能拿到值，拿不到人；要**用人就用 `ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC)`**
> - 想要拼接组内所有人 → `GROUP_CONCAT(name)`（第七节）
> 总之：**永远不要依赖"随机某一行"**。

---

## 三、多列分组

`GROUP BY` 后面写多个列，就是按**组合**分组。组数是各列取值个数的**乘积**（这里是 3 个部门 × 2 种性别 = 最多 6 组）。

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

> [!warning] 多列分组的顺序有讲究
> `GROUP BY dept, gender` 和 `GROUP BY gender, dept` 的**结果集完全一样**（组是一样的），但：
> 1. 默认返回顺序不同（按分组键字典序）
> 2. 能不能用上索引不同——索引 `(dept, gender)` 只能加速 `GROUP BY dept, gender`，反过来用不上
>
> 所以多列分组时，**让 `GROUP BY` 的列顺序和索引列顺序一致**。

> [!note] 组数不是"一定"等于乘积
> 3 部门 × 2 性别 = 理论上 6 组，恰好这里是 6 组。但如果某个部门全是男性，`(该部门, F)` 这一组**根本不存在**，不会返回一行空的。
> 想让不存在的组合也显示出来，得用 `LEFT JOIN` 一张"全组合表"，这是做交叉报表的常见需求。

---

## 四、五个常用聚合函数速查

| 函数 | 作用 | 忽略 NULL？ | `bonus` 列（3 行 NULL）上的结果 |
| --- | --- | --- | --- |
| `COUNT(*)` | 统计**行数** | ❌ **不忽略** | `8` |
| `COUNT(列)` | 统计该列**非 NULL** 的行数 | ✅ 忽略 | `COUNT(bonus)` = `5` |
| `SUM(列)` | 求和 | ✅ 忽略 | `23000.00` |
| `AVG(列)` | 求平均 | ✅ 忽略 | `4600.00` |
| `MAX(列)` | 最大值 | ✅ 忽略 | `8000.00` |
| `MIN(列)` | 最小值 | ✅ 忽略 | `3000.00` |

> [!important] 记住这一句就够
> ==**除了 `COUNT(*)`，所有聚合函数都忽略 NULL。**==
> `SUM` 忽略 NULL 不影响结果（加 0 嘛），但 **`AVG` 忽略 NULL 会改变分母**——这是最实际的坑，第六节专门讲。
> `MAX` / `MIN` 忽略 NULL 意味着：**全组都是 NULL 时返回 NULL，而不是 0**。

```sql
SELECT
    COUNT(*)          AS 总行数,
    COUNT(bonus)      AS 有奖金的,
    SUM(bonus)        AS 奖金总额,
    AVG(bonus)        AS 奖金平均,
    MAX(bonus)        AS 最高奖金,
    MIN(bonus)        AS 最低奖金
FROM emp;
```

```
+--------+----------+----------+----------+----------+----------+
| 总行数 | 有奖金的 | 奖金总额 | 奖金平均 | 最高奖金 | 最低奖金 |
+--------+----------+----------+----------+----------+----------+
|      8 |        5 | 23000.00 |  4600.00 |  8000.00 |  3000.00 |
+--------+----------+----------+----------+----------+----------+
```

> [!tip] 聚合函数可以嵌套计算表达式
> `SUM(salary * 12)`、`MAX(salary - 3000)` 都是合法的，聚合的是**表达式的结果**而不是原始列。
> 但**聚合函数不能嵌套聚合函数**：`SUM(COUNT(*))` 会报 `ERROR 1111`（详见 `HAVING` 那篇的报错合集）。

---

## 五、COUNT 家族辨析（重点）

`COUNT` 是面试最爱问的聚合函数。同一张表上四种写法，**结果能差一倍**。

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

| 写法 | 统计对象 | 是否忽略 NULL | 结果 | 何时用 |
| --- | --- | --- | --- | --- |
| `COUNT(*)` | **行数**（整行，含全 NULL 行） | ❌ 不忽略 | `8` | 数"有多少条记录"，最常用 |
| `COUNT(1)` | 同上，逐行评估常量 1 | ❌ 不忽略 | `8` | 语义上等价，纯粹写法差异 |
| `COUNT(bonus)` | `bonus` **非 NULL** 的行数 | ✅ 忽略 | `5` | 数"有多少人填了这一项" |
| `COUNT(DISTINCT bonus)` | `bonus` 去重后的**不同值**个数 | ✅ 忽略 | `4` | 数"有几种不同的值" |

### 5.1 COUNT(*) vs COUNT(1)：真的一样吗

> [!question] 面试官问：`COUNT(*)` 和 `COUNT(1)` 谁快？
> **标准答案：一样快。** `COUNT(*)` 不是"把每一列都读出来数一遍"，优化器会把它**重写**成等价逻辑，两者执行计划完全相同。
> 网上流传的"`COUNT(1)` 更快"是**针对 Oracle 的老结论**（Oracle 里 `COUNT(*)` 要展开列），**MySQL 上不成立**。惯例写 `COUNT(*)`，语义最明确。

> [!info] InnoDB 的 COUNT(*) 为什么慢
> MyISAM 把总行数**存在磁盘上**，不带 `WHERE` 的 `COUNT(*)` 直接返回；InnoDB **不存**总行数（有 MVCC，每个事务看到的行数可能不同），必须真的扫一遍索引。
> 替代方案：自己维护计数表，或用 `information_schema.TABLES.TABLE_ROWS`（**近似值，误差可达 40%**）。

### 5.2 COUNT(列) 与 COUNT(DISTINCT 列)

`bonus` 列实际是 `5000, NULL, 8000, 3000, NULL, 3000, NULL, 4000`：`COUNT(*)` 数 8 行；`COUNT(bonus)` 只数 5 个非 NULL；`COUNT(DISTINCT bonus)` 把两个 `3000` 合成一个，得 `4`。

```sql
-- 实用场景：一个部门有 5 个人，但这 5 个人分布在 3 个城市
SELECT dept, COUNT(*) AS 人数, COUNT(DISTINCT city) AS 覆盖城市数
FROM emp GROUP BY dept;
```

> [!failure] COUNT 最常见的写法错误
> 想数部门种类却写成裸列，结果差得离谱：
> - ❌ `SELECT COUNT(dept) FROM emp;` —— 想数部门数，得到 `8`
> - ✅ `SELECT COUNT(DISTINCT dept) FROM emp;` —— 得到 `3`
> 另外注意 `COUNT(NULL)` **永远等于 0**，`COUNT('abc')` 和 `COUNT(1)` 一样等于行数（常量非 NULL，每行都算 1）。
> 还有：`COUNT(DISTINCT a, b)` 是合法的，表示"按 (a,b) 组合去重"，不要以为它只能跟一列。

---

## 六、AVG 遇到 NULL：分母变了

> [!danger] 本节是本文最重要的坑
> `AVG(bonus)` 的分母是 ==**非 NULL 的行数**==，不是总行数。
> 8 个人里 3 个人没填奖金，`AVG(bonus)` 算的是 `SUM / 5` 而不是 `SUM / 8`。
> **业务方看到的"平均奖金 4600"其实比真实的"人均 2875"高出一大截**——报表算错就是这么来的。

具体演算：

| 项 | 值 | 说明 |
| --- | --- | --- |
| `SUM(bonus)` | `23000.00` | 5000 + 8000 + 3000 + 3000 + 4000 |
| 非 NULL 行数 | `5` | `COUNT(bonus)` |
| 总行数 | `8` | `COUNT(*)` |
| `AVG(bonus)` | `23000 / 5` = **`4600.00`** | 只除以有值的人 |
| `SUM(bonus) / COUNT(*)` | `23000 / 8` = **`2875.00`** | 除以**所有人**，把没奖金的人算作 0 |

```sql
-- 两种口径，差异一望便知
SELECT
    AVG(bonus)             AS 有奖金者平均,   -- 4600.00
    SUM(bonus) / COUNT(*)  AS 人均奖金        -- 2875.00
FROM emp;
```

```
+--------------+----------+
| 有奖金者平均 | 人均奖金 |
+--------------+----------+
|      4600.00 |  2875.00 |
+--------------+----------+
```

> [!tip] 想按总行数算平均，三种写法
> - `SELECT SUM(bonus) / COUNT(*) FROM emp;` —— 最直白
> - `SELECT AVG(IFNULL(bonus, 0)) FROM emp;` —— 把 NULL 当 0 再平均
> - `SELECT AVG(COALESCE(bonus, 0)) FROM emp;` —— 同义，标准 SQL 函数
> 三者结果都是 `2875.00`。**选哪种取决于业务口径**：
> - "填报单位的平均奖金是多少" → `AVG(bonus)`（只看填报了的）
> - "每个员工平均拿到多少奖金" → `SUM(bonus)/COUNT(*)`（没拿到就是 0）
>
> 这类口径问题**必须问清楚需求方**，代码层面没有对错。

> [!warning] 全组都是 NULL 时
> 跑一下 `SELECT AVG(bonus) FROM emp WHERE dept = '不存在的部门';`
> **返回 `NULL`**（不是 `0`，也不是报错）。
> 空集上 `AVG`/`SUM`/`MAX`/`MIN` 都返回 `NULL`，只有 `COUNT` 返回 `0`。
> 所以前端展示时通常要套一层：`IFNULL(AVG(bonus), 0)`。

---

## 七、GROUP_CONCAT：把组内值拼成字符串

聚合函数不止算数，`GROUP_CONCAT` 能把组内的值**拼成一串**，做"部门成员名单"这类需求特别顺手。

```sql
SELECT dept,
       GROUP_CONCAT(name ORDER BY salary DESC SEPARATOR '、') AS 成员,
       COUNT(*) AS 人数
FROM emp
GROUP BY dept;
```

```
+--------+------------------+--------+
| dept   | 成员             | 人数   |
+--------+------------------+--------+
| 研发部 | 王强、张伟、李娜 |      3 |
| 财务部 | 周杰、孙悦       |      2 |
| 销售部 | 赵敏、刘洋、陈晨 |      3 |
+--------+------------------+--------+
```

完整语法：

```sql
GROUP_CONCAT(
    [DISTINCT] 列名
    [ORDER BY 排序列 [ASC|DESC]]     -- 组内排序，不写则顺序不定
    [SEPARATOR '分隔符']              -- 默认是英文逗号 ','
)
```

| 参数 | 是否可省 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `DISTINCT` | 可省 | 不去重 | 去重后再拼 |
| `ORDER BY` | 可省 | **顺序不定** | 想结果稳定就一定要写 |
| `SEPARATOR` | 可省 | `,` | 可换成 `、` `\|` ` -> ` 等 |

> [!danger] GROUP_CONCAT 有个隐藏截断
> 结果长度受系统变量 `group_concat_max_len` 限制，**默认只有 1024 字节**，超长部分会被**静默截断**（不报错！）。
> 一个组里拼几百个名字就可能被砍掉尾巴。要加大就执行 `SET SESSION group_concat_max_len = 1024 * 1024;`（1MB）。
> 排查建议：拼出来的字符串长度接近 1024 就该怀疑被截断了。

> [!note] 依赖分组顺序的"坑中坑"
> `GROUP_CONCAT` 的输出长度上限是按**一行**算的，而一行的长度在 MySQL 里也受 `max_allowed_packet` 影响。
> 另外它**不能和 `DISTINCT` + `ORDER BY` 之外的复杂表达式随意组合**，比如 `GROUP_CONCAT(DISTINCT name ORDER BY salary)` 在部分版本会报错，因为 `salary` 不在 `DISTINCT` 列表里。

---

## 八、WITH ROLLUP：自动追加汇总行

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
| NULL   |     74500.00 |   <- 合计行
+--------+--------------+
```

`WITH ROLLUP` 会在末尾补一行**全表汇总**，那个 `NULL` 就是"总计"的标记。多列分组时会**逐级汇总**：

```sql
SELECT dept, gender, COUNT(*) AS 人数
FROM emp
GROUP BY dept, gender WITH ROLLUP;
```

```
+--------+--------+--------+
| dept   | gender | 人数   |
+--------+--------+--------+
| 研发部 | F      |      1 |
| 研发部 | M      |      2 |
| 研发部 | NULL   |      3 |   <- 研发部小计
| 财务部 | F      |      1 |
| 财务部 | M      |      1 |
| 财务部 | NULL   |      2 |   <- 财务部小计
| 销售部 | F      |      2 |
| 销售部 | M      |      1 |
| 销售部 | NULL   |      3 |   <- 销售部小计
| NULL   | NULL   |      8 |   <- 全表总计
+--------+--------+--------+
```

> [!warning] ROLLUP 的 NULL 会和真实 NULL 混淆
> 如果 `dept` 本身有真实 `NULL` 值，你**分不清**哪个 NULL 是"未分配部门"、哪个是"小计行"。
> MySQL 提供了 `GROUPING(列)` 函数来区分：**返回 `1` 表示这是 ROLLUP 生成的 NULL，返回 `0` 表示是数据本身的 NULL**。
> 用法：`SELECT IF(GROUPING(dept), '总计', dept) AS 部门, SUM(salary) FROM emp GROUP BY dept WITH ROLLUP;`
> 这样"总计"那行就会显示成 `总计` 而不是 `NULL`。

> [!info] 8.0 也没有 GROUPING SETS
> `WITH ROLLUP` 只能做"逐级全汇总"，不能自定义汇总维度。标准 SQL 的 `GROUPING SETS` / `CUBE` 更灵活，但 **MySQL 到 8.0 仍未原生支持**（得用 `UNION ALL` 手写）。复杂交叉报表建议交给 BI 工具或应用层。

---

## 九、WHERE 与 GROUP BY 的配合

> [!important] 分工明确
> ==**分组前能过滤的，一律用 `WHERE`；分组后才能判断的，才用 `HAVING`。**==
> `WHERE` 先砍掉一批行，参与分组的行少了，后面所有计算都快。

```sql
-- 只看女性员工的部门统计
SELECT dept, COUNT(*) AS 人数, AVG(salary) AS 平均工资
FROM emp
WHERE gender = 'F'          -- 先过滤行：8 行 → 4 行
GROUP BY dept;              -- 再分组：4 行 → 3 组
```

```
+--------+--------+--------------+
| dept   | 人数   | 平均工资     |
+--------+--------+--------------+
| 研发部 |      1 |      9000.00 |
| 财务部 |      1 |      7000.00 |
| 销售部 |      2 |      7750.00 |
+--------+--------+--------------+
```

执行过程拆解：

| 阶段 | 动作 | 数据量 |
| --- | --- | --- |
| 1 | `FROM emp` 取全表 | 8 行 |
| 2 | `WHERE gender = 'F'` 过滤 | **4 行**（李娜、赵敏、刘洋、孙悦） |
| 3 | `GROUP BY dept` 分桶 | 3 组：研发 1 人、财务 1 人、销售 2 人 |
| 4 | 算 `COUNT` / `AVG` | 3 行结果 |

> [!tip] 同一个条件放前面的好处
> 把 `gender = 'F'` 放 `WHERE`，参与分组和聚合的只有 4 行；如果放到 `HAVING`，就要先把 8 行全部分组算完再扔掉。
> 数据量大时这是**数量级**的差别。而且 `WHERE` 能用索引，`HAVING` 不能。
> 详细的对比表和性能分析见 [[计算机类/数据库/Mysql/DML/Having]]。

---

## 十、分组结果默认无序

```sql
-- 你以为会按部门顺序出来？不一定
SELECT dept, COUNT(*) FROM emp GROUP BY dept;
```

> [!danger] 不写 ORDER BY 就没有顺序保证
> 分组用哈希算法时，返回顺序取决于哈希桶的遍历顺序；用排序算法时，取决于分组键的排序结果。**8.0 默认哈希分组，顺序和 5.7 经常不一样**。
> 更隐蔽的是：加个索引、改个数据量，MySQL 可能从哈希分组切换到排序分组，**结果顺序突然就变了**。
> 结论：**只要顺序对业务有意义，就必须显式写 `ORDER BY`**，哪怕你觉得"它本来就该是那个顺序"。

```sql
SELECT dept, COUNT(*) AS 人数, AVG(salary) AS 平均工资
FROM emp
GROUP BY dept
ORDER BY 平均工资 DESC;      -- 别名在这里能用，因为 ORDER BY 在 SELECT 之后
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

> [!success] 分页取"每组统计排名"
> 分组统计后按指标排序，再 `LIMIT` 取前 N，是"部门平均工资排行榜"这类需求的标准写法：
> `SELECT dept, AVG(salary) AS avg_sal FROM emp GROUP BY dept ORDER BY avg_sal DESC LIMIT 3;`
> **注意 `LIMIT` 作用于分组后的结果集，不是原始行**，这一点和 `ORDER BY` 那篇讲的"每组 Top N"完全不同。

---

## 十一、速查表

| 需求 | 写法 |
| --- | --- |
| 按部门统计人数 | `SELECT dept, COUNT(*) FROM emp GROUP BY dept;` |
| 按多列分组 | `GROUP BY dept, gender` （组数 = 组合数） |
| 分组前过滤 | `WHERE gender = 'F' GROUP BY dept` |
| 分组后过滤 | `GROUP BY dept HAVING COUNT(*) > 2` |
| 分组后排序 | `GROUP BY dept ORDER BY AVG(salary) DESC` |
| 数非 NULL 值 | `COUNT(列)` |
| 数不同值 | `COUNT(DISTINCT 列)` |
| 按总行数求平均 | `SUM(列) / COUNT(*)` |
| 拼接组内值 | `GROUP_CONCAT(列 ORDER BY x SEPARATOR '、')` |
| 追加合计行 | `GROUP BY 列 WITH ROLLUP` |

`SELECT` 列表里能出现什么，一张图记住：

| 能不能写 | 内容 | 例子 |
| --- | --- | --- |
| ✅ | 分组列 | `dept` |
| ✅ | 聚合函数 | `COUNT(*)`、`AVG(salary)` |
| ✅ | 常量表达式 | `'2026 年度'`、`NOW()` |
| ❌ | 非分组列 | `name` ← ERROR 1055 |
| ❌ | 聚合函数嵌套 | `SUM(COUNT(*))` ← ERROR 1111 |

> [!question] 自测三连
> 1. `SELECT dept, name FROM emp GROUP BY dept;` 在两个不同 `sql_mode` 下分别是什么结果？
> 2. 8 行数据中 `bonus` 有 3 个 NULL，`AVG(bonus)` 和 `SUM(bonus)/COUNT(*)` 哪个更大？为什么？
> 3. `GROUP BY dept, gender` 是不是一定返回 6 行？

---

> [!quote] 一句话记忆
> **GROUP BY 之后，行变组、明细变汇总**：`SELECT` 里只留"分组列 + 聚合函数 + 常量"，写了别的列就是 `ERROR 1055`；而 `COUNT` 认行、`SUM`/`AVG` 认非 NULL——**`AVG` 的分母永远比你想的小**。

---

## 相关笔记

- [[Select]] —— 查询整体结构与子句执行顺序
- [[Where]] —— 分组**前**过滤行
- [[计算机类/数据库/Mysql/DML/Having]] —— 分组**后**过滤组，`GROUP BY` 的最佳搭档
- [[Order By]] —— 分组结果默认无序，要排序靠它
- [[From]] —— 数据来源
- [[Join]] —— 多表连接后再分组统计
- [[Create Table]] —— 联合索引的列顺序会影响 `GROUP BY` 能否走索引
