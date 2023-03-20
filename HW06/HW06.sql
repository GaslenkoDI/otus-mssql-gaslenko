/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

select * from 
 (
 select	(SELECT SUBSTRING(C.CustomerName,CHARINDEX('(',C.CustomerName)+1,(CHARINDEX(')',C.CustomerName)-CHARINDEX('(',C.CustomerName))-1) 
		FROM Sales.Customers as C
		WHERE C.CustomerID = I.CustomerID
		) AS CustomerName,
		I.OrderID,
		cast(DATEADD(mm,Datediff(mm,0,InvoiceDate),0) as DATE) as MonthInv 
		from Sales.InvoiceLines as LI
		Left join Sales.Invoices I on LI.InvoiceID = I.InvoiceID
	where CustomerID between 2 and 6 
	) as A
 PIVOT
(
count(OrderID) for CustomerName in ("Peeples Valley, AZ", "Jessie, ND", "Gasport, NY", "Medicine Lodge, KS", "Sylvanite, MT" )
) as pvt
order by MonthInv

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

select unpt.CustomerName, unpt.Adress
from (select C.CustomerName, C.DeliveryAddressLine1, C.DeliveryAddressLine2, C.PostalAddressLine1, C.PostalAddressLine2
	from Sales.Customers C where C.CustomerName Like '%Tailspin Toys%') as Adr
Unpivot (Adress FOR Name in (DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2)) as unpt


/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

select CountryID, CountryName, Code
from	(select C.CountryID, C.CountryName, C.IsoAlpha3Code, convert(nvarchar(3),C.IsoNumericCode) as IsoNumericCode
		from Application.Countries as C ) as A

Unpivot (Code FOR name in (A.IsoAlpha3Code, A.IsoNumericCode)) as B


/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

;with CTE as 
(
	select I.CustomerID, C.CustomerName, I.InvoiceDate, IL.UnitPrice
	From Sales.Invoices I
	left join Sales.InvoiceLines IL on I.InvoiceID = IL.InvoiceID
	left join Sales.Customers C on I.CustomerID=C.CustomerID
)
select O.CustomerID, O.CustomerName, O.InvoiceDate, O.UnitPrice 
from Sales.Customers C
cross apply (
			select top 2 *
			From CTE 
			Where C.CustomerID = CTE.CustomerID
			order by UnitPrice desc
			) as O
order by C.CustomerName 
