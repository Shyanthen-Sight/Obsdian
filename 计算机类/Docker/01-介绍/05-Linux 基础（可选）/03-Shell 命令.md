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

> [!tip] 先确认在哪个命名空间
> 命令输出和预期不符时，先 `cat /proc/1/cgroup`、`ip addr`、`hostname` 确认自己站在哪个容器里，再谈排查。

## 为什么容器里看到的范围不一样

这些命令本身没变，变的是它们读取的内核视图。每条命令背后都对应一个命名空间：

| 命令 | 读取的命名空间 | 容器里看到 | 宿主机看到 |
| --- | --- | --- | --- |
| `ps`、`top` | PID | 只有本容器的进程，PID 1 是入口命令 | 全部进程 |
| `ss`、`netstat` | NET | 本容器的网卡、端口、连接 | 全部网络栈 |
| `ip addr`、`ip route` | NET | 本容器的接口和路由 | 全部接口和路由 |
| `df`、`mount` | MNT | 镜像层和挂载点 | 宿主挂载表 |
| `hostname` | UTS | 容器 ID 或 `--hostname` | 宿主主机名 |
| `ipcs` | IPC | 本容器的共享内存、消息队列 | 全部 IPC 对象 |
| `id` | USER | 容器内的 uid/gid 映射 | 宿主 uid/gid |
| `cat /proc/1/cgroup` | CGROUP | 本容器所在的 cgroup 路径 | 宿主 cgroup 树 |

所以“容器里 `ps` 只有两个进程”不是宿主机进程少，而是 PID 命名空间只暴露了这些。要从宿主看全貌，用 `docker top <容器>`，或者 `ps -ef | grep <进程名>`。

有两个容易忽略的点：

- `/proc/meminfo`、`/proc/cpuinfo` 不是按容器隔离的，`free`、`nproc` 经常显示的是宿主的总量。要看容器限额，读 cgroup：`cat /sys/fs/cgroup/memory.max`、`cat /sys/fs/cgroup/cpu.max`（cgroup v2）。
- `uname -r` 永远读宿主内核，`dmesg` 默认被 `CAP_SYSLOG` 挡住，容器里看不到内核日志。

## 排查命令对照

| 目的 | 宿主机 | 容器内 | 注意 |
| --- | --- | --- | --- |
| 进程 | `ps -ef`、`top` | `ps aux`、`top`、`cat /proc/1/cmdline` | 只看到本 PID 命名空间 |
| 端口 | `ss -lntp` | `ss -lntp`、`netstat -lntp` | 老镜像可能只有 `netstat` |
| 连通性 | `curl -v`、`nc -zv` | `curl -v`、`wget -qO-`、`nc -zv` | `ping` 可能被 seccomp/网络策略挡住 |
| DNS | `dig`、`getent hosts` | `getent hosts db`、`dig db`、`cat /etc/resolv.conf` | 服务名解析优先用 `getent` |
| 文件 | `ls`、`lsof`、`stat` | `ls`、`lsof`（如果有） | 看到的是镜像层和挂载点 |
| 磁盘 | `df -h`、`du -sh` | `df -h`、`du -sh /var/*` | overlay 的统计和宿主不完全一致 |
| 网络接口 | `ip addr`、`ip route` | `ip addr`、`ip route` | 只看到本网络命名空间 |
| 内核 | `dmesg`、`sysctl -a` | 多数不可用 | 缺 `CAP_SYSLOG`、`CAP_SYS_ADMIN` |
| 系统调用 | `strace -p`、`perf`、`bpftrace` | 通常没有 | 需要在宿主侧对 PID 操作 |
| 资源 | `docker stats`、cgroup 文件 | `cat /sys/fs/cgroup/...` | `free`/`nproc` 可能显示宿主值 |
| 环境变量 | `docker inspect` | `env`、`printenv` | 注意别把密钥打进日志 |

DNS 这一行值得单独说：Docker 在用户自定义网络里提供内置 DNS（`127.0.0.11`），容器可以用服务名互相解析；默认 bridge 网络没有这个能力，只能靠 IP 或 `--link`。`dig` 直接查 DNS 服务器，不一定走 `/etc/hosts`；`getent hosts db` 走 NSS，会同时看 `/etc/hosts` 和 DNS，排查服务名时更接近应用的真实行为。

