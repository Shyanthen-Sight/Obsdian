# SAVEPOINT —— 保存点

> [!abstract] 一句话
> `SAVEPOINT` 在事务内部打一个"**存档点**"；
> `ROLLBACK TO SAVEPOINT` 只撤销它之后的修改，**事务继续**，之前的修改和锁仍然保留。

> [!info] 本篇在 TCL 中的位置
> [[BEGIN]] 开启 → DML → **SAVEPOINT 打点** → `ROLLBACK TO` 局部回滚 → [[COMMIT]] / [[ROLLBACK]] 收尾；
> 四大保证见 [[ACID]]。

---

## 一、语法

```sql
-- 设置保存点
SAVEPOINT sp1;

-- 回滚到保存点（不结束事务）
ROLLBACK TO SAVEPOINT sp1;
ROLLBACK TO sp1;                 -- 简写

-- 删除保存点（不提交、不回滚）
RELEASE SAVEPOINT sp1;
```

| 语句 | 作用 | 是否结束事务 |
| --- | --- | --- |
| `SAVEPOINT sp` | 在当前事务中设置/覆盖保存点 | ❌ |
| `ROLLBACK TO SAVEPOINT sp` | 撤销 `sp` 之后的修改，事务继续 | ❌ |
| `RELEASE SAVEPOINT sp` | 删除保存点，不提交也不回滚 | ❌ |

> [!note] 保存点只在当前事务内有效
> - 其他会话看不到你的保存点
> - `COMMIT` / `ROLLBACK` 后保存点全部清除
> - DDL 隐式提交后保存点也会被清除
> - 连接断开后保存点自然消失

> [!warning] `autocommit=1` 时保存点没有实际意义
> 每条语句执行完就自动提交，事务边界只有一条语句，保存点没有可回滚的中间状态。
> 保存点应在显式事务（`START TRANSACTION` 或 `autocommit=0`）中使用。

### 1.1 同名保存点会被覆盖

```sql
SAVEPOINT sp1;
-- ... 一些操作 ...
SAVEPOINT sp1;   -- 旧 sp1 被删除，新 sp1 取代它
```

> [!tip] 保存点名建议带业务含义
> `sp_item_1001`、`sp_before_discount` 比 `sp1`、`sp2` 好排查。
> 但也不要在循环里创建过多保存点，事务维护成本会上升。

### 1.2 回滚到不存在的保存点

```sql
ROLLBACK TO SAVEPOINT not_exists;
-- ERROR 1305 (42000): SAVEPOINT not_exists does not exist
```

> [!note] `RELEASE SAVEPOINT` 对不存在的保存点通常不报错
> 它只是"确保这个保存点不在了"。
> 但 `ROLLBACK TO SAVEPOINT` 必须指向存在的保存点，否则报 1305。

---

## 二、执行流程

```sql
START TRANSACTION;

INSERT INTO student (name, score) VALUES ('A', 60);   -- ①
SAVEPOINT sp1;

UPDATE student SET score = 90 WHERE name = 'A';       -- ②
SAVEPOINT sp2;

DELETE FROM student WHERE name = 'A';                 -- ③

ROLLBACK TO SAVEPOINT sp1;                            -- 撤销 ②③，① 保留
-- sp2 被删除，sp1 仍然存在

COMMIT;                                               -- 只提交 ①
```

执行后的状态：

| 步骤 | 操作 | 数据状态 |
| --- | --- | --- |
| ① | `INSERT A` | A 存在，score=60 |
| — | `SAVEPOINT sp1` | 存档点 1 |
| ② | `UPDATE A score=90` | A 存在，score=90 |
| — | `SAVEPOINT sp2` | 存档点 2 |
| ③ | `DELETE A` | A 不存在 |
| — | `ROLLBACK TO sp1` | **回到存档点 1**：A 存在，score=60；sp2 被删除 |
| — | `COMMIT` | A 以 score=60 提交 |

> [!important] `ROLLBACK TO SAVEPOINT` 的三个关键行为
> 1. **不结束事务**：之后还可以继续执行 SQL
> 2. **保留命名保存点**：`sp1` 仍然存在，可以再次回滚到它
> 3. **删除它之后的保存点**：`sp2` 被清除

> [!warning] 别忘了最终提交
> `ROLLBACK TO SAVEPOINT` 只是局部回滚，事务仍然开着。
> 如果之后不 `COMMIT` 也不 `ROLLBACK`，事务会一直持有锁，直到连接关闭或被 `KILL`。

---

## 三、保存点与锁

> [!abstract] 回滚到保存点，释放的是"保存点之后"的锁
> 保存点之前的锁仍然保留，因为那部分修改还在事务里。

