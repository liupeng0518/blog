title: IOS 应用构建 Ant 脚本
date: 2016-01-11 17:45:00
categories: 
  - CI
feature: /images/logo/apache-ant-logo.webp
tags: 
  - Ant
  - iOS
toc: true
---

<h2 id="readme">注意事项</h2>

~~首先你需要有一台Mac，其实写个shell也能解决~~

* **脚本是调用xctool命令进行编译，所以必须先安装好xctool。**
* **如果提示找不到 xctool 命令，请在 Jenkins 系统设置中添加 path 变量，并输入系统 path 值。**
* **调用脚本 Target `-pack` 执行 `CocoaPods` 报错，提示 `encoding` `UTF-8` 相关信息时，需要在 Jenkins 系统设置中增加 `LANG`，值为 `zh_CN.UTF-8`。**
* **由于首次构建ios项目时会有一个访问系统钥匙串的提示,只会在图形界面下有,因此最好手动执行一下该脚本,确认提示.**

<!-- more -->

---

<h2 id="target">Target 说明</h2>

* `dev`
使用开发环境相关配置信息进行构建
    * `-dev-config`
    开发环境相关配置信息
* `beta`
使用测试环境相关配置信息进行构建
    * `-beta-config`
    测试环境相关配置信息
* `release`
使用正式环境相关配置信息进行构建
    * `-release-config`
    正式环境相关配置信息
* `appstore`
使用正式环境相关配置信息进行构建
    * `-appstore-config`
    正式环境相关配置信息
* `-modify`
根据指定的配置信息修改代码段
    * `-modify-appname`
    修改应用名称
    * `-check-isNeedModifyAppName`
    检查是否需要修改应用名称
* `-get-cvs-info`
或者版本控制系统相关信息
* `-pack`
调用xctool构建ipa文件
* `-out-file`
输出文件到指定路径
    * `-check-isNeedOutFile`
    检查是否需要输出文件到指定目录
* `-build-report`
生成构建报告信息
* `-bugly`
上传至蒲公英平台
    * `-bugly-config`
    微信相关配置信息

* `send-wechat`
使用微信企业号API发送构建通知
    * `-wechat-config`
    微信相关配置信息

---

<h2 id="howto">使用说明</h2>

* 上传到蒲公英平台需要在 target `-pgy` 中设置 `pgy.ukey` `pgy.api_key`
* 如果不需要上传到蒲公英需要在 `dev` 等 target 的 depends 中去掉 `-pgy`
* target `-out-file` 需要根据需要修改路径
* target `wechat` 需要在执行脚本时手动指定，例如 `ant -buildfile ios.build.xml dev wechat`
* 使用微信通知需要在 target `-wecha-config` 配置好 `wechat.partyid` `wechat.agentid` `wechat.userid` ,其中 `corp.media` 使用的素材 ID 需要是对应的微信应用下的素材，推荐使用永久素材。

<h2 id="code">脚本代码</h2>

