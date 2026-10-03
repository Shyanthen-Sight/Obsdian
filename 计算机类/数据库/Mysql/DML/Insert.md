# INSERT —— 插入数据

> [!abstract] 一句话
> `INSERT` 往表里**新增行**，是 DML 四件事（增、删、改、查）里的"**增**"。
> 它能插一行、能插一批，也能把另一张表 `SELECT` 出来的结果整批发过来。

---

## 一、四种写法总览

| 写法 | 语法骨架 | 特点 | 什么时候用 |
| --- | --- | --- | --- |
| ① 完整写法 | `INSERT INTO t (c1, c2) VALUES (v1, v2);` | ==最推荐==，字段一目了然 | 日常开发一律用它 |
| ② 省略列名 | `INSERT INTO t VALUES (v1, v2, ...);` | 必须按建表顺序给全所有列 | 临时测试、结构不会变 |
| ③ `SET` 写法 | `INSERT INTO t SET c1 = v1, c2 = v2;` | MySQL 特有（别的库没有） | 单行、字段少 |
| ④ `INSERT ... SELECT` | `INSERT INTO t SELECT ... FROM t2;` | 一次灌一整批 | 复制表、跨表同步 |

```sql
-- ① 完整写法：显式列出字段名，最安全
INSERT INTO student (name, gender, age, score, class) VALUES ('张三', 'M', 18, 92.50, '高一1班');

-- ② 省略列名：值的顺序必须和建表时的字段顺序完全一致
INSERT INTO student VALUES (NULL, '张三', 'M', 18, 92.50, '高一1班');

-- ③ SET 写法（MySQL 特有）
INSERT INTO student SET name = '张三', gender = 'M', age = 18;

-- ④ 从另一张表整批灌数据
INSERT INTO student_bak (name, score) SELECT name, score FROM student WHERE score >= 90;
```

> [!info] 三篇笔记共用同一张示例表
> 为方便和 [[Update]]、[[Delete]] 串读，本文示例都基于下面这张表，建表说明见 [[Create Table]]。

```sql
CREATE TABLE student (
    id     INT          AUTO_INCREMENT PRIMARY KEY,
    name   VARCHAR(20)  NOT NULL,
    gender CHAR(1)      DEFAULT 'U',      -- M男 F女 U未知
    age    TINYINT      DEFAULT 0,
    score  DECIMAL(5,2),
    class  VARCHAR(20)
);
```

---

## 二、单行插入

```sql
INSERT INTO student (name, gender, age, score, class) VALUES ('张三', 'M', 18, 92.50, '高一1班');
-- Query OK, 1 row affected (0.01 sec)

SELECT * FROM student;
```

```
+----+--------+--------+-----+-------+-----------+
| id | name   | gender | age | score | class     |
+----+--------+--------+-----+-------+-----------+
|  1 | 张三   | M      |  18 | 92.50 | 高一1班   |
+----+--------+--------+-----+-------+-----------+
```

**没写 `id` 它却有了值** —— 自增列由 MySQL 自己填，从 1 开始（见 [[自增长约束]]）。若 `score` 也不写，该列没有 `DEFAULT` 又允许 NULL，结果就是 `NULL`。

> [!tip] 字符串必须用单引号
> `'张三'` 是**字符串**；`"张三"` 在 MySQL 默认模式下被当成**标识符**（列名或表名），当值用会报 `ERROR 1054 Unknown column '张三' in 'field list'`。
> ==别赌双引号，一律单引号。== 字符串里还要写单引号就转义：`'It\'s ok'` 或 `'It''s ok'`。

---

## 三、多行批量插入

```sql
INSERT INTO student (name, gender, age, score, class) VALUES
    ('张三', 'M', 18, 92.50, '高一1班'),
    ('李四', 'F', 17, 88.00, '高一1班'),
    ('王五', 'M', 19, 76.50, '高一2班');
-- Query OK, 3 rows affected (0.01 sec)
-- Records: 3  Duplicates: 0  Warnings: 0
-- 结果：id 依次是 1、2、3，影响行数 = 插入行数
```

> [!important] 批量插入快在哪
> 只发**一次网络往返**、只解析一次 SQL、只提交一次事务。循环 10000 次单行 `INSERT` 则要发 10000 次包、开 10000 次事务（`autocommit=1` 时每条都提交）。
> ==同样插 10000 行，批量写法通常快 10~30 倍==（本地实测约 12 秒 vs 0.4 秒）。

