# AUTO_INCREMENT —— 自增长约束

> [!abstract] 一句话
> `AUTO_INCREMENT` 让整数字段在插入时**自动填一个递增的数**（默认从 1 开始，每行 +1）；它==必须依附在主键或唯一键上==，一张表只能有一个。

---

## 一、核心规则（先记这四条）

1. **只能是整数类型**：`TINYINT` / `SMALLINT` / `INT` / `BIGINT`（小数、字符串都不行）。
2. **必须依附在一个键上**：`PRIMARY KEY` 或 `UNIQUE`；实际开发**几乎只和主键搭配**。
3. **一张表只能有 1 个**自增字段。
4. **默认从 1 开始**，插入时给 `NULL` 或不赋值，就自动填下一个数。

> [!failure] 忘了加键会报错
> ```
> ERROR 1075 (42000): Incorrect table definition;
> there can be only one auto column and it must be defined as a key
> ```
> 给自增列补上 `PRIMARY KEY` 或 `UNIQUE` 即可。

---

## 二、建表时声明

### 2.1 最常用：列级 + 主键

```sql
CREATE TABLE user (
    id   BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(20) NOT NULL,
    PRIMARY KEY (id)
);
```

也可以把 `PRIMARY KEY` 直接跟在字段后（列级）：

```sql
CREATE TABLE user (
    id   INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(20)
);
```

### 2.2 复合主键场景 + 自增

复合主键里，自增只能加在**其中一个整数字段**上：

```sql
CREATE TABLE score (
    id    INT AUTO_INCREMENT,
    sid   INT,
    score INT,
    PRIMARY KEY (id, sid)     -- id 自增，sid 由业务给
);
```

### 2.3 自定义起始值

建表末尾用 `AUTO_INCREMENT = N` 指定第一条的编号：

```sql
CREATE TABLE user (
    id   INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(20)
) AUTO_INCREMENT = 1000;      -- 第一条数据 id 从 1000 开始
```

---

## 三、插入数据：三种写法等效

```sql
-- 写法1：省略自增字段（推荐）
INSERT INTO user (name) VALUES ('张三');

-- 写法2：给自增字段传 NULL
INSERT INTO user (id, name) VALUES (NULL, '李四');

-- 写法3：手动指定数字（会改变下一次的自增基数！）
INSERT INTO user (id, name) VALUES (50, '王五');
```

> [!warning] 手动指定会"拔高"计数器
> 上面写法 3 插入 id=50 后，**下一条自动分配的就是 51**（计数器被抬到 50）。
> 但如果手动指定一个**比当前最大值小**的 id（如再插 id=10），计数器**不会被拉低**，仍从 51 继续——只是那条数据本身能插进去（只要不重复）。

> [!tip] 想用 `0` 触发自增？先关 `NO_AUTO_VALUE_ON_ZERO`
> 默认只有 `NULL`（或缺省）才触发自增，写 `0` 会被当成"真的要 0"。除非会话设了 `NO_AUTO_VALUE_ON_ZERO`。
> 别记这个特例，记住"**建议省略或传 NULL**"就行。

---

## 四、建表后添加 / 移除 / 调整

```sql
-- 添加自增（同时确保它是主键）
ALTER TABLE emp MODIFY id INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

-- 只去掉自增，保留主键
ALTER TABLE emp MODIFY id INT NOT NULL;      -- 注意：别再写 AUTO_INCREMENT

-- 修改自增起始值
ALTER TABLE user AUTO_INCREMENT = 200;
```

> [!warning] 只能往大调，不能往小调
> `ALTER TABLE ... AUTO_INCREMENT = N` 若 `N` 小于当前已有最大值，**语句不报错但不生效**。
> 想真正重置，得先清空表（见下）。

---

## 五、自增"空洞"与重置

> [!danger] 自增值不会回退 = 天然有空洞
> 以下情况都会**白白消耗一个编号**，导致 id 不连续：
> - 插入失败 / 事务回滚（编号已分配，不再回收）
> - `DELETE` 删掉中间的行（计数器不动）
> - `INSERT ... ON DUPLICATE KEY UPDATE` 冲突时也会先占号
>
> **这是设计如此，不是 bug。** 别指望 id 连续，也别用它当"第几条记录"。

| 操作                       | 是否重置自增计数器 |
| ------------------------ | --------- |
| `DELETE FROM t;`         | ❌ 不重置，继续往上加 |
| `TRUNCATE TABLE t;`      | ✅ 重置回 1（或建表指定值） |
| `DROP` 后重建               | ✅ 重置     |

> [!tip] `TRUNCATE` 是重置自增的唯一常规手段
> ```sql
> TRUNCATE TABLE user;      -- 清空 + 自增归零
> ALTER TABLE user AUTO_INCREMENT = 1;   -- 若表非空，此句不生效
> ```

---

## 六、常见坑

> [!failure] 自增用完怎么办
> `INT` 自增上限约 21 亿；高写入表可能耗尽，之后报 `Duplicate entry`。
> 所以**主键一律用 `BIGINT`**，别省这个空间。

> [!warning] 自增锁与并发
> InnoDB 用 `innodb_autoinc_lock_mode` 控制自增分配。默认模式（`1`/`2`）在**批量插入**时可能分配出"不连续但唯一"的编号。
> 只要**唯一**，业务就不该依赖它**连续**。

> [!info] 主从/分库分表下别用默认自增
> 多个数据库实例各自自增会撞号。分布式场景改用**雪花算法（Snowflake）**、号段模式或 UUID 等全局唯一策略。

---

> [!quote] 一句话记忆
> **`AUTO_INCREMENT` = 自动发号机**：整数、必须挂键、一表一个、从 1 起；只保证唯一不保证连续，只有 `TRUNCATE` 能重置。

---

## 相关笔记

- [[数据约束概述]] —— 七大约束总览
- [[PRIMARY KEY]] —— 自增几乎总是跟着主键
- [[UNIQUE]] —— 自增也可以挂在唯一键上
- [[Truncate Table]] —— 清空并重置自增
- [[Create Table]] —— 建表时声明自增
- [[Alter Table]] —— `MODIFY` 增删自增属性