<h3 id="ios">build.ios.xml</h3>

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project name="DJT" default="dev" basedir="..">
  <property name="project.name" value="DJPlatform" />
  <property name="project.workspace.name" value="DJPlatform" />
  <property name="project.scheme.name" value="DJPlatform" />
  <import file="plug/WeChat.xml" />
  <import file="plug/Bugly.xml" />
  
  <exec executable="date" outputproperty="build.time" failifexecutionfails="false" errorproperty="DateError">
    <arg value="+%Y%m%d%H%M" />
  </exec>
  
  <target name="dev" depends="-dev-config, -pack, -build-report, -bugly">
  </target>
  
  <target name="beta" depends="-beta-config, -pack, -build-report, -bugly">
  </target>
  
  <target name="release" depends="-release-config, -pack, -build-report, -bugly">
  </target>
  
  <target name="appstore" depends="-appstore-config, -pack, -build-report">
  </target>
  
  <target name="-get-cvs-info" >
  <!-- 获取CVS信息 -->
    <echo message="读取CVS信息" />
    
    <exec executable="git" outputproperty="cvs.tag" failifexecutionfails="false" errorproperty="GitTagError">
      <arg value="describe" />
      <arg value="--tags" />
    </exec>
    <exec executable="git" outputproperty="cvs.commit" failifexecutionfails="false" errorproperty="GitCommitError">
      <arg value="log" />
      <arg value="--pretty=format:%h" />
      <arg value="-n1" />
    </exec>
    <exec executable="git" outputproperty="normalcvs.log" failifexecutionfails="false" errorproperty="GitLogError">
      <arg value="log" />
      <arg value="--pretty=format:%B" />
      <arg value="-n1" />
    </exec>
    
    <!-- 替换掉"号防止json解析错误 -->
    <loadresource property="cvs.log">
      <propertyresource name="normalcvs.log"/>
      <filterchain>
        <tokenfilter>
          <filetokenizer/>
          <replacestring from='"' to=' '/>
        </tokenfilter>
      </filterchain>
    </loadresource>
  </target>

  <target name="-dev-config" depends="-get-cvs-info">
    <echo message="加载内网开发环境配置信息" />
    <loadproperties srcFile="ant-script/config/dev.config.properties" />
    <property name="project.profile.name" value="djt_adhoc" />
    <!-- 构建内网测试包配置信息 -->
    <property name="app.name" value="-Dev" />
    <property name="build.type" value="Dev" />
    <property name="build.config.name" value="连接内网开发环境" />
    <property name="build.file.path" value="dev" />
    <property name="build.file.name" value="${project.name}_${cvs.tag}_beta${build.time}" />
    
  </target>
  
  <target name="-beta-config" depends="-get-cvs-info">
    <echo message="加载外网测试环境配置信息" />
    <loadproperties srcFile="ant-script/config/beta.config.properties" />
    <property name="project.profile.name" value="djt_adhoc" />
    <!-- 构建外网测试包配置信息 -->
    <property name="app.name" value="-Beta" />
    <property name="build.type" value="Beta" />
    <property name="build.config.name" value="连接外网测试环境" />
    <property name="build.file.path" value="beta" />
    <property name="build.file.name" value="${project.name}_${cvs.tag}_beta${build.time}" />
  </target>
  
  <target name="-release-config" depends="-get-cvs-info">
    <echo message="加载外网正式环境配置信息" />
    <loadproperties srcFile="ant-script/config/release.config.properties" />
    <property name="project.profile.name" value="djt_adhoc" />
    <!-- 构建正式包配置信息 -->
    <property name="app.name" value="-Release" />
    <property name="build.type" value="Release" />
    <property name="build.config.name" value="连接外网正式环境-Bugly" />
    <property name="build.file.path" value="release" />
    <property name="build.file.name" value="${project.name}_${cvs.tag}_r${build.time}" />
  </target>
  
  <target name="-appstore-config" depends="-get-cvs-info">
    <echo message="加载外网正式环境配置信息-AppStore" />
    <loadproperties srcFile="ant-script/config/release.config.properties" />
    <property name="project.profile.name" value="djt_appstore" />
    <!-- 构建正式包配置信息 -->
    <property name="app.name" value="" />
    <property name="build.type" value="AppStore" />
    <property name="build.config.name" value="连接外网正式环境-AppStore" />
    <property name="build.file.path" value="release" />
    <property name="build.file.name" value="${project.name}_${cvs.tag}_r${build.time}" />
    
    <property name="build.file.url" value="http://download.jenkins.51djt.com/IOS/${project.scheme.name}/${build.file.name}.ipa" />
    <property name="build.file.qrcode" value="http://qr.liantu.com/api.php?text=${build.file.url}" /> 
    
  </target>
  
  <target name="-modify" depends="-modify-appname">
    <echo message="修改代码中的相关配置字段"/>
    <!-- 配置第三方 Key -->
      <!-- 融云 Key -->
      <replaceregexp byline="true" encoding="UTF-8">
        <regexp pattern='^#define\s+RONGCLOUD_IM_APPKEY\s+(.*)' />
        <substitution expression='#define RONGCLOUD_IM_APPKEY @"${rongcloud.key}"' />
        <fileset dir="DJPlatform/Classes/Main/Other" includes="DJConst.h" />
      </replaceregexp>
      <!-- 融云客服 ID -->
      <replaceregexp byline="true" encoding="UTF-8">
        <regexp pattern='^#define\s+CustomerServiceId\s+(.*)' />
        <substitution expression='#define CustomerServiceId @"${rongcloud.scid}"' />
        <fileset dir="DJPlatform/Classes/Main/Other" includes="DJConst.h" />
      </replaceregexp> 
      <!-- JPush -->
      <replaceregexp flags="g" byline="false" encoding="UTF-8">
        <regexp pattern="(&lt;key&gt;APP_KEY&lt;/key&gt;\s+&lt;string&gt;)(.*)(&lt;/string&gt;)" />
        <substitution expression="\1\${jpush.key}\3" />
        <fileset dir="DJPlatform" includes="PushConfig.plist" />
      </replaceregexp>

  </target>
    
  <target name="-check-isNeedModifyAppName" >
    <echo message="检查是否需要修改构建的App Name" />
    <condition property="isNeedModifyAppName">
      <not>
        <equals arg1="${build.type}" arg2="AppStore" />
      </not>
    </condition>
  </target>

  <target name="-modify-appname" if="isNeedModifyAppName" depends="-check-isNeedModifyAppName">
    <!-- 配置 App 名称 -->
    <echo message="修改构建的App Name" />
    <replaceregexp flags="g" byline="false" encoding="UTF-8">
      <regexp pattern="(&lt;key&gt;CFBundleDisplayName&lt;/key&gt;\s+&lt;string&gt;)(.*)(&lt;/string&gt;)" />
      <substitution expression="\1\2${app.name}\3" />
      <fileset dir="DJPlatform" includes="Info.plist" />
    </replaceregexp>
  </target>
  
  <target name="podRepoUpdate" >
  <!-- pod update-->
    <exec executable="pod" failonerror="true">
      <arg value="repo" />
      <arg value="update" />
    </exec>
  </target>
  
  <target name="-pack" depends="-modify">
    <echo message="进行构建" />
    <property name="build.archive.path" value="build/${build.file.path}/${build.file.name}" />
    <!-- pod install-->
    <exec executable="pod" failonerror="true">
      <arg value="install" />
      <arg value="--verbose" />
      <arg value="--no-repo-update" />
    </exec>
    <!-- Clean -->
    <exec executable="xcodebuild" failonerror="true">
      <arg value="-workspace" />
      <arg value="${project.workspace.name}.xcworkspace" />
      <arg value="-scheme" />
      <arg value="${project.scheme.name}" />
      <arg value="clean" />
    </exec>
    <!-- archive -->
    <exec executable="xcodebuild" failonerror="true">
      <arg value="-workspace" />
      <arg value="${project.workspace.name}.xcworkspace" />
      <arg value="-scheme" />
      <arg value="${project.scheme.name}" />
      <arg value="build" />
      <arg value="archive" />
      <arg value="-archivePath" />
      <arg value="${build.archive.path}" />
    </exec>
    <!-- export ipa -->
    <exec executable="xcodebuild" failonerror="true">
      <arg value="-exportArchive" />
      <arg value="-archivePath" />
      <arg value="${build.archive.path}.xcarchive" />
      <arg value="-exportPath" />
      <arg value="${build.archive.path}.ipa" />
      <arg value="-exportFormat" />
      <arg value="ipa" />
      <arg value="-exportProvisioningProfile" />
      <arg value="${project.profile.name}" />
    </exec>
    
    <antcall target="-out-file" />
  </target>

  <target name="-out-file" >
    <echo message="输出文件到指定路径" />
    <!-- 复制构建文件到共享目录 -->
    <property name="share.file.path" value="/Volumes/ShareFiles/Jenkins/IOS/${project.scheme.name}/${build.file.path}/" />
    <copy file="${basedir}/${build.archive.path}.ipa" todir="${share.file.path}" />
  </target>

  <target name="-build-report" >
    <!-- 构建报告 -->
    <echo message="构建报告" />
    <exec executable="date" outputproperty="build.report.time" failifexecutionfails="false" errorproperty="DateError">
      <arg value="+%Y年%m月%d日%H:%M" />
    </exec>
    <checksum file="${basedir}/${build.archive.path}.ipa" property="build.file.md5" />
    <length file="${basedir}/${build.archive.path}.ipa" property="build.file.size" />
    <echo message="Build Complete: ${ant.project.name} [${build.config.name}]" encoding="UTF-8"></echo>
    <echo message="Tag: ${cvs.tag} Commit:${cvs.commit}" encoding="UTF-8" />
    <echo message="Lastest Commit Log:${line.separator}${cvs.log}" encoding="UTF-8" />
    <echo message="File Name: ${build.file.name}.ipa" encoding="UTF-8" />
    <echo message="File Size: ${build.file.size}bytes" encoding="UTF-8" />
    <echo message="File MD5 : ${build.file.md5}" encoding="UTF-8" />
  </target>
  
  <target name="-bugly" depends="-bugly-config, bugly" >
    <echo message="上传到 bugly 平台" />
    <property name="build.file.url" value="https://${bugly.url}" />
    <property name="build.file.qrcode" value="http://qr.liantu.com/api.php?text=${build.file.url}" />
  </target>
  
  <target name="-bugly-config" />
    <property name="bugly.app_id" value="bugly_app_id" />
    <property name="bugly.app_key" value="bugly_app_key" />
    <property name="bugly.upload.file" value="${basedir}/${build.archive.path}.ipa" />
    <property name="bugly.pid" value="2" />
    <property name="bugly.title" value="${ant.project.name} - IOS [${build.config.name}] Tag:${cvs.tag} Commit:${cvs.commit}" />
    <property name="bugly.description" value="${build.type}${line.separator}${cvs.log}" />
  </target>
  
  <target name="send-wechat" depends="-wechat-config, wechat" >
    <echo message="发送微信mpnews信息" />
  </target>
  
  <target name="-wechat-config" >
    <property name="build.file.url" value="http://download.jenkins.51djt.com/IOS/${project.scheme.name}/${build.file.path}/${build.file.name}.ipa" />
    <property name="build.file.qrcode" value="http://qr.liantu.com/api.php?text=${build.file.url}" />
    
    <property name="wechat.partyid" value="2" />
    <property name="wechat.agentid" value="12" />
    <property name="wechat.userid" value="tomczhen" />
    <property name="mpnews.author" value="Jenkins" />
    <property name="mpnews.media_id" value="wechat_media_id" />
    <property name="mpnews.title" value="Jenkins 构建通知" />
    <property name="mpnews.digest" value="构建完成${line.separator}${ant.project.name}-IOS [${build.config.name}]${line.separator}Tag:${cvs.tag} Commit:${cvs.commit}" />
        
    <property name="mpnews.content" value="&lt;p&gt;构建完成&lt;br/&gt;${ant.project.name}-IOS [${build.config.name}]&lt;br/&gt;${build.report.time}&lt;br/&gt;文件名称&lt;br/&gt;${build.file.name}&lt;br/&gt;Tag:${cvs.tag} Commit:${cvs.commit}&lt;br/&gt;更新说明&lt;br/&gt;${build.type}&lt;br/&gt;${cvs.log}&lt;br/&gt;下载地址&lt;br/&gt;&lt;a href=\&quot;${build.file.url}\&quot; src=\&quot;${build.file.url}\&quot;&gt;${build.file.url}&lt;/a&gt;&lt;br/&gt;&lt;img src=\&quot;${build.file.qrcode}\&quot;/&gt;&lt;/p&gt;" />
  </target>
</project>

```

<h3 id="config">config/beta.config.properties</h3>

```
# 说明
# 非英文数字字符必须转换编码后才能读取正常 Natvie->ASCII
# http://tool.oschina.net/encode?type=3 

# API URL
api.url=http://api.yourweb.com

# RongCloud
rongcloud.key=rong_cloud_key
rongcloud.scid=rong_cloud_scid
rongcloud.secret=rong_cloud_secret

# JPush
jpush.key=jpush_key
jpush.secret=jpush_secret
```
