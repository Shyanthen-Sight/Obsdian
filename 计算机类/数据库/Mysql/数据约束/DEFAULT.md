# DEFAULT —— 默认值约束

> [!abstract] 一句话
> `DEFAULT` 规定：**插入时如果没给这一列赋值，就自动填上预设值**。它只在"你没写"时生效，写了就按你写的来。

---

## 一、生效时机（最关键的一点）

```sql
CREATE TABLE student (
    id       BIGINT AUTO_INCREMENT PRIMARY KEY,
    name     VARCHAR(50) NOT NULL,
    gender   CHAR(1)     DEFAULT 'U',        -- 不写 gender 时 → 'U'
    is_vip   TINYINT(1)  DEFAULT 0
);

-- ① 完全不给 gender 赋值 → 填默认 'U'
INSERT INTO student (name) VALUES ('张三');           -- gender = 'U'

-- ② 显式给 NULL → 填的就是 NULL，DEFAULT 不生效！
INSERT INTO student (name, gender) VALUES ('李四', NULL);  -- gender = NULL
```

> [!danger] 最容易踩的坑：显式 `NULL` 会盖掉默认值
> `DEFAULT` 只在**语句里完全没提到这一列**时触发。
> 一旦你写了 `VALUES (..., NULL)`，那是"我明确要 NULL"，默认值不再介入。
> 若这列同时有 `NOT NULL` + `DEFAULT`，插 `NULL` 就会直接报错。

---

## 二、建表时声明

```sql
CREATE TABLE t (
    -- 常量默认
    status   TINYINT      DEFAULT 0,
    gender   CHAR(1)      DEFAULT 'U',
    score    DECIMAL(4,1) DEFAULT 0.0,
    remark   VARCHAR(50)  DEFAULT '无',

    -- 默认 NULL（显式写出，语义 = 允许空）
    phone    VARCHAR(20)  DEFAULT NULL,

    -- 非空 + 默认值（最常用组合）
    balance  DECIMAL(10,2) NOT NULL DEFAULT 0.00,

    -- 表达式默认（8.0.13+ 支持括号表达式）
    created  DATETIME     DEFAULT CURRENT_TIMESTAMP,
    uuid     VARCHAR(36)  DEFAULT (UUID())
);
```

> [!info] 顺序无所谓
> `NOT NULL DEFAULT 0` 与 `DEFAULT 0 NOT NULL` 等价。
> 但**语义上要配合**：既然默认给了值，通常也希望它非空 → `NOT NULL DEFAULT 0`。

---

## 三、默认值能写什么

| 类型              | 例子                                  | 备注                     |
| --------------- | ----------------------------------- | ---------------------- |
| 常量              | `DEFAULT 0`、`DEFAULT 'U'`            | 类型必须与该列匹配              |
| `NULL`          | `DEFAULT NULL`                       | 等价于不写，但更显式            |
| 时间函数            | `DEFAULT CURRENT_TIMESTAMP`          | `DATETIME` / `TIMESTAMP` |
| 表达式（8.0.13+）   | `DEFAULT (UUID())`、`DEFAULT (JSON_ARRAY())` | ==必须用括号包起来==          |

> [!warning] 不能有默认值的类型
> - `TEXT` / `BLOB` / `JSON` / `GEOMETRY`：**不能设常量默认值**（`TEXT` 在 8.0.13+ 可设表达式默认）。
> - `AUTO_INCREMENT` 列：本身就有"自动填下一个数"的语义，写 `DEFAULT` 无意义。
> - 8.0.13 之前，表达式默认值不被支持，`DEFAULT (UUID())` 会报错。

---

## 四、建表后修改 / 删除默认值

```sql
-- 添加 / 修改默认值
ALTER TABLE t MODIFY status TINYINT DEFAULT 1;

-- 非空 + 默认值一起改
ALTER TABLE t MODIFY balance DECIMAL(10,2) NOT NULL DEFAULT 100.00;

-- 删除默认值（保留非空）
ALTER TABLE t MODIFY balance DECIMAL(10,2) NOT NULL;

-- 删除默认值（同时允许为空）
ALTER TABLE t MODIFY balance DECIMAL(10,2);
```

> [!tip] `ALTER ... MODIFY` 是"整列重定义"
> 只改默认值时，也要把该列的**类型、NOT NULL、COMMENT** 原样写全，否则会一起丢掉。
> 想省事可用：`ALTER TABLE t ALTER COLUMN status SET DEFAULT 1;`（只动默认值，不影响其他属性）；删除用 `ALTER COLUMN status DROP DEFAULT;`。

---

## 五、`NULL` 默认 vs 常量默认

| 建表写法                             | 不写该列时            | 语义      |
| -------------------------------- | ---------------- | ------- |
| `phone VARCHAR(20)`              | `NULL`           | 不关心，允许空 |
| `phone VARCHAR(20) DEFAULT NULL` | `NULL`           | 同上，只是写得更明确 |
| `balance DECIMAL(10,2) NOT NULL DEFAULT 0.00` | `0.00` | 有业务含义的兜底 |

> [!success] 实战建议
> - **状态、计数、金额、开关**等字段：`NOT NULL DEFAULT 初值`，让业务代码永远不用判空。
> - **真正可选的**字段：允许 NULL，别硬塞一个假默认值（如 `'未知'`），否则分不清"没填"和"填了未知"。

---

## 六、几个常见的隐式默认（历史包袱）

> [!warning] `TIMESTAMP` 的隐式行为
> 早于 `explicit_defaults_for_timestamp=ON`（8.0 默认开启）时，**第一个 `TIMESTAMP` 列会自动获得 `DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`**，非常反直觉。
> 现在（8.0+）默认不再隐式添加，但**老库迁移时要注意**：本以为没默认值的列，可能悄悄带了自动更新。
> 建议：需要自动记录时间就**显式写出来**，别依赖隐式规则。

```sql
created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                   ON UPDATE CURRENT_TIMESTAMP
```

---

> [!quote] 一句话记忆
> **`DEFAULT` = "没填就替你填"**：只在完全没给该列赋值时生效；显式写 `NULL` 会绕过默认值。

---

## 相关笔记

- [[数据约束概述]] —— 七大约束总览
- [[NOT NULL]] —— 默认值的最佳拍档
- [[AUTO_INCREMENT]] —— 另一种"自动填值"机制
- [[Create Table]] —— 建表时声明默认值
- [[Alter Table]] —— `MODIFY` / `ALTER COLUMN` 改默认值
