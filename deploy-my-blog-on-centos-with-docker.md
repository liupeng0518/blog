title: 在 CentOS 上使用 Docker 部署个人博客和 Git 仓库
date: 2017-03-21 22:10:00
categories:
  - linux
feature: /images/logo/docker-logo.webp
tags:
  - nginx
  - https
  - letsencrypt
  - docker
toc: true
---

从开始自己搭建博客已经过去 3 年了，最开始是在 FreeBSD 上运行的 WordPress，由于配置低，经常因为数据库挂掉而无法访问。几经折腾，先是迁移到 Ghost，然后是 HEXO。
虽然用过不少笨方法解决问题，好在也获取了不少经验与知识。

随着 Docker 的流行，感觉不得不放弃 FreeBSD 了。虽然早就迁移到 CentOS，并用 Docker 完成了部署，这里补充一下记录，算是知识的整理与回顾。

<!-- more -->

### 预期目标

* Gogs Git 仓库
* Hexo 博客
* 部署 https 证书

### 服务器 sshd 配置

注： 因为后面 gogs 要使用默认的 22 端口，所以这里将服务器的 ssh 服务端口修改为 10022
```
# 修改 sshd 服务端口
Port 10022

# 启用密钥登录
RSAAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile      .ssh/authorized_keys

# 关闭密码登录
PasswordAuthentication no
ChallengeResponseAuthentication no

# 是否允许 root 用户登录
PermitRootLogin yes

# 是否允许空密码登录
PermitEmptyPasswords no
```

* 重启 sshd 服务
```
sudo systemctl restart sshd
```

### Docker

#### 安装 docker-ce

> 参考: https://docs.docker.com/engine/installation/linux/centos/#install-docker

* 安装 `yum-utils`
```
sudo yum install -y yum-utils
```

* 使用 `yum-config-manager` 来添加 docker-ce 源
```
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
```

* 安装 docker-ce
```
sudo yum makecache fast && yum install docker-ce
```
*安装完成后可以使用 DaoCloud 的脚本配置 `registry-mirror`，解决镜像拉取慢的问题。*

* 启动 docker 服务
```
sudo systemctl start docker
```

#### 安装 docker-compose

> 参考: https://docs.docker.com/compose/install/#alternative-install-options

* 添加 EPEL源
```
sudo yum install epel-release
```

* 安装 pip（python2）
```
sudo yum install python2-pip
```

* 安装 docker-compose
```
sudo pip2 install docker-compose
```

#### 编写 docker 编排文件

> 参考
> * https://docs.docker.com/compose/compose-file/
> * https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_atomic_host/7/html/container_security_guide/docker_selinux_security_policy

注意: 阿里云默认是关闭 selinux 与 firewalld 的，如果开启了 selinux 用于挂载的目录需要执行
```
chcon -Rt svirt_sandbox_file_t /docker_volume_path
```

##### Gogs

* gogs.yaml
```yaml
version: "2"
services:
    pgsql-gogs:
        container_name: pgsql-gogs
        image: postgres:9.6.2-alpine
        volumes:
            - /mnt/pgdata:/var/lib/postgresql/data
        expose:
            - "5432"
    gogs:
        container_name: gogs
        image: gogs/gogs:latest
        volumes:
            - /mnt/gogs:/data
        links:
            - pgsql-gogs
        ports:
            - "3000:3000"
            - "22:22"
```
##### HEXO

HEXO只是用来生成静态文件，所以并不需要一直运行，现成的镜像并不满足我的需要，所以这里自己来 build 镜像。
* dockerfile
```
FROM node:6.10.0
MAINTAINER Tom CzHen "tom.czhen@gmail.com"
WORKDIR /home/hexo
RUN npm install hexo-cli -g
RUN npm install hexo --save
RUN hexo init
ENTRYPOINT ["hexo"]
CMD ["--help"]
```

