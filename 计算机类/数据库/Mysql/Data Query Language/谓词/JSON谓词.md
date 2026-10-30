# JSON 谓词 —— `IS JSON` / `MEMBER OF` / `JSON_CONTAINS`

> [!abstract] 一句话
> MySQL 5.7+ 提供了一组针对 `JSON` 类型的判断谓词/函数：`IS JSON` 判断是不是合法 JSON，`MEMBER OF` 判断值是否在 JSON 数组里，`JSON_CONTAINS` / `JSON_OVERLAPS` 判断包含与重叠。
> 它们让"在 JSON 字段里查数据"变得可读，但==**性能依赖生成列或多值索引，否则仍是全表扫描**==。

> [!info] 与其它笔记的分工
> 普通谓词见 [[谓词总览]]；全文检索见 [[全文检索谓词]]。
> 本篇只讲 JSON 相关的**判断条件**，不展开 JSON 函数全集。

---

## 一、`IS JSON` / `IS NOT JSON`

判断一个字符串是否是合法的 JSON 文档：

```sql
expr IS JSON
expr IS NOT JSON
```

MySQL 8.0.16+ 还支持类型限定：

```sql
expr IS JSON VALUE      -- 任意 JSON 值
expr IS JSON SCALAR     -- 标量（数字、字符串、布尔、NULL）
expr IS JSON ARRAY      -- 数组
expr IS JSON OBJECT     -- 对象
```

```sql
SELECT '{"a": 1}' IS JSON;          -- 1
SELECT '[1, 2, 3]' IS JSON;         -- 1
SELECT 'not json' IS JSON;          -- 0
SELECT '123' IS JSON;               -- 1（数字也是合法 JSON）
SELECT '123' IS JSON SCALAR;        -- 1
SELECT '123' IS JSON OBJECT;        -- 0
```

> [!warning] `IS JSON` 判断的是"文本能否解析为 JSON"
> `'123'`、`'"abc"'`、`'true'`、`'null'` 都是合法 JSON 标量。
> 如果你要的是"必须是对象"，用 `IS JSON OBJECT`，不要用 `IS JSON`。

```sql
-- 找出 json_col 中不是合法 JSON 的脏数据
SELECT * FROM t WHERE json_col IS NOT JSON;
```

> [!tip] 清洗脏数据的好工具
> 把 `VARCHAR` 迁移到 `JSON` 类型前，先用 `IS JSON` 找出无法解析的行。
> ```sql
> SELECT id, json_col FROM t WHERE json_col IS NOT JSON;
> ```

---

## 二、`MEMBER OF`：值是否在 JSON 数组里

MySQL 8.0.17+：

```sql
value MEMBER OF (json_array)
```

判断 `value` 是否是 `json_array` 的一个元素。

```sql
SELECT 2 MEMBER OF ('[1, 2, 3]');          -- 1
SELECT 4 MEMBER OF ('[1, 2, 3]');          -- 0
SELECT 'mysql' MEMBER OF ('["mysql", "redis"]'); -- 1
SELECT NULL MEMBER OF ('[1, 2, 3]');       -- NULL
```

```sql
-- 表：article.tags 是 JSON 数组，如 ["mysql", "database"]
SELECT * FROM article
WHERE 'mysql' MEMBER OF (tags);
```

> [!important] `MEMBER OF` 的右侧必须是 JSON 数组
> `MEMBER OF ('not an array')` 会报错或返回 NULL。
> 右侧可以是 JSON 列、JSON 字面量或返回 JSON 数组的表达式。

### 2.1 否定写法

```sql
WHERE NOT ('mysql' MEMBER OF (tags))
```

> [!warning] NULL 语义
> 如果 `tags` 为 NULL，`'mysql' MEMBER OF (NULL)` 返回 NULL（UNKNOWN），行会被 `WHERE` 丢弃。
> 需要保留 NULL 行时：`WHERE NOT (... ) OR tags IS NULL`。

---

## 三、`JSON_CONTAINS`：包含判断

```sql
JSON_CONTAINS(target, candidate[, path])
```

判断 `target` 是否包含 `candidate`，可指定路径。

