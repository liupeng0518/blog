title: SQL Server查询结果的排序问题
date: 2015-12-08 19:25:51
categories:
  - database
  - sqlserver
feature: http://pic.tomczhen.com/sqlserver-logo.png@!title
tags:
  - sqlserver
---
　　一般在SQL语句中使用`ORDER BY`来进行排序,但没有使用`ORDER BY`时查询的结果的顺序是由什么决定的呢？

>集合

>　　元素列出的顺序不同，或者元素列表中有重复，都没有关系。比如：这三个集合 {2, 4}，{4, 2} 和 {2, 2, 4, 2} 是相同的，同样因为它们有相同的元素。


>堆

>　　堆是不含聚集索引的表。可在存储为堆的表上创建一个或多个非聚集索引。数据存储于堆中并且无需指定顺序。通常，数据最初以行插入表时的顺序存储，但数据库引擎可能会在堆中四处移动数据，以便高效地存储行；因此，无法预测数据顺序。

　　无索引的表连接查询有索引的表时，查询结果排序会被索引所影响，因此需要通过`ORDER BY`确定无索引表的顺序之后再进行连接查询，以保持无索引的表的原始顺序。

　　可以使用以下查询语句来保证查询结果的顺序
```
SELECT ROW_NUMBER() OVER ( ORDER BY ( SELECT 0 ) ) AS RowNum FROM Table
```