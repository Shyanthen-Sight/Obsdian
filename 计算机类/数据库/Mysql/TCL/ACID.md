# ACID —— 事务的四大特性

> [!abstract] 一句话
> 事务是"**要么全做、要么全不做**"的逻辑工作单元；ACID 是它的四个保证：
> **A 原子性**不半途而废、**C 一致性**不破坏规则、**I 隔离性**互不干扰、**D 持久性**提交不丢。

> [!info] 事务的边界
> [[BEGIN]] 开启 → DML 执行 → [[COMMIT]] 提交 / [[ROLLBACK]] 回滚；
> 事务内部要"局部反悔"，用 [[SAVEPOINT]]。

---

## 一、什么是事务

事务（Transaction）是一组**不可分割的 SQL 操作**。它们要么全部生效，要么全部不生效。

最经典的例子是转账：

```sql
START TRANSACTION;

UPDATE account SET balance = balance - 100 WHERE id = 1;  -- 张三 -100
UPDATE account SET balance = balance + 100 WHERE id = 2;  -- 李四 +100

COMMIT;
```

如果第二条 `UPDATE` 失败，而第一条已经生效，钱就凭空消失了。
事务的作用就是：**两条要么都成功，要么都当没发生过**。

> [!tip] 事务解决的是"并发 + 故障"下的正确性问题
> 单机、单用户、永不崩溃时，你确实不太需要事务。
> 但真实系统一定会有：并发写入、网络中断、进程崩溃、磁盘故障。事务就是为这些情况兜底的。

---

## 二、A —— 原子性（Atomicity）

> [!abstract] 一句话
> 事务里的操作是一个整体：**全部成功，或者全部撤销**，不存在"做了一半"。

### 2.1 靠什么实现：undo log

InnoDB 在执行 `INSERT` / `UPDATE` / `DELETE` 时，会把**修改前的数据**记录到 **undo log（回滚日志）**。

- 执行 `ROLLBACK` → 按 undo log 把数据改回去
- 事务执行到一半报错 → 语句级回滚，或整个事务回滚
- 数据库崩溃 → 未提交事务在恢复时用 undo log 回滚

```sql
START TRANSACTION;

UPDATE account SET balance = balance - 100 WHERE id = 1;
-- 此时 undo log 里记下了：id=1 的 balance 原来是 1000

ROLLBACK;
-- 根据 undo log 恢复：id=1 的 balance 回到 1000
```

### 2.2 原子性的边界

| 场景 | 是否原子 |
| --- | --- |
| `INSERT` / `UPDATE` / `DELETE`（InnoDB） | ✅ 可回滚 |
| 多条 DML 组成的事务 | ✅ 整体回滚 |
| `CREATE` / `ALTER` / `DROP` / `TRUNCATE` | ❌ DDL 隐式提交，不能回滚 |
| `GRANT` / `REVOKE` | ❌ 隐式提交 |
| MyISAM 等非事务引擎 | ❌ 不支持事务 |
| 发送邮件、调用接口、写文件 | ❌ 外部副作用，数据库管不了 |

> [!warning] "原子性"只覆盖事务内的数据库操作
> 事务回滚不会帮你撤回已发送的短信、已扣的第三方支付、已写入的消息队列。
> 涉及外部系统时，要靠**幂等 + 补偿事务 + 本地消息表 / outbox** 等方案，不能只靠 `ROLLBACK`。

---

## 三、C —— 一致性（Consistency）

> [!abstract] 一句话
> 事务执行前后，数据库都必须处于**满足所有规则**的状态：约束不被破坏，业务不变量成立。

### 3.1 一致性包括什么

| 层次 | 例子 | 靠谁保证 |
| --- | --- | --- |
| 实体完整性 | 主键唯一、非空 | `PRIMARY KEY` / `NOT NULL` |
| 参照完整性 | 外键必须指向存在的行 | `FOREIGN KEY` |
| 域完整性 | 年龄在 0~150、金额不能为负 | 数据类型 / `CHECK` |
| 唯一性 | 手机号、订单号不能重复 | `UNIQUE` |
| 业务不变量 | 转账前后两人余额之和不变 | 应用逻辑 + 事务 |

