# Nomad

Nomad 是 HashiCorp 出的调度器。和 Swarm 一样是单二进制、装完就能跑，但它的调度对象不限于容器：普通进程、Java jar、批处理任务、系统服务都能塞进同一套 job 里。集群分 server 和 client 两种角色，server 用 Raft 保存状态，生产环境一般 3 或 5 个起步，client 才是真正跑任务的地方。

一个最小的 HCL job 长这样：

```hcl
job "web" {
  datacenters = ["dc1"]
  type        = "service"

  group "app" {
    count = 3

    network {
      port "http" { to = 8080 }
    }

    task "server" {
      driver = "docker"

      config {
        image = "registry.example.com/web:1.4.2"
        ports = ["http"]
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
```

`group` 是调度单位，`count` 控制副本数；`task` 里的 `driver = "docker"` 表示用 Docker 跑，换成 `exec` 或 `java` 就是非容器负载。`network` 里声明的端口由 Nomad 分配，服务发现可以靠内置的，也可以接 Consul。提交和日常操作：

```bash
nomad job run web.nomad
nomad job status web
nomad alloc logs <alloc-id> server
nomad job scale web 5
```

`alloc` 是分配实例，相当于 K8s 的 Pod，`nomad alloc logs` 是排障时最常用的命令。滚动更新由 job 里的 `update` 块控制，`stagger` 是批次间隔，`max_parallel` 是并发替换数，`healthy_deadline` 是等待健康检查的上限。没配健康检查时，Nomad 只能按时间猜任务是否起来，发布风险会明显变大。

和 Kubernetes 比，Nomad 少了 Pod、CRD、Operator 这一整套抽象，二进制几十 MB，概念两页纸能写完；代价是生态薄，Ingress、自动扩缩容、细粒度 RBAC 都要自己补或买 Enterprise。它更像一个纯粹的调度器，K8s 更像一个操作系统。已经有 Consul/Vault 的团队用起来最顺，因为服务发现和密钥管理是现成的。

> [!warning] 网络是常见坑
> Nomad 默认用 host 网络，容器端口直接绑在宿主机上。同一台机器上跑多个副本容易端口冲突，要么让 `port` 动态分配，要么上 Consul Connect 做 service mesh。

## 相关笔记

- [[00-部署|部署]]
- [[02-Docker Swarm|Docker Swarm]]
- [[03-Kubernetes|Kubernetes]]
- [[04-PaaS 选项|PaaS 选项]]
- [[00-网络|网络]]
- [[02-其他仓库|其他仓库]]
