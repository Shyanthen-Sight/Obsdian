# Docker Hub

不写 registry 前缀时，Docker 默认去 `docker.io` 找。`docker pull nginx` 实际展开是 `docker.io/library/nginx:latest`，`library` 是官方镜像的命名空间。自己推送时必须带用户名，`docker push alice/my-app:1.0` 对应 `docker.io/alice/my-app:1.0`。

## 登录与推送

```bash
docker login -u alice
# 密码处粘贴 Personal Access Token
docker tag my-app:1.0 alice/my-app:1.0
docker push alice/my-app:1.0
```

`docker tag` 不复制镜像，只是给本地镜像再加一个名字，所以执行很快。`docker push` 按层上传，仓库里已有的层会跳过，这也是为什么改动越小、推送越快。第一次推送前仓库要存在，或者账号里开启了自动创建。

## 限流

匿名拉取按 IP 限流，登录用户额度更高，具体数字 Hub 调整过几次，以官方文档为准。CI 里最常见的报错是：

```text
toomanyrequests: You have reached your pull rate limit.
```

处理办法按成本排：CI 里配置 `docker login`，用机器人账号的 token；把常用基础镜像同步到内部仓库；量确实大就买付费计划。改 `daemon.json` 的 `registry-mirrors` 只对部分匿名拉取场景有效，镜像站本身也经常变化，不适合当长期方案。

## 官方镜像也要看一眼

Official Image 有维护者审核，Verified Publisher 有企业背书，但都只说明来源相对可信。用之前看几件事：标签多久没更新、支持哪些架构（`docker manifest inspect nginx:1.27`）、默认用户是不是 root、entrypoint 会不会把你要传的命令吃掉。

> [!tip] 用 access token
> 开了双因素认证后，CLI 登录必须用 access token。token 可以只给读或写权限，泄露了能单独吊销，比账号密码安全。

其他常见报错：`unauthorized: authentication required` 是没登录或 token 过期；`denied: requested access to the resource is denied` 多半是仓库名和账号不匹配，或者账号没有写权限。

## 相关笔记

- [[00-镜像仓库|镜像仓库]]
- [[02-其他仓库|其他仓库]]
- [[03-镜像标签|镜像标签]]
- [[01-镜像|镜像]]
- [[04-持续集成|持续集成]]