```text
T1: START TRANSACTION;
T1: UPDATE student SET score = 100 WHERE id = 1;   -- 锁 id=1
T1: SAVEPOINT sp1;
T1: UPDATE student SET score = 200 WHERE id = 2;   -- 锁 id=2
T1: ROLLBACK TO SAVEPOINT sp1;
    -- 释放 id=2 的锁；id=1 的锁仍然持有
T1: COMMIT;
    -- 释放 id=1 的锁
```

| 回滚方式 | 保存点之前的锁 | 保存点之后的锁 |
| --- | --- | --- |
| `ROLLBACK` | 释放 | 释放 |
| `ROLLBACK TO SAVEPOINT` | **保留** | 释放 |
| `COMMIT` | 释放 | 释放 |

> [!note] 保存点不会降低隔离性
> 其他事务仍然看不到你未提交的修改；
> 保存点只是你自己的"撤销标记"，不改变事务的可见性和锁语义。

---

## 四、保存点 vs 嵌套事务

> [!important] MySQL 没有真正的嵌套事务
> `START TRANSACTION` 在事务中执行时，会**先提交当前事务**，再开新事务——这不是嵌套。
> `SAVEPOINT` 是模拟"部分回滚"的手段，但它不是独立事务。

| 对比项 | 真正的嵌套事务 | MySQL 保存点 |
| --- | --- | --- |
| 独立提交/回滚 | 内层可以独立提交 | ❌ 全部随外层提交/回滚 |
| 内层回滚不影响外层 | ✅ | ✅（保存点之后的部分） |
| 内层提交后外层回滚 | 内层保留 | ❌ 外层回滚会全部撤销 |
| 隔离性 | 独立事务 | 同一事务 |
| MySQL 支持 | ❌ | ✅ |

```sql
-- ❌ 这不是嵌套事务
START TRANSACTION;
INSERT ...
START TRANSACTION;   -- 隐式提交前面的 INSERT，再开新事务
INSERT ...
ROLLBACK;            -- 只回滚第二个事务
```

> [!tip] 保存点能模拟"局部事务"，但不能模拟"独立提交"
> 如果业务需要"内层成功就永久保留，外层失败也不影响内层"，保存点做不到。
> 那需要拆成多个独立事务，或使用补偿/ Saga 方案。

---

## 五、保存点 vs COMMIT / ROLLBACK

| 对比项 | `SAVEPOINT` | `ROLLBACK TO SAVEPOINT` | `ROLLBACK` | `COMMIT` |
| --- | --- | --- | --- | --- |
| 结束事务 | ❌ | ❌ | ✅ | ✅ |
| 撤销修改 | — | 撤销保存点之后 | 撤销全部 | 不撤销 |
| 释放锁 | — | 释放保存点之后 | 全部释放 | 全部释放 |
| 保存点状态 | 新增/覆盖 | 命名保存点保留 | 全部清除 | 全部清除 |
| 能否继续执行 | ✅ | ✅ | ❌（需重新开启） | ❌（需重新开启） |

---

## 六、使用场景

### 6.1 复杂批量操作：部分失败不拖垮整批

```sql
START TRANSACTION;

SAVEPOINT batch_start;

-- 第 1 条
SAVEPOINT item_1;
INSERT INTO student (name, score) VALUES ('A', 60);

-- 第 2 条（假设失败）
SAVEPOINT item_2;
INSERT INTO student (name, score) VALUES ('B', 70);

-- 如果第 2 条失败：
ROLLBACK TO SAVEPOINT item_2;
RELEASE SAVEPOINT item_2;

-- 继续第 3 条
SAVEPOINT item_3;
INSERT INTO student (name, score) VALUES ('C', 80);

COMMIT;
-- 结果：A、C 成功，B 被局部回滚
```

> [!tip] 批量导入的常见模式
> 每一条/每一小批打一个保存点，失败就回滚到该点并记录错误，然后继续下一条。
> 这样不会因为一条脏数据导致整批 10 万行全部回滚。

### 6.2 存储过程错误处理

```sql
CREATE PROCEDURE import_student()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        -- 发生错误时回滚到当前条目的保存点
        ROLLBACK TO SAVEPOINT sp_item;
    END;

    START TRANSACTION;

    -- 第 1 条
    SAVEPOINT sp_item;
    INSERT INTO student (name) VALUES ('A');

    -- 第 2 条
    SAVEPOINT sp_item;
    INSERT INTO student (name) VALUES ('B');

    COMMIT;
END;
```

