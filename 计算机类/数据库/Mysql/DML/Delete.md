# DELETE —— 删除数据

> [!abstract] 一句话
> `DELETE` 删除**表中的行**，表结构、索引、约束**原样保留**。
> 它能按条件挑着删、能配 `LIMIT` 分批删——这是 [[Truncate Table]] 永远做不到的。

> [!danger] 忘写 `WHERE` = 全表数据清空
> `DELETE FROM student;` 与 `DELETE FROM student WHERE id = 1;` 只差几个字，效果却是"删一行"和"删光全表"。`DELETE` 在事务里能回滚，但前提是**开了事务且还没提交**。
> ==如果本来就打算清空全表，请用 [[Truncate Table]] 而不是 `DELETE`。==

---

## 一、语法结构

| 子句 | 是否必须 | 作用 |
| --- | --- | --- |
| `DELETE FROM 表名` | ✅ | 删哪张表 |
| `WHERE 条件` | ❌ | 删**哪些行**，见 [[Where]]；==不写就是全表== |
| `ORDER BY` | ❌ | 配合 `LIMIT` 决定先删哪些行 |
| `LIMIT n` | ❌ | 最多删 n 行（MySQL 特有，仅单表删除支持） |

> [!info] 三篇笔记共用同一张示例表
> 与 [[Insert]]、[[Update]] 共用 `student` 表，建表细节见 [[Create Table]]。

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

## 二、按条件删除

```sql
DELETE FROM student WHERE name = '王五';
-- Query OK, 1 row affected (0.00 sec)
-- 结果：只剩张三、李四两行；id=3 不会被补上，其余行原封不动

DELETE FROM student;      -- 删除全部行
-- Query OK, 2 rows affected
```

| id | name | 操作前 | 结果 |
| --- | --- | --- | --- |
| 1 | 张三 | 在表里 | 保留 |
| 2 | 李四 | 在表里 | 保留 |
| 3 | 王五 | 在表里 | ==已删除== |

> [!note] `DELETE FROM t;` 与 `TRUNCATE TABLE t;` 长得像，本质完全不同
> 前者是**逐行删除**的 DML：能回滚、不重置自增、不释放磁盘空间；后者是**删表重建**的 DDL：秒级完成、不可回滚、重置自增、直接归还空间。

---

## 三、`ORDER BY` + `LIMIT`：大表分批删

```sql
DELETE FROM big_log WHERE created_at < '2026-01-01' ORDER BY id LIMIT 5000;
-- Query OK, 5000 rows affected (0.32 sec)
```

> [!warning] 大表为什么必须分批删
> 一次删几百万行会同时引发四个问题：**长事务**（几百秒提交不了）、**锁**（行锁 / 间隙锁长时间持有，其他写入全被挡住）、**undo 日志膨胀**（撑爆磁盘后删除中途失败，留下"删了一半"的表，极难修）、**主从延迟**（巨大的 binlog 事件，从库要重放很久）。
> ==拆成 N 个小事务，上述问题全部消失==：`while (true) { rows = 执行上面那条 DELETE; if (rows == 0) break; sleep(0.1); }`

> [!tip] `ORDER BY id` 不能省
> 不带 `ORDER BY` 的 `LIMIT` 是"**随便挑 5000 行**"：某些行**永远轮不到**，另一些反复被扫描。加上 `ORDER BY id`（走主键）后，每批都是"当前最小的 5000 个 id"。另一个技巧是**按主键区间切**：`DELETE FROM t WHERE id BETWEEN 1 AND 5000;` 再 `BETWEEN 5001 AND 10000`，比 `LIMIT` 更可控。

---

## 四、`DELETE` / `TRUNCATE` / `DROP` 三方对比

