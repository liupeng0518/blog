title: 使用 saltstack 在 Windows 服务器上发布 Web 应用 - Part 1
date: 2017-03-21 22:10:00
categories:
  - linux
feature: /images/logo/docker-logo.webp
tags:
  - SaltStack
toc: true
---

由于公司业务发生变化，之前单纯的使用 SVN 仓库钩子完成发布更新 IIS 站点无法满足新的需求。对比 Ansible、Puppet、SaltStack 之后选择了 SaltStack 作为运维工具。

选择 SaltStack 的原因如下：
* Puppet 使用 Ruby，而 Ansible 和 SaltStack 使用 Python。人生苦短，我选 Python，所以 Puppet Pass
* Ansible 是 agent-less 方案，通过 WinRM（Windows Remote Management） 来支持 Windows 管理。恩，稍微看了下 WinRM 的认证方案，太麻烦，所以 Ansible Pass

由于篇幅较长，所以分为两部分，第一部分是完成部署 saltstack，实现使用命令行来发布更新。第二部分使用 `jenins` 与 `salt-api`，实现自动持续集成。

<!-- more -->

### 部署 SaltStack

#### 安装 salt-master
> 参考：https://repo.saltstack.com/#rhel

由于 Windows 只能部署 minion ，只能在 Linux 上部署 master，以 CentOS 7 为例安装 `salt-master` 与 `salt-api`。
* 添加 SaltStack 源
```
sudo yum install https://repo.saltstack.com/yum/redhat/salt-repo-latest-1.el7.noarch.rpm
```
* 安装 `salt-master`
```
sudo yum install salt-master
```
* 启动 `salt-master`
```
sudo systemctl start salt-master
```

#### 配置 Windows Software Repo

* 配置 winrepo 项
编辑 `/etc/salt/master` 或者添加 `win_repo.conf` 到 `/etc/salt/master.d`

```
# 增加 winrepo 的仓库路径
winrepo_dir_ng: '/srv/salt/base/win/repo-ng'
# 设置 winrepo 的远端仓库
winrepo_remotes_ng:
  - https://github.com/saltstack/salt-winrepo-ng.git
```

* 同步远端仓库到 salt-master 本地仓库路径
```
salt-run winrepo.update_git_repos
```

同步完成后可以在 `winrepo_dir_ng` 路径中找到本地仓库的软件配置信息，以 `git-for-windows` 为例，由于国情问题，造成官方仓库中配置的 GitHub 下载地址下载基本无法成功，可以根据需要修改为 salt-mater 路径或其他下载地址。

```
# both 32-bit (x86) AND a 64-bit (AMD64) installer available
{% set PROGRAM_FILES = "%ProgramFiles%" %}
git:
  '2.11.0.3':
    full_name: 'Git version 2.11.0.3'
    {% if grains['cpuarch'] == 'AMD64' %}
    installer: 'salt://win/repo-ng/git/Git-2.11.0.3-64-bit.exe'
    {% elif grains['cpuarch'] == 'x86' %}
    installer: 'salt://win/repo-ng/git/Git-2.11.0.3-32-bit.exe'
    {% endif %}
    install_flags: '/VERYSILENT /NORESTART /SP- /NOCANCEL'
    uninstaller: '{{ PROGRAM_FILES }}\Git\unins000.exe'
    uninstall_flags: '/VERYSILENT /NORESTART & {{ PROGRAM_FILES }}\Git\unins001.exe /VERYSILENT /NORESTART & exit 0'
    msiexec: False
    locale: en_US
    reboot: False
```

* 同步 salt-master 本地仓库到 salt-minion
```
salt -G 'os:windows' pkg.refresh_db
```

* 在 salt-minion 上安装软件包
使用可选参数 `version` 安装指定的版本
```
salt 'winminion' pkg.install 'git' version=2.11.0.3
```



#### 安装 salt-minion

在 https://repo.saltstack.com/#windows 下载最新的安装包安装即可。

#### windows 上 ssh 相关问题

> 参考:
> https://docs.saltstack.com/en/latest/ref/modules/all/salt.modules.ssh.html
> https://docs.saltstack.com/en/latest/ref/states/all/salt.states.ssh_auth.html
> https://docs.saltstack.com/en/latest/ref/states/all/salt.states.ssh_known_hosts.html

注意：saltstack 的 ssh 模块，只在非 Windows 平台可用

* 用户目录

> 参考: https://docs.saltstack.com/en/latest/topics/installation/windows.html#running-the-salt-minion-on-windows-as-an-unprivileged-user
由于 ssh 相关配置都必须存放在 `~/.ssh` 下，对应 Windows 则是 `%USERPROFILE%\.ssh`，默认安装 salt-minion 以 Windows 服务启动时是使用的内置账户启动，无法在该账户用户目录下添加文件。
因此需要手动添加一个用户运行 `salt-minion` 服务

注意：添加的用户必须拥有 `salt-minion` 安装路径的写入权限(默认安装路径为 'C:\salt')

* known_hosts

* config

* RSA Key file