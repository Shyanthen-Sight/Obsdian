# COMMIT —— 提交事务

> [!abstract] 一句话
> `COMMIT` 把当前事务的修改**正式生效**：结束事务、释放锁、让后续读取看到新值。
> InnoDB 靠 **redo log + WAL + fsync** 保证"提交成功就不丢"。

> [!info] 本篇在 TCL 中的位置
> [[BEGIN]] 开启 → DML 执行 → **COMMIT 提交** / [[ROLLBACK]] 回滚；
> 局部回滚用 [[SAVEPOINT]]；四大保证见 [[ACID]]。

---

## 一、语法

```sql
COMMIT;
COMMIT WORK;            -- 标准 SQL 的可选写法

COMMIT AND CHAIN;       -- 提交后立即开启一个新事务（沿用当前隔离级别）
COMMIT AND NO CHAIN;    -- 提交后结束事务（默认）
COMMIT RELEASE;         -- 提交后断开客户端连接
```

| 写法 | 作用 |
| --- | --- |
| `COMMIT` | 提交并结束当前事务 |
| `COMMIT WORK` | 同上，`WORK` 可省略 |
| `COMMIT AND CHAIN` | 提交后立刻开始新事务 |
| `COMMIT AND NO CHAIN` | 提交后结束（默认行为） |
| `COMMIT RELEASE` | 提交后断开连接 |

> [!note] 没有活动事务时，`COMMIT` 是空操作
> 在 `autocommit=1` 且没有显式事务时执行 `COMMIT`，不会报错，也不会"提交"什么。
> 它只是确认当前没有待提交的事务。

> [!warning] `COMMIT` 属于 TCL，不是 DCL
> `COMMIT` / `ROLLBACK` 管的是**事务边界**；
> `GRANT` / `REVOKE` 才是 DCL，管的是**权限**。
> 详见 [[四大SQL分类讲解]]。

---

## 二、`COMMIT` 到底做了什么

一次提交大致按下面的顺序发生：

```text
COMMIT
  │
  ├── 1. 结束事务，释放行锁 / 表锁
  ├── 2. 修改对其他事务可见（按隔离级别）
  ├── 3. redo log 写入 + 按参数 fsync
  ├── 4. binlog 写入（如开启）
  ├── 5. undo log 保留，等待 purge 线程清理
  └── 6. 数据页不一定立即刷盘，由 checkpoint 后续处理
```

| 步骤 | 说明 |
| --- | --- |
| **结束事务** | 事务状态从 `RUNNING` 变为 `COMMITTED` |
| **释放锁** | 行锁、间隙锁、表锁等释放，等待中的事务可以继续 |
| **可见性** | 其他事务能否看到，取决于它的隔离级别和快照 |
| **redo log** | 保证持久性；提交时是否 `fsync` 由参数决定 |
| **binlog** | 主从复制、CDC 依赖；与 redo log 有两阶段提交 |
| **undo log** | 不立即删除；只要还有旧快照需要它，purge 就不能清理 |
| **数据页** | 不要求提交时刷盘；WAL 已经保证可恢复 |

> [!tip] 为什么提交可以很快？
> 因为 InnoDB 不在提交时随机写数据页，而是**顺序追加 redo log**。
> 数据页的随机写被推迟到后台 checkpoint，这就是 WAL 的核心价值。

---

## 三、持久性：`COMMIT` 返回后真的不丢吗？

> [!important] 取决于参数，不取决于 `COMMIT` 这四个字母
> 默认配置下（`innodb_flush_log_at_trx_commit=1`），已提交事务在崩溃后可以恢复。
> 如果调成 `0` 或 `2`，`COMMIT` 返回了，崩溃仍可能丢最近约 1 秒的数据。

### 3.1 `innodb_flush_log_at_trx_commit`

| 值 | 提交时做什么 | 崩溃会丢多少 | 性能 |
| --- | --- | --- | --- |
| `0` | 写 redo log buffer；**每秒**写文件并 `fsync` | 最多丢 **1 秒** | 最快 |
| `1` | **每次提交**都写文件并 `fsync` | 已提交的不丢 | 最慢、最安全 |
| `2` | 每次提交**写 OS cache**；每秒 `fsync` | MySQL 崩溃不丢；**OS 崩溃**最多丢 1 秒 | 折中 |

```sql
SHOW VARIABLES LIKE 'innodb_flush_log_at_trx_commit';

-- 金融级数据：保持 1
SET GLOBAL innodb_flush_log_at_trx_commit = 1;
```

### 3.2 `sync_binlog`

如果开启了 binlog，还要让 binlog 落盘：

| 值 | 行为 | 风险 |
| --- | --- | --- |
| `0` | 由操作系统决定 | 崩溃可能丢 binlog |
| `1` | 每次提交 `fsync` | 最安全，推荐 |
| `N` | 每 N 次提交 `fsync` | 崩溃最多丢 N 个事务 |