| 维度 | `DELETE FROM t` | `TRUNCATE TABLE t` | `DROP TABLE t` |
| --- | --- | --- | --- |
| 语句类型 | DML | **DDL** | **DDL** |
| 能否带 `WHERE` | ✅ 可以挑着删 | ❌ 只能全清 | ❌ 整张表 |
| 删除对象 | **行** | 全部行 | **表（结构 + 数据）** |
| 表结构 | 保留 | 保留 | ==一起删掉== |
| 自增是否重置 | ❌ 保留原值 | ✅ 重置为 1 | 随表消失 |
| 能否回滚 | ✅ 事务内可回滚 | ❌ 隐式提交 | ❌ 隐式提交 |
| 速度 | 慢，随行数增长 | 快，与行数无关 | 快 |
| 是否释放空间 | ❌ 只留可复用空洞 | ✅ 释放 | ✅ 释放 |
| 所需权限 | `DELETE` | **`DROP`** | **`DROP`** |
| 是否触发触发器 | ✅ 触发 `AFTER DELETE` | ❌ 不触发 | ❌ 不触发 |

> [!important] 一句话选型
> 只删**部分**行 → `DELETE ... WHERE`；要**清空全表**且不需回滚 → [[Truncate Table]]；要**连表结构一起干掉** → [[Drop Table]]。
> `TRUNCATE` 的自增重置、外键限制（报 1701）、DDL 隐式提交等细节都在 [[Truncate Table]] 里讲透了，这里不重复。

---

## 五、`DELETE` 不重置 `AUTO_INCREMENT`

```sql
DELETE FROM student;                                    -- 清空，id 曾经到过 3
INSERT INTO student (name, age) VALUES ('赵六', 20);
SELECT id, name FROM student;
```

```
+----+--------+
| id | name   |
+----+--------+
|  4 | 赵六   |     ← 从 4 继续，不是从 1 重新开始
+----+--------+
```

> [!warning] 自增计数器是**表级属性**，不跟着行走
> InnoDB 把自增值记在内存里（8.0 起持久化到 redo log），`DELETE` 只删行、不碰计数器。好处是老 id 不会被复用（历史日志里的 `id=1` 永远指同一条数据），坏处是反复增删后 id 出现大段"空洞"，`INT` 甚至会被耗尽。
> 想让它回到 1，只能显式重置：`ALTER TABLE student AUTO_INCREMENT = 1;` —— 该值会被自动抬到"当前最大 id + 1"，所以**先删光所有行再重置**才有意义。见 [[Alter Table]]、[[自增长约束]]。

---

## 六、`DELETE` 可以回滚：相对 `TRUNCATE` 的最大优势

```sql
SELECT COUNT(*) FROM student;      -- 3

START TRANSACTION;
DELETE FROM student WHERE class = '高一1班';
-- Query OK, 2 rows affected
SELECT COUNT(*) FROM student;      -- 1  ← 只剩王五，删多了！
ROLLBACK;
SELECT COUNT(*) FROM student;      -- 3  ← 数据全部回来了
```

| 阶段 | `COUNT(*)` | 说明 |
| --- | --- | --- |
| 删除前 | 3 | 张三、李四、王五 |
| `DELETE` 之后 | 1 | 高一1班的两人被删 |
| `ROLLBACK` 之后 | **3** | ==完整恢复== |

> [!success] 这是 `DELETE` 最值钱的一条特性
> InnoDB 里 `DELETE` 会把被删的行写进 **undo 日志**，所以 `ROLLBACK` 一回放数据就回来了。`TRUNCATE` 是 DDL，会**隐式提交**当前事务，`ROLLBACK` 只是空操作。

> [!danger] 但这不代表"随便删"就行
> 回滚有三个前提：表是 **InnoDB**（MyISAM 没有事务，回滚无效）、**开在同一个事务里且还没提交**、中间**没夹 DDL**（夹了 `TRUNCATE` / `ALTER` / `DROP` 会隐式提交，把前面全坐实）。
> 一旦 `COMMIT` 或连接断开被自动提交，就只剩 binlog 时间点恢复，而且**恢复的是整库，不是一行**。

---

## 七、外键与级联删除

被从表引用时，删除主表会被直接拒绝：

```sql
DELETE FROM `user` WHERE id = 1;
-- ERROR 1451 (23000): Cannot delete or update a parent row: a foreign key
-- constraint fails (`db`.`order`, CONSTRAINT `fk_order_user`
-- FOREIGN KEY (`user_id`) REFERENCES `user` (`id`))
-- 原因：order 表里还有 user_id = 1 的订单，删掉会让它们失去归属
```

