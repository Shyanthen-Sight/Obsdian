# Kubernetes

K8s 把"跑容器"拆成几层对象。Pod 是最小调度单位，里面可以有一个或多个共享网络和存储的容器；日常很少直接建 Pod，而是用 Deployment 管副本和发布，用 Service 提供稳定虚拟 IP，用 Ingress 按域名和路径接外部 HTTP 流量。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels: {app: web}
  template:
    metadata:
      labels: {app: web}
    spec:
      imagePullSecrets:
        - name: regcred
      containers:
        - name: web
          image: registry.example.com/web:1.5.0
          readinessProbe:
            httpGet: {path: /healthz, port: 8080}
          livenessProbe:
            httpGet: {path: /healthz, port: 8080}
```

`maxSurge: 1` 加 `maxUnavailable: 0` 是先多起一个新 Pod，等它 Ready 再停旧的，发布期间容量不掉。readinessProbe 决定 Pod 能不能接流量，livenessProbe 失败会重启容器；两个探针别共用慢接口，否则滚动发布会卡住。

Service 和 Ingress 把流量接进来：

```yaml
apiVersion: v1
kind: Service
metadata: {name: web}
spec:
  selector: {app: web}
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata: {name: web}
spec:
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web
                port: {number: 80}
```

Service 的 selector 必须和 Pod label 对上，对不上时 Endpoints 为空，访问就是 connection refused。Ingress 只是规则，真正干活的是 ingress controller，没装它 Ingress 不会生效。

私有仓库的 imagePullSecrets 必须和 Pod 同 namespace：

```bash
kubectl create secret docker-registry regcred \
  --docker-server=registry.example.com \
  --docker-username=robot \
  --docker-password='***' \
  -n prod
```

报 `ImagePullBackOff` 先 `kubectl describe pod` 看事件，区分 401、DNS 还是证书。

Docker 和 K8s 的关系容易混淆。从 1.24 起 dockershim 被移除，kubelet 通过 CRI 直接调 containerd 或 CRI-O，Docker Engine 不再是默认运行时。CRI 是一层 gRPC 接口，规定 kubelet 怎么创建容器、拉镜像、配网络。但 Docker 构建的镜像遵循 OCI 镜像规范，照样能跑。构建用 Docker、运行时是 containerd，这是现在最常见的组合。

学习曲线主要在网络、存储、权限和排障，小团队先从托管 K8s 开始。Docker 基础不牢，K8s 的很多行为会变成玄学。

## 相关笔记

- [[00-部署|部署]]
- [[01-Nomad|Nomad]]
- [[02-Docker Swarm|Docker Swarm]]
- [[04-PaaS 选项|PaaS 选项]]
- [[00-网络|网络]]
- [[04-Docker 与 OCI|Docker 与 OCI]]
- [[03-镜像标签|镜像标签]]
