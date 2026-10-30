# LIKE 谓词 —— 通配符模糊匹配

> [!abstract] 一句话
> `LIKE` 用 ==`%`（任意个字符）和 `_`（恰好一个字符）==做模式匹配，是最常用的"模糊查询"。
> 它有两个关键约束：==**前导 `%` 会让索引失效**==；==**`_` 只匹配一个字符，不是"任意长度"**==。

> [!info] 与其它笔记的分工
> 本篇讲 `LIKE` / `NOT LIKE` 的通配符、转义、大小写、索引与替代方案。
> 正则匹配见 [[REGEXP谓词]]；全文检索见 [[全文检索谓词]]。
> `WHERE` 的整体用法见 [[Where]]。

---

## 一、语法

```sql
expr LIKE pattern
expr NOT LIKE pattern
expr LIKE pattern ESCAPE '转义符'
```

```sql
SELECT * FROM student WHERE name LIKE '张%';
SELECT * FROM student WHERE name NOT LIKE '张%';
```

结果只有三种：`TRUE`（1）、`FALSE`（0）、`UNKNOWN`（NULL）。

---

## 二、两个通配符

| 通配符 | 含义 | 示例 | 匹配 |
| --- | --- | --- | --- |
| `%` | 任意个字符（含 0 个） | `'张%'` | 张三、张三丰、张 |
| `_` | ==恰好一个字符== | `'张_'` | 张三（**不匹配**张三丰） |

```sql
SELECT * FROM student WHERE name LIKE '张%';      -- 以"张"开头
SELECT * FROM student WHERE name LIKE '%三';      -- 以"三"结尾
SELECT * FROM student WHERE name LIKE '%三%';     -- 含"三"
SELECT * FROM student WHERE name LIKE '张_';      -- "张" + 恰好 1 个字符
SELECT * FROM student WHERE phone LIKE '138%';    -- 手机号前 3 位
```

数据与结果对照：

```
student 表
+----+---------+-------------+
| id | name    | phone       |
+----+---------+-------------+
|  1 | 张三    | 13812345678 |
|  2 | 张三丰  | 13900001111 |
|  3 | 李四    | 13898765432 |
|  4 | 王小三  | 15900002222 |
+----+---------+-------------+

WHERE name LIKE '张%'    → 张三、张三丰
WHERE name LIKE '张_'    → 张三          （张三丰 3 个字，不匹配）
WHERE name LIKE '%三%'   → 张三、张三丰、王小三
WHERE phone LIKE '138%'  → 张三、李四
```

> [!warning] `_` 只能匹配**一个**字符
> 这是 `LIKE` 最常被搞错的地方：`'张_'` **不匹配** `'张三丰'`。
> 在 `utf8mb4` 下，一个汉字算**一个字符**，所以 `'张_'` 能匹配 2 个字的 `'张三'`。
> 想匹配"张"开头的任意长度，用 `'张%'`。

> [!tip] `%` 和 `_` 可以组合
> - `'张%丰'`：以张开头、以丰结尾；
> - `'_三%'`：第二个字是"三"；
> - `'%三_'`：倒数第二个字是"三"；
> - `'___'`：恰好 3 个字符。

---

## 三、转义：查找字面量的 `%` 和 `_`

如果要查的字符串本身包含 `%` 或 `_`，必须转义，否则会被当成通配符。

```sql
-- 查备注里包含"%"的，例如"需发票50%"
SELECT * FROM goods WHERE remark LIKE '%!%%' ESCAPE '!';

-- 查用户名里包含下划线的，例如 user_name
SELECT * FROM user WHERE username LIKE '%!_%' ESCAPE '!';
```

> [!warning] 反斜杠在字符串字面量里本身也是转义符
> MySQL 的字符串字面量中，`\` 是转义字符。写成 `'\%'` 时，MySQL 会保留 `\%` 交给 `LIKE` 处理，所以通常能工作。
> 但为了意图明确，**建议显式写 `ESCAPE`**。
> 如果转义符用反斜杠，SQL 字符串字面量里要写成 `ESCAPE '\\'`（两个反斜杠），因为 `\` 在字符串里本身是转义符。
> 更省心的做法是换一个不常用的转义符，例如 `ESCAPE '!'`：
> ```sql
> WHERE remark LIKE '%!%%' ESCAPE '!';
> ```

> [!tip] 也可以换一个不常用的转义符
> 当模式里同时有反斜杠和 `%` 时，用 `ESCAPE '!'` 之类的字符能让 SQL 更易读：
> ```sql
> WHERE path LIKE '%!%%' ESCAPE '!';   -- 查包含 % 的路径
> ```

---

## 四、大小写与排序规则

`LIKE` 是否区分大小写，取决于列的 **collation**：

```sql
-- 默认 utf8mb4_0900_ai_ci：不区分大小写
SELECT 'ABC' LIKE 'abc';              -- 1
SELECT 'ABC' LIKE 'ABC';              -- 1