```sql
-- 转账的业务不变量：a.balance + b.balance 恒定
START TRANSACTION;
UPDATE account SET balance = balance - 100 WHERE id = 1;
UPDATE account SET balance = balance + 100 WHERE id = 2;
COMMIT;
-- 无论中间发生什么，提交后总额必须不变
```

> [!important] C 是"目标"，A、I、D 是"手段"
> 很多教材把 ACID 并列讲，容易误解成四个独立机制。
> 更准确的理解是：
> - **A** 保证不半途而废
> - **I** 保证并发不互相踩踏
> - **D** 保证提交后不丢
> - **C** 是前三者共同服务的结果，同时还需要**约束 + 业务代码**配合
>
> 数据库只能保证"约束层面的一致性"；"业务层面的一致性"永远需要应用自己负责。

### 3.2 一致性不是数据库一个人的事

```sql
-- 数据库能挡住：余额变成 NULL、主键重复、外键指向不存在的用户
-- 数据库挡不住：A 转给 B，但业务要求"单日累计不超过 5 万"
```

> [!tip] 把能下沉的规则尽量下沉到数据库
> `NOT NULL`、`UNIQUE`、`FOREIGN KEY`、`CHECK` 是**所有写入路径都绕不过的物理墙**；
> 应用层校验只拦得住走这个接口的请求。两者都要有，但数据库约束是最后一道防线。
> 详见 [[数据约束概述]]。

---

## 四、I —— 隔离性（Isolation）

> [!abstract] 一句话
> 多个事务并发执行时，彼此**不应该看到对方未提交的中间状态**，也不能互相把结果改乱。

### 4.1 并发会带来的四类问题

| 问题 | 定义 | 例子 |
| --- | --- | --- |
| **脏读**（Dirty Read） | 读到了另一个事务**未提交**的数据 | T1 把余额改成 0 但没提交，T2 读到了 0 |
| **不可重复读**（Non-repeatable Read） | 同一事务内，两次读**同一行**，结果不同 | T1 第一次读余额 100，T2 提交改成 200，T1 再读变成 200 |
| **幻读**（Phantom Read） | 同一事务内，两次读**同一范围**，行数不同 | T1 查"年龄 > 18"有 10 行，T2 插入 1 行并提交，T1 再查变 11 行 |
| **丢失更新**（Lost Update） | 两个事务读同一值、各自修改，后提交的覆盖先提交的 | 两人同时读余额 100，各扣 10，最终变成 90 而不是 80 |

> [!note] 不可重复读 vs 幻读
> - **不可重复读**：同一行，**值**变了
> - **幻读**：同一范围，**行数**变了
>
> 前者通常是 `UPDATE` 造成的，后者通常是 `INSERT` / `DELETE` 造成的。

### 4.2 四种隔离级别

| 隔离级别 | 脏读 | 不可重复读 | 幻读 | 说明 |
| --- | --- | --- | --- | --- |
| `READ UNCOMMITTED` | ✅ 可能 | ✅ 可能 | ✅ 可能 | 几乎不用，性能最好但最不安全 |
| `READ COMMITTED`（RC） | ❌ | ✅ 可能 | ✅ 可能 | Oracle / PostgreSQL 默认 |
| `REPEATABLE READ`（RR） | ❌ | ❌ | ⚠️ 标准允许，InnoDB 基本避免 | **MySQL InnoDB 默认** |
| `SERIALIZABLE` | ❌ | ❌ | ❌ | 最强，并发最差 |

```sql
-- 查看当前隔离级别（MySQL 8.0）
SELECT @@transaction_isolation;

-- 5.7 及以前
SELECT @@tx_isolation;

-- 设置当前会话
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- 设置全局（只影响之后新建的连接）
SET GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- 只对下一个事务生效（必须在事务开始前执行）
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

> [!warning] `SET TRANSACTION` 必须在事务开始前
> 事务已经 `START TRANSACTION` 后再改隔离级别，会报：
> `ERROR 1568 (25001): Transaction characteristics can't be changed while a transaction is in progress`
> 要改就改 `SESSION` / `GLOBAL`，或者等当前事务结束。

### 4.3 MySQL 的 RR 为什么"看起来"没有幻读

