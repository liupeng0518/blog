title: 如何在LoadRunner11中调用C#编译的动态链接库
date: 2015-12-06 19:25:51
categories:
  - loadrunner
feature: http://pic.tomczhen.com/loadrunner-logo.jpg@!title
tags:
  - loadrunner
  - csharp
toc: true
---
<h2 id="dllcode">动态库代码实例</h2>

以下示例代码在 Visual Studio Community 2015 中编译测试通过，在 LoadRunner11 中测试通过。

<h3 id="csharp">创建 C# 动态库项目</h3>

示例代码
```
namespace CSHelper
{
    public class Class1
    {
        public Class1()
            {
            }
            public static int sum(int a, int b)
        {
            return (a + b);
        }
        public static string cstr(string a)
        {
            a = a + "OK";
            return a;
        }
    }
}
```

<!-- more -->

<h3 id="cpp">创建 C++ 动态库项目</h3>

需要关闭预编译头，并开启 /clr 选项（公共语言运行时支持）
注意：开启 /clr 后编译时会有提示其他选择也需要修改，按提示修改即可。
示例代码
```
#using "..\bin\Debug\CSHelper.dll"
using namespace System;
using namespace CSHelper;
using namespace std;
using namespace System::Runtime::InteropServices;
extern int Calladd(int, int);
extern char* Callstr(char*);
extern "C"
{
  __declspec(dllexport) int add(int a, int b)
  {
    return Calladd(a, b);
  }
  __declspec(dllexport) char* cstr(char* a)
  {
    return Callstr(a);
  }
}
int Calladd(int a, int b) {
  return Class1::sum(a, b);
}
char* Callstr(char* a) {
  String^cstrin = gcnew String(a);//将char*类型转为System::String,出入C#的参数类型为System::String
  String^cstrout = Class1::cstr(cstrin);
  char* str;
  str = (char*)(void*)Marshal::StringToHGlobalAnsi(cstrout);//将System::String转换为char*,在C中只能使用char*
  return str;
}
```
<h3 id="cppdemo">C++ 控制台 Demo</h3>

示例代码
```
// CPPTest.cpp : 定义控制台应用程序的入口点。
//
#include "stdafx.h"
#include <string>
#using "..\bin\Debug\CSHelper.dll"
using namespace System;
using namespace intmath;
using namespace std;
using namespace System::Runtime::InteropServices;
extern int Calladd(int, int);
extern char* Callstr(char*);
extern "C"
{
  __declspec(dllexport) int add(int a, int b)
  {
    return Calladd(a, b);
  }
  __declspec(dllexport) char* cstr(char* a)
  {
    return Callstr(a);
  }
}
int Calladd(int a, int b) {
  return Class1::sum(a, b);
}
char* Callstr(char* a) {
  String^cstrin = gcnew String(a);
  String^cstrout = Class1::cstr(cstrin);
  char* str;
  str = (char*)(void*)Marshal::StringToHGlobalAnsi(cstrout);
  return str;
}
int main()
{
  int a = add(5, 5);
  printf("----%d----\n", a);
  char* b = cstr("Hello World!");
  printf("----%s----",b);
  getchar();
    return 0;
}
```

<h2 id="lr">LoadRunner</h2>

由于 C# 动态库依赖 .net 运行库，因此只能在 Windows 平台上加载。

<h3 id="local-lr">本地 Generator 加载</h3>

注：需要将编译好的 C# DLL 拷贝到 LoadRunner 安装路径 bin 目录下并在 Loadrunner 中调用 C++ 动态库
```
Action()
{
  lr_load_dll("LrDLL.dll");
  lr_output_message("add(12, 13) = %d", add(12, 13));
    lr_output_message("cstr(Hello World) = %s", cstr("Hello World"));
  return 0;
}
```

**LoadRunner输出结果，本机测试通过**
```
虚拟用户脚本已从 : 2015-08-19 12:38:48 启动
正在开始操作 vuser_init。
Web Services replay version 11.0.0 for Windows 7; Toolkit: "NotDefined"; build 8859
Run-Time Settings file: "D:\LoadRunner\Test\\default.cfg"
Vuser directory: "D:\LoadRunner\Test"
Vuser output directory: "D:\LoadRunner\Test\"
LOCAL start date/time:  2015-08-19 12:38:48
正在结束操作 vuser_init。
正在运行 Vuser...
正在开始迭代 1。
正在开始操作 Action。
Action.c(4): add(12, 13) = 25
Action.c(5): cstr(Hello World) = Hello World!OK
正在结束操作 Action。
正在结束迭代 1。
正在结束 Vuser...
正在开始操作 vuser_end。
正在结束操作 vuser_end。
Vuser 已终止。
```

<h3 id="remote-lr">远程 Generator 加载</h3>

<h4>报错一</h4>

```
vuser_init.c(6): Error: C interpreter run time error: 
vuser_init.c(6): Error -- File error : LoadLibrary(LrDLL.dll) failed : 找不到指定的模块。.	[MsgId: MERR-19890]
```

*	确认远程 Generator 机器的 Vuser 目录下是否已经有调用的 LrDLL.dll 文件，如果没有则需要为脚本添加文件。
*	使用 Windows Dependency Walker 检查 LrDLL.dll 依赖的运行库文件在远程 Generator 系统中是否存在。可以通过拷贝 C++ 控制台 Demo 到目标机器，测试是否能正常运行。
*	修改加载脚本，使用绝对路径进行加载，例如：

```
vuser_init()
{
	lr_load_dll("C:\\DLL\\LrDLL.dll");
	return 0;
}
```

<h4>报错二</h4>

```
vuser_init.c(6): Error: C interpreter run time error: 
vuser_init.c(6): Error -- File error : LoadLibrary(LrDLL.dll) failed : (null).	[MsgId: MERR-19890]
```

* 一般是由于解决报错一时所使用的运行库文件版本与系统不对应造成的，只能通过多尝试同名文件的不同版本测试。
* 可以在远程机器上系统环境变量中添加自定义目录方便替换和整理好需要的运行库，用于批量部署。
* 使用 C++ 控制台 Demo 测试可以方便的看出运行结果。

<h4>报错三</h4>

```
Action_UserLogin.c(3): Error: An exception was raised while calling invocation function in interpreter extension cciext.dll: System Exceptions: Uknown.	[MsgId: MERR-10399]
```

* 与本地 Vuser 运行相同，需要将 CSHelper.dll 拷贝到 HP Load Generator 的安装路径 bin 目录下，否则会造成函数调用报错。