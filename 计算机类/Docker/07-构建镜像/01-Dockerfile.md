# Dockerfile

Dockerfile 按行执行，每条指令产生一层。难的是知道哪些写法会留下垃圾、哪些会让缓存失效。

| 指令 | 作用 | 常见写法 |
| --- | --- | --- |
| `FROM` | 指定基础镜像 | `FROM node:20-alpine` |
| `WORKDIR` | 设置后续指令的工作目录 | `WORKDIR /app` |
| `COPY` | 从上下文复制文件 | `COPY package*.json ./` |
| `RUN` | 构建阶段执行命令 | `RUN npm ci --omit=dev` |
| `ENV` | 设置环境变量 | `ENV NODE_ENV=production` |
| `EXPOSE` | 声明容器监听的端口 | `EXPOSE 3000` |
| `USER` | 切换构建与运行用户 | `USER node` |
| `CMD` | 默认命令，可覆盖 | `CMD ["node","server.js"]` |
| `ENTRYPOINT` | 固定入口，参数追加 | `ENTRYPOINT ["/app"]` |

一个完整的 Node 例子：

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
ENV NODE_ENV=production
EXPOSE 3000
USER node
CMD ["node", "server.js"]
```

`COPY package*.json` 单独一行放在 `COPY . .` 前面，是为了让依赖层在源码变化时还能命中缓存，详见 [[02-层缓存|层缓存]]。`USER node` 切到镜像自带的非 root 用户，UID 1000。`EXPOSE` 只是文档声明，真正让端口可达的是 `-p` 和网络配置。

## CMD 和 ENTRYPOINT

`CMD` 提供默认参数，`ENTRYPOINT` 定义可执行文件。两者都用 exec 形式（JSON 数组）时，容器启动的就是 `ENTRYPOINT` 加 `CMD`：

```dockerfile
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres"]
```

`docker run my-pg -c 'max_connections=200'` 只替换 `CMD`，`ENTRYPOINT` 不变，参数追加在后面。只写 `CMD` 时，`docker run` 后面的命令会整个替换它。

shell 形式（`CMD node server.js`）会多起一个 shell 当 PID 1，`docker stop` 的 SIGTERM 传不到 node，优雅退出会失效。

## 多阶段构建

编译型语言把构建工具留在最终镜像里既大又危险。多阶段构建允许前面阶段随便装，最后只拷产物：

```dockerfile
FROM golang:1.22 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -o /out/app ./cmd/app

FROM gcr.io/distroless/static-debian12
COPY --from=build /out/app /app
USER nonroot:nonroot
ENTRYPOINT ["/app"]
```

`COPY --from=build` 只取产物，构建工具和源码不进最终镜像。`CGO_ENABLED=0` 得到静态二进制，distroless 里没有 glibc。

## .dockerignore 与 BuildKit

`.dockerignore` 排除不该进上下文的东西，常见的是 `node_modules`、`.git`、`*.log`、`.env`、`dist`。

不排除 `node_modules`，`COPY . .` 会把宿主几万个文件传进 builder。`.env` 不排掉，密钥直接进镜像层。

BuildKit 是默认构建器，支持并行、缓存挂载和构建密钥。要用这些特性，首行加 `# syntax=docker/dockerfile:1`，然后可写 `RUN --mount=type=cache` 或 `--mount=type=secret`。老版本用 `DOCKER_BUILDKIT=1`。

> [!tip] 先跑通再优化
> 别一上来就抠层数和镜像大小。先让构建成功、容器能访问，再调顺序、换基础镜像。

## 相关笔记

- [[00-构建镜像|构建镜像]]
- [[02-层缓存|层缓存]]
- [[03-镜像大小与安全|镜像大小与安全]]
- [[01-包管理器|包管理器]]
- [[01-编程语言|编程语言]]
- [[03-镜像标签|镜像标签]]
