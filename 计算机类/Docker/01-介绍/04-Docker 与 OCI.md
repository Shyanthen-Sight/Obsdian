# Docker 与 OCI

Docker 最早把"构建、分发、运行"这套流程做得顺手，但镜像格式和运行时并不归 Docker 私有。OCI（Open Container Initiative）定了三份规范：

- 镜像规范：镜像由 manifest、config、layers 组成，按内容寻址
- 运行时规范：怎么根据 config 创建进程、命名空间和挂载
- 分发规范：仓库怎么通过 HTTP API 推拉镜像

遵守这些规范，镜像可以由 Docker、BuildKit、Podman、Kaniko 构建，运行时可以用 runc、crun，编排层可以是 Kubernetes。工具换了，产物还能互通。

可以导出一次 OCI 布局看看：

```bash
docker buildx build --output type=oci,dest=app.tar .
tar -tf app.tar | head
# blobs/  index.json  oci-layout
```

`index.json` 指向 manifest，`oci-layout` 标记版本，`blobs/sha256/` 下是 config 和层。这个 tar 用 `skopeo copy oci-archive:app.tar docker://registry/app:tag` 能直接推进别的仓库。日常的 `docker save` 是 Docker 自有格式，跨工具时留意区别。

## Docker 内部不是一块铁板

```text
docker CLI → dockerd → containerd → containerd-shim → runc → 容器进程
```

CLI 只负责发请求；dockerd 管镜像、网络、卷和 API；containerd 管容器生命周期和镜像分发；runc 真正调用 clone、unshare、pivot_root 创建容器。容器跑起来后 runc 退出，shim 留下当父进程。

这解释了"重启 Docker，容器还在跑"：dockerd 挂了不一定影响 containerd 和 shim 托管的进程。也解释了 `docker` 命令连不上时，`ctr -n moby containers ls` 为什么还能看到容器。

```bash
docker info --format '{{json .Runtimes}}'
# {"runc":{"path":"runc"},"io.containerd.runc.v2":{...}}
```

> [!tip] 排查分层
> 命令报错先分清是哪一层：CLI 连不上 daemon，看 socket 和权限；daemon 在但容器起不来，看 containerd 日志；容器创建失败，看 runc 报错和内核限制。

## 三份规范各管什么

OCI 不是一份笼统的“容器标准”，而是三份互相独立的规范。分清楚它们，才知道换工具时到底换掉了哪一层。

### 镜像规范：镜像长什么样

一个 OCI 镜像由三部分组成：

- **manifest**：指向 config 和各个 layer，记录每个 blob 的 digest、大小和媒体类型。
- **config**：入口命令、`CMD`、环境变量、工作目录、用户、暴露端口、卷、labels、构建历史。
- **layers**：文件系统差异，通常是 tar 包（可 gzip/zstd 压缩），每层按内容寻址。

多架构镜像用 index（manifest list）指向不同平台的 manifest。所有内容都用 `sha256` 摘要标识，所以“同一个 digest”意味着同一份字节，tag 只是指向 digest 的别名，可以移动。这就是为什么生产环境建议用 digest 而不是 `latest` 固定版本。

镜像规范只定义“长什么样”，不规定用什么工具构建。Docker BuildKit、Buildah、Kaniko、Podman 都能产出符合规范的镜像。

### 运行时规范：怎么把镜像变成进程

运行时规范定义的是一个 **bundle**：一个目录，里面包含 `config.json` 和 `rootfs`。`config.json` 描述进程参数、环境变量、命名空间、cgroup 限额、挂载、capabilities、seccomp 和 hooks；运行时按这份配置调用 `clone`、`unshare`、`pivot_root`，把进程创建出来。

生命周期也有标准动作：`create`、`start`、`kill`、`delete`，加上 `state` 查询。hooks 允许在容器创建前后、启动前后插入操作，比如配置网络、挂载密钥。

关键点是：运行时本身不需要常驻 daemon。runc 创建完容器就退出，容器进程由 shim 或宿主 init 接管。这也是“重启 dockerd，容器还在跑”的底层原因之一。`runc` 和 `crun` 是这份规范的两个常见实现，Kata、gVisor 也提供兼容的运行时。

```bash
docker info --format '{{json .Runtimes}}'
# {"runc":{"path":"runc"},"io.containerd.runc.v2":{...}}
```

### 分发规范：镜像怎么推拉

分发规范定义 registry 的 HTTP API：怎么取 manifest、怎么判断 blob 是否存在、怎么分块上传、怎么列 tag、怎么处理认证（Bearer token）、怎么跨仓库挂载 blob。客户端可以是 Docker CLI、Podman、Skopeo、ORAS，服务端可以是 Docker Registry、Harbor、云厂商的镜像服务。

因为接口标准化，镜像可以在不同 registry 之间搬，CI 里的构建产物也能直接被部署工具拉取。OCI 还支持把 Helm chart、SBOM、签名等作为 artifact 存进同一个仓库，不必另建一套存储。

## Docker 镜像格式与 OCI 镜像格式

日常最容易混的是“镜像文件”和“OCI 镜像”。它们相关，但不是一回事：

| 格式 | 典型命令 | 结构 | 跨工具 |
| --- | --- | --- | --- |
| Docker archive | `docker save` / `docker load` | `manifest.json`、`repositories`、各层目录 | 主要给 Docker 自己用 |
| OCI layout | `docker buildx build --output type=oci`、`skopeo copy` | `oci-layout`、`index.json`、`blobs/sha256/` | 通用 |
| OCI archive | `skopeo copy oci-archive:` | OCI layout 打成的 tar | 通用 |
| Registry 对象 | `docker push` / `docker pull` | manifest + config + blobs | 通用 |

