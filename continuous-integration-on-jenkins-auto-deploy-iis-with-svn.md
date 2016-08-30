title: Jenkins实现持续集成——使用SVN实现IIS站点自动部署
date: 2016-01-15 19:25:51
categories: 
  - ci
  - jenkins
feature: /images/logo/jenkins-logo.webp
tags: 
  - jenkins
  - ci
  - svn
  - iis
toc: true
---
<h2 id="svn">安装 SVN Server</h2>

访问 [https://www.visualsvn.com/server/download/](https://www.visualsvn.com/server/download/) 并下载标准版安装到服务器。
需要注意修改 SVN 默认服务端口，防止被工具扫描，并设置好强口令以免暴力破解密码。

<h3 id="repo">配置 SVN 版本库</h3>

为每个站点或虚拟目录建立版本库，并设置好权限。

<h3 id="config">配置 SVN 服务</h3>

由于 hook 脚本涉及到创建文件以及调用 `appcmd` 命令修改 IIS 站点配置，因此需要足够的权限运行命令。修改 IIS 配置需要管理员权限，因此 SVN Server 服务运行的账号拥有管理员权限。

<h2 id="osenv">系统环境</h2>

由于 `appcmd` 命令路径并未配置在 `Path` 中，为使用方便，可以添加 `%systemroot%\system32\inetsrv\` 到系统环境变量 `Path` 中，在命令行中输入 `appcmd /?` 可以查看帮助。

<h3 id="dateformat">日期格式</h3>

由于 Hooks 脚本中有使用系统变量 `date` 生成文件夹，而 Windows 系统没有简单的格式化日期输出的办法，因此修改系统设置是最简单的办法。
需要在控制面板，区域中修改日期短格式为 `yyyy-MM-dd` ，在命令行中输入 `echo %date%` 输出的日期格式应为 `2016-01-15`。也可以使用网上的Windows日期格式化脚本达到目的。

<!-- more -->

<h3 id="appcmd">IIS 命令行管理工具</h3>

>参考资料：
>关于 appcmd
>IIS 7 提供了一个新的命令行工具 Appcmd.exe，可以使用该工具来配置和查询 Web 服务器上的对象，并以文本或 XML 格式返回输出。 下面是一些可以使用 Appcmd.exe 完成的任务的示例：
>* 创建和配置站点、应用程序、应用程序池和虚拟目录。
>* 停止和启动站点。
>* 启动、停止和回收应用程序池。
>* 查看有关在 Web 服务器上运行的工作进程和请求的信息。

>[Getting Started with AppCmd.exe](http://www.iis.net/learn/get-started/getting-started-with-iis/getting-started-with-appcmdexe)  
>[使用 Appcmd.exe 为站点、应用程序、虚拟目录或 URL 配置设置 (IIS 7)](https://technet.microsoft.com/zh-cn/library/cc732107.aspx)  

使用 `appcmd` 命令可以实现所有的站点管理功能，但这里我们只实现站点自动部署功能。

<h2 id="hoooks">设置 SVN Hooks</h2>

<h3 id="scprits"> Hook 脚本</h3>

```shell
set sitename=mysite
set dir=v%date:~0,4%%date:~5,2%%date:~8,2%-%2
set sitepath=D:\www\mysite\%dir%
mkdir %sitepath%
svn export https://localhost:8443/svn/mysite/ %sitepath% --force
appcmd set site /site.name:%sitename% -[path='/'].[path='/'].physicalPath:%sitepath%
```

<h3 id="readme">脚本说明</h3>

* `set sitename=mysite`
设置变量`sitename`
* `set dir=v%date:~0,4%%date:~5,2%%date:~8,2%-%2`
根据当前日期和SVN版本生成文件夹名，当前生成文件夹名为`v20160115-1`(假设SVN版本号为1)
* `set sitepath=D:\www\mysite\%dir%`
设置新路径值到变量`sitepath`,当前路径值为`D:\www\mysite\v20160115-1`
* `mkdir %sitepath%`
创建路径
* `svn export https://localhost:8443/svn/mysite/ %sitepath% --force`
导出svn版本库中的文件到指定目录，导出方式不会带有`.svn`目录，避免路径浏览泄漏版本文件信息。
* `appcmd set site /site.name:%sitename% -[path='/'].[path='/'].physicalPath:%sitepath%`
设置`mysite`的站点根目录物理路径到新建的路径。
已创建新目录的方式可以方便回滚到旧版本，只需要修改站点的物理路径到上一次创建的路径即可实现回滚。


<h2 id="ant">使用 Ant 脚本修改配置文件</h2>

>注意：由于公司需求是要对开发人员隔离测试环境与生产环境，所以开发、测试、生产环境所使用的 SVN 仓库是独立的，并不是在同一仓库下做分支处理。

<h3 id="ant-code">build.api.xml</h3>

说明：
* 运行平台为 Mac OS，如果其他平台需要测试相应的 shell 命令是否正常。
* 替换配置信息，并将源仓库文件移动到目标仓库。
* 为了避免“额外的文件”造成部署后引起异常，使用了先将目标仓库签出，然后删除所有文件，再将源仓库签出文件复制到目标目录的做法。

```
<?xml version="1.0" encoding="UTF-8"?>
<project name="APIDeployToBeta" default="warning" basedir="..">
  <property name="api.dev.path" value="api_dev" />
  <property name="api.beta.path" value="api_beta" />
  <property name="api.release.path" value="api_release" />
  <property name="api.name" value="${APIName}" />
  <import file="plug/WeChat.xml" />

  <target name="warning" >
    <echo message="必须指定运行的Target" />
  </target>

  <target name="test" >
    <loadproperties srcFile="ant-script/config/beta.config.properties" />
    <antcall target="-modify" />
  </target>

  <target name="deploy2beta" depends="-beta-config, -svn-deploy" >
  </target>

  <target name="deploy2release" depends="-release-config, -svn-deploy" >
  </target>

  <target name="-beta-config">
    <echo message="加载外网测试环境配置信息" />
    <loadproperties srcFile="ant-script/config/beta.config.properties" />
    <property name="build.config.name" value="外网测试" />
    <property name="path.origin" value="${api.dev.path}" />
    <property name="path.target" value="${api.beta.path}" />
  </target>

  <target name="-release-config">
    <echo message="加载外网正式环境配置信息" />
    <loadproperties srcFile="ant-script/config/release.config.properties" />
    <property name="build.config.name" value="外网正式" />
    <property name="path.origin" value="${api.beta.path}" />
    <property name="path.target" value="${api.release.path}" />
    
  </target>

  <target name="-svn-deploy" depends="-modify, -svn-add, -svn-del, -svn-update" >
    <echo message="更新[target]SVN" />
  </target>

  <target name="-svn-add" >
    <echo message="SVN Force Add" />
    <exec executable="sh" failonerror="true">
      <arg value="-c" />
      <arg value="svn add --force ./${path.target}/*" />
    </exec>
  </target>

  <target name="-svn-del" >
    <echo message="SVN Delete Files" />
    <exec executable="sh" failonerror="true">
      <arg value="-c" />
      <arg value="svn status ./${path.target} |grep ! |awk '{print $2}'|xargs svn del" />
    </exec>
  </target>

  <target name="-svn-update" >
    <echo message="SVN Update" />
    <exec executable="sh" failonerror="true">
      <arg value="-c" />
      <arg value="svn ci ./${path.target} -m Jenkins-${JOB_NAME}-${BUILD_NUMBER}" />
    </exec>
  </target>

  <target name="-svn-upgrade" >
    <echo message="Target SVN Upgrade" />
    <exec executable="svn" failonerror="false">
      <arg value="upgrade" />
      <arg value="./${path.target}" />
    </exec>
  </target>

  <target name="-del-file-target">
    <echo message="删除[target]文件" />
    <delete includeemptydirs="true" verbose ="true">
      <fileset dir="${path.target}" includes="**/*"/>
    </delete>
  </target>

  <target name="-copy-file-origin2target" >
    <echo message="复制[origin]文件到[target]" />
    <copy todir="./${path.target}" verbose ="true">
      <fileset dir="./${path.origin}">
        <!-- <exclude name="**/*.md"/> -->
      </fileset>
    </copy>
  </target>

  <target name="-modify" depends="-del-file-target, -copy-file-origin2target" >
    <echo message="修改[target]web.config配置"/>
    
    <!-- Database Config -->
      <!-- Default -->
      <replaceregexp flags="g" byline="false" encoding="UTF-8">
        <regexp pattern="(name=&quot;myconn&quot;)(.*)(Data Source=)(.*)(;Initial)" />
        <substitution expression="\1\2\3${db.source}\5" />
        <fileset dir="" includes="${path.target}/Web.config" />
    </replaceregexp>

    <replaceregexp flags="g" byline="false" encoding="UTF-8">
      <regexp pattern="(name=&quot;myconn&quot;)(.*)(Catalog=)(.*)(;Persist)" />
      <substitution expression="\1\2\3${db.name}\5" />
      <fileset dir="" includes="${path.target}/Web.config" />
    </replaceregexp>

    <replaceregexp flags="g" byline="false" encoding="UTF-8">
      <regexp pattern="(name=&quot;myconn&quot;)(.*)(User ID=)(.*)(;Password)" />
      <substitution expression="\1\2\3${db.userid}\5" />
      <fileset dir="" includes="${path.target}/Web.config" />
    </replaceregexp>

    <replaceregexp flags="g" byline="false" encoding="UTF-8">
      <regexp pattern="(name=&quot;myconn&quot;)(.*)(Password=)(.*)(&quot;)" />
      <substitution expression="\1\2\3${db.passwd}\5" />
      <fileset dir="" includes="${path.target}/Web.config" />
    </replaceregexp>
    
    <!-- API URL -->
    <replaceregexp flags="g" byline="false" encoding="UTF-8">
      <regexp pattern="(key=&quot;APIURL&quot;)(.*)(value=&quot;)(.*)(&quot;)" />
      <substitution expression="\1\2\3${api.url}\5" />
      <fileset dir="" includes="${path.target}/Web.config" />
    </replaceregexp>
    
    <!-- RongCloud -->
    <replaceregexp flags="g" byline="false" encoding="UTF-8">
      <regexp pattern="(key=&quot;AppKey&quot;)(.*)(value=&quot;)(.*)(&quot;)" />
      <substitution expression="\1\2\3${rongcloud.key}\5" />
      <fileset dir="" includes="${path.target}/Web.config" />
    </replaceregexp>

    <replaceregexp flags="g" byline="false" encoding="UTF-8">
      <regexp pattern="(key=&quot;AppSecret&quot;)(.*)(value=&quot;)(.*)(&quot;)" />
      <substitution expression="\1\2\3${rongcloud.secret}\5" />
      <fileset dir="" includes="${path.target}/Web.config" />
    </replaceregexp>

    <!-- JPush -->
    <replaceregexp flags="g" byline="false" encoding="UTF-8">
      <regexp pattern="(key=&quot;JPush_AppKey&quot;)(.*)(value=&quot;)(.*)(&quot;)" />
      <substitution expression="\1\2\3${jpush.key}\5" />
      <fileset dir="" includes="${path.target}/Web.config" />
    </replaceregexp>

    <replaceregexp flags="g" byline="false" encoding="UTF-8">
      <regexp pattern="(key=&quot;JPush_MasterSecret&quot;)(.*)(value=&quot;)(.*)(&quot;)" />
      <substitution expression="\1\2\3${jpush.secret}\5" />
      <fileset dir="" includes="${path.target}/Web.config" />
    </replaceregexp>
    
  </target>

  <target name="-build-report" >
    <echo message="构建报告" />
    <exec executable="date" outputproperty="build.report.time" failifexecutionfails="false" errorproperty="DateError">
      <arg value="+%Y年%m月%d日%H:%M" />
    </exec>
    <echo message="Build Complete:${api.name} - ${ant.project.name} [${build.config.name}]" encoding="UTF-8"></echo>

  </target>

  <target name="send-wechat" >
    <property name="build.digest" value="部署完成${line.separator}${api.name} - ${ant.project.name} [${build.config.name}]" />
    <property name="build.report" value="&lt;p&gt;部署完成&lt;br/&gt;${api.name} - ${ant.project.name} [${build.config.name}]&lt;br/&gt;${build.report.time}&lt;/p&gt;" />
    <property name="wechat.mpnews.json" value="{&quot;touser&quot;:&quot;${wechat.userid}&quot;,&quot;toparty&quot;:&quot;${wechat.partyid}&quot;,&quot;totag&quot;:&quot;&quot;,&quot;msgtype&quot;:&quot;mpnews&quot;,&quot;agentid&quot;:${wechat.agentid},&quot;mpnews&quot;:{&quot;articles&quot;:[{&quot;title&quot;:&quot;Jenkins 构建通知&quot;,&quot;thumb_media_id&quot;:&quot;${corp.media}&quot;,&quot;author&quot;:&quot;&quot;,&quot;content_source_url&quot;:&quot;&quot;,&quot;content&quot;:&quot;${build.report}&quot;,&quot;digest&quot;:&quot;${build.digest}&quot;,&quot;show_cover_pic&quot;:&quot;0&quot;}]},&quot;safe&quot;:&quot;0&quot;}" />
    
    <antcall target="wechat" />
  </target>

</project>
```

<h3 id="config">config/beta.config.properties</h3>

```
# 说明
# 非英文数字字符必须转换编码后才能读取正常 Natvie->ASCII
# http://tool.oschina.net/encode?type=3 

# 数据库配置
db.source=127.0.0.1,3433
db.name=database-beta
db.userid=sqluser
db.passwd=sqlpwd

# Redis
redis.host=127.0.0.1
redis.port=6379
redis.pwd=redispwd

# API URL
api.url=http://api.android.com
```

<h3 id="wechat">相关脚本链接</h3>


---

<div align="center">
![](/images/logo/alipay_tomczhen.webp)  
如果对您有帮助的话，可以考虑通过支付宝请作者喝杯咖啡。
</div>
