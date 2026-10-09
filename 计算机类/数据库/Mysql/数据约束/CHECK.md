# CHECK —— 检查约束

> [!abstract] 一句话
> `CHECK` 规定==**只有满足表达式的值才允许写入**，==相当于给字段加一条自定义规则；不满足就报错拒收。

---

## 一、最重要的坑：MySQL 8.0.16 之前形同虚设

> [!danger] 版本陷阱（面试高频）
> **MySQL 8.0.16 以前，`CHECK` 会被语法解析、但完全不执行**——写了等于没写，插什么进去都"成功"。
> 只有 **8.0.16 及以上** 才真正生效。
> 用 `SELECT VERSION();` 确认版本；不确定时，一律用**应用层校验 + 触发器**兜底。

```sql
SELECT VERSION();   -- 例如 8.0.35，CHECK 才真正生效
```

---

## 二、语法

### 2.1 建表时——列级写法（单列）

```sql
CREATE TABLE student (
    id     BIGINT AUTO_INCREMENT PRIMARY KEY,
    gender CHAR(1) CHECK (gender IN ('M', 'F', 'U')),
    age    TINYINT CHECK (age BETWEEN 0 AND 150)
);
```

### 2.2 建表时——表级写法（可命名、可跨列）

```sql
CREATE TABLE student (
    id     BIGINT AUTO_INCREMENT,
    gender CHAR(1),
    age    TINYINT,
    PRIMARY KEY (id),
    CONSTRAINT chk_gender CHECK (gender IN ('M', 'F', 'U')),
    CONSTRAINT chk_age    CHECK (age BETWEEN 0 AND 150)
);
```

> [!tip] 强烈建议表级 + 命名
> 报错时能直接看到 `chk_age`，一眼定位；匿名检查约束在 MySQL 里会被自动命名成 `student_chk_1` 这种，不好排查。

### 2.3 跨列检查（列级做不到）

```sql
CREATE TABLE exam (
    id     BIGINT PRIMARY KEY,
    pass   TINYINT,          -- 是否通过 0/1
    score  DECIMAL(4,1),
    CONSTRAINT chk_consistent CHECK (pass = 0 OR score >= 60)
);
```

这里的规则同时用到 `pass` 和 `score`，**只能写成表级约束**。

---

## 三、建表后添加 / 删除

```sql
-- 添加
ALTER TABLE student
    ADD CONSTRAINT chk_age CHECK (age BETWEEN 0 AND 150);

-- 删除（8.0.16+ 用 DROP CONSTRAINT）
ALTER TABLE student DROP CONSTRAINT chk_age;

-- 8.0.16 之前如果建的是匿名约束，需先查名字再删
ALTER TABLE student DROP CHECK chk_age;   -- 部分版本写法
```

> [!warning] 加约束前先清理历史数据
> 表里已有 `age = 999` 这种违规数据时，`ADD CONSTRAINT` 会直接失败。先 `UPDATE` 修正，再加。

---

## 四、表达式里能用什么、不能用什么

| 允许                                       | 不允许                          |
| ---------------------------------------- | ---------------------------- |
| 该行字段之间的比较、`IN`、`BETWEEN`、`AND/OR/NOT` | ❌ 子查询 `CHECK (age > (SELECT ...))` |
| 常量、确定性的内置函数（`LENGTH`、`UPPER` 等）         | ❌ 引用**其他行**的值                |
| 多个列之间的运算                                 | ❌ 引用**其他表**的列                |
|                                          | ❌ 存储函数、用户变量、非确定性函数（如 `RAND()`、`NOW()`） |

> [!info] 为什么限制这么严
> 检查约束只在**写入本行时**评估，必须"就地可判"。要求跨表、跨行判断的规则，本质是**触发器或应用层**的活。

---

## 五、能替代 `NOT NULL` 吗？

不能完全替代，但能表达更细的规则：

```sql
-- 想"必须有值" → 用 NOT NULL
name VARCHAR(50) NOT NULL

-- 想"非空，且不能是空串" → NOT NULL + CHECK 组合
name VARCHAR(50) NOT NULL CHECK (name <> '')
```

> [!tip] 常见组合
> ```sql
> -- 手机号：非空 + 11 位
> phone CHAR(11) NOT NULL CHECK (phone REGEXP '^1[3-9][0-9]{9}$')
> -- 金额：非空 + 非负
> amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0)
> ```

> [!warning] `CHECK` 里的 NULL 会"漏网"
> 检查表达式结果为 `NULL`（未知）时，约束**视为通过**。所以 `CHECK (age > 0)` 拦不住 `age IS NULL`。
> 想连 NULL 一起拦，必须叠加 `NOT NULL`。

---

## 六、与 ENUM 的取舍

| 方案                | 优点             | 缺点                 |
| ----------------- | -------------- | ------------------ |
| `ENUM('M','F','U')` | 写法短、存储省（内部按整数存） | 改枚举值要 `ALTER` 表结构，灵活性差 |
| `CHECK (col IN (...))` | 改规则方便、语义统一     | 语法略长               |

> [!tip] 选型建议
> 取值**极少且几乎不变**（性别、是否删除）→ `ENUM` 够用；
> 取值**可能增删**（订单状态会加新状态）→ 用 `CHECK` 或干脆字典表 + 外键，避免频繁改结构。

---

## 七、查询已有的检查约束

```sql
SELECT CONSTRAINT_NAME, CHECK_CLAUSE
FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = '你的库名';
```

---

> [!quote] 一句话记忆
> **`CHECK` = 字段的自定义准入门槛**：表达式为真才放行；**8.0.16 之前它是个摆设**，为 NULL 时也会放行。

---

## 相关笔记

- [[数据约束概述]] —— 七大约束总览
- [[NOT NULL]] —— 常与 CHECK 叠加使用
- [[UNIQUE]] —— 唯一性约束
- [[FOREIGN KEY]] —— 跨表参照完整性
- [[Create Table]] —— 建表时声明约束
- [[Alter Table]] —— `ADD CONSTRAINT` / `DROP CONSTRAINT`
