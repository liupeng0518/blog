title: 使用 SaltStack 在 Windows 服务器上发布 Web 应用 - Part 1
date: 2017-03-21 22:10:00
categories:
  - CI
feature: /images/logo/saltstack-logo.webp
tags:
  - SaltStack
toc: true
---

由于公司业务发生变化，之前单纯的使用 SVN 仓库钩子发布、更新 IIS 站点无法满足新的需求。对比 Ansible、Puppet、SaltStack 之后选择了 SaltStack 作为运维工具。

选择 SaltStack 的原因如下：

* Puppet 使用 Ruby，而 Ansible 和 SaltStack 使用 Python。人生苦短，我选 Python， Pass。
* Ansible 是 agent-less 方案，通过 WinRM（Windows Remote Management） 来支持 Windows 管理。恩，稍微看了下 WinRM 的认证方案，太麻烦，Pass。

由于篇幅较长，所以分为两部分，第一部分是完成部署 SaltStack，实现使用命令行来发布更新。第二部分使用 `Jenkins` 与 `salt-api`，实现自动持续集成。

<!-- more -->

### 部署 SaltStack

#### 安装 salt-master

> 参考: https://repo.saltstack.com/#rhel

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
> 参考: https://docs.saltstack.com/en/latest/topics/windows/windows-package-manager.html

* 配置 winrepo 项
编辑 `/etc/salt/master` 或者添加 `win_repo.conf` 到 `/etc/salt/master.d`

```
# 增加 winrepo 的仓库路径
winrepo_dir_ng: '/srv/salt/base/win/repo-ng'
# 设置 winrepo 的远端仓库
winrepo_remotes_ng:
  - https://github.com/saltstack/salt-winrepo-ng.git
```

* 同步远端仓库到 master 本地仓库路径
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

* 同步 master 本地仓库到 minion
```
salt -G 'os:windows' pkg.refresh_db
```

* 在 minion 上安装软件包
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

注意：SaltStack 的 SSH 模块，只在非 Windows 平台上可用。

* 用户目录

> 参考: https://docs.saltstack.com/en/latest/topics/installation/windows.html#running-the-salt-minion-on-windows-as-an-unprivileged-user

由于 ssh 相关配置都必须存放在 `~/.ssh` 下，对应 Windows 则是 `%USERPROFILE%\.ssh`，默认安装 salt-minion 以 Windows 服务启动时是使用的内置账户启动，无法在该账户用户目录下添加文件。
因此需要手动添加一个用户运行 `salt-minion` 服务

注意：添加的用户必须拥有 `salt-minion` 安装路径的写入权限(默认安装路径为 'C:\salt')

* known_hosts、config、rsa

> 参考:
> https://docs.saltstack.com/en/latest/ref/modules/all/salt.modules.file.html
> https://docs.saltstack.com/en/latest/ref/states/all/salt.states.file.html

`known_hosts` 用于保存信任机器的指纹，`config` 用于配置指定 host 所使用的用户和密钥，`rsa` 保存用户私钥，它们都保存在用户目录下的 `.ssh` 文件夹中。

```
Host gogs.tomczhen.com
User git
Identityfile ~/.ssh/gogs_rsa
```

上面就是一个 `config` 文件的内容，可以为不同的 Host 与 用户配置不同的密钥。

这里为了简单，是直接将 master 的文件发布到 minion 上指定的路径，

`salt-minion` 运行的用户可以通过 grains 获取。将内容保存在 pillar 中，并使用替换内容的方式修改应该更加合理一些。

```
deploy_rsa:
  file.managed:
    - name: C:\Users\saltminion\.ssh\deploy_rsa
    - source: salt://ssh/deploy_rsa
    - makedirs: true

config_file:
  file.managed:
    - name: C:\Users\saltminion\.ssh\config
    - source: salt://ssh/config
    - makedirs: true

known_hosts_file:
  file.managed:
    - name: C:\Users\saltminion\.ssh\known_hosts
    - source: salt://ssh/known_hosts
    - makedirs: true
```