---

## 四、省略列名 vs 显式列名

| 对比项 | 省略列名 `INSERT INTO t VALUES (...)` | 显式列名 `INSERT INTO t (a, b) VALUES (...)` |
| --- | --- | --- |
| 值的顺序 | ==必须严格等于建表顺序== | 跟列名列表对齐即可 |
| 值的数量 | 必须**等于全表列数** | 等于列名列表长度 |
| 自增 / 默认值列 | 也得占位（写 `NULL` 或 `DEFAULT`） | 直接不写，最省事 |
| 表新增一列后 | **静默错位**，值串到隔壁列 | 不受影响 |
| 可读性 | 差，看不出第 4 个值是什么 | 好，字段名就在眼前 |
| 推荐度 | 仅临时测试 | ==生产代码一律用它== |

```sql
-- 假设后来执行了 ALTER TABLE student ADD COLUMN phone VARCHAR(20) AFTER name;
INSERT INTO student VALUES (NULL, '赵六', '13800000000', 'M', 18, 92.5, '高一1班');
--                              id    name   ↑ 手机号插进了新加的 phone，后面全部错位
```

> [!warning] 省略列名必须给全所有列
> 少给一个值报 `ERROR 1136: Column count doesn't match value count at row 1`；顺序错了更可怕——**不报错，但数据静默串位**，事后极难排查。
> 只要表上还有 `AUTO_INCREMENT` 列，它也要占一个位。

---

## 五、`NULL` 与 `DEFAULT` 怎么处理

| 写法 | 结果 | 适用条件 |
| --- | --- | --- |
| `score = NULL` | 该列存 `NULL` | 列必须允许 NULL |
| `score = DEFAULT` | 该列取**默认值** | 列没定义 `DEFAULT` 则取 `NULL` |
| **完全不写这一列** | 默认值 / `NULL` / 自增值 | ==最正规、最通用的写法== |

> [!note] "用默认值"的正规写法是**不写这一列**
> `DEFAULT` 关键字在 `UPDATE` 里要 8.0.13+ 才支持，别的数据库也未必认。直接**不列出该字段名**，任何版本、任何数据库都按默认值处理，才是最稳的写法。

```sql
INSERT INTO student (name, score) VALUES ('钱七', NULL);
-- 结果：id=4, name=钱七, gender='U'(默认值), age=0(默认值), score=NULL(显式), class=NULL
```

> [!question] 自增列想让它自动生成，该写 `0` 还是 `NULL`？
> **两种都行**——都会被忽略，转而生成新值（只在 `NO_AUTO_VALUE_ON_ZERO` 模式下写 `0` 会真的存 0）。
> 语义上 `NULL` 更准确："这里没有值"。但**最推荐显式列名 + 根本不给 `id` 赋值**：
> `INSERT INTO student (name, age) VALUES ('孙八', 20);` → 结果 id 自动取 4 之后的下一个值。

---

## 六、日期时间怎么插

```sql
INSERT INTO article (title, created_at) VALUES ('MySQL 入门', '2026-09-29 10:30:00');
INSERT INTO article (title) VALUES ('SQL 进阶');          -- 交给 CURRENT_TIMESTAMP
INSERT INTO article (title, created_at) VALUES ('索引原理', NOW());
```

| 写法 | 实际存入 | 说明 |
| --- | --- | --- |
| `'2026-09-29'` | `2026-09-29 00:00:00` | 只给日期，时间部分补零 |
| `'2026-09-29 10:30:00'` | 原样 | ==标准写法，推荐== |
| `'2026/09/29'` | `2026-09-29` | MySQL 认，别的库未必，别用 |
| `NOW()` | 语句**开始执行**的时刻 | 一条语句里调多次结果相同 |
| `CURRENT_TIMESTAMP` | 同 `NOW()` | 标准 SQL 写法 |
| `SYSDATE()` | 函数**被调用**的时刻 | 与 `NOW()` 有微秒级差异 |

> [!tip] 时间字段交给数据库自己填
> 建表时写 `created_at DATETIME DEFAULT CURRENT_TIMESTAMP`，插入就**别再写这一列**。应用服务器时钟跑偏也不影响，`ON UPDATE CURRENT_TIMESTAMP` 还能自动维护"最后修改时间"，见 [[默认值约束]]。

---

## 七、主键 / 唯一键冲突的三种处理（重点）

默认行为是**直接报错**：

