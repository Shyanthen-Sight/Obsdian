# docker compose

服务一多，一长串 `docker run` 很快就没人维护得动。compose 把这些参数收进一份 `compose.yaml`，容器、网络、卷、依赖关系都声明出来，起停只剩一条命令。

```yaml
services:
  web:
    build: .
    ports:
      - "8080:80"
    environment:
      DATABASE_URL: postgres://app:secret@db:5432/app
    depends_on:
      db:
        condition: service_healthy
    profiles: ["app"]

  db:
    image: postgres:16
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: secret
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d app"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 10s

volumes:
  pgdata:
```

`services` 下的键名就是服务名，同时会成为同一网络里的 DNS 名。web 连 `db:5432` 即可，不用关心容器 IP。`volumes` 声明命名卷；不写 `networks` 时 compose 自动建一个 `<项目名>_default`。

## 依赖和健康检查

普通 `depends_on: [db]` 只保证启动顺序，db 进程还没接受连接，web 就已经开始连了。加上 `condition: service_healthy` 后，compose 会等 healthcheck 通过再启动 web。`start_period` 是给慢启动服务的宽限，这期间的失败不计入 `retries`。

healthcheck 的 `test` 用 `CMD-SHELL` 可以写管道和变量，用 `CMD` 则是直接 exec、不经过 shell。退出码 0 为健康，1 为不健康，2 保留不用。

## profiles

不是所有服务每次都要起。给调试工具、一次性任务加 `profiles`，默认 `up` 不会创建它们。假设有个只在排查时用的 `psql` 服务：

```bash
docker compose --profile debug up -d
docker compose --profile debug run --rm psql
```

没写 `profiles` 的服务始终启动；写了但没激活的连容器都不会创建。适合放 adminer、mailhog、数据迁移这类偶尔用的东西。

## 日常命令

```bash
docker compose up -d          # 构建并后台启动，配置变了会重建
docker compose logs -f web    # 跟踪某个服务的日志，不写服务名是全部
docker compose exec db psql -U app -d app   # 在运行中的容器里执行命令
docker compose ps             # 看状态和端口
docker compose down           # 停止并删除容器、网络
docker compose down -v        # 连命名卷一起删
```

`up -d` 会对比配置和现有容器，需要时重建；`restart` 不读新配置，改完 YAML 要用 `up -d`。`exec` 要求容器正在运行，服务没起或者已经退出就改用 `run --rm`，它会新建一个一次性容器。

> [!warning] down -v 会删数据
> `-v` 删的是 compose 文件里声明的命名卷，数据库数据也在里面。本地重置环境很好用，对着有数据的环境敲之前先看一眼 `docker volume ls`。

`-f` 指定文件，`-p` 指定项目名。同一目录想同时跑两套环境，用 `-p` 隔离，否则容器名、网络名和卷名都会撞。

## 相关笔记

- [[00-运行容器|运行容器]]
- [[01-docker run 命令|docker run]]
- [[03-运行时配置|运行时配置]]
- [[01-数据库|数据库]]
- [[04-网络|网络]]
- [[02-卷挂载|卷挂载]]
