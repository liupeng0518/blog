title: FreeBSD安装部署Hexo
date: 2015-12-10 22:18:51
categories: 
  - freebsd
  - hexo
feature: http://www.tomczhen.com/images/logo/hexo-logo.webp
tags:
  - freebsd
  - hexo
toc: true
---
>参考资料:
>[使用GitHub和Hexo搭建免费静态Blog](http://wsgzao.github.io/post/hexo-guide/)  
>[FreeBSD: Nginx Virtual Hosting Configuration](http://www.cyberciti.biz/faq/freebvsd-nginx-namebased-virtual-hosting-configuration/)  
>[Hexo博客后台运行技巧](http://www.tuijiankan.com/2015/05/08/hexo-forever-run/)

******

<h2 id="freebsd">FreeBSD</h2>

<h3 id=“pkg”>修改 pkg 源</h3>

`ee /etc/pkg/FreeBSD.conf`

```
FreeBSD: {
  url: "pkg+http://pkg0.twn.freebsd.org/freebsd:10:x86:64/latest/",
  mirror_type: "srv",
  signature_type: "fingerprints",
  fingerprints: "/usr/share/keys/pkg",
  enabled: yes
}
```
访问[http://pkg.freebsd.org](http://pkg.freebsd.org)可以查看镜像站点，选择速度最快的替换即可。

<!-- more -->

<h2 id="nginx">Nginx</h2>

******

<h3 id="install-nginx">安装Nginx</h3>

`pkg install nginx`

在 `/etc/rc.conf` 中添加 `nginx_enable="YES"`
使用 `service nginx start` 启动 nginx 服务，在浏览器中输入服务器 IP 检查 nginx 是否工作正常。

<h3 id="nginx-vhosts">配置Nginx虚拟站点</h3>

`ee /usr/local/etc/nginx/nginx.conf`

编辑ngxin.conf文件，并添加以下内容

```
# virtual hosting
include /usr/local/etc/nginx/vhosts/*;
```

在 vhost 目录中新建 `.conf` 文件，例如: `yourhostname.conf` 为自己的站点单独创建配置文件方便管理。

`mkdir /usr/local/etc/nginx/vhosts`

在新建的配置文件中输入以下内容。

```shell
server {
    listen  80;
    server_name yourhostname.com;
    location / {
            root   /mnt/hexo/public;
            index  index.html index.htm;
    }
}
```

最后使用 `service nginx restart` 重启 nginx 使新配置生效，如果出现检查配置文件错误，请按提示检查配置文件。

注意：`/mnt/hexo/public` 为 hexo 生成静态文件的路径，由于目前 hexo 还未启动，所以还无法正常访问 vhost 绑定的域名。

---

<h2 id="hexo">Hexo</h2>

<h3 id="hexo-reday">准备</h3>

<h4 id="install-node">安装 node</h4>

`pkg install node`

<h4 id="install-npm">安装 npm</h4>

`pkg install npm`

<h4 id="installhexo">安装 Hexo</h4>

`npm install hexo -g`
`npm instal hexo-cli -g`

可以使用淘宝NPM镜像作为安装源安装——[淘宝 NPM 镜像](http://npm.taobao.org/)

`npm install hexo-cli -g --registry=https://registry.npm.taobao.org`
`npm instal hexo -save --registry=https://registry.npm.taobao.org`

<h3 id="hexo-init">初始化Hexo</h3>

<h3 id="auto-de">自动化发布</h3>
每次提交后需要手动生成静态文件，可以利用 git hook 来实现自动发布生成。