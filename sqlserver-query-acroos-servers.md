title: SQL Server跨服务器查询实例
date: 2015-12-08 19:25:51
categories:
  - database
  - sqlserver
feature: http://www.tomczhen.com/images/logo/sqlserver-logo.webp
tags:
  - sqlserver
---
**First:启用Ad Hoc Distributed Queries，考虑到安全问题非必要保持开启，在使用后可以关闭。**
```
exec sp_configure 'show advanced options',1
reconfigure
exec sp_configure 'Ad Hoc Distributed Queries',1
reconfigur
```
简单的查询例子
```
SELECT * FROM OPENDATASOURCE('SQLOLEDB', 'Data Source=192.168.1.144,9000;User ID=sa;Password=123').database.ower.table
```

实际跨服务器查询可以连接不同的数据库，比如MySQL，Oracle等数据库。

<!-- more -->

实例：使用Excel表格作为外部数据源，跨服务器外链接查询表格，最后将结果插入本地数据库。
```
USE School_MIS;
GO
--创建本地临时表
CREATE TABLE #temp_table_local ([单号] [nvarchar](255) NULL,
[部门] [nvarchar](255) NULL,
[条码号] [nvarchar](255) NULL,
[数量] [float] NULL,
[结算价] [float] NULL);

--从指定路径的Excel表格取数据，需要指定格式
INSERT #temp_table_local
select * from OPENDATASOURCE('Microsoft.Jet.OLEDB.4.0',
'Data Source=G:1.xls;--Excel表格所在路径
Extended Properties="Excel 8.0;HDR=YES;IMEX=1;"');

--插入到本地数据库ex_table表
INSERT dbo.ex_table
SELECT ex1_no,ex2_no
FROM OPENDATASOURCE('SQLOLEDB', 'Data Source=192.168.1.144,9000;User ID=sa;Password=123').database.dbo.ex_table
RIGHT OUTER JOIN #temp_table_local
ON ex1_no = #temp_table_local.单号 
AND ex2_no = #temp_table_local.条码号;

--删除临时表
DROP TABLE #temp_table_local;
```