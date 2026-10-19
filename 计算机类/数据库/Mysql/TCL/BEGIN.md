# BEGIN —— 开启事务

> [!abstract] 一句话
> `BEGIN` / `START TRANSACTION` 只是画一条**起跑线**：它本身不加锁、不建快照；
> 真正的锁和一致性视图在后续语句执行时才逐步建立，最后由 [[COMMIT]] / [[ROLLBACK]] 收尾。

> [!info] 本篇在 TCL 中的位置
> [[BEGIN]] 开启 → DML 执行 → [[COMMIT]] 提交 / [[ROLLBACK]] 回滚；
> 事务内部局部回滚用 [[SAVEPOINT]]；事务的四大保证见 [[ACID]]。

---

## 一、两种写法

```sql
-- 写法一：BEGIN
BEGIN;
BEGIN WORK;          -- 标准 SQL 的可选写法

-- 写法二：START TRANSACTION
START TRANSACTION;

-- 带修饰符
START TRANSACTION READ ONLY;
START TRANSACTION READ WRITE;
START TRANSACTION WITH CONSISTENT SNAPSHOT;
```

| 写法 | 是否支持修饰符 | 说明 |
| --- | --- | --- |
| `BEGIN` | ❌ | `START TRANSACTION` 的别名，最简洁 |
| `BEGIN WORK` | ❌ | 同上，`WORK` 可省略 |
| `START TRANSACTION` | ✅ | 推荐写法，语义清晰 |
| `START TRANSACTION READ ONLY` | — | 只读事务 |
| `START TRANSACTION READ WRITE` | — | 显式读写事务（默认） |
| `START TRANSACTION WITH CONSISTENT SNAPSHOT` | — | 立即建立一致性快照 |

> [!warning] 存储过程里的 `BEGIN` 不是开启事务
> 在存储过程/函数/触发器里，`BEGIN ... END` 是**语句块**，不是事务。
> 要在存储程序里开启事务，必须写 `START TRANSACTION;`，否则会报语法错误或语义不符。

```sql
-- ❌ 在存储过程里，BEGIN 会被当成语句块
CREATE PROCEDURE p()
BEGIN
    BEGIN;              -- 这不是开启事务
    UPDATE ...
END;

-- ✅
CREATE PROCEDURE p()
BEGIN
    START TRANSACTION;
    UPDATE ...
    COMMIT;
END;
```

> [!note] `START TRANSACTION` 会先提交当前事务
> 如果当前已经有一个未提交的事务，执行 `START TRANSACTION`（或 `BEGIN`）会**隐式提交**它，再开始新事务。
> 它不是"嵌套事务"。
> ```sql
> START TRANSACTION;
> INSERT INTO t VALUES (1);
> START TRANSACTION;   -- ⚠️ 前面的 INSERT 被隐式提交
> ROLLBACK;            -- 只能回滚第二条 START 之后的操作
> ```

---

## 二、事务的生命周期

```text
START TRANSACTION
        │
        ├── DML 1  ── 加锁 / 写 undo / 写 redo
        ├── DML 2
        ├── SELECT ... FOR UPDATE  ── 当前读 + 加锁
        ├── SAVEPOINT sp1
        ├── DML 3
        │
        ├── COMMIT    ── 提交，结束事务
        └── ROLLBACK  ── 回滚，结束事务
```

### 2.1 开启时发生了什么？

严格来说，`START TRANSACTION` 只做两件事：

1. **结束当前事务**（如果有，隐式提交）
2. **标记一个新事务开始**

它**不会**立刻：

- 给所有表加锁
- 创建一致性快照（除非 `WITH CONSISTENT SNAPSHOT`）
- 分配事务 ID（InnoDB 通常在第一次写操作时才分配）

> [!tip] 锁是"用到才加"，不是"一开始全加"
> `START TRANSACTION` 之后，只有具体语句访问到某行/某个范围时，才加对应的锁。
> 所以"事务一开启就锁全表"是误解。

### 2.2 快照是什么时候建立的？

| 隔离级别 | 快照建立时机 |
| --- | --- |
| `READ COMMITTED` | **每条一致性读语句**都创建新快照 |
| `REPEATABLE READ` | **事务内第一次一致性读**时创建，之后复用 |
| `SERIALIZABLE` | 普通 `SELECT` 也会加共享锁，行为更接近当前读 |