> [!success] 推荐组合
> ```ini
> innodb_flush_log_at_trx_commit = 1
> sync_binlog = 1
> ```
> 这是"提交成功就不丢"的必要条件，代价是每次提交至少两次 `fsync`。
> 日志、监控、缓存类数据可以适当放宽；订单、支付、账务必须严格。

### 3.3 两阶段提交：redo log 与 binlog

开启 binlog 后，一次提交要保证 **redo log 和 binlog 一致**，否则主从数据可能不一致。MySQL 用两阶段提交：

```text
1. InnoDB 写 redo log，标记 PREPARE
2. 写 binlog
3. InnoDB 写 redo log，标记 COMMIT
```

崩溃恢复时：

| 崩溃点 | 处理 |
| --- | --- |
| redo 已 PREPARE，binlog 未写完 | 回滚事务 |
| redo 已 PREPARE，binlog 已完整 | 提交事务 |
| redo 已 COMMIT | 提交事务 |

> [!info] 为什么需要两阶段提交？
> 如果先提交 redo 再写 binlog，崩溃可能导致"主库有、从库没有"；
> 如果先写 binlog 再提交 redo，崩溃可能导致"从库有、主库没有"。
> 两阶段提交让两者要么都成功、要么都失败。

### 3.4 双写缓冲与组提交

| 机制 | 作用 |
| --- | --- |
| **Doublewrite Buffer** | 防止页撕裂（torn page），保证数据页本身完整 |
| **组提交（Group Commit）** | 把多个事务的日志刷盘合并成一次系统调用，提高并发提交吞吐 |

> [!tip] 组提交是高并发下提交仍然快的关键
> 并发越高，多个事务越容易"拼车"一起 `fsync`，单事务的平均提交成本越低。
> 相关参数：`binlog_group_commit_sync_delay`、`binlog_group_commit_sync_no_delay_count`。

---

## 四、提交与可见性

> [!abstract] 提交了，别人不一定马上看得到
> 其他事务能否看到你刚提交的数据，取决于它的**隔离级别**和**快照创建时间**。

### 4.1 自己总能看到自己的修改

```sql
START TRANSACTION;
UPDATE student SET score = 100 WHERE id = 1;
SELECT score FROM student WHERE id = 1;   -- 100，自己的修改自己可见
COMMIT;
```

### 4.2 其他事务的可见性

| 场景 | 能否看到刚提交的数据 |
| --- | --- |
| 对方是 `READ COMMITTED`，提交后执行新语句 | ✅ 能看到 |
| 对方是 `REPEATABLE READ`，事务早已开始并有快照 | ❌ 看不到，直到它结束/重新开始 |
| 对方是 `REPEATABLE READ`，提交后才第一次快照读 | ✅ 能看到 |
| 对方执行 `SELECT ... FOR UPDATE` | ✅ 当前读，看到最新已提交版本 |

```text
T1: START TRANSACTION; UPDATE ...; COMMIT;          -- 提交
T2: START TRANSACTION; SELECT ...;                  -- 快照已建立
    （T1 提交）
T2: SELECT ...;                                     -- RR 下仍看到旧值
T2: COMMIT;
T2（新事务）: SELECT ...;                            -- 看到新值
```

> [!note] 这不是"提交失败"
> 数据已经提交，只是对方的一致性快照看不到。
> 需要读最新数据时，用新事务，或使用当前读（`FOR UPDATE` / `LOCK IN SHARE MODE`），但要注意加锁代价。

---

## 五、隐式提交：哪些语句会"替你做 COMMIT"

> [!danger] 隐式提交 = 你不写 `COMMIT`，MySQL 也帮你提交了
> 当前事务会结束，之前未提交的 DML 一起落盘，`ROLLBACK` 无法撤销。

### 5.1 DDL

```sql
CREATE DATABASE / DROP DATABASE
CREATE TABLE / ALTER TABLE / DROP TABLE / TRUNCATE TABLE / RENAME TABLE
CREATE INDEX / DROP INDEX
CREATE VIEW / ALTER VIEW / DROP VIEW
CREATE TRIGGER / DROP TRIGGER
CREATE PROCEDURE / DROP PROCEDURE
CREATE FUNCTION / DROP FUNCTION
```

> [!note] 临时表例外
> `CREATE TEMPORARY TABLE` 和 `DROP TEMPORARY TABLE` 不会隐式提交。

### 5.2 DCL / 账号管理

```sql
GRANT / REVOKE
CREATE USER / DROP USER / ALTER USER / RENAME USER
SET PASSWORD
```

### 5.3 其他

