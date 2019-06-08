---
title: iOS 应用构建 Shell 脚本
date: 2015-12-08 19:25:51
tags: [iOS]
---

只是一个 ios 应用构建 Shell 脚本。

<!--more-->

## CocoaPods

1. 更新 Ruby

    `gem update --system`

1. 修改 Ruby 安装源
    ```
    gem sources --remove https://rubygems.org/
    gem sources -a https://ruby.taobao.org/
    ```
    注:使用`gem sources -l`命令查看源列表

1. 安装 cocoapods

    `sudo gem install cocoapods`

## xctool

1. 安装 brew

    `ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`

1. 安装 Xcode's Command Line Tools

    `xcode-select install`

1. 使用 brew 安装 xctool

    `brew install xctool`

## 使用说明

* 运行脚本前需要在 xcode 中配置好证书及描述文件。
* 如果不需要修改代码请注释掉相关 sed 语句。
* 默认使用 xctool 进行构建，需要先安装好 xctool。
* 使用 xcodebuild 构建需要注释 xctool 相关语句，并取消 xcodebuild 相关语句的注释。
* 在项目目录创建脚本文件，例如: iosbuild.sh （与 .xcworkspace 文件同级目录），使用命令 `chmod 777 iosbuild.sh` 为脚本文件增加可执行权限，执行脚本会根据配置在 `EXPORT_PATH` 中生成 ipa 文件。

### 脚本代码

{{< gist TomCzHen 0f95e8d3a661d1a4a3247650fea2ad0e >}}
