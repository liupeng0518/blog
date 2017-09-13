title: 在树莓派上学习 Docker —— Part 1
date: 2017-09-13 19:20:00
categories:
  - Linux
tags:
  - Docker
toc: true
---

以树莓派和 Docker 的火热程度相信不需要在额外介绍了，本篇的计划就是在树莓派上学会如何使用 Docker。

开局只有一块树莓派3，其余全靠下载 `_(:з」∠)_`

<!--more-->

# 安装

树莓派上最常使用的发行版就是 Raspbian 了，不过由于树莓派很流行其实也有很多其他的选择，都可以了解一下。

树莓派官方在 2016 八月份时曾经发布一篇 [DOCKER COMES TO RASPBERRY PI](https://www.raspberrypi.org/blog/docker-comes-to-raspberry-pi/)，宣布了 Docker 官方对树莓派的支持。
在这篇文章中有提到一个安装脚本 `curl -sSL https://get.docker.com | sh` 就可以安装好 Docker 了。
另外还贴出大神 Show 由树莓派 Zero 组成的 Docker Swarm 集群的 [TWITTER](https://twitter.com/alexellisuk/status/764518552154042369)。

## Raspbian

虽然有一键安装脚本存在，不过尝试手动安装也是很有必要的。

在[官方文档](https://docs.docker.com/engine/installation/#server)中，可以看到 Docker CE ARM 支持的发行版有 Debian 和 Ubuntu。

而在 Debian 的[安装文档](https://docs.docker.com/engine/installation/linux/docker-ce/debian/#os-requirements)中可以明确的看到有对 Raspbian 的支持。

>OS requirements

>To install Docker CE, you need the 64-bit version of one of these Debian or Raspbian versions:

>* Stretch (stable) / Raspbian Stretch
* Jessie 8.0 (LTS) / Raspbian Jessie
* Wheezy 7.7 (LTS)

>Docker CE is supported on both x86_64 (or amd64) and armhf architectures for Jessie and Stretch.

这里跟着文档走就可以安装好 Docker 了（以 Raspbian Stretch 为例）。

### 配置安装源

安装之前可以先修改 Raspbian 的安装源为国内镜像，比如[科大开源镜像](https://mirrors.ustc.edu.cn/)，具体操作可以查看科大的[帮助文件](https://lug.ustc.edu.cn/wiki/mirrors/help/raspbian)。
当然还有一个选择就是[阿里开源镜像](http://mirrors.aliyun.com/help/raspbian)，个人来说推荐用阿里，毕竟首富家开的，还是为大学节省点经费比较好。

1. 更新 `apt` 软件包索引：

```shell
$ sudo apt-get update
```

2. 允许 `apt` 通过 HTTPS 使用镜像仓库：

```shell
$ sudo apt-get install \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg2 \
     software-properties-common
```

3. 添加 Docker 的官方 GPG 密钥：

```shell
$ curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo apt-key add -
```

验证密钥 ID 是否为 9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88。

```shell
$ sudo apt-key fingerprint 0EBFCD88

 pub   4096R/0EBFCD88 2017-02-22
       Key fingerprint = 9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88
 uid                  Docker Release (CE deb) <docker@docker.com>
 sub   4096R/F273FCD8 2017-02-22
```

4. 添加 Docker CE 仓库

```
echo "deb [arch=armhf] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
     $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list
```

注意：

截至本文发表时（2017年9月13日）

上面的命令添加仓库之后，在 `apt-get update` 过程中，可以看到 Raspbian Stretch 的 Docker 仓库中 armhf 架构提示 Not Found。

使用下面的命令重新添加后正常。与第一个命令的结果不同的是 `raspbian` 变成了 `debian`，考虑到后续官方会在 Raspbian 仓库中提供正式的包，因此，**如果遇到任何问题请先看看官方英文文档。**

```
$ echo "deb [arch=armhf] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | \
     sudo tee /etc/apt/sources.list.d/docker.list
```


### 安装 DOCKER CE

1. 更新 apt 软件包索引：

```
$ sudo apt-get update
```

2. 安装最新版本的 Docker CE：

```
$ sudo apt-get install docker-ce
```

3. 将当前用户添加到 docker 组（可选）：

```
$ sudo usermod -aG docker $USER
```

这样重新登录 SSH 之后执行 docker 命令时就不需要加上 `sudo` 了。

4. 增加 Docker 仓库镜像：

修改 `/etc/docker/daemon.json` 文件，添加上 registry-mirrors 键值。

```
{
  "registry-mirrors": ["https://registry.docker-cn.com"]
}
```

修改保存之后重启 Docker 即可生效

```
$ sudo systemctl restart docker
```

上面的镜像地址是由 [Docker 中国](https://www.docker-cn.com/)官方提供的，可以在[中文网站](https://www.docker-cn.com/)上查看一些其他关于 Docker 的资料。

需要注意的是虽然有提供中文文档，不过截至本文发布时，大部分内容仍然是英文，而且内容还有滞后，所以还是看英文文档吧。

重启 Docker 之后，可以查看一下是否配置成功

```
$ sudo docker info
```

如果有以下信息就表示镜像配置成功：

```
...
Registry Mirrors:
 https://registry.docker-cn.com/
...
```

## Hypriot

在 Docker 官方支持树莓派之前，[Hypriot](https://blog.hypriot.com/) 就提供了非官方支持，并且有发布专门为树莓派制作的发行版。
在[https://blog.hypriot.com/downloads/](https://blog.hypriot.com/downloads/)直接下载镜像，用它来启动树莓派就可以直接使用 Docker 了。

虽然是非官方支持，不过 Hypriot 也是相当给力的，也经常发布一些关于 Docker ARM 的技术资讯，值得关注。

## resinOS

[resinOS](https://resinos.io/) 与 [CoreOS](https://coreos.com/) 类似，但是专注与嵌入式平台。

resinOS 不仅仅是为了树莓派打造，同时也支持其他硬件，不过这里我们只需要下载[树莓派镜像](https://resinos.io/#downloads-raspberrypi)。

开源智能家居平台 [Hass.io](https://home-assistant.io/hassio/) 就是基于 resinOS 开发的。
Hass.io 的插件以 Docker 容器的方式部署运行，大大降低了安装插件的复杂性与风险，可以说是打造了一套基于树莓派的微服务架构。

另外 resinOS 还有发布一个跨平台的烧写 SD 卡软件 [Etcher](https://etcher.io/)。
使用 Mac/Linux 对 DD 命令不太熟悉的话，那么用 Etcher 可以避免写错盘的悲剧发生。Windows 平台则推荐另一款开源软件 [Rufus](https://rufus.akeo.ie/?locale=zh_CN)。

# Hello World

最后，用容器向世界打声招呼：

```
$ sudo docker run --rm armhf/hello-world
```