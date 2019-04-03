title: pipenv 快速入门
date: 2019-02-02 16:45:00
categories:
  - Python
feature: /images/logo/python-logo.webp
tags:
  - Python
  - pipenv
toc: true

---

> [A Better Pip Workflow™](https://www.kennethreitz.org/essays/a-better-pip-workflow)

Python 开发中一般会使用 `virtualenv` `pip` 管理项目运行环境与依赖。在创建一个新项目时先使用 `virtualenv` 创建一个虚拟运行环境，然后使用 `pip` 安装依赖，最后使用 `pip freeze > requirements.txt` 记录项目依赖。这个过程中会遇到一些问题：

* 版本信息没有保存
* 升级依赖包时需要先查看`requirements.txt`
* 开发环境与生产环境依赖区分

解决上述问题最直接的做法就是生成多个 `requirements.txt` ，比如：`requirements-dev.txt`、`requirements-prod.txt` 并记录好依赖版本信息，或者选择 [Pipenv: Python Dev Workflow for Humans](https://pipenv.readthedocs.io/en/latest/) 。

<!-- more -->

从名字可以很直观的看出 `pipenv` = `pip` + `virtualenv`。

## 在开发中使用 `pipenv`

在项目开发过程中使用 `pipenv` 体验基本与 `pip` 一致，而且由于 `pipenv` 也会同时管理虚拟环境，体验上流程更顺滑。`pipenv` 使用 `Pipfile` 与 `Pipfile.lock` 来管理依赖，`Pipfile.lock` 会根据安装的依赖包记录 hash 校验值与版本信息。

### 创建虚拟环境

在新建项目目录下可以通过以下三种方式创建虚拟环境：

```bash
$ pipenv --python 3.6`
```

```bash
$ pipenv --python /path/to/python`
```

```bash
$ pipenv install requests --python 3.6`
```

注意：如果没有使用 `--python` 参数指定 Python 版本则会使用默认的 Python 版本创建，如果想指定默认 Python 版本可以通过环境变量 `PIPENV_DEFAULT_PYTHON_VERSION` 配置，可以设置为 Python 版本号：`3.6.8` 或 Python 解释器程序路径。

如果需要虚拟运行环境目录指定在项目目录下创建，有两种方式可以实现：

* 执行 `pipenv` 前先创建 `.venv` 目录

```bash
$ mkdir .venv && pipenv install requests --python 3.6
```

* 配置 `PIPENV_VENV_IN_PROJECT` 环境变量

```bash
$ export PIPENV_VENV_IN_PROJECT=1
```

如果想自定义这个目录则需要通过 `WORKON_HOME` 环境变量来配置。

#### 从现有项目创建虚拟环境

对于现有项目，可以区分为三种情况：

* 没有使用 `pipenv`

使用 `pipenv install -r path/to/requirements.txt --python 3.6` 来安装依赖。

* 有使用意向，但需要兼容旧方式

通过 `pipenv lock -r > requirements.txt` 生成与 pip 相同格式的依赖管理文件。

* 已经在使用

根据需要可以使用  `pipenv install` 或 `pipenv sync`。两者都会根据 `Pipfile` 中的 Python 版本创建虚拟环境，使用指定的 PyPI 源，区别是 `pipenv install` 会根据 `Pipfile` 中的版本信息安装依赖包，并重新生成 `Pipfile.lock`；而 `pipenv sync` 会根据 `Pipfile.lock` 中的版本信息安装依赖包。

也就是 `pipenv install` 安装的依赖包版本可能被更新，具体的机制在依赖包管理中进一步说明。

### 激活虚拟环境

可以先激活虚拟环境，再来运行 Python :

```bash
$ pipenv shell
```

或者直接运行：

```bash
$ pipenv run python main.py
```

在项目根目录下有 `.env` 环境配置文件时，激活虚拟环境同时会加载 `.env` 文件中的环境变量配置，如果不想使用这个功能可以通过配置 `PIPENV_DONT_LOAD_ENV` 变量来关闭它。

### 依赖包管理

`pipenv`安装包的使用方式与 `pip` 基本一致，直接在项目目录下执行 `pipenv install request` 会安装到虚拟环境目录下，没有虚拟环境则会创建后安装。

#### 安装包

没有指定版本信息时，`Pipfile` 中不会注明版本，如果在新目录中使用 `pipenv install` 直接安装依赖包的最新版本。

```shell
$ pipenv install requests
```

以下方式会指定为 `1.2` 或以上版本，但不会大于等于 `2.0`，使用 `pipenv install` 安装依赖时，如果新版本在 `1.2` 到 `2.0` 之间（不包含 `2.0` 版本）就会更新

```shell
$ pipenv install “requests~=1.2”
```

更多的版本指定方式如下：

```
$ pipenv install "requests>=1.4"   # 版本号大于或等于 1.4.0
$ pipenv install "requests<=2.13"  # 版本号小于或等于 2.13.0
$ pipenv install "requests>2.19"   # 版本号大于 2.19.0
```

如果仅仅在开发 环境下使用这个包，可以添加 `--dev` 参数安装：

```
$ pipenv install ipython --dev
```

#### 更新包

* 查看有更新的包

```shell
$ pipenv update --outdated
```

* 更新所有依赖包

```shell
$ pipenv update
```

* 更新指定依赖包

```shell
$ pipenv update request
```

注意：升级依赖包的版本时受到 `Pipfile` 中版本信息限制，如果想安装超出限制的版本，则需要执行 `pipenv install <pkg>` 安装。

#### 卸载包

```shell
$ pipenv uninstall requests
```

* 查看依赖关系

```shell
$ pipenv graph
```

安装或卸载依赖包之后，`pipenv` 都会更新 `pipfile` 与 `pipfile.lock`

### 配置 PyPI 镜像源

通常会使用 `pip.conf` 或者 `--index-url` 参数来配置 PyPI 镜像源，`pipenv` 中有多种配置方式：

* 使用环境变量 `PIPENV_PYPI_MIRROR` 配置。

```bash
$ export PIPENV_PYPI_MIRROR=https://mirrors.aliyun.com/pypi/simple/
```

* 使用项目中的 `pipfile` 文件配置。

通过项目 `pipfile` 文件中的 `[[source]]` 节也可以配置安装源，并且只对该项目生效。

```
[[source]]
name = "pypi"
url = "https://mirrors.aliyun.com/pypi/simple/"
verify_ssl = true
...
```

### 配合 `pyenv` 使用

Linux 和 macOS 下可以安装 `pyenv` 配合使用，在使用 `pipenv` 时如果指定的 Python 版本没有安装，就会调用 `pyenv` 进行编译安装。

首先请参考 [pyenv: Common build problems - Prerequisites](https://github.com/pyenv/pyenv/wiki/Common-build-problems#prerequisites) 安装好编译依赖。

然后根据 [Simple Python Version Management: pyenv - Installation](https://github.com/pyenv/pyenv#installation) 安装好 `pyenv`。

注意：Windows 用户请手动下载 Python 安装包安装，通过 `pipenv --python X:\Python\...\python.exe` 指定 Python 版本，~~如果想编译安装请自行解决~~。

#### 配置 `pyenv`

可以根据需要配置源码缓存与编译临时文件路径，解决因为网络问题无法下载源码包，或者 `/tmp` 分区空间不足造成编译安装失败。

* 源码包缓存

添加缓存目录，然后将源码包存放到缓存目录，并且编译失败时不会重新下载源码包。

```bash
$ mkdir -p $(pyenv root)/cache
```

* 临时文件目录

默认使用系统临时文件路径 `/tmp`，指定其他路径为临时文件目录。 

```bash
$ mkdir ~/tmp
$ export TMPDIR="$HOME/tmp"
```

* 有些第三方包工具比如 PyInstaller 需要 CPython 以 `--enable-shared` 参数编译

```
$ env PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install 3.6.8
```

## 在部署时使用 `pipenv`

为了保证部署时安装的依赖版本与发布一致，使用 `pipenv install` 需要加上 `--deploy` 参数。

```shell
$ pipenv install --deploy
```

如果不使用虚拟环境，还需要加上 `--system` 参数

```shell
$ sudo pipenv install --deploy --system
```

### 在 Docker 中使用 `pipenv`

这里给一个 Dockerfile 作为参考。

```Dockerfile
FROM python:3.6.8

ENV PIP_INDEX_URL https://mirrors.aliyun.com/pypi/simple/
RUN pip3 install pipenv --no-cache-dir

RUN set -ex && mkdir /app
WORKDIR /app

COPY Pipfile Pipfile
COPY Pipfile.lock Pipfile.lock
RUN set -ex && pipenv install --deploy --system

COPY . /app
EXPOSE 8888
CMD python3 main.py
```

也可以先构建一个 Base Image ，然后在构建应用镜像时使用，假设构建的 Base Image tag 为 `tomczhen/python-pipenv-base:3.6.8`。

* Base Image Dockerfile

```Dockerfile
FROM python:3.6.8

ENV PIP_INDEX_URL https://mirrors.aliyun.com/pypi/simple/
RUN pip3 install pipenv --no-cache-dir

RUN set -ex && mkdir /app
WORKDIR /app

ONBUILD COPY Pipfile Pipfile
ONBUILD COPY Pipfile.lock Pipfile.lock
ONBUILD RUN set -ex && pipenv install --deploy --system
```

* Python Application Image Dockerfile
```Dockerfile
FROM tomczhen/python-pipenv-base:3.6.8

COPY . /app
EXPOSE 8888
CMD python3 main.py
```

## `pipenv` 的缺点

当然，pipenv 也有缺点存在。

### lock 耗时

[Lock updating is very slow · Issue #1914 · pypa/pipenv](https://github.com/pypa/pipenv/issues/1914)

这是一个代价问题。

由于需要根据依赖关系以及文件 hash 来生成 `Pipfile.lock`，所以短时间内看这个问题应该是无法解决的。需要在 `pipenv` 带来的依赖管理功能与速度上做一个权衡取舍。

目前的办法是在安装依赖时使用 `pipenv install --skip-lock` 来跳过生成/更新 `Pipfile.lock`,然后在需要时执行 `pipenv lock` 来生成/更新 `Pipfile.lock`

### 跨平台问题

严格来说这并不算是 `pipenv` 的问题。

部分包在跨平台时的依赖不同，比如 [PyInstaller](https://pypi.org/project/PyInstaller/) 可以在多个平台使用，但仅在 Windows 上才依赖 pywin32 包，由于 `Pipfile.lock` 是根据安装的包生成的，所以会造成跨平台时安装依赖失败。

根据 [Problem with Pipfile and system specific packages · Issue #1575 · pypa/pipenv](https://github.com/pypa/pipenv/issues/1575) 中的讨论看，即便 pywin32 修复了问题也只能在新版本中解决，因此短期内如果有跨平台需求还需要先确定是否正常。
