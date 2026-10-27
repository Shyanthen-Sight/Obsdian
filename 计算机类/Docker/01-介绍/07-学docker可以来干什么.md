# 学 Docker 可以来干什么

学 Docker 最实际的回报，不是背下一串命令，而是把"运行环境"变成一件可以打包、复制、回滚的东西。同一套能力落在不同人手里是不同的活：后端用它交付服务，算法和科研用它固定实验环境，运维用它做部署单元，普通用户用它自托管软件。

下面按"手上有什么活"来分，最后再说哪些事不该硬套 Docker。

## 一张表看全

| 你在做什么 | Docker 帮你做什么 | 要先用到的能力 |
| --- | --- | --- |
| 本地开发 | 一条命令起数据库、缓存、消息队列，不污染宿主机 | `run`、端口映射、卷 |
| 试用工具 | 不安装就直接用 CLI、编译器、数据库客户端 | `run --rm`、绑定挂载 |
| 自托管 | 跑 Gitea、Nextcloud、监控、笔记等现成服务 | Compose、卷、反向代理 |
| 交付应用 | 把应用和依赖打成镜像，各环境跑同一份字节 | Dockerfile、构建、仓库 |
| 测试与 CI | 干净环境跑测试、多版本矩阵、集成测试起依赖 | `run`、Compose、CI 配置 |
| 科研与 AI | 固定 CUDA、Python、系统库版本，复现实验 | 镜像、卷、GPU 运行时 |
| 多服务联调 | 一条 `compose up` 起整套栈 | Compose、网络 |
| 隔离不可信工具 | 限制网络、文件系统、权限后再运行 | 安全选项、命名空间 |
| 教学与演示 | 给他人一条命令复现你的环境或 bug | 镜像、Compose |
| 遗留系统迁移 | 先把老应用封进容器，再逐步上编排 | Dockerfile、卷、网络 |

这张表里的每一行，对应的都是"原来要在宿主机上装一堆东西、改一堆配置，现在换成一条命令"。

## 一、一条命令起开发依赖

本地开发最常见的麻烦是依赖服务：PostgreSQL、Redis、RabbitMQ、Elasticsearch。装在宿主机上要管版本、端口、开机启动，卸不干净还会互相冲突。用容器起，用完就删：

```bash
docker run -d --name dev-pg \
  -e POSTGRES_PASSWORD=dev \
  -p 5432:5432 \
  postgres:16

docker run -d --name dev-redis -p 6379:6379 redis:7-alpine
```

应用照常连 `localhost:5432` 和 `localhost:6379`，代码不用改。要换版本，删掉容器换 tag 重跑；要清空数据，`docker rm -f dev-pg` 再起一个。宿主机的包管理器里不会多出任何东西。

几个容易踩的点：

- **端口冲突**：本机已经装了 PostgreSQL，5432 被占用，把左边改成 `-p 15432:5432`。
- **数据默认会丢**：容器删了可写层就没了。需要保留时挂命名卷，见 [[00-数据持久化|数据持久化]]。
- **初始化脚本**：`postgres` 镜像会执行 `/docker-entrypoint-initdb.d/` 下的 `.sql` 或 `.sh`，建表可以放这里。

这套做法在团队里很实用：新同事克隆仓库，跑一条 `docker compose up -d`，依赖就齐了，不用在 README 里写"请先安装 PostgreSQL 14 并创建用户"。

## 二、不安装就能用命令行工具

有些工具只是想试一次：某个版本的 Node、某个 Python 包、某个数据库客户端、某个编译工具链。为了一次性需求装进宿主机，之后还得记得清理。直接借容器跑：

```bash
# 用容器里的 Node 跑一次依赖安装和构建
docker run --rm -v "$PWD":/work -w /work node:20 npm ci

# 用指定 Python 版本跑测试
docker run --rm -v "$PWD":/work -w /work python:3.12 python -m pytest

# 临时进一个干净环境看看
docker run --rm -it alpine sh
```

`--rm` 让容器退出后自动删除，`-v "$PWD":/work` 把当前目录挂进去，`-w` 指定工作目录。工具、运行时、系统库全部来自镜像，宿主机不受影响。

注意两个细节：

- **文件属主**：Linux 上容器默认以 root 运行，写回绑定挂载的文件会变成 root 所有。加 `--user "$(id -u):$(id -g)"` 可以避免。
- **每次都要拉镜像**：第一次几百 MB，之后走本地缓存；临时用一次可以接受，天天用还是装本地更划算。

## 三、自托管现成服务

很多开源软件官方直接提供镜像：Git 服务、网盘、监控、密码管理、笔记、家庭自动化。以前要装 PHP、配 Nginx、调数据库，现在一个 Compose 文件就够：