```sql
SELECT JSON_CONTAINS('[1, 2, 3]', '2');          -- 1
SELECT JSON_CONTAINS('[1, 2, 3]', '[1, 2]');     -- 1（数组包含）
SELECT JSON_CONTAINS('{"a": 1, "b": 2}', '1', '$.a'); -- 1
SELECT JSON_CONTAINS('{"a": 1}', '{"a": 1}');    -- 1（对象包含）
SELECT JSON_CONTAINS('[1, 2, 3]', '4');          -- 0
```

| 场景 | 写法 |
| --- | --- |
| 数组包含某个标量 | `JSON_CONTAINS(arr, '2')` |
| 数组包含子数组 | `JSON_CONTAINS(arr, '[1,2]')` |
| 对象包含某键值 | `JSON_CONTAINS(obj, '{"a":1}')` |
| 指定路径 | `JSON_CONTAINS(obj, '1', '$.a')` |

```sql
-- tags 是 JSON 数组，查包含 mysql 的文章
SELECT * FROM article WHERE JSON_CONTAINS(tags, '"mysql"');
```

> [!warning] 字符串要写成 JSON 字符串
> `JSON_CONTAINS(tags, 'mysql')` 会报"Invalid JSON text"。
> 正确写法是 `JSON_CONTAINS(tags, '"mysql"')`——**外层单引号是 SQL 字符串，内层双引号是 JSON 字符串**。

---

## 四、`JSON_OVERLAPS`：是否重叠

MySQL 8.0.17+：

```sql
JSON_OVERLAPS(json_doc1, json_doc2)
```

判断两个 JSON 文档是否有交集（数组有共同元素，或对象有共同键值）。

```sql
SELECT JSON_OVERLAPS('[1, 2, 3]', '[3, 4, 5]');       -- 1
SELECT JSON_OVERLAPS('[1, 2, 3]', '[4, 5]');          -- 0
SELECT JSON_OVERLAPS('{"a": 1}', '{"a": 1, "b": 2}'); -- 1
```

```sql
-- 查 tags 与目标标签数组有任意交集的文章
SELECT * FROM article
WHERE JSON_OVERLAPS(tags, '["mysql", "redis"]');
```

> [!note] `JSON_OVERLAPS` vs `JSON_CONTAINS`
> - `JSON_CONTAINS(A, B)`：A 是否**包含** B；
> - `JSON_OVERLAPS(A, B)`：A 和 B 是否**有交集**。
> 前者是"包含"，后者是"相交"。

---

## 五、`JSON_CONTAINS_PATH`：路径是否存在

```sql
JSON_CONTAINS_PATH(json_doc, one_or_all, path[, path]...)
```

判断指定路径是否存在：

```sql
SELECT JSON_CONTAINS_PATH('{"a": 1, "b": 2}', 'one', '$.a', '$.c'); -- 1（至少一个）
SELECT JSON_CONTAINS_PATH('{"a": 1, "b": 2}', 'all', '$.a', '$.c'); -- 0（不是全部）
SELECT JSON_CONTAINS_PATH('{"a": 1}', 'all', '$.a');                -- 1
```

| 参数 | 含义 |
| --- | --- |
| `'one'` | 至少存在一个路径 |
| `'all'` | 所有路径都存在 |

```sql
-- 查有 nickname 字段的用户
SELECT * FROM user WHERE JSON_CONTAINS_PATH(profile, 'one', '$.nickname');
```

---

## 六、JSON 值的比较

MySQL 支持对 JSON 值使用普通比较运算符：

```sql
SELECT JSON_EXTRACT('{"a": 1}', '$.a') = 1;   -- 1
SELECT '{"a": 1}' = '{"a": 1}';               -- 1（JSON 比较）
```

> [!warning] JSON 比较有类型优先级
> MySQL 比较 JSON 值时，先按类型排序（`NULL` < 数字 < 字符串 < 对象 < 数组 < 布尔），再按值比较。
> 不要用 `>` / `<` 对 JSON 对象做业务排序，语义很反直觉。
> 需要按某个字段排序时，用 `->>` 提取成标量再比：
> ```sql
> ORDER BY profile->>'$.age'
> ```

---

## 七、索引：JSON 查询的性能关键

