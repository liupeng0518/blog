title: Jenkins——在 Windows 中安装 Jenkins
date: 2015-12-08 19:25:51
categories:
  - ci
  - jenkins
feature: http://www.tomczhen.com/images/logo/jenkins-logo.webp
tags:
  - jenkins
toc: true
---

>原文地址:
>[Installing Jenkins as a Windows service](https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+as+a+Windows+service)

<!-- more -->

### Windows 安装

如果需要将 Jenkins 作为 Windows 服务在无需用户登录的情况下运行，那么最简单的方法就是使用在主页下载的 Windows 安装包进行安装，这也是最容易的方法。
也可以在安装好的 servlet 容器中部署 Jenkins，像是 GlassFish 和 Tomcat。

### 作为 Windows 服务安装 Jenkins

注意：如果你是使用的 Windows 安装包安装的 Jenkins，安装包已经自动配置 Jenkins 作为一个 Windows 服务运行。
在安装之前你需要先启动 Jenkins。 可以在 Web 容器中启动或者直接运行 `java -jar jenkins.war`。
然后通过 `http://<hostname>:8080/` 连接 Jenkins ，在系统管理 (Manage Jenkins) 找到 Install as Windows Service 的链接(需要 Microsoft .NET framework 2.0)：

![](http://pic.tomczhen.com/jenkins-install-windows-1.png)

注意：如果 Jenkins 已经是做为一个服务运行，那么 Install as Windows Service 的链接不会出现。可以在系统服务中检查 Jenkins 是否已经做为一个服务运行。

点击链接显示安装页面：

![](http://pic.tomczhen.com/jenkins-install-windows-2.png)

选择 Jenkins 安装的目录，目标必须是已经存在的。目录路径会成为 `JENKINS_HOME` 变量值，并且将用于保存程序数据。安装完成之后页面会询问是否重启 Jenkins 。

![](http://pic.tomczhen.com/jenkins-install-windows-3.png)

选择是会以新安装系统服务启动 Jenkins。

>如果重启失败，需要在你选择的安装路径查看 Jenkins 的输出日志。
>在 Windows Server 2008R2 下需要添加 `C:\Windows\SysWOW64` 到 `PATH` 系统环境变量。

可以在系统服务中检查 Jenkins 是否已经做为服务在运行。

![](http://pic.tomczhen.com/jenkins-install-windows-4.png)

### 作为 Windows 服务安装 Slave 代理(需要 .NET 2.0 framework)

Jenkins 允许将 slave 代理作为 Windows 服务安装。

需要将 slave 配置为以 JNLP slave 代理运行:

在 slave 机器上运行代理，会显示下面的窗口：

![](http://pic.tomczhen.com/jenkins-install-windows-6.png)

在目录中选择 "File" > "Install as Windows Service" ：

![](http://pic.tomczhen.com/jenkins-install-windows-7.png)

确认打算作为服务安装。安装会将程序文件放到 slave 的根目录(from the "configure executors" screen.)

![](http://pic.tomczhen.com/jenkins-install-windows-8.png)

Once the installation succeeds, you'll be asked if you'd like to stop the current slave agent and immediately start a slave agent. 
安装成功后会询问是否停止当前 slave 代理并立刻启动 slave 代理(作为服务启动)。

点击 "OK" 后 slave 代理窗口会终止。然后作为服务运行的 slave 代理会以无窗口模式运行，在服务管理面板中可以确认 slave 代理服务是否作在运行。

![](http://pic.tomczhen.com/jenkins-install-windows-10.png)

>如果 slave 应该启动桌面应用，可以在服务属性中设置允许服务与桌面交互。

### 使用 Windows 计划任务启动 Java Web Start slave 代理

如果上面的方法遇到问题无法解决你可以尝试使用 [Windows 计划任务](https://wiki.jenkins-ci.org/display/JENKINS/Launch+Java+Web+Start+slave+agent+via+Windows+Scheduler)来实现 slave 代理自动启动。

### 修改服务配置

将 Jenkins 作为 Windows 服务安装后，JVM 启动参数是由JENKINS_HOME( Windows 中是 %JENKINS_HOME% ) 和 slave 根目录的 jenkins.xml 和 jenkins-slave.xml 控制。

文件会自动生成，你可以调整参数增加 JVM 可使用的最大内存。

服务进程输出和错误日志文件也在同一目录下。

### 卸载

在命令行中执行 `jenkins-slave.exe uninstall` 卸载 Jenkins slave 服务。
在命令行中执行 `jenkins.exe uninstall` 卸载 Jenkins 服务。

### 故障排除

如果 slave 服务没有正常启动，根据下面的说明获取更多的信息解决问题
* 查看 Windows 事件查看器中关于 Jenkins 的日志信息。主要关注 Windows 服务事件，例如服务器的启动和终止。
* 查看 Jenkins 的日志文件。进程会输出标准信息和错误到日志文件，也会包含一些 Java 堆栈信息。
---

<div align="center">
![](http://pic.tomczhen.com/alipay_QR.png)  
如果对您有帮助的话，可以考虑通过支付宝请作者喝杯咖啡。
</div>