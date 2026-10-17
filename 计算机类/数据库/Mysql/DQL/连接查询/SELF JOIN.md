# SELF JOIN —— 自连接

> [!abstract] 一句话
> 自连接就是==**同一张表自己跟自己连**==：把这张表在 `FROM` 里写两次，各起一个**别名**，让它变成"两张逻辑表"，再按普通连接处理。
> 典型场景：==**层级结构（员工-经理）、同表行间比较、成对匹配**==。

> [!info] 与 DML 版的分工
> [[Join|DML/Join]] 已给出自连接的基础示例。本篇聚焦它的==**三种典型场景、别名的必要性、内/外连接的选择、成对匹配的去重技巧、以及和子查询的取舍**==。

---

> [!example] 本篇示例数据
> 主例子用一张**自己指向自己**的 `emp_mgr`（`manager_id` → 同表的 `emp_id`）。
> 后半篇同表行间比较 / 成对匹配，复用同目录各篇共用的 `emp` / `dept` 表。

```sql
-- 层级表：每行指向自己的上级（老板的 manager_id 为 NULL）
CREATE TABLE emp_mgr (
    emp_id     INT PRIMARY KEY,
    emp_name   VARCHAR(20),
    manager_id INT             -- 指向本表的 emp_id
);

INSERT INTO emp_mgr VALUES (1, '张总', NULL),
                           (2, '张三', 1),
                           (3, '李四', 1),
                           (4, '王五', 2),
                           (5, '赵六', 2);
```

```
emp_id | emp_name | manager_id
-------+----------+-----------
     1 | 张总     |       NULL   <-- 老板，没有上级
     2 | 张三     |          1
     3 | 李四     |          1
     4 | 王五     |          2
     5 | 赵六     |          2
```

---

## 一、为什么会有"自己连自己"的表

自连接的适用前提是：**表里有一列存的是"同一张表另一行的主键"**。

| 场景 | 自指列 | 一句话 |
| --- | --- | --- |
| 组织架构 | `emp.manager_id` → `emp.emp_id` | 员工找上级 |
| 分类树 | `category.parent_id` → `category.id` | 商品分类、地区层级 |
| 评论楼中楼 | `comment.parent_comment_id` → `comment.id` | 回复某条评论 |
| 网页结构 | `page.prev_id` / `page.next_id` | 上一条 / 下一条 |

> [!note] 这类表**无法**靠"两张不同的表"来连
> 因为"员工"和"经理"其实是**同一张表里的两类行**。要在一行结果里同时看到两者，就得把这张表"扮演两次"——这正是自连接。

---

## 二、别名是生命线

```sql
-- ❌ 报错：同一张表出现两次，MySQL 分不清哪个是哪个
SELECT emp_name FROM emp_mgr JOIN emp_mgr ON emp_mgr.manager_id = emp_mgr.emp_id;
-- ERROR 1066 (42000): Not unique table/alias: 'emp_mgr'

-- ✅ 各起一个别名，变成两张逻辑表
SELECT e.emp_name, m.emp_name
FROM emp_mgr e
JOIN emp_mgr m ON e.manager_id = m.emp_id;
```

> [!important] 别名让"一张表"变成"两张逻辑表"
> - `e`：站在**下属**视角（`e.manager_id` 是它的上级编号）；
> - `m`：站在**经理**视角（`m.emp_id` 是经理自己的编号）。
> 之后所有列**必须带别名前缀**，否则报 `ERROR 1052 Column ... is ambiguous`（两张逻辑表有同名 `emp_name`）。

---

## 三、场景一：层级结构（员工 → 经理）

```sql
SELECT e.emp_name AS 员工, m.emp_name AS 经理
FROM emp_mgr e
LEFT JOIN emp_mgr m ON e.manager_id = m.emp_id
ORDER BY e.emp_id;
```

```
员工   | 经理
-------+------
张总   | NULL     <-- 老板没有上级，靠 LEFT JOIN 才留下来
张三   | 张总
李四   | 张总
王五   | 张三
赵六   | 张三
```

**5 行**，全员都在。