```sql
START TRANSACTION;

-- 第一条 SELECT 才建立 RR 的快照
SELECT * FROM student WHERE id = 1;

-- 后面的 SELECT 复用同一个快照
SELECT * FROM student WHERE id = 1;
```

如果希望**事务一开始就建立快照**，用：

```sql
START TRANSACTION WITH CONSISTENT SNAPSHOT;
```

> [!important] `WITH CONSISTENT SNAPSHOT` 的适用条件
> 它只对支持一致性读的引擎（InnoDB）有效，并且只在 `REPEATABLE READ` 或 `READ COMMITTED` 下有意义。
> 常用场景：**一致性逻辑备份 / 导出**——保证整个导出过程看到同一时间点的数据。

---

## 三、`autocommit`：隐式事务开关

```sql
SELECT @@autocommit;          -- 1 = 开启，0 = 关闭
SELECT @@session.autocommit;

SET autocommit = 0;           -- 关闭自动提交
SET autocommit = 1;           -- 开启自动提交（会提交当前未提交事务）
```

| `autocommit` | 行为 |
| --- | --- |
| `1`（默认） | 每条 SQL 自动成为一个事务，执行完立即提交 |
| `0` | 后续 DML 自动开启事务，需要手动 `COMMIT` / `ROLLBACK` |

### 3.1 `autocommit=1` 下显式事务仍然有效

```sql
SET autocommit = 1;
START TRANSACTION;            -- 显式事务覆盖 autocommit
UPDATE ...;
UPDATE ...;
COMMIT;                       -- 这两条一起提交
```

### 3.2 `autocommit=0` 下不要忘记提交

```sql
SET autocommit = 0;

UPDATE student SET score = 100 WHERE id = 1;
-- 此时事务已隐式开始，但没有提交

COMMIT;   -- 必须手动提交
-- 或 ROLLBACK;
```

> [!danger] `SET autocommit = 1` 会提交当前事务
> 从 `0` 改成 `1` 时，MySQL 会**自动提交**当前未提交的事务。
> 反过来，从 `1` 改成 `0` 不会开启事务，只是让后续语句进入隐式事务模式。

> [!warning] `SET GLOBAL autocommit` 只影响新连接
> 已经建立的连接仍使用自己的会话值。
> 生产环境不建议全局关掉 `autocommit`，容易导致"忘了提交、锁一直不释放"。

### 3.3 `autocommit` 与 DDL

即使 `autocommit=0`，DDL 仍然会**隐式提交**：

```sql
SET autocommit = 0;

INSERT INTO student (name) VALUES ('张三');
CREATE TABLE t_tmp (id INT);   -- ⚠️ 隐式提交，INSERT 也被提交
ROLLBACK;                      -- 撤不回 INSERT
```

> [!important] 事务里不要混 DDL
> `CREATE` / `ALTER` / `DROP` / `TRUNCATE` / `RENAME` 等都会隐式提交。
> 详见 §六。

---

## 四、只读事务与一致性快照

### 4.1 `READ ONLY`

```sql
START TRANSACTION READ ONLY;

SELECT * FROM student WHERE class_id = 1;
SELECT * FROM score WHERE student_id = 1;

COMMIT;
```

| 特点 | 说明 |
| --- | --- |
| 不能修改数据 | 写入会报 `ERROR 1792: Cannot execute statement in a READ ONLY transaction` |
| 适合报表/导出 | 防止误写，语义清晰 |
| 可减少部分开销 | InnoDB 对只读事务有优化 |
| 仍然是一致性读 | 是否可重复读取决于隔离级别 |

> [!note] 只读事务不是"只读账号"
> `READ ONLY` 是**事务级**限制；账号权限是另一层控制（见 DCL 的 `GRANT`）。
> 两者可以叠加：只读账号 + 只读事务，双重保险。

### 4.2 `WITH CONSISTENT SNAPSHOT`

```sql
START TRANSACTION WITH CONSISTENT SNAPSHOT;

-- 整个事务看到同一时间点的数据
SELECT * FROM orders;
SELECT * FROM order_items;

COMMIT;
```

