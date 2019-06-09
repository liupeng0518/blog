---
title: 在 Jenkins 中构建 Eclipse 开发的 Android 项目
date: 2019-06-04T00:45:00+08:00
tags: [Jenkins,Android,Eclipse]
toc: true
---

本文只是对之前的资料进行一个整理与汇总，毕竟已经 9102 年了，大概已经没有不用 Android Studio 开发的 Android 项目了 :doge:。 

## 问题

Android Studio 与早期 Eclipse 所使用的构建脚本语言不同，Eclipse 是 Ant，Android Studio 则使用 Gradle，两者均是通过调用 Android SDK 进行编译构建。

但是很多时候 Eclipse 开发的 Android 项目代码在仅有 Android 编译环境中，通过 CLI 命令调用 Ant 脚本构建时却无法编译成功。

原因是 Eclipse 中默认使用 Java 编译器并非 Oracle JDK/OpenJDK 而是 Eclipse 的 [Eclipse Java development tools (JDT)](https://www.eclipse.org/jdt/) 中的 Eclipse Compiler for Java (ECJ)，正是编译器的差异造成了这些问题。

<!--more-->

###  Eclipse Compiler for Java

Eclipse Compiler for Java (ECJ) 可以在 [Eclipse Project Downloads](https://download.eclipse.org/eclipse/downloads/) 中找到，选择版本后，找到 JDT Core Batch Compiler 下载即可。

下载完成后创建一个 java 代码段，并将代码文件编码保存为 GB18030。

```java
public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("你好，世界");
    }
}
```

然后分别使用 javac 与 EJC 进行编译。

```bash
java -jar ecj-4.11.jar HelloWorld.java
```

```bash
javac HelloWorld.java
```

如果没有使用环境变量 JAVA_TOOL_OPTIONS 配置默认编码的话，使用 javac 编译时会提示编码错误，然后通过添加 `-encoding GB18030` 参数即可编译成功。

对代码文件编码的自动处理只是 ECJ 与 javac 的差异之一，因此存在 EJC 可以编译的代码使用 javac 无法编译的情况。

### 解决

知道问题的原因之后要解决问题就不难了，解决方式有两种：

* 修改代码来适配 javac
* 使用 ECJ

修改代码自然是可以解决问题，通过修改 Eclipse 的设置，使用 Oracle JDK 的编译器，然后根据编译报错信息修复代码即可——当然，能升级到 Android Studio 就最好不过了。

但是很多时候开发人员会用“在我机器上没问题”这种理由来~~甩锅~~规避这些额外工作，因此只能在 Jenkins 上构建时指定 ECJ 进行编译。

在 Ant 脚本中可以通过添加下面属性的方式指定编译器，需要将项目使用的 `org.eclipse.jdt.core_xxxxx.jar` 从 Eclipse plugins 目录中复制到 ANT_HOME 的 lib 目录下。

```xml
<property name="build.compiler" value="org.eclipse.jdt.core.JDTCompilerAdapter"/>
```

在 Gradle 中则需要添加以下内容，（代码是网上找的，没有环境进行测试）。

```gradle
configurations {
    ecj
}
dependencies {
    ecj 'org.eclipse.jdt.core.compiler:ecj:4.6.1'
}

compileJava {
    options.fork = true
    options.forkOptions.with {
    executable = 'java'
    jvmArgs = ['-classpath', project.configurations.ecj.asPath, 'org.eclipse.jdt.internal.compiler.batch.Main', '-nowarn']
    }
}
```