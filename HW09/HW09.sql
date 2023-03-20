/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.
������� "08 - ������� �� XML � JSON �����".
������� ����������� � �������������� ���� ������ WideWorldImporters.
����� �� ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
����� WideWorldImporters-Full.bak
�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
���������� � �������� 1, 2:
* ���� � ��������� � ���� ����� ��������, �� ����� ������� ������ SELECT c ����������� � ���� XML. 
* ���� � ��� � ������� ������������ �������/������ � XML, �� ������ ����� ���� XML � ���� �������.
* ���� � ���� XML ��� ����� ������, �� ������ ����� ����� �������� ������ � ������������� �� � ������� (��������, � https://data.gov.ru).
* ������ ��������/������� � ���� https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. � ������ �������� ���� ���� StockItems.xml.
��� ������ �� ������� Warehouse.StockItems.
������������� ��� ������ � ������� ������� � ������, ������������ Warehouse.StockItems.
����: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 
��������� ��� ������ � ������� Warehouse.StockItems: 
������������ ������ � ������� ��������, ������������� �������� (������������ ������ �� ���� StockItemName). 
������� ��� ��������: � ������� OPENXML � ����� XQuery.
*/
/*������� 1. OPENXML*/
DROP TABLE IF EXISTS #StockItems
CREATE TABLE #StockItems
(
	 StockItemName nvarchar(100) COLLATE Latin1_General_100_CI_AS 
	,SupplierID int
	,UnitPackageID int
	,OuterPackageID int
	,QuantityPerOuter int
	,TypicalWeightPerUnit decimal(18, 3)
	,LeadTimeDays int 
	,IsChillerStock bit 
	,TaxRate decimal(18, 3)
	,UnitPrice decimal(18, 2) 
)


DECLARE @docHandle int
DECLARE @xmlDocument  xml

SELECT @xmlDocument = BulkColumn
FROM OPENROWSET
(BULK 'C:\Users\olgaasu\Documents\StockItems.xml', 
 SINGLE_CLOB)
as data
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument

INSERT INTO #StockItems
SELECT *
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
		[StockItemName]			nvarchar(100)	'@Name',
		[SupplierID]			int				'SupplierID',
		[UnitPackageID]			int				'Package/UnitPackageID',
		[OuterPackageID]		int				'Package/OuterPackageID',
		[QuantityPerOuter]		int				'Package/QuantityPerOuter',
		[TypicalWeightPerUnit]  decimal(18, 3)  'Package/TypicalWeightPerUnit',
		[LeadTimeDays]		    int				'LeadTimeDays',
		[IsChillerStock]		bit				'IsChillerStock',
		[TaxRate]		        decimal(18, 3)  'TaxRate',
		[UnitPrice]		        decimal(18, 2)  'UnitPrice')

/*������� 2. XQuery*/
DECLARE @x XML
SET @x = ( 
  SELECT * FROM OPENROWSET
  (BULK 'C:\Users\olgaasu\Documents\StockItems.xml',
   SINGLE_CLOB) as d)

SELECT  
  t.StockItem.value('(@Name)', 'nvarchar(100)')							   as [StockItemName],
  t.StockItem.value('(SupplierID)[1]', 'int')							   as [SupplierID],
  t.StockItem.value('(Package/UnitPackageID)[1]', 'int')				   as [UnitPackageID],
  t.StockItem.value('(Package/OuterPackageID)[1]', 'int')				   as [OuterPackageID],
  t.StockItem.value('(Package/QuantityPerOuter)[1]', 'int')				   as [QuantityPerOuter],
  t.StockItem.value('(Package/TypicalWeightPerUnit)[1]', 'decimal(18, 3)') as [TypicalWeightPerUnit],
  t.StockItem.value('(LeadTimeDays)[1]', 'int')							   as [LeadTimeDays],
  t.StockItem.value('(IsChillerStock)[1]', 'bit')						   as [IsChillerStock],
  t.StockItem.value('(TaxRate)[1]', 'decimal(18, 3)')					   as [TaxRate],
  t.StockItem.value('(UnitPrice)[1]', 'decimal(18, 2)')					   as [UnitPrice]
  --t.StockItem.query('.')
FROM @x.nodes('/StockItems/Item') as t(StockItem)

GO

