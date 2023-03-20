/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

SELECT [PersonID],
	   [FullName]
FROM [Application].[People]
WHERE IsSalesperson = 1
and PersonID not in 
			(SELECT [SalespersonPersonID]  
			FROM [Sales].[Invoices]  
			WHERE InvoiceDate = '20150704')

SELECT	i.[SalespersonPersonID], 
		p.[FullName]
FROM [Application].[People] as p
JOIN [Sales].[Invoices] as i on p.PersonID = i.SalespersonPersonID
WHERE p.IsSalesperson = 1
EXCEPT
SELECT	i.[SalespersonPersonID],
		p.[FullName]
FROM [Sales].[Invoices] as i 
JOIN [Application].[People] as p on p.PersonID = i.SalespersonPersonID
WHERE i.InvoiceDate = '20150704'

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

SELECT	StockItemID,
		StockItemName,
		UnitPrice
FROM [Warehouse].[StockItems]
where StockItemID in (SELECT top 1 StockItemID FROM [Warehouse].[StockItems] group by StockItemID order by MIN(unitprice))

SELECT	s.StockItemID,
		StockItemName,
		UnitPrice
FROM [Warehouse].[StockItems] as s
JOIN (SELECT top 1 StockItemID FROM [Warehouse].[StockItems] group by StockItemID order by MIN(unitprice)) as m on m.StockItemID = s.StockItemID

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

TODO:

SELECT TOP 5 t.CustomerID, CustomerName, TransactionAmount, TransactionDate
FROM Sales.CustomerTransactions as t
JOIN [Sales].[Customers] as c on c.CustomerID = t.CustomerID
order by TransactionAmount desc

;WITH TransactionCTE as
(SELECT TOP 5 CustomerID, TransactionAmount, TransactionDate
FROM Sales.CustomerTransactions
ORDER BY TransactionAmount desc)
SELECT c.CustomerID, CustomerName, TransactionAmount, TransactionDate
FROM [Sales].[Customers] as c
JOIN TransactionCTE as t on c.CustomerID = t.CustomerID

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

TODO:

;WITH PackedByCTE AS
	(SELECT	FullName,  
            PackedByPersonID, 
            CustomerID,
            InvoiceID
	FROM Sales.Invoices
    JOIN Application.People on PersonID = PackedByPersonID)

SELECT DISTINCT CityID, 
                CityName, 
                FullName
FROM Application.Cities as c
       JOIN Sales.Customers		as sc on sc.PostalCityID = c.CityID
       JOIN PackedByCTE			as pb on pb.CustomerID = sc.CustomerID 
       JOIN Sales.InvoiceLines	as il on il.InvoiceID = pb.InvoiceID
       JOIN (	SELECT TOP 3 StockItemID 
				FROM [Warehouse].[StockItems] 
				GROUP BY StockItemID 
				ORDER BY MAX(unitprice) DESC) as m on m.StockItemID = il.StockItemID
order by CityID

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: напишите здесь свое решение
