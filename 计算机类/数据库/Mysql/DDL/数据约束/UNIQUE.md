# UNIQUE —— 唯一约束

> [!abstract] 一句话
> `UNIQUE` 规定**这一列（或几列的组合）的值不能重复**。和主键的区别只有一个：==`UNIQUE` 允许 `NULL`，主键不允许==。

---

## 一、与主键的核心区别

| 对比项      | `PRIMARY KEY`   | `UNIQUE`              |
| -------- | --------------- | --------------------- |
| 唯一性      | ✅ 不能重复          | ✅ 不能重复                |
| 是否允许 NULL | ❌ 自动非空          | ✅ **允许**（且可多个 NULL）   |
| 数量       | 一张表**只能一个**     | 可以有**多个**（每个字段都能加）    |
| 命名       | 固定叫 `PRIMARY`   | 可自定义 `uk_xxx`         |
| 用途       | 一行的身份标识         | 业务唯一字段（手机号、订单号、邮箱）  |

> [!success] 一句话说清两者分工
> **能唯一标识一行的选主键，只是"业务上要求不重复"的加 UNIQUE。**
> 如"学号"：它是业务主键，但当主键的是代理 id，学号加 `UNIQUE`。

---

## 二、允许多个 NULL —— 这一点很反直觉

```sql
CREATE TABLE user (
    id    BIGINT AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(20) UNIQUE
);

INSERT INTO user (phone) VALUES ('13800000000');   -- ✅
INSERT INTO user (phone) VALUES (NULL);            -- ✅
INSERT INTO user (phone) VALUES (NULL);            -- ✅ 又一个 NULL，也允许！
INSERT INTO user (phone) VALUES ('13800000000');   -- ❌ ERROR 1062: Duplicate entry
```

> [!warning] NULL 不算重复
> SQL 标准里 `NULL <> NULL`，所以**多个 NULL 之间不构成重复**，`UNIQUE` 会全部放行。
> 若这列同时要求"不能为空且不重复"，必须写成 `phone VARCHAR(20) NOT NULL UNIQUE`。
> 想"允许一个 NULL、但不允许两个"，标准 SQL 无解，得靠**触发器**或 MySQL 8.0.13+ 的函数索引技巧。

---

## 三、建表时声明

### 3.1 列级写法（单字段）

```sql
CREATE TABLE user (
    phone  VARCHAR(20) UNIQUE,          -- 匿名唯一约束
    email  VARCHAR(100) UNIQUE KEY      -- UNIQUE 与 UNIQUE KEY 完全等价
);
```

### 3.2 表级写法（可命名、可复合）

```sql
CREATE TABLE user (
    phone VARCHAR(20),
    email VARCHAR(100),
    -- 给约束起名字（推荐）
    CONSTRAINT uk_phone UNIQUE (phone),
    UNIQUE KEY uk_email (email),
    -- 复合唯一：两列组合不重复
    UNIQUE KEY uk_name_dept (name, dept)
);
```

> [!tip] 复合唯一 ≠ 各自唯一
> `UNIQUE (name, dept)` 表示 `(name, dept)` 组合不重复；单看 `name` 或 `dept` 都**可以重复**。
> 典型场景：同一部门内不允许重名，但不同部门可以同名。

---

## 四、建表后添加 / 删除

```sql
-- 添加唯一约束
ALTER TABLE user ADD CONSTRAINT uk_phone UNIQUE (phone);

-- 删除唯一约束：用的是 DROP INDEX，不是 DROP CONSTRAINT！
ALTER TABLE user DROP INDEX uk_phone;
```

> [!danger] 删除唯一约束为什么是 `DROP INDEX`？
> MySQL 中 `UNIQUE` **底层就是一个唯一索引**（这也是它能加速该列查询的原因）。
> 所以增删走**索引**那套语法：`ADD CONSTRAINT ... UNIQUE` / `DROP INDEX 约束名`。
> 而**外键**才用 `DROP FOREIGN KEY`，**检查**用 `DROP CHECK` / `DROP CONSTRAINT`——**四类约束的删除语法都不一样，别记混**。

> [!tip] 匿名唯一约束怎么删？
> 建表时写 `phone VARCHAR(20) UNIQUE`（没起名），MySQL 会**用列名当索引名**，直接 `ALTER TABLE user DROP INDEX phone;` 即可。
> 想稳当就建表时显式命名。

---

## 五、查询已有的唯一约束

```sql
SELECT tc.CONSTRAINT_NAME, kcu.COLUMN_NAME
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
  ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
 AND tc.TABLE_SCHEMA  = kcu.TABLE_SCHEMA
WHERE tc.TABLE_SCHEMA = '你的库名'
  AND tc.TABLE_NAME   = 'user'
  AND tc.CONSTRAINT_TYPE = 'UNIQUE';
```

查重复数据（加约束前先自查）：

```sql
SELECT phone, COUNT(*) AS cnt
FROM user
GROUP BY phone
HAVING cnt > 1;
```

---

## 六、`UNIQUE` 的性能副作用

> [!warning] 每个唯一约束 = 一个索引，写时都要维护
> 加 `UNIQUE` 会创建索引，**加速该列查询**，但每次 `INSERT` / `UPDATE` 都要维护它，**略降写入速度**并占用磁盘。
> 一张表挂七八个 `UNIQUE` 会明显拖累写入。只在"业务确实要求唯一"的字段上加。

> [!info] 与唯一索引的区别
> `UNIQUE` 约束和 `CREATE UNIQUE INDEX` 在建索引层面**几乎等价**；差别只在语义与可移植性。
> 建表时写 `UNIQUE` 更"声明式"，表达意图更清楚。

---

> [!quote] 一句话记忆
> **`UNIQUE` = "不许重复，但可以空着"**：主键的宽松版，可多个、可组合、可命名；底层是唯一索引，所以删除要用 `DROP INDEX`。

---

## 相关笔记

- [[数据约束概述]] —— 七大约束总览
- [[PRIMARY KEY]] —— 唯一 + 非空的"严格版"
- [[FOREIGN KEY]] —— 外键的被引用列通常需要唯一/主键
- [[Create Table]] —— 建表时声明约束
- [[Alter Table]] —— `ADD CONSTRAINT` / `DROP INDEX`