InnoDB 的 `REPEATABLE READ` 同时用了两套机制：

| 读法 | 机制 | 效果 |
| --- | --- | --- |
| **快照读**（普通 `SELECT`） | MVCC + Read View | 整个事务看到同一个快照，重复读结果一致 |
| **当前读**（`SELECT ... FOR UPDATE` / `LOCK IN SHARE MODE` / `UPDATE` / `DELETE`） | 行锁 + **临键锁（Next-Key Lock）** | 锁住记录及间隙，阻止其他事务插入，避免幻读 |

> [!important] 标准 RR 允许幻读，InnoDB 的 RR 是"加强版"
> - SQL 标准只要求 RR 解决脏读和不可重复读，**允许幻读**。
> - InnoDB 在 RR 下通过 **MVCC 快照**让普通查询看不到新插入的行；
>   通过 **临键锁**让锁定读/写操作阻止范围内的插入。
> - 所以日常说"MySQL RR 没有幻读"基本成立，但要注意：
>   **快照读和当前读的行为不同**，不要混为一谈。

```sql
-- 快照读：走 MVCC，不加锁
SELECT * FROM student WHERE age > 18;

-- 当前读：加临键锁，锁住 age > 18 的范围，阻止插入
SELECT * FROM student WHERE age > 18 FOR UPDATE;
```

### 4.4 RC 与 RR 的关键差异

| 对比项 | `READ COMMITTED` | `REPEATABLE READ` |
| --- | --- | --- |
| 快照创建时机 | **每条语句**创建新快照 | **事务第一次快照读**时创建，整个事务复用 |
| 不可重复读 | 可能 | 不会（快照读） |
| 间隙锁 | 基本不用（外键/唯一键检查除外） | 使用临键锁 |
| 并发度 | 更高 | 相对较低 |
| 适用场景 | 高并发 OLTP、很多互联网公司默认改成 RC | 需要事务内稳定视图、MySQL 默认 |

> [!tip] 互联网业务为什么常把 RC 设为默认？
> RC 不加间隙锁，锁范围小、死锁概率低、并发更高；代价是同一事务内可能读到不同快照。
> 这不是"RC 更先进"，而是**业务愿意接受不可重复读，换取吞吐**。
> 改默认值前一定要评估业务是否依赖"事务内多次读一致"。

### 4.5 隔离性靠什么实现

| 机制 | 作用 |
| --- | --- |
| **MVCC**（多版本并发控制） | 普通读不加锁，读 undo log 里的历史版本 |
| **Read View** | 判断当前事务能看到哪些版本 |
| **行锁** | 锁定读/写时防止并发修改同一行 |
| **间隙锁（Gap Lock）** | 锁住索引记录之间的"空隙"，防止插入 |
| **临键锁（Next-Key Lock）** | 记录锁 + 间隙锁，锁住范围 |
| **意向锁（Intention Lock）** | 表级锁与行级锁的协作 |

> [!note] MVCC 只对"普通读"有效
> `SELECT ... FOR UPDATE`、`UPDATE`、`DELETE` 是**当前读**，读最新已提交版本，并且加锁。
> 所以"MVCC = 不加锁"只适用于快照读。

---

## 五、D —— 持久性（Durability）

> [!abstract] 一句话
> 一旦 `COMMIT` 成功返回，即使下一秒数据库崩溃、机器断电，已提交的数据也不能丢。

### 5.1 靠什么实现：redo log + WAL

InnoDB 不会在提交时立刻把数据页写回磁盘（那是随机 I/O，太慢），而是：

1. 把修改记录顺序写入 **redo log**
2. 按配置 `fsync` 到磁盘
3. 数据页在后台由 checkpoint 慢慢刷盘

这就是 **WAL（Write-Ahead Logging，预写日志）**：
**先写日志，再写数据页**。崩溃恢复时，用 redo log 把已提交但未刷盘的数据重放出来。

```text
事务修改 → 写 redo log（顺序写，快） → COMMIT 返回
                ↓
        后台 checkpoint 刷数据页（随机写，慢，可延后）
```

> [!tip] 为什么 redo log 能把随机写变成顺序写？
> 数据页分散在磁盘各处，直接刷盘是随机 I/O；
> redo log 是追加写，顺序 I/O 快得多。提交时只保证日志落盘，数据页可以慢慢来。

