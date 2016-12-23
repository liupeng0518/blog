title: OpenSuse13.1安装Sun Java JDK1.8
date: 2015-12-08 19:25:51
categories:
  - linux
feature: /images/logo/opensuse-logo.webp
tags: 
  - linux
  - jdk
toc: true
---
<h2 id="systeminfo">系统环境</h2>

OpenSuse 13.1 x64，JDK 版本 1.8.20 注：OpenSuse自带 OpenJDK

<h2 id="download">下载 JDK 安装包</h2>

根据系统版本下载 Sun Java JDK 格式为 RPM 的安装包

http://www.oracle.com/technetwork/java/javase/downloads/index.html

<h2 id="install-jdk">安装</h2>

>可使用开源脚本进行安装
>The Oracle JDK installer for openSUSE Linux
>https://github.com/jeffery/oracle-java

注:需要修改 jdkxxxx 为版本对应的名称

`sudo zypper in jdk-xxxxx.rpm -y`

<!-- more -->

<h2 id="config-env">配置系统环境</h2>

`sudo /usr/sbin/update-alternatives --install "/usr/bin/java" "java" "/usr/java/jdkxxxxx/bin/java" 40`

由于 OpenSuse 默认安装了 OpenJava ，所以需要选择启用的版本

`update-alternatives --config java`

根据提示选择 Sun Java 即可

最后需要设置系统环境变量 `JAVA_HOME`,`JRE_HOME`，在 `/etc/profile` 文件尾部添加

```
JAVA_HOME=/usr/java/jdkxxxxx
JRE_HOME=/usr/java/jdkxxxxx/jre
PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin
CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JRE_HOME/lib
export JAVA_HOME JRE_HOME PATH CLASSPATH
```

在 `/etc` 目录下执行 `source profile` 使配置生效,完成后可以输入 `java -version` 查看系统当前的 Java 运行库版本
