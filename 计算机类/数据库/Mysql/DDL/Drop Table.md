# DROP TABLE —— 删除表

> [!danger] 一句话
> `DROP TABLE` 把**整张表连结构带数据一起抹掉**——表和它的一切都不存在了。
> **不可回滚、没有回收站、没有确认弹窗**。这是 SQL 里最危险的语句之一。

---

## 一、基本语法

```sql
DROP [TEMPORARY] TABLE [IF EXISTS] 表名1 [, 表名2, ...] [RESTRICT | CASCADE];
```

| 部分          | 说明                                  |
| ----------- | ----------------------------------- |
| `TEMPORARY` | 只删临时表，防止误删同名普通表                     |
| `IF EXISTS` | 表不存在时**不报错**，只给个 warning            |
| `表名1, 表名2`  | 一次删多张                               |
| `RESTRICT`  | 有外键依赖就拒绝删除（**默认行为**）                |
| `CASCADE`   | 连依赖对象一起删（MySQL 中此选项**被解析但无效**，见 §四） |

```sql
-- 最常用写法：加 IF EXISTS，脚本可重复执行
DROP TABLE IF EXISTS mytable;

-- 不带 IF EXISTS：表不存在就报 1051
DROP TABLE mytable;

-- 一次删多张
DROP TABLE IF EXISTS order_item, `order`, user;

-- 只删临时表
DROP TEMPORARY TABLE IF EXISTS tmp_report;
```

> [!tip] `DROP TABLE a, b;` 的顺序无所谓
> MySQL 会**先把所有表名收集起来统一检查**，再一起删。所以有外键关系的两张表，写 `a, b` 还是 `b, a` 都一样能删掉（前提是**它们互相引用的关系也在被删之列**）。
> 但如果被删的表引用了**不在删除列表里**的表，就会整体失败。

---

## 二、DROP 到底删掉了什么

| 被删除的东西 | 是否随之消失 |
| --- | --- |
| 表里所有数据行 | ✅ |
| 表结构（字段定义） | ✅ |
| 主键、唯一、外键、检查约束 | ✅ |
| 该表上的所有索引 | ✅ |
| 该表上的**触发器** | ✅ |
| 表注释、表选项 | ✅ |
| **视图**引用了这张表 | ❌ 视图保留但**变成坏视图**，一查就报错 |
| **存储过程 / 函数**里引用了这张表 | ❌ 保留，运行时才报错 |
| **其他表**指向它的外键 | ❌ 会导致 DROP **失败**（见 §四） |
| 该表上的**用户权限** | ❌ 权限记录会残留 |

> [!warning] "坏视图"是个隐蔽的雷
> 删表后一定要顺手检查依赖：`SHOW CREATE VIEW v_user;` 或全局搜表名。

```sql
CREATE VIEW v_user AS SELECT id, username FROM user;
DROP TABLE user;      -- 成功
SELECT * FROM v_user; -- ERROR 1146: Table 'db.user' doesn't exist
```

---

## 三、与 DELETE / TRUNCATE 的区别（重点）

三种"删除"是数据库考试与面试的必考对比题：

| 对比维度 | `DELETE` | `TRUNCATE` | `DROP` |
| --- | --- | --- | --- |
| **语句类型** | DML（数据操作） | DDL（结构定义） | DDL（结构定义） |
| **典型语法** | `DELETE FROM t WHERE ...` | `TRUNCATE TABLE t` | `DROP TABLE t` |
| **能否带 WHERE** | ✅ 可删部分行 | ❌ 全删 | ❌ 全删 |
| **删除的对象** | 行数据 | 表内所有行数据 | **表结构 + 数据 + 索引** |
| **表结构** | 保留 | 保留 | **删除** |
| **`AUTO_INCREMENT`** | **不重置** | **重置为 1** | 随表消失 |
| **能否回滚** | ✅ 在事务里可回滚 | ❌ 隐式提交，不可回滚 | ❌ 隐式提交，不可回滚 |
| **触发触发器** | ✅ 触发 `DELETE` 触发器 | ❌ 不触发 | ❌ 不触发 |
| **执行速度** | 慢（逐行 + 记日志） | 快（按页清空 / 重建） | 快 |
| **释放磁盘空间** | ❌ 表空间不还（会有空洞） | ✅ 释放 | ✅ 释放 |
| **所需权限** | `DELETE` | `DROP` | `DROP` |
| **有外键引用时** | 可删（无被引用行时） | ❌ 失败 | ❌ 失败 |
| **返回结果** | 受影响行数 | `0 rows affected` | `0 rows affected` |

