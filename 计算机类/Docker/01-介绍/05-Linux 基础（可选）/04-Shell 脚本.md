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

## PID 1 与信号：为什么 `exec "$@"` 是关键

Linux 对 PID 1 有特殊处理：如果一个信号没有安装处理器，默认动作会被忽略。也就是说，shell 作为 PID 1 时，收到 SIGTERM 可能既不退出、也不转发给子进程。Docker 默认等 10 秒，然后发 SIGKILL，退出码从 143 变成 137。

对比三种写法：

```sh
# 写法一：shell 是 PID 1，npm 是子进程
#!/bin/sh
npm start
```

```sh
# 写法二：shell 是 PID 1，应用后台运行
#!/bin/sh
npm start &
wait
```

```sh
# 写法三：应用替换 shell，应用成为 PID 1
#!/bin/sh
exec "$@"
```

写法一里 SIGTERM 发给 shell，shell 未必转发，应用可能被直接 SIGKILL。写法二多了 `wait`，shell 会等子进程，但信号转发仍然要靠 trap，`wait` 被信号打断后的行为也要处理。写法三最干净：`exec` 用应用替换当前 shell，PID 不变，应用直接收到 SIGTERM，只要它装了处理器就能优雅退出。

`exec "$@"` 还有一个好处：`CMD` 里的参数会原样传进来。`ENTRYPOINT` 固定脚本，`CMD` 提供默认命令，`docker run image --help` 会把 `--help` 作为 `"$@"` 传给脚本。

如果确实需要多进程，才自己写 trap：

```sh
#!/bin/sh
set -eu

./server &
child=$!

term() {
  echo "shutting down"
  kill -TERM "$child" 2>/dev/null || true
}
trap term TERM INT

wait "$child"
```

注意 `$!` 拿的是后台进程 PID，`wait` 保证脚本不会在子进程结束前退出。更省事的做法是用 tini/dumb-init 当 PID 1，它们负责转发信号和回收僵尸进程。

另外，`npm start` 这类包装命令自己也可能再 fork 一个 node 进程，信号转发链更长。能直接 `exec node server.js` 就不要经过 npm。

## ENTRYPOINT 与 CMD 的组合

这两个指令经常被混用，实际规则是“ENTRYPOINT 定可执行文件，CMD 定默认参数”：

| ENTRYPOINT | CMD | 最终执行 | PID 1 | `docker run image --help` |
| --- | --- | --- | --- | --- |
| 无 | `["node","server.js"]` | `node server.js` | node | 替换 CMD，变成 `node --help` |
| `["/entry.sh"]` | `["node","server.js"]` | `/entry.sh node server.js` | entry.sh（exec 后是 node） | 替换 CMD，变成 `/entry.sh --help` |
| `["node"]` | `["server.js"]` | `node server.js` | node | 变成 `node --help` |
| shell 形式 `node server.js` | 任意 | `/bin/sh -c "node server.js"` | sh | CMD 参数被忽略 |

几条容易踩的规则：

- **exec 形式**（`["node","server.js"]`）直接启动进程，信号能到应用；**shell 形式**（`node server.js`）会包一层 `/bin/sh -c`，PID 1 是 sh，信号容易丢。
- 如果基础镜像定义了 `ENTRYPOINT`，你在子镜像里再写 `CMD`，`CMD` 是作为参数传给那个 `ENTRYPOINT` 的，不是独立命令。
- `docker run --entrypoint` 可以覆盖 `ENTRYPOINT`，但会清空原来的 `CMD` 语义，参数要自己补齐。
- 想临时调试，`docker run --rm -it --entrypoint sh image` 比改 Dockerfile 快。

最常用的组合就是“ENTRYPOINT 放启动脚本，CMD 放默认命令”，脚本里 `exec "$@"` 收尾。

## 五种 init 方案对比

| 方案 | 体积 | 信号转发 | 僵尸回收 | 多进程 | 复杂度 |
| --- | --- | --- | --- | --- | --- |
| 手写 trap | 0 | 自己实现 | 自己做 | 可以 | 容易漏边界 |
| tini | ~20 KB | 是 | 是 | 单主进程 | 低 |
| dumb-init | ~20 KB | 是 | 是 | 单主进程 | 低 |
| s6-overlay | 数 MB | 是 | 是 | 多服务 | 中高 |
| supervisord | 数 MB（Python） | 部分 | 是 | 多服务 | 中 |