### 编写 States

#### 设置 minion 的 grains

> 参考: https://docs.saltstack.com/en/latest/topics/grains/

可以在 minion 配置文件中添加 grains 段来设置 minion 的 grains

```
grains:
  roles:
    - web-server
    - redis
  deployment: dev
```

grains 可以理解为“以服务器为作用域的变量”。

执行下面的命令可以查看各个 minion 的 grains 数据
```
salt '*' grains.items
```

#### 编写 pillars

> 参考:
> https://docs.saltstack.com/en/latest/topics/pillar/index.html
> https://docs.saltstack.com/en/latest/topics/targeting/index.html

pillar 保存在 master，可以根据执行的 target 来读取数据。

执行下面的命令可以查看各个 minion 的 grains 数据

```
salt '*' pillar.items
```

#### 编写 states

> 参考:
> https://docs.saltstack.com/en/latest/topics/states/index.html
> https://docs.saltstack.com/en/latest/topics/yaml/index.html
> https://docs.saltstack.com/en/latest/topics/jinja/index.html
> https://docs.saltstack.com/en/latest/ref/modules/all/salt.modules.saltutil.html

前面关于解决 Windows 上 ssh 密钥、known_host、config 的问题中就是使用的 states。简单来说就是使用 yaml 的语法，将需要执行 modules/states 的命令组合起来。
在执行过程中，通过不同 target 的 grains 来分配不同 pillar 数据，来解决配置问题。

saltstack 默认是 jinja 模板，所以可以使用模板自带的语法来实现一些逻辑流程判断。可以说不同的 target 上最终执行的 states 是由模板所生成出来的，只要关注最终的生成内容即可。

```
{% set api_config = salt['pillar.get']('api:' + salt['pillar.get']('target')) %}
{% set service_config = salt['pillar.get'](salt['pillar.get']('target')) %}
install_git:
  pkg.installed:
    - names:
      - git

{{ salt['grains.get']('customers') }}_api:
  git.latest:
    - name: {{ salt['pillar.get']('api:repo:url') }}
    - target: {{ salt['grains.get']('wwwroot') + '\\' + api_config.website.name }}
    {% if salt['pillar.get']('git_rev') %}
    rev: {{ salt['pillar.get']('git_rev') }}
    {% endif %}
    - force: true
    - force_checkout: true
    - force_reset: true
    - require:
      - pkg: install_git

{% if salt['pillar.get']('target') != 'dev' %}
{{ salt['grains.get']('wwwroot') + api_config.website.name + '\\Web.config' }}:
  file.managed:
    - name: {{ salt['grains.get']('wwwroot') + '\\' + api_config.website.name + '\\Web.config' }}
    - source: salt://api/web.config.jinja
    - template: jinja
    - makedirs: true
{% endif %}
```

注意：grains、pillar 等数据需要执行同步才会真正在 minion 上生效，可以执行下面的命令同步所有配置，也可以参考文档来查看单独的同步的方法。

```
salt '*' saltutil.sync_all
```

使用下面的命令可以执行编写好的 states

```
salt '*' state.apply your_state
```

在执行时设置 pillar 变量
```
salt '*' state.apply your_state pillar='{"foo1":"var1","foo2":"var2"}'
```

#### Target

> 参考: https://docs.saltstack.com/en/latest/topics/targeting/

Target 就是挑选目标 minion，可以使用 grains、pillar 等 SaltStack 自带的数据来挑选 minion。

按操作系统选择 minion
```
salt -G 'os:windows' test.ping
```

按 pillar 数据选择 minion
```
salt -I 'key:value' test.ping
```

也可以组合条件进行选择
```
salt -C 'G@os:windows and web-server-* or E@db.*' test.ping
```

#### 配置文件 demo

根据公司项目需要编写的示例

https://gogs.tomczhen.com/tomczhen/saltstack-example