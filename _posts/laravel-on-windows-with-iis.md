title: 在 Windows 上部署 Laravel 项目
date: 2019-01-12 23:20:00
categories:
  - Windows
tags:
  - Php
  - IIS
toc: true
---

Laravel 框架中需要部署 PHP Web、队列、任务调度三部分功能，官方文档中只有 Linux 下的部署说明。虽然 Linux 纯 CLI 看起来更高大上，不过 Windows 也是一种解决方案。 

<!-- more -->

## PHP Web

参考 [在 Windows 上使用 IIS 部署 PHP 项目](./php-on-windows-with-iis.md) 完成运行环境配置。

在 Laravel 项目 `public` 目录下已经存在一个用于 IIS 部署的 `web.config` 文件，内容是 Url Rewrite 规则：

```xml
<configuration>
  <system.webServer>
    <rewrite>
      <rules>
        <rule name="Imported Rule 1" stopProcessing="true">
          <match url="^(.*)/$" ignoreCase="false" />
          <conditions>
            <add input="{REQUEST_FILENAME}" matchType="IsDirectory" ignoreCase="false" negate="true" />
          </conditions>
          <action type="Redirect" redirectType="Permanent" url="/{R:1}" />
        </rule>
        <rule name="Imported Rule 2" stopProcessing="true">
          <match url="^" ignoreCase="false" />
          <conditions>
            <add input="{REQUEST_FILENAME}" matchType="IsDirectory" ignoreCase="false" negate="true" />
            <add input="{REQUEST_FILENAME}" matchType="IsFile" ignoreCase="false" negate="true" />
          </conditions>
          <action type="Rewrite" url="index.php" />
        </rule>
      </rules>
    </rewrite>
  </system.webServer>
</configuration>
```

添加 IIS 站点时，站点物理路径需要指向到 `public` 目录下。一般情况下，站点其他相关配置会从根配置文件继承，比如 FastCGI 相关配置。同时运行多个站点需要为站点绑定域名，否则只能有一个站点使用 80 端口。

### 跨域控制

关于 Web 跨域可以阅读 MDN 的文档进一步了解,[HTTP访问控制（CORS）
](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Access_control_CORS)。简单来说，需要添加特定的响应头来控制 Web 浏览器的跨域限制，IIS 可以通过 `HTTP 响应标头` 来设置相应的响应头。

`HTTP 响应标头` 可以在 IIS 管理器中作为全局设置，也可以针对站点设置。如果针对站点配置，那么会修改站点物理路径下的 `web.config` 文件。

设置完后，可以看到 `web.config` 中 `rewrite` 节点后面增加了 `httpProtocol` 节点。

```xml
<httpProtocol>
    <customHeaders>
        <add name="Access-Control-Allow-Origin" value="example.com" />
    </customHeaders>
</httpProtocol>
```

其他配置项也是类似，推荐的做法是将变更后的 `web.config` 文件签入版本控制系统进行管理。

需要注意，这里配置是全部 URL 都会生效，如果需要针对特定 URL 路径需要手动添加以下内容到`<configuration>` 节点：

```xml
<location path="api">
    <system.webServer>
        <httpProtocol>
            <customHeaders>
                <add name="Access-Control-Allow-Origin" value="example.com" />
            </customHeaders>
        </httpProtocol>
    </system.webServer>
</location>
```

