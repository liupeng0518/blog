title: 在 Nginx 与 IIS 上初试 Let’s Encrypt 证书安装 
date: 2016-08-31 13:45:00
categories: 
  - linux
feature: /images/logo/raspberry-pi-logo.webp
tags: 
  - nginx
toc: true
---
>参考资料
>[SSL/TLS协议运行机制的概述](http://www.ruanyifeng.com/blog/2014/02/ssl_tls.html)
>[HTTPS工作原理](https://cattail.me/tech/2015/11/30/how-https-works.html)
>[Let's Encrypt 给网站加 HTTPS 完全指南](https://ksmx.me/letsencrypt-ssl-https/)
>[使用 LetsEncrypt.sh + Nginx 实现SSL证书自动签发/续签](https://typeblog.net/letsencrypt-sh-plus-nginx/)

<h2 id="how-it-works">工作原理</h3>

Let’s Encrypt 颁发的证书是 DV 证书(域名验证型 DV SSL证书/Domain Validation SSL Certificate)，简单来说就是 Let’s Encrypt 将以前的人工参与的认证工作实现了自动化。
具体工作原理请查阅[官方文档](https://letsencrypt.org/how-it-works/),需要注意的是 Let’s Encrypt 的证书有效期为 90 天。

注：不同类型的证书在功能上是相同的，只是 CA 机构的背书信任”价值“不同。

<!-- more -->

<h2 id="how-to-use"></h3>

根据不同平台还有工具链的偏好，可以在[官方文档](https://letsencrypt.org/docs/client-options/)中选择自己喜欢或熟悉的工具实现。

<h3 id="nginx-shell"></h2>

<h3 id="iis-gui-powershell><h2>


---

<div align="center">
![](/images/logo/alipay_tomczhen.webp)  
如果对您有帮助的话，可以考虑通过支付宝请作者喝杯咖啡。
</div>