从表定义了 `ON DELETE CASCADE` 时，情况完全不同：

```sql
-- order 外键写成 ON DELETE CASCADE，灌入 4 条订单（张三 3 条、李四 1 条）
SELECT COUNT(*) FROM `order`;                     -- 4
DELETE FROM `user` WHERE id = 1;
-- Query OK, 1 row affected                       ← 只写了 1 行
SELECT COUNT(*) FROM `order`;                     -- 1  ← 实际少了 3 行！
SELECT COUNT(*) FROM `order` WHERE user_id = 1;   -- 0
```

> [!danger] 删 1 行，连带删掉 3 行——这是"链式误删"的源头
> 返回信息里只写了 `1 row affected`，从表却**静默少了 3 行**。若从表下面还有二级从表也是 `CASCADE`，会一层层传下去，"删一条用户"可能带走几十万行订单和明细。
> ==排查==：`SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME FROM information_schema.KEY_COLUMN_USAGE WHERE REFERENCED_TABLE_NAME = 'user';`

| `ON DELETE` 选项 | 删主表行时从表怎么办                      | 典型场景              |
| -------------- | ------------------------------- | ----------------- |
| `RESTRICT`（默认） | ==拒绝删除==，报 `ERROR 1451`         | 从表数据很重要，不允许失去归属   |
| `NO ACTION`    | 同 `RESTRICT`（MySQL 里没有区别）       | 同上                |
| `CASCADE`      | 从表里引用它的行**一起删掉**                | 订单明细、附件、日志等"附属"数据 |
| `SET NULL`     | 从表外键列**置为 `NULL`**（该列必须允许 NULL） | 关系可以断，但数据本身要留     |

> [!tip] 线上业务常干脆不用物理外键
> 一是锁与性能开销，二是分库分表后根本没法建，三是"删一个用户要级联算清下游"交给应用层显式做更可控、更好审计。学习阶段则值得动手建一遍。见 [[外键约束]]。

---

## 八、多表删除（MySQL 特有语法）

需求：把黑名单里的用户从 `user` 表清掉（表：`user(id, name, phone)`、`blacklist(phone, reason)`）。

```sql
-- 只删 user 里匹配的行，blacklist 不动
DELETE u FROM `user` u JOIN blacklist b ON u.phone = b.phone;
-- Query OK, 3 rows affected (0.01 sec)

-- 两张表里匹配的行一起删
DELETE u, b FROM `user` u JOIN blacklist b ON u.phone = b.phone;
-- Query OK, 6 rows affected                 ← 3 + 3

-- 三种等价写法（推荐第一种）
-- DELETE u   FROM `user` u JOIN blacklist b ON u.phone = b.phone;
-- DELETE u.* FROM `user` u JOIN blacklist b ON u.phone = b.phone;
-- DELETE FROM u USING `user` u JOIN blacklist b ON u.phone = b.phone;
```

> [!warning] 多表删除的语法陷阱
> 多表删除里 **`FROM` 只出现一次**：单表是 `DELETE FROM t WHERE ...`，多表是 `DELETE t FROM t JOIN t2 ...`——`DELETE` 后面**直接跟要删的表**，再跟一个 `FROM`。
> 所以 `DELETE FROM t1.* FROM t1 JOIN t2 ...`（两个 `FROM`）是**语法错误**。另外多表删除**不支持 `ORDER BY` 和 `LIMIT`**，想分批删只能退回单表语句。

---

## 九、`DELETE` 会触发 `AFTER DELETE` 触发器

```sql
CREATE TRIGGER trg_user_after_delete
AFTER DELETE ON `user`
FOR EACH ROW
INSERT INTO user_log (user_id, action) VALUES (OLD.id, 'DELETE');

DELETE FROM `user` WHERE id = 2;
-- Query OK, 1 row affected
SELECT * FROM user_log;
-- 结果：1 行  →  (1, 2, 'DELETE', '2026-09-29 10:30:00')
```