> [!tip] 逻辑备份的经典用法
> `mysqldump --single-transaction` 本质上就是在 `REPEATABLE READ` 下开启一致性快照，
> 让备份期间的所有表看到同一时间点，避免"备份到一半数据变了"。

### 4.3 只读 + 快照

```sql
START TRANSACTION READ ONLY, WITH CONSISTENT SNAPSHOT;
```

> [!note] 语法支持因版本而异
> 如果版本不支持组合写法，可以分两步：
> ```sql
> SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
> START TRANSACTION WITH CONSISTENT SNAPSHOT;
> ```

---

## 五、设置事务隔离级别

```sql
-- 查看（8.0）
SELECT @@transaction_isolation;

-- 查看（5.7 及以前）
SELECT @@tx_isolation;

-- 当前会话
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- 全局（只影响之后新建的连接）
SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- 只对下一个事务生效
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

| 作用域 | 生效范围 |
| --- | --- |
| `SET TRANSACTION` | **下一个事务**，必须在事务开始前执行 |
| `SET SESSION TRANSACTION` | 当前连接后续所有事务 |
| `SET GLOBAL TRANSACTION` | 之后新建的连接 |

> [!warning] 事务进行中不能改
> ```sql
> START TRANSACTION;
> SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
> -- ERROR 1568: Transaction characteristics can't be changed
> --         while a transaction is in progress
> ```

> [!tip] MySQL 默认是 `REPEATABLE READ`
> 互联网高并发场景常改成 `READ COMMITTED`，以减少间隙锁和死锁。
> 改之前确认业务是否依赖"事务内多次读一致"。详见 [[ACID]] §4.4。

---

## 六、哪些语句会隐式提交

> [!danger] 隐式提交 = 你的事务被"偷偷"结束了
> 一旦执行下列语句，当前事务会被提交，之前未提交的 DML 也一起落盘，`ROLLBACK` 再也撤不回。

### 6.1 DDL

```sql
CREATE DATABASE / DROP DATABASE
CREATE TABLE / ALTER TABLE / DROP TABLE / TRUNCATE TABLE / RENAME TABLE
CREATE INDEX / DROP INDEX
CREATE VIEW / ALTER VIEW / DROP VIEW
CREATE TRIGGER / DROP TRIGGER
CREATE PROCEDURE / DROP PROCEDURE
CREATE FUNCTION / DROP FUNCTION
```

> [!note] 临时表是例外
> `CREATE TEMPORARY TABLE` 和 `DROP TEMPORARY TABLE` **不会**隐式提交。
> 但其他 DDL 仍然会。

### 6.2 DCL / 账号管理

```sql
GRANT / REVOKE
CREATE USER / DROP USER / ALTER USER / RENAME USER
SET PASSWORD
```

### 6.3 其他

```sql
LOCK TABLES
UNLOCK TABLES        -- 如果之前用 LOCK TABLES 锁过表
SET autocommit = 1   -- 从 0 改成 1 时
START TRANSACTION    -- 开启新事务前，提交旧事务
ANALYZE TABLE
OPTIMIZE TABLE
REPAIR TABLE
FLUSH ...
RESET ...
CACHE INDEX ...
LOAD INDEX INTO CACHE ...
```

> [!failure] 经典翻车现场
> ```sql
> START TRANSACTION;
> INSERT INTO student (name) VALUES ('张三');
> CREATE TABLE t_tmp (id INT);   -- 隐式提交
> ROLLBACK;                      -- '张三' 已经提交，撤不回
> ```
> 正确做法：DDL 放在事务外，或者先提交 DML 再做 DDL。

### 6.4 不会隐式提交的语句

| 语句 | 说明 |
| --- | --- |
| `SELECT` | 只读，不结束事务 |
| `INSERT` / `UPDATE` / `DELETE` | DML，事务内可回滚 |
| `LOAD DATA` | InnoDB 下可回滚（不是隐式提交） |
| `SAVEPOINT` / `ROLLBACK TO SAVEPOINT` | 事务内操作 |
| `CREATE TEMPORARY TABLE` / `DROP TEMPORARY TABLE` | 临时表例外 |
| `SET @var = ...` | 用户变量，不结束事务（但也不回滚） |

---

## 七、事务中能做什么、不能做什么

| 操作 | 事务中是否允许 | 说明 |
| --- | --- | --- |
| `INSERT` / `UPDATE` / `DELETE` | ✅ | 可提交/回滚 |
| `SELECT`（快照读） | ✅ | 不加锁，走 MVCC |
| `SELECT ... FOR UPDATE` | ✅ | 当前读 + 加锁 |
| `SELECT ... LOCK IN SHARE MODE` | ✅ | 当前读 + 共享锁 |
| `SAVEPOINT` / `ROLLBACK TO` | ✅ | 局部回滚 |
| `COMMIT` / `ROLLBACK` | ✅ | 结束事务 |
| `CREATE` / `ALTER` / `DROP` | ⚠️ | 隐式提交，破坏事务边界 |
| `TRUNCATE` | ⚠️ | DDL，隐式提交 |
| `GRANT` / `REVOKE` | ⚠️ | 隐式提交 |
| `LOCK TABLES` | ⚠️ | 隐式提交 |
| 修改隔离级别 | ❌ | 事务中报 1568 |

> [!tip] 事务中尽量只做"数据库内的短操作"
> 不要在事务里：
> - 等用户输入
> - 调用 HTTP / RPC
> - 发消息、发邮件
> - 做大量计算或文件 I/O
>
> 这些操作会把事务拉长，锁和 undo 一直不释放。

---

## 八、事务大小与最佳实践

> [!success] 五条实战原则
> 1. **短事务**：开启后尽快提交，事务内不做耗时操作
> 2. **明确边界**：`START TRANSACTION` 和 `COMMIT` 成对出现，异常分支必须有 `ROLLBACK`
> 3. **批量分批**：大批量写入每 500~1000 行提交一次，避免超大事务
> 4. **只读分离**：报表/导出用 `READ ONLY` + 一致性快照
> 5. **死锁重试**：捕获 `ERROR 1213`，退避后重试整个事务

```sql
-- 推荐的异常处理结构（应用层伪代码）
START TRANSACTION;
TRY {
    UPDATE ...
    INSERT ...
    COMMIT;
} CATCH {
    ROLLBACK;
    // 根据错误类型决定是否重试
}
```

> [!warning] 长事务的危害
> - 长时间持有行锁，阻塞其他事务
> - 阻止 undo log purge，history list 增长
> - 占用大量 undo 空间和 buffer pool
> - 回滚可能非常慢
> - 增加死锁概率
>
> 监控长事务：
> ```sql
> SELECT trx_id, trx_state, trx_started, trx_query,
>        TIMESTAMPDIFF(SECOND, trx_started, NOW()) AS seconds
>   FROM information_schema.INNODB_TRX
>  ORDER BY trx_started;
> ```

---

## 九、常见报错

> [!failure] ERROR 1568：Transaction characteristics can't be changed while a transaction is in progress
> 事务进行中修改隔离级别。等事务结束，或用 `SET SESSION` 在事务外设置。

> [!failure] ERROR 1792：Cannot execute statement in a READ ONLY transaction
> 在 `START TRANSACTION READ ONLY` 中执行了写操作。改用 `READ WRITE` 或普通 `START TRANSACTION`。

> [!failure] ERROR 1205：Lock wait timeout exceeded; try restarting transaction
> 等锁超过 `innodb_lock_wait_timeout`（默认 50 秒）。
> 默认只回滚当前语句，事务仍在；需要时设置 `innodb_rollback_on_timeout=ON` 回滚整个事务。

> [!failure] ERROR 1213：Deadlock found when trying to get lock; try restarting transaction
> InnoDB 检测到死锁，主动回滚了其中一个事务（牺牲者）。
> 应用应捕获该错误并**重试整个事务**。

> [!failure] ERROR 1305：SAVEPOINT ... does not exist
> `ROLLBACK TO SAVEPOINT` 指向了不存在的保存点。检查保存点是否已被 `RELEASE`，或被 `COMMIT` / DDL 清除。

> [!failure] ERROR 1422：Explicit or implicit commit is not allowed in stored function or trigger
> 在存储函数/触发器里执行了 `COMMIT` / `ROLLBACK`（或触发隐式提交的语句）。
> 把事务控制移到存储过程或应用层。

> [!failure] ERROR 1100：Table ... was not locked with LOCK TABLES
> 用了 `LOCK TABLES` 后访问了未锁定的表。检查锁表范围，或改用事务 + 行锁。

---

## 十、常见面试问答

> [!question] Q1：`BEGIN` 和 `START TRANSACTION` 有什么区别？
> `BEGIN` 是 `START TRANSACTION` 的别名，最简洁；
> `START TRANSACTION` 支持 `READ ONLY` / `READ WRITE` / `WITH CONSISTENT SNAPSHOT` 等修饰符。
> 在存储程序里，`BEGIN ... END` 是语句块，不是事务，必须用 `START TRANSACTION`。

> [!question] Q2：`autocommit=1` 时，`START TRANSACTION` 还有用吗？
> 有用。显式 `START TRANSACTION` 会覆盖当前语句的自动提交行为，后续 DML 直到 `COMMIT` / `ROLLBACK` 才结束。

> [!question] Q3：`autocommit=0` 和显式 `START TRANSACTION` 有什么区别？
> `autocommit=0` 是**会话级**的隐式事务模式，后续 DML 自动开启事务，容易忘记提交；
> `START TRANSACTION` 是**显式**事务，边界清晰，推荐在代码里使用。
> 两者可以叠加，但显式事务更可控。

> [!question] Q4：`START TRANSACTION` 会立刻加锁/建快照吗？
> 不会。锁在具体语句访问数据时才加；一致性快照在第一次快照读时建立。
> 只有 `WITH CONSISTENT SNAPSHOT` 会在开启时立即建立快照。

> [!question] Q5：事务中执行 DDL 会怎样？
> DDL 会**隐式提交**当前事务，之前未提交的 DML 也会一起落盘。
> 之后 `ROLLBACK` 只能回滚 DDL 之后的操作，前面的 DML 已经无法撤销。

> [!question] Q6：`START TRANSACTION` 能嵌套吗？
> 不能。MySQL 没有真正的嵌套事务。执行 `START TRANSACTION` 会先提交当前事务，再开新事务。
> 需要"事务内局部回滚"，用 [[SAVEPOINT]]。

> [!question] Q7：只读事务有什么用？
> 用于报表、导出、只读查询：防止误写，语义清晰，InnoDB 还能做部分优化。
> 它不改变账号权限，只限制当前事务不能写数据。

> [!question] Q8：`WITH CONSISTENT SNAPSHOT` 和普通 `START TRANSACTION` 的区别？
> 普通 RR 事务在第一次快照读时才建立快照；
> `WITH CONSISTENT SNAPSHOT` 在开启事务时就建立快照，适合逻辑备份和需要"从第一秒起就一致"的场景。

> [!question] Q9：长事务有什么危害？怎么发现？
> 危害：锁等待、undo 膨胀、history list 增长、回滚慢、死锁概率上升。
> 发现：`information_schema.INNODB_TRX`、`SHOW ENGINE INNODB STATUS`、`sys.innodb_lock_waits`、监控慢事务。

> [!question] Q10：事务开启后，什么时候分配事务 ID？
> InnoDB 通常在**第一次写操作**时分配事务 ID；只读事务可能不分配。
> 但一致性读视图会在第一次快照读时创建。

---

> [!quote] 一句话记忆
> **`BEGIN` / `START TRANSACTION` 只画起跑线，锁和快照用到才建；**
> **`autocommit` 是隐式开关，DDL/DCL 会偷偷提交；短事务、快提交、异常必回滚。**

---

## 相关笔记

- [[ACID]] —— 事务的四大特性
- [[COMMIT]] —— 提交事务
- [[ROLLBACK]] —— 回滚事务
- [[SAVEPOINT]] —— 事务内局部回滚
- [[Insert]] · [[Update]] · [[Delete]] —— 事务中的 DML
- [[Select]] · [[Where]] · [[Join]] —— 事务中的查询
- [[Create Table]] · [[Alter Table]] · [[Drop Table]] · [[Truncate Table]] —— DDL 隐式提交
- [[数据约束概述]] —— 事务一致性的约束基础
- [[四大SQL分类讲解]] —— TCL 与 DDL/DML/DQL/DCL 的边界
