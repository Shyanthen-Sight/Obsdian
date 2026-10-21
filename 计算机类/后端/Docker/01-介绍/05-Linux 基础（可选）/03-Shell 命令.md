# Shell 命令

容器里排查问题，还是那几条老命令，只是范围变了：`ps` 只看得到当前 PID 命名空间里的进程，`ss` 看到的是当前网络命名空间的端口。

| 目的 | 命令 |
| --- | --- |
| 进程 | `ps aux`、`top`、`cat /proc/1/cmdline` |
| 端口 | `ss -lntp`、`netstat -lntp`（老镜像） |
| 连通性 | `curl -v`、`wget -qO-`、`nc -zv` |
| DNS | `getent hosts db`、`dig db`、`cat /etc/resolv.conf` |
| 磁盘 | `df -h`、`du -sh /var/*` |
| 网络接口 | `ip addr`、`ip route` |

## 镜像里没这些工具怎么办

`alpine` 只有 busybox，`distroless` 连 shell 都没有。别为了排查往生产镜像里塞一整套工具，起一个临时调试容器，共享目标容器的网络命名空间：

```bash
docker run --rm -it --network container:web nicolaka/netshoot
# 在调试容器里
ss -lntp
curl -v http://localhost:80
dig db
```

`--network container:web` 让调试容器直接使用 `web` 的网络栈，看到的 `localhost` 和端口就是 `web` 的。也可以共享 PID 命名空间（`--pid container:web`），用 `ps` 看目标进程。

Docker Desktop 用户还有更轻的办法：

```bash
docker debug web
```

它往容器里注入一套调试工具，不修改镜像。生产环境不一定有，临时容器更通用。

## 两个常见误判

在容器里 `ps` 只看到一两个进程，不代表宿主机上只有这些。容器的 PID 1 是主进程，其他进程可能被 PID 命名空间隔离掉。要看全貌，在宿主机执行 `ps -ef | grep <进程名>`，或者 `docker top <容器>`。

另一个坑是 `curl localhost`：容器里的 localhost 是容器自己，不是宿主机，也不是别的容器。连别的服务用容器名或网络别名，见 [[04-网络|docker network]]。

> [!tip] 先确认在哪个命名空间
> 命令输出和预期不符时，先 `cat /proc/1/cgroup`、`ip addr`、`hostname` 确认自己站在哪个容器里，再谈排查。

## 相关笔记

- [[00-介绍|介绍]]
- [[02-容器|容器]]
- [[04-网络|网络]]
- [[03-测试|测试]]
- [[02-调试器|调试器]]
