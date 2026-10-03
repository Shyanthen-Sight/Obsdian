# UPDATE —— 修改数据

> [!abstract] 一句话
> `UPDATE` 修改**已存在行**的值。它既不新增行、也不删除行，只把匹配到的那些行里的某些列**换成新值**。

> [!danger] 忘写 `WHERE` = 全表每一行都被改
> `UPDATE user SET vip = 1;` 会让**整张表所有人**瞬间变成 VIP。`UPDATE` 是 DML，一旦 `COMMIT` 就没有撤销按钮，只能翻 binlog 做点对点恢复。
> ==写 `UPDATE` 之前，先把 `WHERE` 抄出来单独 `SELECT` 一遍，确认行数和内容是你要的那批。==

---

## 一、语法结构

```sql
UPDATE 表名
   SET 列1 = 值1,
       列2 = 值2
 [WHERE 条件]
 [ORDER BY ...]
 [LIMIT n];
```

| 子句 | 是否必须 | 作用 |
| --- | --- | --- |
| `UPDATE 表名` | ✅ | 改哪张表（可以 `JOIN` 多张） |
| `SET 列 = 值` | ✅ | 改**什么**；多个赋值用**逗号**分隔 |
| `WHERE 条件` | ❌ | 改**哪些行**；==不写就是全表==，见 [[Where]] |
| `ORDER BY` | ❌ | 配合 `LIMIT` 决定优先改哪些行 |
| `LIMIT n` | ❌ | 最多改 n 行（MySQL 特有） |

> [!info] 三篇笔记共用同一张示例表
> 与 [[Insert]]、[[Delete]] 保持同一张 `student` 表，方便串读，建表细节见 [[Create Table]]。

```sql
CREATE TABLE student (
    id     INT AUTO_INCREMENT PRIMARY KEY,
    name   VARCHAR(20)  NOT NULL,
    gender CHAR(1)      DEFAULT 'U',      -- M男 F女 U未知
    age    TINYINT      DEFAULT 0,
    score  DECIMAL(5,2),
    class  VARCHAR(20)
);

INSERT INTO student (name, gender, age, score, class) VALUES
    ('张三', 'M', 18, 92.50, '高一1班'),
    ('李四', 'F', 17, 88.00, '高一1班'),
    ('王五', 'M', 19, 76.50, '高一2班');
```

---

## 二、单字段与多字段更新

```sql
UPDATE student SET score = 95.00 WHERE name = '张三';
-- Query OK, 1 row affected (0.01 sec)
-- Rows matched: 1  Changed: 1  Warnings: 0
```

| id | name | 更新前 score | 更新后 score |
| --- | --- | --- | --- |
| 1 | 张三 | 92.50 | **95.00** |
| 2 | 李四 | 88.00 | 88.00（没匹配到，原样） |
| 3 | 王五 | 76.50 | 76.50（没匹配到，原样） |

返回里的两个数字不一样：`Rows matched` 是**匹配到几行**，`Changed` 是**真的改了几行**，见第九节。

```sql
-- 多字段：逗号分隔，一次改完
UPDATE student SET gender = 'F', age = 18, class = '高一3班' WHERE id = 2;
-- Query OK, 1 row affected
```

> [!failure] `SET` 里分隔用逗号，不是 `AND`
> `UPDATE student SET gender = 'F' AND age = 18 WHERE id = 2;` 是**错的**，而且**不报语法错误**。
> MySQL 会把 `'F' AND 18` 当成**一个布尔表达式**求值，只给 `gender` 赋了个 `0` 或 `1`；至于 `age = 18`，那只是表达式的一部分，**根本没执行**。
> ==这种错误比报错可怕得多：不报错、静默写进错数据、事后极难发现。==

---

## 三、`SET` 里用原值参与计算

```sql
UPDATE student SET score = score + 5 WHERE class = '高一1班';
-- Query OK, 2 rows affected
-- Rows matched: 2  Changed: 2  Warnings: 0
```

| id | name | class | 更新前 score | 更新后 score |
| --- | --- | --- | --- | --- |
| 1 | 张三 | 高一1班 | 95.00 | **100.00** |
| 2 | 李四 | 高一3班 | 88.00 | 88.00（班级不匹配） |
| 3 | 王五 | 高一2班 | 76.50 | 76.50（班级不匹配） |

```sql
UPDATE employee SET salary = salary * 1.1 WHERE dept_id = 1;              -- 涨薪 10%
UPDATE goods    SET stock  = stock - 1     WHERE id = 100 AND stock > 0;  -- 扣库存
```

