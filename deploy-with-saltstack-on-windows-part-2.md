title: 使用 saltstack 在 Windows 服务器上发布 Web 应用 - Part 1
date: 2017-03-21 22:10:00
categories:
  - linux
feature: /images/logo/saltstack-logo.webp
tags:
  - SaltStack
toc: true
---

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