title: SQL Server分区表操作记录
date: 2015-12-08 19:25:51
categories:
  - database
  - sqlserver
feature: /images/logo/sqlserver-logo.webp
tags:
  - sqlserver
  - 分区表
---
>###### 分区的优点

>　　通过对大型表或索引进行分区，可以具有以下可管理性和性能优点。

>　　可以快速、高效地传输或访问数据的子集，同时又能维护数据收集的完整性。 例如，将数据从 OLTP 加载到 OLAP 系统之类的操作仅需几秒钟即可完成，而如果不对数据进行分区，执行此操作需要几分钟或几小时。
您可以更快地对一个或多个分区执行维护操作。 这些操作的效率更高，因为它们仅针对这些数据子集，而非整个表。 例如，您可以选择在一个或多个分区中压缩数据，或者重新生成索引的一个或多个分区。
您可以根据经常执行的查询类型和硬件配置，提高查询性能。 例如，在两个或更多的已分区表中的分区列相同时，查询优化器可以更快地处理这些表之间的同等联接查询，因为可以联接这些分区本身。
当 SQL Server 针对 I/O 操作执行数据排序时，它会首先按分区对数据进行排序。 SQL Server 每次访问一个驱动器，这样可能会降低性能。 为了提高数据排序性能，可以通过设置 RAID 将多个磁盘中的分区数据文件条带化。

>　　这样一来，尽管 SQL Server 仍按分区对数据进行排序，但它可以同时访问每个分区的所有驱动器。
此外，您可以通过对在分区级别而不是整个表启用锁升级来提高性能。 这可以减少表上的锁争用。
SQL Server 2012 在默认情况下支持多达 15,000 个分区。

<!-- more -->

>###### 分区函数
>　　一种数据库对象，它定义如何根据某个列（称为分区列）的值将表或索引的行映射到一组分区。 也就是说，分区函数定义表将具有的分区数和分区边界的定义方式。 例如，假定一个包含销售订单数据的表，您可能需要
基于 datetime 列（如销售日期）将表划分为 12 个（按月）分区。

>###### 分区方案
　　将分区函数的分区映射到一组文件组的数据库对象。 在各个文件组上放置分区的主要原因是为了确保可以在分区上独立执行备份操作。 这是因为您可以在各个文件组上执行备份。
分区列

>　　分区函数对表或索引进行分区时所使用的表或索引列。 参与分区函数的计算列必须显式标记为 PERSISTED。 用作索引列时有效的所有数据类型都可以用作分区依据列，timestamp 除外。
无法指定 ntext、text、image、xml、varchar(max)、nvarchar(max) 或 varbinary(max) 数据类型。 此外，不能指定 Microsoft .NET Framework 公共语言运行时 (CLR) 用户定义类型和别名数据类型列。

>###### 非对齐的索引
　　独立于其相应的表进行分区的一种索引。 也就是说，索引具有不同的分区方案或者放置于不同于基表的单独文件组中。 在下列情况下，设计非对齐的分区索引可能会很有用：

>基表未分区

>　　索引键是唯一的，不包含表的分区依据列。

>　　您希望基表与使用不同联接列的多个表一起参与并置联接。

>分区排除

>　　查询优化器用来仅访问相关分区以便满足查询的筛选条件的过程。

###### 使用SQL语句创建分区表

**创建分区函数**

假设1,2,3,4共5个分区

使用 RANGE RIGHT 表示边界位置在右边，产生5个区间:

`小于1` `大于等于1，小于2` `大于等于2，小于3` `大于等于3，小于4` `大于等于4`

使用RANGE LEFT表示边界位置在左边，产生5个区间:

`小于等于1` `大于1，小于等于2` `大于2，小于等于3` `大于3，小于等于4` `大于4`
```
CREATE PARTITION FUNCTION PartitionFunction_Status(SMALLINT)
AS RANGE RIGHT 
FOR VALUES(1,2,3,4);
```

**创建分区方案**

如果不增加独立文件组，则指向文件组为 PRIMARY ,分区方案指向的文件组数量需要不少于分区函数的分区数量。
```
CREATE PARTITION SCHEME PartitionScheme_Status
AS
PARTITION PartitionFunction_Status
TO([FG_Status_01],[FG_Status_01],[FG_Status_01],[FG_Status_01],[FG_Status_01]);
```

**建立测试分区表 tbTable**

分区列不需要为主键，但是数据类型必须与分区方案引用的分区函数一致
```
CREATE TABLE tbTable (
col1 SMALLINT NOT NULL,
col2 VARCHAR(32))
ON PartitionScheme_Status(col1);
```
插入测试数据
```
INSERT INTO tbTable
VALUES (0,'A'),(1,'A'),(2,'A'),(3,'A'),(4,'A'),(5,'A');
```
查看各个分区的数据行数
```
SELECT $PARTITION.PartitionFunction_Status(col1) AS 'Partition Number',
MIN(col1) AS 'Min Status',
MAX(col1) AS 'Max Status',
COUNT(*) AS 'Rows In Partition'
FROM dbo.tbTable
GROUP BY $PARTITION.PartitionFunction_Status(col1);
```

```
SELECT *,$PARTITION.PartitionFunction_Status(col1) AS 'Partition Number' FROM tbTable;
```

###### 使用 SQL 语句修改分区表
* **增加表分区**

修改分区方案，增加文件组
```
ALTER PARTITION SCHEME PartitionScheme_Status NEXT USED [FG_Status_01];
```
* **增加表分区条件**

修改分区方案对应的分区函数，新增加使用 5 作为边界
```
ALTER PARTITION FUNCTION PartitionFunction_Status() SPLIT RANGE (5);
```
* **删除表分区** 

注意：分区方案指向的文件组数可以大于分区函数的分区数，因此不需要修改分区方案
``` 
ALTER PARTITION FUNCTION PartitionFunction_Status() MERGE RANGE (5);
```

同样使用语句查看修改后的数据分布情况
```
SELECT $PARTITION.PartitionFunction_Status(col1) AS 'Partition Number',
MIN(col1) AS 'Min Status',
MAX(col1) AS 'Max Status',
COUNT(*) AS 'Rows In Partition'
FROM dbo.tbTable
GROUP BY $PARTITION.PartitionFunction_Status(col1);
```

```
SELECT *,$PARTITION.PartitionFunction_Status(col1) AS 'Partition Number' FROM tbTable;
```
　　可以看到数据已经重新分布，原本属于5分区的数据到了新的6分区中。（由于数据会发生转移，如果新的分区使用的文件组不一样，则会造成数据需要进行实际物理转移。）将现有普通表的聚集索引指向分区方案，即可将普通表转换为分区表，但是需要注意，如果分区方案指向的文件组与原表文件组不一致，数据会发生转移，期间会锁住该表。将分区表转换为普通表，则需要做反操作，将指向分区方案的聚集索引与非聚集索引删除，重新建立聚集索引执行指向 PRIMARY 文件组。如果发生数据转移（不同文件组），期间会锁住该表。

　　可以先创建分区函数，然后使用以下的语句查询准备分区的表数据，查看分区后各个分区的数据行数，来确认实际使用的文件组数量，或者调整分区方案。
```
SELECT $PARTITION.PartitionFunction_Status(col1) AS 'Partition Number',
MIN(col1) AS 'Min Status',
MAX(col1) AS 'Max Status',
COUNT(*) AS 'Rows In Partition'
FROM dbo.tbTable
GROUP BY $PARTITION.PartitionFunction_Status(col1);
```