> [!tip] 用原值计算是 `UPDATE` 最值钱的用法
> 普调工资、扣库存、积分累加、浏览量 +1，全靠它，因为**不需要先把值读到应用层再写回去**。
> ==但要注意并发风险==：先 `SELECT stock` 再算好 `stock-1` 写回去，两个人同时下单就会**丢失更新**。
> 正确姿势是把判断也放进 SQL（`WHERE id = 100 AND stock > 0`），让数据库在一条语句里原子完成"检查 + 修改"，再看影响行数是否为 0 判断有没有抢到。

---

## 四、`SET` 里用 `NULL` 和 `DEFAULT`

```sql
UPDATE student SET score = NULL WHERE id = 3;                     -- 显式置空
UPDATE student SET gender = DEFAULT, age = DEFAULT WHERE id = 3;  -- 恢复默认值
-- 结果：该行变成 gender='U'（默认值）、age=0（默认值）、score=NULL（显式置空）
```

> [!warning] `NOT NULL` 的列不能 `SET NULL`
> 会报 `ERROR 1048 (23000): Column 'name' cannot be null`，整条 `UPDATE` 回滚，一行都不会改。见 [[非空约束]]。
> 想把非空列"清空"，要么给它一个业务意义上的空值（`''`、`0`、`'1970-01-01 00:00:00'`），要么先去掉 `NOT NULL`（改结构用 [[Alter Table]]）。
> 另外 `DEFAULT` 关键字在 `UPDATE` 里是 **8.0.13 才支持**的。

---

## 五、顺序陷阱：`SET` 里引用同一行的列

引用**同一行的其他列**（不是同句刚被改过的列）完全没问题，这是"派生列"的常用写法：

```sql
UPDATE order_item SET total = price * qty WHERE total IS NULL;
-- Query OK, 5 rows affected
```

但如果引用的那一列在**同一句 `SET` 里也被改了**，事情就反直觉了。

> [!important] MySQL 的赋值**从左到右**依次生效，引用到的是**新值**
> 这与编程语言的直觉一致，**但和标准 SQL 相反**：标准 SQL（PostgreSQL / Oracle / SQL Server）里所有表达式都基于**旧值**求值，`SET a = 1, b = a` 中 `b` 拿到**旧 a**；而 MySQL 单表 UPDATE 里 `b` 拿到的是**刚改成 1 的新 a**。
> 另外 **MySQL 多表 UPDATE** 官方明说"赋值顺序不做任何保证"，==多表更新时千万别写互相依赖的赋值==。结论：**MySQL 里 `SET` 的书写顺序真的会改变结果**，不要依赖它。

跑一遍就清楚了：

```sql
-- 初始 score = 90.00；先把 score 改成 0，再让 age 取 score
UPDATE student SET score = 0, age = score WHERE id = 1;
-- 结果：score=0，age=0        ← age 拿到"新 score"

-- 还原后只把两个赋值的顺序对调
UPDATE student SET score = 90.00, age = 18 WHERE id = 1;
UPDATE student SET age = score, score = 0 WHERE id = 1;
-- 结果：score=0，age=90       ← age 拿到"旧 score"
```

> [!example] 同样的表达式，只换了书写顺序
> 两条语句只差 `SET` 里两个赋值的先后，结果 `age` 一个是 0、一个是 90。
> 而在 PostgreSQL / Oracle 里，这两条的结果**都是 `age = 90`**。
> 所以写 `UPDATE` 时==多个赋值之间不要产生依赖==，是最省心的做法。

---

## 六、`UPDATE` + `JOIN`：联表更新（重点）

场景：`emp` 表里的冗余字段 `dept_name` 一直是空的，要从 `dept` 表补上。

```sql
CREATE TABLE dept (dept_id INT PRIMARY KEY, dept_name VARCHAR(20));
CREATE TABLE emp (
    emp_id   INT AUTO_INCREMENT PRIMARY KEY,
    emp_name VARCHAR(20),
    dept_id  INT,
    dept_name VARCHAR(20)          -- 冗余字段，待补
);

INSERT INTO dept VALUES (1, '研发部'), (2, '市场部'), (3, '人事部');
INSERT INTO emp (emp_name, dept_id) VALUES ('张三', 1), ('李四', 1), ('王五', 2), ('赵六', 3);

UPDATE emp e JOIN dept d ON e.dept_id = d.dept_id
   SET e.dept_name = d.dept_name
 WHERE d.dept_name = '研发部';
-- Query OK, 2 rows affected
-- Rows matched: 2  Changed: 2  Warnings: 0
```

| emp_id | emp_name | dept_id | 更新前 dept_name | 更新后 dept_name |
| --- | --- | --- | --- | --- |
| 1 | 张三 | 1 | NULL | **研发部** |
| 2 | 李四 | 1 | NULL | **研发部** |
| 3 | 王五 | 2 | NULL | NULL（被 `WHERE` 过滤掉） |
| 4 | 赵六 | 3 | NULL | NULL（被 `WHERE` 过滤掉） |

