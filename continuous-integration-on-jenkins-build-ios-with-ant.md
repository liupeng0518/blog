title: Jenkins实现持续集成——使用Ant脚本构建ios项目
date: 2016-01-08 17:06:51
categories: 
  - ci
feature: /images/logo/jenkins-logo.webp
tags: 
  - jenkins
  - ant
  - ios
  - xctool
toc: true
---
<h2 id="cocoapods">CocoaPods</h2>

<h3 id="ruby-update">更新 Ruby</h3>

`gem update --system`

<h3 id="ruby-change">修改 Ruby 安装源</h3>

```
gem sources --remove https://rubygems.org/
gem sources -a https://ruby.taobao.org/
```
注:使用 `gem sources -l` 命令查看当前源列表

<h3 id="cocoapods-install">安装 cocoapods</h3>

`sudo gem install cocoapods`

<h2 id="xctool-install">xctool & ant</h2>

<h3 id="brew-install">安装 brew </h3>

`ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`

<h3 id="xcode-install">安装 Xcode's Command Line Tools</h3>

`xcode-select install`

<h3 id="brew-xctool-install">使用 brew 安装 xctool</h3>

`brew install xctool`

<h3 id="brew-ant-install">使用 brew 按照 ant</h3>

`brew install ant`

<h2 id = "config-jenkins-env">配置运行环境</h2>

在 Jenkins 的系统设置页面设置 ANT_HOME 路径，并在全局属性中添加键 `LANG` 值 `zh_CN.UTF-8` ,键 `PATH` 值 `系统PATH输出值`.

<h3 id = "create-build">编写 Ant 脚本</h3>

[官方手册](https://ant.apache.org/manual/tasksoverview.html)，可以查看可用的任务或命令以及具体的参数，实例。

<!-- more -->

<h2 id="create-jenkins-job">添加 Jenkins 任务</h2>

新建任务类型"构建一个自由风格的软件项目"，选择源代码管理的方式。在"增加构建步骤"中选择 `Invoke Ant` ,打开高级选项，配置好 Targets，在 Build File 中输入配置好的 build.xml 文件路径。

注意：可以在任务中只配置源代码管理，执行任务测试获取代码是否正常，然后在服务器上的命令行界面中使用 ant 命令调用项目中的 build.xml 文件进行编译测试。


<h2 id="exmple">脚本实例</h2>

Link:[ANT构建IOS项目脚本](/2016/01/11/ant-build-ios-scripts)
