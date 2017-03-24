title: 调用微信公众平台接口发送消息脚本
date: 2016-07-17 20:45:00
categories: 
  - ci
feature: /images/logo/wechat-logo.webp
tags: 
  - Ant
  - shell
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
 
function get_json_value()
{
    local json=$1
    local key=$2
    local num=1
    
    local value=$(echo "${json}" | awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'${key}'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p)
    
    echo ${value}
    
    return 0;
}

function wechat_gettoken_request()
{
    local id="wechat_crop_id"
    local secret="wechat_crop_secret"
    local url="https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=${id}&corpsecret=${secret}"
    local response=$(curl -s ${url})
    
    echo ${response}

    return 0; 
}

function parse_wechat_token_response()
{
    local json=$1
    local code=$(get_json_value "${json}" "errcode")
    local msg=$(get_json_value "${json}" "errmsg")
    
    if [[ "${err_code}" = "" ]]; then
        wechat_token=$(get_json_value "${json}" "access_token")
        echo_blue "Get Wechat Token Success"
    else
        echo_red "Get Wechat Token Fail"
    fi

    return 0;
}

function wechat_send_msg()
{
  local token=$1
  local content=$2
  local url="https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=${token}"
  
  local json='{"touser":"tomczhen","toparty":"","totag":"","msgtype":"text","agentid":"12","text":{"content":"'${content}'"},"safe":"0"}'
  
  local response=$(curl -l -H "Content-type: application/json" -X POST -d "${json}" ${url})
  
  echo ${response}
  
  return 0; 
}

function parse_wechat_msg_response()
{
    local json=$1
    local code=$(get_json_value "${json}" "errcode")
    local msg=$(get_json_value "${json}" "errmsg")
    
    if [[ "${code}" = "0" ]]; then
        echo_blue "Send Wechat Message Success"
    else
        echo_red "Send Wechat Message Fail"
    fi

    return 0;
}

echo_green "Start Send Wechat Message"
echo_green "==========================================================="
echo_green "Get Wechat Token"

wechat_token_json=$(wechat_gettoken_request)

echo ${wechat_token_json}

parse_wechat_token_response ${wechat_token_json}

echo_green "Send Wechat Message"

wechat_msg_json=$(wechat_send_msg "${wechat_token}" $1)

echo ${wechat_msg_json}

parse_wechat_msg_response ${wechat_msg_json}