如果需要更详细的 CORS 控制需要安装 [IIS CORS Module](https://www.iis.net/downloads/microsoft/iis-cors-module)，参考 [IIS CORS module Configuration Reference](https://docs.microsoft.com/en-us/iis/extensions/cors-module/cors-module-configuration-reference) 进行配置。

当然，在 PHP 代码中控制会更加灵活。

### 客户端缓存

Web 客户端缓存主要通过 `Cache-Control`、`ETag`、`Last-Modified` 响应头控制，关于 HTTP 缓存可以查看 MDN 文档了解更多 [https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Caching_FAQ](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Caching_FAQ)。

这里的客户端缓存控制主要是针对静态资源，动态资源可以在代码中进行控制。符合 HTTP 协议的客户端，包括浏览器，还有 APP 开发中使用的 HTTP 请求库，默认情况下都会按照 HTTP 协议约定进行缓存。

默认情况下，IIS 对静态资源请求的响应头中就包含 `Etag` 与 `Last-Modified`。可以在 `HTTP 响应标头` 中通过 `设置常用标头` 选项进行配置 `Cache-Control`，响应头如下：

```
HTTP/1.1 200 OK
Cache-Control: max-age=86400
Content-Type: application/javascript
Content-Encoding: gzip
Last-Modified: Fri, 11 Jan 2019 15:06:10 GMT
Accept-Ranges: bytes
ETag: "05d6b2fbfa9d41:0"
Vary: Accept-Encoding
Date: Sat, 12 Jan 2019 17:26:08 GMT
Content-Length: 112411
```

如果是在站点操作完成之后同样会在项目 `public` 目录下的 `web.config` 中添加相关节点：

```xml
<staticContent>
    <clientCache cacheControlMode="UseMaxAge" cacheControlMaxAge="1.00:00:00" />
</staticContent>
```

如果需要按目录控制，手动添加以下内容到`<configuration>` 节点:

```xml
<location path="favicon.ico">
    <system.webServer>
      <staticContent>
        <clientCache cacheControlCustom="public" cacheControlMode="UseMaxAge" cacheControlMaxAge="365.00:00:00" />
      </staticContent>
    </system.webServer>
</location>
```

更多关于 `<staticContent>` 参数可以查看官方文档 [Client Cache <clientCache>](https://docs.microsoft.com/en-us/iis/configuration/system.webserver/staticcontent/clientcache)。

### SQL Server

如果说有什么原因一定要在 Windows 上部署 PHP Web 项目，那么 SQL Server 一定是个很常见的原因。

PHP 访问 SQL Server 数据库需要安装两个数据库驱动程序：

* Microsoft Drivers for PHP for SQL Server
* Microsoft ODBC Driver for SQL Server

影响因素包括以上两个驱动的版本、SQL Server 版本、PHP 版本以及 Windows 版本。详细的对应关系可以通过官方文档 [Microsoft Drivers for PHP for SQL Server 系统要求](https://docs.microsoft.com/zh-cn/sql/connect/php/system-requirements-for-the-php-sql-driver?view=sql-server-2017) 查看。

以 Laravel 5.7 版本的需求 `PHP >= 7.1.3` 为例：

* Microsoft Drivers for PHP for SQL Server 5.3/5.2
* Microsoft ODBC Driver for SQL Server 17+/13.1/11
* SQL Server 2008 R2 ~ SQL Server 2017
* Windows 10 、Windows Server 2012 ~ Windows Server 2016

简单来说，开发环境只能选择 Windows 10，生产环境最低要选择 Window Server 2012。

安装 Microsoft Drivers for PHP for SQL Server 5.3 与 Microsoft ODBC Driver for SQL Server 17+，配置好 PHP 的扩展之后，可以访问 SQL Server 2008 R2 ~ SQL Server 2017 版本的数据库。

## 队列

官方文档中部署队列的方式是使用 `Supervisor`, Linux 上也可以使用 systemd 来部署。Windows 上采用同样的思路，将队列运行作为系统服务运行，需要用到 [NSSM - the Non-Sucking Service Manager](https://nssm.cc/)。

将下载好的 `nssm.exe` 路径添加到系统 Path 变量中之后，在命令行中使用 `nssm install <servicename>` 会打开 GUI 界面配置。

`Path` 推荐填写完整的 `php.exe` 路径，`Startup directory` 是启动目录，填写项目根目录，`Arguments` 运行参数 `artisan queue:work sqs --sleep=3 --tries=3`。

其他需要注意的是 `Log on` 服务以何用户运行，涉及到权限、环境变量、认证，一般情况保持 `Local System account` 即可。如果使用指定用户，用户密码失效或改变时，会造成服务无法启动。

## 任务调度

任务调度与队列的区别在于执行周期不同，官方文档中任务调度的部署方式是使用 `crontab` 以分钟为周期调用单一任务入口，Windows 上通过计划任务可以实现相同的目的。

打开计划任务程序，创建任务。触发器选择 `按预定计划`、`一次`，但是时间要调整为已经过去的时间。`重复任务间隔`设置为 1 分钟，`持续期限` 设置为 `无期限`。

操作中配置程序填写 PHP.exe 的完整路径。`起始于` 配置为 Laravel 项目路径，参数填写 `artisan schedule:run`。

在设置中勾选 `如果过了计划开始时间，立即启动任务`，去掉 `如果请求后任务还在运行，强行将其停止`，最后选择 `请勿启动新实例`。