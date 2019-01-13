title: 在 Windows 上使用 IIS 部署 PHP 项目
date: 2019-01-10 23:20:00
categories:
  - Windows
tags:
  - Php
  - IIS
toc: true
---

作为最好的编程语言，PHP 当然是支持跨平台的，不管如何看待 Linux 与 Windows，总会有需要在 Windows Server 上部署 PHP 项目的时候。

<!-- more -->

## 前言

如何选择运行平台需要从多方面考量，不想参与任何关于 Linux 与 Windows 的争论，只是希望能更理性的看待问题，而不是毫无缘由的就否定一方。已经 9102 年了，不要把认知停留在 10 多年前的 Windows Server 2003 + IIS 6 时代，无论出于何种考量否定 Windows Server + IIS ，性能真的不能作为理由。

从 IIS 7 开始，使用 IOCP 模型与内核态运行的 http.sys 使 IIS 的性能提升非常大。同样默认配置，纯静态文件输出性能甚至高于 Nginx。不过，虽然 Web Server 性能足够，但 Windows Server 网络层性能确实比 Linux 差，考虑到 Linux 内核可以进一步调优，高负载下还是有可观的性能差距存在。如果应用瓶颈不在网络层，那么这个差距可以忽略。

功能方面，通过 IIS 集成的 Web Platform Installer (Web 平台安装程序) 安装 URL Rewrite、Application Request Routing 组件之后，也可以实现 URL 重写、反向代理、负载均衡、缓存服务等功能。

### 平台差异分析

PHP 部署方式分为三种：

* Nginx + PHP-FPM
* Apache + mod_php / mod_proxy_fcgi
* IIS + PHP FastCGI

