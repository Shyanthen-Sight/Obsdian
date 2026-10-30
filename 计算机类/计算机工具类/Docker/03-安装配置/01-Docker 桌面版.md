# Docker 桌面版

Docker Desktop 把 dockerd、CLI、compose、Kubernetes 和一个图形界面打包成一个安装包。Windows 和 macOS 没有 Linux 内核，所以它实际是在轻量虚拟机里跑 Linux 容器，桌面应用负责把 socket 暴露给本机 CLI。

## WSL2 后端

Windows 上选 WSL2 后端，性能比旧的 Hyper-V 方案好，和 WSL 里的开发环境也能直接协作。装完会多出 `docker-desktop` 这个 WSL 发行版：

```bash
wsl -l -v
#   NAME              STATE           VERSION
# * Ubuntu            Running         2
#   docker-desktop    Running         2
```

虚拟机的资源通过 `.wslconfig`（位于 `C:\Users\<你>\.wslconfig`）或 Settings → Resources 调整：

```ini
[wsl2]
memory=8GB
processors=4
swap=2GB
```

这几项限制的是整个 WSL2 虚拟机，Docker 和其他 WSL 发行版一起分这 8GB。给太小，`npm install` 或镜像构建容易因 OOM 退出 137；给太大，Windows 本体会开始换页。改完执行 `wsl --shutdown` 再启动才生效。

## CLI 连的是哪个 daemon

Desktop 会注册一个 context，CLI 通过它找到虚拟机里的 socket：

```bash
docker context show
# desktop-linux
docker info -f '{{.OperatingSystem}} | {{.KernelVersion}}'
# Docker Desktop | 6.6.87.2-microsoft-standard-WSL2
```

Desktop 没启动时，所有 `docker` 命令都会报 `Cannot connect to the Docker daemon`，先开应用而不是重装。机器上同时装了原生引擎或 Podman 时，`docker context use` 切错 context 是常见的“镜像怎么没了”。

## 文件性能

Windows 上把 `C:\` 下的代码 bind mount 进容器，IO 要经过 9p 转换，`node_modules` 这种小文件多的目录能慢好几倍。把项目放到 WSL 文件系统里（`\\wsl$\Ubuntu\home\you\project`），从 WSL 终端里跑 Docker，速度接近原生 Linux。macOS 上 VirtioFS 比早期的 osxfs 好很多，但大量小文件仍然慢，依赖目录用命名卷而不是 bind mount 更稳。

## 授权与替代

Docker Desktop 对规模较大的公司收费（按官方条款，员工数或年收入超过阈值需要订阅）。用之前确认公司是否已有授权。不能用的场景可以选 Linux 虚拟机里装 Docker Engine、macOS 上的 Colima、跨平台的 Podman Desktop 或 Rancher Desktop，命令基本兼容，差别主要在 GUI 和 Kubernetes 集成。

> [!tip] 磁盘只涨不缩
> Desktop 的虚拟磁盘文件会随镜像和容器增长，删除对象后宿主机文件不一定变小。定期 `docker system prune`，必要时在 Settings 里清理数据或压缩 vhdx，别等 C 盘满了再查。

## 相关笔记

- [[00-安装配置|安装配置]]
- [[02-Docker 引擎|Docker 引擎]]
- [[03-绑定挂载|绑定挂载]]
- [[01-热重载|热重载]]
- [[02-调试器|调试器]]
- [[00-开发体验|开发体验]]
- [[00-基础|基础]]