```sql
INSERT INTO student (id, name) VALUES (1, '李四');
-- ERROR 1062 (23000): Duplicate entry '1' for key 'student.PRIMARY'
```

### 7.1 `INSERT IGNORE` —— 冲突就跳过

```sql
INSERT IGNORE INTO student (id, name) VALUES (1, '李四');
-- Query OK, 0 rows affected, 1 warning (0.00 sec)   ← 不报错，影响行数为 0
SHOW WARNINGS;
-- 结果：Warning | 1062 | Duplicate entry '1' for key 'student.PRIMARY'
```

> [!warning] `INSERT IGNORE` 会把别的错误一起吞掉
> 它的语义是"遇到能忽略的错误就降级成警告"，不只是主键冲突：`NOT NULL` 违反会悄悄塞成默认值、**字符串超长会静默截断**、数值超范围会截成边界值。
> 结果是**脏数据静默入库**，比直接报错危险得多。只在确知"重复可以跳过"时用。

### 7.2 `ON DUPLICATE KEY UPDATE` —— 一句话实现 upsert

> [!success] upsert = update + insert
> 冲突时**不报错也不跳过**，而是执行后面的 `UPDATE`。写"同步数据""累计计数"时最常用。

```sql
CREATE TABLE score_board (
    id    INT AUTO_INCREMENT PRIMARY KEY,
    name  VARCHAR(20)  NOT NULL,
    score DECIMAL(5,2) DEFAULT 0,
    UNIQUE KEY uk_name (name)
);

-- 第 1 次：表里没有"张三" → 走插入分支
INSERT INTO score_board (name, score) VALUES ('张三', 92.50)
ON DUPLICATE KEY UPDATE score = VALUES(score);
-- Query OK, 1 row affected

-- 第 2 次：唯一键撞上了 → 走更新分支
INSERT INTO score_board (name, score) VALUES ('张三', 95.00)
ON DUPLICATE KEY UPDATE score = VALUES(score);
-- Query OK, 2 rows affected
```

| 执行次数 | id | name | score | 说明 |
| --- | --- | --- | --- | --- |
| 第 1 次 | 1 | 张三 | 92.50 | 走**插入**分支，影响 1 行 |
| 第 2 次 | 1 | 张三 | **95.00** | 走**更新**分支，影响 2 行，==id 保持不变== |

> [!note] 影响行数的三条规则
> 走**插入**分支 → `1 row affected`；走**更新**分支且值**真的变了** → `2 rows affected`；走更新分支但新值 = 旧值 → `0 rows affected`。
> 很多人用它判断"到底插了还是改了"，但第三种情况极易误判，==建议还是靠业务逻辑判断==。

> [!tip] MySQL 8.0.20+ 用别名代替 `VALUES()`
> 老写法 `VALUES(col)` 已**被标记废弃**，推荐写成
> `INSERT INTO score_board (name, score) VALUES ('张三', 96.00) AS new ON DUPLICATE KEY UPDATE score = new.score;`

### 7.3 `REPLACE INTO` —— 先删后插

```sql
REPLACE INTO score_board (id, name, score) VALUES (1, '张三', 88.00);
-- Query OK, 2 rows affected   ← 删掉旧行 1 行 + 插入新行 1 行
```

> [!danger] `REPLACE` 的四个副作用
> 它**不是"更新"**，而是"**删掉冲突行，再插一条新的**"。于是：
> - **触发从表的 `ON DELETE CASCADE`** —— 你只想改个名字，从表数据却被连带删光
> - **重置自增** —— 新行 `id` 重新分配，不再是原来的值（所以上面必须显式写 `id`）
> - **丢掉未指定的列** —— 没写的列被重置为默认值 / `NULL`，不是"保留原值"
> - **触发两次** —— `DELETE` 触发器和 `INSERT` 触发器**都会**跑
>
> 要"有则改、无则插"，**优先用 `ON DUPLICATE KEY UPDATE`**。

### 7.4 四种方式对比

| 方式 | 冲突时行为 | 影响行数 | 未指定的列 | 自增 | 触发器 |
| --- | --- | --- | --- | --- | --- |
| 默认 `INSERT` | ==报 1062 错误== | 失败 | — | — | — |
| `INSERT IGNORE` | **跳过**该行（其他错误也一起吞） | 0 | — | — | 只触发成功的行 |
| `ON DUPLICATE KEY UPDATE` | **更新**指定列 | 1 / 2 / 0 | **保留原值** | 不变 | INSERT + UPDATE |
| `REPLACE INTO` | **先删后插** | 2（或 1） | **重置为默认值** | **可能变** | DELETE + INSERT |

