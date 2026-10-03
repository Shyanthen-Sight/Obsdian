# ALTER TABLE —— 修改表结构

> [!abstract] 一句话
> 表建好之后要**加字段、删字段、改类型、改名字、加约束**，统统用 `ALTER TABLE`。它是 DDL，**改的是结构，不是数据**。

---

## 一、语法总览

```sql
ALTER TABLE 表名
    <动作1>,
    <动作2>,
    ...;
```

> [!tip] 一条语句能塞多个动作
> 用逗号分隔，MySQL 会**合并成一次表重建**：

```sql
ALTER TABLE user
    ADD COLUMN phone VARCHAR(20) AFTER email,
    MODIFY COLUMN age SMALLINT NOT NULL DEFAULT 0,
    DROP COLUMN is_active;
```

> [!tip] 一条语句能塞多个动作（续）
> 分开写要重建 3 次表，合并只重建 1 次。**大表上这是天壤之别**——10 万行以下的表感知不明显，千万行级别的表分开写可能锁上几十分钟。

**动作一览：**

| 分类  | 动作                       | 用途                |
| --- | ------------------------ | ----------------- |
| 字段  | `ADD COLUMN`             | 加字段               |
| 字段  | `DROP COLUMN`            | 删字段               |
| 字段  | `MODIFY COLUMN`          | 改**类型 / 约束**      |
| 字段  | `CHANGE COLUMN`          | 改**名字 + 类型 + 约束** |
| 字段  | `RENAME COLUMN`          | **只改名字**          |
| 表名  | `RENAME TO`              | 改表名               |
| 约束  | `ADD` / `DROP`           | 加/删主键、唯一、外键、检查    |
| 默认值 | `ALTER COLUMN`           | 加/删默认值            |
| 选项  | `ENGINE=` / `CONVERT TO` | 改引擎、改字符集          |

---

## 二、字段操作

### 2.1 添加字段 ADD COLUMN

```sql
-- 默认加到最后
ALTER TABLE user ADD COLUMN phone VARCHAR(20);

-- 加到第一个
ALTER TABLE user ADD COLUMN uuid CHAR(36) FIRST;

-- 加到指定字段之后（最常用）
ALTER TABLE user ADD COLUMN phone VARCHAR(20) AFTER email;

-- 一次加多个
ALTER TABLE user
    ADD COLUMN phone   VARCHAR(20)  AFTER email,
    ADD COLUMN address VARCHAR(255) AFTER phone;
```

> [!warning] 加字段的三个默认行为
> 1. **位置默认在最后** —— `SELECT *` 的字段顺序会变，若代码依赖列序号取结果（`rs.getString(3)`），会静默取错值
> 2. **新字段对已有行填的是默认值**，没写 `DEFAULT` 就是 `NULL`
> 3. **`FIRST` / `AFTER` 会触发整表重建**（比加在末尾贵得多），非必要不加中间

---

### 2.2 删除字段 DROP COLUMN

```sql
ALTER TABLE user DROP COLUMN address;

-- 一次删多个：每个都要写 DROP
ALTER TABLE user DROP COLUMN a, DROP COLUMN b;
```

> [!danger] 删字段 = 永久丢数据
> `DROP COLUMN` **连该列的所有数据一起删**，不可回滚、无回收站。
> 上线前先确认：没有视图/触发器/存储过程/代码引用这个字段。
> 稳妥做法：**先改名不删**（`CHANGE` 成 `xxx_deprecated_20260929`），观察一周确认无引用再真删。

---

### 2.3 MODIFY vs CHANGE —— 最容易混的一对

| 对比项  | `MODIFY`            | `CHANGE`                       |
| ---- | ------------------- | ------------------------------ |
| 改类型  | ✅                   | ✅                              |
| 改约束  | ✅                   | ✅                              |
| 改字段名 | ❌ **不能**            | ✅                              |
| 写法   | `MODIFY 字段 新类型 新约束` | `CHANGE 旧名 新名 类型 约束`           |
| 参数个数 | 2 段                 | **3 段，缺一不可**                   |
| 适用版本 | 全版本                 | 全版本（8.0 起改名推荐 `RENAME COLUMN`） |

