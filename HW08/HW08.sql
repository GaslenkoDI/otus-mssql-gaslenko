/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "10 - Операторы изменения данных".
Задания выполняются с использованием базы данных WideWorldImporters.
Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak
Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/
INSERT INTO Purchasing.Suppliers
	  ([SupplierID]
      ,[SupplierName]
      ,[SupplierCategoryID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[SupplierReference]
      ,[BankAccountName]
      ,[BankAccountBranch]
      ,[BankAccountCode]
      ,[BankAccountNumber]
      ,[BankInternationalCode]
      ,[PaymentDays]
      ,[InternalComments]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy])

SELECT TOP 5 
	   [SupplierID]+10000
      ,[SupplierName]+' 1'
      ,[SupplierCategoryID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[SupplierReference]
      ,[BankAccountName]
      ,[BankAccountBranch]
      ,[BankAccountCode]
      ,[BankAccountNumber]
      ,[BankInternationalCode]
      ,[PaymentDays]
      ,[InternalComments]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy]
 FROM Purchasing.Suppliers


/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/
DELETE TOP (1) 
FROM Purchasing.Suppliers 
WHERE SupplierName LIKE '%1%' 

/*
3. Изменить одну запись, из добавленных через UPDATE
*/
UPDATE Purchasing.Suppliers 
SET 
	PhoneNumber='(360) 510-0100'
WHERE SupplierName LIKE '%Contoso, Ltd. 1%' 

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

MERGE Purchasing.Suppliers AS target
USING (SELECT * FROM Purchasing.Suppliers WHERE SupplierName LIKE '%1%') AS P
ON 
(target.SupplierName = P.SupplierName)
WHEN MATCHED 
	THEN UPDATE SET target.SupplierName = P.SupplierName + ' NEW_NAME' 
WHEN NOT MATCHED
	THEN INSERT (
	   [SupplierID]
      ,[SupplierName]
      ,[SupplierCategoryID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[SupplierReference]
      ,[BankAccountName]
      ,[BankAccountBranch]
      ,[BankAccountCode]
      ,[BankAccountNumber]
      ,[BankInternationalCode]
      ,[PaymentDays]
      ,[InternalComments]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy])
	VALUES (
	   P.[SupplierID]+100000
      ,P.[SupplierName] + ' NEW_NAME'
      ,P.[SupplierCategoryID]
      ,P.[PrimaryContactPersonID]
      ,P.[AlternateContactPersonID]
      ,P.[DeliveryMethodID]
      ,P.[DeliveryCityID]
      ,P.[PostalCityID]
      ,P.[SupplierReference]
      ,P.[BankAccountName]
      ,P.[BankAccountBranch]
      ,P.[BankAccountCode]
      ,P.[BankAccountNumber]
      ,P.[BankInternationalCode]
      ,P.[PaymentDays]
      ,P.[InternalComments]
      ,P.[PhoneNumber]
      ,P.[FaxNumber]
      ,P.[WebsiteURL]
      ,P.[DeliveryAddressLine1]
      ,P.[DeliveryAddressLine2]
      ,P.[DeliveryPostalCode]
      ,P.[DeliveryLocation]
      ,P.[PostalAddressLine1]
      ,P.[PostalAddressLine2]
      ,P.[PostalPostalCode]
      ,P.[LastEditedBy]);


/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/
-- To allow advanced options to be changed.  
EXEC sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  

SELECT @@SERVERNAME

exec master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.InvoiceLines" out  "C:\Users\daniilig\Desktop\Обучение\otus-mssql-gaslenko\HW08\InvoiceLines1.txt" -T -w -t"@$$", -S ROCHWS1179\SQL2017'

drop table if exists [Sales].[InvoiceLines_BulkDemo]

CREATE TABLE [Sales].[InvoiceLines_BulkDemo](
	[InvoiceLineID] [int] NOT NULL,
	[InvoiceID] [int] NOT NULL,
	[StockItemID] [int] NOT NULL,
	[Description] [nvarchar](100) NOT NULL,
	[PackageTypeID] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[UnitPrice] [decimal](18, 2) NULL,
	[TaxRate] [decimal](18, 3) NOT NULL,
	[TaxAmount] [decimal](18, 2) NOT NULL,
	[LineProfit] [decimal](18, 2) NOT NULL,
	[ExtendedPrice] [decimal](18, 2) NOT NULL,
	[LastEditedBy] [int] NOT NULL,
	[LastEditedWhen] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Sales_InvoiceLines_BulkDemo] PRIMARY KEY CLUSTERED 
(
	[InvoiceLineID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [USERDATA]
) ON [USERDATA]
----



	BULK INSERT [WideWorldImporters].[Sales].[InvoiceLines_BulkDemo]
				   FROM "D:\1\InvoiceLines1.txt"
				   WITH 
					 (
						BATCHSIZE = 1000, 
						DATAFILETYPE = 'widechar',
						FIELDTERMINATOR = '@$$',
						ROWTERMINATOR ='\n',
						KEEPNULLS,
						TABLOCK        
					  );



select Count(*) from [Sales].[InvoiceLines_BulkDemo];

TRUNCATE TABLE [Sales].[InvoiceLines_BulkDemo];