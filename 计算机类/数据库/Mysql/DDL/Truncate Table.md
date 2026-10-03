# TRUNCATE TABLE —— 清空表

> [!abstract] 一句话
> `TRUNCATE TABLE` 把表里的==**数据全部清空，但表结构原样保留**==。
> 它不是"批量 DELETE"，而是一次 DDL——==**重建一张空表**==。所以又快、又不可回滚、还会**重置自增**。

---

## 一、基本语法

```sql
TRUNCATE [TABLE] 表名;
```

- `TABLE` 关键字可以省略：`TRUNCATE user;` 与 `TRUNCATE TABLE user;` 等价
- **没有 `WHERE`**，没有 `ORDER BY`，没有 `LIMIT`——它只有"全清"这一个选项
- **一次只能清一张表**，不能写 `TRUNCATE a, b;`

```sql
TRUNCATE TABLE user;          -- 推荐写全，语义清楚
TRUNCATE user;                -- 等效简写
TRUNCATE TABLE IF EXISTS user; -- ❌ 语法错误！TRUNCATE 不支持 IF EXISTS
```

> [!failure] TRUNCATE 不支持 IF EXISTS
> 表不存在时直接报错：

```
ERROR 1146 (42S02): Table 'db.user' doesn't exist
```

> [!tip] 脚本里怎么安全执行
> 需要在脚本里安全执行就自己判断：

```sql
-- 先建表（IF NOT EXISTS 保证存在），再清空
CREATE TABLE IF NOT EXISTS user (...);
TRUNCATE TABLE user;
```

> [!tip] 备选写法
> 或把 `TRUNCATE` 写成 `DELETE FROM user;`（但会失去自增重置）。

---

## 二、它为什么这么快

> [!info] TRUNCATE 的本质是 DDL
> `TRUNCATE` 不逐行删除，而是**先 `DROP` 掉整张表，再按原结构重建一张空的**。
> - 不写行级 undo，只记一条 DDL 日志 → 日志量极小
> - 直接按**数据页**回收，不走"标记删除 + 后台清理"

```sql
-- 换句话说，TRUNCATE TABLE t 的效果约等于：
-- DROP TABLE t;  然后  CREATE TABLE t (...与原定义完全一致...);
```

**速度实测对比（100 万行）：**

| 操作                  | 大致耗时      | 说明                    |
| ------------------- | --------- | --------------------- |
| `DELETE FROM t;`    | 数十秒 ~ 数分钟 | 逐行删除 + 写 undo/redo 日志 |
| `TRUNCATE TABLE t;` | **几十毫秒**  | 重建表，与行数基本无关           |

```sql
DELETE FROM big_log;       -- 慢：要一行一行删，日志巨大，还可能撑爆 undo 表空间
TRUNCATE TABLE big_log;    -- 快：瞬间回到空表状态
```

> [!tip] 清空整张表的正确姿势
> 只要**不需要 WHERE 条件**、**不需要回滚**，清空一律用 `TRUNCATE`，不要用 `DELETE FROM t;`。
> 大表上 `DELETE FROM t;` 除了慢，还可能因为 undo 日志膨胀把磁盘写满，最后删到一半失败，留下一张"删了一半"的表——修起来很麻烦。

---

## 三、与 DELETE 的逐项对比

| 对比维度 | `DELETE FROM t` | `TRUNCATE TABLE t` |
| --- | --- | --- |
| **语句类型** | DML（数据操作语言） | **DDL（数据定义语言）** |
| **删除范围** | 可用 `WHERE` 挑行 | ==只能全表== |
| **执行方式** | 逐行删除 | 删表 + 重建 |
| **速度** | 慢，随行数线性增长 | 快，与行数几乎无关 |
| **`AUTO_INCREMENT`** | **保留原值**，继续递增 | ==重置为 1== |
| **事务 / 回滚** | ✅ 可回滚 | ❌ 隐式提交，**不可回滚** |
| **触发 `DELETE` 触发器** | ✅ 触发 | ❌ 不触发 |
| **磁盘空间** | 不释放（有碎片空洞） | **释放** |
| **外键被引用时** | 可行（无被引用行） | ❌ 直接失败 |
| **所需权限** | `DELETE` | **`DROP`** |
| **返回值** | 受影响行数 | `0 rows affected` |

> [!tip] 关键差异一：自增是否重置
> 这是最容易被忽略、也最影响业务的一条。

### 3.1 自增重置演示

```sql
CREATE TABLE demo (
    id   INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(20),
    PRIMARY KEY (id)
);

INSERT INTO demo (name) VALUES ('A'), ('B'), ('C');
SELECT * FROM demo;
```

```
+----+------+
| id | name |
+----+------+
|  1 | A    |
|  2 | B    |
|  3 | C    |
+----+------+
```

**用 DELETE 清空：**

```sql
DELETE FROM demo;
INSERT INTO demo (name) VALUES ('D');
SELECT * FROM demo;
```

