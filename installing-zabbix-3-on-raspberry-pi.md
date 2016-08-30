title: 在树莓派上安装 Zabbix 3
date: 2016-08-01 09:45:00
categories: 
  - zabbix
  - raspberry pi
feature: http://www.tomczhen.com/images/logo/raspberry-pi-logo.webp
tags: 
  - zabbix
  - raspberry pi
toc: true
---
>原文地址:
>[Installing Zabbix 3 on a Raspberry Pi](http://devopsish.blogspot.com.au/2016/05/installing-zabbix-3-on-raspberry-pi.html)

对于熟悉 Zabbix 的人来说——这是一个相当棒的开源监控平台。Zabbix 有着可定制性，你可以创建一些非常漂亮的仪表盘。可以打开 [Zabbix 官网](http://www.zabbix.com/) 获取更多的信息。让我用一台带有 Raspbian Jessie 的 [树莓派3 Modele B](https://www.raspberrypi.org/products/raspberry-pi-3-model-b/)来安装一下吧。

注: 原文使用的是 [树莓派2 Model B](https://www.raspberrypi.org/products/raspberry-pi-2-model-b/)

<!-- more -->

<h3 id="pre">安装前的准备</h3>

首先，需要安装 Zabbix 的依赖组件。打开终端或者使用 SSH 连接到你的树莓派进行安装。

```shell
sudo apt-get install \
    mysql-server \
    php5 \
    apache2 \
    php5-gd \
    php5-mysql \
    php5-ldap \
    snmpd \
    libiksemel3 \
    libodbc1 \
    libopenipmi0 \
    fping \
    ttf-dejavu-core \
    ttf-japanese-gothic
```

<h3 id="install-zabbix">安装 Zabbix 3</h3>

幸运的是有人已经在 [https://github.com/imkebe/zabbix3-rpi](https://github.com/imkebe/zabbix3-rpi) 编译好了树莓派的 Zabbix 3 安装包，所以我们不需要自己来编译。
打开控制台让我们继续。

```shell
cd ~
wget https://github.com/imkebe/zabbix3-rpi/archive/master.zip
unzip master.zip
cd zabbix3-rpi-master
sudo dpkg -i zabbix-server-mysql_3.0.*+jessie_armhf.deb
sudo dpkg -i zabbix-frontend-php_3.0.*+jessie_all.deb
sudo dpkg -i zabbix-agent_3.0.*+jessie_armhf.deb
sudo service apache2 reload
```

<h3 id="setup-database">部署 Zabbix 数据库</h3>

Zabbix 服务数据都存储在数据库中，这里我们使用 MySQL。下面的语句都来自 [Zabbix 数据库文档](https://www.zabbix.com/documentation/3.0/manual/appendix/install/db_scripts)。

```shell
mysql -uroot -p<password> -e "create database zabbix character set utf8 collate utf8_bin;"
mysql -uroot -p<password> -e "grant all privileges on zabbix.* to zabbix@localhost identified by '<db-password>';"
zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql -uzabbix -p<db-password> zabbix
```

你需要根据实际情况替换语句中的 `<password>` 和 `<db-password>`。

<h3 id="config-zabbix">配置 Zabbix</h3>

我们需要让服务和前端知道如何连接数据库。可以通过修改几个配置文件来达到这个目的，这里我使用了 `vi` 来编辑。

```shell
sudo vi /etc/zabbix/zabbix_server.conf
```

注:对 `vi` 不熟练的话也可以使用 `nano` 代替。

现在我们来编辑配置文件。如果你使用的是这个指南中的默认配置(数据库名和数据库用户名都是 zabbix)，你只需要反注释掉 DBPassword 条目然后输入你的 zabbix 数据库密码就可以了。

```
DBPassword=<bd-password>
```

接下来需要前端的修改时区设置。

```shell
sudo vi /etc/apache2/conf-enabled/zabbix.conf
```

反注释掉 `php_value date.timezone` 条目然后输入你的时区。你可以在 [http://php.net/manual/en/timezones.php](http://php.net/manual/en/timezones.php) 查看支持的时区。

```
php_value date.timezone Australia/Sydney
```

注: 中国的时区设置应为 `Asia/Shanghai`

重启服务让改动生效

```shell
sudo service apache2 restart
sudo service zabbix-server start
sudo service zabbix-agent start
```

现在我们部署好了后台。打开我们的浏览器然后输入 `http://<your-pi-ip-address>/zabbix`,如果你使用的树莓派桌面浏览器可以输入`http://localhost/zabbix`。
接下来只需要点击下一步，直到`Configure DB connection`部分，这里需要你输入正确的数据用户名和密码。前端配置完成之后就可以看到登录页面了。

![](http://pic.tomczhen.com/zabbix-login.png)

默认的用户名是 `Admin` 默认密码是 `zabbix`。

---

<div align="center">

![](http://pic.tomczhen.com/alipay_QR.png)<br/>
如果对您有帮助的话，可以考虑通过支付宝请作者喝杯咖啡。

</div>