> [!note] 触发器里用 `OLD` 取被删掉的那一行
> `DELETE` 触发器**只有 `OLD`**，没有 `NEW`——行都要没了，哪来的新值。反过来 `INSERT` 触发器只有 `NEW`，`UPDATE` 触发器两个都有。

> [!failure] 但 `TRUNCATE` 不会触发它
> `TRUNCATE TABLE `user`;` 是 DDL，不走行级操作，触发器**一次都不会执行**，`user_log` 里干干净净。依赖触发器做审计 / 同步的系统，一旦有人清表，**下游会静默失联**。

---

## 十、磁盘空间不释放

```sql
-- big_log 表数据 1GB
DELETE FROM big_log WHERE created_at < '2026-01-01';
-- Query OK, 4528136 rows affected (3 min 12.44 sec)

SHOW TABLE STATUS LIKE 'big_log'\G
-- Data_length 依然接近 1GB —— 文件一点没小
```

> [!info] 为什么删了数据文件不变小
> InnoDB 按**页**（默认 16KB）管理数据，`DELETE` 只在页内把记录标注为"已删除、空间可用"，页本身不还给操作系统，于是留下大量**可复用的空洞**。
> 好处是后续 `INSERT` 优先填补空洞，表不会无限膨胀；坏处是这张表若以后不再写入，空间就永远占着。==`df` 没变化是正常的，不是删除失败。==

```sql
ALTER TABLE big_log ENGINE = InnoDB;   -- 重建表，压实空洞（推荐）
OPTIMIZE TABLE big_log;                -- 本质也是重建
```

> [!warning] 重建期间会占**额外**一份磁盘
> 做法是**新建表 → 逐行拷贝 → 换名 → 删旧表**，1GB 的表重建时**峰值要占 2GB**，磁盘不够会中途失败。大表还要评估锁时间和主从延迟，最好放在低峰期，或用 `pt-online-schema-change`、`gh-ost`。见 [[Alter Table]]。

---

## 十一、安全删除流程

> [!tip] 第 1 步：先数行数，再拆 `WHERE` 核对数据
> 先 `SELECT COUNT(*)` 知道会删多少行，再 `SELECT *` 看删的是不是这批。然后把 `SELECT *` 原样换成 `DELETE`，**`WHERE` 一个字都别改**。

```sql
SELECT COUNT(*) FROM student WHERE class = '高一1班';      -- 先知道会删多少行
SELECT * FROM student WHERE class = '高一1班' LIMIT 20;    -- 再看删的是不是这批

DELETE FROM student WHERE class = '高一1班';
-- Query OK, 2 rows affected      ← 必须和上面 COUNT(*) 一致，不一致立刻停手
```

> [!success] 第 2 步：开事务删，验完再提交
> **把 `ROLLBACK` 当成默认选项，`COMMIT` 才是需要主动做的决定。**

```sql
START TRANSACTION;
DELETE FROM student WHERE class = '高一1班';
SELECT COUNT(*) FROM student;                  -- 看总数对不对
SELECT * FROM student WHERE class = '高一1班';  -- 应该是 0 行
-- 都对：COMMIT;   不对：ROLLBACK;
ROLLBACK;
```

> [!danger] 第 3 步：删之前先备份，并确认连的是哪个库
> `CREATE TABLE student_bak LIKE student;` 再 `INSERT INTO student_bak SELECT * FROM student;`。大表用 `mysqldump`，或确认 binlog 开着以便时间点恢复。
> 执行前 `SELECT DATABASE();` 确认库，并确认表是 InnoDB、没有视图 / 触发器 / 同步任务依赖它。

> [!warning] 第 4 步：开安全模式
> `SET sql_safe_updates = 1;` 打开后，`DELETE` 只要**不带 `WHERE`** 或 **`WHERE` 里的列没走索引**，就直接报错拒绝：
> `ERROR 1175 (HY000): You are using safe update mode and you tried to delete from a table without a WHERE that uses a KEY column`
> ==它拦下的基本就是"手滑型事故"。==

> [!example] 第 5 步：互联网公司的主流做法——软删除
> 生产环境几乎**不做物理删除**，而是加一个标记位，把 `DELETE` 换成 `UPDATE`（见 [[Update]]）。

