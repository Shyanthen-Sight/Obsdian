# REGEXP 谓词 —— 正则表达式匹配

> [!abstract] 一句话
> `expr REGEXP pattern` 用**正则表达式**做模式匹配，能力比 `LIKE` 强得多：字符类、重复次数、分支、锚点都能写。
> 代价是==**几乎无法使用普通索引，基本等于全表扫描**==，只适合小数据量或预过滤后的结果集。

> [!info] 与其它笔记的分工
> 简单通配匹配见 [[LIKE谓词]]；大文本分词检索见 [[全文检索谓词]]。
> 本篇讲 MySQL 8.0 的 `REGEXP` / `RLIKE`、常用元字符、转义、大小写和性能。

---

## 一、语法

```sql
expr REGEXP pattern
expr NOT REGEXP pattern
expr RLIKE pattern          -- REGEXP 的同义词
expr NOT RLIKE pattern
```

MySQL 8.0 还提供函数形式，可以指定匹配选项：

```sql
REGEXP_LIKE(expr, pattern[, match_type])
```

```sql
SELECT 'abc123' REGEXP '^[a-z]+[0-9]+$';   -- 1
SELECT 'abc' NOT REGEXP '^[0-9]+$';        -- 1
SELECT REGEXP_LIKE('ABC', 'abc', 'c');     -- 0（c = 区分大小写）
```

> [!note] 返回值
> 匹配返回 `1`，不匹配返回 `0`，任一操作数为 NULL 返回 `NULL`。
> 在 `WHERE` 里同样是"只保留 TRUE"。

---

## 二、常用元字符

| 元字符 | 含义 | 示例 |
| --- | --- | --- |
| `.` | 任意单个字符（默认不含换行） | `'a.c'` 匹配 `abc` |
| `*` | 前一项 0 次或多次 | `'ab*'` 匹配 `a`、`ab`、`abb` |
| `+` | 前一项 1 次或多次 | `'ab+'` 匹配 `ab`、`abb` |
| `?` | 前一项 0 次或 1 次 | `'ab?'` 匹配 `a`、`ab` |
| `{n}` | 前一项恰好 n 次 | `'a{3}'` 匹配 `aaa` |
| `{n,}` | 至少 n 次 | `'a{2,}'` |
| `{n,m}` | n 到 m 次 | `'a{2,4}'` |
| `[...]` | 字符类，任选其一 | `'[abc]'` |
| `[^...]` | 排除字符类 | `'[^0-9]'` |
| `^` | 字符串开头 | `'^张'` |
| `$` | 字符串结尾 | `'三$'` |
| `|` | 或 | `'cat|dog'` |
| `(...)` | 分组 | `'(ab)+'` |
| `\d` | 数字（ICU） | `'\\d+'` |
| `\w` | 字母/数字/下划线 | `'\\w+'` |
| `\s` | 空白字符 | `'\\s+'` |

> [!warning] 反斜杠要写两层
> SQL 字符串字面量里 `\` 本身是转义符。要传给正则引擎一个 `\d`，SQL 里要写 `'\\d'`。
> ```sql
> SELECT '123' REGEXP '\\d+';    -- 1
> SELECT '123' REGEXP '[0-9]+';  -- 1（更易读，推荐）
> ```
> 能用字符类 `[0-9]`、`[a-zA-Z]` 时，优先用它，少踩转义的坑。

---

## 三、`REGEXP` 是"包含"匹配，不是"完全匹配"

> [!important] 不加锚点，只要求子串匹配
> ```sql
> SELECT 'abc123' REGEXP 'abc';    -- 1（包含即可）
> SELECT 'abc123' REGEXP '^abc$';  -- 0（要求整个字符串就是 abc）
> SELECT 'abc123' REGEXP '^abc';   -- 1（以 abc 开头）
> SELECT 'abc123' REGEXP '123$';   -- 1（以 123 结尾）
> ```
> 想要"整个字段完全符合"，必须显式加 `^...$`。

---

## 四、大小写敏感

默认行为取决于列的 collation：

```sql
-- 非二进制、大小写不敏感的 collation
SELECT 'ABC' REGEXP 'abc';        -- 1
SELECT BINARY 'ABC' REGEXP 'abc'; -- 0

-- 8.0 函数形式，显式指定
SELECT REGEXP_LIKE('ABC', 'abc', 'i');  -- 1（不区分）
SELECT REGEXP_LIKE('ABC', 'abc', 'c');  -- 0（区分）
```

| 写法 | 行为 |
| --- | --- |
| `col REGEXP 'abc'` | 跟随 collation |
| `BINARY col REGEXP 'abc'` | 区分大小写 |
| `REGEXP_LIKE(col, 'abc', 'i')` | 强制不区分 |
| `REGEXP_LIKE(col, 'abc', 'c')` | 强制区分 |

> [!tip] 生产代码建议显式指定
> 不要把"大小写是否敏感"交给默认 collation。用 `REGEXP_LIKE(..., 'c')` 或 `BINARY` 把意图写死。

---

## 五、实用示例

### 5.1 手机号（中国大陆，简化）

```sql
SELECT * FROM user WHERE phone REGEXP '^1[3-9][0-9]{9}$';
```

### 5.2 邮箱（简化校验）

```sql
SELECT * FROM user
WHERE email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$';
```

> [!warning] 正则校验邮箱只能"挡明显错误"
> 真正严格的邮箱格式非常复杂，且业务上通常只需"包含 @ 且域名有点"。
> 不要为了追求完美正则写出无法维护的表达式；最终校验应放在应用层或发验证邮件。

### 5.3 身份证号（18 位，简化）

```sql
SELECT * FROM person
WHERE id_card REGEXP '^[1-9][0-9]{5}(19|20)[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])[0-9]{3}[0-9Xx]$';
```

### 5.4 包含连续数字

```sql
SELECT * FROM log WHERE content REGEXP '[0-9]{3,}';
```

### 5.5 多个关键词任一命中

```sql
SELECT * FROM article WHERE title REGEXP 'MySQL|PostgreSQL|Redis';
```

---

## 六、`REGEXP` 与 `LIKE` 的取舍

| 需求 | 推荐 |
| --- | --- |
| 前缀/后缀/包含固定字符串 | `LIKE`（更简单，前缀可走索引） |
| 字符类、重复次数、分支 | `REGEXP` |
| 严格格式校验 | `REGEXP` 或应用层 |
| 大文本关键词搜索 | `FULLTEXT` / 搜索引擎 |
| 大数据量 + 复杂模式 | 尽量别在数据库做 |

```sql
-- LIKE 能表达的，别用 REGEXP
WHERE name LIKE '张%'          -- ✅ 可走索引
WHERE name REGEXP '^张'        -- ❌ 全表，且没必要

