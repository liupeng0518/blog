title: 使用 saltstack 在 Windows 服务器上发布 Web 应用 - Part 2
date: 2017-03-23 22:10:00
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

#### 配置 Jenkins
> 参考:
> https://wiki.jenkins-ci.org/display/JENKINS/Git+Plugin
> https://wiki.jenkins-ci.org/display/JENKINS/Git+Parameter+Plugin
> https://wiki.jenkins-ci.org/display/JENKINS/saltstack-plugin

##### 部署流程

1. 开发推送发布文件到仓库时，自动发布到开发服务器

1. 推送 Tag 到仓库时，如果 Tag 格式为`beat-*` 则对应 Tag 部署到测试服务器

1. 完成测试可以发布提交，打上格式为 `release-*` 的 Tag 并推送到远程仓库，在 Job 中手动选择需要部署到生产服务器的 Tag

考虑到测试服务器和生产服务器的部署需要可以回滚，所以使用了三个 Job 来对应三个流程。
由于公司开发者都是 .net 技术栈，对 Git 不熟悉，所以没有使用分支的方式来来区分不同环境，所以有发布都推送到 master 分支，只通过 Tag 名称来区分。

##### 配置构建项目

需要安装`Git Plugin` `Git Parameter Plugin` `saltstack-plugin` 三个插件。添加好三个构建项目之后，都需要勾选`触发远程构建`，并设置好`身份验证令牌`。

注意：部署到生产环境可以不做触发构建，只做手动执行。

* 发布到开发服务器

只需要在 `Branches to build` 保持默认的监听 `*/master`就可以了。

* 发布到测试服务器

在 `Repositories` 中点击 高级 按钮，在 Refspec 中输入 `+refs/tags/beta-*:refs/remotes/origin/tags/beta-*`

开启参数化构建，选择 `Git Parameter`,在 Tag filter 中输入 `beta-*`

* 发布到生产服务器

在 `Repositories` 中点击 高级 按钮，在 Refspec 中输入 `+refs/tags/release-*:refs/remotes/origin/tags/release-*`

开启参数化构建，选择 `Git Parameter`,在 Tag filter 中输入 `release-*`

* 构建步骤配置

构建步骤中选择添加 `Send a message to Salt API`， 认证信息需要和配置 salt-api 的认证对应。
`Function`、`Arguments`、`Target`、`Target Type` 组成了最终使用的 salt 命令

```
salt -G 'web-server' state.apply your_state pillar=`{"foo1":"var1","foo2":"var2"}`
```

以上面的命令为例，`Function` 是 `state.apply`；`Target` 是 `web-server`；`Target Type` 是 `G`。
具体关于 saltstack Target 的信息可以查看官方文档。

实际项目中，我将 jenkins 获取的 git 标签作为参数传递到 salt 中执行，在 states 中根据参数值获取发布文件。

> https://docs.saltstack.com/en/latest/topics/targeting/compound.html#targeting-compound

整个流程就是开发者推送 -> 触发 Jenkins 构建任务 -> 执行编写好的 salt states 进行部署。

自动部署时，是部署新标签对应的提交。需要回退时，选择需要回退的 Tag 手动执行构建就可以完成回退。

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

由于代码仓库的变动是由 Jenkins 插件完成检测的，所以只需要请求对应 Job 的远程构建 URL 即可。

```
curl  JENKINS_URL/job/api-dev/build?token=TOKEN_NAME
```

#### 注意事项

* 没有实现 TFS 自动构建的步骤，开发者自己生成发布文件后推送到仓库。
* 如果在 `salt-api` 中使用自签名证书, Jenkins 请求接口时会有一个证书信任错误。我的解决方案是使用 Nginx 作为代理，证书在 Nginx 这里部署。
* 由于只有一个 master 分支，推送标签时仍然会触发只监听 master 分支的构建任务。不过如果代码没有变化，salt 执行时也不会拉取新文件。
* 如果使用 GitLab 作为仓库，可以直接使用 Gitlab Hook Plugin 更加方便一些。