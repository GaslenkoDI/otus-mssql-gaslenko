/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

 
	use[WideWorldImporters]

SELECT 
		 StockItemID,
		 StockItemName,
		 UnitPrice,
		 RecommendedRetailPrice
	FROM Warehouse.StockItems
	WHERE
		StockItemName LIKE '%urgent%'
		OR StockItemName LIKE 'Animal%'

	GO

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/


	use[WideWorldImporters]
SELECT 
		 ps.SupplierID,
		 ps.SupplierName
	FROM 
		Purchasing.Suppliers as ps
		LEFT JOIN Purchasing.PurchaseOrders as ppo ON ps.SupplierID = ppo.SupplierID
	WHERE
		ppo.PurchaseOrderID IS NULL

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT 
	o.OrderID, CONVERT(NVARCHAR, o.OrderDate, 104) AS OrderDate, c.CustomerName, DATENAME(MM, o.OrderDate) AS Mounth, DATEPART(QUARTER, o.OrderDate) AS [Quarter],
CASE WHEN MONTH(o.OrderDate) <5 THEN 1 WHEN MONTH(o.OrderDate) > 8 THEN 3 ELSE 2 END [Треть]
FROM Sales.Orders AS o
JOIN Sales.OrderLines AS ol ON o.OrderID = ol.OrderID 
JOIN Sales.Customers AS c ON o.CustomerID = c.CustomerID
WHERE ol.UnitPrice > 100 or ol.Quantity > 20 and ol.PickingCompletedWhen is not null
ORDER BY [Quarter], [Треть], o.OrderDate

SELECT o.OrderID, CONVERT(NVARCHAR, o.OrderDate, 104) AS OrderDate, c.CustomerName, DATENAME(MM, o.OrderDate) AS Mounth, DATEPART(QUARTER, o.OrderDate) AS [Quarter],
CASE WHEN MONTH(o.OrderDate) <5 THEN 1 WHEN MONTH(o.OrderDate) > 8 THEN 3 ELSE 2 END [Треть]
FROM Sales.Orders AS o
JOIN Sales.OrderLines AS ol ON o.OrderID = ol.OrderID 
JOIN Sales.Customers AS c ON o.CustomerID = c.CustomerID
WHERE ol.UnitPrice > 100 or ol.Quantity > 20 and ol.PickingCompletedWhen is not null
ORDER BY [Quarter], [Треть], o.OrderDate OFFSET 1000 rows fetch first 100 rows only


/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

	
SELECT
	ppo.PurchaseOrderID,
	ppo.OrderDate,
	ppo.ExpectedDeliveryDate,
	adm.DeliveryMethodName,
	ps.SupplierName,
	ap.FullName AS [Contact Person Name]
	FROM Purchasing.PurchaseOrders AS ppo
	JOIN Application.DeliveryMethods as adm ON ppo.DeliveryMethodID = adm.DeliveryMethodID
	LEFT JOIN Purchasing.Suppliers as ps ON ppo.SupplierID = ps.SupplierID
	LEFT JOIN Application.People as ap ON ppo.ContactPersonID = ap.PersonID
	WHERE
	ppo.ExpectedDeliveryDate BETWEEN '20130101' AND '20130131'
	AND ppo.IsOrderFinalized = 1
	AND adm.DeliveryMethodName IN ('Air Freight', 'Refrigerated Air Freight')

	GO

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP 10
		 so.OrderID,
		 so.OrderDate,
		 sc.CustomerName,
		 ap.FullName
	FROM Sales.Orders AS so
		LEFT JOIN Sales.Customers AS sc ON so.CustomerID = sc.CustomerID
		LEFT JOIN Application.People AS ap ON so.SalespersonPersonID = ap.PersonID
	ORDER BY
		so.OrderID DESC

	GO

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

	DECLARE @StockItemName nvarchar(100) = 'Chocolate frogs 250g', @StockItemID int;

	SET @StockItemID = (SELECT StockItemID FROM Warehouse.StockItems WHERE StockItemName = @StockItemName)

	SELECT DISTINCT
		 sc.CustomerID,
		 sc.CustomerName,
		 sc.PhoneNumber
	FROM Warehouse.StockItems as wsi
		 JOIN Sales.OrderLines as sol ON wsi.StockItemID = sol.StockItemID
		 JOIN Sales.Orders as so ON sol.OrderID = so.OrderID
		 JOIN Sales.Customers as sc ON sc.CustomerID = so.CustomerID
	WHERE
		wsi.StockItemID = @StockItemID

	GO