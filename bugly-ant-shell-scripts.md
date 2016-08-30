title: 上传安装包到 Bugly 发布平台脚本
date: 2016-07-17 20:45:00
categories: 
  - ant
  - shell
feature: /images/logo/bugly-logo.webp
tags: 
  - ant
  - shell
  - bugly
toc: true
---

<h2 id="readme">注意事项</h2>

**由于使用了 curl 命令，因此在 windows 平台运行脚本需要先安装 curl 才能执行。**

<!-- more -->

---

<h2 id="shell">Shell 脚本</h2>

<h3 id="shell_code">脚本代码</h3>

```shell
#!/bin/sh
# -*- coding: UTF-8 -*-

set -e

function echo_green()
 {
    echo "\033[32m $1 \033[0m"
 }

function echo_red() 
 {
    echo "\033[31m $1 \033[0m"
 }

function echo_blue()
 {
    echo "\033[36m $1 \033[0m" 
 }
 
function get_ios_project_version()
{
    local info_plist_path=$1
    local version=$(/usr/libexec/PlistBuddy -c "print CFBundleVersionString" ${info_plist_path})
    local build=$(/usr/libexec/PlistBuddy -c "print CFBundleVersion" ${info_plist_path})
    echo "${versoin}-${build}"
    
    return 0;
}
 
function get_json_value()
{
    local json=$1
    local key=$2
    local num=1
    
    local value=$(echo "${json}" | awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'${key}'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p)
    
    echo ${value}
    
    return 0;
}

function bugly_upload()
{
    local app_key="bugly_app_key"
    local app_id="bugly_app_id"
    local url=https://api.bugly.qq.com/beta/apiv1/exp?app_key=${app_key}

    local pid="1"
    local title="Bugly Upload Shell Script Example"
    local description="Bugly Upload Shell Script Example"
    local secret="1"
    local password=""
    local users=""
    local download_limit="1000"
    
    local response=$(curl --insecure -F "file=@$1" -F "app_id=${app_id}" -F "pid=${pid}" -F "title=${title}" -F "description=${description}" -F "secret=${secret}" -F "password=${password}" -F "users=${users}" -F "download_limit=${download_limit}" ${url})

    echo ${response}

    return 0;   
}
 
function parse_bugly_response()
{
    local json=$1
    
    local code=$(get_json_value "${json}" "rtcode")
    local msg=$(get_json_value "${json}" "msg")
    
    if [[ "${code}" = "0" ]]; then
        bugly_download_url=$(echo $json | sed -e 's/^.*"url":"\([^"]*\)".*$/\1/')
        echo_blue "Upload Bugly Success"
        echo_blue "Bugly Download URL : ${bugly_download_url}"
    else
        echo_red "Upload Bugly Fail"
    fi

    return 0;
}


if [[ -f "$1" ]]; then

    echo_green "Start Bugly Upload"
    
    bugly_upload_json=$(bugly_upload $1)
    echo ${bugly_upload_json}
    
    echo_green "Bugly Request Success"
    echo_green "==========================================================="
    parse_bugly_response "${bugly_upload_json}"
    echo_green "==========================================================="
fi
```

<h3 id="shell_howto">使用说明</h3>

将需要发送的安装包路径作为参数传入即可，路径需要是绝对路径，注意根据平台修改 `pid` 的值。

```shell
./bugly.sh /home/user/myapp.ipa
```

可以根据需要使用 `get_ios_project_version` 函数获取项目的版本号与 build 号。

<h2 id="ant">Ant 脚本</h2>