echo_green "==========================================================="
```

<h3 id="shell_howto">使用说明</h3>

将需要发送的信息作为参数传入即可，脚本只是实现了普通的 text 型信息，如果使用其他类型，需要修改发送的请求内容。

```
./wechat.sh "test message"
```

<h2 id="ant">Ant 脚本</h2>

<h3 id="ant_code">脚本代码</h3>

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project name="WeChat" default="wechat">
  
  <target name="wechat" depends="-wechat-default-config, -wechat-get-token, -wechat-send-mpnews">
    <echo message="Send Wechat Message" />
  </target>

  <target name="-wechat-default-config">
    <echo message="Wechat Default Config" />
    <property name="corp.id" value="wechat_corp_id" />
    <property name="corp.secret" value="wechat_secret" />
    
    <property name="wechat.userid" value="wechat_user_id" />
    <property name="wechat.partyid" value="wechat_party_id" />
    <property name="wechat.agentid" value="wechat_agent_id" />
    
    <property name="mpnews.title" value="wechat_mpnews_title" />
    <property name="mpnews.media_id" value="wechat_media_id" />
    <property name="mpnews.content" value="wechat_mpnews_content" />
    <property name="mpnews.digest" value="wechat_mpnews_digest" />
    <property name="mpnews.author" value="wechat_mpnews_author" />
  </target>
	
  <target name="-wechat-get-token">
    <echo message="Get Wechat Token" />
    <exec executable="curl" outputproperty="corp.token.json" failifexecutionfails="false">
      <arg value="-s" />
      <arg value="https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=${corp.id}&amp;corpsecret=${corp.secret}"/>
    </exec>
    
    <script language="javascript">
      var jsonString = project.getProperty("corp.token.json");
      var json = eval ("(" + jsonString + ")");
      project.setProperty("corp.token",json.access_token);
    </script>
    
    <echo message="${corp.token.json}" />
  </target>
  
  <target name="-wechat-send-mpnews" >
    <echo message="Send Wechat Mpnews Message" />
    <property name="wechat.mpnews.json" value="{&quot;touser&quot;:&quot;${wechat.userid}&quot;,&quot;toparty&quot;:&quot;${wechat.partyid}&quot;,&quot;totag&quot;:&quot;&quot;,&quot;msgtype&quot;:&quot;mpnews&quot;,&quot;agentid&quot;:${wechat.agentid},&quot;mpnews&quot;:{&quot;articles&quot;:[{&quot;title&quot;:&quot;${mpnews.title}&quot;,&quot;thumb_media_id&quot;:&quot;${mpnews.media_id}&quot;,&quot;author&quot;:&quot;&quot;,&quot;content_source_url&quot;:&quot;&quot;,&quot;content&quot;:&quot;${mpnews.content}&quot;,&quot;digest&quot;:&quot;${mpnews.digest}&quot;,&quot;show_cover_pic&quot;:&quot;0&quot;}]},&quot;safe&quot;:&quot;0&quot;}" />

    <exec executable="curl" outputproperty="corp.message.json" failifexecutionfails="false">
      <arg value="-s" />
      <arg value="-l" />
      <arg value="-H" />
      <arg value="Content-type: application/json" />
      <arg value="-X" />
      <arg value="POST" />
      <arg value="-d" />
      <arg value="${wechat.mpnews.json}" />
      <arg value="https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=${corp.token}"/>
    </exec>
    
    <echo message="${corp.message.json}" />
  </target>

</project>
```

<h3 id="ant_howto">使用说明</h3>

* `partyid` `agentid` 需要在微信公众平台中存在，`media_id` 使用永久性素材比较方便。
* 需要回传获取到是否发送成功的状态，所以调用时需要注意方式。
* mpnews 支持 HTML 但是由于是通过 json 发送，需要注意字符转义。

```xml
  <target name="send-wechat" depends="-wechat-config, wechat" >
    <echo message="Send Wechat Mpnews Message" />
  </target>
  
  <target name="-wechat-config" >
    <property name="build.file.url" value="http://download.jenkins.51djt.com/Android/DJT/${build.file.path}/${build.file.name}" />
    <property name="build.file.qrcode" value="http://qr.liantu.com/api.php?text=${build.file.url}" />
    
    <property name="wechat.partyid" value="2" />
    <property name="wechat.agentid" value="12" />
    <property name="wechat.userid" value="" />
    <property name="mpnews.author" value="Tom CzHen" />
    <property name="mpnews.media_id" value="media_id" />
    <property name="mpnews.title" value="Mpnews Title" />
    <property name="mpnews.digest" value="构建完成${line.separator}${ant.project.name}-Android [${build.config.name}]${line.separator}Tag:${cvs.tag} Commit:${cvs.commit}" />
        
    <property name="mpnews.content" value="&lt;p&gt;构建完成&lt;br/&gt;${ant.project.name}-Android [${build.config.name}]&lt;br/&gt;${build.report.time}&lt;br/&gt;文件名称&lt;br/&gt;${build.file.name}&lt;br/&gt;Tag:${cvs.tag} Commit:${cvs.commit}&lt;br/&gt;更新说明&lt;br/&gt;${build.type}&lt;br/&gt;${cvs.log}&lt;br/&gt;下载地址&lt;br/&gt;&lt;a href=\&quot;${build.file.url}\&quot; src=\&quot;${build.file.url}\&quot;&gt;${build.file.url}&lt;/a&gt;&lt;br/&gt;&lt;img src=\&quot;${build.file.qrcode}\&quot;/&gt;&lt;/p&gt;" />
  </target>
```
