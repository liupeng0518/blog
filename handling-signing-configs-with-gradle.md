title: 用 Gradle 处理 Android 签名配置
date: 2017-03-24 22:10:00
categories:
  - ci
feature: /images/logo/jenkins-logo.webp
tags:
  - Gradle
  - Android
  - Jenkins
toc: true
---

公司 Android 项目终于由 Eclipse 迁移到 Android Studio 上了，需要将之前在 Jenkins 上的构建任务修改一下支持 gradle 构建。
出于信息安全需要，开发人员不掌握生产环境使用的签名证书，但是 Jenkins 构建时需要自动的使用生产签名证书进行打包签名。

之前是用 ant 的正则替换对应的代码或配置文件实现的，这次使用 gradle 来实现。

<!-- more -->

##### 保护签名证书私钥

> 参考: https://developer.android.com/studio/publish/app-signing.html#secure-key

1. 在项目中创建 `keystore.properties`，内容包含签名使用的配置信息，例如：

```
store=store_file_location
store_pwd=pwd
alias=alias_name
alias_pwd=alias_pwd
```
需要注意的是，`keystore.properties` 和使用的 store 文件不要添加到版本控制系统中。

1. 在模块的 build.gradle 文件中，于 android {} 的 signingConfigs {} 中添加用于加载 keystore.properties 文件的代码。

```
signingConfigs {
  release {
    v2SigningEnabled false
    try {
      def Properties keyProps = new Properties()
      keyProps.load(new FileInputStream(file('keystore.properties')))
      storeFile file(keyProps["store"])
      storePassword keyProps["store_pwd"]
      keyAlias keyProps["alias"]
      keyPassword keyProps["alias_pwd"]
    } catch (Exception ex) {
      println(ex)
    }
  }
}
```

1. 在模块的 build.gradle 文件中，于 android {} 的 buildTypes {} 中添加用指定使用的签名配置

```
buildTypes {
  release {
    buildConfigField "boolean", "LOG_DEBUG", "false"
    minifyEnabled false
    proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.txt'
    debuggable false
    # 加载 signingConfigs.release 签名配置
    signingConfig signingConfigs.release
  }

  debug{
    buildConfigField "boolean", "LOG_DEBUG", "true"
  }
}
```

##### 在 Jenkins 中使用

> 参考: https://developer.android.com/studio/build/index.html

需要在 Jenkins 中安装 Gradle 插件以支持 Gradle 构建。了解 Gradle 的构建流程之后，可以知道 IDE 中的打包操作可以等价转换为 CLI 命令。

在构建步骤中选择 `Invoke Gradle script`,在 `Tasks` 中输入，以下参数：

```
clean
assembleRelease
```

配置完成之后该 Jenkins 构建项目只会构建正式签名的 Android 包。

##### 其他

如果你只想解决自动签名的问题，那么可以按官方文档上的做法，将加载配置放在模块的 build.gradle 文件中, android {} 块的前面加载。

```
...
def keystorePropertiesFile = rootProject.file("keystore.properties")

def keyProps = new Properties()

keyProps.load(new FileInputStream(keystorePropertiesFile))

android {
    ...
}
```

同样需要在 signingConfigs 块中使用加载好的配置信息

```
android {
    signingConfigs {
        config {
            storeFile file(keyProps["store"])
            storePassword keyProps["store_pwd"]
            keyAlias keyProps["alias"]
            keyPassword keyProps["alias_pwd"]
        }
    }
    ...
  }
```

在 Build Variants 工具窗口中确定已选择发布构建类型。

然后点击 Build > Build APK 以构建您的发布构建，并确认 Android Studio 已在模块的 build/outputs/apk/ 目录中创建一个签署的 APK。