> [!warning] 存储过程里的 `COMMIT` 与异常
> `COMMIT` / `ROLLBACK` 可以出现在存储过程里，但不能出现在**存储函数/触发器**里（`ERROR 1422`）。
> 另外，`ROLLBACK TO SAVEPOINT` 之后要继续处理，最终仍要决定 `COMMIT` 还是 `ROLLBACK`。

### 6.3 应用层"可选步骤"

```text
START TRANSACTION;
  必做步骤 A;
  SAVEPOINT sp_optional;
  可选步骤 B;   -- 例如发积分、写审计日志
  IF B 失败 THEN
      ROLLBACK TO SAVEPOINT sp_optional;   -- 只撤销 B
  END IF;
  必做步骤 C;
COMMIT;
```

> [!note] 可选步骤要看业务语义
> 如果 B 失败必须让整个事务失败，就别用保存点，直接 `ROLLBACK`。
> 保存点适合"B 失败可以接受，但不能影响 A 和 C"的场景。

### 6.4 数据修复 / 迁移

```sql
START TRANSACTION;

SAVEPOINT before_fix;
UPDATE account SET balance = balance + 100 WHERE id = 1;

-- 校验
SELECT balance FROM account WHERE id = 1;

-- 如果校验不通过
ROLLBACK TO SAVEPOINT before_fix;
-- 如果通过
COMMIT;
```

> [!tip] 保存点 + 校验是安全的修复模式
> 先改、再查、确认无误再提交；发现问题就回到保存点，不用重跑整个事务。

### 6.5 测试与调试

在测试环境里，可以用保存点逐步执行、逐步回滚，观察每一步的数据变化，而不必反复重建数据。

---

## 七、常见坑

> [!failure] 坑一：回滚到保存点后忘记提交
> `ROLLBACK TO SAVEPOINT` 不结束事务。之后不 `COMMIT` / `ROLLBACK`，事务和锁会一直挂着。
> 这是生产环境最常见的"保存点泄漏"。

> [!failure] 坑二：保存点被 DDL 清除
> ```sql
> START TRANSACTION;
> SAVEPOINT sp1;
> CREATE TABLE t_tmp (id INT);   -- 隐式提交，sp1 被清除
> ROLLBACK TO SAVEPOINT sp1;     -- ERROR 1305
> ```

> [!failure] 坑三：`RELEASE SAVEPOINT` 不是提交
> ```sql
> SAVEPOINT sp1;
> UPDATE ...;
> RELEASE SAVEPOINT sp1;   -- 只是删除保存点，修改仍在事务里
> -- 别忘了 COMMIT / ROLLBACK
> ```

> [!failure] 坑四：自增 ID 不会因保存点回滚而回退
> 回滚到保存点后，之前分配的 `AUTO_INCREMENT` 值不会退回，ID 空洞仍然存在。

> [!failure] 坑五：非事务表不受保存点保护
> 对 MyISAM 等非事务表的修改，`ROLLBACK TO SAVEPOINT` 也无效。
> 保存点只对事务引擎有效。

> [!failure] 坑六：外部副作用不会被局部回滚
> 保存点之后调用的支付、短信、MQ 消息，不会因为 `ROLLBACK TO SAVEPOINT` 而撤回。
> 需要补偿或幂等设计。

> [!failure] 坑七：同名保存点覆盖
> ```sql
> SAVEPOINT sp1;
> -- ...
> SAVEPOINT sp1;   -- 旧 sp1 被覆盖，回滚只能回到新的位置
> ```

> [!failure] 坑八：在 autocommit=1 下使用
> 每条语句自动提交，保存点没有中间状态可回滚，基本没有意义。

> [!failure] 坑九：连接断开
> 保存点随事务一起消失；连接断开后服务端自动回滚未提交事务，保存点自然不存在。

---

## 八、最佳实践

> [!success] 保存点使用八条经验
> 1. **在显式事务中使用**：`START TRANSACTION` + `SAVEPOINT`
> 2. **给保存点起有业务含义的名字**：`sp_item_1001`、`sp_before_audit`
> 3. **每个保存点都要有明确的回滚分支**：不要只打点不处理
> 4. **回滚后记得最终 `COMMIT` / `ROLLBACK`**
> 5. **不要在事务里混 DDL**：会隐式提交并清除保存点
> 6. **批量处理每条/每批打点**：避免一条脏数据回滚整批
> 7. **保存点不是嵌套事务**：需要独立提交时拆分事务
> 8. **外部副作用用补偿**：不要依赖保存点撤回

```sql
-- 推荐模板
START TRANSACTION;

SAVEPOINT sp_main;
-- 必做操作
-- ...

SAVEPOINT sp_optional;
-- 可选操作
-- 失败时：ROLLBACK TO SAVEPOINT sp_optional;

COMMIT;   -- 或 ROLLBACK;
```

