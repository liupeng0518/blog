title: 在树莓派上学习 Docker —— Part 3
date: 2018-03-02 17:20:00
categories:
  - Linux
tags:
  - Docker
toc: true
---

已经掌握了如何 Run Docker 镜像，接下来就是如何 Build 、Ship。

首先需要知道镜像（Image）是只读的，容器（Container）是可写的，为了方便 Image 的分发，还需要一个集中保存管理 Image 的地方，称为 Docker Registry。

<!-- more -->

# Build

根据需要构建自己的镜像是使用 Docker 的重要步骤。

## Docker Commit

除了使用 Volume 挂载本地文件到容器来实现持久化之外，还可以通过定制镜像实现。

首先运行一个 nginx 容器：

```
$ docker run --rm --name nginx -p 80:80 -d arm32v7/nginx
```

用浏览器打开树莓派的 IP 就能看到 Nginx 的欢迎页面了，然后我们先修改一下容器的内容，使用下面的命令进入容器内：

```
$ docker exec -ti nginx bash
```

然后尝试修改默认页面，刷新之后就可以看到页面内容变成了 "hello world" 了。：

```
$ echo "hello world" > /usr/share/nginx/html/index.html
```
显然，如果运行的容器销毁后，重新从 `arm32v7/nginx` 镜像运行的话，默认页面又会还原。

退出容器，然后使用 Docker Commit 可以将修改后的容器标记为一个新的镜像：

```
$ docker commmit nginx -t mynginx
```

然后运行新的镜像就可以看到默认页面是修改之后的内容：

```
$ docker run --rm --name mynginx -p 80:80 -d mynginx
```

注：需要将前面运行的 nginx 容器停止。

## Dockerfile

知道 Git 的话对 Commit、Pull 应该会觉得眼熟，大体积二进制文件在 Git 中并不能很好的管理，显然 Docker Commmit 虽然能满足自定义镜像的需求，但是对于工程而言这种方式过于原始。

可以使用 Dockerfile 来“描述”镜像如何构建，只需要一个 Dockerfile 文本就能定义镜像。首先创建一个文件夹 `mynginx`，在该文件夹中创建一个内容如下的 `Dockerfile` 文件

```
FROM arm32v7/nginx
RUN echo "hello world from dockerfile" > /usr/share/nginx/html/index.html
```

进入到 mynginx 目录后用下面的使用 Dockerfile 来构建镜像：

```
$ docker build . -t mynginx:dev
```

接下来就是运行起来看看成果：

```
$ docker run --name mynginx --rm -p 80:80 -d mynginx:dev
```
注：需要将前面运行的 nginx 容器停止。

### dockerignore

Build 时，Docker 默认情况下会收集 Dockerfile 所在目录的所有文件，假如直接使用系统根目录下的 Dockerfile 文件进行 Build 将会是一个灾难。

软件项目目录也会有类似 `.git` 的目录，并不需要参与构建过程。与 Git 类似，可以创建一个 `.dockerignore` 文件，用于定义 Build Docker 镜像时忽略的文件。

## Layers

分层是 Docker 的重要概念，对于编写合理的 Dockerfile、理解容器运行有重要的意义。

通过 `docker images` 列出所有的镜像，至少包含有 3 个镜像。

```
REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
...
mynginx               dev                 d0fd5936b0cc        5 minutes ago       87.9MB
mynginx               latest              f85648f5127a        21 minutes ago      87.9MB
arm32v7/nginx         latest              ec8084797f1e        8 days ago          87.9MB
...
```

然后使用 `docker inspect mynginx:latest` 分别查看这三个镜像的详细信息，主要关注的是 ROOTFS 中 Layers 的内容。

以我的环境为例，三个镜像 Laryers 的内容如下：

