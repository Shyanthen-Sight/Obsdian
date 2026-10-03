# CREATE TABLE —— 创建表

> [!abstract] 一句话
> `CREATE TABLE` 用来在数据库中**定义一张新表**：写清楚有哪些字段、每个字段存什么类型的数据、受哪些约束、用哪个存储引擎。

---

## 一、语法骨架

```sql
CREATE TABLE [IF NOT EXISTS] 表名 (
    字段名1 数据类型 [约束] [COMMENT '说明'],
    字段名2 数据类型 [约束] [COMMENT '说明'],
    ...
    [表级约束]
) [表选项];
```

| 部分 | 是否必须 | 说明 |
| --- | --- | --- |
| `CREATE TABLE 表名` | ✅ | 表名可用反引号包裹 |
| 字段定义 | ✅ | 至少一个字段 |
| `IF NOT EXISTS` | ❌ | 表已存在时不报错、直接跳过 |
| 表级约束 | ❌ | 主键、唯一、外键等复合约束 |
| 表选项 | ❌ | 引擎、字符集、注释 |

> [!tip] 强烈建议加上 `IF NOT EXISTS`
> 脚本被重复执行（重跑初始化脚本）时，不会因为"表已存在"而中断。
> 注意它**只保证不报错**，不会帮你比对结构差异——表已存在时后续定义被完全忽略。

---

## 二、命名规范

> [!warning] 三条硬规矩
> 1. **表名 / 字段名一律小写**，多个单词用**下划线**分隔：`user_login_log`
> 2. **禁止**中文、空格、特殊符号、SQL 关键字
> 3. 撞上关键字必须用**反引号**包裹：`` `order` ``、`` `desc` ``、`` `user` ``

```sql
-- ❌ 反例
CREATE TABLE Order (...);          -- Order 是关键字，直接报语法错
CREATE TABLE 用户表 (...);          -- 中文名，跨平台/工具容易出问题
CREATE TABLE userInfo (...);        -- 驼峰，Windows 能跑 Linux 可能出事

-- ✅ 正例
CREATE TABLE `order` (...);
CREATE TABLE user_info (...);
```

> [!info] 大小写差异的坑
> ==**Linux 环境表名区分大小写，Windows 不区分**。开发在 Windows、上线到 Linux，`UserInfo` 和 `userinfo` 就变成两张不同的表。
> 结论：**全程统一小写**，从根源上避开。字段名同理。==

---

## 三、数据类型速查

### 数值型

| 类型                 | 范围 / 特点                    | 典型用途                     |
| ------------------ | -------------------------- | ------------------------ |
| `TINYINT`          | -128 ~ 127（UNSIGNED 0~255） | 状态标记、年龄                  |
| `INT`              | ±21 亿                      | 一般整型外键、数量                |
| `BIGINT`           | 极大                         | ==**主键 id**==、时间戳毫秒      |
| `DECIMAL(M,D)`     | 精确小数==，M 位中 D 位小数==        | ==**金额**==、==任何不能有误差的数== |
| `FLOAT` / `DOUBLE` | 浮点，有精度误差                   | 科学计算、坐标                  |

> [!danger] 金额千万不要用 FLOAT / DOUBLE
> 浮点是二进制近似存储，`0.1 + 0.2` 算不出 `0.3`。

```sql
SELECT 0.1 + 0.2 = 0.3;            -- 0  (假)
SELECT CAST(0.1 AS DOUBLE) + 0.2;  -- 0.30000000000000004
```

> [!tip] 那该用什么？
> 涉及钱、库存、评分一律 `DECIMAL(10,2)`。

### 字符串型

| 类型           | 长度              | 特点                                    |
| ------------ | --------------- | ------------------------------------- |
| `CHAR(n)`    | ==固定== n        | ==定长，不足补空格==；适合 `CHAR(1)`、==手机号==、MD5 |
| `VARCHAR(n)` | ==可变==，==最多== n | ==**最常用**==，==n 是**字符数**不是字节数==       |
| `TEXT`       | 最长 64KB         | 文章正文、备注；不能设默认值                        |
| `ENUM`       | 枚举              | 只能是预设值之一                              |


> [!tip] VARCHAR 长度怎么给
> ==中文、英文、数字、符号，**每 1 个都算 1 个字符**==，按**实际业务上限**给，不要一律 `VARCHAR(255)`。它省的是**磁盘/内存里的实际长度**，但排序、临时表按 `n` 分配内存——`VARCHAR(255)` 和 `VARCHAR(20)` 在排序时开销差一个量级。
> 经验值：用户名 50、邮箱 100、手机号 20、地址 255。

### 日期时间型

| 类型          | 范围                      | 说明                             |
| ----------- | ----------------------- | ------------------------------ |
| `DATE`      | 1000-01-01 ~ 9999-12-31 | 只要年月日，生日                       |
| `DATETIME`  | 1000 ~ 9999             | 日期+时间，**与时区无关**，存什么读什么         |
| `TIMESTAMP` | 1970 ~ 2038             | 按 **UTC 存储**，随会话时区转换；有 2038 上限 |
| `YEAR`      | 1901 ~ 2155             | 年份                             |

