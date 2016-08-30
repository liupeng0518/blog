title: 如何在FreeBSD中安装Shadowsocks并使用PAC科学上网
date: 2015-12-08 19:25:51
categories:
  - freebsd
feature: http://www.tomczhen.com/images/logo/shadowsocks-logo.webp
tags: 
  - freebsd
  - shadowsocks
toc: true
---
<H2 id="first">首先</h2>

需要在Girl(G) Friend(F) Wall(W)外的服务器上搭建好 Shadowsocks 服务端。

<h2 id="shadowsocks">Shadowsocks</h2>

<h3 id="pkg">修改 pkg 源</h3>

`ee /etc/pkg/FreeBSD.conf`

```
FreeBSD: {
  url: "pkg+http://pkg0.twn.freebsd.org/freebsd:9:x86:64/latest/",
  mirror_type: "srv",
  signature_type: "fingerprints",
  fingerprints: "/usr/share/keys/pkg",
  enabled: yes
}
```
访问[http://pkg.freebsd.org](http://pkg.freebsd.org)可以查看镜像站点，选择速度最快的替换即可。

<h3 id="install-shadowsocks">安装 shadowsocks-libev</h3>

`pkg install shadowsocks-libev`

注意：FreeBSD 上只支持 ss-local，ss-server，ss-tunnel 不支持 ss-redir。

<!-- more -->

<h3 id="config-shadowsocks">配置 Shadowsocks</h3>

假设安装 Shadowscosk 的服务器 IP 为 `192.168.1.254`
根据服务端 IP 及端口生成配置文件 `ss-local.json` ,格式如下
```
{
"server":"YourServer",
"server_port":9009,
"local_address":"192.168.1.254",
"local_port":1080,
"password":"YourPassword",
"timeout":300, 
"method":"aes-256-cfb",
"fast_open":false
}
```

<h3 id="auto-shadowsocks">开机启动 Shadowsocks</h3>

在 rc.local 中添加开机启动命令
`/usr/local/bin/ss-local -c /etc/ss-local.json -f /var/run/ss-local.pid`

<h2 id="pac">PAC</h2>

<h3 id="summary-pac">PAC 简介</h3>

代理自动配置（英语：Proxy auto-config，简称 PAC）是一种网页浏览器技术，用于定义浏览器该如何自动选择适当的代理服务器来访问一个网址。

<h3 id="config-pac">配置 pac 脚本</h3>

　　根据 Girl Friend Wall 的屏蔽列表生成的 PAC 文件 http://pan.baidu.com/s/1mgq0LNa

　　将下载好的 PAC 文件中 proxy 修改为与 ss-local.json 配置中对应的本地 IP 与端口，rules 段则可以根据需要修改，需要注意的是 ss-local 为 socks5 代理，IE 是不支持的。

　　按照上面的配置，需要将 PAC 文件对应代码段修如下

`var proxy = "SOCKS5 192.168.8.254:1080";`

<h3 id="putout-pac">发布 pac 脚本</h3>

　　发布 pac 脚本需要使用网页服务器,发布服务器可以不和 ss-local 在同一机器,例如使用 Windows 服务器 (IIS) 发布 PAC。
	需要添加 MEMI 类型，文件类型为 `.pac` ，类型值为 `application/x-ns-proxy-autoconfig` 。
	推荐在运行 ss-local 的机器上安装 Nginx 发布，统一管理。这里，默认在同一台服务器上发布 PAC 文件，在本篇的例子中 PAC 地址为`http://192.168.1.254/proxy.pac`

<h2 id="use-pac">如何使用</h2>

<h3 id="use-pac-web">在浏览器中使用 PAC</h3>

　　Windows 系统在 `Internet选项->连接->局域网`设置，勾选`使用自动配置脚本`，然后在地址中输入 `http://192.168.1.254/proxy.pac`。
　　由于 IE 不支持 socks5 代理，因此只能在其他浏览器中科学上网。不使用插件的情况下，Chrome 按系统设置，需要按以上步骤设置，FireFox 则可以单独设置 PAC 或者默认按系统配置。

<h2 id="ps">补充说明</h2>

　　以上并未解决 DNS 污染问题，可以使用 ss-tunnel 转发 DNS 请求解决，另外可以使用 ss-local 的 --acl 参数可以控制代理访问的地址。  
　　需要 HTTP 代理的话，可以使用其他应用将 socks5 代理转为 http 代理，同时修改 pac 脚本开启 http 代理。

-----

<div align="center">
![](http://pic.tomczhen.com/alipay_QR.png)  
如果对您有帮助的话，可以考虑通过支付宝请作者喝杯咖啡。
</div>