### 5.2 `innodb_flush_log_at_trx_commit`

这是持久性最关键的一个参数：

| 值 | 提交时做什么 | 崩溃会丢多少 | 性能 |
| --- | --- | --- | --- |
| `0` | 写 redo log buffer；**每秒**写文件并 `fsync` | 最多丢 **1 秒** | 最快 |
| `1` | **每次提交**都写文件并 `fsync` | 已提交的不丢 | 最慢、最安全 |
| `2` | 每次提交**写 OS cache**；每秒 `fsync` | MySQL 崩溃不丢；**操作系统崩溃**最多丢 1 秒 | 折中 |

```sql
SHOW VARIABLES LIKE 'innodb_flush_log_at_trx_commit';

-- 生产环境金融级数据：保持 1
SET GLOBAL innodb_flush_log_at_trx_commit = 1;
```

> [!danger] `0` / `2` 不是"免费加速"
> 它们把持久性换成了性能。`0` 在 MySQL 进程崩溃时就会丢数据；`2` 在断电/OS 崩溃时会丢数据。
> 日志、监控、缓存类数据可以适当放宽；订单、支付、账务必须用 `1`。

### 5.3 `sync_binlog`

如果开启了 binlog（主从复制、CDC 依赖它），还要保证 binlog 落盘：

| 值 | 行为 | 风险 |
| --- | --- | --- |
| `0` | 由操作系统决定何时刷盘 | 崩溃可能丢 binlog |
| `1` | **每次提交**都 `fsync` binlog | 最安全，推荐 |
| `N` | 每 N 次提交 `fsync` 一次 | 崩溃最多丢 N 个事务 |

> [!success] 金融级持久性组合
> ```ini
> innodb_flush_log_at_trx_commit = 1
> sync_binlog = 1
> ```
> 代价是每次提交至少两次 `fsync`，但这是"提交成功就不丢"的必要条件。

### 5.4 双写缓冲（Doublewrite Buffer）

如果数据库在写数据页的过程中崩溃，可能只写了半个页（**页撕裂 / torn page**）。redo log 也无法修复一个本身就不完整的页。

InnoDB 的解决办法是 **doublewrite**：

1. 先把页写到 doublewrite 区域
2. 再写到真实数据文件
3. 崩溃恢复时，用 doublewrite 里的完整副本修复坏页

```sql
SHOW VARIABLES LIKE 'innodb_doublewrite';   -- 默认 ON
```

> [!note] doublewrite 是"页完整性"的保险
> redo log 保证"已提交的事务不丢"，doublewrite 保证"页本身不写坏"。
> 两者解决的不是同一个问题。

### 5.5 组提交（Group Commit）

高并发下，如果每个事务都单独 `fsync`，磁盘会被打爆。InnoDB / MySQL 会把多个事务的日志刷盘合并成一次系统调用，这就是 **组提交**。

- 多个事务一起等待、一起 `fsync`
- 并发越高，摊薄后的单事务提交成本越低
- 相关参数：`binlog_group_commit_sync_delay`、`binlog_group_commit_sync_no_delay_count`

> [!tip] 组提交是"高并发下提交仍然快"的关键
> 这也是为什么"批量提交"通常比"每条自动提交"快得多。

---

## 六、ACID 在 InnoDB 中的实现映射

| 特性 | 核心机制 | 关键日志 / 参数 |
| --- | --- | --- |
| **A 原子性** | undo log 回滚 | undo tablespace、`ROLLBACK` |
| **C 一致性** | 约束 + 触发器 + 应用逻辑 | `PRIMARY KEY` / `FOREIGN KEY` / `UNIQUE` / `CHECK` / `NOT NULL` |
| **I 隔离性** | MVCC + Read View + 行锁 / 间隙锁 / 临键锁 | `transaction_isolation` |
| **D 持久性** | redo log + WAL + `fsync` + doublewrite | `innodb_flush_log_at_trx_commit`、`sync_binlog` |

> [!info] 一句话串起来
> **undo log 管反悔，redo log 管不丢，MVCC + 锁管并发，约束 + 业务管规则。**

---

