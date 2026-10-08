# ORDER BY —— 排序

> [!abstract] 一句话
> `ORDER BY` 对**最终结果集**排序，执行顺序上排在 `SELECT` **之后**、`LIMIT` **之前**——所以它能用 `SELECT` 里刚起的别名，`WHERE` 不能。

---

> [!example] 本篇示例数据
> 三篇笔记（`ORDER BY` / `GROUP BY` / `HAVING`）**共用同一张 `emp` 表**。两个考点：**`bonus` 有 3 行是 NULL**，**部门名是中文**。

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

## 一、语法

```sql
SELECT 列1, 列2 FROM 表 WHERE 行级条件
ORDER BY 列1 [ASC|DESC], 列2 [ASC|DESC] ...
LIMIT n;
```

| 要点 | 说明 |
| --- | --- |
| 位置 | **倒数第二个子句**，后面只剩 `LIMIT` |
| 默认值 | ==**不写就是 `ASC`**==，`ORDER BY salary` 等价于 `ORDER BY salary ASC` |
| 多列 | 逗号分隔，先按第一列排，**第一列相同**再按第二列排 |
| NULL | 默认被当作**最小值**（见第四节） |

> [!tip] DESC 只作用于紧跟它的那一列
> `ORDER BY a DESC, b` 是"a 降序、**b 升序**"。两列都要降序必须写两遍 `a DESC, b DESC`。

### 1.1 按列序号排序：能跑，但别用

```sql
SELECT name, dept, salary FROM emp ORDER BY 2 DESC;   -- 2 = SELECT 里的第 2 列 dept
-- 结果：销售部 → 财务部 → 研发部（按 dept 降序）
```

> [!failure] 为什么不推荐列序号
> ① `SELECT` 里**一改列顺序就出错**：`dept` 挪到第 3 位后，`ORDER BY 2` 从"按部门"悄悄变成"按工资"，**不报错但结果是错的**；
> ② `ORDER BY 5 DESC` 谁也不知道第 5 列是什么，得来回数；
> ③ 表结构变动后语义会漂移。正经代码一律写列名。

---

## 二、单列排序与多列排序

```sql
SELECT name, dept, salary FROM emp ORDER BY salary DESC;
```

```
+--------+--------+----------+
| name   | dept   | salary   |
+--------+--------+----------+
| 王强   | 研发部 | 15000.00 |
| 张伟   | 研发部 | 12000.00 |
| 周杰   | 财务部 |  9500.00 |
| 李娜   | 研发部 |  9000.00 |
| 赵敏   | 销售部 |  8000.00 |
| 刘洋   | 销售部 |  7500.00 |
| 孙悦   | 财务部 |  7000.00 |
| 陈晨   | 销售部 |  6500.00 |
+--------+--------+----------+
```

去掉 `DESC` 结果就是完全倒过来：陈晨 6500 → 孙悦 7000 → … → 王强 15000。

```sql
-- 先按部门排，同一个部门内再按工资从高到低排
SELECT dept, name, salary FROM emp ORDER BY dept ASC, salary DESC;
```

```
+--------+--------+----------+
| dept   | name   | salary   |
+--------+--------+----------+
| 研发部 | 王强   | 15000.00 |   <- 研发部内 salary 降序
| 研发部 | 张伟   | 12000.00 |
| 研发部 | 李娜   |  9000.00 |
| 财务部 | 周杰   |  9500.00 |   <- 财务部内 salary 降序
| 财务部 | 孙悦   |  7000.00 |
| 销售部 | 赵敏   |  8000.00 |   <- 销售部内 salary 降序
| 销售部 | 刘洋   |  7500.00 |
| 销售部 | 陈晨   |  6500.00 |
+--------+--------+----------+
```

> [!warning] 部门顺序为什么是"研发 → 财务 → 销售"？
> 默认按 **utf8mb4 编码值**比较：`研`(U+7814) < `财`(U+8D22) < `销`(U+9500)。既不是拼音序也不是笔画序，想按拼音必须显式转换（见第六节）。