```sql
-- MODIFY：只改类型/约束，名字原样不动
ALTER TABLE user MODIFY age SMALLINT NOT NULL DEFAULT 0;

-- 加大长度
ALTER TABLE user MODIFY email VARCHAR(200) NOT NULL;

-- CHANGE：改名（类型原样抄一遍）
ALTER TABLE employee CHANGE birth birthday DATE;

-- CHANGE：只改类型，名字照抄（前后同名）
ALTER TABLE employee CHANGE birthday birthday DATETIME;

-- CHANGE：改名 + 改类型 一起
ALTER TABLE employee CHANGE salary month_salary DECIMAL(12,2) NOT NULL;
```

> [!danger] MODIFY / CHANGE 会**覆盖**而不是叠加约束
> 这个坑最常踩。新定义里**没写的约束会被丢掉**：
> **正确写法——把想要的约束全部重写一遍：**
> 改之前先 `SHOW CREATE TABLE user\G` 看看原定义长什么样，照抄再改。

```sql
-- ❌ 错误示范
-- 原字段：name VARCHAR(50) NOT NULL DEFAULT '匿名'
ALTER TABLE user MODIFY name VARCHAR(100);
-- 结果：NOT NULL 没了、DEFAULT 没了，只剩 VARCHAR(100)！

-- ✅ 正确写法
ALTER TABLE user MODIFY name VARCHAR(100) NOT NULL DEFAULT '匿名';
```

> [!tip] MySQL 8.0 起，只改名用 RENAME COLUMN
> 不用像 `CHANGE` 那样重复类型，语义更清楚。但 **8.0 以下不支持**。

```sql
ALTER TABLE user RENAME COLUMN old_name TO new_name;
```

---

## 三、表名操作

```sql
-- 标准写法（推荐，兼容性好）
ALTER TABLE 旧表名 RENAME TO 新表名;

-- MySQL 简写
RENAME TABLE 旧表名 TO 新表名;

-- 原子批量改名（RENAME TABLE 特有，一次切换多张表）
RENAME TABLE user TO user_old, user_new TO user;
```

> [!tip] 线上切换表的经典手法
> 两条改名在**一条语句里原子完成**，用户端察觉不到中断。做数据迁移/重构时非常好用。

```sql
RENAME TABLE live_table TO live_table_bak,
             live_table_new TO live_table;
```

> [!warning] 改名不会自动更新引用
> 改名后，**视图、存储过程、触发器里引用的旧表名不会跟着改**。改完记得全局搜一遍。

---

## 四、约束操作

### 4.1 主键

```sql
ALTER TABLE student ADD PRIMARY KEY (id);
ALTER TABLE student DROP PRIMARY KEY;              -- 删主键
ALTER TABLE student DROP PRIMARY KEY, ADD PRIMARY KEY (stu_no);  -- 换主键
```

> [!warning] 自增主键要先摘掉 AUTO_INCREMENT
> 直接 `DROP PRIMARY KEY` 会报 `ERROR 1075`，因为自增列必须依附于键。
> 顺序应为：

```sql
ALTER TABLE student MODIFY id BIGINT NOT NULL;   -- 1. 先去掉 AUTO_INCREMENT
ALTER TABLE student DROP PRIMARY KEY;            -- 2. 再删主键
```

### 4.2 唯一约束

```sql
ALTER TABLE user ADD UNIQUE KEY uk_phone (phone);
ALTER TABLE user DROP INDEX uk_phone;     -- 删唯一约束用的是 DROP INDEX
```

> [!note] 为什么删唯一约束写 `DROP INDEX`？
> 唯一约束在 MySQL 里**通过唯一索引实现**，所以删除时要按索引删。
> 外键要写 `DROP FOREIGN KEY 名字`（名字 ≠ 列名），普通索引写 `DROP INDEX 名字`。

