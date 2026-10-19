# ROLLBACK —— 回滚事务

> [!abstract] 一句话
> `ROLLBACK` 用 **undo log** 撤销当前事务**尚未提交**的修改，释放锁并结束事务。
> 已经 `COMMIT` 的、DDL 隐式提交的、非事务表的、外部副作用，都回不来。

> [!info] 本篇在 TCL 中的位置
> [[BEGIN]] 开启 → DML 执行 → [[COMMIT]] 提交 / **ROLLBACK 回滚**；
> 只想撤销一部分，用 [[SAVEPOINT]]；四大保证见 [[ACID]]。

---

## 一、语法

```sql
ROLLBACK;
ROLLBACK WORK;              -- 标准 SQL 的可选写法

ROLLBACK AND CHAIN;         -- 回滚后立即开启新事务
ROLLBACK AND NO CHAIN;      -- 回滚后结束事务（默认）
ROLLBACK RELEASE;           -- 回滚后断开连接

ROLLBACK TO SAVEPOINT sp1;  -- 只回滚到保存点，不结束事务
ROLLBACK TO sp1;            -- 简写
```

| 写法 | 作用 |
| --- | --- |
| `ROLLBACK` | 回滚整个事务并结束 |
| `ROLLBACK WORK` | 同上 |
| `ROLLBACK AND CHAIN` | 回滚后立即开始新事务 |
| `ROLLBACK AND NO CHAIN` | 回滚后结束（默认） |
| `ROLLBACK RELEASE` | 回滚后断开连接 |
| `ROLLBACK TO SAVEPOINT sp` | 只回滚保存点之后的修改，事务继续 |

> [!note] 没有活动事务时，`ROLLBACK` 是空操作
> `autocommit=1` 且没有显式事务时，每条语句已经提交，`ROLLBACK` 没有可撤销的内容。
> 它不是"撤销上一条 SQL"的按钮。

> [!warning] `ROLLBACK TO SAVEPOINT` 不是 `ROLLBACK`
> 前者**不结束事务**，只撤销保存点之后的操作；后者结束整个事务。
> 详见 §五。

---

## 二、`ROLLBACK` 到底做了什么

```text
ROLLBACK
  │
  ├── 1. 读取 undo log 中的 before-image
  ├── 2. 把修改过的行 / 索引恢复原状
  ├── 3. 释放事务持有的锁
  ├── 4. 结束事务，状态标记为 ROLLED BACK
  └── 5. undo log 保留，等待 purge 线程清理（MVCC 可能还需要）
```

| 步骤 | 说明 |
| --- | --- |
| **应用 undo** | 按 undo log 把数据改回修改前 |
| **恢复索引** | 索引项也随数据一起恢复 |
| **释放锁** | 行锁、间隙锁、表锁释放，等待者可以继续 |
| **结束事务** | 事务不再持有任何资源 |
| **undo 保留** | 其他事务的旧快照可能还需要这些历史版本 |

> [!tip] 回滚不是"反向执行 SQL"
> 它不重新跑一遍 `DELETE` 去撤销 `INSERT`，而是直接应用 undo log 里的**修改前镜像**。
> 所以回滚通常比"再写一条反向 SQL"更可靠，也更理解事务语义。

---

## 三、什么能回滚，什么不能

> [!important] 先记住一句话
> **只有"事务内、事务引擎、未提交、数据库内"的修改才能回滚。**

| 操作 | 能否回滚 | 说明 |
| --- | --- | --- |
| `INSERT` / `UPDATE` / `DELETE`（InnoDB） | ✅ | 事务内未提交即可回滚 |
| `LOAD DATA` 写入 InnoDB | ✅ | 属于 DML |
| 触发器对事务表的修改 | ✅ | 作为事务的一部分 |
| `SELECT` | — | 不修改数据，无需回滚 |
| `CREATE` / `ALTER` / `DROP` | ❌ | DDL 隐式提交 |
| `TRUNCATE TABLE` | ❌ | DDL，隐式提交 |
| `RENAME TABLE` | ❌ | DDL |
| `CREATE INDEX` / `DROP INDEX` | ❌ | DDL |
| `GRANT` / `REVOKE` | ❌ | DCL，隐式提交 |
| `LOCK TABLES` | ❌ | 隐式提交 |
| `SET autocommit = 1` | ❌ | 会提交当前事务 |
| `COMMIT` 已经执行 | ❌ | 提交后无法撤销 |
| `AUTO_INCREMENT` 已分配的值 | ❌ | 自增值不回退，会留下空洞 |
| `SET @var = ...` / 会话变量 | ❌ | 变量不是事务性的 |
| MyISAM 等非事务表 | ❌ | 引擎不支持事务 |
| 发邮件、调接口、写文件 | ❌ | 外部副作用，数据库管不了 |
| `SELECT ... INTO OUTFILE` | ❌ | 文件已经写出，不会自动删除 |