```
+----+------+
| id | name |
+----+------+
|  4 | D    |     ← 自增计数器保留，从 4 继续
+----+------+
```

**用 TRUNCATE 清空：**

```sql
TRUNCATE TABLE demo;
INSERT INTO demo (name) VALUES ('D');
SELECT * FROM demo;
```

```
+----+------+
| id | name |
+----+------+
|  1 | D    |     ← 计数器被重置，重新从 1 开始
+----+------+
```

> [!warning] 重置自增的两个副作用
> 1. **老 id 会被重用**。如果日志、报表、外部系统里存过旧 id（比如 `id=1` 是"张三"），新数据拿到同样的 `id=1`，历史数据就会**张冠李戴**。
> 2. 若表有从表引用，**清空主表而没清从表**，新数据可能和从表里的旧引用撞上。
>
> 需要保留自增计数 → 用 `DELETE FROM t;`（并配合 `ALTER TABLE t AUTO_INCREMENT = 原值;`）

> [!note] TRUNCATE 不重置的情况
> 如果表上**有外键约束**（即便是它自己引用别人），MySQL 的某些版本/场景下 `TRUNCATE` 会静默退化成逐行删除，此时自增**不会**重置。
> MySQL 8.0 的行为已统一为"真清空 + 重置"。

### 3.2 事务与回滚演示

```sql
START TRANSACTION;

-- ① DELETE 可以后悔
DELETE FROM demo;
SELECT COUNT(*) FROM demo;   -- 0
ROLLBACK;
SELECT COUNT(*) FROM demo;   -- 又回来了 ✅

-- ② TRUNCATE 不能后悔
TRUNCATE TABLE demo;
SELECT COUNT(*) FROM demo;   -- 0
ROLLBACK;                    -- ⚠ 隐式提交已发生，这句是空操作
SELECT COUNT(*) FROM demo;   -- 依然是 0 ❌
```

> [!danger] TRUNCATE 会隐式提交你的事务
> 在事务中间混入 DDL（`TRUNCATE`、`ALTER`、`DROP`、`CREATE`）会**静默提交之前的所有改动**。
> 写批处理脚本时务必把 DDL 放在事务**外面**。

```sql
START TRANSACTION;
UPDATE account SET balance = balance - 100 WHERE id = 1;  -- 已改
TRUNCATE TABLE log;      -- ⚠ 这句把上面的 UPDATE 一起提交了！
ROLLBACK;                -- 无效，扣款已成事实
```

### 3.3 空间释放演示

```sql
-- 表数据 1GB，其中 90% 是废弃日志
DELETE FROM big_log WHERE created_at < '2026-01-01';
-- 数据没了，但 .ibd 文件还是 1GB —— DELETE 不归还空间

TRUNCATE TABLE big_log;
-- .ibd 文件瞬间回到几 KB，空间真的释放了
```

> [!tip] DELETE 后的空间怎么还
> `DELETE` 只在表内部留下可复用的空洞，物理文件不变。想真正释放要重建表：

```sql
ALTER TABLE big_log ENGINE = InnoDB;   -- 重建，回收空洞
-- 或 OPTIMIZE TABLE big_log;（本质也是重建）
```

> [!tip] DELETE 后的空间怎么还（续）
> 而从"删光所有数据"的角度看，`TRUNCATE` 一步到位。

---

## 四、外键限制：TRUNCATE 最常失败的地方

```sql
TRUNCATE TABLE user;
```

会报错：

```
ERROR 1701 (42000): Cannot truncate a table referenced in a
foreign key constraint (db.order, CONSTRAINT fk_order_user
FOREIGN KEY (user_id) REFERENCES db.user (id))
```

> [!failure] ERROR 1701 (42000)
> **含义**：`order` 表的外键指着 `user`。TRUNCATE 是"删表重建"，重建后 `user` 的 id 会从头开始，但 `order` 里还留着旧 `user_id` → 参照完整性被破坏，所以 MySQL **直接拒绝**。

**注意与 DELETE 的区别：**

```sql
-- 从表有数据时，两者都会因外键失败
DELETE FROM user;         -- ERROR 1451: Cannot delete or update a parent row
TRUNCATE TABLE user;      -- ERROR 1701

-- 从表已被清空时，行为就不同了
TRUNCATE TABLE `order`;   -- 先清从表（从表没有外键指向它，成功）
DELETE FROM user;         -- ✅ 成功（已无被引用的行）
TRUNCATE TABLE user;      -- ❌ 仍然失败！1701 只看"约束是否存在"，不看有没有数据
```

> [!important] 1701 的判定和"有没有数据"无关
> 只要**外键约束定义还在**，TRUNCATE 就失败。DELETE 则会逐行检查，引用行都删掉后就能成功。
> 解法：先删外键 → TRUNCATE → 再把外键加回来。
> 或者临时关掉检查（**记得改回来**）：

