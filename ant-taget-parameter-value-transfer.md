title: ANT 实践总结
date: 2016-07-12 17:45:00
categories: 
  - ci
feature: /images/logo/apache-ant-logo.webp
tags: 
  - ant
toc: true
---

项目中使用了 ANT 脚本来实现持续集成，使用过程中遇到了一些问题，这里做一下记录。

<!-- more -->

<h3 id ="property">property</h3>

可以通过 `property` 声明一个变量，根据执行顺序，对变量赋值后就不能重新赋值了。ANT 脚本是先按顺序执行 `project` 下的语句，再来按调用顺序执行 `target` 下的语句。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project name="ant-project">
    
    <property name="key" value="val1" />
    <echo message="${key}" encoding="UTF-8"/>

    <property name="key" value="val2" />
    <echo message="${key}" encoding="UTF-8" />

    <target name="test">
        <property name="key" value="val-target" />
        <echo message="${key}" encoding="UTF-8" />
    </target>

</project>
```

运行上面的脚本，查看一下结果
注意：输出时可以使用 `encoding="UTF-8"` 指定编码，对于文件读写，编码需要特别注意。

```
C:\Users\tomcz\Desktop>ant -file ant.xml test
Buildfile: C:\Users\tomcz\Desktop\ant.xml
     [echo] val1
     [echo] val1

test:
     [echo] val1

BUILD SUCCESSFUL
Total time: 0 seconds
```

<h3 id="loadproperties">loadproperties</h3>

除了使用 `property` 还可以使用 `<loadproperties srcFile="ant.properties" />` 加载文件的方式声明。需要注意的是非英文数字字符必须转换编码后才能读取正常(Natvie->ASCII)

```
# 说明
# 非英文数字字符必须转换编码后才能读取正常 Natvie->ASCII
# ant.properties
filekey=filekeyvalue
zhvalkey=\u4e2d\u6587
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project name="ant-project">

    <target name="t1">
    <loadproperties srcFile="ant.properties" />
        <echo message="${filekey}" encoding="UTF-8" />
        <echo message="${zhvalkey}" encoding="UTF-8" />
    </target>

</project>
```

运行结果，`loadproperties` 也可以放在 `target` ，需要注意的是要保证变量在被使用前赋值。

```
C:\Users\tomcz\Desktop>ant -file ant.xml t1
Buildfile: C:\Users\tomcz\Desktop\ant.xml

t1:
     [echo] filekeyvalue
     [echo] 中文

BUILD SUCCESSFUL
Total time: 0 seconds
```


<h3 id="target">target</h3>

可以使用 `antcall` 和 `depends` 在 `target` 中调用其他 `target`，差别是 `antcall` 是在执行语句时才会调用，而 `depends` 是在执行这个 `target` 前调用。
由于前面讲过的赋值后无法改变的问题，如果需要传递变量值时也特别注意。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project name="ant-project">

    <target name="t1" depends="-t2">
        <property name="key1" value="t1-key1-test" />
        <property name="key2" value="t1-key2-test" />
        <property name="key3" value="t1-key3-test" />
        <echo message="${key1}" encoding="UTF-8" />
        <echo message="${key2}" encoding="UTF-8" />
        <echo message="${key3}" encoding="UTF-8" />
        <antcall target="t3"/>
    </target>

    <target name="-t2">
        <property name="key1" value="t2-key1-test" />
        <property name="key2" value="t2-key2-test" />
        <property name="key3" value="t2-key3-test" />
        <echo message="${key1}" encoding="UTF-8" />
        <echo message="${key2}" encoding="UTF-8" />
        <echo message="${key3}" encoding="UTF-8" />
    </target>

    <target name="t3">
        <property name="key1" value="t3-key1-test" />
        <property name="key2" value="t3-key2-test" />
        <property name="key3" value="t3-key3-test" />
        <echo message="${key1}" encoding="UTF-8" />
        <echo message="${key2}" encoding="UTF-8" />
        <echo message="${key3}" encoding="UTF-8" />
    </target>

</project>
```