只改了 2 行——因为 `WHERE` 把范围限死在研发部。逗号写法完全等价，只是把连接条件塞进了 `WHERE`：

```sql
UPDATE emp e, dept d
   SET e.dept_name = d.dept_name
 WHERE e.dept_id = d.dept_id AND d.dept_name = '研发部';
```

> [!tip] 多表 `UPDATE` 里，`WHERE` 只负责"过滤"，"改什么"永远由 `SET` 决定
> `WHERE d.dept_name = '研发部'` 只是**筛出要改哪几行**，它不会自动把值写过去——真正赋值的是 `SET e.dept_name = d.dept_name`。
> 反过来，只写 `SET` 不写 `WHERE`，就是**两边全表笛卡尔匹配后全部更新**，灾难级别。
> 最稳的习惯：**先写成同样 `JOIN` 的 `SELECT`，看看到底会匹配出多少行，再改成 `UPDATE`**。

---

## 七、`UPDATE` + 子查询

标量子查询可以从**别的表**取值，这没问题：

```sql
UPDATE emp e
   SET e.dept_name = (SELECT d.dept_name FROM dept d WHERE d.dept_id = e.dept_id);
-- Query OK, 4 rows affected
```

但引用**目标表自己**就会被拦下：

```sql
UPDATE student SET score = score + 5 WHERE score < (SELECT AVG(score) FROM student);
-- ERROR 1093 (HY000): You can't specify target table 'student' for update in FROM clause
```

> [!danger] `ERROR 1093` 的成因与两种绕法
> MySQL **不允许**在 `UPDATE` / `DELETE` 的子查询里引用**正在被修改的那张表**：执行器要先扫出子查询结果、再逐行更新，而扫的过程中表随时在变，结果无法确定。
>
> **绕法 ① 套一层派生表**，强迫 MySQL 先把平均值物化成一个临时结果：
> `UPDATE student SET score = score + 5 WHERE score < (SELECT avg_score FROM (SELECT AVG(score) AS avg_score FROM student) AS tmp);`
>
> **绕法 ② 改成 `JOIN`**，语义更清楚：
> `UPDATE student s JOIN (SELECT AVG(score) AS avg_score FROM student) tmp ON s.score < tmp.avg_score SET s.score = s.score + 5;`
>
> 两种写法都是 `Query OK, 2 rows affected`。**派生表那层 `AS tmp` 不能省**，MySQL 要求每个派生表必须有别名。

---

## 八、`LIMIT` 限制更新行数

```sql
UPDATE student SET score = score + 1 WHERE score < 60 ORDER BY id LIMIT 100;
-- Query OK, 100 rows affected
```

> [!note] `LIMIT` 的两个使用场景
> 1. **大表分批更新**：一次改几万行会产生长事务、长时间持锁、undo 日志膨胀，还可能拖出主从延迟。改成"每批 1000 行、循环执行到影响行数为 0"就安全得多。
> 2. **修复脏数据**：先 `LIMIT 10` 试改一批，`SELECT` 看看对不对，没问题再放开。
>
> ==但要小心：不带 `ORDER BY` 的 `LIMIT` 是"随便挑 n 行"，每次挑的可能都不一样。==

---

## 九、影响行数与 `ROW_COUNT()`

```sql
UPDATE student SET score = 100 WHERE id = 1;
-- Query OK, 1 row affected
SELECT ROW_COUNT();          -- 1

UPDATE student SET score = 100 WHERE id = 1;   -- 值本来就等于 100
-- Query OK, 0 rows affected
-- Rows matched: 1  Changed: 0  Warnings: 0
SELECT ROW_COUNT();          -- 0
```

> [!important] `0 rows affected` 不等于失败
> MySQL **默认**只把"值真的发生变化"的行计入 `affected rows`。新值与旧值相同时：`Rows matched: 1` 说明**匹配到了**、`WHERE` 没问题，`Changed: 0` 只是**没有实际改动**。
> 所以**不能**用"影响行数是否为 1"判断"这条记录存不存在"。
> 想让驱动返回"匹配行数"而不是"改动行数"：连接时带 **`CLIENT_FOUND_ROWS`** 标志，或 JDBC 连接串加 **`useAffectedRows=false`**。

> [!question] 那乐观锁为什么还敢用影响行数？
> 因为乐观锁一定带着 `SET version = version + 1`，**版本号必然会变**，`affected rows` 就能真实反映"有没有抢到"。
> `UPDATE t SET ... WHERE id = ? AND version = ?` 返回 0，就说明这条记录已经被人抢先改过了。

---

## 十、安全操作流程

> [!tip] 第 1 步：先用**完全相同的 `WHERE`** 跑一遍 `SELECT`
> 先 `SELECT COUNT(*)` 知道会改多少行，再 `SELECT ... LIMIT 20` 看是不是这批数据。

