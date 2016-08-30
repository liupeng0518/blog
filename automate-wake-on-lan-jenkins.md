title: Automate实现远程唤醒开机以及扩展应用
date: 2016-01-21 22:06:51
categories: 
  - other
  - android
feature: http://www.tomczhen.com/images/logo/automate-logo.webp
tags: 
  - android
  - automate
---
<h2 id="readme">准备条件</h2>

基本要求：
* [Server 酱](http://sc.ftqq.com/2.version)
* [Automate](http://www.coolapk.com/apk/com.llamalab.automate)
* 系统版本 Android 4.3 以上手机一部
* 知道怎么设置 BIOS

扩展要求：
* [Jenkins](https://jenkins-ci.org/)
* 懂一些 Shell 或 Windows 批处理命令

　　以上，如果只需要满足远程开机，你需要满足基本要求中列出的事项。如果想实现各种花样，你需要满足扩展要求中列出的事项，如果觉得有难度，请购买花生壳开机棒。

<h2 id="wol">实现推送消息网络唤醒主机</h2>

　　需要主板以及系统支持 Wake-On-Lan 功能，懂得 BIOS 设置如何设置。需要注意的是，完全断电/非法关机时有部分主板无法通过 WOL 功能唤醒启动，与 BIOS 设置或硬件有关，有相关问题请咨询硬件厂商或百度。
　　或者看看这篇花生壳的文章 [判断主机是否支持远程开机？](http://service.oray.com/question/1331.html)

<!-- more -->

<h3 id="serverchan">安装 Server 酱</h3>

　　安装好 `Server 酱` 并注册两个 GitHub 账号绑定，分别称为 A 账号和 B 账号，在 A 手机上安装好 Server 酱 App 并绑定 A 账号，这部手机称为 A 手机。如果不需要返回远程执行任务的结果或者其他信息则只需要注册一个账号即可。
假设注册量个账号都激活的话会获得两个接口地址 `http://sc.ftqq.com/Asckey.send` 与 `http://sc.ftqq.com/Bsckey.send` 。

　　通过在浏览器中输入 `http://sc.ftqq.com/Asckey.send?text=主人服务器又挂掉啦~` 测试绑定 A 手机能否收到到Server酱的推送消息。能收到的话完成第一步。

<h3 id="automate">安装 Automate </h3>

　　A 手机必须安装，可以在另一台手机（B手机）上安装，也可以直接使用网页推送信息。建议用另一台手机安装，可以实现更多的功能，例如：A 手机执行任务流后向 B 手机推送执行结果。

<h4 id="push">消息推送</h4>

　　在 B 手机上安装好 Automate，下载 [推送消息.flo](http://pan.baidu.com/s/1dEaxemP) 导入到 Automate，这个工作流是用于向 A 手机推送消息的，如果需要 A 手机执行任务后向 B 手机推送消息，那么需要 B 手机安装好 Server 酱并绑定 B 账号。
A 手机导入该任务后将推送地址接口改为 B 账号对应的接口即可做到向 B 手机推送消息。

　　需要注意的是 `http://sc.ftqq.com/Asckey.send?text=%23开机` 中 `%23` 是 `#` 号的编码，特殊符号作为请求参数时需要进行编码，可以在 [在线编码转换](http://tool.oschina.net/encode?type=4) 中查看需要发送的信息编码后的情况，注意要选择`encodeURIComponent`。

修改好请求参数之后，可以测试运行任务，看看 A 手机是否能接受到推送消息。需要注意的是相同内容的信息一分钟内只能发送一次，具体的限制请查看 Server 酱的官方网站。

<h4 id="wolflo">自动唤醒</h4>

　　在 A 手机上安装好 Automate，下载 [读取应用通知.flo](http://pan.baidu.com/s/1o7ux4lO) 按提示导入到 Automate ，进入 Atuomate 里查看导入的工作流。
![](http://tomczhen.oss-cn-shenzhen.aliyuncs.com/Screenshot_20160121-210613.png)
　　首先需要将必要的权限允许，任务执行需要的权限已经列出，点击安装按钮进行安装即可。
![](http://tomczhen.oss-cn-shenzhen.aliyuncs.com/Screenshot_20160121-210647.png)

**任务说明**

* `When notification`
判断通知栏的应用包名，限定为Server酱的包名，并且输出三个参数`app` `title` `message`分别对应应用名称，消息标题，消息内容。
* `title="#开机"`
判断通知信息的标题是否为#开机
* `Turn on flashlight`
打开闪光灯
* `Delay awake`
加入一个等待
* `Send Wake-on-LAN`
发送WOL包，编辑可以输入IP和MAC
* `Turn off flashlight`
关闭闪光灯

注意:闪光灯的开启只是为了方便调试，因为只是发送 WOL 包的话你无法知道是否任务触发(虽然可以看 LOG ,但是闪光灯更直观),测试完成后可以将闪光灯的操作删除。
    
PS:为了判断是否唤醒成功，可以自己添加一个新的流程， ping 主机 IP，ping 通后调用推送任务推送信息到 B 账号，由 B 手机接收信息。
    
<h3 id="jenkins">Jenkins</h3>

Jenkins 本来是用于软件开发中实现持续集成的，可以实现调用接口的方式执行设定好的任务。类似前面的消息推送，使用一个 http 请求来让服务器运行指定的任务。
在非 Windows 系统上安装 Jenkins 需要有一定的 Linux 操作基础以及了解基本的 Shell 命令。

* 在 FreeBSD 中安装 Jenkins:[https://wiki.jenkins-ci.org/display/JENKINS/FreeBSD](https://wiki.jenkins-ci.org/display/JENKINS/FreeBSD)
* 在 Windows 中安装 Jenkins:[https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+as+a+Windows+service](https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+as+a+Windows+service)

我的建议是：如果你连这个的安装都搞不定的话，还是别折腾这一段了。

以在 Windows 中安装 Jenkins 为前提，实现一个调用接口关机的例子
* 首先在 jenkins 中创建一个自由风格的软件项目，命名为 `PowerOff`

![](http://tomczhen.oss-cn-shenzhen.aliyuncs.com/20160122105222.png)

在任务内容中选择执行 windows 命令，然后输入 Windows 关机命令 `shutdown -s -t 60`

![](http://tomczhen.oss-cn-shenzhen.aliyuncs.com/20160122105249.png)

![](http://tomczhen.oss-cn-shenzhen.aliyuncs.com/20160122105406.png)

保存之后，再次点击进入任务页面，可以在右下角看到这个项目的地址 `http://192.168.1.100:81/job/PowerOff/` ，使用 http 请求执行这个任务的地址就是 `http://192.168.8.250:81/job/PowerOff/build`

* 参考前面调用 Server 酱信息推送接口的任务，在 Automate 中创建自己的流程，然后执行流程试试运行结果吧。
![](http://tomczhen.oss-cn-shenzhen.aliyuncs.com/Screenshot_20160122-110758.png)

`REQUEST METHOD` 需要选择为 `POST` ，在 `REQUEST URL` 里填写调用任务的URL地址 `http://192.168.8.250:81/job/PowerOff/build`,保存这个工作流，执行一下就可以完成调用任务关机了。

注意：调用的命令可能会因为运行 jenkins 服务的账号权限问题而无法执行或执行失败，需要进行相应的权限设置或改变运行 jenkins 的账号。
