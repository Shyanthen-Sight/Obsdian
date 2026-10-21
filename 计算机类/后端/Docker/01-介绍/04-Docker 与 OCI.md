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

## 相关笔记

- [[01-容器|容器]]
- [[01-Dockerfile|Dockerfile]]
- [[02-Docker 引擎|Docker 引擎]]
- [[00-镜像仓库|镜像仓库]]
- [[03-Kubernetes|Kubernetes]]