`docker save` 传统上产出 Docker 自有格式，不是 OCI layout；`docker load` 也主要吃这种格式。开启 containerd 镜像存储后兼容性会好一些，但跨工具交换仍然建议用 OCI layout 或 `skopeo copy`，不要假设 `docker save` 的 tar 能被任意工具直接读。

一个 OCI layout 解压后大致是这样：

```text
oci-layout          # 版本标记
index.json          # 入口，指向 manifest
blobs/sha256/...    # config、manifest、layers
```

`skopeo copy oci-archive:app.tar docker://registry/app:tag` 可以把它推进任意兼容 registry；反过来也能把 registry 里的镜像导出成 OCI layout 再检查。排查“镜像里到底有什么”时，这比在容器里翻文件系统更直接。

## 组件职责与故障分层

Docker 内部不是一块铁板，而是一条调用链：

```text
docker CLI → dockerd → containerd → containerd-shim → runc → 容器进程
```

| 层 | 组件 | 职责 | 这一层挂了会怎样 |
| --- | --- | --- | --- |
| 客户端 | `docker` CLI | 解析参数、发 API 请求 | 只是命令用不了，容器不受影响 |
| 守护进程 | `dockerd` | 镜像、网络、卷、API、构建调度 | 新操作失败；已运行容器通常继续 |
| 容器守护 | `containerd` | 容器生命周期、镜像分发、snapshot | 管理受阻；shim 托管的进程可能继续 |
| 垫片 | `containerd-shim` | 每个容器的父进程、stdio、回收 | 该容器失去管理或日志 |
| 低层运行时 | `runc` / `crun` | 创建命名空间、cgroup、挂根，然后退出 | 容器创建失败 |
| 内核 | namespaces / cgroups | 隔离与限额 | 宿主级问题波及所有容器 |

几个能直接观察到的推论：

- 容器跑起来后 runc 已经退出，留下 shim 当父进程。所以 `ps -ef | grep containerd-shim` 能看到每个容器一个 shim。
- dockerd 重启时，容器进程不一定被杀，因为它们的父进程是 shim，不是 dockerd。但 CLI 会短暂不可用，网络和端口映射可能需要 daemon 恢复后重新同步。
- `docker` 命令连不上 daemon 时，`ctr -n moby containers ls` 仍可能看到容器，因为它直接跟 containerd 说话。
- 容器创建失败要往下看：dockerd 报参数错误、containerd 报 snapshot 或镜像问题、runc 报命名空间或 cgroup 问题，层次不同，排查入口也不同。

## 容器工具链对比

这几个名字经常被放在一起，但定位差别很大：

| 工具 | 架构 | rootless | 构建 | 编排 | 主要定位 |
| --- | --- | --- | --- | --- | --- |
| Docker Engine | daemon + CLI | 支持 | BuildKit | Compose、Swarm | 一体化工具链 |
| Podman | 无 daemon，fork-exec | 默认支持 | Buildah | Pod、Compose provider | Docker CLI 的替代品 |
| containerd | daemon，低层 | 支持 | 需配合 BuildKit/nerdctl | 通过 CRI 给 K8s | 容器运行时 |
| nerdctl | containerd 的 CLI | 支持 | 配合 BuildKit | Compose | Docker 风格的 containerd 客户端 |
| CRI-O | K8s CRI 运行时 | 支持 | 不负责构建 | 只给 K8s | Kubernetes 专用运行时 |
| runc / crun | 低层运行时 | 不涉及 | 不涉及 | 不涉及 | 真正创建容器 |

**Docker Engine** 把构建、运行、网络、卷、Compose 打包在一起，开发体验最好，但需要常驻 daemon，默认以 root 运行（虽然支持 rootless）。

**Podman** 用 fork-exec 模型，不需要 daemon，默认 rootless，CLI 与 Docker 高度兼容，还引入了 pod 的概念。迁移时大部分命令能直接换，但要注意：没有 `docker.sock`，依赖它的工具要改；Compose 需要 `podman-compose` 或 Docker Compose provider；rootless 网络走 slirp4netns/pasta，端口和性能表现不同；systemd 集成方式也不一样。

**containerd** 是更低层的运行时，Docker 和 Kubernetes 都在用。它管生命周期、镜像分发、snapshot，不直接提供面向开发者的构建和 Compose 体验。`ctr` 是它的原生 CLI，但比较难用；`nerdctl` 提供了 Docker 风格的命令。

**CRI-O** 是专门给 Kubernetes 的 CRI 实现，只负责跑 Pod，不负责构建。**runc/crun** 则是最底层，只按 OCI 运行时规范创建进程，连镜像管理都没有。

所以“换成 Podman 也差不多”在“拉镜像、跑容器、构建镜像”这件事上大体成立，因为大家遵守同一套 OCI 规范；但一旦涉及 daemon 依赖、Compose、rootless 网络、编排和 systemd，差异就出来了。

## 相关笔记

- [[01-容器|容器]]
- [[01-Dockerfile|Dockerfile]]
- [[02-Docker 引擎|Docker 引擎]]
- [[00-镜像仓库|镜像仓库]]
- [[03-Kubernetes|Kubernetes]]