### 4.3 外键

```sql
-- 加外键
ALTER TABLE `order`
    ADD CONSTRAINT fk_order_user
    FOREIGN KEY (user_id) REFERENCES `user`(id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- 删外键（注意：用的是约束名，不是字段名）
ALTER TABLE `order` DROP FOREIGN KEY fk_order_user;

-- 删完外键，它自动创建的索引还在，通常要顺手删掉
ALTER TABLE `order` DROP INDEX fk_order_user;
```

> [!tip] 外键名怎么查
> 输出里 `CONSTRAINT `fk_order_user` FOREIGN KEY ...` 引号里的就是名字。忘了名字就没法删。

```sql
SHOW CREATE TABLE `order`\G
```

### 4.4 检查约束（8.0.16+）

```sql
ALTER TABLE user ADD CONSTRAINT chk_age CHECK (age BETWEEN 0 AND 150);
ALTER TABLE user DROP CHECK chk_age;
ALTER TABLE user ALTER CHECK chk_age ENFORCED;   -- 启用
```

### 4.5 默认值

```sql
ALTER TABLE user ALTER COLUMN age SET DEFAULT 18;
ALTER TABLE user ALTER COLUMN age DROP DEFAULT;
```

> [!note] 只改默认值不用重建表
> `SET DEFAULT / DROP DEFAULT` 是**元数据改动**，秒完成，不影响已有数据、不锁表。要改默认值别绕道 `MODIFY`。

---

## 五、表选项

```sql
-- 改存储引擎
ALTER TABLE t ENGINE = InnoDB;

-- 改表注释
ALTER TABLE user COMMENT = '用户主表';

-- 改默认字符集（只改新字段的默认，已存在的字段不动）
ALTER TABLE user DEFAULT CHARSET = utf8mb4;

-- 把已有字段也一起转（真实转换，会重建表）
ALTER TABLE user CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
```

> [!warning] `DEFAULT CHARSET` 和 `CONVERT TO` 不是一回事
> - `DEFAULT CHARSET` → 只影响**以后新加**的字段
> - `CONVERT TO CHARACTER SET` → **把现有字段的内容真的转码**，大表上非常昂贵，务必先备份

---

## 六、性能与锁：大表 ALTER 的代价

> [!info] 为什么 ALTER 会慢
> MySQL 8.0 之前，很多 ALTER 操作走 `ALGORITHM=COPY`：**新建一张临时表 → 逐行拷贝数据 → 换名 → 删旧表**。
> 表越大越慢，拷贝期间原表通常**只能读不能写**（或整个被锁）。

```sql
-- 强制要求用 INPLACE（不拷整表），不支持就直接报错而不是偷偷降级
ALTER TABLE user ADD COLUMN phone VARCHAR(20), ALGORITHM=INPLACE, LOCK=NONE;

-- 不想等锁时立刻失败（避免拖垮线上）
ALTER TABLE user ADD COLUMN phone VARCHAR(20), LOCK=NONE;
```

| ALGORITHM | 行为 | 能否并发写 |
| --- | --- | --- |
| `INSTANT` | 只改元数据（8.0.12+ 加末尾列） | ✅ 瞬间完成 |
| `INPLACE` | 原地重建，不拷数据到临时表 | 多数 ✅ |
| `COPY` | 拷全表，最慢 | ❌ |

> [!tip] 加字段的省事技巧
> MySQL 8.0.12 起，**把列加在最后**且带默认值时走 `INSTANT`——**瞬间完成，不重建表**。
> 代价：`FIRST` / `AFTER` 用不了，只能加末尾。权衡一下：如果字段顺序不重要，就别用 `AFTER`。

```sql
ALTER TABLE big_table ADD COLUMN remark VARCHAR(200) DEFAULT NULL, ALGORITHM=INSTANT;
```

