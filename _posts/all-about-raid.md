title: RAID 资料整理与收集
date: 2018-01-02 22:25:00
categories:
  - Other
tags:
  - RAID
---
> 参考资料:
> * [Arch Linux Wiki - RAID](https://wiki.archlinux.org/index.php/RAID)
> * [Wikipedia - Standard RAID levels](https://en.wikipedia.org/wiki/Standard_RAID_levels)
>
> 磁盘阵列（Redundant Arrays of Independent Disks，RAID），有“独立磁盘构成的具有冗余能力的阵列”之意。 磁盘阵列是由很多价格较便宜的磁盘，以硬件（RAID卡）或软件（例如ZFS）形式组合成一个容量巨大的磁盘组，利用个别磁盘提供数据所产生加成效果提升整个磁盘系统效能。利用这项技术，将数据切割成许多区段，分别存放在各个硬盘上。 磁盘阵列还能利用同位检查（Parity Check）的观念，在数组中任意一个硬盘故障时，仍可读出数据，在数据重构时，将数据经计算后重新置入新硬盘中。
>
> **警告：尽管 RAID 可以预防数据丢失，但并不完全保证数据不会丢失，请在使用RAID的同时注意备份重要数据。**

RAID 的核心在于使用多个硬盘 (Array) 来提升容量 (Capacity) 和性能 (Performance), 使用额外的 (Redundant) 的硬盘来保证完整性 (Integrity)。

根据不同的性能和可靠性需求，有着不同的 RAID 级别，Storage Networking Industry Association (SNIA) 对 RAID 进行了[标准化工作](https://www.snia.org/tech_activities/standards/curr_standards/ddf)。

虽然 RAID 可以针对硬盘缺陷或故障提供保护或恢复方案，但无法应对灾难性故障造成的数据丢失，比如自然灾害、用户误操作、软件故障、恶意软件等。对于重要数据，**RAID 不能代替备份**。

<!-- more -->

# 实现方式

## Software RAID

最容易的实现方式，不需要专有的硬件或软件。操作系统可以通过以下几种方式对 RAID 进行管理：

* 使用抽象层（例如：[mdadm](https://wiki.archlinux.org/index.php/RAID#Installation)）
* 使用逻辑分卷管理器（例如：[LVM](https://wiki.archlinux.org/index.php/LVM)）
* 使用文件系统功能组件（例如：[ZFS](https://wiki.archlinux.org/index.php/ZFS)，[Btrfs](https://wiki.archlinux.org/index.php/Btrfs)）

软阵列实现需要额外消耗系统资源，并且有一些额外限制：不支持从软 RAID 0 或 RAID 5 引导系统。

## Hardware RAID

由专门的硬件设备对 RAID 进行管理，有专门的设备处理 RAID 逻辑处理运算，不占用主系统资源。需要在专门的固件管理界面配置 RAID，安装系统时也需要加载对应的驱动才能让硬件 RAID 控制器正常工作。
对于操作系统内核而言 RAID 配置是透明的——系统无法看到单个磁盘。

硬件阵列设备通常还有专门的缓存与电池模块，有更高的性能。

## Fake RAID

通常是由 BIOS 或主板集成实现的，RAID 控制逻辑是由 BIOS 选项或者 UEFI 的 SATA Driver固件中实现，不具有完整的硬阵列控制器功能。最常见的 Fake RAID 控制器是：[Intel Rapid Storage](https://en.wikipedia.org/wiki/Intel_Rapid_Storage_Technology)。

本质上仍然是软件实现的 RAID，但也有着硬 RAID 的特点——安装操作系统时需要加载对应的驱动程序，对操作系统内核而言 RAID 配置是透明的，因此没有软 RAID 的限制——可以实现在 RAID 磁盘上引导系统。不过由于Fake RAID 没有专门的缓存和独立运算单元，仍然需要消耗额外的系统资源，并且性能低于硬件 RAID。

# 标准 RAID 级别 (Standard RAID levels)

![](/images/2018/raid_ddf_example.webp)

根据 [Common RAID Disk Data Format (DDF) Specification v2.0 ](https://www.snia.org/sites/default/files/SNIA_DDF_Technical_Position_v2.0.pdf) 中的定义可以发现，标准 RAID 中，存储最终映射到 Stripe，Stripe 横跨所有的物理磁盘 。而 Stripe 则由 Strip 组成，Strip 中可以保存数据块（Data blocks）与校验块（Parity blocks）。最终根据不同组成方案形成了不同的 RAID 级别。

## 标准 RAID 比较表

| RAID 级别 | 最少磁盘 | 最大容错 | 可用容量 | 读取性能 | 写入性能 | 可用性 |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 单一磁盘 | - | 0 | 1 | 1 | 1 | 无 |
| JBOD | 1 | 0 | n | 1 | 1 | 无 |
| RAID 0 | 2 | 0 | n | n | n | 无 |
| RAID 1 | 2 | n-1 | 1 | n | 1 | 最高 |
| RAID 5 | 3 | 1 | n-1 | n-1 | n-1 | 高 |
| RAID 6 | 4 | 2 | n-2 | n-2 | n-2 | 高于 RAID5 |

*n 表示磁盘总数量，读写性能为理论最佳性能*

### RAID 0

![](/images/2018/RAID_0.webp)

RAID 0 并不是真正的RAID结构，没有数据冗余，没有数据校验的磁盘陈列。实现RAID 0至少需要两块以上的硬盘，它将两块以上的硬盘合并成一块，数据连续地分割在每块盘上。
因为带宽加倍，所以读/写速度加倍， 但RAID 0在提高性能的同时，并没有提供数据保护功能，只要任何一块硬盘损坏就会丢失所有数据。因此RAID 0 不可应用于需要数据高可用性的关键领域。

### RAID 1

![](/images/2018/RAID_1.webp)

RAID 1 是将一个两块或以上N个磁盘所构成 RAID 磁盘阵列，其容量仅等于一块磁盘（最小容量）的容量，因为所有的磁盘是互相作为镜像。RAID 1 磁盘阵列显然是最可靠的一种阵列，因为它总是保持一份完整的数据备份。在一些多线程操作系统中能有很好的读取速度，理论上读取速度等于硬盘数量的倍数，与RAID 0相同。RAID 1 磁盘阵列的写入速度通常较慢，因为数据得分别写入多块磁盘中并做比较。RAID 1 磁盘阵列一般支持“热交换”，就是说阵列中硬盘的移除或替换可以在系统运行时进行，无须中断退出系统。RAID 1 磁盘阵列是十分安全的，不过也是较贵一种 RAID 磁盘阵列解决方案，因为多块硬盘仅能提供一块硬盘的容量。RAID 1 磁盘阵列主要用在数据安全性很高，而且要求能够快速恢复被破坏的数据的场合。

### RAID 5

![](/images/2018/RAID_5.webp)

RAID 5 是一种存储性能、数据安全和存储成本兼顾的存储解决方案。
RAID 5 可以理解为是 RAID 0 和 RAID 1 的折中方案。RAID 5 可以为系统提供数据安全保障，但保障程度要比 Mirror 低而磁盘空间利用率要比 Mirror 高。RAID 5具有和RAID 0相近似的数据读取速度，只是多了一个奇偶校验信息，写入数据的速度比对单个磁盘进行写入操作稍慢，若使用“回写缓存”可以让性能改善不少。同时由于多个数据对应一个奇偶校验信息，RAID 5 的磁盘空间利用率要比 RAID 1 高，存储成本相对较低。
> Note: 尽管 RAID 5 是数据安全与 I/O 速度的权衡，但是由于其工作方式，在大于 4Tb 的场合下，磁盘故障发生后，数据重建的难度将大大增加。所以存储行业并不建议使用 RAID 5，有被 RAID 6 取代的趋势。

### RAID 6

![](/images/2018/RAID_6.webp)

RAID 6 技术是在 RAID 5 基础上，为了进一步加强数据保护而设计的一种 RAID 方式，实际上是一种扩展RAID 5等级。
与 RAID 5 的不同之处于除了每个硬盘上都有同级数据 XOR 校验区外，还有一个针对每个数据块的 XOR 校验区。当然，当前盘数据块的校验数据不可能存在当前盘而是交错存储的。这样一来，等于每个数据块有了两个校验保护屏障（一个分层校验，一个是总体校验），因此 RAID 6 的数据冗余性能相当好。但是，由于增加了一个校验，所以写入的效率较 RAID 5 还差，而且控制系统的设计也更为复杂，第二块的校验区也减少了有效存储空间。
> Note: 组成 RAID 6 阵列需要至少四块磁盘。

## RAID Write Hole

> 参考资料: ["Write hole" phenomenon](http://www.raid-recovery-guide.com/raid5-write-hole.aspx)

根据 DFF 中的 RAID 结构说明可以看出，可能发生数据块 Strip 写入后校验块 Strip 并没有完成更新的情况（硬件故障、电源故障、缓存丢失）。此时，如果同一 Stripe 上其 Strip 的数据块发生丢失或错误，会需要根据校验块计算出数据块，这时无法得到正确的数据。
为了解决 Write Hole 问题，通常 RAID 系统都有 SYNC 功能，用于检查 RAID 中所有的 Stripe 并进行数据一致性修复。虽然 SYNC 功能可以在事后处理 Write Hole 造成的数据问题，但仍然无法完全避免数据错误或丢失。

解决 Write Hole 问题，可以使用 [CoW](https://en.wikipedia.org/wiki/Copy-on-write) 机制来保证写入事件的原子性，但这需要文件系统的支持（例如：[ZFS](https://wiki.archlinux.org/index.php/ZFS)）。
通常的做法是通过硬件阵列卡附带额外的非易失内存（即带缓存和电池）来避免问题产生，因此使用 RAID 5/6 时需要配置 UPS 电源，并且选择带电池和缓存的硬件阵列卡，除了能保证数据安全也有利于读写提高性。

# 混合/嵌套 RAID (Nested/Hybrid RAID levels)

RAID 不但可以创建在裸盘上, 还可以创建在其他 RAID 上。为了平衡性能 （Performance） 和可靠性（Reliability）, 往往会创建嵌套 RAID, 比如说先创建多个 RAID 1, 然后再通过 RAID 0 组合起来。

## 混合/嵌套 RAID 比较表

| RAID 类型 | 最少磁盘 | 最大容错 | 可用容量 | 读取性能 | 写入性能 |
| :---: | :---: | :---: | :---: | :---: | :---: |
| RAID 01 | 4 | 2 | n/2 | n | n/2 |
| RAID 10 | 4 | 2 | n/2 | n | n/2 |
| RAID 50 | 6 | 2 | n-m | n-m | n-m |
| RAID 60 | 8 | 4 | n-2m | n-2m | n-2m |
| RAID 100 | 8 | 4 | n/2 | n | n/2 |

*n 表示磁盘总数量，m 表示子 RAID 数，读写性能为理论最佳性能*

### RAID 01

![](/images/2018/RAID_01.webp)

### RAID 10

![](/images/2018/RAID_10.webp)

#### RAID 01 vs RAID 10

RAID 10 是先镜射再分区数据，再将所有硬盘分为两组，视为是 RAID 0 的最低组合，然后将这两组各自视为 RAID 1 运作。RAID 01 则是跟RAID 10 的程序相反，是先分区再将数据镜射到两组硬盘。它将所有的硬盘分为两组，变成 RAID 1 的最低组合，而将两组硬盘各自视为 RAID 0 运作。
当 RAID 10 有一个硬盘受损，其余硬盘会继续运作。RAID 01 只要有一个硬盘受损，同组 RAID 0 的所有硬盘都会停止运作，只剩下其他组的硬盘运作，可靠性较低。

* RAID 01 出现一块磁盘故障时，故障磁盘所在的子 RAID 0 将停止运作，即同组下的其他磁盘其实是不工作的。此时，新的故障磁盘必然出现在另一个子 RAID 0 中，RAID 阵列就会失效造成数据丢失。

* RAID 10 出现一块磁盘故障时，故障磁盘所在的子 RAID 1 会继续运作，所有子 RAID 1 组中只要有一块磁盘正常工作，整个 RAID 阵列就不会失效造成数据丢失。

## RAID 50

![](/images/2018/RAID_50.webp)

## RAID 60

![](/images/2018/RAID_60.webp)

## RAID 100

![](/images/2018/RAID_100.webp)

# Rebuild 风险

当 RAID 阵列中的磁盘出现降级或者故障时就需要更换磁盘，这个时候需要进行 Rebuild 来对新磁盘写入数据。
Rebuild 所需要的时间取决于数据的大小与单块磁盘的性能，可以预见的是 TB 级数据使用机械硬盘 Rebuild 时间都最少都需要按小时，甚至按天计算。而Rebuild 时 RAID 是处于降级状态，并且性能会受到影响，在生产环境下考虑到不能进行停机，实际所需要的时间只会更长。

当数据规模过大时 RAID 会有无法解决的问题与风险存在，需要根据业务情况重新设计存储。

# IO 性能量化与计算

> 参考资料：[Wikipedia - IOPS](https://zh.wikipedia.org/wiki/IOPS)
>
> IOPS（Input/Output Operations Per Second）是一个用于电脑存储设备（如硬盘（HDD）、固态硬盘（SSD）或存储区域网络（SAN））性能测试的量测方式，可以视为是每秒的读写次数。和其他性能测试一様，存储设备制造商提出的IOPS不保证就是实际应用下的性能。
>
> IOPS 可以用应用程序来量测，例如 [Iometer](http://www.iometer.org/)，IOPS 主要会用在评估服务器，以找到最佳的存储配置。
>
> IOPS 的数值会随系统配置而有很大的不同，依测试者在测试时的控制变因而异，控制变因包括读取及写入的比例、其中循序访问及随机存取的比例及配置方式、线程数量及访问队列深度，以及数据区块的大小。其他因素也会影响IOPS的结果，例如系统设置、存储设备的驱动程序、操作系统后台运行的作业等。若在测试固态硬盘时，是否先进行预调（preconditioning）机制也会影响IOPS的结果。

机械硬盘读取和写入的 IOPS 大约相同，而大部分闪存SSD的写入速度明显比读要慢很多，原因是无法写入一个之前写过的区域，会强制引导垃圾数据回收功能。

关于 RAID 性能计算与 IOPS 换算可以利用下面两个在线工具进行计算。

* [RAID Performance Calculator](http://wintelguy.com/raidperf.pl)

* [IOPS, MB/s, GB/day Converter](http://wintelguy.com/iops-mbs-gbday-calc.pl)

## 机械硬盘

| 设备类型 | IOPS(4KB block, random) |
| :---: | :---: |
| 7,200 RPM SATA 硬盘| 73 - 79 |
| 10,000 RPM SATA 硬盘 | 125 - 150 |
| 10,000 RPM SAS 硬盘 | 142 - 150 |
| 15,000 RPM SAS 硬盘 | 	188 - 203 |

随机读写处理下，机械硬盘 IOPS 计算方式是 1000ms/(旋转延迟 + 寻道时间 + 传输时间)。磁头延迟取决于盘片的 RPM，由于接口速率大大高于单次读写的数据，因此传输时间可以忽略不计。

## 固态硬盘

优势：

* 非常高的随机读写 IOPS
* 非常高的读吞吐能力
* 响应时间短、延迟低

缺点：

* 顺序 IO 与 SAS 硬盘 RAID 差距较小，但成本高得多
* 在高压力的连续写入业务时性能可能会降低
* 由于闪存的平衡磨损设计，一个 RAID 阵列中的固态硬盘寿命都是相近的，有几率出现多块固态硬盘同时损坏造成数据丢失

*注：机械硬盘也有这种情况存在，同批次的产品寿命大都是相近的，在平均损耗的情况下出现故障的时间也是相近的。*

## RAID 写入惩罚

> 参考资料：[浅谈RAID写惩罚（Write Penalty）与IOPS计算](https://community.emc.com/docs/DOC-26624)

以 RAID 5 为例，当写入数据是一个完整的 Stripe 时，只需要额外写入一个 Strip 作为校验数据即可，也就是额外增加一个 IO 操作。当写入数据不是一个完整的 Stripe 时，需要先读取 Strip 的数据块与校验块，根据新数据块计算出新的校验块后再写入 Strip，也就是写入一个 Strip 时总共需要四次 IO 操作，这就是 RAID 的写入惩罚。
存储设备的 Cache 可以将小 IO 合并为大 IO，尽量做到每个写入都是一个完整的 Stripe。对于顺序 IO 实际的写入惩罚达不到理论数值，但对于随机 IO （OLTP 数据库）是无法保证达到同样的效果的，即无法保证缓存的命中率。

IOPS 作为存储设备的性能指标，通常厂家在标称最大 IOPS 时会使用 100% 命中缓存的数据，根据业务不同，实际有效的 IOPS 会小于厂家标称数据。

## 典型应用类型的 IO 特性

> 参考资料：
> * [不同RAID级别对性能和容量影响](http://support.huawei.com/huaweiconnect/enterprise/thread-371019-1-1.html)
> * [关于不同应用程序存储IO类型的描述](https://community.emc.com/docs/DOC-26547)

通常把<=16KB的IO认为是小IO（典型的如512bytes、4KB），而>=32KB的IO认为是大IO（典型的如256KB、1MB），处于16K和32K间的IO也认为是小IO。

| 应用类型 | IO 类型 | IO 大小 | 读写比例 |
| :---: | :---: | :---: | :---: |
| Web File Server | 75%随机/25%顺序 | 4KB、8KB、64KB | 95%读/5%写 |
| Web Server Log | 100%顺序 | 8KB | 100% Write |
| Media Streaming | 100%顺序  | 64KB | 98%读/2%写 |
| OLTP - Data | 100%随机 | 8KB | 75%读/25%写 |
| OLTP - Log | 100%顺序 | 512bytes - 64KB | 100%写 |
| OLAP - Data | - | 64KB - 512KB | 95%读/5%写 |

*注: 数据库应用的 IO 大小取决于数据库应用的设计，应根据实际情况确定 IO 大小。*