> [!danger] 直接对 JSON 列用谓词，通常全表扫描
> `JSON_CONTAINS(tags, ...)`、`MEMBER OF` 如果作用在原始 JSON 列上，无法使用普通索引。
> 数据量大时必须用**生成列 + 索引**或**多值索引**。

### 7.1 生成列 + 普通索引

```sql
ALTER TABLE article
ADD COLUMN tags_text VARCHAR(200)
    GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(tags, '$.category'))) STORED,
ADD INDEX idx_tags_text (tags_text);

-- 查询走索引
SELECT * FROM article WHERE tags_text = 'mysql';
```

### 7.2 多值索引（8.0.17+）

```sql
ALTER TABLE article
ADD INDEX idx_tags ((CAST(tags AS CHAR(20) ARRAY)));
```

多值索引可以加速：

- `MEMBER OF`
- `JSON_CONTAINS`
- `JSON_OVERLAPS`

```sql
SELECT * FROM article WHERE 'mysql' MEMBER OF (tags);
-- 可能使用 idx_tags 多值索引
```

> [!tip] 用 `EXPLAIN` 验证
> 多值索引是否生效，取决于查询写法、类型和优化器。
> ```sql
> EXPLAIN SELECT * FROM article WHERE 'mysql' MEMBER OF (tags);
> ```
> 看 `key` 是否命中多值索引。

---

## 八、常见错误合集

> [!failure] `JSON_CONTAINS(tags, 'mysql')`
> 第二个参数必须是合法 JSON，字符串要写成 `'"mysql"'`。

> [!failure] 把 `IS JSON` 当成"必须是对象"
> `'123'` 也是合法 JSON。要对象用 `IS JSON OBJECT`。

> [!failure] 对 NULL 使用 JSON 谓词
> 结果可能是 NULL（UNKNOWN），行被 `WHERE` 丢弃。需要保留时显式处理。

> [!failure] 在大表上直接查 JSON 列
> 没有生成列/多值索引就是全表扫描。

> [!failure] 用 `>` / `<` 比较 JSON 对象
> JSON 类型有内部排序规则，不是业务字段大小。先 `->>` 提取标量。

> [!failure] 忘了 MySQL 版本
> `MEMBER OF`、`JSON_OVERLAPS` 需要 8.0.17+；`IS JSON` 的类型限定需要 8.0.16+。
> 低版本要用 `JSON_CONTAINS` 等等价写法。

---

## 九、速查表

| 需求 | 写法 |
| --- | --- |
| 是否合法 JSON | `expr IS JSON` |
| 是否是 JSON 对象 | `expr IS JSON OBJECT` |
| 是否是 JSON 数组 | `expr IS JSON ARRAY` |
| 值是否在数组里 | `value MEMBER OF (json_array)` |
| 数组/对象是否包含 | `JSON_CONTAINS(target, candidate[, path])` |
| 两个 JSON 是否有交集 | `JSON_OVERLAPS(a, b)` |
| 路径是否存在 | `JSON_CONTAINS_PATH(doc, 'one'/'all', path...)` |
| 提取标量再比较 | `doc->>'$.field'` |
| 性能优化 | 生成列 + 索引 / 多值索引 |
| 检查索引 | `EXPLAIN` |

> [!question] 自测三连
> 1. `'123' IS JSON` 返回什么？为什么？
> 2. `JSON_CONTAINS(tags, 'mysql')` 为什么报错？正确写法是什么？
> 3. `JSON_CONTAINS` 和 `JSON_OVERLAPS` 的语义区别是什么？

---

> [!quote] 一句话记忆
> **`IS JSON` 判断文本能否解析为 JSON；`MEMBER OF` 判断值是否在数组里；`JSON_CONTAINS` 是包含、`JSON_OVERLAPS` 是相交；字符串参数要写成 JSON 字符串；大表查询靠生成列或多值索引。**

---

## 相关笔记

- [[谓词总览]] —— 谓词分类总览
- [[比较谓词]] —— JSON 标量的比较
- [[空值谓词]] —— NULL 与三值逻辑
- [[Where]] —— 条件过滤
- [[计算机类/数据库/Mysql/进阶函数与功能/字符串函数|字符串函数]] —— `JSON_UNQUOTE` 等
- [[管理索引|管理索引]] —— 生成列索引与多值索引
