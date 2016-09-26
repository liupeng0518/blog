title: SQL Server 批量重命名主键、外键、默认约束、索引 SQL 脚本
date: 2016-07-18 10:45:00
categories: 
  - database
feature: /images/logo/sqlserver-logo.webp
tags: 
  - sqlserver
toc: true
---

<h2 id="readme">说明</h2>

使用 SQL Server Management Studio 添加主键、外键、约束和索引时默认命名方式会增加一些随机编码，或者修改后忘记修改名称，造成命名与实际情况不符或者不直观的情况。
所以写了一个批量重命名的脚本解决这个问题。

<!-- more -->

---

<h3 id="code">脚本代码</h3>

```sql
/*
前缀说明

IX	聚集索引	
NIX	非聚集索引 
UIX	唯一，聚集索引 
UNIX唯一，非聚集索引
DF	默认约束	
UQ	唯一约束	
CK	CHECK约束	
FK	外键约束

命名方式为：前缀_表名_列名

2015-08-14
删除order by减少资源消耗

增加名称区分大小写
增加CHECK约束重命名
增加外键约束重命名

修正唯一约束识别为非聚集索引的问题
说明:唯一约束会隐式的创建一个唯一非聚集索引

修正因XML索引引起的报错问题
说明:先过滤掉XML类型索引

修正多schema下生成的语句重命名失败的问题

2016-02-27
修正聚集索引超过2个时因排序问题引起索引名错误的情况
*/

DECLARE @schemaName VARCHAR(256) = '';
DECLARE @tableName VARCHAR(256) = '';
DECLARE @indexName VARCHAR(256) = '';
DECLARE @colName VARCHAR(256) = '';
DECLARE @indexID SMALLINT;
DECLARE @colSeq SMALLINT;
DECLARE @isUnique SMALLINT;
DECLARE @isPK SMALLINT;
DECLARE @IndexType SMALLINT;
DECLARE @preIndexName VARCHAR(256) = '';
DECLARE @preTableName VARCHAR(256) = '';
DECLARE @newIndexName VARCHAR(256) = '';

DECLARE @preConName VARCHAR(256)= '';
DECLARE @newConName VARCHAR(256) = '';
DECLARE @prefix VARCHAR(32) = '';

--索引/唯一约束
DECLARE indexCur CURSOR
FOR
  SELECT  SCHEMA_NAME(tb.schema_id) AS schemaName ,
          tb.name AS tableName ,
          ix.name AS indexName ,
          c.name AS colName ,
          ix.index_id AS IndexID ,
          ixc.key_ordinal AS colSeq ,
          ix.is_unique AS isUnique ,
          ix.is_primary_key AS isPK ,
            ix.[type] AS IndexType
    FROM    sys.tables AS tb
            LEFT OUTER JOIN sys.indexes AS ix ON tb.object_id = ix.object_id
            LEFT OUTER JOIN sys.index_columns AS ixc ON ix.object_id = ixc.object_id
                                                        AND ix.index_id = ixc.index_id
            LEFT OUTER JOIN sys.columns AS c ON tb.object_id = c.object_id
                                                AND ixc.column_id = c.column_id
    WHERE   ix.name IS NOT NULL
            AND ixc.is_included_column = 0	--排除索引包含列	
            AND ixc.partition_ordinal = 0	--排除分区函数隐藏索引
            AND tb.type = 'U'				--限制为用户表
            AND ix.[type] BETWEEN 1 AND 2
    ORDER BY tb.name ,
            ixc.key_ordinal;
	--排除XML索引类型
 
OPEN indexCur;
FETCH NEXT FROM indexCur
			   INTO @schemaName, @tableName, @indexName, @colName, @indexID,
    @colSeq, @isUnique, @isPK, @IndexType;
 
WHILE @@FETCH_STATUS = 0
    BEGIN	       
        IF @colSeq = 1
            BEGIN
                IF @preIndexName <> ''
                    AND @newIndexName COLLATE Chinese_PRC_CS_AI <> @preIndexName COLLATE Chinese_PRC_CS_AI
                    BEGIN                
                        PRINT 'EXEC SP_RENAME N''' + @schemaName + '.'
                            + @preTableName + '.' + @preIndexName + ''', N'''
                            + @newIndexName + ''';';
                        SET @preIndexName = '';
                    END;             
            
                SELECT  @preIndexName = @indexName ,
                        @preTableName = @tableName;
                     
                IF EXISTS ( SELECT  *
                            FROM    sys.objects
                            WHERE   type = 'UQ'
                                    AND name = @preIndexName )
                    SET @prefix = 'UQ_';
                ELSE
                    IF @isPK = 1
                        SET @prefix = 'PK_';	--主键生成的索引名与主键命名一致
                    ELSE
                        SET @prefix = CASE @isUnique
                                        WHEN 1 THEN 'U'
                                        ELSE ''
                                      END + CASE @IndexType
                                              WHEN 1 THEN ''
                                              WHEN 2 THEN 'N'
                                              ELSE ''
                                            END + 'IX_';
                                          
                SET @newIndexName = @prefix + @tableName + '_' + @colName;
                FETCH NEXT FROM indexCur
						INTO @schemaName, @tableName, @indexName, @colName,
                    @indexID, @colSeq, @isUnique, @isPK, @IndexType;
            END;
               
        IF @colSeq > 1
            BEGIN             
                SET @newIndexName = @newIndexName + '_' + @colName;
                FETCH NEXT FROM indexCur
						INTO @schemaName, @tableName, @indexName, @colName,
                    @indexID, @colSeq, @isUnique, @isPK, @IndexType;
            END;

    END;

CLOSE indexCur;
DEALLOCATE indexCur;
 
IF @newIndexName COLLATE Chinese_PRC_CS_AI <> @preIndexName COLLATE Chinese_PRC_CS_AI
    PRINT 'EXEC SP_RENAME N''' + @schemaName + '.' + @preTableName + '.'
        + @preIndexName + ''', N''' + @newIndexName + ''';';

--默认约束
DECLARE dfCur CURSOR
FOR
    SELECT  SCHEMA_NAME(tb.schema_id) AS schemaName ,
            tb.name AS tableName ,
            col.name AS colName ,
            dc.name AS DFName
    FROM    sys.tables AS tb
            LEFT OUTER JOIN sys.default_constraints AS dc ON tb.object_id = dc.parent_object_id
            LEFT OUTER JOIN sys.columns AS col ON col.object_id = dc.parent_object_id
                                                  AND col.column_id = dc.parent_column_id
    WHERE   dc.name IS NOT NULL
            AND tb.type = 'U';
	--限制为用户表
OPEN dfCur;
FETCH NEXT FROM dfCur
INTO @schemaName, @tableName, @colName, @preConName;
WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @newConName = 'DF_' + @tableName + '_' + @colName;
        IF @preConName COLLATE Chinese_PRC_CS_AI <> @newConName COLLATE Chinese_PRC_CS_AI
            PRINT 'EXEC SP_RENAME N''' + @schemaName + '.' + @preConName
                + ''', N''' + @newConName + ''';';
        FETCH NEXT FROM dfCur
INTO @schemaName, @tableName, @colName, @preConName;
    END;
CLOSE dfCur;
DEALLOCATE dfCur;

--CHECK约束
DECLARE ckCur CURSOR
FOR
    SELECT  SCHEMA_NAME(tb.schema_id) AS schemaName ,
            tb.name AS tableName ,
            col.name AS colName ,
            cc.name AS DFName
    FROM    sys.tables AS tb
            LEFT OUTER JOIN sys.check_constraints AS cc ON tb.object_id = cc.parent_object_id
            LEFT OUTER JOIN sys.columns AS col ON col.object_id = cc.parent_object_id
                                                  AND col.column_id = cc.parent_column_id
    WHERE   cc.name IS NOT NULL
            AND tb.type = 'U';
 --限制为用户表
OPEN ckCur;
FETCH NEXT FROM ckCur
INTO @schemaName, @tableName, @colName, @preConName;
WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @newConName = 'CK_' + @tableName + '_' + @colName;
        IF @preConName COLLATE Chinese_PRC_CS_AI <> @newConName COLLATE Chinese_PRC_CS_AI
            PRINT 'EXEC SP_RENAME N''' + @schemaName + '.' + @preConName
                + ''', N''' + @newConName + ''';';
        FETCH NEXT FROM ckCur
				INTO @schemaName, @tableName, @colName, @preConName;
    END;
CLOSE ckCur;
DEALLOCATE ckCur;

--外键约束
DECLARE fkCur CURSOR
FOR
    SELECT  SCHEMA_NAME(fkTable.schema_id) AS schema_name ,
            fkTable.name AS FKTableName ,
            fkCol.name AS FKColName ,
            pkTable.name AS PKTableName ,
            pkCol.name AS PKColName ,
            OBJECT_NAME(col.constraint_object_id) AS FKConName
    FROM    sys.foreign_key_columns col
            INNER JOIN sys.objects fkTable ON fkTable.object_id = col.parent_object_id
            INNER JOIN sys.columns fkCol ON fkCol.column_id = col.parent_column_id
                                            AND fkCol.object_id = fkTable.object_id
            INNER JOIN sys.objects pkTable ON pkTable.object_id = col.referenced_object_id
            INNER JOIN sys.columns pkCol ON pkCol.column_id = col.referenced_column_id
                                            AND pkCol.object_id = pkTable.object_id;

DECLARE @FKTableName NVARCHAR(64);
DECLARE @FKColName NVARCHAR(64);
DECLARE @PKTableName NVARCHAR(64);
DECLARE @PKColName NVARCHAR(64);
OPEN fkCur;
FETCH NEXT FROM fkCur
INTO @schemaName, @FKTableName, @FKColName, @PKTableName, @PKColName,
    @preConName;

WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @newConName = 'FK_' + @FKTableName + '_' + @FKColName + '_ON_'
            + @PKTableName + '_' + @PKColName;
        IF @preConName COLLATE Chinese_PRC_CS_AI <> @newConName COLLATE Chinese_PRC_CS_AI
            PRINT 'EXEC SP_RENAME N''' + @schemaName + '.' + @preConName
                + ''', N''' + @newConName + ''';';
        FETCH NEXT FROM fkCur
				INTO @schemaName, @FKTableName, @FKColName, @PKTableName,
            @PKColName, @preConName;
    END;
CLOSE fkCur;
DEALLOCATE fkCur;
```

<h3 id="howto">使用说明</h3>

在对应数据库中执行脚本，会输出修改语句，检查修改语句确认后执行即可。需要注意，由于是架构修改，因此在生产环境需要注意死锁问题。

---

<div align="center">
![](/images/logo/alipay_tomczhen.webp)  
如果对您有帮助的话，可以考虑通过支付宝请作者喝杯咖啡。
</div>
