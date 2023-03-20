/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

SELECT	i.[OrderID], 
		с.[CustomerName], 
		i.[InvoiceDate],
		l.[Quantity] * l.[UnitPrice] as InvSum,
		(SELECT SUM(l.[UnitPrice]*l.[Quantity]) FROM [Sales].[InvoiceLines] as l
		 JOIN [Sales].[Invoices] as i2 on i2.[InvoiceID] = l.[InvoiceID]
		 WHERE FORMAT(i2.[InvoiceDate], 'yyyyMM') <= FORMAT(i.[InvoiceDate], 'yyyyMM') and i2.[InvoiceDate] >= '20150101'
		 ) as total
FROM [Sales].[Invoices] as i
JOIN [Sales].[Customers] as с on с.[CustomerID] = i.[CustomerID]
JOIN [Sales].[InvoiceLines] as l on i.[InvoiceID] = l.[InvoiceID]
WHERE i.[InvoiceDate] >= '20150101'
ORDER BY i.[InvoiceDate]

3 минуты 39 сек

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

SELECT	i.[OrderID], 
		с.[CustomerName], 
		i.[InvoiceDate], 
		l.[Quantity] * l.[UnitPrice] as InvSum,
		SUM(l.[UnitPrice]*l.[Quantity]) OVER (ORDER BY FORMAT(i.[InvoiceDate], 'yyyyMM')
                ) as total
FROM [Sales].[Invoices]		as i
JOIN [Sales].[InvoiceLines] as l on i.[InvoiceID] = l.[InvoiceID]
JOIN [Sales].[Customers]	as с on с.[CustomerID] = i.[CustomerID]
WHERE i.[InvoiceDate] >= '20150101'
ORDER BY i.[InvoiceDate]

1 сек

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

SELECT * 
FROM (
SELECT 
		MONTH(InvoiceDate) AS [Month],
		[Description],
		SUM (Quantity) AS SumQuantity,
		ROW_NUMBER () OVER (PARTITION BY MONTH(InvoiceDate) ORDER BY(SUM (Quantity)) DESC) AS RowPopular

FROM Sales.Invoices AS SI
JOIN Sales.InvoiceLines AS SIL ON
	SI.InvoiceID=SIL.InvoiceID
WHERE YEAR(InvoiceDate)=2016
GROUP BY [Description], MONTH(InvoiceDate)) AS T
WHERE T.RowPopular <=2
ORDER BY [Month]

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

SELECT
		StockItemID, 
		StockItemName, 
		Brand,
		UnitPrice ,
		RANK() OVER (PARTITION BY LEFT(StockItemName, 1) ORDER BY StockItemName) as Number,
		COUNT(StockItemID) OVER ()												 as Cnt_All,
		COUNT(StockItemID) OVER (PARTITION BY LEFT(StockItemName, 1) )			 as Cnt_Group,
		LEAD(StockItemID) OVER (ORDER BY StockItemName)							 as NextID,
		LAG(StockItemID,1,0) OVER (ORDER BY StockItemName)						 as PrevID , 
		LAG(StockItemName,2,'No items') OVER (ORDER BY StockItemName)			 as PrevItemName,
		Ntile(30) OVER (ORDER BY TypicalWeightPerUnit )							 as WeightGr30
FROM [Warehouse].[StockItems] 
ORDER BY StockItemName

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

SELECT TOP 1 WITH TIES  
		i.SalespersonPersonID,
		p.FullName,
		c.CustomerID,
		c.CustomerName,
		i.InvoiceDate,
		SUM(l.UnitPrice*l.Quantity) as InvSum
FROM [Sales].[InvoiceLines]		as l
	JOIN [Sales].[Invoices]		as i on l.InvoiceID  = i.InvoiceID
	JOIN [Application].[People]	as p on p.PersonID	 = i.SalespersonPersonID
	JOIN [Sales].[Customers]	as c on c.CustomerID = i.CustomerID
	GROUP BY i.SalespersonPersonID, c.CustomerID, i.InvoiceDate, c.CustomerName, p.FullName
	ORDER BY ROW_NUMBER () OVER (PARTITION BY i.SalespersonPersonID ORDER BY i.InvoiceDate DESC)

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT CustomerID, CustomerName, ItemID, Price, InvDate FROM 
	(SELECT DISTINCT 
					i.CustomerID	as CustomerID, 
					c.CustomerName	as CustomerName, 
					l.StockItemID	as ItemID,
					l.UnitPrice		as Price,
					i.InvoiceDate	as InvDate,
					DENSE_RANK() OVER (PARTITION BY i.CustomerId ORDER BY UnitPrice DESC) as dr
From [Sales].[InvoiceLines]		as l
	JOIN [Sales].[Invoices]		as i on l.InvoiceID = i.InvoiceID
	JOIN [Sales].[Customers]	as c on c.CustomerID = i.CustomerID 
	) as calculation	
WHERE dr < 3
ORDER BY CustomerId, Price  DESC

Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 