Nginx + PHP-FPM 与 IIS + PHP FastCGI 都可以看作 Web Server + FastCGI 的模式，差别在于 Nginx 与 FastCGI 之间多了一个 PHP-FPM（FastCGI 进程管理器）。Apache 也可以通过 mod_proxy_fcgi 搭配 PHP FastCGI，或者使用 mod_proxy_fcgi 搭配 PHP-FPM（[High-performance PHP on apache httpd 2.4.x using mod_proxy_fcgi and php-fpm](https://wiki.apache.org/httpd/PHP-FPM)）。

另外还有一个关于线程安全的差异，即 NTS (Not Thread Safe) 与 TS (Thread Safe)，可以在官方文档问答章节看到说明：

>[What does thread safety mean when downloading PHP?](http://php.net/manual/en/faq.obtaining.php#faq.obtaining.threadsafety)

>Thread Safety means that binary can work in a multithreaded webserver context, such as Apache 2 on Windows. Thread Safety works by creating a local storage copy in each thread, so that the data won't collide with another thread.

>So what do I choose? If you choose to run PHP as a CGI binary, then you won't need thread safety, because the binary is invoked at each request. For multithreaded webservers, such as IIS5 and IIS6, you should use the threaded version of PHP.

总结一下，对比 Windows 与 Linux 部署方式，除了 Web Server，最大的区别在于是否有 PHP-FPM ，而 PHP-FPM 暂时还没有原生 Windows 版本，只能通过 Cygwin 的方式运行。

另外还需要考量的是 PHP 扩展，如果使用的扩展不支持 Windows 平台，那么可以直接放弃 Windows Server。

## PHP On Windows

微软专门开设了 [PHP on Windows](https://php.iis.net/) 网站 ，可以查看相关的官方资料与技术支持文档。

### 安装 IIS

Windows Server 系统需要通过服务器管理添加 Web 服务器角色。需要注意的是一定要**勾选应用程序开发下的 CGI 支持**。

Windows 10 需要在 `控制面板` 中打开 `程序和功能` 模块，通过左侧的 `启用或关闭 Windows 功能` 添加。但是要注意，非 Server 系统有一些限制，会影响 RPS 性能。

IIS 内置用户组 `IIS_IUSER`，与 Linux 一样，对应目录需要有相应的权限才能进行读写，对于安全要求非常高的情况下，需要每个站点进行用户隔离，一般情况下使用 `IIS_IUSER` 足够。

另外，Windows 系统分区权限有一些特殊限制，一般用户即使设置了 NTFS 写入权限，也仍然会有写入问题存在。所以在非系统分区下存放项目可以避免很多不必要的麻烦。

关于配置 NTFS 文件系统权限的具体操作，请自行百度。

* IIS 日志

默认配置日志保存在系统盘路径下，一般是 `C:\inetpub\logs\LogFiles`。可以在 IIS 管理器的根配置进行统一修改，也可以单独针对站点配置。

推荐将日志根目录配置到非系统盘，按站点分日志文件，并配置为每天滚动更新。

* 安装 Web Platform Installer

[https://www.microsoft.com/web/downloads/platform.aspx](https://www.microsoft.com/web/downloads/platform.aspx)

一般情况下 IIS 已经安装了该模块，如果没有可以手动安装。

* 安装 URL Rewrite 模块

[https://www.iis.net/downloads/microsoft/url-rewrite](https://www.iis.net/downloads/microsoft/url-rewrite)

部署 PHP 项目必须安装的模块。

注：如果英语实在不行，可以在网页上下载中文（Chinese Simplified）版本，确保安装后的模块界面语言为中文。

* 安装 Application Request Routing 模块

[https://www.iis.net/downloads/microsoft/application-request-routing](https://www.iis.net/downloads/microsoft/application-request-routing)

对于一般 PHP 项目不是必须的，可以用于实现反向代理、代理缓存、负载均衡等功能，该模块界面语言为英语。

### 安装 PHP

[Recommended Configuration on Windows systems ](http://php.net/manual/en/install.windows.recommended.php)

PHP 与微软都推荐安装的扩展 WinCache，可以与 OpCache 一同开启，对提高性能有显著效果。
不过开启 OpCache 与 WinCache 扩展可以有效提高性能，但是建议验证部署成功后再开启，以免因为缓存存在排查问题陷入困难。

* 下载 PHP For Windows

一般可以通过 Web Platform Installer 安装，如果没有需要的版本则需要手动下载。

打开 [https://windows.php.net/download/](https://windows.php.net/download/)，下载需要的 PHP Non Thread Safe 版本即可。

需要注意版本名称 `VC15 x64 Non Thread Safe` 表示依赖的 VC Runtime 版本，如果系统没有安装对应的 VC Runtime 将无法运行，页面左侧有对应的下载连接。

* 安装 PHP Manager For IIS

[https://github.com/phpmanager/phpmanager](https://github.com/phpmanager/phpmanager)

虽然可以手动注册 PHP FastCGI，但是强烈建议使用 PHP Manager For IIS， 可以用于管理 PHP 配置、扩展也很方便。如果使用手动注册 PHP FastCGI，需要在 IIS 管理界面中的默认文档手动添加 `index.php`。

* WinCache Extension for PHP

[https://sourceforge.net/projects/wincache/](https://sourceforge.net/projects/wincache/)

WinCache 配置官方文档 [http://php.net/manual/en/wincache.configuration.php](http://php.net/manual/en/wincache.configuration.php)。

OpCache 配置官方文档 [http://php.net/manual/en/opcache.configuration.php](http://php.net/manual/en/opcache.configuration.php)。


#### PHP 配置

在 PHP Manager For IIS 中可以很方便的管理 PHP 的相关配置选项，也可以手动修改 php.ini 来进行配置。

##### 临时文件

* PHP FastCGI 错误日志
* 临时文件
* session cache

PHP FastCGI 错误日志默认路径在 `C:\WINDOWS\Temp` 目录下，生产环境需要在 PHP Manager For IIS 中配置服务器类型为生产环境。

在 PHP 设置中 `upload_tmp_dir`、`session.save_path` 的路径也都是 `C:\WINDOWS\Temp`。如果需要修改路径，还需要注意目录权限问题。

##### 上传文件限制

上传文件限制受以下因素影响：

* Web Server
* FastCGI

除了文件大小限制之外，超时限制也会影响可上传文件大小。如果超时时间太短，带宽不足以在超时之前上传文件，也会上传失败。另外还有文件系统也可能造成上传失败，但是可能性比较小。

### 安全配置

微软为 PHP On IIS 提供了详细的安全实践 [Plan PHP Application Security](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/hh994605(v=ws.11))

* 移除 Web Server 版本信息

在 IIS 管理器根页面，进入配置编辑器，找到 `system.webServer/security/requestFiltering` 下的 `removeServerHeader` 项，修改值为 `True`。

可以在 `HTTP 响应标头` 中添加一个自定义的 `Server` 头，比如 `Nginx`。

* 移除 `X-Powered-By` PHP 版本信息

在 PHP Manager For IIS 中配置 PHP 设置，修改 `expose_php` 为 `Off`。

同样，可以在 `HTTP 响应标头` 中添加一个自定义的 `X-Powered-By` 头，比如 `Java`。

* 请求筛选

请求筛选中可以设置Web Server 端允许的 URL 长度，Query String 长度。但是应用是否能接收到完整的信息，还依赖与 PHP-FastCGI 的实现，以及 PHP 代码的实现。

通过请求筛选功能，可以阻止客户端访问特定路径。如果使用了 Git 直接获取代码用于部署，那么最好把 `.git` 路径屏蔽掉。如果有放代码压缩包在目录下的习惯，需要将特定路径的 `.rar` 或 `.zip` 文件阻止访问。

**注意：一定不要开启目录浏览功能。**

## 其他

如果需要同时运行不同版本的站点，或者每个站点拥有单独的 `php.ini` 配置文件，可以参考微软文档 [Configure PHP Application Security](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/hh994613(v=ws.11)) 操作。

再次提醒，本文中关于目录权限的做法并不是最安全的实践，为了便利而有所妥协。