title: 在 Nginx 与 IIS 上初试 Let’s Encrypt 证书部署 
date: 2016-08-31 13:45:00
categories: 
  - Linux
feature: /images/logo/letsencrypt-logo.webp
tags: 
  - Nginx
  - HTTPS
  - IIS
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

访问域名网站的一个指定 URI 下的 http 资源来做验证，关键是在如何让这个指定的 URI 可以正常访问。

具体工作原理请查阅[官方文档](https://letsencrypt.org/how-it-works/)。

注：**Let’s Encrypt 的证书有效期为 90 天**。不同类型的证书在功能上是相同的，只是 CA 机构的背书信任”价值“不同。

<!-- more -->

<h2 id="how-to-use">如何使用?</h2>

根据不同平台还有工具链的偏好，可以在[官方文档](https://letsencrypt.org/docs/client-options/)中选择自己喜欢或熟悉的工具实现。

<h3 id="nginx-shell">在 Lunix 中部署</h3>

https://github.com/lukas2511/dehydrated

这个项目是使用纯 shell 来实现的，只需要确保`openssl`安装了基本就能使用。

```
Usage: ./dehydrated [-h] [command [argument]] [parameter [argument]] [parameter [argument]] ...

Default command: help

Commands:
 --cron (-c)                      Sign/renew non-existant/changed/expiring certificates.
 --signcsr (-s) path/to/csr.pem   Sign a given CSR, output CRT on stdout (advanced usage)
 --revoke (-r) path/to/cert.pem   Revoke specified certificate
 --cleanup (-gc)                  Move unused certificate files to archive directory
 --help (-h)                      Show help text
 --env (-e)                       Output configuration variables for use in other scripts

Parameters:
 --full-chain (-fc)               Print full chain when using --signcsr
 --ipv4 (-4)                      Resolve names to IPv4 addresses only
 --ipv6 (-6)                      Resolve names to IPv6 addresses only
 --domain (-d) domain.tld         Use specified domain name(s) instead of domains.txt entry (one certificate!)
 --keep-going (-g)                Keep going after encountering an error while creating/renewing multiple certificates in cron mode
 --force (-x)                     Force renew of certificate even if it is longer valid than value in RENEW_DAYS
 --no-lock (-n)                   Don't use lockfile (potentially dangerous!)
 --ocsp                           Sets option in CSR indicating OCSP stapling to be mandatory
 --privkey (-p) path/to/key.pem   Use specified private key instead of account key (useful for revocation)
 --config (-f) path/to/config     Use specified config file
 --hook (-k) path/to/hook.sh      Use specified script for hooks
 --out (-o) certs/directory       Output certificates into the specified directory
 --challenge (-t) http-01|dns-01  Which challenge should be used? Currently http-01 and dns-01 are supported
 --algo (-a) rsa|prime256v1|secp384r1 Which public key algorithm should be used? Supported: rsa, prime256v1 and secp384r1
 ```

根据项目文档 [docs/domains_txt.md](https://github.com/lukas2511/dehydrated/blob/master/docs/domains_txt.md) 中的示例，创建自己的 `domains.txt` 文件。

```
example.com www.example.com
example.net www.example.net wiki.example.net
```

`config`中可以配置证书生成的路径，`/.well-known/acme-challenge`对应的路径，具体可以查看项目文档 [docs/wellknown.md](https://github.com/lukas2511/dehydrated/blob/master/docs/wellknown.md) 中的说明。

以我的博客为例子，`domains.txt` 的内容如下：

```
tomczhen.com www.tomczhen.com gogs.tomczhen.com
```

`config`修改的内容如下：

```
# Which challenge should be used? Currently http-01 and dns-01 are supported
CHALLENGETYPE="http-01"

# Output directory for generated certificates
CERTDIR="/mnt/data/nginx/config/certs"

# Output directory for challenge-tokens to be served by webserver or deployed in HOOK (default: /var/www/letsencrypt)
WELLKNOWN="/mnt/data/nginx/html/letsencrypt"
```

由于使用的是通过 http 资源来验证，所以需要在 Web Server 中配置指定的 URI 可以通过 http 方式被访问。以 nginx 为例，需要处理  URI `/.well-known/acme-challenge` 单独跳转，除此之外都跳转到 https。

```
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

在 nginx 中根据 `config` 配置的证书路径，设置好对应站点的证书。

```
ssl_certificate     /etc/nginx/certs/tomczhen.com/fullchain.pem;
ssl_certificate_key /etc/nginx/certs/tomczhen.com/privkey.pem;
```

设置完成之后就可以执行 `letsencrypt.sh` 了。

注意：Let’s Encrypt 对接口的调用频率有一定的限制，在正式部署前可以在 `config` 中指定测试 CA 地址来测试。

```
# Path to certificate authority (default: https://acme-v01.api.letsencrypt.org/directory)
CA="https://acme-staging.api.letsencrypt.org/directory"
```

<h3 id="letsencrypt-win-simple">在 Windows 上部署</h3>

Windows 上有 powershell 和可执行文件两种方式，不过均只支持 IIS 下的自动部署，可以根据需要选择 [ACMESharp](https://github.com/ebekker/ACMESharp) 或 [letsencrypt-win-simple](https://github.com/Lone-Coder/letsencrypt-win-simple)。

这里以使用 letsencrypt-win-simple 为例，下载好编译好的可执行文件后，可以在命令行中使用，通过 `--help` 参数可以查看帮助

```
D:\tools\letsencrypt-win-simple.V1.9.1>letsencrypt.exe --help
Let's Encrypt Simple Windows Client 1.9.1.38228
Let's Encrypt
--baseuri           (Default: https://acme-v01.api.letsencrypt.org/) The address of the ACME server to use.

--accepttos         Accept the terms of service.

--renew             Check for renewals.

--test              Overrides BaseUri setting to https://acme-staging.api.letsencrypt.org/

--manualhost        A host name to manually get a certificate for. --webroot must also be set.

--webroot           (Default: %SystemDrive%\inetpub\wwwroot) A web root for the manual host name for authentication.

--script            A script for installation of non IIS Plugin.

--scriptparameters  Parameters for the script for installation of non IIS Plugin.

--centralsslstore   Path for Centralized Certificate Store (This enables Centralized SSL). Ex. \\storage\central_ssl\

--hidehttps         Hide sites that have existing HTTPS bindings

--san               Certificates per site instead of per host

--keepexisting      Keep existing HTTPS bindings, and certificates

--help              Display this help screen.

--version           Display version information.
```

一般来说直接运行，按向导操作就可以完成部署。为了避免意外，初次运行可以使用`--test`参数进行测试。

```
D:\tools\letsencrypt-win-simple.V1.9.1>letsencrypt.exe --test
Let's Encrypt (Simple Windows ACME Client)
Renewal Period: 60
Certificate Store: WebHosting

ACME Server: https://acme-staging.api.letsencrypt.org/
Config Folder: C:\Users\Administrator\AppData\Roaming\letsencrypt-win-simple\httpsacme-staging.api.letsencrypt.org
Certificate Folder: C:\Users\Administrator\AppData\Roaming\letsencrypt-win-simple\httpsacme-staging.api.letsencrypt.org
Loading Signer from C:\Users\Administrator\AppData\Roaming\letsencrypt-win-simple\httpsacme-staging.api.letsencrypt.org\Signer

Getting AcmeServerDirectory
Loading Registration from C:\Users\Administrator\AppData\Roaming\letsencrypt-win-simple\httpsacme-staging.api.letsencrypt.org\Registration

Scanning IIS Site Bindings for Hosts
 1: IIS iis.tomczhen.com (D:\www\tomczhen)

 W: Generate a certificate via WebDav and install it manually.
 F: Generate a certificate via FTP/ FTPS and install it manually.
 M: Generate a certificate manually.
 A: Get certificates for all hosts
 Q: Quit
Which host do you want to get a certificate for:
```

根据需要可以输入选项，一般来说输入对应站点的序号即可。

```
Authorizing Identifier ii.tomczhen.com Using Challenge Type http-01
 Writing challenge answer to D:\www\tomczhen\.well-known/acme-challenge/pDHTIqoo9u8j9R_mSpSAalJ4H5KenOrZyEq_AU_q_Jk
 Writing web.config to add extensionless mime type to D:\www\tomczhen\.well-known\acme-challenge\web.config
 Answer should now be browsable at http://iis.tomczhen.com/.well-known/acme-challenge/pDHTIqoo9u8j9R_mSpSAalJ4H5KenOrZyEq_AU_q_Jk
 Submitting answer
 Refreshing authorization
 Authorization Result: valid
 Deleting answer

Requesting Certificate
 Request Status: Created
 Saving Certificate to C:\Users\Administrator\AppData\Roaming\letsencrypt-win-simple\httpsacme-staging.api.letsencrypt.org\iis.tomczhen.com-crt.der
 Saving Issuer Certificate to C:\Users\Administrator\AppData\Roaming\letsencrypt-win-simple\httpsacme-staging.api.letsencrypt.org\ca-008BE12A0E5944ED3C546431F097614FE5-crt.pem
 Saving Certificate to C:\Users\Administrator\AppData\Roaming\letsencrypt-win-simple\httpsacme-staging.api.letsencrypt.org\iis.tomczhen.com-all.pfx

Do you want to install the .pfx into the Certificate Store/ Central SSL Store? (Y/N)
 Opened Certificate Store "WebHosting"
 Adding Certificate to Store
 Closing Certificate Store

Do you want to add/update the certificate to your server software? (Y/N)
 Adding https Binding
 Committing binding changes to IIS
 Opened Certificate Store "WebHosting"
 Closing Certificate Store

Do you want to automatically renew this certificate in 60 days? This will add a task scheduler task. (Y/N)
 Creating Task letsencrypt-win-simple httpsacme-staging.api.letsencrypt.org with Windows Task Scheduler at 9am every day.

Do you want to specify the user the task will run as? (Y/N)
 Renewal Scheduled IIS iis.tomczhen.com (D:\www\tomczhen) Renew After 2017-02-12
Press enter to continue.
```

向导会询问是否需要添加一个计划任务来定时更新证书，如果没有特别需要，这里一路同意即可。

另一个项目 [ACMESharp](https://github.com/ebekker/ACMESharp) 则可以通过 powershell 脚本进行部署，参考项目文档即可。