```sql
ALTER TABLE `user`
    ADD COLUMN is_deleted TINYINT  NOT NULL DEFAULT 0 COMMENT '0正常 1已删',
    ADD COLUMN deleted_at DATETIME DEFAULT NULL       COMMENT '删除时间',
    ADD INDEX  idx_deleted (is_deleted);

-- 删除 = 打标记，不是真删
UPDATE `user` SET is_deleted = 1, deleted_at = NOW() WHERE id = 2;
-- Query OK, 1 row affected

-- 之后所有查询都要带上这个条件
SELECT * FROM `user` WHERE is_deleted = 0;
```

> [!question] 软删除这么好，为什么不是银弹？
> **好处**：随时"撤销删除"、能追溯谁什么时候删的、外键不会断。
> **代价**：每条查询都得记得带条件（**漏一条就把已删数据查出来了**）；表越涨越大；**唯一索引会和软删除冲突**——同一手机号"删了再注册"会撞 `uk_phone`，惯用解法是改成 `(phone, is_deleted)` 复合唯一。

---

## 十二、常见报错合集

> [!failure] 六种最常见的 DELETE 报错
> - `ERROR 1451 (23000)` Cannot delete or update a parent row —— **被从表引用**
> - `ERROR 1146 (42S02)` Table doesn't exist —— **表名写错**（或连错库）
> - `ERROR 1054 (42S22)` Unknown column in 'where clause' —— **字段名写错**
> - `ERROR 1175 (HY000)` safe update mode —— **安全模式拦截**
> - `ERROR 1205 (HY000)` Lock wait timeout exceeded —— **锁等待超时**，删大表时极常见
> - `ERROR 1701 (42000)` Cannot truncate a table referenced in a FK —— 见 [[Truncate Table]]

| 报错码 | 触发原因 | 对策 |
| --- | --- | --- |
| 1451 | 从表还在引用这些行 | 先删从表，或调整 `ON DELETE` 行为 |
| 1146 | 表不存在 | 检查库名 / 表名拼写 |
| 1054 | 列名不存在 | `DESC 表名` 核对 |
| 1175 | 安全模式 + `WHERE` 不走索引 | 给条件列加索引，或临时关闭 |
| 1205 | 锁等待超时 | 缩小批次、避开高峰、查 `SHOW ENGINE INNODB STATUS` |
| 1701 | `TRUNCATE` 被外键引用 | 改用 `DELETE`，或先摘掉外键 |

> [!important] 1205 锁等待超时：删大表的头号拦路虎
> 分批删时若**每批范围太大**或 `WHERE` **没走索引**，就会长时间持有间隙锁，把别的写入全堵住，最后报 1205。处理顺序：
> 1. 确认条件列**有索引**（先 `EXPLAIN SELECT ...` 看执行计划）
> 2. **缩小 `LIMIT`**（5000 → 500），批间加 `sleep`
> 3. 查谁在持锁：`SELECT * FROM performance_schema.data_locks;`（8.0）
> 4. 高并发表改用"**建新表 → 灌入要留的数据 → `RENAME` 原子切换**"，见 [[Alter Table]]

---

> [!quote] 一句话记忆
> **`DELETE` 删行不删表，`WHERE` 不写全清空**；能回滚是它最大的本事（所以**先开事务、默认 `ROLLBACK`**），不重置自增、不还磁盘空间是它的两个"后遗症"。
> 清空整表请找 [[Truncate Table]]，连表一起干掉请找 [[Drop Table]]。

---

## 相关笔记

- [[Truncate Table]] —— 清空全表的正确工具（快、重置自增、不可回滚）
- [[Drop Table]] —— 连表结构一起删
- [[Insert]] —— 管"增"，`DELETE` 管"删"
- [[Update]] —— 管"改"；**软删除**就是用它实现的
- [[Where]] —— 决定删哪些行，写错就是全表事故
- [[Select]] —— 删之前先查、删之后再查
- [[外键约束]] —— `ON DELETE` 的四种行为与 1451 报错
- [[Alter Table]] —— 重置自增、重建表回收空间
