use WideWorldImporters;

--создаем файловую группу
ALTER DATABASE [WideWorldImporters] ADD FILEGROUP [TransactionTypeID]
GO

--добавляем файл БД

ALTER DATABASE [WideWorldImporters] ADD FILE 
( NAME = N'TransactionTypeID', FILENAME = N'C:\Users\daniilig\Desktop\Обучение\otus-mssql-gaslenko\HW19\TransactionTypeID.ndf' , 
SIZE = 109715KB , FILEGROWTH = 65536KB ) TO FILEGROUP [TransactionTypeID]
GO


--создаем функцию партиционирования по SalespersonID 
CREATE PARTITION FUNCTION [fnTransactionTypeIDPartition](int) AS RANGE RIGHT FOR VALUES
(10,11,12);																																																									
GO

-- партиционируем, используя созданную функцию
CREATE PARTITION SCHEME [schmTransactionTypeIDPartition] AS PARTITION [fnTransactionTypeIDPartition] 
ALL TO ([TransactionTypeID])
GO

--создаем секционированные таблицы
CREATE TABLE [Warehouse].[StockItemTransactions_TransactionTypeID](
	[StockItemTransactionID] [int] NOT NULL,
	[StockItemID] [int] NOT NULL,
	[TransactionTypeID] [int] NOT NULL,
	[CustomerID] [int] NULL,
	[InvoiceID] [int] NULL,
	[SupplierID] [int] NULL,
	[PurchaseOrderID] [int] NULL,
	[TransactionOccurredWhen] [datetime2](7) NOT NULL,
	[Quantity] [decimal](18, 3) NOT NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL,
) ON [schmTransactionTypeIDPartition]([TransactionTypeID])
 
ALTER TABLE [Warehouse].[StockItemTransactions_TransactionTypeID] ADD CONSTRAINT PK_StockItemTransactions_TransactionTypeID 
PRIMARY KEY CLUSTERED  (TransactionTypeID,StockItemTransactionID)
 ON [schmTransactionTypeIDPartition]([TransactionTypeID]);

GO

SELECT * INTO Warehouse.StockItemTransactionsPartitioned
FROM Warehouse.StockItemTransactions;

GO
INSERT INTO [Warehouse].[StockItemTransactions_TransactionTypeID]
           ([StockItemTransactionID]
           ,[StockItemID]
           ,[TransactionTypeID]
           ,[CustomerID]
           ,[InvoiceID]
           ,[SupplierID]
           ,[PurchaseOrderID]
           ,[TransactionOccurredWhen]
           ,[Quantity]
           ,[LastEditedBy]
           ,[LastEditedWhen])
SELECT [StockItemTransactionID]
      ,[StockItemID]
      ,[TransactionTypeID]
      ,[CustomerID]
      ,[InvoiceID]
      ,[SupplierID]
      ,[PurchaseOrderID]
      ,[TransactionOccurredWhen]
      ,[Quantity]
      ,[LastEditedBy]
      ,[LastEditedWhen]
  FROM [Warehouse].[StockItemTransactionsPartitioned]

 GO

--Проверяем все ли корректно отработало и партиционировались ли данные

select distinct t.name
from sys.partitions p
inner join sys.tables t
	on p.object_id = t.object_id
where p.partition_number <> 1

--смотрим как конкретно по диапазонам разделились данные
SELECT  $PARTITION.fnTransactionTypeIDPartition(TransactionTypeID) AS Partition
		, COUNT(*) AS [COUNT]
		, MIN(TransactionTypeID)
		, MAX(TransactionTypeID) 
FROM [Warehouse].[StockItemTransactions_TransactionTypeID]
GROUP BY $PARTITION.fnTransactionTypeIDPartition(TransactionTypeID) 
ORDER BY Partition ;  