> [!info] 多列排序的本质
> 就是 Excel 的"多级排序"：第一列是**主关键字**，第二列只在主关键字**打平时**才起作用。第一列没有重复值时，第二列写了也白写。

---

## 三、能用 SELECT 别名（与 WHERE 的最大区别）

```sql
-- ✅ 合法：别名 annual 直接用在 ORDER BY 里
SELECT name, salary * 12 AS annual FROM emp ORDER BY annual DESC;

-- ❌ 报错：别名用在 WHERE 里
SELECT name, salary * 12 AS annual FROM emp WHERE annual > 100000;
-- ERROR 1054 (42S22): Unknown column 'annual' in 'where clause'
```

`ORDER BY annual DESC` 的结果：

```
+--------+-----------+
| name   | annual    |
+--------+-----------+
| 王强   | 180000.00 |
| 张伟   | 144000.00 |
| 周杰   | 114000.00 |
| 李娜   | 108000.00 |
| 赵敏   |  96000.00 |
| 刘洋   |  90000.00 |
| 孙悦   |  84000.00 |
| 陈晨   |  78000.00 |
+--------+-----------+
```

> [!tip] 为什么一个能用一个不能用
> 因为**书写顺序 ≠ 执行顺序**：
>
> | 书写顺序 | 执行顺序 | 子句 |
> | --- | --- | --- |
> | 1 | 1 | `FROM` |
> | 2 | 2 | `WHERE` |
> | 3 | 3 | `GROUP BY` |
> | 4 | 4 | `HAVING` |
> | 5 | 5 | `SELECT`（**别名在这里才诞生**） |
> | 6 | 6 | `ORDER BY` |
> | 7 | 7 | `LIMIT` |
>
> `WHERE` 执行时 `SELECT` 还没跑，别名不存在；`ORDER BY` 执行时结果集已经带上别名了。

> [!danger] WHERE 里想用计算结果的正确写法
> 别名用不了，就把表达式**原样再写一遍**：`WHERE salary * 12 > 100000`。
> 代价是表达式算两遍（优化器通常会合并）。数据量大时，`WHERE` 里给字段套函数会**让索引失效**——能用列本身的条件就别套函数。

---

## 四、NULL 排在哪

> [!important] 一句话结论
> MySQL 把 `NULL` 当成**比任何值都小**的存在：`ASC` 时排**最前面**，`DESC` 时排**最后面**。
> Oracle 正好相反（NULL 最大，ASC 排最后）——这是跨库迁移的经典翻车点。

```sql
SELECT name, bonus FROM emp ORDER BY bonus ASC;
```

```
+--------+---------+
| name   | bonus   |
+--------+---------+
| 李娜   |    NULL |   <- NULL 在最前
| 陈晨   |    NULL |
| 孙悦   |    NULL |
| 赵敏   | 3000.00 |
| 刘洋   | 3000.00 |
| 周杰   | 4000.00 |
| 张伟   | 5000.00 |
| 王强   | 8000.00 |
+--------+---------+
```

> [!note] 三行 NULL 之间谁先谁后？
> **不保证**。它们互相之间没有大小关系，返回顺序取决于扫描顺序和排序算法，换个版本、加个索引都可能变。
> 要结果稳定，必须再加一个**唯一列**做决胜：`ORDER BY bonus ASC, id ASC`。

改成 `DESC`，`NULL` 就跑到最后：王强 8000 → 张伟 5000 → 周杰 4000 → 赵敏 3000 → 刘洋 3000 → 然后才是三行 NULL。

### 4.1 强制让 NULL 排最后

```sql
-- bonus IS NULL 对 NULL 行返回 1，对非 NULL 行返回 0
-- 先按 0/1 升序（非 NULL 在前），再按 bonus 升序
SELECT name, bonus FROM emp ORDER BY bonus IS NULL, bonus;
```

```
+--------+---------+
| name   | bonus   |
+--------+---------+
| 赵敏   | 3000.00 |
| 刘洋   | 3000.00 |
| 周杰   | 4000.00 |
| 张伟   | 5000.00 |
| 王强   | 8000.00 |
| 李娜   |    NULL |   <- 全部挪到末尾
| 陈晨   |    NULL |
| 孙悦   |    NULL |
+--------+---------+
```

