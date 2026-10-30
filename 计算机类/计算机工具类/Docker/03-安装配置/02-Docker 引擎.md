# Docker 引擎

Linux 上 Docker 是一组进程：`dockerd` 接收 API 请求，containerd 管容器生命周期，runc 调用 `clone()`、`unshare()`、`mount()` 创建容器。CLI 只是 HTTP 客户端，通过 `/var/run/docker.sock` 说话。

## 用官方仓库装

发行版自带的 `docker.io` 偏旧，服务器建议用官方仓库（需 curl、gnupg、lsb-release）：

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update && sudo apt install docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
```

buildx、compose v2 是独立包，用 `docker compose`（带空格）；老教程的 `docker-compose` 是 Python 版。

```bash
sudo usermod -aG docker "$USER"
newgrp docker          # 或者重新登录
docker run --rm hello-world
```

docker 组等价于 root，组内用户能把宿主机根目录挂进容器。多租户用 rootless：

```bash
dockerd-rootless-setuptool.sh install
systemctl --user enable --now docker
export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
```

需要 `uidmap`、slirp4netns，默认不能绑 1024 以下端口。

## daemon.json

配置在 `/etc/docker/daemon.json`，改完重启 `docker` 生效：

```json
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "50m", "max-file": "3" },
  "data-root": "/data/docker",
  "registry-mirrors": ["https://docker.mirrors.example.com"],
  "default-address-pools": [
    { "base": "172.30.0.0/16", "size": 24 }
  ],
  "live-restore": true
}
```

`log-opts` 最易被忽略：默认 json-file 不轮转，话痨容器能写满磁盘。`data-root` 改完不会自动搬数据，先停服务、`cp -a /var/lib/docker /data/`。`default-address-pools` 避开和 VPN 冲突的 `172.17.0.0/16`。`live-restore` 让守护进程重启时容器继续跑，升级大版本或改网络配置时仍会中断。

## 出问题时看哪里

```bash
systemctl status docker
journalctl -u docker -n 100 --no-pager
docker system df
```

`Cannot connect to the Docker daemon` 先看服务和 context；`permission denied` 是组没生效；`no space left on device` 看 `/var/lib/docker`。容器 DNS 失败，通常是宿主机 `/etc/resolv.conf` 或防火墙改过，内置的 127.0.0.11 被绕过了。

## 相关笔记

- [[00-安装配置|安装配置]]
- [[01-Docker 桌面版|Docker 桌面版]]
- [[04-Docker 与 OCI|Docker 与 OCI]]
- [[02-运行时安全|运行时安全]]
- [[00-Docker 命令行|Docker 命令行]]
- [[03-运行时配置|运行时配置]]
- [[02-用户与组|用户与组]]
