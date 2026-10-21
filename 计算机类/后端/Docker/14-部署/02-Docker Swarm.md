# Docker Swarm

Swarm 是 Docker Engine 内置的编排模式，不用额外装组件，`docker swarm init` 就把当前机器变成 manager。它的卖点是概念少：节点、service、task，跟 `docker run` 的参数几乎一一对应。

初始化时最好显式指定 `--advertise-addr`，否则多网卡机器可能广播错地址，其他节点连不上：

```bash
docker swarm init --advertise-addr 10.0.1.10
docker swarm join-token worker
docker swarm join --token SWMTKN-1-xxxx 10.0.1.10:2377
docker node ls
```

worker 用普通 token，manager 用 `docker swarm join-token manager` 生成的 token。manager 之间靠 Raft 选主，数量取 3 或 5，偶数没有意义，2 个 manager 反而比 1 个更容易失去 quorum。

服务用 `docker service create` 声明，参数和 `docker run` 很像，多了副本与更新策略：

```bash
docker service create \
  --name web \
  --replicas 3 \
  --publish published=80,target=8080 \
  --update-delay 10s \
  --update-parallelism 1 \
  --update-failure-action rollback \
  registry.example.com/web:1.4.2

docker service scale web=5
docker service update --image registry.example.com/web:1.5.0 web
docker service ps web
```

`--update-parallelism 1` 表示一次只换一个 task，`--update-delay 10s` 是两批之间的间隔，失败时按 `rollback` 回滚到上一个版本。`docker service ps web` 能看到每个副本落在哪个节点、是 running 还是 failed，比 `service ls` 有用得多。

跨节点通信要 overlay 网络。`--attachable` 让普通容器也能接进来，本地调试方便：

```bash
docker network create --driver overlay --attachable app-net
docker service create --name api --network app-net registry.example.com/api:2.1
```

发布端口走的是 ingress 网络，任意节点收到 80 端口流量都会转发到健康副本，所以前面挂不挂 LB 都能工作。

限制同样明显。没有内置自动扩缩容，指标要外挂；secret 只是挂进容器的文件，缺少 K8s 那样的加密存储和细粒度 RBAC；没有 CRD/Operator 生态，复杂发布、金丝雀、流量切分都得自己拼。社区这些年基本处于维护状态，新特性很少。

> [!warning] 别把 Swarm 当 K8s 用
> 它的价值是"十分钟拿到多机编排"，不是替代 K8s。已经有 K8s 的团队再引入 Swarm，只会多一套要维护的东西。

## 相关笔记

- [[00-部署|部署]]
- [[01-Nomad|Nomad]]
- [[03-Kubernetes|Kubernetes]]
- [[04-PaaS 选项|PaaS 选项]]
- [[00-网络|网络]]
- [[03-运行时配置|运行时配置]]