> [!tip] 三句话记住
> - **DELETE**：删**数据**，能挑着删，可后悔
> - **TRUNCATE**：清空**数据**，不能挑，不可后悔，表还在
> - **DROP**：删**表本身**，什么都不剩

```sql
-- 三者的语义差异一眼看穿
DELETE FROM user WHERE id = 1;   -- 删 1 行，id 自增计数继续往下走
TRUNCATE TABLE user;             -- 全空，下一行 id 又是 1
DROP TABLE user;                 -- 表都没了，再执行任何 SELECT 都报 1146
```

---

## 四、外键依赖：DROP 失败的头号原因

```sql
-- 有从表引用它时
DROP TABLE user;
```

会报错：

```
ERROR 3730 (HY000): Cannot drop table 'user' referenced by a
foreign key constraint 'order.fk_order_user'.
```

> [!failure] ERROR 3730（8.0） / 1217（5.7）
> **含义**：`order` 表的外键指着 `user`，删了 `user` 参照就断了，所以不允许。

**三种解法，按推荐顺序：**

```sql
-- ① 先删从表，再删主表（通常最干净）
DROP TABLE IF EXISTS `order`;
DROP TABLE IF EXISTS `user`;

-- ② 只解除外键，保留从表（还要删外键顺手建的索引）
ALTER TABLE `order` DROP FOREIGN KEY fk_order_user;
ALTER TABLE `order` DROP INDEX fk_order_user;
DROP TABLE user;

-- ③ 临时关闭外键检查（危险，慎用）
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE user;
SET FOREIGN_KEY_CHECKS = 1;   -- ⚠ 一定要改回来！
```

> [!danger] 关于 `DROP TABLE ... CASCADE`
> 标准 SQL 里 `CASCADE` 表示"连依赖对象一起删"。但 **MySQL 会解析这个关键字然后忽略它**，行为与 `RESTRICT` 相同——**不会**帮你级联删掉子表。
> 想级联删除必须自己写 `SET FOREIGN_KEY_CHECKS=0` 或先删子表。
> （`DROP DATABASE` / `DROP SCHEMA` 才真的会级联删掉库内所有表。）

---

## 五、能撤销吗？

> [!danger] 不能
> `DROP TABLE` 属于 DDL，执行前**隐式提交**当前事务，`ROLLBACK` 对它无效。

```sql
START TRANSACTION;
DROP TABLE user;
ROLLBACK;                 -- ❌ user 表不会回来
```

那还能救回来吗？理论上有三条路，**都不保证**：

| 恢复途径          | 前提条件                                          | 成功率                                  |
| ------------- | --------------------------------------------- | ------------------------------------ |
| **从备份还原**     | 有定期备份 / 从库                                    | ⭐⭐⭐⭐⭐ 最可靠                            |
| **解析 binlog** | `binlog_format=ROW` 且 binlog 未被清理             | ⭐⭐⭐ 需专门工具（如 `binlog2sql`）反向生成 INSERT |
| **文件层恢复**     | 有 `innodb_file_per_table=ON` 的 `.ibd` 文件且未被覆盖 | ⭐ 极难，通常求助专业数据恢复                      |

> [!tip] 最有效的"恢复"是事前预防
> 生产库还应设置 `sql_safe_updates=1`、禁止无 `WHERE` 的 DML、对 `DROP` 做权限管控。