### 3.1 自增 ID 不会回滚

```sql
CREATE TABLE t (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(20)
);

START TRANSACTION;
INSERT INTO t (name) VALUES ('A');   -- 假设拿到 id=1
ROLLBACK;

SELECT * FROM t;                     -- 空表
INSERT INTO t (name) VALUES ('B');   -- id 会是 2，不是 1
```

> [!warning] 自增空洞是正常现象
> 回滚、失败的插入、批量预留都会消耗自增值。
> 不要依赖"自增 ID 连续"，更不要用它做业务排序或数量统计。

### 3.2 外部副作用不可回滚

```sql
START TRANSACTION;
UPDATE account SET balance = balance - 100 WHERE id = 1;
-- 调用支付接口扣款成功
ROLLBACK;   -- 数据库回滚了，但支付接口的扣款不会自动退回
```

> [!danger] 数据库事务不等于分布式事务
> 跨系统操作要靠**补偿**（退款）、**幂等**、**本地消息表 / outbox**、**Saga / TCC**。
> 不能假设 `ROLLBACK` 能撤回所有外部动作。

### 3.3 非事务引擎

```sql
CREATE TABLE log_myisam (
    id INT,
    msg VARCHAR(100)
) ENGINE=MyISAM;

START TRANSACTION;
INSERT INTO log_myisam VALUES (1, 'hello');
ROLLBACK;   -- ❌ 无效，MyISAM 不支持事务
```

> [!warning] 建表时确认引擎
> MySQL 默认引擎是 InnoDB，但历史表、临时表、迁移脚本可能用了 MyISAM。
> 关键业务表统一 `ENGINE=InnoDB`，否则事务形同虚设。

---

## 四、回滚与锁

### 4.1 回滚会释放锁

```text
T1: START TRANSACTION;
T1: UPDATE student SET score = 100 WHERE id = 1;  -- 持有 id=1 的行锁
T2: UPDATE student SET score = 200 WHERE id = 1;  -- 等待
T1: ROLLBACK;                                      -- 释放锁
T2: 获得锁，继续执行
```

> [!tip] 回滚是"解锁"的重要手段
> 应用异常时如果不 `ROLLBACK`，事务可能一直挂着，锁一直不释放，最终拖垮其他请求。

### 4.2 死锁：`ERROR 1213`

```sql
-- T1 锁 A 等 B，T2 锁 B 等 A
-- InnoDB 检测到死锁后，选择一个"牺牲者"回滚
-- ERROR 1213 (40001): Deadlock found when trying to get lock;
--                     try restarting transaction
```

| 要点 | 说明 |
| --- | --- |
| 谁被回滚 | InnoDB 选择代价较小的事务作为牺牲者 |
| 回滚范围 | **整个事务**，不是单条语句 |
| 应用处理 | 捕获 1213，**退避后重试整个事务** |
| 预防 | 固定加锁顺序、缩短事务、减少范围锁、合适索引 |

> [!warning] 不要只重试最后一条 SQL
> 死锁牺牲者的事务已经整体回滚，之前的操作都没了。
> 必须从头重放整个事务逻辑，并保证幂等。

### 4.3 锁等待超时：`ERROR 1205`

```sql
-- 等待超过 innodb_lock_wait_timeout（默认 50 秒）
-- ERROR 1205 (HY000): Lock wait timeout exceeded;
--                     try restarting transaction
```

