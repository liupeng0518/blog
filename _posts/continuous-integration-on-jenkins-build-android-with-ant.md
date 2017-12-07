title: 持续集成——在 Jenkins 上使用 Ant 脚本构建 Android 应用
date: 2015-12-08 19:25:51
categories: 
  - CI
feature: /images/logo/jenkins-logo.webp
tags: 
  - Jenkins
  - Ant
  - Android
  - JDT
toc: true
---

随着 Android Stuido 的普及，现在 Gradle 已经是主流了，不过公司项目仍然使用 Eclipse，所以得继续使用 Ant 来进行构建。

<!-- more -->

<h2 id = "install-apache-ant">安装 Apache Ant</h2>

[Apache Ant Download](http://ant.apache.org/bindownload.cgi)

1.	下载 Apache Ant 程序包解压。
1.	配置系统环境变量`ANT_HOME`，值为 Ant 解压路径，例如: `X:\apache-ant`
1.	添加 Ant 目录下的 bin 目录到环境变量 Path 中，例如: `X:\apache-ant\bin` .在命令行中输入 `ant -version` 命令，如果返回 Ant 版本信息表示 Ant 安装成功。
1.	在 Jenkins 的系统管理-管理插件中安装好 `Ant Plugin`
1.	在 Jenkins 的系统设置中设置 Ant 参数，在 `ANT_HOME` 中输入系统环境变量 `ANT_HOME` 中一样的值。

<h2 id = "eclipse-ant-plugin">为Eclipse安装ant插件</h2>

　　由于 Eclipse 的 Ant 插件中的 Ant 版本过低，需要将最近的 Ant 包中的文件覆盖 Ant 插件目录，升级 Ant 插件到最新版本。

<h2 id = "create-buildxml">生成 build.xml</h2>

<h3 id = "config-android-env">配置运行环境</h3>

　　可以添加 Android SDK 中的 tools 目录到环境变量 `Path` 中，如果已经添加好 `ANDROID_HOME` 环境变量，可以直接添加 `%ANDROID_HOME%\tools` 到PATH中。

　　在命令行界面中输入 `android -h` 如果可以看到输出的 `android` 命令帮助信息表示配置完成。

<h3 id = "create-buildxml-project">在项目中生成 build.xml</h3>

　　使用 `android update project -p projectpath -t <target>` 命令在指定项目目录中生成 build.xml ，外部项目则需要再次执行该命令，会自动检测依赖。
`android list targets` 命令可以显示当前安装的 android sdk 版本,可以使用 id 或者 `android-23` 做为 `targets` 参数.

　　除了 `build.xml` 外还会生成 `local.properties` 文件，保存的是项目 `sdk-dir` 的路径，因为是本地环境相关路径，所以该文件应排除在版本控制之外。
如果在 Eclipse 中已经安装了 Ant 插件，可以在 Eclipse 中右击 build.xml 文件选择 `Run As-->Ant Build` 来使用 Ant 编译运行，也可以通过在命令行中输入 `ant build.xml` 来进行编译。

<h3 id="build-with-jdt">使用 JDT 进行编译</h3>

　　由于 Eclipse 默认使用 JDT 编译，因此即便没有安装 JDK 其实仍然是可以编译项目的，但由于 JDT 与 JDK 的差异，会出现 Eclipse 下编译可以通过但使用 Ant 编译则无法通过的情况。这种情况可以在 Ant 的编译配置文件中指定使用 JDT 编译来解决。

　　复制 Eclipse 安装目录的 plugins 文件夹中 `org.eclipse.jdt.core_xxxxxx.jar` 文件到环境变量 ANT_HOME 中的 lib 文件夹，并且从此文件中解压出 `jdtCompilerAdapter.jar` 到同级目录。
如果是在Eclipse中使用Run As Ant的话还需要修改Runtime JRE配置，勾选`Run in the same JRE as the workspace`

　　通过在 build.xml 中添加 `<property name="build.compiler" value="org.eclipse.jdt.core.JDTCompilerAdapter"/>` 可以指定使用 JDT 编译，同时需要注意，需要指定 java 编译版本 `<property name="java.target" value="1.7" />` `<property name="java.source" value="1.7" />`

<h3 id="config-buildxml">自定义 build.xml 脚本</h3>

　　通过复制 build.xml 可以得到最基础的 Ant 编译脚本，可以将 build.xml的 拷贝根据需要重命名，例如: build-release.xml

　　参考Ant任务的[官方手册](https://ant.apache.org/manual/tasksoverview.html)，可以查看可用的任务或命令以及具体的参数，实例。

<h2 id="create-jenkins-job">添加 Jenkins 任务</h2>

　　新建任务类型"构建一个自由风格的软件项目"，选择源代码管理的方式。在"增加构建步骤"中选择 `Invoke Ant` ,打开高级选项，配置好 Targets ，在 Build File 中输入配置好的 build.xml 文件路径。

　　注意：可以在任务中只配置源代码管理，执行任务测试获取代码是否正常，然后在服务器上的命令行界面中使用 Ant 命令调用项目中的 build.xml 文件进行编译测试。

<h2 id="exmple">脚本实例</h2>

Link:[ANT构建Android项目脚本](/2016/01/11/ant-build-android-scripts/)