> [!success] 万能优先级公式
> `ORDER BY <表达式>, 列`：**先用表达式造排序优先级，再用真实列排细序**。
> - `ORDER BY bonus IS NULL, bonus DESC` → 有奖金的按降序，没奖金的沉底
> - `ORDER BY status = '已完成', created_at` → 未完成的优先展示
> 比 `CASE WHEN` 写法短得多，效果一样。

---

## 五、配合 LIMIT 取 Top N

```sql
SELECT name, dept, salary FROM emp ORDER BY salary DESC LIMIT 3;
```

```
+--------+--------+----------+
| name   | dept   | salary   |
+--------+--------+----------+
| 王强   | 研发部 | 15000.00 |
| 张伟   | 研发部 | 12000.00 |
| 周杰   | 财务部 |  9500.00 |
+--------+--------+----------+
```

> [!warning] 千万别写不带 ORDER BY 的 LIMIT
> `SELECT * FROM emp LIMIT 3;` 是"**随便** 3 行"，不是"前 3 行"。不排序时 MySQL 没有义务按 id 顺序返回，加索引、改引擎、分页都可能让结果变化。**要 Top N 就必须先有确定的排序。**

### 5.1 经典难题：每个部门工资最高的 N 个人

`ORDER BY + LIMIT` 只能取**全局** Top N，取不了"每组 Top N"——`LIMIT` 作用在整个结果集上，它根本不知道"组"是什么。

> [!question] 为什么 `GROUP BY dept ORDER BY salary DESC LIMIT 3` 是错的？
> `GROUP BY` 之后每个部门只剩**一行**（组），另外两个人**已经被丢掉了**，不可能再取出来；`LIMIT 3` 只是从 3 个部门里挑 3 行，等于把"每组取第 1 名"当成了"每组取前 3 名"。
> 正确思路是**先给组内每行打上名次，再筛名次**——这就是窗口函数要做的事。

```sql
SELECT dept, name, salary, rn
FROM (
    SELECT dept, name, salary,
           ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC) AS rn
    FROM emp
) AS t
WHERE rn <= 2
ORDER BY dept, rn;
```

```
+--------+--------+----------+----+
| dept   | name   | salary   | rn |
+--------+--------+----------+----+
| 研发部 | 王强   | 15000.00 |  1 |
| 研发部 | 张伟   | 12000.00 |  2 |
| 财务部 | 周杰   |  9500.00 |  1 |
| 财务部 | 孙悦   |  7000.00 |  2 |
| 销售部 | 赵敏   |  8000.00 |  1 |
| 销售部 | 刘洋   |  7500.00 |  2 |
+--------+--------+----------+----+
```

| 部分 | 作用 |
| --- | --- |
| `PARTITION BY dept` | 按部门**切窗口**，每个部门**独立**排名 |
| `ORDER BY salary DESC` | 窗口内排序，决定谁排第 1 |
| `ROW_NUMBER()` | 给窗口内每行发一个**连续不重复**的序号 |
| 外层 `WHERE rn <= 2` | **不能在里层筛**，窗口函数在 `WHERE` 之后才算出来 |

> [!tip] 三个排名函数怎么选
> - `ROW_NUMBER()`：1、2、3、4 —— **严格不重复**，并列也硬分先后
> - `RANK()`：1、2、2、4 —— 并列跳号
> - `DENSE_RANK()`：1、2、2、3 —— 并列不跳号
> 三个人工资相同时，三者返回的行数完全不同，按业务语义选。**8.0 以下**没有窗口函数，只能自连接数排名，写法丑性能差——能升级就用 8.0。

---

## 六、中文排序：默认不是拼音序

> [!danger] 最容易被忽略的坑
> `utf8mb4` 的默认排序规则对中文是**按 Unicode 码点**比较的，而码点在汉字区大致按**部首/笔画**分布，**不是拼音**。
> 结果：`ORDER BY name` 出来的名单，中国人看着"乱得一塌糊涂"。