> [!important] 锁等待超时的默认行为是"只回滚当前语句"
> `innodb_rollback_on_timeout` 默认 `OFF`：
> - 只回滚当前语句
> - **事务仍然存在**，之前的修改还在，锁也还持有
>
> 设为 `ON` 时，整个事务回滚。
> 所以捕获 1205 后，应用通常应该主动 `ROLLBACK`，避免事务悬空。

```sql
SHOW VARIABLES LIKE 'innodb_lock_wait_timeout';
SHOW VARIABLES LIKE 'innodb_rollback_on_timeout';
```

### 4.4 唯一键冲突：语句回滚，事务继续

```sql
START TRANSACTION;
INSERT INTO student (id, name) VALUES (1, '张三');
INSERT INTO student (id, name) VALUES (1, '李四');
-- ERROR 1062: Duplicate entry '1' for key 'PRIMARY'
-- 默认只回滚第二条语句，事务仍然可用
COMMIT;   -- 第一条仍然会提交
```

> [!note] 语句级回滚 vs 事务级回滚
> - **语句级**：唯一键冲突、部分数据错误 → 当前语句回滚，事务继续
> - **事务级**：死锁牺牲者、显式 `ROLLBACK`、`innodb_rollback_on_timeout=ON` → 整个事务回滚
>
> 应用要分清错误类型，别把"语句失败"当成"整个事务已经回滚"。

---

## 五、`ROLLBACK` vs `ROLLBACK TO SAVEPOINT`

| 对比项 | `ROLLBACK` | `ROLLBACK TO SAVEPOINT sp` |
| --- | --- | --- |
| 是否结束事务 | ✅ 结束 | ❌ 不结束 |
| 撤销范围 | 整个事务 | 保存点之后的修改 |
| 保存点之前的修改 | 全部撤销 | **保留** |
| 保存点之后的锁 | 全部释放 | 释放 |
| 保存点之前的锁 | 释放 | **保留** |
| 保存点状态 | 全部清除 | 命名保存点保留，之后的保存点被删除 |
| 之后能否继续执行 | 需要重新 `START TRANSACTION` | ✅ 可以继续 |
| 典型用途 | 整体失败、异常退出 | 局部失败、可选步骤 |

```sql
START TRANSACTION;

INSERT INTO student (name) VALUES ('A');   -- ①
SAVEPOINT sp1;

UPDATE student SET score = 100;            -- ②
DELETE FROM student WHERE name = 'A';      -- ③

ROLLBACK TO SAVEPOINT sp1;                 -- 撤销 ②③，① 保留
-- 此时 sp1 仍然存在

COMMIT;                                    -- ① 被提交
```

> [!important] `ROLLBACK TO SAVEPOINT` 之后，事务还在
> 别忘了最终 `COMMIT` 或 `ROLLBACK`，否则事务一直开着，锁不释放。
> 详见 [[SAVEPOINT]]。

---

## 六、回滚与 MVCC / undo

### 6.1 undo log 不只为回滚服务

| 用途 | 说明 |
| --- | --- |
| **回滚** | `ROLLBACK` 时恢复修改前数据 |
| **MVCC** | 普通读需要历史版本，undo log 提供旧值 |
| **崩溃恢复** | 未提交事务在重启后回滚 |

> [!note] 回滚后 undo log 不会立刻删除
> 只要还有别的事务的 Read View 需要这个历史版本，purge 线程就不能清理。
> 所以"长事务 + 频繁更新"会让 undo 越积越多，history list 越来越长。

### 6.2 长事务会阻止 purge

```sql
-- 查看 history list length（TRANSACTIONS 段）
SHOW ENGINE INNODB STATUS\G

-- 查看当前长事务
SELECT trx_id, trx_state, trx_started,
       TIMESTAMPDIFF(SECOND, trx_started, NOW()) AS seconds,
       trx_query
  FROM information_schema.INNODB_TRX
 ORDER BY trx_started;
```

> [!warning] 大事务回滚可能很慢
> `ROLLBACK` 需要逐条应用 undo，事务越大、修改越多，回滚越久。
> 回滚期间仍然占用资源，可能继续阻塞其他事务。
> 所以"先开个大事务，出错再回滚"不是安全策略，**短事务才是**。

### 6.3 连接断开时的回滚

