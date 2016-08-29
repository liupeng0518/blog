title: 阿里云ECS自建Redis性能测试
date: 2016-04-10 13:28:00
categories: 
  - database
  - redis
description: 阿里云 ECS 自建 Redis 实例与云数据库 Redis 实例性能对比测试
feature: http://pic.tomczhen.com/redis-logo.png@!title
tags: 
  - redis
  - 阿里云
  - ECS
toc: true
---

由于公司项目需要使用 Redis 数据库，需要在自建实例与云实例间做出选择，所以进行了测试。由于项目不需要数据持久化，因此没有测试持久化 IO 相关性能。

<!-- more -->

<h2 id="env">测试环境说明</h2>

<h3 id="hardware">硬件环境</h3>

* **服务器**
    * 实例系列 : 系列I
    * 实例规格 : 2 核 2GB
    * 公网带宽 : 10Mpbs
    * 操作系统 : FreeBSD 10.1 64位

* **内网客户端**
    * 实例系列 : 系列 I
    * 实例规格 : 2 核 4GB
    * 操作系统 : Windows Server 2012 标准版 64位

* **外网客户端**
    * 硬件配置 : Intel Core i5 4200U / DDR3L 1600 8G
    * 上行带宽 : 4Mpbs
    * 操作系统 : Windows 10 64位

* **云数据库Redis** 

    * 存储容量 : 1G

<h3 id="software">软件环境</h3>

* Redis 3.0.2

配置为最大内存可用1024mb,其余为默认配置.

* Python 2.7

<h3 id="code">测试脚本</h3>

分别使用单线程,2 线程,4 线程增加 10 万个 TTL 值为 60 秒的 key , key 名使用 UUID , value 统一为 0 .

```
# coding:utf-8
 
import uuid
import redis
from datetime import datetime
from threading import Thread
 
 
def set_redis_key():
    thread_start_time = datetime.now()
    thread_name = t.getName()[-1:]
    j = 0
    r = redis.StrictRedis(host=redis_host, port=redis_port, password=redis_pwd)
 
    while j < 100000:
        key_name = thread_name + ":" + str(uuid.uuid4())
        key_value = 0
        r.set(key_name, key_value, ex=60, px=None, nx=False, xx=False)
        j += 1
 
    thread_end_time = datetime.now()
    print "Thread " + thread_name + " start: " + str(thread_start_time) + " end: " + str(
        thread_end_time) + " cost: " + str((thread_end_time - thread_start_time).seconds) + " seconds."
 
 
if __name__ == "__main__":
    redis_host = "10.169.0.0"
    redis_port = 6379
    redis_pwd = "redis"
 
    max_thread_num =1
    for i in range(max_thread_num):
        t = Thread(target=set_redis_key)
        t.start()
```

<h2 id="result">测试结果</h2>

注意 : 云数据库 Redis 仅支持从内网访问

<h3 id="table">测试数据</h3>

<h4 id="redisonecs">ECS 自建 Redis 实例</h4>

* **ECS 本地**
    * 1 线程 : 22 秒
    * 2 线程 : 18 秒
    * 4 线程 : 18 秒

* **内网客户端**
    * 1 线程 : 44秒
    * 2 线程 : 33秒
    * 4 线程 : 30秒

* **外网客户端**
    * 1 线程 : 471 秒
    * 2 线程 : 312 秒
    * 4 线程 : 154 秒

<h4 id="redisonyun">云数据库 Redis 实例</h4>

* **内网客户端**
    * 1 线程 : 191 秒
    * 2 线程 : 106.5 秒
    * 4 线程 : 55 秒

<h3 id="expiry">结论</h3>

阿里云云数据库 Redis 存储容量 2G 实例每年费用为 2700 元,2 核 4GB 系列 II 实例价格为 2160 元.(注 : 系列 II 的性能比 系列 I 更好.)
云数据库 Redis 的优势是自带集群并且免维护,但性价比低.自建 Redis 实例性价比高,但需要自行维护并且没有集群(需要自建集群).
如果对性能要求高,并且没有持久化的需求(持久化 IO 并未测试)选择自建实例.如果对可靠性要求高,有其他复杂应用运维有难度可以直接选择云数据库实例.

<h3 id="other">后话</h3>

批量增加大量 key 时可以使用管道和连接池来提高效率，python 代码 demo 如下：
```
# -*- coding: utf-8 -*-
import uuid
import redis
from datetime import datetime
import threading


class RedisTest(object):
    def __init__(self, host, port=6379, pwd=""):
        self.pool = redis.ConnectionPool(host=host, port=port, password=pwd)
        self.record_time = {}

    def set_key_test(self, key_num, thread_num):
        for i in range(thread_num):
            thread = threading.Thread(target=self.__set_key(key_num), name=i + 1)
            if i == 0:
                self.record_time["start"] = datetime.now()
            thread.start()
            if i == thread_num - 1:
                self.record_time["end"] = datetime.now()

        cost_time = self.record_time["end"] - self.record_time["start"]
        print(
            "使用 {} 个线程，每线程添加 {} 个 key，共耗时 {} 秒 {} 毫秒".format(thread_num, key_num, cost_time.seconds,
                                                             cost_time.microseconds / 1000))

    def __init_pool(self):
        pool = redis.Redis(connection_pool=self.pool)
        return pool

    def __set_key(self, key_num):
        j = 0
        connect_pool = self.__init_pool()
        pipe = connect_pool.pipeline()
        while j < key_num:
            key_name = "python" + ":" + str(uuid.uuid4())
            key_value = ""
            pipe.set(key_name, key_value, ex=60, px=None, nx=False, xx=False)
            j += 1

        pipe.execute()

    def lpush(self, value_num):
        connect_pool = self.__init_pool()
        pipe = connect_pool.pipeline()
        start_time = datetime.now()
        tuple_values = tuple(range(value_num))
        pipe.lpush("key_list", *tuple_values)
        pipe.execute()
        end_time = datetime.now()
        cost_time = end_time - start_time
        print(
            "使用 rpush，添加 {} 个 value 到 list，共耗时 {} 秒 {} 毫秒".format(value_num, cost_time.seconds,
                                                       
```

<div align="center">
![](http://pic.tomczhen.com/alipay_QR.png)  
如果对您有帮助的话，可以考虑通过支付宝请作者喝杯咖啡。
</div>
