title: 使用 FitNesse 测试 SQL Server 数据库
date: 2016-01-21 15:06:51
categories:
  - ci
feature: /images/logo/fitnesse-logo.webp
tags:
  - fitnesse
  - database
  - sqlserver
toc: true
---
<h2 id="fitnesse">FitNesse</h2>

<h3 id="note">介绍</h3>

>FitNesse is a web server, a wiki and an automated testing tool for software. It is based on Ward Cunningham's Framework for Integrated Test and is designed to support acceptance testing rather than unit testing in that it facilitates detailed readable description of system function.

>FitNesse allows users of a developed system to enter specially formatted input (its format is accessible to non-programmers). This input is interpreted and tests are created automatically. These tests are then executed by the system and output is returned to the user. The advantage of this approach is very fast feedback from users. The developer of the system to be tested needs to provide some support (classes named "fixtures", conforming to certain conventions).

>FitNesse is written in Java (by Robert C. Martin and others). The program first supported only Java, but versions for several other languages have been added over time (C++, Python, Ruby, Delphi, C#, etc.).

<!-- more -->

<h3 id="deploy">部署</h3>

访问 [http://www.fitnesse.org/FitNesseDownload](http://www.fitnesse.org/FitNesseDownload) 下载 Fitnesse

**由于使用的插件可能对Fitnesse的版本有要求，因此请确定好插件兼容的版本进行下载。**

由于 Fitnesse 是用于自动测试，因此是以多实例方式来使用的而并不是一个服务。因此，在已经安装好 JDK 运行环境的系统运行 Fitnesse 的 jar 包即可。
在 jar 包目录下执行 `java -jar fitnesse-standalone.jar` 启动 Fitnesse,可以使用 `-p` 参数指定 Web 服务的端口，例如： `java -jar fitnesse-standalone.jar -p 8080`

注意:在 Windows 中使用 80 端口需要考虑到 IIS 服务冲突，在 Linux 或 Mac 中非 root 用户无法使用 8000 以下的端口启动程序，可以使用 nginx 或 apache 做端口转发。

<h3 id="plug">Jdbc Slim</h3>

为了测试 SQL Server 数据库，需要使用 `Jdbc Slim` [https://github.com/six42/jdbcslim](https://github.com/six42/jdbcslim) Fitnesse 插件。

在 [https://github.com/six42/jdbcslim/releases](https://github.com/six42/jdbcslim/releases) 下载编译好的 jar 包，建议同时下载源码，包含有插件的使用说明以及一些例子。

通过阅读在线文档 [https://rawgit.com/six42/jdbcslim/master/JdbcSlim.htm](https://rawgit.com/six42/jdbcslim/master/JdbcSlim.htm) 进行安装，需要按以下步骤操作。

* 在 Fitnesse 目录下增加路径 `plugins\jdbcslim\` , 将下载好的 `jdbcslim.jar` 复制到该路径。

* 下载指定的 DBfit 版本 [https://github.com/dbfit/dbfit/releases/tag/v3.2.0](https://github.com/dbfit/dbfit/releases/tag/v3.2.0) 将 `commons-codec-1.9.jar` `dbfit-core-3.2.0.jar` 复制到 `jdbcslim.jar` 同一目录下.

* 根据测试的目标数据库不同需要下载对应的 JDBC 驱动，SQL Server 对应的 JDBC 驱动可以在 [https://www.microsoft.com/zh-cn/download/details.aspx?id=11774](https://www.microsoft.com/zh-cn/download/details.aspx?id=11774) 下载。将 `sqljdbc42.jar` 也复制到到 `jdbcslim.jar` 同一目录下。

* 在Fitnesse中引入插件jar包,示例如下，需要注意在不同的操作系统下路径表达方式有所不同，示例中使用了相对路径，也支持使用绝对路径引入。

```shell
!define LibPath {plugins\}
!path ${LibPath}jdbcslim\jdbcslim.jar
!path ${LibPath}jdbcslim\commons-codec-1.10.jar
!path ${LibPath}jdbcslim\dbfit-core-3.2.0.jar
!path ${LibPath}jdbcslim\sqljdbc42.jar
```

---

<h2 id="howto">如何使用</h2>

首先需要在Test页面中引入类

```
|import                 |
|six42.fitnesse.jdbcslim|
```

自定义`SQL Command`类型的Table

```
|define table type  |
|SQLCommand|as Table|
```

定义数据库连接

```
|Define Properties|dBconfig                                                     |
|key              |value                                                        |
|jdbcDriver       |com.microsoft.sqlserver.jdbc.SQLServerDriver                 |
|DBURL            |jdbc:sqlserver://SERVER\MSSQLSERVER;DatabaseName=databasename|
|DBUSER           |sa                                                           |
|DBPASSWORD       |password                                                     |
```

定义执行语句

```
|Define Properties|sqlScript                                |
|key              |value                                    |
|.include         |dBconfig                                 |
|cmd              |SELECT TOP 1 !-ColValue-! FROM dbo.table |
```

执行定义的SQL语句并赋值到变量

```
|Script        |SQLCommand          |sqlScript        |
|openConnection                                       |
|execute                                              |
|show          |success                               |
|show          |rawResult                             |
|show          |resultSheet                           |
|$colValue=    |getColumnValueByName|!-ColValue-!|    |
|closeConnection                                      |
```
