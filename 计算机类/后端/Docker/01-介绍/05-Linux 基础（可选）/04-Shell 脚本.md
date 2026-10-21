# Shell 脚本

entrypoint 脚本常用来做启动前准备：等数据库、渲染配置、跑迁移、再启动主进程。这类脚本写错，表现往往是"容器起不来"或"`docker stop` 要等 10 秒才杀"。

## 三条硬要求

```bash
#!/bin/sh
set -eu

: "${DATABASE_URL:?DATABASE_URL is required}"

until pg_isready -h db -U app >/dev/null 2>&1; do
  echo "waiting for db..."
  sleep 1
done

exec "$@"
```

`set -e` 让命令失败立即退出，别带着半初始化状态启动应用；`set -u` 把未定义变量当错误，配置漏了能早发现。`${VAR:?message}` 是更明确的必填检查。

`exec "$@"` 是关键：它用主进程替换当前 shell，让应用的 PID 变成 1。这样 `docker stop` 发的 SIGTERM 能直接到应用，应用才有机会优雅退出。写成 `npm start` 或 `./app &`，PID 1 是 shell，信号可能收不到，Docker 等 10 秒后发 SIGKILL，退出码 137。

Dockerfile 里配套写：

```dockerfile
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["node", "server.js"]
```

`ENTRYPOINT` 收固定脚本，`CMD` 提供默认参数；`docker run image --help` 会把 `--help` 作为 `"$@"` 传进去。

## 信号与超时

自己写 trap 要小心，别把 SIGTERM 吞掉：

```bash
./server &
child=$!
trap 'echo shutting down; kill -TERM "$child"; wait "$child"' TERM INT
wait "$child"
```

`$child` 是后台进程的 PID；没有 `wait`，脚本可能在子进程结束前就退出。更省事的做法是引入 tini 或 dumb-init 当 PID 1，它们负责转发信号和回收僵尸进程：

```dockerfile
ENTRYPOINT ["/sbin/tini", "--", "/docker-entrypoint.sh"]
```

等依赖也别无限等。CI 或编排环境里，数据库可能永远起不来，脚本挂死比报错更难查。给循环加次数上限，或者用应用自身的重试机制。

> [!warning] 迁移脚本要幂等
> 每次启动都跑迁移很常见，但脚本必须能重复执行。用版本表、`IF NOT EXISTS`，别用会重复插入数据的语句。

## 相关笔记

- [[00-介绍|介绍]]
- [[03-Shell 命令|Shell 命令]]
- [[01-Dockerfile|Dockerfile]]
- [[03-运行时配置|运行时配置]]
- [[01-数据库|数据库]]