> [!danger] 换成内连接，老板就消失了
> ```sql
> SELECT e.emp_name AS 员工, m.emp_name AS 经理
> FROM emp_mgr e
> JOIN emp_mgr m ON e.manager_id = m.emp_id;   -- 内连接：只剩 4 行
> ```
> 张总的 `manager_id IS NULL`，`NULL = m.emp_id` 恒不成立 → 匹配不上 → 被内连接淘汰。
> ==**要留住"顶层/根节点"，自连接必须用 `LEFT JOIN`。**==

---

## 四、场景二：同表行间比较

查"工资比王五高的人"——把 `emp` 表连自己，一边当"被查的人"、一边当"参照人"：

```sql
SELECT a.emp_name AS 员工, a.salary AS 其工资,
       b.emp_name AS 参照人, b.salary AS 参照工资
FROM emp a
JOIN emp b ON a.salary > b.salary
WHERE b.emp_name = '王五';      -- 王五 9000
```

```
员工   | 其工资 | 参照人 | 参照工资
-------+--------+--------+----------
张三   |  12000 | 王五   |     9000
李四   |  15000 | 王五   |     9000
```

同一思路做"**同部门里谁工资高于谁**"（一对多成对比较）：

```sql
SELECT a.dept_id,
       a.emp_name AS 高薪者, a.salary AS 高,
       b.emp_name AS 低薪者, b.salary AS 低
FROM emp a
JOIN emp b
  ON a.dept_id = b.dept_id AND a.salary > b.salary;
```

```
dept_id | 高薪者 | 高    | 低薪者 | 低
--------+--------+-------+--------+------
   1001 | 李四   | 15000 | 张三   | 12000
   1002 | 王五   |  9000 | 赵六   |  8500
```

> [!tip] 自连接的杀手锏：**一行里并排显示两个"角色"**
> 子查询通常只能给"一个值"当条件；自连接能把**两行的列并排取出来**（谁、多少钱 vs 谁、多少钱），这是它相比子查询的独特价值。

---

## 五、场景三：成对匹配（去重 + 防自配）

要枚举"同部门的**任意两人组合**"：

```sql
SELECT a.emp_name AS 甲, b.emp_name AS 乙
FROM emp a
JOIN emp b
  ON a.dept_id = b.dept_id
 AND a.emp_id < b.emp_id      -- 关键：只取 id 较小的一侧
ORDER BY a.dept_id, a.emp_id;
```

```
甲     | 乙
-------+------
张三   | 李四     <-- 研发部
王五   | 赵六     <-- 销售部
```

只有 **2 组**。

> [!warning] 不加 `a.emp_id < b.emp_id` 会怎样
> 假设去掉这个条件、只留 `a.dept_id = b.dept_id`：
> 1. **自己配自己**：`(张三,张三)`、`(李四,李四)` … 每个员工都和自己配成一组；
> 2. **重复配对**：`(张三,李四)` 与 `(李四,张三)` 各出现一次。
> 研发部 2 人就会产出 2×2 = 4 行（含自配），而不是 1 行。
> ==**`a.id < b.id` 一举两得：既排除自配，又去掉"甲乙"顺序造成的重复。**==

---

## 六、自连接 vs 子查询：怎么选

自连接能做的事，很多也能用**相关子查询**完成。

```sql
-- 自连接：把两人的信息并排取出来
SELECT a.emp_name, a.salary, b.emp_name, b.salary
FROM emp a JOIN emp b ON a.dept_id = b.dept_id AND a.salary > b.salary;

-- 相关子查询：只回答"谁比同部门平均工资高"这样的一元问题
SELECT e.emp_name, e.salary
FROM emp e
WHERE e.salary > (SELECT AVG(x.salary) FROM emp x WHERE x.dept_id = e.dept_id);
```

| | 自连接 | 相关子查询 |
| --- | --- | --- |
| 输出 | 可**并排**取两行多列信息 | 通常只产出**一个值/一列** |
| 可读性 | 别名一多容易晕 | 意图更直接 |
| 性能 | 视索引而定，可能 n² | 视场景而定，有时更快 |

> [!tip] 选择口诀
> 要"**两行并排显示**"→ 自连接；只要"**一个值做过滤条件**"→ 子查询（`EXISTS` / `IN` / 标量子查询）。
> 更多见 [[相关子查询|相关子查询]] 与 [[嵌套查询|嵌套查询]]。

