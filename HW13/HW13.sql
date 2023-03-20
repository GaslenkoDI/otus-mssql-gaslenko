�������� ������� �� ����� MS SQL Server Developer � OTUS.
������� "12 - �������� ���������, �������, ��������, �������".
������� ����������� � �������������� ���� ������ WideWorldImporters.
����� �� ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
����� WideWorldImporters-Full.bak
�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
�� ���� �������� �������� �������� ��������� / ������� � ������������������ �� �������������.
*/

/*
1) �������� ������� ������������ ������� � ���������� ������ �������.
*/

CREATE FUNCTION GetPurchaseAmount ( ) 
RETURNS TABLE  
AS 
 
RETURN    
 
( 
  
 Select top 1 c.CustomerID,c.CustomerName,  sum(il.ExtendedPrice) as SUMinv
    from Sales.Customers c
    inner join Sales.Invoices i on c.CustomerID=i.CustomerID
    inner join Sales.InvoiceLines il on i.InvoiceID=il.InvoiceID
	group by  c.CustomerID,i.InvoiceID, c.CustomerName
    Order by sum(il.ExtendedPrice) desc 
 
);   
GO    
--����
Select * from GetPurchaseAmount ()
--���������
USE WideWorldImporters;
GO
CREATE PROCEDURE dbo.GetCustomersPurchaseAmount AS
BEGIN
    select top 1 c.CustomerID, c.CustomerName, SUM(il.ExtendedPrice) as SUMinv from Sales.InvoiceLines il
		inner join Sales.Invoices i on i.InvoiceID = il.InvoiceID
		inner join Sales.Customers c on c.CustomerID = i.CustomerID
		group by c.CustomerID,i.InvoiceID,c.CustomerName
		Order by sum(il.ExtendedPrice) desc 
END;
-------------------���������-------------------------------------------------------------------
exec GetCustomersPurchaseAmount
-----------------------------------------------------------------------------------------------


/*
2) �������� �������� ��������� � �������� ���������� �ustomerID, ��������� ����� ������� �� ����� �������.
������������ ������� :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

USE WideWorldImporters;
GO
CREATE PROCEDURE dbo.CustomersPurchase 
(@CustomerID int)
AS
BEGIN
    select top 1 c.CustomerID, c.CustomerName, SUM(il.ExtendedPrice) as SUMinv from Sales.InvoiceLines il
		inner join Sales.Invoices i on i.InvoiceID = il.InvoiceID
		inner join Sales.Customers c on c.CustomerID = i.CustomerID
		where i.CustomerID= @CustomerID
		group by c.CustomerID,i.InvoiceID,c.CustomerName
		Order by sum(il.ExtendedPrice) desc 
END;
--���������
Exec CustomersPurchase @CustomerID=834


/*
3) ������� ���������� ������� � �������� ���������, ���������� � ��� ������� � ������������������ � ������.
*/

-- ������� ��������� � ������� �� ������� �������
SET STATISTICS TIME,IO ON

print '-[F]---------------------'
Select * from GetPurchaseamount ()
print '-[SP]--------------------'
exec GetCustomersPurchaseAmount

---�������� �������
print '-[SP]--------------------'
exec GetCustomersPurchaseAmount
print '-[F]---------------------'
Select * from GetPurchaseamount ()
print '----------------------'

SET STATISTICS TIME,IO OFF


--SQL Server parse and compile time: 
--   CPU time = 61 ms, elapsed time = 61 ms.

-- SQL Server Execution Times:
--   CPU time = 0 ms,  elapsed time = 0 ms.


---[F]---------------------

-- SQL Server Execution Times:
--   CPU time = 0 ms,  elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 141 ms,  elapsed time = 140 ms.


---[SP]--------------------

-- SQL Server Execution Times:
--   CPU time = 0 ms,  elapsed time = 0 ms.
--SQL Server parse and compile time: 
--   CPU time = 16 ms, elapsed time = 24 ms.



-- SQL Server Execution Times:
--   CPU time = 125 ms,  elapsed time = 185 ms.

-- SQL Server Execution Times:
--   CPU time = 141 ms,  elapsed time = 210 ms.
---[SP]--------------------

-- SQL Server Execution Times:
--   CPU time = 0 ms,  elapsed time = 0 ms.
--SQL Server parse and compile time: 
--   CPU time = 0 ms, elapsed time = 0 ms.



-- SQL Server Execution Times:
--   CPU time = 125 ms,  elapsed time = 149 ms.

-- SQL Server Execution Times:
--   CPU time = 125 ms,  elapsed time = 149 ms.
---[F]---------------------

-- SQL Server Execution Times:
--   CPU time = 0 ms,  elapsed time = 0 ms.



-- SQL Server Execution Times:
--   CPU time = 125 ms,  elapsed time = 142 ms.
------------------------

-- SQL Server Execution Times:
--   CPU time = 0 ms,  elapsed time = 0 ms.

--�����, �� elapsed time ������� �������� �������


/*
4) �������� ��������� ������� �������� ��� �� ����� ������� ��� ������ ������ result set'� ��� ������������� �����. 
*/

CREATE FUNCTION [dbo].[GetCustomerLPDate] 
(@CustomerId INT)

RETURNS DATE
BEGIN

DECLARE @Date DATE;

SELECT TOP 1
	@Date = i.[InvoiceDate]
FROM [Sales].[Customers] c
INNER JOIN [Sales].[Invoices] i ON i.[CustomerID] = c.[CustomerID]
WHERE c.CustomerID = @CustomerId
ORDER BY i.[InvoiceDate] desc

RETURN @Date

END

GO

--������ �������������
SELECT
	c.[CustomerID],
	c.[CustomerName],
	[dbo].[GetCustomerLPDate](c.[CustomerID]) AS [LPDate]
FROM [Sales].[Customers] c
