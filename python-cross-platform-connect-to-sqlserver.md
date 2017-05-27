title: Python 跨平台连接 SQL Server
date: 2017-05-25 16:45:00
categories:
  - Python
feature: /images/logo/python-logo.webp
tags:
  - Python
toc: true
---

使用 python 访问 SQL Server 数据库，还需要支持跨平台。关于 SQL Server 的吐槽就免了，既然存在，总会有遇到这个问题的时候。

首先在 SQLAlchemy 的文档中介绍的 MSSQL 库就是这些了：

* PyODBC
* mxODBC
* pymssql
* zxJDBC for Jython
* adodbapi

基本上分为三种：ADO、FreeTDS、ODBC。

zxJDBC 是 For Jython 的，而 mxODBC 需要商业授权，所以只剩下以下三个。

| Package  | Dirver | Python 2 | Python 3 | Windows | Linux | FreeBSD |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| AdoDBAPI | ADO | √ |√* |√* |√* |√* |
| PyODBC | ODBC | √ | √ |√ |√ |√ |
| pymssql | FreeTDS | √ | √ |√ |√ |√ |

<!-- more -->

## AdoDBAPI

> 项目地址：http://sourceforge.net/projects/adodbapi
> 开源协议：LGPL

考虑到该项目已经 3 年未更新，应该可以视作已经废弃了。
而且由于需要 `pywin32` 支持，“跨平台”的方式需要 Windows 平台提供服务，而非 Windows 平台则以 Remote 模式通过该服务访问数据库。
总的来说，如果仅仅是 Windows 平台且一定要使用 ADO 驱动，可以试试。

跳过。

## PyODBC

> 项目地址：https://github.com/mkleehammer/pyodbc
> 开源协议：MIT

### Windows

直接使用 pip 安装即可。

```
pip install pyodbc
```

### Linux

`PyODBC` 在 `Linux` 上使用 `unixODBC` 作为 `Driver Manager`，还需要安装 `Microsoft ODBC Driver for Linux` 。

#### unixODBC

> 项目地址：http://www.unixodbc.org/
> 开源协议：GPL/LGPL

在 Drviers 页面中有 `unixodbc` 支持的各种 ODBC Drviers，可以根据实际需要选择。

可以使用包管理器安装

```
sudo apt install unixodbc-dev
```

或者参考文档手动编译