```text
客户端异常断开
  → MySQL 检测到连接关闭
  → 服务端自动回滚该连接上未提交的事务
  → 释放锁
```

> [!note] 客户端"以为回滚了"不等于服务端已经回滚完
> 大事务的回滚可能在后台持续一段时间。
> 监控 `INNODB_TRX` 和锁等待，确认事务真正结束。

---

## 七、回滚失败的场景

> [!failure] 场景一：DDL 已经隐式提交
> ```sql
> START TRANSACTION;
> INSERT INTO student (name) VALUES ('张三');
> CREATE TABLE t_tmp (id INT);   -- 隐式提交
> ROLLBACK;                      -- '张三' 撤不回
> ```

> [!failure] 场景二：已经 `COMMIT`
> ```sql
> START TRANSACTION;
> UPDATE ...;
> COMMIT;      -- 已经生效
> ROLLBACK;    -- 空操作，什么也撤不回
> ```

> [!failure] 场景三：非事务表
> MyISAM、部分临时表、某些特殊引擎不支持事务，`ROLLBACK` 无效。

> [!failure] 场景四：外部副作用
> 已发邮件、已调支付、已写文件、已发 MQ 消息，数据库回滚不会撤回。

> [!failure] 场景五：自增 ID
> 回滚不会把 `AUTO_INCREMENT` 退回去，ID 空洞会保留。

> [!failure] 场景六：会话变量 / 用户变量
> `SET @x = 1;`、`SET SESSION ...` 不属于事务，`ROLLBACK` 不会恢复。

> [!failure] 场景七：保存点已被清除
> `COMMIT` / `ROLLBACK` / DDL 隐式提交都会清除保存点。
> 之后再 `ROLLBACK TO SAVEPOINT sp` 会报 `ERROR 1305: SAVEPOINT sp does not exist`。

> [!failure] 场景八：连接已断开 / 事务已被死锁回滚
> 事务已经结束，再 `ROLLBACK` 是空操作。
> 应用应根据错误码判断，而不是假设"我调了 ROLLBACK 就一定回滚了"。

---

## 八、最佳实践

> [!success] 回滚相关的八条经验
> 1. **异常分支必须 `ROLLBACK`**：不要让事务悬空
> 2. **短事务**：事务越大，回滚越慢、锁越久
> 3. **死锁重试**：捕获 `ERROR 1213`，退避后重试**整个事务**
> 4. **锁超时主动回滚**：捕获 `ERROR 1205` 后，通常应主动 `ROLLBACK`
> 5. **局部回滚用 `SAVEPOINT`**：不要让一个可选步骤失败拖垮整个事务
> 6. **关键路径用 InnoDB**：确认表引擎支持事务
> 7. **外部副作用用补偿**：不要依赖数据库回滚
> 8. **自增 ID 不要依赖连续性**：回滚会留下空洞

```sql
-- 推荐的事务模板（应用层伪代码）
START TRANSACTION;
TRY {
    -- 业务 DML
    COMMIT;
} CATCH (e) {
    ROLLBACK;
    IF (e.code == 1213) {
        // 死锁：退避后重试整个事务
        RETRY_WITH_BACKOFF();
    } ELSE IF (e.code == 1205) {
        // 锁等待超时：回滚后重试或报错
        THROW;
    } ELSE {
        THROW;
    }
}
```

> [!tip] `ROLLBACK AND CHAIN`
> 回滚后立即开启新事务，适合循环批处理：一项失败、回滚、马上处理下一项。
> 但要注意：链式事务仍然是新事务，不会保留上一项的保存点。

---

## 九、常见报错

> [!failure] ERROR 1213：Deadlock found when trying to get lock
> 死锁牺牲者，整个事务已被回滚。捕获后重试整个事务。

> [!failure] ERROR 1205：Lock wait timeout exceeded
> 等锁超时。默认只回滚当前语句；事务可能仍然存在，建议主动 `ROLLBACK`。

> [!failure] ERROR 1305：SAVEPOINT ... does not exist
> 保存点不存在。可能已被 `RELEASE`、`COMMIT`、`ROLLBACK` 或 DDL 隐式提交清除。

> [!failure] ERROR 1422：Explicit or implicit commit is not allowed in stored function or trigger
> 在存储函数/触发器里执行了 `ROLLBACK` 或触发隐式提交的语句。事务控制移到存储过程/应用层。