```sql
SELECT COUNT(*) FROM student WHERE class = '高一1班';                  -- 先确认行数
SELECT id, name, score FROM student WHERE class = '高一1班' LIMIT 20;  -- 再核对内容

-- 确认无误后，把 SELECT ... 原样换成 UPDATE，WHERE 一个字都别改
UPDATE student SET score = score + 5 WHERE class = '高一1班';
-- Query OK, 2 rows affected
```

返回的 `Rows matched` 应该和刚才 `COUNT(*)` 一致——不一致就立刻停下来查原因。

> [!success] 第 2 步：包在事务里执行，验完再提交
> **把 `ROLLBACK` 当默认选项，`COMMIT` 才是需要主动做的决定。**
> 注意：表如果是 MyISAM，事务是假的、回滚无效——`UPDATE` 前先 `SHOW CREATE TABLE` 确认是 InnoDB。

```sql
START TRANSACTION;
UPDATE student SET score = score + 5 WHERE class = '高一1班';
SELECT id, name, score FROM student WHERE class = '高一1班';   -- 先看一眼
-- 对了就 COMMIT;  不对就 ROLLBACK;
ROLLBACK;
```

> [!warning] 第 3 步：开启安全更新模式
> `SET sql_safe_updates = 1;` 打开后，`UPDATE` / `DELETE` 只要满足下面任一条就直接**报错拒绝执行**：没有写 `WHERE`、`WHERE` 里的列**没走索引**、用了 `LIMIT` 却没写 `WHERE`。
> 报错：`ERROR 1175 (HY000): You are using safe update mode and you tried to update a table without a WHERE that uses a KEY column`
> 想临时绕过可以 `SET sql_safe_updates = 0;`——但==既然是"绕过"，就该反问自己为什么过不去==。

> [!danger] 第 4 步：生产库先备份，并且确认连的是哪个库
> 备份：`CREATE TABLE student_bak LIKE student;` 再 `INSERT INTO student_bak SELECT * FROM student;`。大表用 `mysqldump` 或 binlog 时间点恢复。
> 执行前务必 `SELECT DATABASE();` —— **跑错库是最经典的事故来源**。

---

## 十一、常见报错合集

> [!failure] 六种最常见的 UPDATE 报错
> - `ERROR 1054` Unknown column —— **列名打错**，或别名没起对
> - `ERROR 1062` Duplicate entry —— **改成别人已占用的唯一值**，见 [[唯一约束]]
> - `ERROR 1048` Column cannot be null —— **给非空列赋了 `NULL`**
> - `ERROR 1175` safe update mode —— **安全模式拦截**，`WHERE` 没走索引
> - `ERROR 1093` You can't specify target table —— **目标表陷阱**
> - `ERROR 1406` Data too long —— **值超出列长度**

| 报错码 | 触发原因 | 对策 |
| --- | --- | --- |
| 1054 | 列名 / 别名写错 | 用 `DESC 表名` 核对 |
| 1062 | 唯一约束被撞 | 先查有没有重复值 |
| 1048 | 非空列被赋 NULL | 给值，或去掉 `NOT NULL` |
| 1175 | 安全模式 + `WHERE` 不走索引 | 给条件列加索引，或临时关闭 |
| 1093 | 子查询引用了目标表 | 套派生表，或改 `JOIN` |
| 1406 | 值超过列定义长度 | 改结构加长，见 [[Alter Table]] |

> [!warning] 1406 之外还有个更阴的：静默截断
> **严格模式**（`STRICT_TRANS_TABLES`，MySQL 8.0 默认开启）下，超长会**报 1406 并回滚整条语句**，这是好事。但严格模式一旦被关掉（老项目、配置里显式写 `sql_mode=''`），MySQL 会**把值悄悄截断后照常写入**，只给一个 `Warning`。
> ==报错能看见，警告看不见——后者才是真危险。== 上线前确认 `SELECT @@sql_mode;` 里带着严格模式。

---

> [!quote] 一句话记忆
> **`SET` 改什么，`WHERE` 改哪些行**；改之前先 `SELECT`，改之时开事务，改之后看 `matched` 和 `changed`。
> 记住两条反直觉的：**`SET` 用逗号不用 `AND`**、**`0 rows affected` 不代表执行失败**。

---

## 相关笔记

- [[Insert]] —— 先有行才能改行
- [[Delete]] —— 删除行
- [[Where]] —— `UPDATE` 里最关键的子句，写错就是全表事故
- [[Select]] —— 改之前先查，改之后再查
- [[Join]] —— 联表更新的基础
- [[Alter Table]] —— 改的是**结构**，别和 `UPDATE` 混
- [[非空约束]] · [[唯一约束]] —— `UPDATE` 最容易撞上的两种约束