-- REGEXP 才值得的场景
WHERE phone REGEXP '^1[3-9][0-9]{9}$'
```

> [!tip] 能用 `LIKE` 就用 `LIKE`
> `LIKE` 至少在前缀匹配时能走索引；`REGEXP` 几乎总是全表扫描。
> 只有当模式确实需要正则能力时，才付出这个代价。

---

## 七、性能

> [!danger] `REGEXP` 基本等于全表扫描
> MySQL 无法把正则表达式转换成 B+ 树的区间条件，只能**逐行取出字段值、交给正则引擎匹配**。
> 表越大越慢，而且正则本身也可能很耗时（灾难性回溯）。

优化思路：

1. **先用可索引的条件缩小范围**，再对少量结果做正则：
   ```sql
   SELECT * FROM user
   WHERE created_at >= '2026-01-01'
     AND phone REGEXP '^1[3-9][0-9]{9}$';
   ```
2. **能改成前缀 `LIKE` 就改**：`LIKE '138%'` 比 `REGEXP '^138'` 快得多。
3. **把正则移到应用层**：数据库只负责取数。
4. **用生成列 + 索引**：如果某个正则结果需要频繁查询，可考虑把"是否匹配"固化成生成列并建索引（仅适用于固定模式）。
5. **大文本搜索用 `FULLTEXT` 或 Elasticsearch**。

> [!warning] 正则灾难性回溯
> 像 `(a+)+b` 这类嵌套量词，在长字符串上可能指数级回溯，拖垮数据库连接。
> 写正则时避免嵌套量词，必要时限制输入长度。

---

## 八、常见错误合集

> [!failure] 以为 `REGEXP 'abc'` 是完全匹配
> 它是子串匹配。完全匹配要写 `'^abc$'`。

> [!failure] 反斜杠只写一层
> `'\d'` 在 SQL 字符串里会被转义处理，应写 `'\\d'`，或改用 `[0-9]`。

> [!failure] 在大小写敏感的列上期待不敏感
> 行为由 collation 决定，需要时用 `REGEXP_LIKE(..., 'i')`。

> [!failure] 在大表上直接跑复杂正则
> 全表扫描 + 正则回溯，容易拖垮数据库。先缩小范围或移到应用层。

> [!failure] 用 `REGEXP` 替代简单 `LIKE`
> `LIKE '张%'` 能走索引，`REGEXP '^张'` 不能。

> [!failure] 正则写得太复杂
> 邮箱、URL 的"完美正则"往往不可维护。校验分层：数据库挡明显错误，应用层做业务校验。

---

## 九、速查表

| 需求 | 写法 |
| --- | --- |
| 包含某串 | `col REGEXP 'abc'` |
| 完全匹配 | `col REGEXP '^abc$'` |
| 开头匹配 | `col REGEXP '^abc'` |
| 结尾匹配 | `col REGEXP 'abc$'` |
| 数字 | `col REGEXP '[0-9]+'` 或 `'\\d+'` |
| 手机号 | `col REGEXP '^1[3-9][0-9]{9}$'` |
| 多个关键词 | `col REGEXP 'a|b|c'` |
| 不匹配 | `col NOT REGEXP '...'` |
| 区分大小写 | `REGEXP_LIKE(col, '...', 'c')` |
| 不区分大小写 | `REGEXP_LIKE(col, '...', 'i')` |
| 性能优化 | 先用索引条件缩小范围，再正则 |

> [!question] 自测三连
> 1. `REGEXP 'abc'` 和 `REGEXP '^abc$'` 有什么区别？
> 2. 为什么 `REGEXP` 用不上普通索引？`LIKE 'abc%'` 为什么可以？
> 3. SQL 里写 `\d` 为什么要写成 `'\\d'`？有没有更易读的替代？

---

> [!quote] 一句话记忆
> **`REGEXP` 是子串正则匹配，完全匹配要加 `^...$`；反斜杠写两层或改用 `[0-9]`；大小写看 collation；它几乎总是全表扫描，能用前缀 `LIKE` 就别用正则。**

---

## 相关笔记

- [[LIKE谓词]] —— `%` / `_` 通配匹配
- [[全文检索谓词]] —— 大文本关键词搜索
- [[比较谓词]] —— collation 与大小写
- [[Where]] —— 条件过滤
- [[计算机类/数据库/Mysql/进阶函数与功能/字符串函数|字符串函数]] —— `REGEXP_LIKE` 等字符串处理
- [[查询优化|查询优化]] —— 索引失效与全表扫描