> [!failure] ERROR 1792：Cannot execute statement in a READ ONLY transaction
> 只读事务里执行了写操作。改用读写事务。

> [!failure] ERROR 1062：Duplicate entry
> 唯一键冲突。默认只回滚当前语句，事务可继续；根据业务决定是跳过还是整体回滚。

---

## 十、常见面试问答

> [!question] Q1：`ROLLBACK` 做了什么？
> 用 undo log 把未提交的修改恢复原状，释放事务持有的锁，结束事务。
> 已提交的、DDL 隐式提交的、非事务表的、外部副作用都无法回滚。

> [!question] Q2：哪些操作不能回滚？
> DDL（`CREATE` / `ALTER` / `DROP` / `TRUNCATE` / `RENAME` / 索引变更）、DCL（`GRANT` / `REVOKE`）、`LOCK TABLES`、`SET autocommit=1`、已 `COMMIT` 的事务、自增 ID、会话变量、非事务表、外部副作用。

> [!question] Q3：为什么 DDL 不能回滚？
> MySQL 对 DDL 采用隐式提交：执行前提交当前事务，执行后立即提交自身。
> 即使用户在事务中写 `ROLLBACK`，也撤销不了已提交的 DDL。
> MySQL 8.0 的原子 DDL 只保证单条 DDL 的原子性，不等于事务可回滚。

> [!question] Q4：自增 ID 为什么回滚不了？
> InnoDB 的自增值在插入时已经分配并持久化到内存/系统表，不参与事务的 undo。
> 回滚后行没了，但自增值不会退回去，因此会留下空洞。

> [!question] Q5：死锁和锁等待超时有什么区别？
> - **死锁（1213）**：循环等待，InnoDB 主动选择牺牲者，**整个事务回滚**，应用应重试整个事务。
> - **锁等待超时（1205）**：等锁超过 `innodb_lock_wait_timeout`，默认只回滚当前语句，事务可能仍在。

> [!question] Q6：`ROLLBACK` 和 `ROLLBACK TO SAVEPOINT` 的区别？
> `ROLLBACK` 撤销整个事务并结束；`ROLLBACK TO SAVEPOINT` 只撤销保存点之后的修改，不结束事务，之前的修改和锁保留。

> [!question] Q7：回滚会释放锁吗？
> 会。`ROLLBACK` 释放事务持有的所有锁；`ROLLBACK TO SAVEPOINT` 释放保存点之后获得的锁，保存点之前的锁保留。

> [!question] Q8：为什么大事务回滚很慢？
> 回滚要逐条应用 undo log，事务越大、修改越多，回滚越久；期间还占用资源、可能继续阻塞其他事务。
> 所以应避免大事务，分批提交。

> [!question] Q9：连接断开后事务会怎样？
> MySQL 检测到连接关闭后，会自动回滚该连接上未提交的事务并释放锁。
> 但大事务的回滚可能在后台持续一段时间，需要监控确认。

> [!question] Q10：`ROLLBACK` 能撤销外部接口调用吗？
> 不能。数据库事务只覆盖数据库内的操作。外部副作用要靠补偿、幂等、Saga/TCC、本地消息表等方案处理。

---

> [!quote] 一句话记忆
> **`ROLLBACK` 靠 undo 撤销未提交的数据库修改；DDL、已提交、自增、非事务表、外部副作用都回不来。**
> **死锁回滚整个事务要重试，锁超时默认只回滚语句；局部回滚用 `ROLLBACK TO SAVEPOINT`。**

---

## 相关笔记

- [[ACID]] —— 原子性与 undo log
- [[BEGIN]] —— 开启事务
- [[COMMIT]] —— 提交事务
- [[SAVEPOINT]] —— 事务内局部回滚
- [[Insert]] · [[Update]] · [[Delete]] —— 可回滚的 DML
- [[Create Table]] · [[Alter Table]] · [[Drop Table]] · [[Truncate Table]] —— 不可回滚的 DDL
- [[数据约束概述]] —— 约束与事务一致性
- [[四大SQL分类讲解]] —— TCL 在 SQL 分类中的位置