/*Merge*/
MERGE Warehouse.StockItems AS target
USING (SELECT * FROM #StockItems) AS S
ON 
(	 target.SupplierID = S.SupplierID
 AND target.UnitPackageID = S.UnitPackageID
 AND target.OuterPackageID = S.OuterPackageID
 AND target.StockItemName = S.StockItemName)
WHEN MATCHED AND StockItemID IS NOT NULL
	THEN UPDATE SET  
                     target.QuantityPerOuter = S.QuantityPerOuter
                    ,target.TypicalWeightPerUnit = S.TypicalWeightPerUnit
                    ,target.IsChillerStock = S.IsChillerStock
                    ,target.TaxRate = S.TaxRate
                    ,target.UnitPrice = S.UnitPrice
WHEN NOT MATCHED 
	THEN INSERT (
	[StockItemName],
	[SupplierID],
	[UnitPackageID],
	[OuterPackageID],
	[QuantityPerOuter],
	[TypicalWeightPerUnit],
	[LeadTimeDays],
	[IsChillerStock],
	[TaxRate],
	[UnitPrice],
	[LastEditedBy])
VALUES (
	S.[StockItemName],
	S.[SupplierID],
	S.[UnitPackageID],
	S.[OuterPackageID],
	S.[QuantityPerOuter],
	S.[TypicalWeightPerUnit],
	S.[LeadTimeDays],
	S.[IsChillerStock],
	S.[TaxRate],
	S.[UnitPrice],
	1 );
/*
2. ��������� ������ �� ������� StockItems � ����� �� xml-����, ��� StockItems.xml
*/

SELECT 
		[StockItemName]			AS  [@Name],
		[SupplierID]			AS	[SupplierID],
		[UnitPackageID]			AS	[Package/UnitPackageID],
		[OuterPackageID]		AS	[Package/OuterPackageID],
		[QuantityPerOuter]		AS	[Package/QuantityPerOuter],
		[TypicalWeightPerUnit]  AS  [Package/TypicalWeightPerUnit],
		[LeadTimeDays]		    AS	[LeadTimeDays],
		[IsChillerStock]		AS	[IsChillerStock],
		[TaxRate]		        AS  [TaxRate],
		[UnitPrice]		        AS  [UnitPrice]
FROM Warehouse.StockItems
WHERE StockItemName in (
'"The Gu" red shirt XML tag t-shirt (Black) 3XXL',
'Developer joke mug (Yellow)',
'Dinosaur battery-powered slippers (Green) L',
'Dinosaur battery-powered slippers (Green) M',
'Dinosaur battery-powered slippers (Green) S',
'Furry gorilla with big eyes slippers (Black) XL',
'Large  replacement blades 18mm',
'Large sized bubblewrap roll 50m',
'Medium sized bubblewrap roll 20m',
'Shipping carton (Brown) 356x229x229mm',
'Shipping carton (Brown) 356x356x279mm',
'Shipping carton (Brown) 413x285x187mm',
'Shipping carton (Brown) 457x279x279mm',
'USB food flash drive - sushi roll',
'USB missile launcher (Green)')
ORDER BY StockItemName
FOR XML PATH('Item'), ROOT('StockItems')
GO

/*
3. � ������� Warehouse.StockItems � ������� CustomFields ���� ������ � JSON.
�������� SELECT ��� ������:
- StockItemID
- StockItemName
- CountryOfManufacture (�� CustomFields)
- FirstTag (�� ���� CustomFields, ������ �������� �� ������� Tags)
*/

SELECT
		StockItemID,
		StockItemName,
		JSON_VALUE(CustomFields, '$.CountryOfManufacture') as CountryOfManufacture,
		JSON_VALUE(CustomFields, '$.Tags[1]') as FirstTag

FROM Warehouse.StockItems

/*
4. ����� � StockItems ������, ��� ���� ��� "Vintage".
�������: 
- StockItemID
- StockItemName
- (�����������) ��� ���� (�� CustomFields) ����� ������� � ����� ����
���� ������ � ���� CustomFields, � �� � Tags.
������ �������� ����� ������� ������ � JSON.
��� ������ ������������ ���������, ������������ LIKE ���������.
������ ���� � ����� ����:
... where ... = 'Vintage'
��� ������� �� �����:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/


SELECT 
		StockItemID,
		StockItemName,
		JSON_QUERY(CustomFields, '$.Tags') as Tags,
		sites.[value]

FROM Warehouse.StockItems WS
CROSS APPLY  OPENJSON(CustomFields, '$.Tags') sites
WHERE 	sites.[value] = 'Vintage'

/*�����������*/
SELECT StockItemID,StockItemName, 
	   SUBSTRING(tags2,2,LEN(tags2)-1) AS tags 
FROM (
		SELECT StockItemID,
			   StockItemName,
			  (SELECT ','+item FROM OPENJSON(TAGS) WITH (item nvarchar(max) '$') FOR XML PATH('')) AS tags2 
		FROM (
			  SELECT 
					StockItemID,
					StockItemName,
					(SELECT JSON_QUERY(CustomFields, '$.Tags') AS 'data'
			  FROM Warehouse.StockItems W  where ws.StockItemID=w.StockItemID
					 ) AS TAGS
		FROM Warehouse.StockItems ws
			) t 
	) t2 
WHERE tags2 IS NOT NULL