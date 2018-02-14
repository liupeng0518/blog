title: 一次 DNS 查询会产生多少流量
date: 2018-02-12 19:25:00
categories:
  - Network
tags:
  - DNS

---

> 参考资料：
> * [Internet protocol suite - Abstraction layers](https://en.wikipedia.org/wiki/Internet_protocol_suite#Abstraction_layers)

以客户端的角度，根据相关协议的 RFC 文档内容来计算 IPv4 网络中一次 DNS 查询会产生多少网络流量。

根据 [RFC 1122](https://tools.ietf.org/html/rfc1122) TCP/IP 模型可以知道，要计算一次 DNS 查询所产生的流量，首先需要知道 DNS 协议在应用层产生的数据大小，然后根据传输层 TCP 或 UDP 协议计算出数据封包后的大小，最后根据网络层 IP 协议计算出实际产生的流量。

<!-- more -->

# 应用层 - DNS

> 参考资料：
> * [RFC 1035 - DOMAIN NAMES](https://www.ietf.org/rfc/rfc1035)
> * [Fully qualified domain name (FQDN)](https://en.wikipedia.org/wiki/Fully_qualified_domain_name)
> * [What is the real maximum length of a DNS name?](https://blogs.msdn.microsoft.com/oldnewthing/20120412-00/?p=7873)

根据 RFC 1035 中的定义，域名以 Label 组成，以长度为零的 Label 结束，只能包含 ASCII 字符中的字母（A-Za-z）、数字（0-9）以及 `-`（注1、注2）。每个 Label 的长度最大为 63 Byte，域名的总的最大长度为 253 Byte（注3）。所有的域名都有一个根域，完整的域名应该为 `example.com.`，DNS 应用在查询时会自动补全最后的 `.` 。
RFC 中对域名定义为大小写不敏感，`example.com` 与 `EXAMPLE.COM` 会获得相同的查询记录，但浏览器 URL 中除了 `scheme` 与 `host`，其他部分是大小写敏感的。如果后端没有进行处理， `http://example.com/a` 与 `http://example.co/A` 是指向不同的资源。

* *注1：RFC 1035 规定 Label 必须以字母开头，但是 [RFC1123 - 6.1.3.5](https://www.ietf.org/rfc/rfc1123) 中去掉了这个限制。*
* *注2：在浏览器中可以输入非 ASCII 字符作为域名，实际是使用基于 [Punycode](https://zh.wikipedia.org/wiki/Punycode) 码的 [IDNA](https://zh.wikipedia.org/wiki/IDNA) 系统，将 Unicode 字符串映射为有效的 DNS 字符集。*
* *注3：RFC 1035 规定域名最大长度为 255 Byte，但根据 RFC 中的编码规则，`.` 并不会参与编码，除了 Label 字符串需要编码外还需要将 Label 的长度进行编码，加上最后的长度为 0 的 Label，因此实际可用长度为 253 Byte。*

## Message

DNS 协议通信的消息格式只有一种，分为 5 个部分，`Header` 是一定存在的，其他部分在一些情况下为空。

```
+---------------------+
|        Header       |
+---------------------+
|       Question      | the question for the name server
+---------------------+
|        Answer       | RRs answering the question
+---------------------+
|      Authority      | RRs pointing toward an authority
+---------------------+
|      Additional     | RRs holding additional information
+---------------------+
```

### Header

`Header` 是必须存在的，大小固定为 12 Byte。

```
                                1  1  1  1  1  1
  0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|                      ID                       |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|QR|   Opcode  |AA|TC|RD|RA|   Z    |   RCODE   |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|                    QDCOUNT                    |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|                    ANCOUNT                    |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|                    NSCOUNT                    |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|                    ARCOUNT                    |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
```

| 字段 | 长度 | 说明 |
| :--- | :---: | :--- |
| ID | 2 Byte | A 16 bit identifier assigned by the program that generates any kind of query. |
| QR | 1 Bit | A one bit field that specifies whether this message is a query (0), or a response (1). |
| OPCODE | 4 Bit | A four bit field that specifies kind of query in this message. |
| AA | 1 Bit | Authoritative Answer - this bit is valid in responses, and specifies that the responding name server is an authority for the domain name in question section. |
| TC | 1 Bit | TrunCation - specifies that this message was truncated due to length greater than that permitted on the transmission channel. |
| RD | 1 Bit | Recursion Desired - this bit may be set in a query and is copied into the response. |
| RA | 1 Bit | Recursion Available - this be is set or cleared in a response, and denotes whether recursive query support is available in the name server. |
| Z | 3 Bit | Reserved for future use. |
| RCODE | 4 Bit | Response code - this 4 bit field is set as part of responses. |
| QDCOUNT | 2 Byte | an unsigned 16 bit integer specifying the number of entries in the question section. |
| ANCOUNT | 2 Byte | an unsigned 16 bit integer specifying the number of resource records in the answer section. |
| NSCOUNT | 2 Byte | an unsigned 16 bit integer specifying the number of name server resource records in the authority records section. |
| ARCOUNT | 2 Byte | an unsigned 16 bit integer specifying the number of resource records in the additional records section. |

### Question

查询时 `Question` 是必须存在的，其中 `QTYPE` 和 `QCLASS` 为固定长度，`QNAME` 是可变长度，由所查询的域名长度决定。

```
                                1  1  1  1  1  1
  0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|                                               |
/                     QNAME                     /
/                                               /
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|                     QTYPE                     |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|                     QCLASS                    |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
```

| 字段 | 长度 | 说明 |
| :--- | :---: | :--- |
| QNAME | variable | a domain name represented as a sequence of labels, where each label consists of a length octet followed by that number of octets.|
| QTYPE | 2 Byte | a two octet code which specifies the type of the query. |
| QCLASS | 2 Byte | a two octet code that specifies the class of the query. |

`QNAME` 为可变长度，域名会被编码为 `{label-length}{label-string}...{label-length}{label-string}0`，所以实际占用的数据会多 2 Byte。

### Resource Record

`Answer` `Authority` `Additional` 的结构是相同的，`NAME` 与 `RDATA` 是可变的。

```
                                1  1  1  1  1  1
  0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|                                               |
/                                               /
/                      NAME                     /
|                                               |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|                      TYPE                     |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|                     CLASS                     |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|                      TTL                      |
|                                               |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|                   RDLENGTH                    |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--|
/                     RDATA                     /
/                                               /
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
```

| 字段 | 长度 | 说明 |
| :--- | :---: | :--- |
| NAME | variable | a domain name to which this resource record pertains. |
| TYPE | 2 Byte | two octets containing one of the RR TYPE codes. |
| CLASS | 2 Byte | two octets containing one of the RR CLASS codes. |
| TTL | 4 Byte | a 32 bit signed integer that specifies the time interval that the resource record may be cached before the source of the information should again be consulted. |
| RDLENGTH | 2 Byte | an unsigned 16 bit integer that specifies the length in octets of the RDATA field. |
| RDATA | variable | a variable length string of octets that describes the resource. |

`NAME` 的长度最少为 2 Byte，当 `NAME` 中的字节前两 Bit 都为 1 时，表示后面的 14 Bit 是一个偏移量，代表从 Message 开始部分偏移。Label 的长度编码前两 Bit 需要是 0（01 和 10 作为保留），也就是 Label 长度最大为 63 的原因。

```
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
| 1  1|                OFFSET                   |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
```

`RDATA` 的大小根据不同类型的记录格式有所不同， A 记录以 32 Bit 来表示一个 IPV4 地址。

```
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
|                    ADDRESS                    |
+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
```

# 传输层 - UDP

> 参考资料：
> * [User Datagram Protocol - UDP](https://tools.ietf.org/html/rfc768)

虽然 DNS 支持 UDP 和 TCP，不过最常用的是 UDP，根据 RFC 768 中 UDP 报文结构的定义可以得到 UDP 报文会为数据增加 8 Byte 的头部信息。

```
 0      7 8     15 16    23 24    31
 +--------+--------+--------+--------+
 |   Source Port   | Destination Port|
 +--------+--------+--------+--------+
 |     Length      |    Checksum     |
 +--------+--------+--------+--------+
 |
 |          data octets ...
 +---------------- ...
```

| 字段 | 长度 | 说明 |
| :--- | :---: | :--- |
| Source Port | 2 Byte | Source Port is an optional field, when meaningful, it indicates the port of the sending process, and may be assumed to be the port to which a reply should  be addressed  in the absence of any other information. |
| Destination  Port | 2 Byte | Destination  Port has a meaning within the context of a particular internet destination address. |
| Length | 2 Byte | Length  is the length in octets  of this user datagram  including  this header  and the data. |
| Checksum | 2 Byte | Checksum is the 16-bit one's complement of the one's complement sum of a pseudo header of information from the IP header, the UDP header, and the data, padded with zero octets at the end (if necessary) to make a multiple of two octets. |

由于 `Length` 的大小是 2 Byte，因此 UDP 包理论最大为 2^16 Byte，减去 8 Byte 的首部，有效负载数据大小为 2^16 - 8 Byte。

# 网络层 - IP

> 参考资料：
> * [IPv4](https://en.wikipedia.org/wiki/IPv4)
> * [RFC 791 - INTERNET PROTOCOL](https://tools.ietf.org/html/rfc791)

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|Version|  IHL  |Type of Service|          Total Length         |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|         Identification        |Flags|      Fragment Offset    |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  Time to Live |    Protocol   |         Header Checksum       |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                       Source Address                          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Destination Address                        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Options                    |    Padding    |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

`IHL` 大小为 4 Bit，使用十进制表示 IP 协议头部的长度为多少个 32 Bit，最小值为 5，最大值为 15，因此 IP 协议头部的最大长度为 60 Byte。当 `IHL` 大于 5 时，`Options` 才会有数据，并且需要 `Padding` 来保证 IP 协议头部大小一定是 32 Bit 的整数倍。通常情况下 IP 协议头部的大小为 20 Byte。

IPv4 中是在 IP 协议中根据 MTU 进行分片，虽然 UDP 包的理论大小限制远大于 MTU 的 1500 Byte(注1)，但是分片会带来额外的消耗，使用 UDP 协议时需根据 MTU 设置包大小。

* 注1：1500 Byte 需要减去网络层 IP 协议使用的 20 Byte 与 UDP Header 使用的 8 Byte ，实际可负载的数据大小为 1472 Byte，如果是 PPPoE 网络 PPP Header 需要占用 8 Byte。

# 链路层

> 参考资料：
> * [Ethernet frame - Ethernet II](https://en.wikipedia.org/wiki/Ethernet_frame#Ethernet_II)
> * [Maximum transmission unit](https://en.wikipedia.org/wiki/Maximum_transmission_unit)

以太网的帧格式事实标准是 Ethernet II Type，在这个阶段会增加 14 Bytes 的 MAC Header 和 4 Byte 的 CRC Checksum。

# 计算

根据以上的所有信息计算请求流量和响应流量。

## 查询请求

以查询 `example.com` 的 A 记录为例进行计算。

* 应用层

查询的 `Message` 只有 `Header` 与 `Question` 两个部分，`Header` 长度固定为 12 Byte。`Question` 部分中 `QNAME` 因为 `example.com` 会被编码为 `7example3com0` 占用长度为 13 Byte，而 `QTYPE` 与 `QCLASS` 长度合计为 4 Byte，最终 DNS 应用层产生的数据大小为 27 Byte。

* 传输层

传输层使用 UDP 协议，因此需要增加 8 Byte UDP Header，这时的数据大小为 35 Byte。

* 网络层

网络层使用 IP 协议，增加 20 Byte IP Header，此时的数据大小为 55 Byte。

* 链路层

链路层使用 Ethernet II Type 帧格式封装，增加 14 Byte MAC Header 和 4 Byte 的 CRC Checksum，最终的数据为 73 Byte。

## 响应结果

为了方便计算，假设仅返回一条记录。

* 应用层

相对查询的 `Message` 增加了 `Answer` 部分，由 `Header`、`Question`、`Answer` 三个部分组成。因为 `Header` 与 `Question` 没有变化，因此只需要计算 `Answer` 的大小即可。

`NAME` 长度因为 `example.com` 已经在 `Question` 中出现过，因此为 2 Byte。`TYPE`、`CLASS`、`TTL` 与 `RDLENGTH` 为固定大小，合计为 10 Byte。A 记录的 `RDATA` 大小为 4 Byte，`Answer` 部分总大小为 16 Byte，DNS 应用层的数据大小为 43 Byte。

* 传输层

传输层使用 UDP 协议，因此需要增加 8 Byte UDP Header，这时的数据大小为 51 Byte。

* 网络层

网络层使用 IP 协议，增加 20 Byte IP Header，此时的数据大小为 71 Byte。

* 链路层

链路层使用 Ethernet II Type 帧格式封装，增加 14 Byte MAC Header 和 4 Byte 的 CRC Checksum，最终的数据为 89 Byte。

## 总结

对 `example.com` 的 A 记录进行一次查询，客户端会发出 73 Byte 的数据，接收 89 Byte 的数据，发出、接收各一个 UDP 包。

## 验证

可以使用抓包工具 [Wireshark](https://www.wireshark.org) 来进行验证，安装好 Wireshark 之后，设置过滤器为 `udp port 53` 进行抓包，由于 DNS 有缓存机制，推荐使用命令行工具发起 DNS 查询请求。

另外需要注意，根据官方文档 [7.10.2. Checksum offloading](https://www.wireshark.org/docs/wsug_html_chunked/ChAdvChecksums.html) 的说法，网卡驱动会将 CRC Checksum 的处理交给硬件完成，因此 Wireshark 无法获取到。

### 扩展内容

* [Microsoft Technet - Nslookup](https://technet.microsoft.com/en-us/library/cc940085.aspx)
* [dig(1) - Linux man page](https://linux.die.net/man/1/dig)