-- 二进制排序规则：区分大小写
SELECT 'ABC' LIKE 'abc' COLLATE utf8mb4_bin;  -- 0
SELECT BINARY 'ABC' LIKE 'abc';               -- 0
```

> [!important] 业务上要不要区分大小写，应该在**建表/查询时明确**
> 不要依赖"默认应该是不敏感"这种假设。跨库迁移、不同 MySQL 版本、不同 collation 都可能改变结果。
> 需要严格匹配时：`WHERE BINARY col LIKE 'Abc%'`，或使用二进制排序规则。

---

## 五、NULL 行为

```sql
SELECT NULL LIKE '%a%';        -- NULL（UNKNOWN）
SELECT 'abc' LIKE NULL;        -- NULL（UNKNOWN）
SELECT 'abc' LIKE '%b%';       -- 1
```

`WHERE` 只保留 TRUE，所以：

```sql
-- ❌ 查不出 name 为 NULL 的行
SELECT * FROM student WHERE name LIKE '%';
```

`'%'` 匹配任意非 NULL 字符串，但 **NULL 仍然不匹配**。要包含 NULL 行：

```sql
SELECT * FROM student WHERE name LIKE '%' OR name IS NULL;
```

> [!danger] `LIKE '%'` 不等于"所有行"
> 它只匹配"非 NULL 的任意字符串"。NULL 行会被 UNKNOWN 丢弃。

---

## 六、性能：前导 `%` 是索引杀手

> [!danger] `LIKE '%关键字%'` 无法使用 B+ 树索引
> B+ 树按**前缀有序**存储。`'张%'` 能定位到"张"开头的区间；`'%三%'` 不知道开头是什么，只能**全表扫描**。

```sql
-- ✅ 前缀匹配，能走索引
SELECT * FROM student WHERE name LIKE '张%';

-- ❌ 前导 %，全表扫描
SELECT * FROM student WHERE name LIKE '%三%';
SELECT * FROM student WHERE name LIKE '%三';

-- ⚠️ 后缀匹配也无法走普通索引
SELECT * FROM student WHERE name LIKE '%三';
```

| 模式 | 索引 |
| --- | --- |
| `'abc%'` | ✅ 前缀匹配，可走 |
| `'%abc'` | ❌ 全表 |
| `'%abc%'` | ❌ 全表 |
| `'_abc'` | ❌ 全表（首字符不确定） |
| `'abc_def'` | ✅ 可以走前缀 `abc` |
| `'%'` | ❌ 全表（且不匹配 NULL） |

> [!tip] 大表模糊搜索的正确工具
> - **全文索引** `FULLTEXT` + `MATCH ... AGAINST`（见 [[全文检索谓词]]）；
> - **Elasticsearch / OpenSearch** 等专用搜索引擎；
> - **倒排索引 / n-gram 分词**（MySQL 的 `ngram` 全文解析器支持中文）；
> - 实在要用 `LIKE '%...%'`，至少把数据量限制在可接受范围，并接受全表扫描。

---

## 七、`LIKE` vs `REGEXP` vs `FULLTEXT`

| 能力 | `LIKE` | `REGEXP` | `MATCH ... AGAINST` |
| --- | --- | --- | --- |
| 通配符 | `%` `_` | 完整正则 | 分词 + 布尔查询 |
| 前缀索引 | ✅ `'abc%'` | ❌ | ✅ 全文索引 |
| 复杂模式 | ❌ | ✅ | 有限（布尔操作符） |
| 中文分词 | ❌ | ❌ | ✅（ngram） |
| 相关性排序 | ❌ | ❌ | ✅ |
| 适用规模 | 小表/前缀 | 小表 | 大文本 |

> [!note] 选择顺序
> 前缀匹配 → `LIKE 'abc%'`；
> 复杂模式且数据量小 → `REGEXP`；
> 大文本搜索 → `FULLTEXT` 或外部搜索引擎。

---

## 八、常见错误合集

> [!failure] 把 `_` 当成"任意长度"
> `_` 只匹配一个字符。任意长度用 `%`。

> [!failure] 忘了转义字面量 `%` / `_`
> 查 `50%` 却写成 `LIKE '%50%%'`，会匹配到所有以 50 开头的内容。用 `ESCAPE`。

> [!failure] 以为 `LIKE '%'` 会返回 NULL 行
> NULL 参与 `LIKE` 得 UNKNOWN，被 `WHERE` 丢弃。

> [!failure] 在大表上用 `LIKE '%关键字%'`
> 全表扫描，数据量大时直接拖垮数据库。

> [!failure] 忽略 collation 的大小写行为
> 默认不区分大小写，需要区分时用 `BINARY` 或二进制排序规则。

> [!failure] 字符串没加引号
> `LIKE 张%` 会把 `张%` 当列名，报 `Unknown column`。

---

## 九、速查表

| 需求 | 写法 |
| --- | --- |
| 以某串开头 | `col LIKE 'abc%'` |
| 以某串结尾 | `col LIKE '%abc'`（全表） |
| 包含某串 | `col LIKE '%abc%'`（全表） |
| 恰好一个字符 | `col LIKE '_'` |
| 固定长度 | `col LIKE '___'`（3 个字符） |
| 查字面量 `%` | `col LIKE '%!%%' ESCAPE '!'` |
| 查字面量 `_` | `col LIKE '%!_%' ESCAPE '!'` |
| 区分大小写 | `BINARY col LIKE 'Abc%'` |
| 包含 NULL 行 | `col LIKE '%' OR col IS NULL` |
| 大文本搜索 | `MATCH ... AGAINST` |

> [!question] 自测三连
> 1. `_` 和 `%` 的区别是什么？`'张_'` 能匹配 `'张三丰'` 吗？
> 2. 为什么 `LIKE '%三%'` 用不上索引？什么情况下 `LIKE` 能走索引？
> 3. `LIKE '%'` 会返回 NULL 行吗？为什么？

---

> [!quote] 一句话记忆
> **`%` 匹配任意长度、`_` 只匹配一个字符；查字面量通配符要 `ESCAPE`；前导 `%` 索引失效，大表搜索用全文索引或搜索引擎；NULL 行永远不会被 `LIKE` 匹配。**

---

## 相关笔记

- [[REGEXP谓词]] —— 正则表达式匹配
- [[全文检索谓词]] —— `MATCH ... AGAINST`
- [[比较谓词]] —— 等值比较与 collation
- [[空值谓词]] —— NULL 与三值逻辑
- [[Where]] —— 模糊查询与索引失效
- [[查询优化|查询优化]] —— 前缀索引与全表扫描
