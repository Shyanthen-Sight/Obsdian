# PaaS 选项

目标只是把镜像跑起来、不想碰节点和集群时，PaaS 通常比自建划算。几家常被放在一起比较的平台，定位其实差别不小：

| 平台 | 形态 | 适合 | 注意 |
| --- | --- | --- | --- |
| Fly.io | 全球 Anycast + Firecracker 微 VM | 低延迟、多区域的小服务 | 按用量计费，卷和机器要单独管 |
| Railway | 项目式部署，连 Git 即构建 | 原型、全栈小团队 | 免费额度有限，资源上限偏小 |
| Render | 类 Heroku 的 Web Service/Worker | 常规 Web 应用、定时任务 | 免费实例会休眠，冷启动明显 |
| Cloud Run | 无服务器容器，按请求伸缩 | 流量波动大的 HTTP 服务 | 请求超时、常驻后台进程受限 |
| ECS Fargate | AWS 托管容器，按 vCPU/内存计费 | 已在 AWS、需要 VPC 集成 | 配置项多，网络和 ALB 要自己接 |

Fly.io 用 `fly.toml` 描述服务：

```toml
app = "my-web"
primary_region = "nrt"

[build]
  image = "registry.example.com/web:1.5.0"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = "suspend"
  min_machines_running = 1
```

`auto_stop_machines` 让没流量的机器挂起省钱，`min_machines_running = 1` 保证至少一台常驻，避免全部实例同时冷启动。Cloud Run 是另一种思路，命令即部署：

```bash
gcloud run deploy web \
  --image asia-northeast1-docker.pkg.dev/proj/repo/web:1.5.0 \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --min-instances 1 --max-instances 20
```

`--min-instances 1` 是花钱买冷启动，`--max-instances 20` 是防止流量突刺把账单打穿。这两个参数是 Cloud Run 成本控制的核心，很多人只设前者，结果促销流量一来费用翻十倍。

成本和锁定要一起看。PaaS 的单价通常比同等配置的 ECS 贵，贵出来的部分是省掉的人力；真正容易失控的是出站流量、跨区调用和常驻实例。锁定则体现在平台特有的配置、私有网络、定时任务和卷上。应用本身如果只是一个监听端口的容器、配置全走环境变量，迁移成本可控；一旦用了平台专有的队列、数据库和 cron 语法，迁走基本等于重写。

> [!tip] 从 PaaS 开始
> 产品早期用 PaaS 快速上线，等规模、合规或成本真的需要时，再迁到 K8s 或自建集群。别为了技术栈好看提前上复杂度。

## 相关笔记

- [[00-部署|部署]]
- [[01-Nomad|Nomad]]
- [[02-Docker Swarm|Docker Swarm]]
- [[03-Kubernetes|Kubernetes]]
- [[04-持续集成|持续集成]]
- [[03-镜像标签|镜像标签]]
- [[02-其他仓库|其他仓库]]