> [!tip] 保存点数量不要太多
> 每个保存点都会占用事务状态和内存。循环里给每行打点可以，但不要给每个字段都打点。
> 大批量处理时，可以每 100~1000 行打一个保存点，而不是每行一个。

---

## 九、常见报错

> [!failure] ERROR 1305：SAVEPOINT ... does not exist
> `ROLLBACK TO SAVEPOINT` 指向不存在的保存点。
> 检查是否被 `RELEASE`、`COMMIT`、`ROLLBACK` 或 DDL 隐式提交清除。

> [!failure] ERROR 1422：Explicit or implicit commit is not allowed in stored function or trigger
> 在存储函数/触发器里执行了事务控制语句。把保存点和事务控制移到存储过程/应用层。

> [!failure] ERROR 1205：Lock wait timeout exceeded
> 保存点不会避免锁等待。等待超时后默认只回滚当前语句，事务可能仍在；建议主动 `ROLLBACK`。

> [!failure] ERROR 1213：Deadlock found when trying to get lock
> 死锁会让整个事务回滚，保存点也一起失效。捕获后重试整个事务。

> [!failure] ERROR 1062：Duplicate entry
> 唯一键冲突通常只回滚当前语句。可以在插入前打保存点，失败后 `ROLLBACK TO SAVEPOINT` 再继续。

---

## 十、常见面试问答

> [!question] Q1：什么是保存点？
> 事务内部的一个"存档点"。`SAVEPOINT sp` 记录当前位置；`ROLLBACK TO SAVEPOINT sp` 只撤销该点之后的修改，事务继续。

> [!question] Q2：`ROLLBACK` 和 `ROLLBACK TO SAVEPOINT` 有什么区别？
> `ROLLBACK` 撤销整个事务并结束；`ROLLBACK TO SAVEPOINT` 只撤销保存点之后的修改，不结束事务，之前的修改和锁保留。

> [!question] Q3：回滚到保存点会释放锁吗？
> 会释放保存点**之后**获得的锁；保存点之前获得的锁仍然保留，因为那部分修改还在事务里。

> [!question] Q4：保存点会结束事务吗？
> 不会。`SAVEPOINT` 和 `ROLLBACK TO SAVEPOINT` 都不结束事务；只有 `COMMIT` / `ROLLBACK` 才结束。

> [!question] Q5：MySQL 支持嵌套事务吗？
> 不支持真正的嵌套事务。`START TRANSACTION` 会先提交当前事务再开新事务；`SAVEPOINT` 只能模拟"局部回滚"，不能模拟"内层独立提交"。

> [!question] Q6：保存点什么时候会被清除？
> `COMMIT`、`ROLLBACK`、DDL 隐式提交、DCL 隐式提交、连接断开都会清除保存点。
> `ROLLBACK TO SAVEPOINT` 只清除它之后的保存点，命名保存点本身保留。

> [!question] Q7：`RELEASE SAVEPOINT` 是提交吗？
> 不是。它只是删除保存点，既不提交也不回滚；修改仍在当前事务里，需要最终 `COMMIT` / `ROLLBACK`。

> [!question] Q8：保存点能回滚自增 ID 吗？
> 不能。`AUTO_INCREMENT` 的分配不参与事务回滚，保存点回滚后 ID 空洞仍然存在。

> [!question] Q9：保存点能撤回外部接口调用吗？
> 不能。保存点只作用于数据库事务内的修改；外部副作用需要补偿、幂等或 Saga/TCC 等方案。

> [!question] Q10：什么场景适合用保存点？
> 复杂批量操作中"部分失败不拖垮整批"、存储过程错误处理、应用层可选步骤、数据修复时"先改再校验、不通过就回退"。
> 核心判断：**失败只需要撤销局部，且外层事务可以继续。**

---

> [!quote] 一句话记忆
> **`SAVEPOINT` 打存档，`ROLLBACK TO` 只回这一段，事务不结束、之前的锁和修改都还在；**
> **它不是嵌套事务，别忘了最后 `COMMIT` / `ROLLBACK`。**

---

## 相关笔记

- [[ACID]] —— 原子性与隔离性
- [[BEGIN]] —— 开启事务
- [[COMMIT]] —— 提交事务
- [[ROLLBACK]] —— 回滚整个事务
- [[Insert]] · [[Update]] · [[Delete]] —— 保存点最常保护的操作
- [[Create Table]] · [[Alter Table]] · [[Drop Table]] · [[Truncate Table]] —— DDL 会清除保存点
- [[数据约束概述]] —— 约束与事务一致性
- [[四大SQL分类讲解]] —— TCL 在 SQL 分类中的位置
