---
title: 在树莓派上学习 Docker —— Part 2
date: 2017-09-15T19:20:00+08:00
tags: [Docker,Linux,Raspberry Pi]
---

Docker 的特点或者说使用方法就全部包含在官网的首页中了——Build,Ship,and Run Any App,Anywhere，可以简单的分为三个部分：Build、Ship、Run。

我们的目的是学会如何使用 Docker，所以先从最末端的 Run 开始。

<!--more-->

注意：如果没有添加当前用户到 docker 用户组，那么所有 docker 命令都需要增加 `sudo` 才能执行。

## Pull

运行容器前需要有镜像，镜像可以在本地 Build 也可以通过镜像仓库获取（pull）。由于，这个是 Ship 环节的内容，所以这里不深入说明，只需要知道可以用 `docker pull` 命令来获取 Build 好的镜像即可。

我们可以在 [Docker Store](https://store.docker.com/) 上找到很多现成的镜像，不过需要注意的是由于 **Docker 不是虚拟机**，所以只能运行相同平台的镜像。

一般树莓派安装的 Raspbian 属于 armhf 架构，因此只能运行 armhf 的 Docker 镜像。

>说明: 这里的说法并不准确，考虑到有 [QEMU](https://zh.wikipedia.org/wiki/QEMU) 的存在实际上 Linux 是可以跨平台运行应用的。
>简单来说，只要有运行环境，X86_64系统也能运行 arm32v7 应用，详细资料请查看 [QEMU 官方文档](https://qemu.weilnetz.de/doc/qemu-doc.html)。

另外需要注意的是，Docker Store 上的镜像分为官方（Official）和社区（Community）两种，官方镜像更有安全保障，但是社区镜像更加丰富。

打开 [Docker Store](https://store.docker.com/community/images/armhf/hello-world)查看镜像 `armhf/hello-world` 的信息 。

可以看到 `armhf/hello-world` 镜像已经是废弃状态，并推荐了更加准确的镜像新地址：

> DEPRECATED
>
> The armhf organization is deprecated in favor of the more-specific arm32v7 and arm32v6 organizations, as per https://github.com/docker-library/official-images#architectures-other-than-amd64. Please adjust your usages accordingly.

树莓派3 使用的 SoC 是 Broadcom BCM2837 64bit ARMv8，但 Raspbian 是 32位系统，因此 arm32v7 和 arm32v6 的镜像应该都能使用。

首先找一个 arm32v7 与 arm32v6 都有的镜像——比如 redis 镜像

* arm32v7/redis

打开 [Docker Hub : arm32v7/redis](https://hub.docker.com/r/arm32v7/redis/) 可以看到页面上对镜像的说明，包括镜像的标签（Tags），有的还会有如何使用镜像的说明。

页面右侧还有如何获取镜像的命令：

```shell
docker pull arm32v7/redis
```

执行命令尝试获取镜像，运行结果如下：

```
Using default tag: latest
latest: Pulling from arm32v7/redis
5ec7d30a9a8c: Pull complete
681a2ce24187: Pull complete
3cd0ed4f3f6d: Pull complete
3c6baf32ca8b: Pull complete
3730cf9f8869: Pull complete
3478618950f1: Pull complete
Digest: sha256:431418afc48dc6255060ccf6b157f5b555867bdd9486761631aecc961889860c
Status: Downloaded newer image for arm32v7/redis:latest
```

首先输出的是使用了默认标签 `latest`，然后就获取镜像的进度和最后获取成功的状态。

* arm32v6/redis

打开 [Docker Hub : arm32v6/redis](https://hub.docker.com/r/arm32v6/redis/)，可以看到 arm32v6/python 的标签比 arm32v7/python 少得多。
同样执行右侧的获取镜像命令：

```shell
docker pull arm32v6/redis
```
结果返回的是找不到对应的 tag：

```
Using default tag: latest
Error response from daemon: manifest for arm32v6/redis:latest not found
```

打开 arm32v6/redis 的[ Tags 页面](https://hub.docker.com/r/arm32v6/redis/tags/)可以看到，这个镜像并没有 latest 标签的版本。所以获取时需要手动指定标签：

```shell
docker pull arm32v6/redis:3.2.9-alpine
```

这样就获取成功了：

```
3.2.9-alpine: Pulling from arm32v6/redis
47c5ef52fac1: Pull complete
61fe9dee93c9: Pull complete
86ba91790149: Pull complete
20a8d3f1f622: Pull complete
1bc8cae18b26: Pull complete
4aa6ca97d16c: Pull complete
Digest: sha256:99ca1c5627328b6f5244fbafd7df89495cc5a5409533008285e659406526a95e
Status: Downloaded newer image for arm32v6/redis:3.2.9-alpine
```

然后通过 `docker images` 命令可以查看本地已经获取的镜像有哪些：

```
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
arm32v7/redis       latest              cbd04331e9ea        3 days ago          83.2MB
arm32v6/redis       3.2.9-alpine        8c7362c51d1c        3 months ago        15.8MB
armhf/hello-world   latest              d40384c3f861        11 months ago       1.64kB
```

到这里使用 `docker pull` 的方法就都知道了：

* 默认获取标签为 `latest` 的镜像
* 在镜像名后面添加 `:` 加标签名的方式获取指定标签的镜像

接下来就是运行（Run）了。

## Run

在上一节末尾使用`docker run --rm hello-world` 时，可以看终端中有如下输出：

```
...
Unable to find image 'hello-world:latest' locally
latest: Pulling from hello-world
a0691bf12e4e: Pull complete
Digest: sha256:f5233545e43561214ca4891fd1157e1c3c563316ed8e237750d59bde73361e77
Status: Downloaded newer image for hello-world:latest
...
```

可以知道 `docker run` 执行时会先从本地找要运行的镜像，如果没有，就会尝试从远程仓库获取镜像。也就是可以不使用 `docker pull` 获取镜像，而是直接 `docker run` 来运行。

接着运行手动获取到的 `arm32v7/redis` 镜像：

```shell
docker run -d --name arm32v7-redis arm32v7/redis
```

`-d` 和 `--name` 都是 `docker run` 的参数。`-d` 表示以后台方式运行容器，`--name` 则表示为容器命名。

然后运行 `arm32v6-redis` 镜像:

```
docker run -d --name arm32v6-redis arm32v6/redis:3.2.9-alpine
```

使用 `docker ps` 查看容器的运行状态：

```
CONTAINER ID        IMAGE                        COMMAND                  CREATED             STATUS              PORTS               NAMES
9fc7c8edb071        arm32v6/redis:3.2.9-alpine   "docker-entrypoint..."   4 seconds ago       Up 2 seconds        6379/tcp            arm32v6-redis
0313638babf3        arm32v7/redis                "docker-entrypoint..."   28 minutes ago      Up 28 minutes       6379/tcp            arm32v7-redis
```

可以看到两个容器都是运行的状态。

如果想查看容器内容应用的日志，可以使用 `docker logs arm32v7-redis`：

```
1:C 15 Sep 12:48:11.625 # oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
1:C 15 Sep 12:48:11.625 # Redis version=4.0.1, bits=32, commit=00000000, modified=0, pid=1, just started
1:C 15 Sep 12:48:11.625 # Warning: no config file specified, using the default config. In order to specify a config file use redis-server /path/to/redis.conf
1:M 15 Sep 12:48:11.630 # Warning: 32 bit instance detected but no memory limit set. Setting 3 GB maxmemory limit with 'noeviction' policy now.
1:M 15 Sep 12:48:11.632 * Running mode=standalone, port=6379.
1:M 15 Sep 12:48:11.632 # WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.
1:M 15 Sep 12:48:11.632 # Server initialized
1:M 15 Sep 12:48:11.632 # WARNING overcommit_memory is set to 0! Background save may fail under low memory condition. To fix this issue add 'vm.overcommit_memory = 1' to /etc/sysctl.conf and then reboot or run the command 'sysctl vm.overcommit_memory=1' for this to take effect.
1:M 15 Sep 12:48:11.632 * Ready to accept connections
```

这里 `arm32v7-redis` 可以是容器 ID(CONTAINER ID)也可以是容器名，不过能查看容器内应用日志的前提是**应用以 `stdout` 与 `stderr` 的方式输出信息**。

> 关于 `stdout` 和 `stderr` 可以在[《鸟哥的Linux 私房菜》](http://cn.linux.vbird.org/linux_basic/0320bash_5.php)中了解。

到这里就有个问题了：

两个 Redis 容器都是使用的默认配置——端口都是 6379，从日志也可以确定两个容器都是运行的，怎么没有产生冲突？如果使用客户端连接容器内的 Redis 实例，连接的是哪一个？

### Network

如何让外部应用可以访问容器的服务，就需要配置容器的网络了。

首先在树莓派上执行 `ip addr` 命令来查看树莓派的网卡信息：

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: enxxxxxxxxxxxxx: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether xx:xx:xx:xx:xx:xx brd ff:ff:ff:ff:ff:ff
    inet 192.168.50.169/24 brd 192.168.50.255 scope global enxxxxxxxxxxxxx
       valid_lft forever preferred_lft forever
    inet6 fe80::3b4e:6e75:3cec:d1b6/64 scope link
       valid_lft forever preferred_lft forever
3: wlan0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc pfifo_fast state DOWN group default qlen 1000
    link/ether yy:yy:yy:yy:yy:yy brd ff:ff:ff:ff:ff:ff
4: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default
    link/ether 02:42:4b:bc:11:30 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 scope global docker0
       valid_lft forever preferred_lft forever
```

除了有线网卡 `enxxxxxxxxxxxxx` 与无线网卡 `wlan0` 之外还多了一个网段为`172.17.0.1/16` 的 `docker0` 的网卡。

接下来需要查看一下在运行的两个容器的 IP 地址：

```
docker exec arm32v7-redis hostname -i
docker exec arm32v6-redis hostname -i
```

可以看到两个容器的 IP 并不一样，但是与 `docker0` 网卡的网段一致，然后尝试使用 Redis 客户端连接 Redis 实例，可以发现是无法连接的，所以就不存在端口冲突。

**结论：默认情况容器间的网络、容器与主机的网络是隔离的。**

先将运行中的容器停下来：

```
docker stop redis32v7-redis redis32v6-redis
```

使用 `docker ps` 是看不到运行的容器了，不过 `docker ps -a` 还是能看到，可以用下面的命令删除掉停止的容器：

```
docker rm redis32v7-redis redis32v6-redis
```

然后添加新的参数来运行容器：

```shell
docker run -d --name arm32v6-redis -p 6379:6379 arm32v6/redis:3.2.9-alpine
```

**注意：因为 `arm32v7/redis` 镜像没有 `ip` 命令，这里需要使用 `arm32v6/redis` 镜像。**

再来查看一下运行状态：

```
CONTAINER ID        IMAGE                        COMMAND                  CREATED             STATUS              PORTS                    NAMES
a0423d07eaae        arm32v6/redis:3.2.9-alpine   "docker-entrypoint..."   2 minutes ago       Up 2 minutes        0.0.0.0:6379->6379/tcp   arm32v6-redis
```

可以发现增加了`-p` 参数之后，运行状态中 PORTS 发生了变化。如果再以相同的参数运行 `arm32v7/redis` 镜像，就会得到端口已经占用的提示：

```
37b2d6758655146b0dd1062b3ab6e56113bcaf4af0278d62f975fc44baad2c17
docker: Error response from daemon: driver failed programming external connectivity on endpoint arm32v7-redis (cea1de660470e80efd513c44dbb60b180b42b01c71cf8262f216290b7f2b37a1): Bind for 0.0.0.0:6379 failed: port is already allocated.
```

然后使用下面的命令在容器 `arm32v6-redis` 中执行 `ip addr` 命令：

```
docker exec arm32v6-redis ip addr
```

```
...
31: eth0@if32: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue state UP
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.2/16 scope global eth0
       valid_lft forever preferred_lft forever
```


`-p` 参数的作用就是将容器端口与主机端口绑定，第一个端口表示主机端口，二个端口表示容器端口。外部应用访问容器应用时应该使用主机端口访问，而不是容器端口。

除了 `-p` 参数还可以使用 `--net` 的方式来配置容器的网络。

将已经运行的容器停止并删除之后，用下面的命令启动新的容器：

```
docker run -d --name arm32v6-redis --net host arm32v6/redis:3.2.9-alpine
```

在来查看容器运行的状态：

```
CONTAINER ID        IMAGE                        COMMAND                  CREATED             STATUS              PORTS               NAMES
41500fe5d148        arm32v6/redis:3.2.9-alpine   "docker-entrypoint..."   31 seconds ago      Up 30 seconds                           arm32v6-redis
```

PORTS 又发生了变化，再次通过 `docker exec arm32v6-redis ip addr` 命令查看容器的网卡信息：

```
...
2: enxxxxxxxxxxxxx: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether xx:xx:xx:xx:xx:xx brd ff:ff:ff:ff:ff:ff
    inet 192.168.50.167/24 brd 192.168.50.255 scope global enxxxxxxxxxxxxx
       valid_lft forever preferred_lft forever
    inet6 fe80::fe0c:bf33:4bcc:d3c7/64 scope link
       valid_lft forever preferred_lft forever
...
```

与之前使用 `-p` 参数比多了一个网卡 `enxxxxxxxxxxxxx`，而且这个网卡是与树莓派的网卡名是一样的。

可以看出参数 `--net host` 将容器网络与主机网卡绑定了——也就是主机模式，而 `-p` 参数只是映射指定的端口。
根据实际需要，使用这两个参数让容器内的服务变成可以访问的状态。

### Volume

先使用下面的命令进入到容器内部的终端：

```
docker exec -ti arm32v6-redis sh
```

注：根据不同的镜像运行的容器，解释器也有可能不同，根据实际情况，`sh` 也可以换成 `bash`。

在容器终端中使用命令创建一个文件：

```
/data # touch test
```

首先重启容器：

```
docker restart arm32v6-redis
```

再进入容器终端查看 `test` 文件还是存在的。

然后，停止并删除容器 `arm32v6-redis`，重新创建一个同名容器，再进入容器查看，发现 `test` 文件不存在了。

**结论：容器初始是以镜像作为基准的，容器运行后内部的变化是不会持久到镜像的。**

如果想将容器运行时产生的文件持久化，就需要使用 `-v` 参数将容器路径挂载到主机路径。

停止并删除容器 `arm32v6-redis` 之后，使用下面的命令重新创建容器：

```
docker run -d --name arm32v6-redis -v $(pwd):/data -p 6379:6379 arm32v6/redis:3.2.9-alpine
```

> 注：`$(pwd)` 表示获取当前路径。如果在用户主目录下运行，则等价于

> ```
docker run -d --name arm32v6-redis -v /home/pi:/data -p 6379:6379 arm32v6/redis:3.2.9-alpine
```

接着使用同样的方法在容器内创建 `test` 文件，退出容器终端，之后查看本机对应的路径：

```
pi@raspberrypi:~ $ ls -l
total 0
-rw-r--r-- 1 root root 0 Sep 16 16:29 test
```

可以看到本地路径下出现了创建的 `test` 文件，显然如果删除容器并将同样的路径挂载，`test` 文件是不会丢失的。

> 注：由于在容器内部时是 `root` 用户，所以创建文件所有者也是 `root` 用户。
> 但实际 Linux 权限是以 ID 为准，也有些镜像并非默认 `root` 权限运行内部应用。这时挂载路径需要根据镜像说明配置正确的权限才能让容器内部应用正常运行。

除了使用 `-v` 参数指定挂载路径，也可以创建 volume 然后挂载：

```
docker volume create redis-data
docker run -d --name arm32v6-redis -v redis-data:/data -p 6379:6379 arm32v6/redis:3.2.9-alpine
```

关于 [Docker Volume](https://docs.docker.com/engine/admin/volumes/volumes/) 可以在文档查看更多信息。

### 实践

如何使用 Docker 部署服务所需要的知识都已经具备了，比如想运行一个 `PostgreSQL` 数据库服务。

首先是在 Docker Hub/Store 上找到镜像：

[https://hub.docker.com/r/arm32v7/postgres/](https://hub.docker.com/r/arm32v7/postgres/)，

接着获取对应标签的镜像（可以跳过，在 `docker run` 时指定）：

```
docker pull arm32v7/postgres:9.6.5
```

接着创建 Volume，或者跳过在运行时通过 `-v` 参数指定路径：

```
docker volume create pgdata
```

使用 `docker volume inspect pgdata` 可以查看创建的 Volume 的路径：

```json
[
    {
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/pgdata/_data",
        "Name": "pgdata",
        "Options": {},
        "Scope": "local"
    }
]
```

运行 `arm32v7/postgres` 镜像是需要通过变量来指定使用比如数据库密码、端口、数据路径等信息：

```
docker run --name arm32v7-pgsql \
 -e POSTGRES_DB=mydb \
 -p 5432:5432 \
 --user root \
 -v pgdata:/var/lib/postgresql/data \
 -d arm32v7/postgres:9.6.5
```

注：这里使用 `--user root` 是偷懒不处理文件权限问题。

容器运行后可以查看 Volume 下的变化：

```
sudo ls /var/lib/docker/volumes/pgdata/_data
```

也可以进入容器内部终端，使用 `psql` 命令：

```
docker exec -ti arm32v7-pgsql bash
```

```
root@90228514f956:/# psql -h localhost -U postgres -d mydb
psql (9.6.5)
Type "help" for help.

mydb=# \l
                                 List of databases
   Name    |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges
-----------+----------+----------+------------+------------+-----------------------
 mydb      | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
 postgres  | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
 template0 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
(4 rows)
```

> 注：如果要设定数据库用户和口令则需要在启动容器时添加对应的变量 `POSTGRES_PASSWORD`、`POSTGRES_USER`，详细的使用方法可以在[ arm32v7/postgres 镜像页面](https://hub.docker.com/r/arm32v7/postgres/)上查看。

`docker run` 常用的方法就是这些了，到这里就可以学会如何获取镜像，并且按照一般需要运行起来了。

如果想了解更多的相关参数可以查看[ Docker 官方文档](https://docs.docker.com/engine/reference/commandline/run/#options)了解。