**tini** 是最常见的轻量 init：`docker run --init` 会自动注入它，也可以显式写进镜像：

```dockerfile
ENTRYPOINT ["/sbin/tini", "--", "/docker-entrypoint.sh"]
```

它作为 PID 1 启动，转发 SIGTERM/SIGINT 给子进程，回收孤儿进程，子进程退出后自己退出。

**dumb-init** 定位类似，适合 shell 脚本入口，`--` 后面的命令作为子进程运行。

**s6-overlay** 适合一个容器里要跑多个长期服务、需要依赖顺序和自动重启的场景，比如 nginx + php-fpm。它提供真正的服务监督，但复杂度和镜像体积都上去了。

**supervisord** 很常见，但它是进程管理器，不是完整的 init：信号转发、僵尸回收、退出码传播都不如 tini/s6 严谨。能用单进程解决就不要上 supervisor。

大多数 Web 应用根本不需要这些：只要入口命令是前台运行、PID 1 是应用、应用处理 SIGTERM，就足够了。需要 init 的信号是“应用会 fork 子进程”或“需要回收孤儿进程”。

## 等待依赖：别用 sleep 赌时间

`sleep 10` 的问题是它既可能不够，也可能白等：数据库启动快时浪费 10 秒，慢时 10 秒后又失败。更好的做法是轮询一个真实信号，并设置上限：

```sh
#!/bin/sh
set -eu

attempts=0
until pg_isready -h db -U app >/dev/null 2>&1; do
  attempts=$((attempts + 1))
  if [ "$attempts" -ge 30 ]; then
    echo "database not ready after 30s" >&2
    exit 1
  fi
  sleep 1
done

exec "$@"
```

几个细节：

- `pg_isready` 只检查 PostgreSQL 是否接受连接，不验证用户名密码；要验证认证，用 `psql -c 'select 1'`。
- Redis 用 `redis-cli ping`，HTTP 服务用 `curl -f`，通用 TCP 用 `nc -z`。
- 无限等待比报错更难查：CI 里数据库永远起不来，脚本会一直挂着。给次数上限或超时。
- compose 的 `depends_on: condition: service_healthy` 只保证启动顺序，不保证应用层可用；应用自己仍要有重试和退避。
- Kubernetes 里可以用 initContainer 等依赖，但同样要设置超时，避免 Pod 永远 Pending。

## 迁移脚本要幂等

每次启动都跑迁移很常见，但多副本同时启动时，迁移会被并发执行。要求两条：

1. **可重复执行**：用版本表记录已执行的迁移，用 `IF NOT EXISTS`、`ON CONFLICT`、唯一约束，避免重复插入。
2. **互斥执行**：用数据库 advisory lock（PostgreSQL `pg_advisory_lock`、MySQL `GET_LOCK`）或独立的迁移 Job/initContainer，保证同一时间只有一个实例在迁移。

更稳妥的做法是把迁移从应用启动流程里拆出来，作为部署流水线的一步；应用只负责启动，迁移失败就阻止发布。启动时自动迁移适合小项目，但要有回滚预案和备份。

## 脚本本身的几个坑

- **CRLF 换行**：Windows 上编辑的脚本带 `\r`，在 Linux 里报 `bad interpreter: no such file or directory`。用 `.gitattributes` 或编辑器统一 LF。
- **BOM**：UTF-8 BOM 会让 `#!/bin/sh` 失效，保存时选无 BOM。
- **执行权限**：`COPY` 进来的脚本可能没有 `+x`，Dockerfile 里补 `RUN chmod +x`，或者用 `COPY --chmod=755`（BuildKit）。
- **`set -e` 的边界**：管道里只有最后一个命令的退出码生效，必要时加 `set -o pipefail`（bash/ash 支持情况不同）；`if`、`while` 条件里的失败不会触发退出。
- **变量引用**：`"$VAR"`、`"$@"` 加引号，避免空格和通配符展开。
- **`#!/bin/sh` 还是 bash**：Alpine 的 `/bin/sh` 是 busybox ash，不支持 bash 的数组、`[[ ]]` 等语法；需要 bash 就显式装 bash 并改 shebang。

## 相关笔记

- [[00-介绍|介绍]]
- [[03-Shell 命令|Shell 命令]]
- [[01-Dockerfile|Dockerfile]]
- [[03-运行时配置|运行时配置]]
- [[01-数据库|数据库]]