## 七、ACID 的代价与权衡

> [!abstract] ACID 不是"越高越好"，而是"按业务选档位"

| 维度 | 更安全的选择 | 代价 |
| --- | --- | --- |
| 隔离级别 | `SERIALIZABLE` > `RR` > `RC` > `RU` | 并发度下降、锁等待/死锁增加 |
| 持久性 | `innodb_flush_log_at_trx_commit=1` + `sync_binlog=1` | 每次提交多次 `fsync`，吞吐下降 |
| 事务大小 | 短事务、尽快提交 | 需要更细的业务拆分 |
| 一致性 | 强约束 + 同步校验 | 写入路径变长、冲突更容易暴露 |

> [!warning] 长事务是 ACID 的"隐形杀手"
> 长事务会：
> - 长时间持有锁，阻塞其他事务
> - 阻止 undo log purge，导致 history list 膨胀
> - 占用大量 undo 空间和 buffer pool
> - 回滚时可能要执行很久
>
> 监控：
> ```sql
> SELECT trx_id, trx_state, trx_started, trx_query,
>        TIMESTAMPDIFF(SECOND, trx_started, NOW()) AS seconds
>   FROM information_schema.INNODB_TRX
>  ORDER BY trx_started;
> ```

---

## 八、ACID vs BASE

| 对比项 | ACID | BASE |
| --- | --- | --- |
| 全称 | Atomicity / Consistency / Isolation / Durability | Basically Available / Soft state / Eventually consistent |
| 典型系统 | 关系型数据库（MySQL、PostgreSQL、Oracle） | 多数 NoSQL（Redis、MongoDB、Cassandra 等） |
| 一致性 | 强一致 | 最终一致 |
| 可用性 | 故障时可能牺牲可用性 | 优先保证可用 |
| 适用场景 | 交易、账务、库存等强一致业务 | 社交动态、日志、推荐、缓存等 |

> [!note] ACID 和 BASE 不是"先进 vs 落后"
> 它们是不同业务目标下的取舍。银行转账需要 ACID；点赞数晚几秒一致通常可以接受。
> 很多系统是混合架构：核心交易走关系库，周边读模型/缓存走最终一致。
> 详见 [[Nosql跟sql]]。

---

## 九、常见误区

> [!failure] 误区一：事务能撤销一切
> DDL（`CREATE` / `ALTER` / `DROP` / `TRUNCATE`）、DCL（`GRANT` / `REVOKE`）会隐式提交，`ROLLBACK` 撤不回。
> 自增 ID、外部接口调用、文件写入、会话变量也都撤不回。

> [!failure] 误区二：`COMMIT` 返回就一定持久
> 只有在 `innodb_flush_log_at_trx_commit=1`（以及需要时 `sync_binlog=1`）的前提下，"提交成功"才等于"落盘"。
> 参数放宽后，崩溃可能丢最近 1 秒的数据。

> [!failure] 误区三：隔离级别越高越好
> `SERIALIZABLE` 会把并发压得很低，死锁和锁等待显著增加。
> 大多数业务用 `RR` 或 `RC` 就够；关键是**明确业务能接受哪种异常**。

> [!failure] 误区四：MySQL 的 RR 完全没有幻读
> InnoDB 的 RR 通过 MVCC + 临键锁在大多数场景下避免了幻读，但标准 RR 允许幻读；
> 快照读和当前读的行为也不同，不能简单说"绝对没有"。

> [!failure] 误区五：一致性只靠数据库
> 数据库只能保证约束层面的一致性。业务不变量（总额、库存、状态机）必须由应用逻辑和事务边界共同保证。

> [!failure] 误区六：所有表都支持事务
> MySQL 中只有 InnoDB 等事务引擎支持；MyISAM 不支持事务，写入即生效，`ROLLBACK` 无效。
> 建表时确认 `ENGINE=InnoDB`。

> [!failure] 误区七：事务越大越"安全"
> 大事务锁得多、undo 大、回滚慢、失败代价高。正确做法是**短事务 + 明确边界**，而不是把所有操作塞进一个事务。

---

## 十、常见面试问答