```sql
SELECT name FROM emp ORDER BY name;                          -- 默认：编码序
SELECT name FROM emp ORDER BY CONVERT(name USING gbk);       -- 拼音序
SELECT name FROM emp ORDER BY name COLLATE gbk_chinese_ci;   -- 等价写法
```

| 默认（utf8mb4 编码序） | 拼音序（转 gbk 后） |
| --- | --- |
| 刘洋（U+5218） | 陈晨（chen） |
| 周杰（U+5468） | 李娜（li） |
| 孙悦（U+5B59） | 刘洋（liu） |
| 张伟（U+5F20） | 孙悦（sun） |
| 李娜（U+674E） | 王强（wang） |
| 王强（U+738B） | 张伟（zhang） |
| 赵敏（U+8D75） | 赵敏（zhao） |
| 陈晨（U+9648） | 周杰（zhou） |

部门同理：默认是 `研发部 → 财务部 → 销售部`；转 gbk 后变成 `财务部 → 销售部 → 研发部`（cai < xiao < yan，符合直觉）。

> [!warning] gbk 转换的两个代价
> ① **用不上索引**——`CONVERT(name USING gbk)` 是函数，`name` 上的索引直接失效，每次全表 + filesort，数据量大时很慢；
> ② **生僻字 / emoji 会丢**——gbk 装不下 emoji，转换后变成 `?`，排序位置就错了。
> **正解**：建表时就用带拼音的排序规则（如 `utf8mb4_zh_0900_as_cs`），或额外存一列 `name_pinyin`。`CONVERT` 只适合临时查询。

---

## 七、自定义顺序：FIELD()

业务顺序既不按大小也不按字母时（比如订单状态"待付款 → 已付款 → 已发货 → 已完成"），按字典序排就成了"已完成 → 已发货 → 待付款 → 已付款"，完全没法看。

`FIELD(value, v1, v2, ...)` 返回 `value` 在列表中的位置（从 1 开始），**找不到返回 0**，拿它当排序键正好。

```sql
-- 部门按老板心里的重要性排：销售 > 研发 > 财务
SELECT name, dept, salary FROM emp
ORDER BY FIELD(dept, '销售部', '研发部', '财务部'), salary DESC;
```

```
+--------+--------+----------+
| name   | dept   | salary   |
+--------+--------+----------+
| 赵敏   | 销售部 |  8000.00 |   FIELD=1
| 刘洋   | 销售部 |  7500.00 |
| 陈晨   | 销售部 |  6500.00 |
| 王强   | 研发部 | 15000.00 |   FIELD=2
| 张伟   | 研发部 | 12000.00 |
| 李娜   | 研发部 |  9000.00 |
| 周杰   | 财务部 |  9500.00 |   FIELD=3
| 孙悦   | 财务部 |  7000.00 |
+--------+--------+----------+
```

订单状态的标准写法：

```sql
SELECT order_no, status FROM `order`
ORDER BY FIELD(status, '待付款', '已付款', '已发货', '已完成'), created_at DESC;
```

> [!warning] FIELD 的两个注意点
> ① **列表里没写的值返回 0，会排到最前面**（0 比任何位置都小）。要么把取值写全，要么用 `FIELD(...) = 0` 把未知值甩到末尾；
> ② **完全用不上索引**，每次都是全表 filesort，只适合小结果集或状态值很少的场景。
> 工程化替代方案：表里加一列 `sort_no TINYINT` 存排序号，然后 `ORDER BY sort_no`，能走索引。

---

## 八、性能：会不会用上索引

| 路径 | 触发条件 | 代价 |
| --- | --- | --- |
| 利用索引 | `ORDER BY` 的列顺序与索引列顺序**完全一致**、方向一致 | ==**零成本**==，索引本身就是有序的 |
| `Using filesort` | 其他所有情况 | 把结果集读进来，**再排一次** |

```sql
EXPLAIN SELECT * FROM emp ORDER BY salary DESC;
```

```
+----+-------+------+------+------+----------------+
| id | table | type | key  | rows | Extra          |
+----+-------+------+------+------+----------------+
|  1 | emp   | ALL  | NULL |    8 | Using filesort |
+----+-------+------+------+------+----------------+
```