> [!warning] DATETIME 还是 TIMESTAMP？
> - 只在一个时区用（学校作业、单体项目）→ `DATETIME`，直观、范围大
> - 用户遍布多时区 → `TIMESTAMP`，自动做时区换算
> - `TIMESTAMP` 有 **2038 年问题**，长期系统别拿它当主时间字段

---

## 四、六大约束

| 约束  | 关键字              | 作用                 | 能否多字段组合 |
| --- | ---------------- | ------------------ | ------- |
| 主键  | `PRIMARY KEY`    | 唯一 + 非空，一行一个身份证    | ✅ 联合主键  |
| 非空  | `NOT NULL`       | 该列必须有值             | —       |
| 唯一  | `UNIQUE`         | 值不能重复，**但允许 NULL** | ✅       |
| 默认值 | `DEFAULT`        | 不写时自动填             | —       |
| 自增  | `AUTO_INCREMENT` | 自动 +1，**必须是键**     | —       |
| 检查  | `CHECK`          | 满足表达式才允许写入         | —       |
| 外键  | `FOREIGN KEY`    | 值必须来自另一张表的主键       | ✅       |


> [!tip] InnoDB 必须有主键
> 不显式定义主键时，InnoDB 会偷偷生成一个 **6 字节隐藏 `row_id`**（你查不到、用不了）。
> 与其让引擎帮你选，不如自己定：**代理主键用 `BIGINT AUTO_INCREMENT`**，业务主键（学号、身份证）另加 `UNIQUE`。

```sql
-- 主键 + 自增 + 唯一 + 非空 + 默认值 一起用
CREATE TABLE student (
    id       BIGINT      NOT NULL AUTO_INCREMENT,
    stu_no   CHAR(10)    NOT NULL,               -- 学号：业务主键
    name     VARCHAR(50) NOT NULL,
    gender   CHAR(1)     DEFAULT 'U',            -- U 未知 / M 男 / F 女
    age      TINYINT     DEFAULT 0,
    PRIMARY KEY (id),
    UNIQUE KEY uk_stu_no (stu_no)
);
```

> [!note] 约束写在字段后面 vs 单独一行
> - **列级约束**：只涉及一个字段，直接跟在字段定义后 → `name VARCHAR(50) NOT NULL`
> - **表级约束**：涉及多个字段，或需要**给约束起名字** → `UNIQUE KEY uk_a_b (a, b)`
> 起名字很重要：报错信息里显示 `uk_stu_no` 比显示一串随机名好排查得多。

---

## 五、完整示例：用户表 + 订单表

### 5.1 用户表

```sql
CREATE TABLE IF NOT EXISTS `user` (
    `id`         BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
    `username`   VARCHAR(50)  NOT NULL                COMMENT '用户名',
    `email`      VARCHAR(100) DEFAULT NULL            COMMENT '邮箱',
    `age`        TINYINT UNSIGNED DEFAULT 0           COMMENT '年龄',
    `balance`    DECIMAL(10,2) NOT NULL DEFAULT 0.00  COMMENT '余额',
    `is_active`  TINYINT(1)   NOT NULL DEFAULT 1      COMMENT '1启用 0禁用',
    `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                              ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`),
    KEY `idx_email` (`email`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_general_ci
  COMMENT='用户表';
```

逐行拆解几个"能省事"的写法：

- `DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP` → **自动记录创建时间与最后修改时间**，不用在 Java 代码里手动赋值
- `TINYINT(1)` 表示布尔：MySQL 没有真正的 `BOOLEAN`，它只是 `TINYINT(1)` 的别名
- `UNIQUE KEY uk_username` 写在表级，才能**给约束起名**
- `KEY idx_email` 是**普通索引**（不属于约束），只为了查询快

### 5.2 订单表（含外键）

```sql
CREATE TABLE IF NOT EXISTS `order` (
    `id`         BIGINT        NOT NULL AUTO_INCREMENT,
    `user_id`    BIGINT        NOT NULL COMMENT '所属用户',
    `order_no`   CHAR(20)      NOT NULL COMMENT '订单号',
    `amount`     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `status`     TINYINT       NOT NULL DEFAULT 0 COMMENT '0待付 1已付 2发货 3完成',
    `created_at` DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_order_no` (`order_no`),
    KEY `idx_user_id` (`user_id`),
    CONSTRAINT `fk_order_user`
        FOREIGN KEY (`user_id`) REFERENCES `user` (`id`)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单表';
