# docker run

`docker run` 做的事可以拆成三步：从镜像创建一个可写容器层（create）、启动它（start）、附着到它的输出（attach）。参数都写在镜像名之前，镜像名之后的第一个词开始，全部是容器里要执行的命令。

```bash
docker run -d --name web \
  -p 8080:80 \
  -v webdata:/usr/share/nginx/html \
  --env TZ=Asia/Shanghai \
  --restart unless-stopped \
  --network app-net \
  nginx:1.27
```

## 高频参数

- `-d`：后台运行，命令立刻返回容器 ID。进程需要留在前台时别加，比如 `docker run -it ubuntu bash`。
- `-it`：`-i` 保持 stdin 打开，`-t` 分配伪终端，两个一起用才有交互式 shell。只加 `-t` 会得到一个没有输入的终端。
- `--name`：给容器起名，后续 `exec`、`logs`、`stop` 都能直接用。不写会随机生成，比如 `vigilant_hopper`。
- `-p 8080:80`：宿主 8080 映射到容器 80。只写 `-p 80` 会让 Docker 随机挑宿主端口，用 `docker port web` 查。
- `-v webdata:/usr/share/nginx/html`：命名卷挂载。写绝对路径就是绑定挂载，例如 `-v $(pwd)/html:/usr/share/nginx/html`。
- `--env TZ=Asia/Shanghai`：注入环境变量，等价写法 `-e`。变量多时改用 `--env-file .env`。
- `--restart unless-stopped`：退出后自动拉起，手动 stop 的除外。`always` 连手动 stop 的也会在 daemon 重启后启动。
- `--network app-net`：加入自定义网络，容器之间可以用名字互相解析。
- `--entrypoint`：覆盖镜像的 ENTRYPOINT，镜像名后面的内容会作为新 entrypoint 的参数。

## entrypoint 和命令怎么拼

镜像定义了 `ENTRYPOINT ["nginx"]`、`CMD ["-g", "daemon off;"]`，执行 `docker run nginx:1.27 -T` 时，最终命令是 `nginx -T`。想完全绕开原入口，用 `--entrypoint sh`，镜像名后的 `-c "..."` 才是 sh 的参数。

> [!tip] 参数位置
> `docker run nginx -p 8080:80` 不会映射端口，`-p 8080:80` 会被原样传给容器内的 nginx，通常直接报错。看到 unknown option，先检查参数是不是写到了镜像名后面。

## 退出码

容器退出后 `docker ps -a` 能看到状态码：

| 退出码 | 常见原因 |
| --- | --- |
| 0 | 命令正常结束 |
| 1 | 应用自身报错，看 `docker logs` |
| 125 | docker run 本身失败，参数或 daemon 有问题 |
| 126 | 命令存在但不可执行，权限不对 |
| 127 | 命令不存在，entrypoint 或 PATH 写错 |
| 137 | 收到 SIGKILL，常见于 OOM 或 `docker kill` |
| 143 | 收到 SIGTERM，`docker stop` 的正常结果 |

看到 137 先查 `docker inspect <容器> --format '{{.State.OOMKilled}}'`：是 `true` 就加内存或查泄漏，不是的话再看是不是有人手动 kill。

`docker run` 每次都会创建新容器，同名会报 `Conflict`。操作已有容器用 `start/stop/restart/exec/logs`，别反复 run。

## 相关笔记

- [[00-运行容器|运行容器]]
- [[02-docker compose 命令|docker compose]]
- [[03-运行时配置|运行时配置]]
- [[02-容器|容器]]
- [[03-绑定挂载|绑定挂载]]
- [[04-网络|docker network]]