> [!danger] ALTER TABLE 是 DDL，不能回滚
> 它执行前会**隐式提交**当前事务。一旦开始就不能 `ROLLBACK`。
> 大表操作前：**先备份 / 先建从库 / 或用 `gh-ost`、`pt-online-schema-change` 这类在线改表工具**。

---

## 七、完整实战案例

场景：`user` 表要从"基础版"升级成"带手机号实名版"。

```sql
-- 先看看现状
SHOW CREATE TABLE user\G

-- 一条语句完成全部改造
ALTER TABLE user
    ADD COLUMN phone      VARCHAR(20)  AFTER email,          -- 加手机号
    ADD COLUMN real_name  VARCHAR(50)  AFTER phone,          -- 加真实姓名
    MODIFY COLUMN username VARCHAR(64) NOT NULL,             -- 放宽用户名长度（约束照抄）
    MODIFY COLUMN age      SMALLINT    NOT NULL DEFAULT 0,   -- 年龄改大范围
    DROP COLUMN is_active,                                   -- 启用标记不再需要
    ADD UNIQUE KEY uk_phone (phone),                         -- 手机号唯一
    ADD CONSTRAINT chk_age CHECK (age BETWEEN 0 AND 150),    -- 年龄检查
    COMMENT = '用户主表 v2';
```

改造后的结果：

| 变化 | 字段 | 说明 |
| --- | --- | --- |
| ➕ 新增 | `phone` | 位置在 `email` 之后，唯一约束 |
| ➕ 新增 | `real_name` | 位置在 `phone` 之后 |
| ✏️ 修改 | `username` | 50 → 64，保留 `NOT NULL` |
| ✏️ 修改 | `age` | `TINYINT` → `SMALLINT`，显式重写约束 |
| ➖ 删除 | `is_active` | 数据一并丢失 |
| 🔒 约束 | `uk_phone` / `chk_age` | 新增 |

---

## 八、避坑清单

> [!failure] ERROR 1060：Duplicate column name
> 字段已存在。先 `DESC 表名;` 看当前结构。

> [!failure] ERROR 1054：Unknown column
> 字段名打错，或表名写错，或该字段已被前面的动作删掉了（同一条语句里动作**按顺序**生效）。

> [!failure] ERROR 1075：Incorrect table definition...
> 改动触及自增列却让它失去了键的身份。参考 §4.1 的两步走。

> [!failure] ERROR 1553 / 1217：Cannot drop index ... needed in a foreign key constraint
> 想删的索引正被外键依赖。**先删外键，再删索引**。

> [!failure] ERROR 1832：Cannot change column used in a foreign key constraint
> 被外键引用的字段不能随便改类型——两边类型必须永远一致（包括 `UNSIGNED`、字符集）。
> 顺序：**先删外键 → 改两边字段 → 再加回外键**。

> [!success] 执行前自查
> - [ ] 已 `SHOW CREATE TABLE` 看原定义，`MODIFY/CHANGE` 是照抄 + 改动，不是凭记忆重写
> - [ ] 多个动作已**合并成一条**语句
> - [ ] 确认没有视图/触发器/存储过程引用要改名的字段
> - [ ] 大表已评估锁时间，必要时用 `ALGORITHM=INSTANT/INPLACE` 或在线工具
> - [ ] 生产库 **已经备份**

---

> [!quote] 一句话记忆
> **MODIFY 改类型不改名，CHANGE 改名也改类型，RENAME COLUMN 只改名**；而 MODIFY/CHANGE **没写的约束就等于删掉**。

---

## 相关笔记

- [[Create Table]] —— 建表时就把约束写全，减少后续 ALTER
- [[Drop Table]] —— 删表 / 删库
- [[Truncate Table]] —— 清空数据
- [[外键约束]] —— 外键的四种级联动作
- [[非空约束]] · [[唯一约束]] · [[检查约束]] · [[默认值约束]] · [[自增长约束]]