---

## 八、`INSERT INTO ... SELECT`：从别的表灌数据

```sql
CREATE TABLE student_bak LIKE student;   -- 结构完全克隆（含索引、约束）

INSERT INTO student_bak (name, gender, age, score, class)
SELECT name, gender, age, score, class
  FROM student
 WHERE score >= 90;
-- Query OK, 3 rows affected
```

这里的过滤用 [[Where]]，分组统计用 [[Group By]]，排序用 [[Order By]]。

> [!warning] 两个硬限制
> 1. **列数必须与 `SELECT` 的列数一致**，否则报 `ERROR 1136: Column count doesn't match value count at row 1`；两边类型也要对得上
> 2. **不要从目标表自己 `SELECT` 再插回自己**。`UPDATE` / `DELETE` 的子查询引用目标表会被直接拦下报 1093；`INSERT ... SELECT` 虽然内部用隐藏临时表绕过了检查，但结果是**行数直接翻倍**，稍不留神就把表撑爆

```sql
-- ❌ 在 INSERT 的子查询里引用目标表 → 1093
INSERT INTO student (name, score)
SELECT name, (SELECT MAX(score) FROM student) FROM student WHERE score > 90;
-- ERROR 1093 (HY000): You can't specify target table 'student' for update in FROM clause
```

---

## 九、性能与注意事项

```sql
-- 批量导入时提速最明显的一招：包进事务
START TRANSACTION;
INSERT INTO student (name, age) VALUES ('A', 18);
INSERT INTO student (name, age) VALUES ('B', 19);
-- ... 剩下的 9998 条
COMMIT;

SHOW VARIABLES LIKE 'max_allowed_packet';   -- 单条语句的包上限，默认 64MB
```

> [!tip] 三条实战经验
> 1. **单条 `INSERT` 的包别超过 `max_allowed_packet`（默认 64MB）**，超了报 `ERROR 2006: MySQL server has gone away`。批量插入建议**每 500~1000 行拆一条**。
> 2. **多条 `INSERT` 包在 `START TRANSACTION ... COMMIT` 里**，可规避 `autocommit=1` 时"每条都刷一次日志"的开销，提速几十倍。
> 3. **导入时让主键递增**。乱序写入会让 InnoDB 的 B+ 树频繁**页分裂**，顺序递增则基本只在最右侧追加，数据量越大差距越明显。
>
> 千万行级初始化导入别用 `INSERT` 一条条灌，用 `LOAD DATA INFILE`（服务端直接读文件）快一个数量级。

---

## 十、常见报错合集

> [!failure] 六种最常见的 INSERT 报错
> - `ERROR 1062 (23000): Duplicate entry '1' for key 'student.PRIMARY'` —— **主键 / 唯一键冲突**，见 [[唯一约束]]
> - `ERROR 1048 (23000): Column 'name' cannot be null` —— **非空列给了 `NULL`**，见 [[非空约束]]
> - `ERROR 1136 (21S01): Column count doesn't match value count at row 1` —— **列数与值数不一致**，多半是省略列名的写法漏了字段
> - `ERROR 1265 (01000): Data truncated for column 'gender' at row 1` —— **值被截断**，如 `CHAR(1)` 给了一长串
> - `ERROR 1264 (22003): Out of range value for column 'age'` —— **数值越界**，如 `TINYINT` 塞了 300
> - `ERROR 1366 (HY000): Incorrect string value: '\xF0\x9F...'` —— **emoji 存进了 `utf8` 列**，换 `utf8mb4`

---

> [!quote] 一句话记忆
> **写列名、给单引号、多行合一、冲突用 upsert**。
> 值要默认就**干脆别写那一列**，值要自动就**别碰自增列**。

---

## 相关笔记

- [[Update]] —— 修改已有行（`INSERT` 无中生有，`UPDATE` 改头换面）
- [[Delete]] —— 删除行
- [[Select]] —— 插进去的数据要靠它查出来
- [[Create Table]] —— 建表决定了 `INSERT` 能省哪些列
- [[Where]] —— `INSERT ... SELECT` 里的条件过滤
- [[自增长约束]] —— 自增列为什么可以不赋值
- [[非空约束]] · [[唯一约束]] · [[默认值约束]] —— INSERT 时最容易踩的三种约束
