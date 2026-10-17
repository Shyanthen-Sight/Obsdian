# FOREIGN KEY —— 外键约束

> [!abstract] 一句话
> `FOREIGN KEY` 规定**本表的某字段取值必须来自另一张表的主键（或唯一键）**，用来保证多表之间的**参照完整性**——从表不能"凭空捏造"一个主表里不存在的关联。

---

## 一、先理解"主表"与"从表"

```
class（主表 / 被参照表）          student（从表 / 参照表）
+----+----------+                +----+-------+----------+
| id | name     |                | id | name  | class_id |
+----+----------+                +----+-------+----------+
|  1 | 一班      | <-------------|  1 | 张三  |    1     |
|  2 | 二班      | <-------------|  2 | 李四  |    2     |
+----+----------+                +----+-------+----------+
                                    外键 class_id 引用 class.id
```

- **主表（父表）**：被引用的那张表，`class`。
- **从表（子表）**：持有外键的那张表，`student`。
- **外键列**：`student.class_id`，它的值必须能在 `class.id` 中找到。

---

## 二、语法

### 2.1 建表时添加

```sql
CREATE TABLE student (
    id       BIGINT AUTO_INCREMENT,
    name     VARCHAR(50) NOT NULL,
    class_id INT,
    PRIMARY KEY (id),
    CONSTRAINT fk_student_class                        -- 约束名（建议写）
        FOREIGN KEY (class_id) REFERENCES class (id)   -- 外键列 → 主表(主键列)
        ON DELETE SET NULL                             -- 主表删除时的动作
        ON UPDATE CASCADE                              -- 主表更新时的动作
);
```

各部分含义：

| 关键字                       | 作用                |
| ------------------------- | ----------------- |
| `CONSTRAINT 外键名`          | 给约束起名，可省略，但强烈建议写  |
| `FOREIGN KEY (外键字段)`      | 指定从表里哪一列是外键       |
| `REFERENCES 主表名 (主键字段)`    | 指定它引用哪张表的哪一列      |
| `ON DELETE / ON UPDATE`   | 主表记录被删/改时，从表怎么办   |

### 2.2 建表后添加

```sql
ALTER TABLE student
    ADD CONSTRAINT fk_student_class
    FOREIGN KEY (class_id) REFERENCES class (id)
    ON DELETE SET NULL ON UPDATE CASCADE;
```

### 2.3 删除外键

```sql
-- 外键用 DROP FOREIGN KEY，删的是约束
ALTER TABLE student DROP FOREIGN KEY fk_student_class;

-- 如果建表时没删掉自动生成的索引，可能还要顺手删索引
ALTER TABLE student DROP INDEX fk_student_class;
```

> [!danger] 四类约束的删除语法各不相同
> | 约束        | 删除语法                        |
> | --------- | --------------------------- |
> | 主键        | `DROP PRIMARY KEY`          |
> | 唯一        | `DROP INDEX 约束名`            |
> | 外键        | `DROP FOREIGN KEY 约束名`      |
> | 检查        | `DROP CHECK 名` / `DROP CONSTRAINT 名` |
> 别混用，混了就是语法错。

---

## 三、前置条件（报错 1215 的根源）

外键是最容易报错的约束，`ERROR 1215: Cannot add foreign key constraint` 是它的"万金油"错误。常见原因：

> [!failure] 外键失败排查清单
> 1. **存储引擎不是 InnoDB**——MyISAM 不支持外键。
> 2. **类型不一致**：`BIGINT` 对 `INT`、`UNSIGNED` 对 `SIGNED`、`utf8mb4` 对 `utf8` 都会失败。==类型、符号、字符集必须完全一致==。
> 3. **被引用的列不是主键或唯一键**——它必须是有索引的唯一列。
> 4. **主表还没建**：==有外键的表，主表必须先建==，否则报 `ERROR 1824: Failed to open the referenced table`。
> 5. 从表外键列已有脏数据，在主表里找不到对应行。

```sql
-- 建表顺序：先主表，后从表
CREATE TABLE class (...);     -- ① 先建
CREATE TABLE student (...);   -- ② 后建，引用 class
```

---

## 四、四个参照动作（核心考点）

当主表记录被 `DELETE` 或 `UPDATE` 时，从表该怎么办：

| 动作           | 含义                      | `ON DELETE` 效果 | `ON UPDATE` 效果 |
| ------------ | ----------------------- | -------------- | -------------- |
| `RESTRICT`（默认） | **拒绝**主表的删除/更新          | 有从表引用 → 报错     | 有从表引用 → 报错     |
| `NO ACTION`  | 同 `RESTRICT`（MySQL 中无差别） | 同 RESTRICT     | 同 RESTRICT     |
| `CASCADE`    | **级联**：从表跟着删 / 跟着改       | 从表对应行**一起删除**  | 从表外键值**一起改**   |
| `SET NULL`   | 从表外键字段**置为 NULL**       | 从表外键**变 NULL** | 从表外键**变 NULL** |

```sql
-- 最常用的组合：主表删 → 从表关联置空；主表改 → 从表跟着改
ON DELETE SET NULL
ON UPDATE CASCADE
```

> [!warning] `SET NULL` 要求外键列本身可空
> 若外键列是 `NOT NULL`，用 `ON DELETE SET NULL` 会失败——主表一删，从表就要写 NULL，而列不允许 NULL。
> 这种场景应改用 `ON DELETE CASCADE` 或 `RESTRICT`。

> [!danger] `CASCADE` 是把双刃剑
> `ON DELETE CASCADE` 会**沿外键链一路删下去**：删一个班级 → 删掉所有学生 → 删掉这些学生的所有选课记录……
> **一次误删能清空半个库。** 生产环境慎用，务必先确认级联链路。

---

## 五、线上要不要用物理外键？

> [!info] 两派观点（面试常问）
> **支持用**：数据库层强制保证一致性，任何写入路径都绕不过，最可靠。
> **反对用（阿里/多数互联网公司规范）**：
> - 外键校验会**加锁**，高并发下容易引发**死锁与锁等待**；
> - 分库分表后**跨库外键无法建立**，架构不支持；
> - `ALTER TABLE` 变更、数据迁移、批量导入时外键**处处掣肘**，DBA 维护成本高；
> - 一致性可以改由**应用层 + 事务**保证。
>
> **结论**：学习阶段用外键能直观理解参照完整性；**互联网高并发项目通常不建物理外键**，靠应用层维护逻辑外键（只在字段上建普通索引）。

---

## 六、查询外键信息

```sql
SELECT CONSTRAINT_NAME, COLUMN_NAME,
       REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = '你的库名'
  AND TABLE_NAME   = 'student'
  AND REFERENCED_TABLE_NAME IS NOT NULL;
```

---

> [!quote] 一句话记忆
> **外键 = 从表的"介绍信"**：你的关联值必须能在主表里对得上；主表删/改时，从表按 `RESTRICT`（拦）、`CASCADE`（跟）、`SET NULL`（置空）三选一应对。

---

## 相关笔记

- [[数据约束概述]] —— 七大约束总览
- [[PRIMARY KEY]] —— 外键引用的目标通常是主键
- [[UNIQUE]] —— 外键也可引用唯一键
- [[码的定义]] —— 外码（Foreign Key）的理论定义
- [[Create Table]] —— 建表时声明外键与建表顺序
- [[Alter Table]] —— `ADD CONSTRAINT` / `DROP FOREIGN KEY`
- [[Join]] —— 外键关系是连接查询的常见依据