```yaml
services:
  gitea:
    image: gitea/gitea:1.22
    ports:
      - "3000:3000"
      - "2222:22"
    volumes:
      - gitea-data:/data
    restart: unless-stopped

volumes:
  gitea-data:
```

```bash
docker compose up -d
```

升级就是改 tag 再 `up -d`，回滚就是把 tag 改回去；数据在 `gitea-data` 卷里，容器重建不影响。这就是"把运维动作收敛成改一个版本号"。

代价也要看清：卷要备份、反向代理和证书要自己配、数据库要单独规划、升级前要看 release notes。容器让部署变简单，但没有替你做运维决策。生产环境的数据库是否容器化、数据放在哪、备份怎么做，仍然要自己回答。

## 四、把自己的应用交付出去

这是 Docker 最核心的用途。写一个 Dockerfile，把代码、运行时、系统依赖、启动命令固化成一个镜像：

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["python", "main.py"]
```

然后构建、打标签、推送：

```bash
docker build -t registry.example.com/team/app:1.4.0 .
docker push registry.example.com/team/app:1.4.0
```

目标机器上：

```bash
docker run -d --name app -p 8080:8000 \
  --env-file .env \
  registry.example.com/team/app:1.4.0
```

测试、预发、生产拉的是同一份镜像，部署不再包含"在目标机上装依赖"这一步，"本地能跑线上跑不起来"的问题就从根上消失了。生产环境建议用 digest 而不是可变 tag 固定版本，具体见 [[03-镜像标签|镜像标签]]。

这条链路涉及的能力最多：写出体积小、可复现的镜像见 [[01-Dockerfile|Dockerfile]] 和 [[02-层缓存|层缓存]]，发布见 [[00-镜像仓库|镜像仓库]]，上线方式见 [[00-运行容器|运行容器]] 和 [[00-部署|部署]]。

## 五、测试与 CI 里的一次性环境

测试最怕"在我机器上是好的"。容器给每次测试一个干净、可复现的环境：

```bash
for v in 3.10 3.11 3.12; do
  docker run --rm -v "$PWD":/app -w /app python:$v \
    sh -c 'pip install -q -r requirements.txt && pytest -q'
done
```

集成测试需要的数据库、消息队列也可以现场起，测完就删。CI 里同样适用：GitHub Actions 的 service containers、GitLab CI 的 `services`、Jenkins 里直接跑 `docker compose`，都是这个思路。

和 CI 结合后，流水线大致是：构建镜像 → 跑测试 → 推仓库 → 部署。细节见 [[04-持续集成|持续集成]]。要注意的是 CI 里也要做缓存：镜像层缓存、依赖缓存、构建缓存，否则每次从零构建会慢得离谱。

## 六、科研与 AI：固定实验环境

科研和 AI 的痛点是环境：CUDA 版本、cuDNN、Python 版本、编译好的扩展、系统库，任何一项不一致，结果就可能复现不了。镜像把这些全部固化：

```bash
docker run --rm --gpus all -it \
  -v "$PWD":/workspace -w /workspace \
  pytorch/pytorch:2.4.0-cuda12.1-cudnn9-devel
```

同一份镜像在实验室的服务器和云上机器上跑，环境完全一致；论文附上镜像 digest，别人就能复现。模型服务也可以直接打包成镜像部署。

前提条件：宿主机有 NVIDIA 驱动并安装 NVIDIA Container Toolkit，`--gpus` 才生效；Docker Desktop 在 WSL2 后端下需要较新的驱动。另外这类镜像动辄几 GB，磁盘和拉取时间要提前算。

## 七、多服务本地联调

真实项目很少只有一个进程。Compose 把应用、数据库、缓存、反向代理写进一个文件，一条命令拉起：

```yaml
services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      DATABASE_URL: postgres://app:secret@db:5432/app
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: app
    volumes:
      - pg-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app"]
      interval: 5s
      retries: 10

volumes:
  pg-data:
```

```bash
docker compose up -d --build
docker compose logs -f app
docker compose down
```

服务名 `db` 会自动成为网络里的主机名，应用直接用 `db:5432` 连接。`depends_on` 配 `condition: service_healthy` 才能等到数据库真正可用，只写 `depends_on` 只能保证启动顺序，不保证就绪。

Compose 解决的是"单机多容器"的编排，跨机器、要弹性伸缩时，才轮到 Kubernetes 这类工具，见 [[03-Kubernetes|Kubernetes]]。

## 八、隔离不可信的工具和代码

拿不准的二进制、来源不明的脚本，可以先放进受限容器里跑：

```bash
docker run --rm -it \
  --network none \
  --read-only \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  -v "$PWD/input":/input:ro \
  alpine sh
