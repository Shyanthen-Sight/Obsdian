# PRIMARY KEY —— 主键约束

> [!abstract] 一句话
> `PRIMARY KEY` = **唯一 + 非空**，用来唯一标识表中的每一行，是一行数据的"身份证"；一张表只能有一个主键（可以是单个字段，也可以是多个字段的联合）。

---

## 一、三大核心特性

| 特性     | 说明                          |
| ------ | --------------------------- |
| **唯一性** | 主键值不能重复，两行不能有相同主键          |
| **非空性** | 主键列自动带 `NOT NULL`，不允许 NULL   |
| **单一性** | 一张表**只能有一个主键**（可单列，可多列联合） |

> [!info] 底层：主键自动创建聚簇索引
> InnoDB 中，主键就是**聚簇索引**（clustered index）——整张表的数据行按主键顺序**物理存储**在 B+ 树叶子节点上。
> 所以主键的选择直接影响插入性能与磁盘布局，**别乱选**。

---

## 二、建表时声明

### 2.1 列级写法（只能单字段）

```sql
CREATE TABLE emp (
    id   INT PRIMARY KEY,          -- 直接跟在字段后
    name VARCHAR(20)
);
```

### 2.2 表级写法（可单字段，也可复合主键）

```sql
-- 单字段 + 自定义约束名
CREATE TABLE emp (
    id   INT,
    name VARCHAR(20),
    CONSTRAINT pk_emp_id PRIMARY KEY (id)
);

-- 复合主键（联合主键）：只能表级写
CREATE TABLE student_course (
    sid INT,
    cid INT,
    CONSTRAINT pk_sc PRIMARY KEY (sid, cid)   -- 学号 + 课程号 组合唯一
);
```

> [!note] 复合主键 = 组合唯一，不是"两个字段各自唯一"
> `PRIMARY KEY (sid, cid)` 表示 `(sid, cid)` 这一对组合不能重复；单个 `sid` 可以重复出现。
> 而且==复合主键的每个字段都不能为 NULL==。

> [!tip] 代理主键 vs 业务主键
> - **代理主键（推荐）**：无业务含义的 `BIGINT AUTO_INCREMENT`，稳定、短、永不变。
> - **业务主键**：学号、身份证、订单号等有含义的字段。==不要直接拿它当主键==——业务字段可能变更、可能很长、可能是字符串。做法：**代理主键 + 给业务字段加 `UNIQUE`**。
> ```sql
> CREATE TABLE student (
>     id     BIGINT AUTO_INCREMENT,
>     stu_no CHAR(10) NOT NULL,          -- 业务主键
>     PRIMARY KEY (id),                  -- 代理主键
>     UNIQUE KEY uk_stu_no (stu_no)
> );
> ```

---

## 三、InnoDB 必须有主键

> [!danger] 没显式主键，InnoDB 会偷偷帮你选
> 1. 若存在**非空唯一索引** → 用它当主键（你查不到、也改不了）；
> 2. 否则生成一个 **6 字节隐藏 `row_id`** 当主键（完全查不到、用不了）。
> 隐藏主键意味着你**无法控制插入顺序、无法删除、无法利用它做任何事**，且全局共享一个计数器。
> ==结论：每张表都显式定义一个主键。==

---

## 四、建表后添加 / 删除

```sql
-- 添加单字段主键
ALTER TABLE emp ADD PRIMARY KEY (id);

-- 添加复合主键
ALTER TABLE student_course ADD PRIMARY KEY (sid, cid);

-- 删除主键
ALTER TABLE emp DROP PRIMARY KEY;
```

> [!warning] 添加主键的前置条件
> 目标字段**必须没有 NULL，且没有重复值**，否则：
> - 有 NULL → `ERROR 1138: Invalid use of NULL value`
> - 有重复 → `ERROR 1062: Duplicate entry`
>
> 先清洗数据再 `ADD PRIMARY KEY`。

> [!warning] 自增主键不能直接 `DROP PRIMARY KEY`
> 若主键列同时是 `AUTO_INCREMENT`，直接删主键会报 `ERROR 1075`（自增列必须是键）。
> 顺序：`MODIFY id BIGINT`（先去掉 AUTO_INCREMENT）→ `DROP PRIMARY KEY`。

---

## 五、怎么选主键字段

| 候选                | 是否推荐         | 理由                            |
| ----------------- | ------------ | ----------------------------- |
| `BIGINT AUTO_INCREMENT` | ✅ 强烈推荐     | 单调递增，插入快、索引不分裂       |
| 业务编号（订单号、学号）        | ⚠️ 另加 `UNIQUE` | 业务字段可能变更、可能很长            |
| 身份证号（18 位）         | ❌ 单独做主键    | 太长（占索引空间）、含隐私、可能变更    |
| 随机 UUID           | ❌ 不做聚簇主键   | 无序导致**页分裂**，写性能差（做业务唯一键可以） |
| 手机号               | ❌            | 会换号、会注销、会共用            |

> [!tip] 主键要"短、稳、单调"
> 主键值会**被所有二级索引存一份**（二级索引叶子存主键值）。主键越长，所有索引越大。
> 所以：能用 `INT` 就别 `BIGINT`（但一般还是 `BIGINT` 保险），能用数字就别用字符串。

---

## 六、查询主键信息

```sql
SELECT CONSTRAINT_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = '你的库名'
  AND TABLE_NAME   = 'student'
  AND CONSTRAINT_NAME = 'PRIMARY';
```

---

> [!quote] 一句话记忆
> **主键 = 一行的身份证**：唯一、非空、一张表只有一个；InnoDB 靠它排布整张表，所以优先用 `BIGINT AUTO_INCREMENT`。

---

## 相关笔记

- [[数据约束概述]] —— 七大约束总览
- [[UNIQUE]] —— 唯一约束：允许 NULL 的"宽松版唯一"
- [[AUTO_INCREMENT]] —— 主键的黄金搭档
- [[FOREIGN KEY]] —— 外键要引用对方的主键
- [[码的定义]] —— 超码 / 候选码 / 主码 / 外码的理论定义
- [[Create Table]] —— 建表时声明约束