使用时需要将 `public` `source` `themes` 挂载到服务器目录，只是用来生成静态页，将博客源文件拉到 `source` 目录之后运行一下即可。

```
docker run --name hexo --rm \
-v /mnt/data/hexo/_config.yml:/home/hexo/_config.yml \
-v /mnt/data/hexo/public:/home/hexo/public \
-v /mnt/data/hexo/source:/home/hexo/source \
-v /mnt/data/hexo/themes:/home/hexo/themes \
tomczhen/hexo g
```
然后将 `public` 目录软链接到 Nginx 站点根目录完成部署。

### 配置 Nginx 以及 https 证书

#### 安装 Nginx 并配置站点

* 安装 nginx
```
sudo  yum install nginx
```
注意: 关于 https  配置可以在 https://mozilla.github.io/server-side-tls/ssl-config-generator/ 根据需要自动生成。

* gogs.tomczhen.com.conf
```
server {
    listen 443 ssl;
    server_name gogs.tomczhen.com;
    ssl_certificate     /etc/nginx/certs/tomczhen.com/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/tomczhen.com/privkey.pem;

    location /.well-known/acme-challenge/ {
      default_type  "text/plain";
      alias         /usr/share/nginx/html/letsencrypt/;
    }

    location / {
        proxy_set_header  X-Real-IP  $remote_addr;
        proxy_pass http://gogs$request_uri;
    }
}


server {
    listen 80;
    server_name gogs.tomczhen.com;

    location /.well-known/acme-challenge/ {
      default_type  "text/plain";
      alias         /usr/share/nginx/html/letsencrypt/;
    }

    location / {
      rewrite ^/(.*)$ https://gogs.tomczhen.com/$1 permanent;
    }
}

upstream gogs {
    server localhost:3000;
}
```

* tomczhen.com.conf
```
server {
    listen              443 ssl http2;
    server_name         tomczhen.com www.tomczhen.com;
    ssl_certificate     /etc/nginx/certs/tomczhen.com/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/tomczhen.com/privkey.pem;
    # ssl_session_timeout 1d;
    # ssl_session_cache shared:SSL:50m;
    # ssl_session_tickets off;

    ssl_protocols TLSv1.2;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256';
    # ssl_prefer_server_ciphers on;

    ssl_stapling on;
    ssl_stapling_verify on;

    location /.well-known/acme-challenge/ {
      default_type  "text/plain";
      alias         /usr/share/nginx/html/letsencrypt/;
    }

    location / {
      root   /usr/share/nginx/html/hexo;
      index  index.html index.htm;
    }
}

server {
    listen 80;
    server_name tomczhen.com www.tomczhen.com;

    location /.well-known/acme-challenge/ {
      default_type  "text/plain";
      alias         /usr/share/nginx/html/letsencrypt/;
    }

    location / {
      rewrite ^/(.*)$ https://www.tomczhen.com/$1 permanent;
    }

}
```

#### 部署 Let's Encrypt 证书

>参考: https://github.com/lukas2511/dehydrated

* 安装 git
```
sudo yum install git
```
* 获取 dehydrated
```
git clone https://github.com/lukas2511/dehydrated
```
* 添加 domains.txt
```
echo "tomczhen.com www.tomczhen.com gogs.tomczhen.com" > domains.txt
```
* 配置 config
注意: 配置参数与 nginx 站点配置有关联，请仔细确认。
```
# Output directory for generated certificates
# 证书生成路径
CERTDIR="/etc/nginx/certs"

# Output directory for challenge-tokens to be served by webserver or deployed in HOOK (default: /var/www/letsencrypt)
# 生成验证文件的路径
WELLKNOWN="/usr/share/nginx/html/letsencrypt"

# E-mail to use during the registration (default: <unset>)
# 联系人邮箱
CONTACT_EMAIL="tom.czhen@gmail.com"
```
* 生成证书
```
./dehydrated -c
```