## 五种补工具的方式对比

镜像里没装 `curl`、`ss`、`dig` 很常见。往生产镜像里塞一整套工具会增大体积和攻击面，更合理的做法是旁路：

| 方式 | 做法 | 优点 | 缺点 | 适用 |
| --- | --- | --- | --- | --- |
| 进容器安装 | `docker exec -it web sh`，再 `apt-get install` | 直接，工具就在目标里 | 改可写层、需要包管理器和网络、不可复现 | 本地开发、临时排查 |
| 旁路容器共享命名空间 | `docker run --rm -it --network container:web --pid container:web nicolaka/netshoot` | 不动目标镜像，工具齐全 | 只能共享指定命名空间，看不到目标文件系统 | 生产排障首选 |
| `docker debug` | `docker debug web` | 对 distroless 也能用，注入工具箱 | Docker Desktop 功能，环境不一定有 | 本地、Docker Desktop |
| 宿主 `nsenter` | `nsenter -t <pid> -n -p -m -u -i` | 用宿主全套工具，权限最全 | 需要宿主 root，风险高 | 宿主机可登录、容器无 shell |
| Kubernetes 临时容器 | `kubectl debug -it pod --image=... --target=container` | 不重建 Pod，共享目标命名空间 | 需要集群权限和临时容器支持 | K8s 环境 |

旁路容器的关键参数是 `--network container:web` 和 `--pid container:web`：前者让调试容器直接使用 `web` 的网络栈，看到的 `localhost` 和端口就是 `web` 的；后者让它能看到 `web` 的进程。注意用了 `--network container:` 之后不能再 `-p` 发布端口，因为网络命名空间归目标容器所有。

`nsenter` 的用法是先拿 PID：

```bash
pid=$(docker inspect -f '{{.State.Pid}}' web)
nsenter -t "$pid" -n -p -m -u -i ss -lntp
```

## 没有 shell 的镜像怎么办

`distroless`、`scratch` 镜像里没有 `/bin/sh`，`docker exec -it web sh` 会报：

```text
OCI runtime exec failed: exec: "/bin/sh": stat /bin/sh: no such file or directory
```

可选路径：

- `docker debug web`（Docker Desktop）直接注入调试工具箱。
- Kubernetes 用 `kubectl debug` 加临时容器，`--target` 指定目标容器。
- 宿主上用 `nsenter` 进入目标命名空间。
- 临时把静态编译的 busybox 用 `docker cp` 拷进去，用完删除；只适合救急。
- 构建一个 `debug` 变体镜像（多阶段 `--target debug`），生产镜像保持最小。

不要为了排查方便，长期往生产镜像里加 shell 和包管理器。调试能力应该来自旁路，不是来自交付物。

## 常见误判

- **`ps` 只看到一两个进程**：PID 命名空间只暴露本容器进程，不代表宿主机空闲。
- **`curl localhost` 连不上**：容器里的 `localhost` 是容器自己，不是宿主机，也不是别的容器。连别的服务用服务名或容器 IP。
- **`free` 显示内存很大**：`/proc/meminfo` 没按容器隔离，看到的是宿主内存；限额看 cgroup。
- **`nproc` 显示 CPU 很多**：同上，CPU 配额看 `cpu.max`。
- **`ping` 不通就认为网络坏**：ICMP 可能被安全组、网络策略或 seccomp 挡住，用 `nc -zv` 或 `curl` 验证 TCP。
- **`dig db` 失败但应用能连**：应用可能走 `/etc/hosts` 或 NSS，`getent hosts db` 更接近真实解析路径。
- **`ss` 看不到宿主端口**：网络命名空间不同，宿主端口要在宿主上看。
- **`docker logs` 为空**：应用把日志写进了文件，没走 stdout/stderr。

## 相关笔记

- [[00-介绍|介绍]]
- [[02-容器|容器]]
- [[04-网络|网络]]
- [[03-测试|测试]]
- [[02-调试器|调试器]]
