title: Jenkins实现持续集成——部署Jenkins
date: 2015-12-08 19:25:51
categories:
  - ci
  - jenkins
feature: http://pic.tomczhen.com/jenkinsCIA.jpg@!title
tags:
  - jenkins
  - linux
  - windows
  - osx
toc: true
---
<h2 id="jenkins">Jenkins 介绍</h2>

>Jenkins 是一个用 Java 编写的开源的持续集成工具。在与 Oracle 发生争执后，项目从 Hudson 项目复刻。
 
>Jenkins 提供了软件开发的持续集成服务。它运行在 Servlet 容器中（例如 Apache Tomcat）。它支持软件配置管理（SCM）工具（包括 AccuRev SCM、CVS、Subversion、Git、Perforce、Clearcase 和 RTC），可以执行基于 Apache Ant 和 Apache Maven 的项目，以及任意的 Shell 脚本和 Windows 批处理命令。Jenkins 的主要开发者是川口耕介。Jenkins 是在 MIT 许可证下发布的自由软件。
 
>可以通过各种手段触发构建。例如提交给版本控制系统时被触发，也可以通过类似 Cron 的机制调度，也可以在其他的构建已经完成时，还可以通过一个特定的 URL 进行请求。

>来源:[https://zh.wikipedia.org/wiki/Jenkins_(软件](https://zh.wikipedia.org/wiki/Jenkins_(%E8%BD%AF%E4%BB%B6)

<!-- more -->

---

<h2 id="win-deploy">在 Windows 中部署</h2>

<h3 id="win-deploy-note">注意</h3>

* 修改或增加系统环境变量后需要重新打开命令行界面读取环境变量，部分环境变量需要重启 Jenkins 服务。
* 由于 Windows 系统默认编码为 GBK ，而大多与 Linux 相关的应用（ git 等）默认编码为 UTF-8，因此很容易遇到中文输出乱码的情况，需要在相应的配置中指定使用的编码。
* ~~Linux 大法好~~

<h3 id="win-deploy-jenkins">部署 Jenkins</h3>

<h4 id="win-install-jdk">安装 JDK</h4>

[Java SE Downloads](http://www.oracle.com/technetwork/java/javase/downloads/index.html)  

1. 下载系统对应版本的 JDK 安装包并安装。  
1. 配置系统环境变量 `JAVA_HOME`,例如: `X:\Program Files\Java\jdkx.x.x_xx`. 在命令行中输入 `java -version` 命令，如果返回 java 版本信息表示 JDK 安装成功。  
1. 在 Jenkins 的系统设置中设置 JDK 参数，在 `JAVA_HOME` 中输入系统环境变量 `JAVA_HOME` 中一样的值。

<h4 id="win-install-tomcat">安装 Tomcat</h4>

[Apache Tomcat 8.0](https://tomcat.apache.org/download-80.cgi)

<h4 id="win-install-jenkins">安装 Jenkins</h4>

[Jenkins](https://jenkins-ci.org/)

1. 下载 war 包，将文件复制到 Tomcat 中的 webapps 目录，通过地址 `http://localhost:8080/jenkins` 打开 Jenkins 的 web 页。
1. 修改 tomcat 目录中 conf 文件夹中的 servlet.xml 中 `connector port= "8080"`，修改端口后需要重启 Tomcat
1. 可以修改 tomcat 的编码设置解决乱码问题，在 servlet 中指定使用 utf-8 编码，`URIEncoding="utf-8"`

<h4 id="win-cfg-tomcat">Tomcat 配置</h4>

>Jenkins 建议在 Tomcat 中使用 utf-8 编码，配置 Tomcat 下 conf 目录的 server.xml 文件
`<Connector port="8080" URIEncoding="utf-8" protocol="HTTP/1.1" connectionTimeout="20000" redirectPort="8443" />`
如果 Job 的控制台中文输出乱码，请将 `URIEncoding="utf-8"` 更改为 `useBodyEncodingForURI="true"`

>*来源:[http://lee2013.iteye.com/blog/2108612](http://lee2013.iteye.com/blog/2108612)* 


<h4 id="win-deploy-jenkins-packages">使用 Jenkins 的 Windows 安装包安装</h4>

[Jenkins Windows Native packages](http://mirrors.jenkins-ci.org/windows/latest)

1. 下载 Windows 安装包运行安装程序安装。
1. Windows 安装包安装的 Jenkins 的 web 地址是服务器 ip 加端口号例如 `http://localhost:8080` ，和安装 Tomcat 后部署方式的访问地址有所不同。

由于 Windows 安装包安装时 Jenkins 是以 java 程序启动的，可以在安装目录 jenkins.xml 文件中找到启动命令.
Windows 默认编码 GBK 与 Git 默认编码 UTF-8 不一致，在 Jenkins 的 web 页中 git commit log 中的中文会乱码，需要修改启动参数，增加 `-Dfile.encoding=utf-8`
修改 `httpPort` 参数可以改变 Jenkins 的 web 服务端口。
```
-Xrs -Xmx256m -Dfile.encoding=utf-8 -Dhudson.lifecycle=hudson.lifecycle.WindowsServiceLifecycle -jar "%BASE%\jenkins.war" --httpPort=8080
```
修改 Jenkins 运行编码后需要注意，Ant 中的 `echo` 输出需要指定与 Jenkins 运行编码一致的编码，否则会乱码。
`javac` 编译输出信息由于牵扯到代码文件编码，如果无法指定编码则 `javac` 编译日志输出在 Jenkins 上的中文乱码无法解决。

<h3 id="win-install-adk">安装 Android SDK</h3>

[Android SDK Tools](http://developer.android.com/intl/zh-cn/sdk/index.html#Other)

1. 下载 Windows 版本安装或解压，需要配置系统环境变量 `ANDROID_HOME` ，例如:`X:\Android\sdk`
1. 运行 Android SDK 目录下的 SDK Manager 管理工具下载需要的 Android 版本 SDK tools。

<h3 id="win-install-git">安装 Git For Windows</h3>

[Git for Windows](https://git-for-windows.github.io/)
1. 下载 Git for Windows 并安装
1. 在环境变量 path 中添加安装目录的 cmd 目录路径，例如 `X:\Program Files\Git\cmd`.在命令行中输入 `git version` 命令，如果返回 git 版本信息表示 git 安装成功。
1. 在 Jenkins 管理插件中安装 `GIT plugin`
1. 在 Jenkins 系统设置中设置 git 参数，在 `Path to Git executable` 中输入 `X:\Program Files\Git\cmd\git.exe`.

<h3 id="jenkins-encoding">乱码问题</h3>

乱码是由于非英文编码不一致造成的，因此，统一编码即可解决。在相关输出中文信息部分单独指定编码是可以解决乱码问题的。如果觉得麻烦，提供一个简单粗暴但是可能会引起其他问题的办法。
* 在系统环境变量中添加变量名 `JAVA_TOOL_OPTIONS` ，设置变量值为 `-Dfile.encoding=UTF-8` 。
设置后会将系统所有 java 相关的编码修改为 UTF-8 ，可以解决 java 相关 UTF-8 编码的乱码问题，但也可能造成无法编译的情况。

---

<h2 id="linux-deploy">在 Linux 中部署</h2>

<h3 id="linux-deploy-note">注意</h3>

* 以下操作在 CentOS6.5 x64 上完成
* Mac大法好同时可以编译 Android 和 iOS 项目,巨硬西奈 
* ~~然而我并没有一台 Mac~~

<h3 id="linux-deploy-jenkins">部署 Jenkins</h4>

<h4 id="linux-install-jdk">安装 JDK</h4>

<h4 id="linux-install-tomcat">安装 Tomcat</h4>

<h4 id="linux-install-jenkins">安装 Jenkins</h4>

<h3 id="linux-install-adk">安装 Android SDK</h3>

[Android SDK Tools](http://developer.android.com/intl/zh-cn/sdk/index.html#Other)
下载 Linux 版本解压，需要配置系统环境变量 `ANDROID_HOME`

<h3 id="linux-install-git">安装 Git</h3>

---

<h2 id="mac-deploy">在 Mac OS 中部署</h2>

* ~~还好公司有一台Macbook~~

<h3 id="mac-deploy-note">注意</h3>

<h3 id="mac-deploy-jenkins">部署 Jenkins</h3>
在 Mac 中可以使用 `brew` 方便的安装 `Jenkins` ，当然，你仍然可以手动安装所需的 JDK 运行环境来部署 `Jenkins`。

<h4 id="brew-install">安装 brew</h3>

首先安装用下面的命令安装 brew

`ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`


<h4 id="mac-install-jdk">安装 JDK</h4>

`sudo brew install java`

<h4 id="mac-install-jenkins">安装 Jenkins</h4>

`sudo brew install jenkins`

<h4 id="mac-install-ant">安装 Ant</h4>
---

<div align="center">
![](http://pic.tomczhen.com/alipay_QR.png)  
如果对您有帮助的话，可以考虑通过支付宝请作者喝杯咖啡。
</div>