<h3 id="ant_code">脚本代码</h3>

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project name="Bugly" default="bugly">

  <target name="bugly" depends="-bugly-default-config,-bugly-report" >
    <echo message="Upload File To Bugly" />
  </target>

  <target name="-bugly-default-config">
    <echo message="Bugly Default Config" />
    <property name="bugly.secret" value="1"/>
    <property name="bugly.password" value="" />
    <property name="bugly.download_limit" value="1000" />
  </target>
	
  <target name="-bugly-upload" >
    <echo message="Start Upload" />
    <exec executable="curl" outputproperty="bugly.json" failifexecutionfails="true">
      <arg value="-s" />
      <arg value="-F" />
      <arg value="file=@${bugly.upload.file}" />
      <arg value="-F" />
      <arg value="app_id=${bugly.app_id}" />
      <arg value="-F" />
      <arg value="pid=${bugly.pid}" />
      <arg value="-F" />
      <arg value="title=${bugly.title}" />
      <arg value="-F" />
      <arg value="description=${bugly.description}" />
      <arg value="-F" />
      <arg value="secret=${bugly.secret}" />
      <arg value="-F" />
      <arg value="password=${bugly.password}" />
      <arg value="-F" />
      <arg value="users=${bugly.users}" />
      <arg value="-F" />
      <arg value="download_limit=${bugly.download_limit}" />
      <arg value="https://api.bugly.qq.com/beta/apiv1/exp?app_key=${bugly.app_key}"/>
    </exec>
  </target>

  <target name="-check-bugly-json" depends="-bugly-upload">
    <echo message="Check Return Response" />
    <condition property="isUploadFail">
      <equals arg1="${bugly.json}" arg2="" />
    </condition>
  </target>
  
  <target name="-get-bugly-error-info" unless="isUploadFail" depends="-check-bugly-json">
    <echo message="Get Return Response Info" />

    <script language="javascript">
      var jsonString = project.getProperty("bugly.json");
      var json = eval ("(" + jsonString + ")");
      project.setProperty("bugly.json.rtcode",json.rtcode);
      project.setProperty("bugly.json.msg",json.msg);
    </script>

    <condition property="isUploadError">
      <not>
        <equals arg1="${bugly.json.rtcode}" arg2="0" />
      </not>
    </condition>
    <echo message="${bugly.json.rtcode}" />
    <echo message="${bugly.json.msg}" />
  </target>
  
  <target name="-get-bugly-url" unless="isUploadError" depends="-get-bugly-error-info">
    <echo message="Get Bugly Download Url" />

    <script language="javascript">
      var jsonString = project.getProperty("bugly.json");
      var json = eval ("(" + jsonString + ")");
      project.setProperty("bugly.url",json.data.url);
    </script>
    <property name="bugly.result.message" value="Upload Success" />
    <echo message="${bugly.url}" />
  </target>

  <target name="-bugly-report" depends="-get-bugly-url" >
    <echo message="Upload Report" />
    <exec executable="date" outputproperty="bugly.report.time" failifexecutionfails="false" errorproperty="DateError">
      <arg value="+%Y-%m-%d-%H:%M" />
    </exec>
    <property name="bugly.json.msg" value="Execution Curl Fail" />
    <property name="bugly.result.message" value="Upload Fail" />
    <property name="build.report.bugly" value="${bugly.result.message}${line.separator}Return Msg:${bugly.json.msg}${line.separator}Retrun Code:${bugly.json.rtcode}" />
    
    <echo message="${build.report.bugly}" />
  </target>

</project>
```

<h3 id="ant_howto">使用说明</h3>

* `bugly_url` `app_id` `app_key` 根据实际情况填写。
* 需要回传获取到是否发送成功的状态，所以调用时需要注意方式。
* 可以通过`ant -buildfile bugly.xml -Dbugly.upload.file=file_path`的方式调用。

```xml
  <target name="-bugly" depends="-bugly-config, bugly" >
    <echo message="Upload To Bugly" />
    <property name="build.file.url" value="https://${bugly.url}" />
  </target>
  
  <target name="-bugly-config" />
    <property name="bugly.app_id" value="bugly_app_id" />
    <property name="bugly.app_key" value="bugly_app_key" />
    <property name="bugly.upload.file" value="upload_file_path" />
    <property name="bugly.pid" value="2" />
    <property name="bugly.title" value="${ant.project.name} - IOS [${build.config.name}] Tag:${cvs.tag} Commit:${cvs.commit}" />
    <property name="bugly.description" value="${build.type}${line.separator}${cvs.log}" />
  </target>
```
---

<div align="center">
![](/images/logo/alipay_tomczhen.webp)  
如果对您有帮助的话，可以考虑通过支付宝请作者喝杯咖啡。
</div>