```

> [!tip] 建表顺序很重要
> 有外键的表，**主表必须先建**。上面必须**先执行 `user`，再执行 `order`**，否则报：
> `ERROR 1824 (HY000): Failed to open the referenced table 'user'`

> [!info] 外键的四个动作
> | 选项 | 主表删除/更新时从表怎么办 |
> | --- | --- |
> | `RESTRICT`（默认） | **拒绝**主表的删除/更新 |
> | `CASCADE` | 从表**跟着删/跟着改** |
> | `SET NULL` | 从表外键字段置为 `NULL` |
> | `NO ACTION` | 同 RESTRICT（MySQL 中无区别） |
>
> 线上业务常**不用物理外键**，改由应用层保证，避免锁表与迁移困难。学习阶段用外键能帮你直观理解参照完整性。

---

## 六、复制一张表

### 6.1 只复制结构

```sql
CREATE TABLE user_bak LIKE user;
```

> [!success] 完整克隆结构
> `LIKE` 会连**索引、约束、自增、注释**一起复制，但**不复制数据**。做备份表、改表前的安全网首选。

### 6.2 复制结构 + 数据

```sql
CREATE TABLE user_copy AS SELECT * FROM user WHERE id <= 100;
```

> [!warning] `AS SELECT` 的三个丢失
> 只复制**字段和值**，会丢掉：
> 1. **索引**（包括主键）
> 2. **约束**（`NOT NULL`、`AUTO_INCREMENT` 全没了）
> 3. **注释**
>
> 建完后必须手动补：`ALTER TABLE user_copy ADD PRIMARY KEY (id);`
> 想"结构+数据"都完整保留 → 用 `CREATE TABLE t2 LIKE t1;` 再 `INSERT INTO t2 SELECT * FROM t1;`

---

## 七、临时表

```sql
CREATE TEMPORARY TABLE tmp_report (
    dept   VARCHAR(50),
    total  DECIMAL(12,2)
);

-- 会话结束（连接断开）后自动消失，不必手动删
DROP TEMPORARY TABLE IF EXISTS tmp_report;
```

> [!note] 临时表特点
> - **只在当前会话可见**，其他连接看不到
> - 与普通表**可以同名**，名字解析优先临时表
> - 适合一次性中间结果、跑批统计

---

## 八、表选项

```sql
) ENGINE=InnoDB              -- 引擎：支持事务、行锁、外键（默认，几乎都用它）
  DEFAULT CHARSET=utf8mb4    -- 字符集
  COLLATE=utf8mb4_general_ci -- 排序规则，_ci = 不区分大小写
  COMMENT='用户表';
```

> [!danger] 一定用 utf8mb4，不要用 utf8
> MySQL 里的 `utf8` 是**残缺的三字节版本**，最多存 BMP 字符，**中文能用，emoji 存不进去**（报 `Incorrect string value`）。
> `utf8mb4` 才是真正的 UTF-8。这个坑在"用户昵称带 emoji"时必炸。

> [!tip] 字符集从库继承
> 建库时指定过字符集，建表就可以省略。但**跨库复制表结构时**，显式写上更稳妥。

---

## 九、常见报错与对策

> [!failure] ERROR 1064（语法错误）
> 大多是这几种：撞关键字没加反引号、**最后一个字段后多写了逗号**、括号没配对。

```sql
CREATE TABLE t (
    id INT,
    name VARCHAR(10),   -- ❌ 末尾多这个逗号，1064
);
```

> [!failure] ERROR 1050：Table already exists
> 表已存在。加 `IF NOT EXISTS`，或先 `DROP TABLE IF EXISTS t;`

> [!failure] ERROR 1075：Incorrect table definition; there can be only one auto column and it must be defined as a key
> 自增列**必须是键**。补 `PRIMARY KEY`，或给它加 `UNIQUE`。

> [!failure] ERROR 1215：Cannot add foreign key constraint
> 外键失败的万金油报错，常见原因：**类型/符号/字符集不一致**（`BIGINT` 对 `INT`、`UNSIGNED` 对 `SIGNED`、`utf8mb4` 对 `utf8`）、主表字段不是索引、引擎不是 InnoDB。

---

## 十、建表自查清单

- [ ] 表名、字段名全小写 + 下划线，无关键字裸奔
- [ ] 有显式主键，且是 `BIGINT AUTO_INCREMENT`
- [ ] 金额用 `DECIMAL`，不用 `FLOAT/DOUBLE`
- [ ] `VARCHAR` 长度按业务上限给，不是一律 255
- [ ] 字符集 `utf8mb4`，引擎 `InnoDB`
- [ ] 唯一业务字段（手机号、订单号）加了 `UNIQUE`
- [ ] 时间字段有 `DEFAULT CURRENT_TIMESTAMP` / `ON UPDATE`
- [ ] 外键：主表先建，类型完全一致
- [ ] 关键字段和每个字段都写了 `COMMENT`

---

> [!quote] 一句话记忆
> **CREATE TABLE = 画表格的格子**：先定有几列（字段）、每列填什么（类型）、每列守什么规矩（约束），最后挑个好本子（ENGINE / CHARSET）。

---

## 相关笔记

- [[Alter Table]] —— 表建好后要改结构
- [[Drop Table]] —— 整张表删掉
- [[Truncate Table]] —— 清空数据但留表
- [[表的操作]] —— 数据增删改（INSERT / UPDATE / DELETE）
- [[计算机类/数据结构/数据定义/数据类型]] —— 类型选型细节
