# NOT NULL —— 非空约束

> [!abstract] 一句话
> `NOT NULL` 规定某列**必须有值**，插入、更新时都不能留空；字段默认是"允许为空"，==必须手动写 `NOT NULL` 才开启==。

---

## 一、先分清：NULL、`''`、0 不是一回事

| 写法         | 含义                | 是否算"空"      |
| ---------- | ----------------- | ----------- |
| `NULL`     | **没有值 / 未知**，占位而已 | ✅ 被 `NOT NULL` 拦 |
| `''`       | 长度为 0 的**空字符串**   | ❌ 是合法值      |
| `0`        | 数字零               | ❌ 是合法值      |

> [!danger] 最常见的误解
> ==`NULL` 不等于 `0`，也不等于空串==。`age = 0` 表示"年龄是零岁"，`age IS NULL` 表示"年龄未知"。
> 所以 `NOT NULL` 只拦 `NULL`，**拦不住空串**——要拦空串得配合 `CHECK (col <> '')`。

```sql
INSERT INTO student (name, gender) VALUES (NULL, 'M');
-- ERROR 1048 (23000): Column 'name' cannot be null
```

---

## 二、为什么默认是"允许为空"

SQL 的设计哲学：**存储太贵，未知很正常**。一个人没填"备注"，不能因此不让他成为一条记录。
所以建表时若想禁止留空，必须**显式声明**：

```sql
CREATE TABLE student (
    name  VARCHAR(50) NOT NULL,   -- 必须有值
    phone VARCHAR(20)             -- 不写，默认允许 NULL
);
```

---

## 三、建表时声明（列级）

`NOT NULL` 是**列级约束**，只能单独跟在某一个字段后面：

```sql
CREATE TABLE student (
    id     BIGINT       NOT NULL AUTO_INCREMENT,
    stu_no CHAR(10)     NOT NULL,               -- 学号不能空
    name   VARCHAR(50)  NOT NULL,               -- 姓名不能空
    gender CHAR(1)      DEFAULT 'U',            -- 可以为空
    PRIMARY KEY (id)
);
```

> [!info] 只能作用于单列
> `NOT NULL` **不能多列组合**（"这两列至少填一个"这种规则要靠 `CHECK`）。
> 声明顺序无所谓：`NOT NULL DEFAULT 'x'` 和 `DEFAULT 'x' NOT NULL` 等价。

---

## 四、建表后添加 / 移除

```sql
-- 添加非空约束
ALTER TABLE student MODIFY phone VARCHAR(20) NOT NULL;

-- 移除非空约束（改回允许 NULL）
ALTER TABLE student MODIFY phone VARCHAR(20) NULL;
```

> [!warning] 添加前必须先填掉已有的 NULL
> 表里该列只要存在一行是 `NULL`，加约束就会失败：
> ```
> ERROR 1138 (22004): Invalid use of NULL value
> ```
> 正确顺序：先 `UPDATE student SET phone = '' WHERE phone IS NULL;` 补数据，再加约束。

> [!tip] `MODIFY` 要写全字段定义
> `ALTER TABLE ... MODIFY` 是**整体重定义该列**，原来写在列上的 `DEFAULT`、`COMMENT` 等如果没重写，会**一起丢掉**。改约束时记得把该列原样定义补全。

---

## 五、与主键的关系

> [!note] 主键天生非空
> `PRIMARY KEY` = 唯一 + 非空。定义主键的列**自动带 `NOT NULL`**，再手写一遍不算错，但纯属多余。
> 反过来，`UNIQUE` 列**允许 NULL**（甚至允许多个 `NULL`），这正是主键和唯一的关键区别。

```sql
CREATE TABLE t (id INT PRIMARY KEY);   -- id 自动 NOT NULL
INSERT INTO t VALUES (NULL);
-- ERROR 1048: Column 'id' cannot be null
```

---

## 六、`NOT NULL` 与查询、聚合的三个坑

### 6.1 比较 NULL 要用 `IS NULL`，不能用 `=`

```sql
SELECT * FROM student WHERE phone = NULL;    -- ❌ 永远查不到
SELECT * FROM student WHERE phone IS NULL;   -- ✅ 正确
```

### 6.2 聚合函数会"跳过" NULL

`COUNT(phone)` 数的是**非 NULL 的行数**，不是总行数；`SUM`/`AVG`/`MAX`/`MIN` 同样忽略 NULL。

```sql
SELECT COUNT(*)     AS 总行数,     -- 含 NULL 行
       COUNT(phone) AS 有电话行数   -- 不含 NULL 行
FROM student;
```

### 6.3 `NULL` 参与运算结果是 `NULL`

```sql
SELECT 100 + NULL;   -- 结果是 NULL，不是 100
```

> [!tip] 想给 NULL 一个兜底值用 `IFNULL` / `COALESCE`
> ```sql
> SELECT IFNULL(phone, '未填写') FROM student;
> SELECT COALESCE(a, b, c) FROM t;   -- 取第一个非 NULL
> ```

---

## 七、要不要给字段加 `NOT NULL`？

| 场景                  | 建议            |
| ------------------- | ------------- |
| 主键、外键、业务必填字段（姓名、金额） | ✅ 加 `NOT NULL` |
| 可选信息（备注、第二联系方式）     | 允许 NULL       |
| 状态类字段               | ✅ 加，并配 `DEFAULT`，避免业务代码到处判空 |
| 时间字段                | ✅ 加，配 `DEFAULT CURRENT_TIMESTAMP` |

> [!success] 心得
> 能加 `NOT NULL` 就加。**空值是最难处理的"幽灵"**——它在比较、聚合、连接、索引里都有特殊行为。
> 少一个可空字段，就少一片需要 `if (x == null)` 的代码。

---

> [!quote] 一句话记忆
> **`NOT NULL` = "这一栏必须填"**：默认允许空，写了才生效；它只拦 `NULL`，不拦空串和 0。

---

## 相关笔记

- [[数据约束概述]] —— 七大约束总览
- [[DEFAULT]] —— 非空常与默认值搭配使用
- [[PRIMARY KEY]] —— 主键自带非空
- [[CHECK]] —— 想拦空串要靠检查约束
- [[Create Table]] —— 建表时声明约束
- [[Alter Table]] —— `MODIFY` 增删非空约束