* mynginx:dev
```
...
"RootFS": {
            "Type": "layers",
            "Layers": [
                "sha256:2c844972db4f9a1ffcbeb594fc9b704fd12438d64ea258d97624b5bafb109921",
                "sha256:0f7f0c8a393cc89587498a39f99be30fb24fad97c055c9d7e68b1244d9b00c04",
                "sha256:d0eff1efd4a6d6b755f72813360462ed2d6d4ab363da460d1c1fb9f52fdf9089",
                "sha256:99be16e468c72a79d29a65e93bea16db897a67f5736bd575f71290c62fd4b341"
            ]
        }
...
```

* mynginx:latest
```
...
"RootFS": {
            "Type": "layers",
            "Layers": [
                "sha256:2c844972db4f9a1ffcbeb594fc9b704fd12438d64ea258d97624b5bafb109921",
                "sha256:0f7f0c8a393cc89587498a39f99be30fb24fad97c055c9d7e68b1244d9b00c04",
                "sha256:d0eff1efd4a6d6b755f72813360462ed2d6d4ab363da460d1c1fb9f52fdf9089",
                "sha256:ab53beed52ffc97e6eea6f86b52cb83dc9e65aa5a55386bfb0135bb6876ef1ca"
            ]
        }

```
* arm32v7/nginx:latest
```
 "RootFS": {
            "Type": "layers",
            "Layers": [
                "sha256:2c844972db4f9a1ffcbeb594fc9b704fd12438d64ea258d97624b5bafb109921",
                "sha256:0f7f0c8a393cc89587498a39f99be30fb24fad97c055c9d7e68b1244d9b00c04",
                "sha256:d0eff1efd4a6d6b755f72813360462ed2d6d4ab363da460d1c1fb9f52fdf9089"
            ]
        }

```

可以看到，`mynginx` 镜像中的 Layers 有 3 个 sha256 值就是 `arm32v7/nginx` 的 Layers，而差异就是多出来的 Layer。

## Build Cache

了解 Layer 之后还需要了解 Build Cache，将 Dockerfile 的内容修改如下：

```
FROM arm32v7/nginx
RUN echo "hello world from dockerfile" > /usr/share/nginx/html/index.html
RUN echo "$(date)" > /usr/share/nginx/html/date.html
```

Build 之后重新运行容器，这次需要打开 date.html 页面，确认好页面内容之后，再次 Build。

观察 Build 的输出可以看到，`RUN "$(date)"` 也是显示 `Using cache`，但是两次 `date` 命令输出的内容应该是不同的。

```
Sending build context to Docker daemon  2.048kB
Step 1/3 : FROM arm32v7/nginx
 ---> ec8084797f1e
Step 2/3 : RUN echo "hello world from dockerfile" > /usr/share/nginx/html/index.html
 ---> Using cache
 ---> d0fd5936b0cc
Step 3/3 : RUN echo "$(date)" > /usr/share/nginx/html/date.html
 ---> Using cache
 ---> cfdfc1063d5a
Successfully built cfdfc1063d5a
Successfully tagged mynginx:dev
```

再次运行 Build 好的镜像，会发现 date.html 页面的内容没有变化。虽然命令输出是会变化，但是因为 RUN 执行的命令内容没有变化，所以 Build 过程中会直接使用 Cache。

更多的关于 Dockerfile 编写请查看 [Dockerfile reference](https://docs.docker.com/engine/reference/builder/) 的内容。

注：可以看看最新的镜像的 Layers 内容有何变化。

# Ship

> 参考资料：
> [docker login](https://docs.docker.com/engine/reference/commandline/login/)
> [docker push](https://docs.docker.com/engine/reference/commandline/push/)

对于 Docker 官方 Registry —— [Docker Hub](https://hub.docker.com/)，之需要注册好帐号，然后使用 `docker login` 命令登录。

以前面构建好的镜像为例，使用 `docker push` 将镜像 Push 到 Docker Hub，需要修改 `mynginx` 镜像的 tag，然后 push 即可：

```
$ docker tag mynginx:dev username/mynginx:dev
$ docker push username/mynginx:dev
```

如果使用的第三方 Docker Registry，请查看相关使用文档。

注意：对于公开镜像，不要保存任何敏感信息。