```sql
LOCK TABLES
UNLOCK TABLES        -- 之前用 LOCK TABLES 锁过表时
SET autocommit = 1   -- 从 0 改成 1
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
> 正确做法：DDL 放在事务外，或者先 `COMMIT` 再做 DDL。

---

## 六、提交失败与"不确定结果"

> [!warning] `COMMIT` 报错，不代表一定没提交
> 网络在提交过程中断开、客户端超时、服务端崩溃，都可能让客户端**不知道事务到底提交了没有**。
> 这是分布式系统里的经典"不确定结果"问题。

常见现象：

| 现象 | 可能原因 |
| --- | --- |
| `ERROR 2006: MySQL server has gone away` | 连接断开，提交结果未知 |
| `ERROR 2013: Lost connection to MySQL server during query` | 网络/服务端异常，结果未知 |
| 客户端超时，但服务端已提交 | 请求发出去了，响应没回来 |
| 磁盘满 / I/O 错误 | 提交可能失败，需检查错误日志 |

> [!success] 处理原则：**幂等 + 重试 + 对账**
> 1. 给业务操作设计**幂等键**（订单号、请求 ID、唯一索引）
> 2. 重试前先查询业务状态，不要盲目重复写
> 3. 对账/补偿任务兜底
> 4. 关键操作记录本地事务表或 outbox

```sql
-- 用唯一索引做幂等兜底
CREATE TABLE payment (
    id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    request_id VARCHAR(64) NOT NULL,
    amount     DECIMAL(10,2) NOT NULL,
    UNIQUE KEY uk_request_id (request_id)
);
-- 重复提交会撞唯一键，而不是重复扣款
```

### 6.1 XA 分布式事务

跨多个数据库/资源时，单机 `COMMIT` 不够，可以用 XA：

```sql
XA START 'xid-001';
UPDATE db1.account SET balance = balance - 100 WHERE id = 1;
XA END 'xid-001';
XA PREPARE 'xid-001';

-- 另一个资源执行类似操作后
XA COMMIT 'xid-001';
-- 或 XA ROLLBACK 'xid-001';
```

> [!note] XA 的代价
> XA 需要协调者、prepare 阶段持锁、故障恢复复杂，性能明显低于本地事务。
> 能不用就不用；优先考虑**本地消息表、事务消息、Saga、TCC** 等方案。

---

## 七、`COMMIT` vs `ROLLBACK` vs 隐式提交

| 对比项 | `COMMIT` | `ROLLBACK` | 隐式提交 |
| --- | --- | --- | --- |
| 是否结束事务 | ✅ | ✅ | ✅ |
| 修改是否生效 | ✅ 永久生效 | ❌ 撤销 | ✅ 永久生效 |
| 是否释放锁 | ✅ | ✅ | ✅ |
| 能否撤销 | ❌ | — | ❌ |
| 典型触发 | 手动 `COMMIT` | 手动 `ROLLBACK` | DDL / DCL / `SET autocommit=1` 等 |
| 是否可预期 | ✅ 明确 | ✅ 明确 | ⚠️ 容易踩坑 |

> [!tip] 事务脚本里只出现两种结局
> **要么 `COMMIT`，要么 `ROLLBACK`**。
> 不要在中间混入 DDL/DCL，否则会出现"第三种结局"——你不想看到的隐式提交。

---

## 八、最佳实践

> [!success] 提交相关的七条经验
> 1. **短事务**：开启后尽快提交，不在事务里等用户、调 RPC、发消息
> 2. **批量分批提交**：每 500~1000 行提交一次，避免超大事务
> 3. **异常分支必须 `ROLLBACK`**：不要让事务悬空、锁不释放
> 4. **关键数据用 `1 + 1`**：`innodb_flush_log_at_trx_commit=1`、`sync_binlog=1`
> 5. **幂等设计**：提交结果不确定时，靠唯一键/请求 ID 防重复
> 6. **不要在函数/触发器里提交**：会报 `ERROR 1422`
> 7. **监控长事务和 history list**：长事务会阻止 undo purge

```sql
-- 查看长事务
SELECT trx_id, trx_state, trx_started, trx_query,
       TIMESTAMPDIFF(SECOND, trx_started, NOW()) AS seconds
  FROM information_schema.INNODB_TRX
 ORDER BY trx_started;

-- 查看 history list（undo 堆积情况）
SHOW ENGINE INNODB STATUS\G
-- 关注 TRANSACTIONS 段的 History list length