运行上面的脚本，查看一下结果
注意：`depends` 可以调用顺序执行多个 `target` 

```
C:\Users\tomcz\Desktop>ant -file ant.xml t1
Buildfile: C:\Users\tomcz\Desktop\ant.xml

-t2:
     [echo] t2-key1-test
     [echo] t2-key2-test
     [echo] t2-key3-test

t1:
     [echo] t2-key1-test
     [echo] t2-key2-test
     [echo] t2-key3-test

t3:
     [echo] t2-key1-test
     [echo] t2-key2-test
     [echo] t2-key3-test

BUILD SUCCESSFUL
Total time: 0 seconds
```

如果在 `target` 以 `-` 开头时，无法在命令中指定运行的 `target`，但是内部 `depends` 没问题。

```
C:\Users\tomcz\Desktop>ant -file ant.xml -t2
Unknown argument: -t2
```

<h3 id="import">import</h3>

可以使用 `<import file="ant.xml" />` 的方式引用其他 ANT 脚本。还是一样要注意 `property` 的值传递的问题，被引入的 ANT 脚本的值是无法获取的，但是可以传递覆盖。
需要注意的是，被引入的脚本`project`的值不能一样，否则会有冲突。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project name="ant-project">
<!-- ant.xml -->
<import file="ant2.xml" />

    <target name="t1">
        <property name="key1" value="t1-key1-test" />
        <property name="key2" value="t1-key2-test" />
        <property name="key3" value="t1-key3-test" />
        <echo message="${key1}" encoding="UTF-8" />
        <echo message="${key2}" encoding="UTF-8" />
        <echo message="${key3}" encoding="UTF-8" />
        <antcall target="a2t1"/>
    </target>

</project>
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project name="ant-project2">
<!-- ant2.xml -->
    <property name="a2key1" value="a2-key1-test" />
    <echo message="${a2key1}" encoding="UTF-8" />
    <echo message="${key1}" encoding="UTF-8" />

    <target name="a2t1">
        <echo message="${key2}" encoding="UTF-8" />
    </target>

</project>
```

执行一下看看结果，需要注意的是，即便是引入的 ANT 脚本，在 `project` 下引入的语句也是比 `target` 先执行的，`import` 也可以放在 `target` 中。

```
C:\Users\tomcz\Desktop>ant -file ant.xml t1
Buildfile: C:\Users\tomcz\Desktop\ant.xml
     [echo] a2-key1-test
     [echo] ${key1}

t1:
     [echo] t1-key1-test
     [echo] t1-key2-test
     [echo] t1-key3-test
     [echo] a2-key1-test
     [echo] t1-key1-test

a2t1:
     [echo] t1-key2-test

BUILD SUCCESSFUL
Total time: 0 seconds
```

<h3 id="condition">condition</h3>

不安装其他扩展的前提下 ANT 也是可以使用 `condition` 实现逻辑判断。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project name="ant-project">
    <property name="key1" value="key1-test" />
    <property name="key2" value="key2-test" />
    <property name="key3" value="key2-test" />

    <condition property="isTrue">
        <equals arg1="${key1}" arg2="key1-test" />
    </condition>

    <condition property="isFalse">
      <not>
        <equals arg1="${key2}" arg2="key2-test" />
      </not>
    </condition>

    <target name="t1" if="isTrue">
        <echo message="${key1}" encoding="UTF-8" />
        <antcall target="t3" />
    </target>

    <target name="t2" if="isFalse">
        <echo message="${key2}" encoding="UTF-8" />
        <antcall target="t3" />
    </target>

    <target name="t3">
        <echo message="${key3}" encoding="UTF-8" />
    </target>
</project>
```

配合 `target` 中的 `if` `depends` 可以实现根据条件执行 `target` 的逻辑。

```
C:\Users\tomcz\Desktop>ant -file ant.xml t1 t2
Buildfile: C:\Users\tomcz\Desktop\ant.xml

t1:
     [echo] key1-test

t3:
     [echo] key2-test

t2:

BUILD SUCCESSFUL
Total time: 0 seconds
```
