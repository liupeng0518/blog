title: 如何在 ClearOS 上安装 Docker
date: 2016-05-12 14:25:51
categories:
  - docker
description: 在 ClearOS 上安装 Docker 并使用 DaoCloud 私有集群管理平台
feature: /images/logo/clearos-logo.webp
tags:
  - linux
  - docker
toc: true
---
ClearOS 是一个适用于小型企业的网络和网关服务器，基于分布式环境而设计。ClearOS 是在 CentOS 基础上构建的，发行版包括通过一个直观的基于 Web 的功能，哪些是易于配置的综合服务广泛列表界面。在 ClearOS 发现的一些工具包括防病毒，防垃圾邮件，虚拟专用网，内容过滤，带宽管理，SSL 的认证，网络日志分析器，只是名称可用的模块数。其分布提供的免费下载，为 18 个月的免费安全性更新的包容性。

<!-- more -->

<h2 id="install_docker">安装 Docker</h2>

添加安装源:
```bash
nano /etc/yum.repos.d/docker.repo
```

将下面的文件添加到 docker.repo:
```text
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
```

安装 Docker：
```bash
yum install docker-engine
```

启动 Docker:
```bash
systemctl enable docker
systemctl start docker
```

<h2 id="config_clearos">配置 ClearOS</h2>


由于 ClearOS 7.2 社区版是基于 CentOS 7，使用了 firewalld，并且有很多事件会触发 ClearOS 执行重启 firewalld，造成 Docker 添加的 iptalbes 规则丢失，引起容器网络问题，所以需要进行一些修改。

<h3 id="config_docker_daemon">配置 Docker 服务</h3>

容器会继承宿主机的 DNS 配置， ClearOS 默认的 DNS 是 127.0.0.1，会造成容器无法解析域名。所以需要修改 docker 服务启动参数，让容器启动时附带设置好的 DNS。

编辑 docker.service
```bash
nano /usr/lib/systemd/system/docker.service
```

在启动命令后添加参数 `--dns`

```text
ExecStart=/usr/bin/docker daemon -H fd:// --dns=114.114.114.114
```

重启 docker daemon 让配置生效
```bash
systemctl reload-daemon
systemctl restart docker
```

<h3 id="config_firewalld">firewalld 问题</h3>

启动 Docker 之后如果 firewalld 服务重启，docker 添加的 iptalbes 规则会丢失，引起容器网络问题，有三种方案解决。

* 使用`--net=host`参数启动容器

使用`--net=host`参数启动的容器是直接使用宿主机的网络，不需在要 iptables 添加规则，所以不受影响。

* 在 firewalld 重启后重启 Docker

可以通过修改 ClearOS 关于防火墙启动后执行的脚步来完成

```bash
nano /etc/clearos/firewall.d/local
```

在文件中添加命令
```bash
systemctl try-restart docker
```

>为什么不是 `systemctl restart docker` ?
>使用 `systemctl restart docker` 的话，在 firewalld 连续重启触发脚本时造成容器启动异常，必须手动启动或者重新启动 ClearOS 主机才能解决。

* 备份相关规则并在 firewalld 重启后添加

ClearOS 使用了监听事件来触发 firewall 重启，可以修改脚本实现，firewalld 重启前将 Docker 相关的 iptables 规则导出备份，重启 firewalld 完成后将备份的规则重新添加，这样就不需要重启 Docker 服务。

可以通过修改 syswatch 中的重启 RestartFirewall 段脚本实现

```bash
nano /usr/sbin/syswatch
```

```perl
###############################################################################
#
# RestartFirewall: Restart the firewall
#
###############################################################################

sub RestartFirewall() {
    LogMsg("info", "system", "restarting firewall\n");
    `/etc/rc.d/init.d/firewall restart 2>/dev/null`; 
}
```

<h2 id="daocloud">DaoCloud 私有集群</h2>

DaoCloud 的私有集群可以很方便的管理主机容器，在 ClearOS 安装时需要注意，daomonit 安装时需要手动安装，自动安装脚本会根据系统执行，而 ClearOS 不在脚本之中。
同样需要注意的是 时速云 的安装脚本也有一样的问题，需要修改脚本后运行。

---

<div align="center">
![](/images/logo/alipay_tomczhen.webp)  
如果对您有帮助的话，可以考虑通过支付宝请作者喝杯咖啡。
</div>