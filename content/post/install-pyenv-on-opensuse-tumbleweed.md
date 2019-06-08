---
title: 在 openSUSE Tumbleweed 上使用 pyenv 管理多版本 Python 共存
date: 2017-09-11 23:15:00
tags: [Python,Linux]
---

> pyenv does...

>* Let you change the global Python version on a per-user basis.
* Provide support for per-project Python versions.
* Allow you to override the Python version with an environment variable.
* Search commands from multiple versions of Python at a time. This may be helpful to test across Python versions with tox.

pyenv 能干啥？在它的  [GitHub 项目页面](https://github.com/pyenv/pyenv) 就很直接的告诉你了。

<!--more-->

## 安装

> Installation : https://github.com/pyenv/pyenv#installation

1. 在你想安装的路径下直接 checkout pyenv 就可以，`$HOME/.pyenv` 路径就是个非常好的选择（不过你也可以把它安装在其他路径）。

```shell
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
```

2. 定义环境变量 `PYENV_ROOT` 指向到 clone 的路径，并且添加 `$PYENV_ROOT/bin` 到 `$PATH`，这样就可以直接在终端中使用 `pyenv` 命令。

```shell
$ echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bash_profile
$ echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile
```

3. 添加 `pyenv init` 到你的 shell

```shell
$ echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.bash_profile
```

4. 让环境变量生效

```shell
$ source ~/.bash_profile
```

如果安装成功的话，可以使用命令查看 `pyenv` 的版本

```shell
$ pyenv --version
```

5. 按照指定的版本到 `$(pyenv root)/versions`。例如，下载并安装 Python 3.5.4，运行：

```shell
$ pyenv install 3.5.4
```
### 缓存与临时目录

每次安装时都是重新下载 Python 源码包，如果遇到编译问题，有时很费时间，可以通过配置下载缓存来解决。

创建默认的缓存目录

```shell
$ mkdir -p $(pyenv root)/cache
```

如果需要值得缓存目录可以通过环境变量配置

```shell
$ export PYTHON_BUILD_CACHE_PATH="$PYENV_ROOT/cache"
```

默认的临时目录路径为 `/tmp`，有些环境下该路径挂载分区容量不足，同样可以配置。

```shell
$ mkdir ~/tmp
$ export TMPDIR="$HOME/tmp"
```

### 编译依赖

安装 Python 3.5.4 时，我遇到了错误，提示如下：

```
tomczhen@linux-8s26:~> pyenv install 3.5.4
Downloading Python-3.5.4.tar.xz...
-> https://www.python.org/ftp/python/3.5.4/Python-3.5.4.tar.xz
Installing Python-3.5.4...
WARNING: The Python bz2 extension was not compiled. Missing the bzip2 lib?
WARNING: The Python readline extension was not compiled. Missing the GNU readline lib?
ERROR: The Python ssl extension was not compiled. Missing the OpenSSL lib?

Please consult to the Wiki page to fix the problem.
https://github.com/pyenv/pyenv/wiki/Common-build-problems


BUILD FAILED (openSUSE 20170908 using python-build 1.1.3-33-g48aa0c4)

Inspect or clean up the working tree at /tmp/python-build.20170911223655.26645
Results logged to /tmp/python-build.20170911223655.26645.log

Last 10 log lines:
(cd /home/tomczhen/.pyenv/versions/3.5.4/share/man/man1; ln -s python3.5.1 python3.1)
if test "xupgrade" != "xno"  ; then \
        case upgrade in \
                upgrade) ensurepip="--upgrade" ;; \
                install|*) ensurepip="" ;; \
        esac; \
         ./python -E -m ensurepip \
                $ensurepip --root=/ ; \
fi
Ignoring ensurepip failure: pip 9.0.1 requires SSL/TLS
```

> Common build problems
> https://github.com/pyenv/pyenv/wiki/Common-build-problems

根据错误提示和文档内容看，就是缺少依赖包造成的，根据文档中的说明安装编译依赖

```shell
$ sudo zypper in zlib-devel bzip2 libbz2-devel libffi-devel libopenssl-devel readline-devel sqlite3 sqlite3-devel xz xz-devel
```

再次执行安装命令，可以看到已经可以安装成功了。

```
tomczhen@linux-8s26:~> pyenv install 3.5.4
Downloading Python-3.5.4.tar.xz...
-> https://www.python.org/ftp/python/3.5.4/Python-3.5.4.tar.xz
Installing Python-3.5.4...
WARNING: The Python bz2 extension was not compiled. Missing the bzip2 lib?
WARNING: The Python sqlite3 extension was not compiled. Missing the SQLite3 lib?
Installed Python-3.5.4 to /home/tomczhen/.pyenv/versions/3.5.4
```

## 使用

* `pyenv versions`

显示系统可用的 Python 版本

* `pyenv version`

显示当前生效的 Python 版本

* `pyenv local 3.5.4`

配置当前路径 Python 版本为 3.5.4

* `pyenv global 3.5.4`

配置全局 Python 版本为 3.5.4

如果是仅仅为开发使用，那么在 Pycharm 中可以直接选择就可以了，非常方便。


## 升级

需要升级时，到之前 clone 的路径使用 git 就可以升级到最新版本了。

```
$ cd $(pyenv root)
$ git pull
```