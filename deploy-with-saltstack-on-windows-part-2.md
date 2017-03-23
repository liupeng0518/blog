title: 使用 saltstack 在 Windows 服务器上发布 Web 应用 - Part 2
date: 2017-03-21 22:10:00
categories:
  - linux
feature: /images/logo/saltstack-logo.webp
tags:
  - SaltStack
toc: true
---

> 参考: https://docs.saltstack.com/en/latest/ref/clients/index.html

接着 Part-1 ，完成 pillar 和 state 之后，就是使用 jenkins 来实现自动化了，这里还需要用到 `salt-api`。
另外也可以选择其他持续集成平台，例如 BuildBot，可以直接使用 saltstack 的 python clinet api 来集成。

<!-- more -->

#### 配置 salt-api

> 参考：
> https://docs.saltstack.com/en/latest/ref/netapi/all/salt.netapi.rest_cherrypy.html
> https://docs.saltstack.com/en/latest/topics/eauth/index.html

注意：为了简便使用 `PAM` 认证方式

* 添加 salt-api 用户
```
useradd -M -s /sbin/nologin salt-api

echo "salt-api_passwd" | passwd salt-api —stdin
```

* 添加认证配置
添加 `auth.conf` 到 `/etc/salt/master.d`
```
external_auth:
  pam:
    salt-api:
      - .*
      - '@wheel'
      - '@runner'
```

* 添加 salt-api 配置
注意：由于会使用 nginx 统一管理证书，所以这里将 ssl 关闭
添加 `api.conf` 到 `/etc/salt/master.d`
```
rest_cherrypy:
  port: 8000
  disable_ssl: true
```

* 重启 `salt-master` 和 `salt-api` 服务
注意：`salt-master` 服务必须重启，否则接口会报 401 认证错误。
```
sudo systemctl restart salt-master salt-api
```

#### 添加 Jenkins Job

**部署流程**

* 开发推送发布文件到仓库时，自动发布到开发服务器

* 推送 Tag 到仓库时，如果 Tag 格式为`beat-*` 则对应 Tag 部署到测试服务器

* 完成测试可以发布提交，打上格式为 `release-*` 的 Tag 并推送到远程仓库，在 Job 中手动选择需要部署到生产服务器的 Tag

#### Git 钩子

> 参考:
> https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks
> https://www.digitalocean.com/community/tutorials/how-to-use-git-hooks-to-automate-development-and-deployment-tasks

钩子分客户端钩子与服务端钩子，服务端（裸仓库）钩子只支持以下三种：

 * `pre-receive`
 开始接受客户端推送时触发

 * `update`
 与 `pre-receive` 类似，但是会在每个被 update 的分支都触发

 * `post-receive`
 客户端推送完成之后触发

 需要在 `post-receive` 编写脚本，向 jenkins 服务器发起请求执行对应的 Job，完成自动化部署。