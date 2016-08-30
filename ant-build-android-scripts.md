title: ANT构建Android项目脚本
date: 2016-01-11 17:45:00
categories: 
  - ci
  - jenkins
feature: http://www.tomczhen.com/images/logo/apache-ant-logo.webp
tags: 
  - ant
  - android
toc: true
---

公司 Android 项目正在使用的 Ant 打包脚本,调用的 JDT 进行打包,去掉了敏感信息.

<!-- more -->

<h2 id="readme">注意事项</h2>

* 关于jenkins中输出乱码的问题参考[Jenkins实现持续集成——部署Jenkins](http://www.tomczhen.com/ci/continuous-integration-on-jenkins-howto-deploy/)

---
<h2 id="target">Target说明</h2>

* `devPack`
使用开发环境相关配置信息进行构建
    * `-dev-config`
    开发环境相关配置信息

* `betaPack`
使用测试环境相关配置信息进行构建
    * `-beta-config`
    测试环境相关配置信息

* `releasePack`
使用正式环境相关配置信息进行构建
    * `-release-config`
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
编译android

* `-out-file`
输出文件到指定路径

* `-build-report`
生成构建报告信息

* `send-wechat`
使用微信企业号API发送构建通知
    * `-wechat-config`
    微信相关配置信息
    
* `-bugly`
上传到 Bugly 平台
    * `-bugly_config`
    Bugly 相关配置信息

---

<h2 id="howto">使用说明</h2>

* target `-out-file` 需要根据需要修改路径
* target `wechat` 需要在执行脚本时手动指定，例如 `ant -buildfile android.build.xml devPack send-wechat`
* 由于公司要求，所有生成的 apk 文件都是都进行正式签名。

<h2 id="code">脚本代码</h2>

<h3 id="android">build.android.xml</h3>

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project name="DJT" default="devPack" basedir="../DJT" >

  <!-- 检查系统变量 ANDROID_HOME -->
  <property environment="env" />
  <condition property="sdk.dir" value="${env.ANDROID_HOME}">
    <isset property="env.ANDROID_HOME" />
  </condition>
	
  <echo message="${env.ANDROID_HOME}"></echo>
  <fail message="请配置系统变量ANDROID_HOME之后重试!" unless="sdk.dir" />
    
  <!-- APK签名信息 -->
  <property name="key.store" value="../ant-script/config/sign/djt.keystore" />
  <property name="key.store.password" value="123456" />
  <property name="key.alias" value="key_alias" />
  <property name="key.alias.password" value="123456" />

  <!-- 编译参数设置 -->
  <exec executable="date" outputproperty="build.time" failifexecutionfails="false" errorproperty="DateError">
    <arg value="+%Y%m%d%H%M" />
  </exec>
  <property name="build.compiler" value="org.eclipse.jdt.core.JDTCompilerAdapter"/>
  <property name="java.target" value="1.7" />
  <property name="java.source" value="1.7" />

  <!-- 项目配置信息-->
    
  <property name="manifest.file" value="AndroidManifest.xml" />
  <property name="application-package" value="com.djt.djt" />
  <property name="external-libs-folder" value="libs" />
  <property name="out.dir" value="dist/build" />
  <property name="gen.absolute.dir" value="dist/build/gen" />
  <xmlproperty file="${manifest.file}" prefix="themanifest" collapseAttributes="true" />
  <property name="log.level" value="NO" />
  <property name="app.version" value="${themanifest.manifest.android:versionName}" />  

  <loadproperties srcFile="project.properties" />
  <import file="${sdk.dir}/tools/ant/build.xml" />
  <import file="../ant-script/plug/WeChat.xml" />
  <import file="../ant-script/plug/Bugly.xml" />
  
  <target name="devPack" depends="-dev-config, -pack, -build-report,-bugly">
  </target>

  <target name="betaPack" depends="-beta-config, -pack, -build-report">
  </target>

  <target name="releasePack" depends="-release-config, -pack,-build-report">
  </target>

  <target name="-get-cvs-info" >
    <echo message="读取CVS信息" />
    <!-- 获取CVS信息  -->
    <exec executable="git" outputproperty="cvs.tag" failifexecutionfails="false" errorproperty="GitTagError">
      <arg value="describe" />
      <arg value="--tags" />
    </exec>
    <exec executable="git" outputproperty="cvs.commit" failifexecutionfails="false" errorproperty="GitCommitError">
      <arg value="log" />
      <arg value="--pretty=format:%h" />
      <arg value="-n1" />
    </exec>
    <exec executable="git" outputproperty="cvs.log" failifexecutionfails="false" errorproperty="GitLogError">
      <arg value="log" />
      <arg value="--pretty=format:%B" />
      <arg value="-n1" />
    </exec>
  </target>
  
  <target name="test" depends="-get-cvs-info" >
    <echo message="加载内网开发环境配置信息" />
    <loadproperties srcFile="../ant-script/config/dev.config.properties" />
    <!-- 构建内网测试包配置信息 -->
    <property name="app.name" value="-Dev" />
    <property name="build.type" value="LAN-Beta" />
    <property name="build.config.name" value="连接内网开发环境" />
    <antcall target="-modify" />
    
  </target>
  
  <target name="-dev-config" depends="-get-cvs-info">
    <echo message="加载内网开发环境配置信息" />
    <loadproperties srcFile="../ant-script/config/dev.config.properties" />
    <!-- 构建内网测试包配置信息 -->
    <property name="app.name" value="-Dev" />
    <property name="build.type" value="Dev" />
    <property name="build.config.name" value="连接内网开发环境" />
    <property name="build.file.path" value="${app.version}/dev" />
    <property name="build.file.name" value="${ant.project.name}_${cvs.tag}_beta_${build.time}.apk" />

	</target>

  <target name="-beta-config" depends="-get-cvs-info">
    <echo message="加载外网测试环境配置信息" />
    <loadproperties srcFile="../ant-script/config/beta.config.properties" />
    <!-- 构建外网测试包配置信息 -->
    <property name="app.name" value="-Beta" />
    <property name="build.type" value="Beta" />
    <property name="build.config.name" value="连接外网测试环境" />
    <property name="build.file.path" value="${app.version}/beta" />
    <property name="build.file.name" value="${ant.project.name}_${cvs.tag}_beta_${build.time}.apk" />

  </target>
	
  <target name="-release-config" depends="-get-cvs-info">
    <echo message="加载外网正式环境配置信息" />
    <loadproperties srcFile="../ant-script/config/release.config.properties" />
    <!-- 构造正式包配置信息 -->
    <property name="app.name" value="" />
    <property name="build.type" value="Release" />
    <property name="build.config.name" value="连接外网正式环境" />
    <property name="build.file.path" value="${app.version}/release" />
    <property name="build.file.name" value="${ant.project.name}_${cvs.tag}_r${build.time}.apk" />

    <!-- 关闭开发人员自定义Log输出 -->
    <replaceregexp byline="true" encoding="UTF-8">
      <regexp pattern='(public\s+static\s+boolean\s+open\s+=\s)+(.*)' />
      <substitution expression='\1false;' />
      <fileset dir="src\com\djt\djt\utils" includes="LogUtil.java" />
    </replaceregexp>
  </target>

  <target name="-modify" depends="-modify-appname">
    <echo message="修改代码中的相关配置字段"/>

    <!-- 配置第三方 Key -->
    <!-- 融云 Key -->
    <replaceregexp flags="g" byline="false" encoding="UTF-8">
      <regexp pattern='(android:name="RONG_CLOUD_APP_KEY"\s+android:value=")(.*)(")' />
        <substitution expression="\1${rongcloud.key}\3" />
        <fileset dir="" includes="AndroidManifest.xml" />
      </replaceregexp>
    
    <!-- JPush Key -->
    <replaceregexp flags="g" byline="false" encoding="UTF-8">
      <regexp pattern="(android:name=&quot;JPUSH_APPKEY&quot;\s+android:value=&quot;)(.*)(&quot;)" />
      <substitution expression="\1${jpush.key}\3" />
      <fileset dir="" includes="AndroidManifest.xml" />
    </replaceregexp>

    <!-- 融云客服 ID -->
    <replaceregexp byline="false" encoding="UTF-8">
      <regexp pattern='public\s+static\s+final\s+String\s+customerServiceId\s+=\s+"(.*)"' />
      <substitution expression='public static final String customerServiceId = "${rongcloud.scid}"' />
      <fileset dir="src\com\djt\djt\app" includes="CommonContent.java" />
    </replaceregexp>

    <property name="out.final.file" location="${out.absolute.dir}/${build.file.name}" />

  </target>

  <target name="-pack" depends="-modify, clean, release">
    <echo message="进行构建" />
    <antcall target="-out-file" />
  </target>
	
  <target name="-out-file" >
    <!-- 复制构建文件到共享目录 -->
    <echo message="输出文件到指定路径" />
    <copy file="${out.final.file}" todir="/Users/MacPro/Jenkins/Android/DJT/${build.file.path}/" />
  </target>

  <target name="-check-isNeedModifyAppName" >
    <echo message="检查是否需要修改构建的App Name" />
    <condition property="isNeedModifyAppName">
      <not>
        <equals arg1="${build.type}" arg2="Release" />
      </not>
    </condition>
  </target>
	
  <target name="-modify-appname" if="isNeedModifyAppName" depends="-check-isNeedModifyAppName">
    <!-- 配置 App 名称 -->
    <echo message="修改构建的App Name" />
    <replaceregexp flags="g" byline="false" encoding="UTF-8">
      <regexp pattern="(&quot;app_name&quot;&gt;)(.*)(&lt;)" />
      <substitution expression="\1\2${app.name}\3" />
      <fileset dir="" includes="res/values/strings.xml" />
    </replaceregexp>
  </target>
	
  <target name="-build-report" >
    <!-- 构建报告 -->
    <echo message="构建报告" />
    <exec executable="date" outputproperty="build.report.time" failifexecutionfails="false" errorproperty="DateError">
      <arg value="+%Y年%m月%d日%H:%M" />
    </exec>
    <checksum file="${out.final.file}" property="build.file.md5" />
    <length file="${out.final.file}" property="build.file.size" />
    <echo message="Build Complete: ${ant.project.name} [${build.config.name}]" encoding="UTF-8"></echo>
    <echo message="Tag: ${cvs.tag} Commit:${cvs.commit}" encoding="UTF-8" />
    <echo message="Lastest Commit Log:${line.separator}${cvs.log}" encoding="UTF-8" />
    <echo message="File Name: ${build.file.name}" encoding="UTF-8" />
    <echo message="File Size: ${build.file.size}bytes" encoding="UTF-8" />
    <echo message="File MD5 : ${build.file.md5}" encoding="UTF-8" />
  </target>
  
  <target name="-bugly" depends="-bugly-config, bugly" >
    <echo message="上传到 bugly 平台" />
    <property name="build.file.url" value="https://${bugly.url}" />
    <property name="build.file.qrcode" value="http://qr.liantu.com/api.php?text=${build.file.url}" />
  </target>
  
  <target name="-bugly-config" >
    <property name="bugly.app_id" value="bugly_app_id" />
    <property name="bugly.app_key" value="bugly_app_key" />
    <property name="bugly.upload.file" value="${out.final.file}" />
    <property name="bugly.pid" value="1" />
    <property name="bugly.title" value="${ant.project.name} - Android [${build.config.name}] Tag:${cvs.tag} Commit:${cvs.commit}" />
    <property name="bugly.description" value="${build.type}${line.separator}${cvs.log}" />
  </target>

  <target name="send-wechat" depends="-wechat-config, wechat" >
    <echo message="发送微信mpnews信息" />
  </target>
  
  <target name="-wechat-config" >
    <property name="build.file.url" value="http://download.jenkins.51djt.com/Android/DJT/${build.file.path}/${build.file.name}" />
    <property name="build.file.qrcode" value="http://qr.liantu.com/api.php?text=${build.file.url}" />
    
    <property name="wechat.partyid" value="2" />
    <property name="wechat.agentid" value="12" />
    <property name="wechat.userid" value="tomczhen" />
    <property name="mpnews.author" value="Jenkins" />
    <property name="mpnews.media_id" value="wechat_media_id" />
    <property name="mpnews.title" value="Jenkins 构建通知" />
    <property name="mpnews.digest" value="构建完成${line.separator}${ant.project.name}-Android [${build.config.name}]${line.separator}Tag:${cvs.tag} Commit:${cvs.commit}" />
        
    <property name="mpnews.content" value="&lt;p&gt;构建完成&lt;br/&gt;${ant.project.name}-Android [${build.config.name}]&lt;br/&gt;${build.report.time}&lt;br/&gt;文件名称&lt;br/&gt;${build.file.name}&lt;br/&gt;Tag:${cvs.tag} Commit:${cvs.commit}&lt;br/&gt;更新说明&lt;br/&gt;${build.type}&lt;br/&gt;${cvs.log}&lt;br/&gt;下载地址&lt;br/&gt;&lt;a href=\&quot;${build.file.url}\&quot; src=\&quot;${build.file.url}\&quot;&gt;${build.file.url}&lt;/a&gt;&lt;br/&gt;&lt;img src=\&quot;${build.file.qrcode}\&quot;/&gt;&lt;/p&gt;" />
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

<h3 id="wechat">相关脚本链接</h3>

---
<div align="center">
![](http://pic.tomczhen.com/alipay_QR.png)  
如果对您有帮助的话，可以考虑通过支付宝请作者喝杯咖啡。
</div>