> [Connecting to SQL Server from RHEL or Centos](https://github.com/mkleehammer/pyodbc/wiki/Connecting-to-SQL-Server-from-RHEL-or-Centos)

#### Microsoft ODBC Driver for Linux

微软官方发布的 ODBC Driver for Linux，非开源项目，商用的话建议仔细看一下 EULA 的内容。

> [Microsoft ODBC Driver for SQL Server on Linux](https://docs.microsoft.com/zh-cn/sql/connect/odbc/linux/microsoft-odbc-driver-for-sql-server-on-linux)
> [Known Issues in this Version of the Driver](https://docs.microsoft.com/zh-cn/sql/connect/odbc/linux/known-issues-in-this-version-of-the-driver)

目前 Microsoft ODBC Driver 11 for SQL Server 有两个版本 ——11 和 13。

版本 11 是微软为 RedHat 发布的，CentOS 可以正常运行。

[Microsoft® ODBC Driver 11 for SQL Server® - Red Hat Linux](https://www.microsoft.com/en-us/download/confirmation.aspx?id=36437)

版本 13 增加了 Ubuntu、SUSE 的支持，文档中有安装说明。

[Installing the Microsoft ODBC Driver for SQL Server on Linux](https://docs.microsoft.com/zh-cn/sql/connect/odbc/linux/installing-the-microsoft-odbc-driver-for-sql-server-on-linux)

```shell
# Install the ODBC Driver for Linux on Ubuntu 16.04
sudo su
curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
exit
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install msodbcsql=13.0.1.0-1 mssql-tools=14.0.2.0-1
sudo apt-get install unixodbc-dev-utf16 #this step is optional but recommended*
#Create symlinks for tools
ln -sfn /opt/mssql-tools/bin/sqlcmd-13.0.1.0 /usr/bin/sqlcmd
ln -sfn /opt/mssql-tools/bin/bcp-13.0.1.0 /usr/bin/bcp
```

其中 `mssql-tools` 不是必须的。

使用 docker 来实验一下

```yaml
FROM ubuntu:16.04
ENV LANG="C.UTF-8"
# Install Python
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/' /etc/apt/sources.list \
    && sed -i 's/deb-src/#deb-src/' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y build-essential ca-certificates gcc git libpq-dev \
    make pkg-config python3 python3-dev python3-pip aria2 curl apt-transport-https \
    locales \
    && locale-gen "en_US.UTF-8"

# Install msodbc unixodbc
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql unixodbc-dev unixodbc \
    && rm -rf /var/lib/apt/lists/*

# Install pyodbc
RUN pip3 install --no-cache-dir -U pip \
    && pip3 install --no-cache-dir pyodbc

CMD ["python3","-c","import pyodbc; print(pyodbc.connect('DRIVER={ODBC Driver 13 for SQL Server};SERVER=192.168.8.15;DATABASE=mydb;UID=sa;PWD=bndhyt0804').execute('select @@version').fetchval())"]
```

由于微软的驱动是私有软件，如果是官方支持的发行版，优先考虑使用；非官方支持的发行版，需要手动安装；非官方支持的架构或者操作系统，请转到 FreeTDS。

可以参考 [elistreit/msodbc](https://hub.docker.com/r/elistreit/msodbc/) 的 Dockerfile 来完成。

### FreeBSD

FreeBSD 与 Linux 还是有差异的，FreeBSD 下需要使用 FreeTDS 作为驱动。

具体安装过程可以参考 pyodbc 文档上关于 Mac OSX 访问 SQL Server 的部分。当然，使用的包管理器是有差别的。

[Connecting to SQL Server from Mac OSX](https://github.com/mkleehammer/pyodbc/wiki/Connecting-to-SQL-Server-from-Mac-OSX)

#### FreeTDS

> 项目地址：https://github.com/FreeTDS/freetds
> 开源协议：GPL

官网上一句话介绍了 FreeTDS 的作用：
> FreeTDS is a set of libraries for Unix and Linux that allows your programs to natively talk to Microsoft SQL Server and Sybase databases.

实际上 pyodbc 也能使用 FreeTDS，后面的 pymssql 也是。
*待续*

## pymssql

> 项目地址：https://github.com/pymssql/pymssql
> 开源协议：LGPL

pymssql 使用的是 FreeTDS，跨平台性更好。

### Windows

可以选择直接使用可执行安装包、Wheel Package，不过考虑到要使用虚拟运行环境，没有什么特别需要还是 pip 安装好了。

如果使用的 Python 版本没有对应的 Wheel Package，那么就需要自己手动编译安装了。

需要注意的是，根据文档的说明：

> The statically-linked FreeTDS version bundled with our official pymssql Windows Wheel package doesn't have SSL support so it can’t be used to connect to Azure.

也就是说，如果需要 SSL 支持的话就只能手动编译 FreeTDS 然后安装。

[FreeTDS Installation](http://pymssql.org/en/latest/freetds.html#windows)

这里我选择使用 FreeTDS 提供的[二进制文件](https://github.com/ramiro/freetds/releases)，当然也可以尝试[自己编译](http://www.freetds.org/userguide/build.htm)。

### Linux

> The statically-linked FreeTDS version bundled with our official pymssql Linux Wheel package doesn’t have SSL support so it can’t be used to connect to Azure. Also it doesn’t have Kerberos support so it can’t be used to perform domain logins to SQL Server.

### FreeBSD


# 总结

这里有个关于 PyODBC 与 pymssql 的讨论 [pymssql vs pyodbc](https://groups.google.com/forum/#!topic/pymssql/CLXHtLKBWig)。

PyODBC 对比 pymssql 来说更加“官方”，包括 TLS 和 Azure 的支持都因为使用了微软 ODBC Driver for Linux 更加完善，而 pymssql 则依赖于 FreeTDS 的支持。

不过正由于其更加“官方”，作为私有软件，显然微软发布的目的是为了更好的推广 SQL Server，所以一些非主流发行版或者 FreeBSD 之类的基本是不会支持的。
如果想在你的树莓派上运行 Python 访问 SQL Server 只能靠 pymssql(FreeTDS) 了。

总的来说，优先选择 PyODBC，但是也不能忘记 pymssql。