```sql
-- 解法：先删外键 → TRUNCATE → 再把外键加回来
ALTER TABLE `order` DROP FOREIGN KEY fk_order_user;
TRUNCATE TABLE user;                        -- 现在成功
ALTER TABLE `order` ADD CONSTRAINT fk_order_user
    FOREIGN KEY (user_id) REFERENCES `user`(id);

-- 或者临时关掉检查（记得改回来）
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE user;
SET FOREIGN_KEY_CHECKS = 1;
```

---

## 五、权限：要的是 DROP 不是 DELETE

> [!info] 意外但有道理的权限设计
> 因为 TRUNCATE 的底层是"删表 + 建表"，需要 **`DROP` 权限**（不是 `DELETE`）。
>
> **这其实是好事**：给应用账号 `DELETE` 是常事，但 `DROP` 通常不给。于是 `TRUNCATE` 天然被挡在应用层之外，防止"一行代码把生产表清空"。

```sql
-- 只有 DELETE 权限的账号
GRANT DELETE ON app_db.* TO 'app_user'@'%';

TRUNCATE TABLE user;
-- ERROR 1142 (42000): DROP command denied to user 'app_user'@'%' for table 'user'
```

---

## 六、不触发触发器

```sql
CREATE TRIGGER trg_user_del AFTER DELETE ON user
FOR EACH ROW INSERT INTO user_log (action) VALUES ('deleted');

DELETE FROM user WHERE id = 1;   -- ✅ 往 user_log 写一条
TRUNCATE TABLE user;             -- ❌ user_log 里没有任何记录
```

> [!warning] 审计日志会漏
> TRUNCATE 是 DDL，**不经过行级操作**，所以 `AFTER DELETE` 触发器完全不会触发。
> 如果业务依赖触发器做审计/同步，清空表前要想清楚这些下游会不会失联。

---

## 七、什么时候该用它

> [!success] 适合的场景
> - **清空临时表 / 中间表**，下一批任务要重新灌数据
> - **重置测试数据**，希望 id 从 1 重新开始（这个特性正好用上）
> - **清空日志表 / 埋点表**，几千万行几秒清掉
> - **删光全表比 DELETE 更快更省空间**，且不需要回滚
> - 表**没有外键被引用**，或可以先摘掉外键

> [!failure] 不该用的场景
> - 只想删**部分**数据 → 用 `DELETE ... WHERE`
> - 需要**能回滚**（在同一事务里还要做别的改动）→ 用 `DELETE`
> - 需要**保留自增计数**或**保留审计触发器** → 用 `DELETE`
> - 表被**外键引用** → 先处理外键，或改用 `DELETE`
> - 想连**表结构一起删** → 用 `DROP TABLE`

---

## 八、生产环境注意事项

> [!danger] 执行前
> - [ ] `SELECT DATABASE();` 确认连的库对不对
> - [ ] `SELECT COUNT(*) FROM 表名;` —— 知道要清掉多少行
> - [ ] 需要留档就先备份：`CREATE TABLE t_bak LIKE t; INSERT INTO t_bak SELECT * FROM t;`
> - [ ] 确认表**没有**被外键引用（`SHOW CREATE TABLE 表名\G`）
> - [ ] 确认没有视图/触发器/同步任务依赖它
> - [ ] 确认自增重置**不会**与历史 id 冲突

> [!tip] 大批量清理的替代思路
> 清空**一部分**旧数据（比如只删 90 天前）时，TRUNCATE 用不上，而 `DELETE` 大事务又很危险。常见做法是**分批删**：

```sql
-- 每批 5000 行，反复执行直到影响行数为 0
DELETE FROM big_log
 WHERE created_at < '2026-01-01'
 ORDER BY id
 LIMIT 5000;
```

> [!tip] 大批量清理的替代思路（续）
> 这样每批都是短事务，不会长时间持锁、不会撑爆 undo 日志。
> 若目标是"保留最近数据"，更优雅的方案是**建新表 → 灌入要留的数据 → RENAME 切换**（见 [[Alter Table]] 的原子改名手法）。

---

## 九、一句话总结

| 语句                 | 表结构   | 数据     | 自增     | 可回滚 | 速度  |
| ------------------ | ----- | ------ | ------ | --- | --- |
| `DELETE FROM t`    | 留     | 可挑着删   | 保留     | ✅   | 慢   |
| `TRUNCATE TABLE t` | 留     | **全清** | **重置** | ❌   | 快   |
| `DROP TABLE t`     | **删** | 删      | 消失     | ❌   | 快   |

> [!quote] 一句话记忆
> **TRUNCATE = 把表倒空但留着碗**。倒得快、倒得干净（连自增编号一起重新开始），代价是**泼出去收不回来**，而且这碗要是被别人的外键"拴着"，你还倒不了。

---

## 相关笔记

- [[Create Table]] —— 建表
- [[Alter Table]] —— 改结构（含 `ALTER TABLE ... ENGINE=InnoDB` 重建回收空间）
- [[Drop Table]] —— 连表带数据一起删
- [[表的操作]] —— `DELETE` 的用法
- [[外键约束]] —— 外键的四种级联动作
