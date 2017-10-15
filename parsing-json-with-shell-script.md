title: 使用 Shell 脚本来处理 JSON
date: 2017-10-15 13:45:00
categories:
  - Linux
tags:
  - Shell
toc: true
---

使用 Shell 脚本来处理 JSON，有以下三种方法：

* 使用 `awk` `sed`
* 使用第三方库
* 调用其他脚本解释器

<!-- more -->

> JSON(JavaScript Object Notation) 是一种轻量级的数据交换格式。 易于人阅读和编写。同时也易于机器解析和生成。 它基于[JavaScript Programming Language](http://www.crockford.com/javascript), [Standard ECMA-262 3rd Edition - December 1999](http://www.ecma-international.org/publications/files/ecma-st/ECMA-262.pdf) 的一个子集。 JSON采用完全独立于语言的文本格式，但是也使用了类似于C语言家族的习惯（包括C, C++, C#, Java, JavaScript, Perl, Python等）。 这些特性使JSON成为理想的数据交换语言。

> 来源：http://json.org/json-zh.html

以 `http://ip.taobao.com/service/getIpInfo.php?ip=myip` 接口为例，返回的 JSON 数据格式为:

```json
{
    "code": 0,
    "data": {
        "country": "中国",
        "country_id": "CN",
        "area": "华南",
        "area_id": "800000",
        "region": "广东省",
        "region_id": "440000",
        "city": "深圳市",
        "city_id": "440300",
        "county": "",
        "county_id": "-1",
        "isp": "电信",
        "isp_id": "100017",
        "ip": "113.104.182.107"
    }
}
```

## 使用内置命令处理

使用内置的 `awk` `sed` 来获取指定的 JSON 键值。

```shell
function get_json_value()
{
  local json=$1
  local key=$2

  if [[ -z "$3" ]]; then
    local num=1
  else
    local num=$3
  fi

  local value=$(echo "${json}" | awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'${key}'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p)

  echo ${value}
}
```

使用下面的方式可以获得 ip 的值：

```shell
get_json_value $(curl -s http://ip.taobao.com/service/getIpInfo.php?ip=myip) ip
```

使用内置命令的优点是无需额外的依赖，缺点是有些 JSON 格式无法正常获取，需要根据实际情况修改相关的正则或命令参数。

例如，以上脚本获取 data 字段时就会有问题：

```shell
get_json_value $(curl -s http://ip.taobao.com/service/getIpInfo.php?ip=myip) data
```

会返回以下结果：

```
{country
```

另外脚本并没有转码功能，所以获取中文值时输出的仍然是原编码，例如获取 isp 字段：

```shell
get_json_value $(curl -s http://ip.taobao.com/service/getIpInfo.php?ip=myip) isp
```

会返回以下结果：

```
\u7535\u4fe1
```

## 使用第三方库处理

> jq is like sed for JSON data - you can use it to slice and filter and map and transform structured data with the same ease that sed, awk, grep and friends let you play with text.

> 来源：https://stedolan.github.io/jq/

`jq` 与 `sed` 类似，但是对于处理 JSON 更加友好、方便。由于是第三方库，所以需要单独安装或添加二进制文件到 PATH 路径下。不过 `jq` 本身是可以跨平台并且单文件即可运行，也很方便。

通过下面的命令可以获得返回的 JSON 数据：

```shell
curl -s http://ip.taobao.com/service/getIpInfo.php?ip=myip | jq '.'
```

如果需要单独获得 `ip` 的值，只需要修改 jq 的参数即可：

```shell
curl -s http://ip.taobao.com/service/getIpInfo.php?ip=myip | jq '.data.ip'
```

更多用法可以查看 `jq` 的手册 [https://stedolan.github.io/jq/manual/](https://stedolan.github.io/jq/manual/)

## 调用其他脚本解释器

虽然 bash/sh 没有专门处理 JSON 的功能，但是其他脚本解释器通常都是有的，比如 Python、PHP 或者 Ruby，甚至 JavaScript 也可以。

注：PHP 需要有 PHP CLI，JavaScript 需要有 Node。

以 Python 为例获取 ip 的值：

* Python 2
```shell
export PYTHONIOENCODING=utf8
curl -s 'http://ip.taobao.com/service/getIpInfo.php?ip=myip' | \
    python -c "import sys, json; print json.load(sys.stdin)['data']['ip']"
```

* Python 3
```shell
curl -s 'http://ip.taobao.com/service/getIpInfo.php?ip=myip' | \
    python3 -c "import sys, json; print(json.load(sys.stdin)['data']['ip'])"
```