```sql
-- 危险操作前先改名（而不是删），改名是元数据操作，秒完成
RENAME TABLE user TO user_deleted_20260929;
-- 观察一周，确认无人使用后再：
DROP TABLE user_deleted_20260929;
```

---

## 六、DROP 家族的其他成员

删除指令不止删表，同族语句语义一致——**删对象，不可回滚**：

```sql
DROP DATABASE IF EXISTS mydb;          -- ⚠ 删库！连库里所有表一起删
DROP SCHEMA   IF EXISTS mydb;          -- DATABASE 的同义词
DROP VIEW     IF EXISTS v_user;        -- 删视图
DROP INDEX    idx_email ON user;       -- 删索引（注意有 ON 表名）
DROP TRIGGER  IF EXISTS trg_user_log;  -- 删触发器
DROP PROCEDURE IF EXISTS p_calc;       -- 删存储过程
DROP FUNCTION  IF EXISTS f_calc;       -- 删函数
DROP EVENT     IF EXISTS e_cleanup;    -- 删事件
DROP USER      IF EXISTS 'test'@'%';   -- 删用户
```

> [!danger] DROP DATABASE 是最狠的一条
> 它**不需要 CASCADE**——库内所有表、视图、存储过程、触发器**无条件全部消失**。而且库里的表再多，它也不问你一句。

> [!note] DROP INDEX 语法与其他不同
> 因为索引不是独立命名空间的对象，必须指明它属于哪张表。

```sql
DROP INDEX idx_email ON user;      -- ✅ 需要 ON 表名
ALTER TABLE user DROP INDEX idx_email;  -- ✅ 等效写法
```

---

## 七、权限要求

> [!info] 删表要的是 `DROP` 权限，不是 `DELETE`
> 这是设计上的**安全护栏**：能改数据的应用账号，通常**不该**拥有删表能力。
> 很多团队的做法是——应用账号**完全没有** `DROP` 权限，删表只能由 DBA 在变更窗口执行。

```sql
-- 只看，不给删表权
GRANT SELECT, INSERT, UPDATE ON app_db.* TO 'app_user'@'%';
-- 危险权限单独授予，且尽量限定到具体库
GRANT DROP ON app_db.* TO 'dba_user'@'%';
```

---

## 八、执行前的死亡清单

> [!danger] 逐条确认，一条不满足就不要按回车
> - [ ] **确认连的是哪个库**：`SELECT DATABASE();` —— 90% 的删表事故是删错了环境
> - [ ] `SHOW CREATE TABLE 表名;` —— 确认这就是你想删的那张
> - [ ] `SELECT COUNT(*) FROM 表名;` —— 心里有数，知道要丢多少数据
> - [ ] **已备份**：`CREATE TABLE 表名_bak_20260929 LIKE 表名; INSERT INTO 表名_bak_20260929 SELECT * FROM 表名;`
> - [ ] 没有视图 / 存储过程 / 触发器引用它
> - [ ] 没有其他表的外键指向它
> - [ ] 团队里有人**知情并同意**（生产环境走变更流程）
> - [ ] 优先考虑改名而非删除

> [!success] 更安全的替代方案
> | 目的 | 别用 | 改用 |
> | --- | --- | --- |
> | 清空数据、保留表 | `DROP TABLE` | `TRUNCATE TABLE` |
> | 删部分数据 | `DROP TABLE` | `DELETE FROM t WHERE ...` |
> | 确认后要彻底删 | 直接 `DROP` | 先 `RENAME` 观察，再 `DROP` |

---

> [!quote] 一句话记忆
> **DROP = 把整张表从数据库里"注销"**。数据、结构、索引、触发器全没，不可回滚，且只要有外键指过来就删不掉。

---

## 相关笔记

- [[Create Table]] —— 建表（DROP 的反操作）
- [[Alter Table]] —— 改结构（另一条 DDL 路）
- [[Truncate Table]] —— 清空数据但**保留**表
- [[表的操作]] —— DELETE 的用法
- [[外键约束]] —— 外键依赖与级联动作