```

这几项分别关掉网络、根文件系统写权限、特权 capability 和提权路径，只留一个只读输入目录。用来观察一个工具会读写什么、连哪些地址，比直接在宿主机上跑安全。

但要说清楚边界：容器共享宿主内核，普通容器不是强隔离沙箱。跑真正不可信的代码，应该用虚拟机、microVM（Firecracker）或 gVisor/Kata 这类运行时。细节见 [[02-运行时安全|运行时安全]]。

## 九、教学、演示和复现问题

"我这跑不起来"最有效的回应不是截图，是给对方一条命令：

```bash
docker run --rm -p 8888:8888 jupyter/scipy-notebook
```

对方浏览器打开就能看到和你一样的环境。培训、比赛、workshop 也常这么发环境：一个镜像或一个 Compose 文件，所有人起点一致，省掉半天装环境的时间。

排查线上问题时同样有用：把出问题的版本拉下来在本地跑，配合日志和 `exec` 进去看，比在生产机上直接操作安全得多。

## 十、遗留系统迁移的跳板

老应用跑在老版本 PHP、Java、Python 上，升级风险大。先把"能跑起来"这件事封进镜像：固定基础镜像、装好依赖、写好启动命令，行为不变，但部署方式统一了。之后再逐步拆配置、外置状态、上编排。

这条路的价值在于**先统一交付方式，再改架构**，不用一次性重写。注意老应用的几个坑：配置写死在文件里（改成环境变量或挂载）、日志写本地文件（改成 stdout）、启动脚本不转发信号（用 `exec` 或 `tini`）。

## 什么时候不必用 Docker

> [!warning] 别为了容器而容器
> 容器解决的是"环境一致、交付频繁、密度和弹性"这三类问题。离开这些前提，引入镜像构建和运行时只会多一层维护成本。

- **单机定时脚本、一次性任务**：直接放 cron 或 systemd 更简单。
- **桌面 GUI 软件**：容器基本只跑 Linux 无头服务，图形界面、驱动、专有许可软件更适合虚拟机或直接安装。
- **需要特定内核、内核模块、驱动的负载**：容器共享宿主内核，加载不了模块，也改不了全局参数。
- **强隔离多租户**：跑不可信代码时，普通容器的内核攻击面太大。
- **极简单的静态站点**：对象存储加 CDN 往往更便宜、更快。
- **团队没有基础运维能力**：镜像仓库、构建流水线、日志、监控任何一环缺失，容器都会变成负担。

这些场景的展开在 [[02-为什么用容器|为什么用容器]] 里，判断逻辑是一样的：收益要和长期维护成本一起算。

## 从"会跑容器"到"能做项目"

同样是"学 Docker"，目标不同，要补的能力也不同：

| 目标 | 需要掌握 | 对应笔记 |
| --- | --- | --- |
| 本地起依赖、试工具 | `run`、端口映射、`--rm`、绑定挂载 | [[00-基础|基础]] |
| 数据不丢 | 卷、绑定挂载、备份 | [[00-数据持久化|数据持久化]] |
| 打包自己的应用 | Dockerfile、多阶段构建、层缓存、体积控制 | [[00-构建镜像|构建镜像]] |
| 发布和回滚 | 标签、digest、仓库、拉取策略 | [[00-镜像仓库|镜像仓库]] |
| 单机多服务 | Compose、网络、健康检查 | [[00-运行容器|运行容器]] |
| 接进开发流程 | 热重载、调试、测试、CI | [[00-开发体验|开发体验]] |
| 上线 | 安全基线、编排、发布策略 | [[00-容器安全|容器安全]]、[[00-部署|部署]] |

不需要一次学完。多数人的路径是：先会跑现成镜像，再会写自己的 Dockerfile，最后才碰 Compose 和部署。

## 怎么判断自己学会了

- 能用一个文件把项目的依赖环境描述清楚，新机器上一条命令跑起来。
- 能写出可重复构建的 Dockerfile，知道镜像为什么这么大、怎么减小。
- 知道哪些数据必须放卷，删掉容器后数据还在。
- 容器起不来时，能按"CLI → daemon → 容器 → 应用"的顺序定位，而不是只会 `docker ps`。
- 知道什么时候该用虚拟机、什么时候该上 Kubernetes、什么时候根本不用容器。

前四条是操作能力，最后一条是判断力。Docker 本身不难，难的是知道它在整个交付链路里站在哪。

## 相关笔记

- [[00-总览|Docker 路线图总览]]
- [[01-容器|容器]]
- [[02-为什么用容器|为什么用容器]]
- [[03-虚拟机与容器|虚拟机与容器]]
- [[04-Docker 与 OCI|Docker 与 OCI]]
- [[00-数据持久化|数据持久化]]
- [[00-构建镜像|构建镜像]]
- [[00-镜像仓库|镜像仓库]]
- [[00-运行容器|运行容器]]
- [[00-开发体验|开发体验]]
- [[00-容器安全|容器安全]]
- [[00-部署|部署]]
