�������� ������� �� ����� MS SQL Server Developer � OTUS.
������� "07 - ������������ SQL".
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
��� ������� �� ������� "��������� CROSS APPLY, PIVOT, UNPIVOT."
����� ��� ���� �������� ������������ PIVOT, ������������ ���������� �� ���� ��������.
��� ������� ��������� ��������� �� ���� CustomerName.
��������� �������� ������, ������� � ���������� ������ ���������� 
��������� ������ �� ���������� ������� � ������� �������� � �������.
� ������� ������ ���� ������ (���� ������ ������), � �������� - �������.
���� ������ ����� ������ dd.mm.yyyy, ��������, 25.12.2019.
������, ��� ������ ��������� ����������:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (������ �������)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/

DECLARE @DML AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX) 

SELECT @ColumnName = ISNULL(@ColumnName + ',','') + QUOTENAME(A.CustomerName)
FROM (SELECT DISTINCT CustomerName
		FROM Sales.Customers
	) AS A

SET @DML=
N'SELECT InvoiceMonth, ' +@ColumnName + '
FROM (
	SELECT DISTINCT
		CustomerName,
		convert(varchar,DATEADD(dd,-(day(InvoiceDate)-1),InvoiceDate), 104) as InvoiceMonth,
		OrderID
	FROM Sales.Customers as SC
		JOIN Sales.Invoices AS SI 
			ON SC.CustomerID=SI.CustomerID
		JOIN Sales.InvoiceLines AS SIL
			ON SI.InvoiceID=SIL.InvoiceID
	) AS Cust
PIVOT (COUNT(OrderID) FOR CustomerName  in (' +@ColumnName + ')) AS PVT
ORDER BY year(InvoiceMonth), month(InvoiceMonth) '

EXEC sp_executesql @dml