> [!question] Q1：请解释 ACID。
> - **A 原子性**：事务内的操作要么全成功、要么全回滚，靠 undo log。
> - **C 一致性**：事务前后都满足约束和业务规则；它是目标，需要 A/I/D + 约束 + 应用逻辑共同保证。
> - **I 隔离性**：并发事务互不干扰，靠 MVCC + 锁 + 隔离级别。
> - **D 持久性**：提交后不丢，靠 redo log + WAL + fsync。

> [!question] Q2：ACID 分别由 InnoDB 的什么机制实现？
> A → undo log；C → 约束 + 应用逻辑；I → MVCC + Read View + 行锁/间隙锁/临键锁；D → redo log + doublewrite + `fsync`。

> [!question] Q3：四种隔离级别分别解决什么问题？
> `READ UNCOMMITTED` 什么都不解决；`READ COMMITTED` 解决脏读；`REPEATABLE READ` 解决脏读和不可重复读；`SERIALIZABLE` 三者都解决。
> MySQL InnoDB 默认 `REPEATABLE READ`。

> [!question] Q4：脏读、不可重复读、幻读的区别？
> - 脏读：读到未提交的数据
> - 不可重复读：同一行两次读，值不同
> - 幻读：同一范围两次读，行数不同

> [!question] Q5：MySQL RR 如何避免幻读？
> 普通 `SELECT` 用 MVCC 快照，整个事务看到同一版本；
> `SELECT ... FOR UPDATE` / `UPDATE` / `DELETE` 用临键锁锁住记录和间隙，阻止其他事务在范围内插入。
> 两者结合，使 RR 在大多数场景下避免幻读。

> [!question] Q6：RC 和 RR 的核心区别？
> RC 每条语句创建新快照，可能出现不可重复读；基本不用间隙锁，并发更高。
> RR 在事务第一次快照读时创建快照并复用；使用临键锁，避免不可重复读和大多数幻读。

> [!question] Q7：`COMMIT` 之后数据一定不会丢吗？
> 取决于持久性配置。`innodb_flush_log_at_trx_commit=1` 且 `sync_binlog=1` 时，已提交事务在崩溃后可通过 redo/binlog 恢复；
> 设为 `0` 或 `2` 时，崩溃可能丢最近约 1 秒的数据。

> [!question] Q8：redo log 和 undo log 的区别？
> - **redo log**：记录"做了什么修改"，用于崩溃恢复，保证持久性。
> - **undo log**：记录"修改前是什么"，用于回滚和 MVCC，保证原子性。
>
> 一个向前重放，一个向后回滚。

> [!question] Q9：为什么说 C 是目标，AID 是手段？
> 一致性要求事务前后都满足规则；原子性防止半成品，隔离性防止并发互相破坏，持久性防止提交后丢失。
> 但业务规则本身还要靠约束和应用逻辑保证，所以 C 不能单靠某一个机制实现。

> [!question] Q10：长事务有什么危害？
> 长时间持锁、阻塞其他事务；阻止 undo purge，history list 膨胀；占用 undo 和 buffer pool；回滚慢；增加死锁概率。
> 解决：缩短事务、尽快提交、避免在事务中做 RPC/等待用户输入。

---

> [!quote] 一句话记忆
> **A 靠 undo 回滚，D 靠 redo 不丢，I 靠 MVCC 和锁隔离，C 靠约束和业务守规则。**
> **短事务、快提交、按业务选隔离级别和持久性档位。**

---

## 相关笔记

- [[BEGIN]] —— 开启事务
- [[COMMIT]] —— 提交事务
- [[ROLLBACK]] —— 回滚事务
- [[SAVEPOINT]] —— 事务内局部回滚
- [[数据约束概述]] —— 主键、唯一、外键、检查约束
- [[PRIMARY KEY]] · [[UNIQUE]] · [[FOREIGN KEY]] · [[CHECK]] · [[NOT NULL]]
- [[Insert]] · [[Update]] · [[Delete]] —— 事务中最常见的 DML
- [[Create Table]] · [[Alter Table]] · [[Drop Table]] · [[Truncate Table]] —— DDL 会隐式提交
- [[Nosql跟sql]] —— ACID 与 BASE 的取舍
- [[四大SQL分类讲解]] —— TCL 在 SQL 分类中的位置
