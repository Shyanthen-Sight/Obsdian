关键字写入顺序不能颠倒：

```sql
SELECT->>>FROM->>>WHERE->>>GROUP BY->>>HAVING->>>ORDER BY->>>LIMIT
```

select语句的执行顺序：

```sql
FROM->>>WHERE->>>GROUP BY->>>HAVING->>>SELECT的字段->>>ORDER BY->>>LIMIT
```