title: 一个简单的 iOS 自动生成 ipa 文件脚本
date: 2015-12-08 19:25:51
categories:
  - ci
feature: /images/logo/bash-logo.webp
tags:
  - ios
  - xctool
toc: true
---
<h2 id="cocoapods">安装CocoaPods</h2>

<h3 id="ruby-update">更新Ruby</h3>

`gem update --system`

<h3 id="ruby-change">修改Ruby安装源</h3>

```
gem sources --remove https://rubygems.org/
gem sources -a https://ruby.taobao.org/
```
注:使用`gem sources -l`命令查看源列表

<h3 id="cocoapods-install">安装cocoapods</h3>

`sudo gem install cocoapods`

<h2 id="xctool-install">xctool</h2>

<h3 id="brew-install">安装 brew</h3>

`ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`

<h3 id="xcode-install">安装 Xcode's Command Line Tools</h3>

`xcode-select install`

<h3 id="brew-xctool-install">使用 brew 安装 xctool</h3>

`brew install xctool`

<h2 id="readme">使用说明</h2>

* 运行脚本前需要在 xcode 中配置好证书及描述文件。
* 如果不需要修改代码请注释掉相关 sed 语句。
* 默认使用 xctool 进行构建，需要先安装好 xctool。
* 使用 xcodebuild 构建需要注释 xctool 相关语句，并取消 xcodebuild 相关语句的注释。
* 在项目目录创建脚本文件，例如: iosbuild.sh （与 .xcworkspace 文件同级目录），使用命令 `chmod 777 iosbuild.sh` 为脚本文件增加可执行权限，执行脚本会根据配置在 `EXPORT_PATH` 中生成 ipa 文件。

<!-- more -->

<h2 id="code">脚本代码</h2>

```shell
#!/bin/sh
# -*- coding: UTF-8 -*-

set -e

function modify_api_config()
{
  api_server_url='"http:\/\/api.yourweb.com"'
  code_file_path="${project_path}\code.h"
  sed -i "" "/^\/\//!s/.* APIServerUrl.*/NSString * const APIServerUrl= @${api_server_url};/" "${code_file_path}"
}

function build_xcode_project()
{
    local project_name=""
    local project_workspace_name=""
    local project_scheme_name=""
    local profile_name=""
    local build_timestamp=$(date +%Y%m%d%H%M)
    
    local project_path=""
    local archive_path="${project_path}"/build/${project_name}_r${build_timestamp}
    local export_file_path="${archive_path}".ipa
    
    cd "${project_path}"
    
    #xcodebuild -workspace ${project_workspace_name}.xcworkspace -scheme ${project_scheme_name} clean
    xctool -workspace ${project_workspace_name}.xcworkspace -scheme ${project_scheme_name} clean
    
    #xcodebuild -workspace ${project_workspace_name}.xcworkspace -scheme ${project_scheme_name} build archive -archivePath ${archive_path}
    xctool -workspace ${project_workspace_name}.xcworkspace -scheme ${project_scheme_name} build archive -archivePath ${archive_path}
    
    xcodebuild -exportArchive -archivePath ${archive_path}.xcarchive -exportPath ${export_file_path} -exportFormat ipa -exportProvisioningProfile ${profile_name}
    
    echo ${export_file_path}
    
    return 0
}

if [[ -z "$1" ]]; then
    
    modify_api_config
    build_xcode_project
fi
```

---

<div align="center">
![](/images/logo/alipay_tomczhen.webp)  
如果对您有帮助的话，可以考虑通过支付宝请作者喝杯咖啡。
</div>
