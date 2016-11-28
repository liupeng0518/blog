title: 在 Nginx 与 IIS 上初试 Let’s Encrypt 证书部署 
date: 2016-08-31 13:45:00
categories: 
  - linux
feature: /images/logo/letsencrypt-logo.webp
tags: 
  - nginx
  - https
  - letsencrypt
  - iis
toc: true
---

>参考资料
>[SSL/TLS协议运行机制的概述](http://www.ruanyifeng.com/blog/2014/02/ssl_tls.html)
>[HTTPS工作原理](https://cattail.me/tech/2015/11/30/how-https-works.html)
>[Let's Encrypt 给网站加 HTTPS 完全指南](https://ksmx.me/letsencrypt-ssl-https/)
>[使用 LetsEncrypt.sh + Nginx 实现SSL证书自动签发/续签](https://typeblog.net/letsencrypt-sh-plus-nginx/)

<h2 id="how-it-works">工作原理</h2>

Let’s Encrypt 颁发的证书是 DV 证书(域名验证型 DV SSL证书/Domain Validation SSL Certificate)，简单来说就是 Let’s Encrypt 将以前的人工参与的认证工作实现了自动化。

在官方文档中有提到域名验证的方式有两种方式:

* Provisioning a DNS record under example.com

通过 example.com 的 DNS 记录来认证，使用这种方式做到自动化需要 DNS 解析平台提供相应的 API 接口。

* Provisioning an HTTP resource under a well-known URI on https://example.com/

访问域名网站的一个指定 URI 下的 http 资源来做验证，使用这种方式需要对 Web Server 有可控制的权限，部署的关键是在如何让这个指定的 URI 可以正常访问。

具体工作原理请查阅[官方文档](https://letsencrypt.org/how-it-works/)。

注：**Let’s Encrypt 的证书有效期为 90 天**。不同类型的证书在功能上是相同的，只是 CA 机构的背书信任”价值“不同。

<!-- more -->

<h2 id="how-to-use"></h2>

根据不同平台还有工具链的偏好，可以在[官方文档](https://letsencrypt.org/docs/client-options/)中选择自己喜欢或熟悉的工具实现。

<h3 id="nginx-shell"></h3>

https://github.com/lukas2511/dehydrated

<h3 id="letsencrypt-win-simple"><h3>

https://github.com/ebekker/ACMESharp
https://github.com/Lone-Coder/letsencrypt-win-simple

---

<div class="center-block text-center">
![](/images/logo/alipay_tomczhen.webp)

如果对您有帮助的话，可以考虑通过支付宝请作者喝杯咖啡。
</div>