加上索引后 `Extra` 就变了：

```sql
ALTER TABLE emp ADD INDEX idx_salary (salary);
-- 再 EXPLAIN：Extra = "Backward index scan"，Using filesort 消失
```

> [!danger] 看到 `Using filesort` 就要警惕
> 名字里有 "file" 但**不一定真写磁盘**，数据量小在内存里排完就行。但它的含义是"**MySQL 必须额外做一次排序**"，这是纯粹的额外开销，大表上响应时间会从毫秒级跳到秒级。

> [!tip] 让 ORDER BY 走索引的三条军规
> ① **`WHERE` 和 `ORDER BY` 用同一个索引**：索引 `(dept, salary)` 配 `WHERE dept='研发部' ORDER BY salary` 最优——`dept` 用于定位、`salary` 天然有序、`LIMIT` 还能**边扫边停**；
> ② **排序方向要一致**：`ORDER BY a ASC, b DESC` 在 8.0 之前用不了普通联合索引，需要降序索引 `INDEX (a ASC, b DESC)`；
> ③ **别排序函数结果**：`ORDER BY UPPER(name)`、`ORDER BY CONVERT(name USING gbk)` 一律 filesort，索引帮不上忙。

> [!success] ORDER BY + LIMIT 的提前终止红利
> 排序列有索引时，`ORDER BY salary DESC LIMIT 10` **不需要读完整个表**——索引本身有序，从尾部倒着读 10 条就停。
> 1000 万行的表取 Top 10，代价和 100 行的表差不多。**这也是分页查询应该用"排序键"而不是 `LIMIT offset, n` 的根本原因。**

---

## 九、速查表

| 需求 | 写法 | 备注 |
| --- | --- | --- |
| 升序 | `ORDER BY col` | `ASC` 是默认值，可省 |
| 降序 | `ORDER BY col DESC` | 只影响紧跟的这一列 |
| 多列 | `ORDER BY a, b DESC` | a 主序，b 只在 a 打平时生效 |
| 用别名 | `ORDER BY annual` | 因为执行顺序在 `SELECT` 之后 |
| 用列序号 | `ORDER BY 2` | 能跑，但**强烈不推荐** |
| NULL 排最后 | `ORDER BY col IS NULL, col` | 万能优先级套路 |
| Top N | `ORDER BY col DESC LIMIT n` | 必须和 `ORDER BY` 一起用 |
| 每组 Top N | `ROW_NUMBER() OVER (PARTITION BY ...)` | 8.0+ 窗口函数 |
| 拼音序 | `ORDER BY CONVERT(col USING gbk)` | 用不了索引，慎用 |
| 自定义序 | `ORDER BY FIELD(col, 'a','b')` | 没列出的值返回 0 排最前 |
| 稳定排序 | `ORDER BY col, id` | 加唯一列破并列 |

> [!question] 自测三连
> ① `SELECT a AS x FROM t WHERE x > 1` 报什么错？为什么 `ORDER BY x` 不报？
> ② `score` 有 3 个 NULL，`ORDER BY score DESC` 时它们落在结果集的哪一端？
> ③ 想让"没有 bonus 的员工"排最后、其他人按 bonus 升序，`ORDER BY` 后面写什么？

---

> [!quote] 一句话记忆
> **ORDER BY 排在 SELECT 之后，所以能用别名；WHERE 排在 SELECT 之前，所以不能用。**
> 补充三点：**默认 ASC**；**NULL 最小**（ASC 在前、DESC 在后）；**不写 ORDER BY 就没有顺序可言**，`LIMIT` 也就失去了意义。

---

## 相关笔记

- [[Select]] —— 查询的整体结构与子句顺序
- [[Where]] —— 行级过滤，执行在 ORDER BY 之前
- [[计算机类/数据库/Mysql/DML/Group By]] —— 分组，分组完再排序
- [[计算机类/数据库/Mysql/DML/Having]] —— 分组后的过滤
- [[From]] —— 数据来源与多表连接
- [[Join]] —— 多表查询后同样可以排序
- [[Create Table]] —— 建表时定好排序规则（collation）能省掉中文排序的麻烦