---

## 七、常见错误合集

> [!failure] 忘起别名 / 别名重名（ERROR 1066）
> `FROM emp_mgr JOIN emp_mgr ON ...` → `Not unique table/alias`。同一张表出现两次，**必须两个不同别名**。

> [!failure] 没加表前缀（ERROR 1052）
> `SELECT emp_name FROM emp e JOIN emp m ...` → `Column 'emp_name' ... is ambiguous`。自连接**一律 `SELECT e.xxx, m.xxx`**，用 `AS` 起可读的列名。

> [!failure] 该用 `LEFT JOIN` 却用了内连接，丢了顶层
> 层级结构里根节点（`manager_id IS NULL`）会被内连接吃掉。要留住根节点，用 `LEFT JOIN`。

> [!failure] 成对匹配忘了 `a.id < b.id`
> 结果里混进"自己配自己"，且每对被算了两次（甲乙顺序颠倒）。用 `<`（或 `<>` 配其它去重手段）修掉。

> [!failure] 三层自连接写晕
> `a JOIN b JOIN c` 三个别名分别代表什么角色？**先在纸上写清"每个别名扮演谁"**，再落 SQL，否则极易接错条件。

---

## 八、性能

| 关注点 | 说明 |
| --- | --- |
| 索引 | 自指列（`manager_id`、`parent_id`）**要建索引**，与普通连接同理 |
| 行数风险 | 自连接是"表 × 自己"，最坏 n²，注意匹配条件的**选择性** |
| 深度层级 | 标准 SQL 只能自连接**固定层数**；查"任意深度的树"要用**递归 CTE**（8.0+ `WITH RECURSIVE`） |
| 对比子查询 | 有时相关子查询反而更快，`EXPLAIN` 说了算 |

> [!info] 想查"任意层级"的树，自连接不够用
> 自连接适合"员工-经理"这种**固定一两层**的关系。要展开"从根到任意深度"的分类树 / 组织树，用 **递归 CTE**：
> ```sql
> WITH RECURSIVE tree AS (
>     SELECT emp_id, emp_name, manager_id, 1 AS lvl
>     FROM emp_mgr WHERE manager_id IS NULL          -- 从根开始
>     UNION ALL
>     SELECT e.emp_id, e.emp_name, e.manager_id, t.lvl + 1
>     FROM emp_mgr e JOIN tree t ON e.manager_id = t.emp_id
> )
> SELECT * FROM tree ORDER BY lvl, emp_id;
> ```

---

## 九、速查表

| 需求 | 写法 |
| --- | --- |
| 同一张表连两次 | `FROM t a JOIN t b ON ...`（**必须两个别名**） |
| 员工找经理（留根） | `emp_mgr e LEFT JOIN emp_mgr m ON e.manager_id = m.emp_id` |
| 同表两行并排比较 | `a JOIN b ON a.组 = b.组 AND a.值 > b.值` |
| 成对组合去重 | 加 `AND a.id < b.id` |
| 任意深度层级 | 改用递归 CTE（`WITH RECURSIVE`） |
| 只要一个值做条件 | 优先考虑相关子查询 |

> [!question] 自测三连
> 1. 自连接为什么"一定要起别名"？
> 2. 查"员工-经理"时用内连接会丢谁？为什么？
> 3. 成对匹配为什么要加 `a.emp_id < b.emp_id`？

---

> [!quote] 一句话记忆
> **自连接 = 同一张表写两次、各起别名变成两张逻辑表；查层级要留意用 `LEFT JOIN` 留住根节点；成对匹配记得加 `a.id < b.id` 去重防自配；要一层行并排看用自连接，只要一个值当条件用子查询。**

---

## 相关笔记

- [[INNER JOIN]] —— 自连接通常就是"内连接自己"
- [[LEFT JOIN]] —— 层级结构里留住根节点必须用它
- [[RIGHT JOIN]] —— 保右表全员
- [[FULL OUTER JOIN]] —— 两表并集
- [[CROSS JOIN]] —— 笛卡尔积，另一种"造组合"
- [[相关子查询]] —— 自连接的替代方案
- [[嵌套查询]] —— 子查询入门
- [[Join]] —— 六种连接的横向总览