-- 提交/回滚计数
SHOW GLOBAL STATUS LIKE 'Com_commit';
SHOW GLOBAL STATUS LIKE 'Com_rollback';
```

> [!warning] `Com_commit` 高不一定是坏事
> 它只说明提交次数多。要结合业务 QPS、慢查询、锁等待一起看。
> 真正要警惕的是**长事务**、**锁等待**、**history list 持续增长**。

---

## 九、常见报错

> [!failure] ERROR 1422：Explicit or implicit commit is not allowed in stored function or trigger
> 在存储函数/触发器里执行了 `COMMIT` / `ROLLBACK`，或触发了隐式提交的语句。
> 把事务控制移到存储过程或应用层。

> [!failure] ERROR 1213：Deadlock found when trying to get lock
> 死锁牺牲者被回滚，当前事务已经结束。
> 捕获错误后**重试整个事务**，不要只重试最后一条语句。

> [!failure] ERROR 1205：Lock wait timeout exceeded
> 等锁超时。默认只回滚当前语句，事务可能仍在；
> 需要整个事务回滚时，设置 `innodb_rollback_on_timeout=ON`。

> [!failure] ERROR 2006 / 2013：连接断开
> 提交结果未知。不要盲目重试写操作，先按业务幂等键查询状态。

> [!failure] ERROR 1040：Too many connections
> 连接耗尽。检查连接池、慢查询、长事务是否占满了连接。

---

## 十、常见面试问答

> [!question] Q1：`COMMIT` 做了什么？
> 结束事务、释放锁、让修改对其他事务可见；写入并 `fsync` redo log（按参数）；写 binlog；undo log 留待 purge；数据页由 checkpoint 后续刷盘。

> [!question] Q2：`COMMIT` 之后数据一定不丢吗？
> 不一定。`innodb_flush_log_at_trx_commit=1` 且 `sync_binlog=1` 时，已提交事务可通过 redo/binlog 恢复；
> 设为 `0` 或 `2` 时，崩溃可能丢最近约 1 秒的数据。

> [!question] Q3：redo log 和 binlog 为什么要两阶段提交？
> 为了保证两者一致。否则崩溃时可能出现"主库有、从库没有"或"从库有、主库没有"。
> 两阶段提交让 redo 和 binlog 要么都生效、要么都回滚。

> [!question] Q4：`COMMIT` 后为什么其他事务还看不到？
> 因为对方可能处于 `REPEATABLE READ` 且已经建立了旧快照。
> 数据已提交，只是对方的一致性视图看不到；新事务或当前读可以看到。

> [!question] Q5：哪些语句会隐式提交？
> DDL（`CREATE` / `ALTER` / `DROP` / `TRUNCATE` / `RENAME` / `CREATE INDEX` 等）、DCL（`GRANT` / `REVOKE` / 用户管理）、`LOCK TABLES`、`SET autocommit=1`、`START TRANSACTION`、`ANALYZE/OPTIMIZE/REPAIR/FLUSH` 等。
> `CREATE TEMPORARY TABLE` / `DROP TEMPORARY TABLE` 是例外。

> [!question] Q6：`COMMIT AND CHAIN` 有什么用？
> 提交当前事务后立即开启一个新事务，沿用当前隔离级别。
> 适合批量循环处理：每批提交后马上开始下一批，减少事务开启的往返。

> [!question] Q7：提交结果不确定怎么办？
> 用幂等键（订单号、请求 ID、唯一索引）防止重复写入；
> 重试前先查询业务状态；配合对账/补偿任务。不要盲目重试扣款、下单等非幂等操作。

> [!question] Q8：为什么组提交能提高性能？
> 多个事务的 redo/binlog 刷盘可以合并成一次 `fsync`，摊薄单事务的磁盘同步成本。
> 并发越高，组提交收益越明显。

> [!question] Q9：XA 是什么？
> XA 是分布式事务的两阶段提交协议：`XA START` → `XA END` → `XA PREPARE` → `XA COMMIT/ROLLBACK`。
> 适合跨多个资源的一致性，但性能差、恢复复杂，能不用就不用。

> [!question] Q10：为什么不能在存储函数/触发器里 `COMMIT`？
> 存储函数/触发器运行在调用者的事务上下文里，如果允许提交，会破坏调用者的事务边界。
> MySQL 直接禁止，报 `ERROR 1422`。事务控制应放在存储过程或应用层。

---

> [!quote] 一句话记忆
> **`COMMIT` = 结束事务 + 释放锁 + 写日志；提交是否真的不丢，看 `flush_log_at_trx_commit` 和 `sync_binlog`。**
> **提交后别人未必马上看到（快照），DDL/DCL 会隐式提交，提交结果不确定时靠幂等兜底。**

---

## 相关笔记

- [[ACID]] —— 原子性、一致性、隔离性、持久性
- [[BEGIN]] —— 开启事务
- [[ROLLBACK]] —— 回滚事务
- [[SAVEPOINT]] —— 事务内局部回滚
- [[Insert]] · [[Update]] · [[Delete]] —— 事务中的 DML
- [[Create Table]] · [[Alter Table]] · [[Drop Table]] · [[Truncate Table]] —— DDL 隐式提交
- [[数据约束概述]] —— 唯一约束与幂等设计
- [[四大SQL分类讲解]] —— TCL 与 DCL 的区别
