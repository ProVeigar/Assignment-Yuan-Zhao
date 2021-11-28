/*
1.List of Persons¡¯ full name, all their fax and phone numbers, 
 as well as the phone number and fax of the company they are working for (if any)
 */
-- ask where the table for companiese's phone and fax 
select a.FullName,a.PhoneNumber,a.FaxNumber,a.IsEmployee, s.PhoneNumber as CompanyPhone,s.FaxNumber as CompanyFax,s.CustomerName
from Application.People a left join [Sales].[Customers] S on a.PersonID=s.CustomerID and a.IsEmployee=1
--where a.IsEmployee=0
order by PersonID


/*2.If the customer's primary contact person has the same phone number as the customer¡¯s phone number,
    list the customer companies.  */
	select s.CustomerName as CompanyName,s.CustomerID,a.FullName,s.PhoneNumber,a.PhoneNumber 
	from Sales.Customers s join Application.People a on s.PrimaryContactPersonID=a.PersonID 
	and s.PhoneNumber=a.PhoneNumber 
	

/*3.List of customers to whom we made a sale prior to 2016 but no sale since 2016-01-01.*/
with After2016 as(
select distinct CustomerID
from [Sales].[CustomerTransactions] s
where s.TransactionDate > cast('2016-01-01' as date)
)
select s.CustomerName
	from Sales.Customers s 
	where s.CustomerID not in (select* from After2016)

/*4.List of Stock Items and total quantity for each stock item in Purchase Orders in Year 2013.*/

select  
od.StockItemID,
sum(od.Quantity) as quantity
from Sales.OrderLines as od 
	where YEAR (od.PickingCompletedWhen) = YEAR('2013')
	group by od.StockItemID

/*5.List of stock items that have at least 10 characters in description.*/
select so.StockItemID, so.Description 
from Sales.OrderLines as so
where LEN(so.Description)>=10

/*6.List of stock items that are not sold to the state of Alabama and Georgia in 2014.*/
Select Distinct OL.StockItemID
From Sales.OrderLines OL
join sales.Orders O on OL.OrderID = O.OrderID and YEAR (O.OrderDate)=YEAR('2014')
join Sales.Customers C on O.CustomerID = C.CustomerCategoryID
Join Application.Cities CS on C.PostalCityID = cs.CityID
join Application.StateProvinces st on cs.StateProvinceID=st.StateProvinceID and CS.StateProvinceID not in (1,11)

/*7.List of States and Avg dates for processing (confirmed delivery date ¨C order date).*/
select 
	st.StateProvinceCode,
	AVG(DATEDIFF(DAY, so.OrderDate,cast(SI.ConfirmedDeliveryTime as date))) as 'Avg dates for processing'
from Sales.Invoices SI
	join Sales.Orders SO on SI.OrderID= SO.OrderID
	join Sales.Customers C on SO.CustomerID = C.CustomerCategoryID
    Join Application.Cities CS on C.PostalCityID = cs.CityID
    join Application.StateProvinces st on cs.StateProvinceID=st.StateProvinceID
	Group by st.StateProvinceCode
/*8.List of States and Avg dates for processing (confirmed delivery date ¨C order date) by month.*/
--8.1
select 
	CAST(Year(so.OrderDate) AS VARCHAR(4))+'.'+CAST(Month(so.OrderDate)AS VARCHAR(2)) as 'BY MONTH',
	st.StateProvinceCode,
	AVG(DATEDIFF(DAY, so.OrderDate,cast(SI.ConfirmedDeliveryTime as date))) as 'Avg dates for processing'
from Sales.Invoices SI
	join Sales.Orders SO on SI.OrderID= SO.OrderID
	join Sales.Customers C on SO.CustomerID = C.CustomerCategoryID
    Join Application.Cities CS on C.PostalCityID = cs.CityID
    join Application.StateProvinces st on cs.StateProvinceID=st.StateProvinceID
	Group by Year (so.OrderDate),Month (so.OrderDate), st.StateProvinceCode
	Order by st.StateProvinceCode,Year (so.OrderDate),Month (so.OrderDate)
-- 8.2
SELECT StateProvinceCode as StateName, [JAN], [Feb], [Mar], [Apr], [May], [Jun], [Jul], [Aug], [Sep], [Oct],[Nov], [Dec]
 FROM (
  select st.StateProvinceCode,
	CONVERT(CHAR(3), DATENAME(MONTH, so.OrderDate)) as MN,
	DATEDIFF(DAY, so.OrderDate,cast(SI.ConfirmedDeliveryTime as date))as 'DataDiff'
from Sales.Invoices SI
	join Sales.Orders SO on SI.OrderID= SO.OrderID
	join Sales.Customers C on SO.CustomerID = C.CustomerCategoryID
    Join Application.Cities CS on C.PostalCityID = cs.CityID
    join Application.StateProvinces st on cs.StateProvinceID=st.StateProvinceID
) t 
PIVOT(
AVG(t.DataDiff) for MN in ([JAN], [Feb], [Mar], [Apr], [May], [Jun], [Jul], [Aug], [Sep], [Oct],[Nov], [Dec])
) AS pivot_table;

/*9.List of StockItems that the company purchased more than sold in the year of 2015.*/
Select os.StockItemID,os.SaleAmt,op.PurchaseAmt from
(SELECT 
	OL.StockItemID,
	Sum(OL.Quantity) AS SaleAmt
FROM Sales.OrderLines OL join Sales.Orders so on ol.OrderID=so.OrderID
Where YEAR(so.OrderDate) = YEAR('2015') 
group by StockItemID
) as OS 
JOIN (
SELECT  
	StockItemID,
	Sum(POL.OrderedOuters) AS PurchaseAmt
FROM Purchasing.PurchaseOrderLines POL join Purchasing.PurchaseOrders PO
on pol.PurchaseOrderID=po.PurchaseOrderID
where YEAR (po.OrderDate) =YEAR('2015') 
group by StockItemID
) AS OP on os.StockItemID=op.StockItemID
where op.PurchaseAmt>os.SaleAmt

/*10.List of Customers and their phone number,
     together with the primary contact person¡¯s name,
		to whom we did not sell more than 10  mugs (search by name) in the year 2016.*/
SELECT SC.CustomerName, WSI.StockItemName,sc.PhoneNumber as CustPhone ,ap.FullName as PrimaryContactName, sum(SIL.Quantity) as quantity
	FROM Sales.Customers FOR SYSTEM_TIME AS OF '2016-12-31' SC 
	join Application.People AP on SC.PrimaryContactPersonID = AP.PersonID
	join Sales.Invoices SI on si.CustomerID =sc.CustomerID
	join Sales.InvoiceLines SIL on SIL.InvoiceID=si.InvoiceID
	join Warehouse.StockItems WSI on WSI.StockItemID=SIL.StockItemID
	where  CAST(WSI.StockItemName AS VARCHAR) like '%mug%'
	group by SC.CustomerName,WSI.StockItemName, sc.PhoneNumber  ,ap.FullName
	having sum(SIL.Quantity) < 10

/*11.List all the cities that were updated after 2015-01-01.*/
SELECT CityName,ValidFrom
From [Application].[Cities] FOR SYSTEM_TIME From '2015-01-01 00:00:00.0000000' to '2015-12-31 00:00:00.0000000'
where CAST(ValidFrom as date) >CAST('2015-01-01' as date)
order by CityName,ValidFrom

/*12.	List all the Order Detail 
     (Stock Item name, delivery address, delivery state, city, country, customer name, customer contact person name, customer phone, quantity) 
	 for the date of 2014-07-01. Info should be relevant to that date.*/
	 SELECT 
	 wsi.StockItemName,
	 si.DeliveryInstructions,
	 ASP.StateProvinceName,
	 AC.CityName,
	 SC.CustomerName,
	 AP.FullName,
	 SC.PhoneNumber,
	 sum(SIL.Quantity) as Quantity
	 FROM Sales.Invoices SI
	 JOIN Sales.InvoiceLines SIL on SI.InvoiceID=SIL.InvoiceID
	 JOIN Warehouse.StockItems FOR SYSTEM_TIME AS OF '2014-07-01' wsi on SIL.StockItemID= wsi.StockItemID
	 JOIN Sales.Customers FOR SYSTEM_TIME AS OF '2014-07-01' SC on SI.CustomerID=SC.CustomerID
	 JOIN Application.People FOR SYSTEM_TIME AS OF '2014-07-01' AP on AP.PersonID = SC.PrimaryContactPersonID
	 JOIN Application.Cities FOR SYSTEM_TIME AS OF '2014-07-01' AC on SC.DeliveryCityID = AC.CityID
	 JOIN Application.StateProvinces FOR SYSTEM_TIME AS OF '2014-07-01' ASP on ASP.StateProvinceID = AC.StateProvinceID
	 JOIN Application.Countries FOR SYSTEM_TIME AS OF '2014-07-01' ACT on ACT.CountryID = ASP.CountryID
	 Group BY
	 wsi.StockItemName,
	 si.DeliveryInstructions,
	 ASP.StateProvinceName,
	 AC.CityName,
	 SC.CustomerName,
	 AP.FullName,
	 SC.PhoneNumber

/*13.List of stock item groups and total quantity purchased, 
     total quantity sold, and the remaining stock quantity (quantity purchased ¨C quantity sold)*/
	 -- ask: 1:group by stockitem or group by stockitemGroups 2: is order outers the purchaseed amount
	 SELECT SIP.StockItemID,SIP.QuantityPurchased,SIS.QuantitySold,SIP.QuantityPurchased-SIS.QuantitySold as Remaining,WSG.StockGroupName
	 FROM(
	 select pol.StockItemID,SUM(pol.ReceivedOuters) as QuantityPurchased
	 From Purchasing.PurchaseOrderLines pol 
	 group by pol.StockItemID) AS SIP
	 LEFT JOIN(
	 Select SOL.StockItemID, SUM(SOL.Quantity) as QuantitySold
	 FROM Sales.OrderLines SOL
	 Group by SOL.StockItemID) AS SIS
	 ON SIP.StockItemID=SIS.StockItemID
	 JOIN Warehouse.StockItemStockGroups SISG on SIP.StockItemID= SISG.StockItemID
	 JOIN Warehouse.StockGroups WSG on WSG.StockGroupID=SISG.StockGroupID


--14.	List of Cities in the US and the stock item that the city got the most deliveries in 2016. 
--      If the city did not purchase any stock items in 2016, print ¡°No Sales¡±.
SELECT SumQuantity.CityName,ISNULL(SumQuantity.Description, 'No Sales' )as StockItem,ISNULL(MAX(SumQuantity.qua),0) as Quantity
FROM Application.Cities Apc left join(SELECT ac.CityName,ac.CityID,sil.Description, SUM(sil.Quantity) as qua
FROM Sales.Customers FOR SYSTEM_TIME AS OF '2016-12-31' SC 
     JOIN Sales.Invoices SI on sc.CustomerID=SI.CustomerID
	 JOIN Sales.InvoiceLines SIL on si.InvoiceID=sil.InvoiceID
     JOIN Application.Cities AC on sc.DeliveryCityID=ac.CityID
	 WHERE YEAR(SI.ConfirmedDeliveryTime)= YEAR('2016-1-1')
	 Group by ac.CityName,ac.CityID,sil.Description
)as SumQuantity on apc.CityID=SumQuantity.CityID
Group by SumQuantity.CityName,SumQuantity.Description
order by CityName


--15.	List any orders that had more than one delivery attempt (located in invoice table). \
--ASK: what indicate more than one attempt
Select  SI.OrderID, json_value(SI.ReturnedDeliveryData,'$.Events[1].Comment') as comment
from sales.Invoices SI
where json_value(SI.ReturnedDeliveryData,'$.Events[1].Comment')  IS NOT NULL;


--16.	List all stock items that are manufactured in China. (Country of Manufacture)
SELECT WSI.stockItemID, WSI.StockItemName, json_value(WSI.CustomFields,'$.CountryOfManufacture') as Country
FROM Warehouse.StockItems as WSI
where json_value(WSI.CustomFields,'$.CountryOfManufacture') = 'China'
--17.	Total quantity of stock items sold in 2015, group by country of manufacturing.--FOR SYSTEM_TIME AS OF '2015-12-31'
SELECT  json_value(WSI.CustomFields,'$.CountryOfManufacture') as MnfCtry, WSI.StockItemName,sum(sil.Quantity) as quantity
From Warehouse.StockItems FOR SYSTEM_TIME AS OF '2016-12-31' WSI 
JOIN sales.InvoiceLines SIL on WSI.StockItemID=SIL.StockItemID 
JOIN Sales.Invoices SI on SI.InvoiceID=SIL.InvoiceID and YEAR(SI.InvoiceDate)=YEAR('2015-12-31')
group by JSON_VALUE(WSI.CustomFields, '$.CountryOfManufacture'), WSI.StockItemName;


--18.	Create a view that shows the total quantity of stock items of 
--      each stock group sold (in orders) by year 2013-2017. [Stock Group Name, 2013, 2014, 2015, 2016, 2017]
--a.dynamicly
DROP VIEW StockGroupSoldByYear

DECLARE 
    @columns NVARCHAR(MAX) = '', 
    @sql     NVARCHAR(MAX) = '';
-- select the category names
SELECT 
    @columns+=QUOTENAME(yr)+ ','
FROM 
		(SELECT distinct YEAR(OrderDate) yr from Sales.Orders)as a
ORDER BY 
    yr;
-- remove the last comma
SET @columns = LEFT(@columns, LEN(@columns) - 1);
 print @columns
-- construct dynamic SQL
SET @sql ='
CREATE VIEW StockGroupSoldByYear AS 
  SELECT* FROM(
		SELECT sg.StockGroupName,YEAR(so.OrderDate) as YR ,SOL.Quantity as QUANTITY
		FROM 
		Sales.OrderLines SOL
		JOIN Sales.Orders SO on SO.OrderID=sol.OrderID
		JOIN Warehouse.StockItemStockGroups SIG on SIG.StockItemID=sol.StockItemID 
		JOIN Warehouse.StockGroups SG on SG.StockGroupID=SIG.StockGroupID
		)as t
		PIVOT (SUM(QUANTITY) FOR YR in ('+ @columns +')
		) as pvt;';
EXECUTE sp_executesql @sql;
Select *
		From [dbo].[StockGroupSoldByYear]
--b.create by list out columns
CREATE VIEW StockGroupSoldByYear AS 
SELECT* FROM(
		SELECT sg.StockGroupName,YEAR(so.OrderDate) as YR ,SOL.Quantity as QUANTITY
		FROM 
		Sales.OrderLines SOL
		JOIN Sales.Orders SO on SO.OrderID=sol.OrderID
		JOIN Warehouse.StockItemStockGroups SIG on SIG.StockItemID=sol.StockItemID 
		JOIN Warehouse.StockGroups SG on SG.StockGroupID=SIG.StockGroupID
		)as t
		PIVOT (SUM(QUANTITY) FOR YR in ([2013],[2014],[2015],[2016],[2017])
		) as pvt;

		Select *
		From [dbo].[StockGroupSoldByYear]

--19.	Create a view that shows the total quantity of stock items of each stock group sold (in orders) by year 2013-2017. [Year, Stock Group Name1, Stock Group Name2, Stock Group Name3, ¡­ , Stock Group Name10] 
DROP VIEW StockGroupSoldByName
DECLARE 
    @columns NVARCHAR(MAX) = '', 
    @sql     NVARCHAR(MAX) = '';
-- select the category names
SELECT 
    @columns+=QUOTENAME(StockGroupName)+ ','
FROM 
		(SELECT distinct StockGroupName from Warehouse.StockGroups)as a
;
-- remove the last comma
SET @columns = LEFT(@columns, LEN(@columns) - 1);
 print @columns
-- construct dynamic SQL
SET @sql ='
CREATE VIEW StockGroupSoldByName AS 
  Select * from
(SELECT sg.StockGroupName,YEAR(so.OrderDate) as YR ,SOL.Quantity as QUANTITY
		FROM 
		Sales.OrderLines SOL
		JOIN Sales.Orders SO on SO.OrderID=sol.OrderID
		JOIN Warehouse.StockItemStockGroups SIG on SIG.StockItemID=sol.StockItemID 
		JOIN Warehouse.StockGroups SG on SG.StockGroupID=SIG.StockGroupID
	) t
	Pivot( SUM(QUANTITY) For StockGroupName in ('+ @columns +')) pvt';
EXECUTE sp_executesql @sql;


	Select *
		From [dbo].[StockGroupSoldByName]
		Order by yr
--20.	Create a function, input: order id; return: total of that order.
--List invoices and use that function to attach the order total to the other fields of invoices. 

DROP FUNCTION OrderTotal;
CREATE FUNCTION OrderTotal (
@OrderId int
)
RETURNS nvarchar(50) AS 
BEGIN
--DECLARE @return_value nvarchar(50);
 RETURN
 (Select SUM(SOL.Quantity * SOL.UnitPrice) FROM Sales.OrderLines SOL
  WHERE sol.OrderID=@OrderId
 )
END;

SELECT si.InvoiceID,[dbo].[OrderTotal](si.OrderID) as OrderTotal,si.CustomerID
FROM sales.Invoices si


/*21.	Create a new table called ods.Orders. Create a stored procedure, with proper error handling and transactions, 
   that input is a date; when executed, it would find orders of that day, calculate order total, 
   and save the information (order id, order date, order total, customer id) into the new table. 
   If a given date is already existing in the new table, throw an error and roll back. Execute the stored procedure 5 times using different dates. 
*/
DROP TABLE dbo.Orders
Create table dbo.Orders(
    orderId int,
    orderDate Date,
    orderTotal varchar(255),
	customerId int
)
Drop PROCEDURE getFromDate;
CREATE PROCEDURE getFromDate
(@dateinput DATE)
AS
BEGIN TRY
 BEGIN TRANSACTION
 IF (@dateinput NOT IN (SELECT isnull(orderDate,cast('1111-01-01' as date)) FROM dbo.Orders ))
  BEGIN
  INSERT INTO dbo.Orders(orderId ,orderDate ,orderTotal,customerId )
  SELECT  so.OrderID,so.OrderDate,[dbo].[OrderTotal](so.OrderID),so.CustomerID
  FROM sales.Orders so
  WHERE so.OrderDate=@dateinput
  COMMIT TRANSACTION
  END
ELSE 
BEGIN
  RAISERROR ('Date already inserted',16, 1)
 END
 END TRY
BEGIN CATCH
  Print ERROR_MESSAGE()
  Print 'transaction rolled back'
  ROLLBACK TRANSACTION
END CATCH

EXEC getFromDate @dateinput = '2013-1-2' 
select * from dbo.Orders
DELETE FROM dbo.Orders

/*22.	Create a new table called ods.StockItem. It has following columns: 
[StockItemID], [StockItemName] ,[SupplierID] ,[ColorID] ,[UnitPackageID] ,[OuterPackageID] ,
[Brand] ,[Size] ,[LeadTimeDays] ,[QuantityPerOuter] ,[IsChillerStock] ,[Barcode] ,[TaxRate]  ,[UnitPrice],
[RecommendedRetailPrice] ,[TypicalWeightPerUnit] ,[MarketingComments]  ,[InternalComments], [CountryOfManufacture], 
[Range], [Shelflife]. Migrate all the data in the original stock item table.

)
*/
CREATE SCHEMA ods

Create table ods.StockItem(
    [StockItemID] int not null PRIMARY KEY, 
	[StockItemName] nvarchar(100) NOT NULL,
	[SupplierID] INT NOT NULL ,
	[ColorID] INT NULL ,
	[UnitPackageID] INT NOT NULL,
	[OuterPackageID] INT NOT NULL,
    [Brand] NVARCHAR(50) NULL,[Size] NVARCHAR(20) NULL ,[LeadTimeDays] INT NOT NULL ,[QuantityPerOuter] INT NOT NULL,
	[IsChillerStock] BIT NOT NULL,[Barcode] NVARCHAR(50) NULL,[TaxRate] DECIMAL(18,3) NOT NULL  ,[UnitPrice] DECIMAL(18,2) NOT NULL,
    [RecommendedRetailPrice]DECIMAL(18,2) NULL ,[TypicalWeightPerUnit] DECIMAL(18,3) NOT NULL,
    [MarketingComments] NVARCHAR(MAX) NULL ,[InternalComments]NVARCHAR(MAX) NULL, [CountryOfManufacture] NVARCHAR(MAX) NULL, 
    [Range] NVARCHAR(MAX) NULL, [Shelflife]NVARCHAR(MAX) NULL, 
	TimeStart datetime2 (7)  NOT NULL, 
	TimeEnd datetime2 (7) NOT NULL, 
	--PERIOD FOR SYSTEM_TIME (TimeStart, TimeEnd) 
	)--WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = ods.StockItemHistory));
Create table ods.StockItemHistory(
    [StockItemID] int not null , 
	[StockItemName] nvarchar(100) NOT NULL,
	[SupplierID] INT NOT NULL ,
	[ColorID] INT NULL ,
	[UnitPackageID] INT NOT NULL,
	[OuterPackageID] INT NOT NULL,
    [Brand] NVARCHAR(50) NULL,[Size] NVARCHAR(20) NULL ,[LeadTimeDays] INT NOT NULL ,[QuantityPerOuter] INT NOT NULL,
	[IsChillerStock] BIT NOT NULL,[Barcode] NVARCHAR(50) NULL,[TaxRate] DECIMAL(18,3) NOT NULL  ,[UnitPrice] DECIMAL(18,2) NOT NULL,
    [RecommendedRetailPrice]DECIMAL(18,2) NULL ,[TypicalWeightPerUnit] DECIMAL(18,3) NOT NULL,
    [MarketingComments] NVARCHAR(MAX) NULL ,[InternalComments]NVARCHAR(MAX) NULL, [CountryOfManufacture] NVARCHAR(MAX) NULL, 
    [Range] NVARCHAR(MAX) NULL, [Shelflife]NVARCHAR(MAX) NULL, 
	TimeStart datetime2 (7) NOT NULL, 
	TimeEnd datetime2 (7) NOT NULL, 
	--PERIOD FOR SYSTEM_TIME (TimeStart, TimeEnd) 
	)
ALTER TABLE ods.StockItem SET (SYSTEM_VERSIONING = OFF);
ALTER TABLE ods.StockItem DROP PERIOD FOR SYSTEM_TIME
DROP TABLE IF EXISTS ods.StockItem, ods.StockItemHistory;
BEGIN TRANSACTION;
INSERT INTO ods.StockItem ([StockItemID], [StockItemName] ,[SupplierID] ,[ColorID] ,[UnitPackageID] ,[OuterPackageID] ,
[Brand] ,[Size] ,[LeadTimeDays] ,[QuantityPerOuter] ,[IsChillerStock] ,[Barcode] ,[TaxRate]  ,[UnitPrice],
[RecommendedRetailPrice] ,[TypicalWeightPerUnit] ,[MarketingComments]  ,[InternalComments], [CountryOfManufacture], 
[Range], [Shelflife],TimeStart,TimeEnd)
SELECT [StockItemID], [StockItemName] ,[SupplierID] ,[ColorID] ,[UnitPackageID] ,[OuterPackageID] ,
[Brand] ,[Size] ,[LeadTimeDays] ,[QuantityPerOuter] ,[IsChillerStock] ,[Barcode] ,[TaxRate]  ,[UnitPrice],
[RecommendedRetailPrice] ,[TypicalWeightPerUnit] ,[MarketingComments]  ,[InternalComments], JSON_VALUE(WS.CustomFields, '$.CountryOfManufacture'), 
Tags, SearchDetails,ws.ValidFrom,ws.ValidTo
FROM Warehouse.StockItems  WS
COMMIT;
BEGIN TRANSACTION;
INSERT INTO ods.StockItemHistory ([StockItemID], [StockItemName] ,[SupplierID] ,[ColorID] ,[UnitPackageID] ,[OuterPackageID] ,
[Brand] ,[Size] ,[LeadTimeDays] ,[QuantityPerOuter] ,[IsChillerStock] ,[Barcode] ,[TaxRate]  ,[UnitPrice],
[RecommendedRetailPrice] ,[TypicalWeightPerUnit] ,[MarketingComments]  ,[InternalComments], [CountryOfManufacture], 
[Range], [Shelflife],TimeStart,TimeEnd)
SELECT [StockItemID], [StockItemName] ,[SupplierID] ,[ColorID] ,[UnitPackageID] ,[OuterPackageID] ,
[Brand] ,[Size] ,[LeadTimeDays] ,[QuantityPerOuter] ,[IsChillerStock] ,[Barcode] ,[TaxRate]  ,[UnitPrice],
[RecommendedRetailPrice] ,[TypicalWeightPerUnit] ,[MarketingComments]  ,[InternalComments], JSON_VALUE(WS.CustomFields, '$.CountryOfManufacture'), 
Tags, SearchDetails,ws.ValidFrom,ws.ValidTo
FROM Warehouse.StockItems_Archive  WS
COMMIT;
ALTER TABLE ods.StockItem
ADD PERIOD FOR SYSTEM_TIME (TimeStart,TimeEnd);
-- Turn on system versioning
ALTER TABLE ods.StockItem
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = ods.StockItemHistory, DATA_CONSISTENCY_CHECK = ON));
Select * FROM ods.StockItem
DELETE FROM ods.StockItem
/*
23.	Rewrite your stored procedure in (21). 
Now with a given date, it should wipe out all the order data
prior to the input date and load the order data that was placed in the next 7 days following the input date.
*/
Create table dbo.Orders(
    orderId int,
    orderDate Date,
    orderTotal varchar(255),
	customerId int
)
Drop PROCEDURE get7FromDate;
CREATE PROCEDURE get7FromDate
(@dateinput DATE)
AS
BEGIN TRY
 IF (@dateinput !=isnull((SELECT MIN(orderDate) FROM dbo.Orders ),cast('1111-01-01' as date)) )
  BEGIN
  BEGIN TRANSACTION
  DELETE FROM dbo.Orders  
  WHERE OrderDate < @dateinput;
  INSERT INTO dbo.Orders(orderId ,orderDate ,orderTotal,customerId )
  SELECT  so.OrderID,so.OrderDate,[dbo].[OrderTotal](so.OrderID),so.CustomerID
  FROM sales.Orders so
  WHERE so.OrderDate BETWEEN DATEADD(DAY, 1, @dateinput) AND DATEADD(DAY, 7, @dateinput);
  COMMIT TRANSACTION
  END
ELSE 
BEGIN
  RAISERROR ('Date already inserted',16, 1) 
 END
 END TRY
BEGIN CATCH
  Print ERROR_MESSAGE()
  Print 'transaction rolled back'
  --ROLLBACK TRANSACTION
END CATCH

EXEC get7FromDate @dateinput = '2013-1-1' 
EXEC get7FromDate @dateinput = '2013-1-2' 

 DELETE  FROM dbo.Orders 
  WHERE (orderDate = '2013-1-1');
DELETE FROM dbo.Orders
select *
from dbo.Orders 
order by orderDate

/*24.	Consider the JSON file:

{
   "PurchaseOrders":[
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"7",
         "UnitPackageId":"1",
         "OuterPackageId":[6,7],
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-01",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"WWI2308"
      },
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"5",
         "UnitPackageId":"1",
         "OuterPackageId":"7",
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-025",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"269622390"
      }
   ]
}
Looks like that it is our missed purchase orders. 
Migrate these data into Stock Item, Purchase Order and Purchase Order Lines tables. Of course, save the script.

*/
drop table #temp
Create Table #temp(
  StockItemName    NVARCHAR(100) ,
         SupplierID       int           ,
         UnitPackageId    int           ,
         OuterPackageId   int ,
         Brand            NVARCHAR(50)  ,
         LeadTimeDays     int           ,
         QuantityPerOuter int           ,
         TaxRate          DECIMAL(18,3) ,
         UnitPrice        DECIMAL(18,2) ,
         RecommendedRetailPrice DECIMAL(18,2) ,
         TypicalWeightPerUnit   DECIMAL(18,3) ,
         CustomFields     NVARCHAR(max)  ,
         Tags             NVARCHAR(max)  ,
         OrderDate        DATE           ,
         DeliveryMethod   NVARCHAR(50)   ,
         ExpectedDeliveryDate DATE       ,
         SupplierReference NVARCHAR(20)  
)
DECLARE @PurchaseOrder NVARCHAR(max) = N'{
 
     "PurchaseOrders":[ {
         "StockItemName":"Panzer Video Game",
         "Supplier":"7",
         "UnitPackageId":"1",
         "OuterPackageId":[6,7],
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-01",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"WWI2308"
      },
      {
         "StockItemName":"Panzer Video Game",
         "Supplier":"5",
         "UnitPackageId":"1",
         "OuterPackageId":"7",
         "Brand":"EA Sports",
         "LeadTimeDays":"5",
         "QuantityPerOuter":"1",
         "TaxRate":"6",
         "UnitPrice":"59.99",
         "RecommendedRetailPrice":"69.99",
         "TypicalWeightPerUnit":"0.5",
         "CountryOfManufacture":"Canada",
         "Range":"Adult",
         "OrderDate":"2018-01-25",
         "DeliveryMethod":"Post",
         "ExpectedDeliveryDate":"2018-02-02",
         "SupplierReference":"269622390"
      }]}'
DECLARE @path NVARCHAR(max)  ='$.PurchaseOrders.OuterPackageId'
DECLARE @pathN int =0
SET @path ='$.PurchaseOrders['+cast(@pathN as NVARCHAR)+']'

WHILE (ISJSON(JSON_QUERY(@PurchaseOrder,@path))=1)
BEGIN 
DECLARE @arr int= 0
IF(JSON_QUERY(@PurchaseOrder,@path+'.OuterPackageId') is NOT NULL)
BEGIN
SELECT
    @arr= @arr*10+CAST(a.[VALUE] as int)
FROM (SELECT  [VALUE]  FROM OPENJSON (@PurchaseOrder, @path+'.OuterPackageId'))as a
END

insert into #temp (StockItemName,SupplierID,UnitPackageId,OuterPackageId,
         Brand,LeadTimeDays,QuantityPerOuter,TaxRate,UnitPrice,RecommendedRetailPrice,
         TypicalWeightPerUnit,CustomFields,Tags,OrderDate,DeliveryMethod,
		 ExpectedDeliveryDate,SupplierReference) 
		 VALUES(
		 JSON_VALUE(@PurchaseOrder,@path+'.StockItemName'),
		 JSON_VALUE(@PurchaseOrder,@path+'.Supplier'),
		 JSON_VALUE(@PurchaseOrder,@path+'.UnitPackageId'),
		 iif(@arr=0,(JSON_VALUE(@PurchaseOrder,@path+'.OuterPackageId')),@arr),		 
		 JSON_VALUE(@PurchaseOrder,@path+'.Brand'),
		 JSON_VALUE(@PurchaseOrder,@path+'.LeadTimeDays'),
		 JSON_VALUE(@PurchaseOrder,@path+'.QuantityPerOuter'),
		 JSON_VALUE(@PurchaseOrder,@path+'.TaxRate'),
		 JSON_VALUE(@PurchaseOrder,@path+'.UnitPrice'),
		 JSON_VALUE(@PurchaseOrder,@path+'.RecommendedRetailPrice'),
		 JSON_VALUE(@PurchaseOrder,@path+'.TypicalWeightPerUnit'),
		 JSON_VALUE(@PurchaseOrder,@path+'.CountryOfManufacture'),
		 JSON_VALUE(@PurchaseOrder,@path+'.Range'),
		 JSON_VALUE(@PurchaseOrder,@path+'.OrderDate'),
		 JSON_VALUE(@PurchaseOrder,@path+'.DeliveryMethod'),
		 JSON_VALUE(@PurchaseOrder,@path+'.ExpectedDeliveryDate'),
		 JSON_VALUE(@PurchaseOrder,@path+'.SupplierReference')
		 )
	SET	 @pathN= @pathN +1
	SET @path ='$.PurchaseOrders['+cast(@pathN as NVARCHAR)+']'
END
select * from #temp
delete from [Warehouse].[PackageTypes] where [PackageTypeID]=69
INSERT INTO [Warehouse].[PackageTypes]([PackageTypeID],[PackageTypeName],[LastEditedBy])
VALUES (67,'Yuan',1)
INSERT INTO  warehouse.stockItems( StockItemName, SupplierID, 
	UnitPackageID, OuterPackageID, Brand, LeadTimeDays, QuantityPerOuter,IsChillerStock,
	TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, 
	CustomFields,LastEditedBy)
	SELECT t.StockItemName+'('+CAST(t.SupplierID as NVARCHAR(20) )+')',t.SupplierID,t.UnitPackageId,t.OuterPackageId,t.Brand,t.LeadTimeDays,
	t.QuantityPerOuter,0,t.TaxRate,t.UnitPrice,t.RecommendedRetailPrice,t.TypicalWeightPerUnit,NULL,1
	FROM #temp as t

	INSERT INTO Purchasing.PurchaseOrders( SupplierID, OrderDate, DeliveryMethodID, ContactPersonID, 
	SupplierReference, IsOrderFinalized, LastEditedBy)
	SELECT t.SupplierID,t.OrderDate,1,ps.PrimaryContactPersonID,t.SupplierReference,1,1
	FROM #temp as t 
	join [Purchasing].[Suppliers] ps on t.SupplierID=ps.SupplierID
	
	
	INSERT INTO Purchasing.PurchaseOrderLines(PurchaseOrderID, StockItemID, OrderedOuters,[Description],
	ReceivedOuters, PackageTypeID, IsOrderLineFinalized, LastEditedBy)
	SELECT ps.PurchaseOrderID,228,t.OuterPackageId,t.StockItemName,t.QuantityPerOuter,1,1,1
	FROM #temp as t 
	join [Purchasing].PurchaseOrders ps on t.OrderDate=ps.OrderDate

/*
25.	Revisit your answer in (19). Convert the result in JSON string and save it to the server using TSQL FOR JSON PATH.
*/

	Select *
		From [dbo].[StockGroupSoldByName]
		Order by yr
		FOR JSON AUTO
/*
26.	Revisit your answer in (19). Convert the result into an XML string and save it to the server using TSQL FOR XML PATH.
*/
Select *
		From [dbo].[StockGroupSoldByName] 
		Order by yr
		FOR XML AUTO,ELEMENTS
/*
27.	Create a new table called ods.ConfirmedDeviveryJson with 3 columns (id, date, value). 
Create a stored procedure, input is a date. 
The logic would load invoice information (all columns) as well as invoice line information (all columns) 
and forge them into a JSON string and then insert into the new table just created. 
Then write a query to run the stored procedure for each DATE that customer id 1 got something delivered to him.
*/
Create Table ods.ConfirmedDeviveryJson(
    id int not null IDENTITY(1,1)  PRIMARY KEY , 
	[date] DATE NOT NULL,
	[value] NVARCHAR(max) NOT NULL )
DROP TABLE ods.ConfirmedDeviveryJson

Drop PROCEDURE forge;
CREATE PROCEDURE forge
(@dateinput DATE)
AS
 BEGIN 
 INSERT INTO ods.ConfirmedDeviveryJson([date],[value]) 
 VALUES(@dateinput,
 (SELECT * FROM
 Sales.Invoices SI
 LEFT JOIN Sales.InvoiceLines SIL on si.InvoiceID=sil.InvoiceID 
 where si.CustomerID=1 and  CAST(si.ConfirmedDeliveryTime as date)= @dateinput
 FOR JSON AUTO)
 )
 END
--EXEC forge @dateinput = '2013-03-13' 
-- run query for each day
DECLARE @StarDate DATE, @MaxxDate DATE  
SELECT @StarDate=MIN(CAST(si.ConfirmedDeliveryTime as date)),@MaxxDate=MAX(CAST(si.ConfirmedDeliveryTime as date))
FROM
 Sales.Invoices SI
 LEFT JOIN Sales.InvoiceLines SIL on si.InvoiceID=sil.InvoiceID 
WHERE si.CustomerID=1 
WHILE (@StarDate<@MaxxDate )
BEGIN
if( @StarDate in (select CAST(ConfirmedDeliveryTime as date) from sales.Invoices where CustomerID=1))
begin
EXEC forge @dateinput = @StarDate
end 
SET @StarDate = DATEADD(DAY,1,@StarDate)
END
select * from ods.ConfirmedDeviveryJson
 
/*


28.	Write a short essay talking about your understanding of transactions, locks and isolation levels.
Transaction is an unit of work, including all kinds of query and activities to modify the data. By default, each statement is a transaction. And we can add multiple statement into one unit of work by define a transaction.
Transaction has four properties: 
Atomicity: which means statements in a transaction can only be committed or rollback together.
Consistency: which means data should be in a consistent state for all user during a transaction start and end.
Isolation: Transactions can not see what others are doing, they access only intermediate data.
Durability: Changes made by transaction are not able to undo.
Locks are applied on resource to prevent others from accessing it. It avoid the conflicts and ensure the consistency of transaction. Locks interact between transactions help us implement the isolation level.
Isolation level the consistency level of data you want the transaction to access. 
There are four different isolation level:
Read Uncommitted is the lowest level that has no lock on it. Transaction can dirty read the uncommitted data. Read committed is the default isolation level of SQL server that prevent dirty read. In this level, reader got the shared lock after writer committed the transaction.
The REPEATABLE READ is a higher isolation level that ensure the consistency between reads in same transaction. Under this condition, locks applied to prevent other locks before reader end the transaction. 
The SERIALIZABLE is the highest level that prevent phantom reads of data that changed between the reads of transaction. This means lock are applied not only on the current rows if resource but also the future rows in the range of filter keys. 

29.	Write a short essay, plus screenshots talking about performance tuning in SQL Server.
Must include Tuning Advisor, Extended Events, DMV, Logs and Execution Plan.

*/





/*
Assignments 30 - 32 are group assignments.
30.	Write a short essay talking about a scenario: 
Good news everyone! We (Wide World Importers) just brought out a small company called ¡°Adventure works¡±! 
Now that bike shop is our sub-company. 
The first thing of all works pending would be to merge the user logon information, 
person information (including emails, phone numbers) and products (of course, add category, colors) to WWI database. 
Include screenshot, mapping and query.
*/
SELECT p.FirstName+''+p.MiddleName+''+p.LastName as [FullName],
p.LastName as [PreferredName] ,p.LastName as [SearchName],CASE WHEN he.LoginID  IS NULL THEN 0 ELSE 1 END as [IsPermittedToLogon], 
he.LoginID as [LogonName],1 as [IsExternalLogonProvider],ppd.PasswordHash as [HashedPassword],1 as [IsSystemUser],
he.CurrentFlag as [IsEmployee], CASE WHEN he.JobTitle='Sales Representative' THEN 1 ELSE 0 END as [IsSalesperson],
null as [UserPreferences],ppe.PhoneNumber as [PhoneNumber], null as [FaxNumber],pea.EmailAddress as [EmailAddress]
,null as [Photo],null as [CustomFields]
INTO #temp
FROM [Person].[Person] p 
JOIN[Person].[Password] ppd on p.BusinessEntityID = ppd.BusinessEntityID
JOIN[Person].[PersonPhone] ppe on p.BusinessEntityID = ppe.BusinessEntityID
JOIN[Person].[EmailAddress] pea on p.BusinessEntityID=pea.BusinessEntityID
JOIN[Person].[BusinessEntityAddress] bea on p.BusinessEntityID=bea.BusinessEntityID
left JOIN [HumanResources].[Employee] he on p.BusinessEntityID=he.BusinessEntityID

select * from #temp





/*
31.	Database Design: OLTP db design request for EMS business: 
when people call 911 for medical emergency, 911 will dispatch UNITs to the given address. 
A UNIT means a crew on an apparatus (Fire Engine, Ambulance, Medic Ambulance, Helicopter, EMS supervisor). 
A crew member would have a medical level (EMR, EMT, A-EMT, Medic). 
All the treatments provided on scene are free. 
If the patient needs to be transported, that¡¯s where the bill comes in. 
A bill consists of Units dispatched (Fire Engine and EMS Supervisor are free), 
crew members provided care (EMRs and EMTs are free), 
Transported miles from the scene to the hospital (Helicopters have a much higher rate, as you can image) 
and tax (Tax rate is 6%). Bill should be sent to the patient insurance company first. If there is a deductible, 
we send the unpaid bill to the patient only. Don¡¯t forget about patient information, medical nature and bill paying status.

32.	Remember the discussion about those two databases from the class, also remember, those data models are not perfect. 
You can always add new columns (but not alter or drop columns) to any tables. 
Suggesting adding Ingested DateTime and Surrogate Key columns. Study the Wide World Importers DW. 
Think the integration schema is the ODS. 
Come up with a TSQL Stored Procedure driven solution to move the data from WWI database to ODS, 
and then from the ODS to the fact tables and dimension tables. By the way, WWI DW is a galaxy schema db. Requirements:
a.	Luckly, we only start with 1 fact: Order. Other facts can be ignored for now.
b.	Add a new dimension: Country of Manufacture. It should be given on top of Stock Items.
c.	Write script(s) and stored procedure(s) for the entire ETL from WWI db to DW.

*/
CREATE TABLE Dimension.Manufacture
(
    id int not null IDENTITY(1,1)  PRIMARY KEY , 
	[Stock Item ID] int NOT NULL FOREIGN KEY REFERENCES [Dimension].[Stock Item]([Stock Item Key]),
	[Country] NVARCHAR(max) NOT NULL 
	)
CREATE PROCEDURE ETL
--(@input  )
AS
 BEGIN 
SELECT --wsc.PostalCityID
     -- ,wso.CustomerID
     --wsol.StockItemID,
     -- ,
	 wso.OrderDate
      ,wso.PickingCompletedWhen
      --,wso.SalespersonPersonID
     -- ,wso.PickedByPersonID
      ,wso.OrderID
      ,wso.BackorderOrderID
      ,wsol.Description
      ,wsol.PackageTypeID
      ,wsol.Quantity
      ,wsol.UnitPrice
      ,wsol.TaxRate
     -- ,[Total Excluding Tax]
      ,wsil.TaxAmount
     -- ,[Total Including Tax]
      --,[Lineage Key]
      ,wsc.PostalCityID
      ,wso.CustomerID
      ,wsol.StockItemID
      ,wso.SalespersonPersonID
      ,wso.PickedByPersonID
      ,wso.LastEditedWhen into #temp 
FROM [WideWorldImporters].[Sales].[Orders] WSO
JOIN [WideWorldImporters].Sales.Customers WSC on wso.CustomerID=wsc.CustomerID
JOIN [WideWorldImporters].[Sales].OrderLines wsol on wso.OrderID=wsol.OrderID
JOIN [WideWorldImporters].[Sales].Invoices wsi on wsi.OrderID=wso.OrderID
JOIN [WideWorldImporters].[Sales].InvoiceLines wsil on wsil.InvoiceID=wsi.InvoiceID

INSERT INTO Integration.Order_Staging(
      [Order Date Key]
      ,[Picked Date Key]
      ,[WWI Order ID]
      ,[WWI Backorder ID]
      ,[Description]
      ,[Package]
      ,[Quantity]
      ,[Unit Price]
      ,[Tax Rate]
      ,[Tax Amount]
      ,[WWI City ID]
      ,[WWI Customer ID]
      ,[WWI Stock Item ID]
      ,[WWI Salesperson ID]
      ,[WWI Picker ID]
      ,[Last Modified When])
	  select* from #temp
--DELETE FROM  Integration.Order_Staging  
--select * from Integration.Order_Staging 
--drop table #temp
MERGE [Dimension].[Stock Item] AS TARGET
USING Integration.Order_Staging AS SOURCE 
ON (TARGET.[WWI Stock Item ID] = SOURCE.[WWI Stock Item ID]) 
--When records are matched, update the records if there is any change
WHEN MATCHED 
THEN UPDATE SET 
TARGET.[WWI Stock Item ID] = SOURCE.[WWI Stock Item ID], TARGET.[Stock Item] = SOURCE. [Description]
--When no records are matched, insert the incoming records from source table to target table
WHEN NOT MATCHED  
THEN INSERT ([WWI Stock Item ID],[Stock Item],,[Color],[Selling Package],[Buying Package],[Brand],[Size],[Lead Time Days],[Quantity Per Outer]
      ,[Is Chiller Stock],[Barcode],[Tax Rate],[Unit Price],[Recommended Retail Price],[Typical Weight Per Unit],[Photo],[Valid From]
      ,[Valid To],[Lineage Key])
	  VALUES (SOURCE.[WWI Stock Item ID], SOURCE.[Description], S'N/A','ignore','ignore','ignore','ignore'
      ,0,0,0,'ignore',0,0,0,0,0,GETDATE(),'9999-12-31 23:59:59.9999999',0)

/*MERGE [City Key] AS TARGET
USING  Integration.Order_Staging  
ON (TARGET.[WWI City Key] = SOURCE.[City Key]) */
/*MERGE [Customer Key] AS TARGET
USING  Integration.Order_Staging  
ON (TARGET.[WWI Customer Key] = SOURCE.[Customer Key]) */
/*MERGG:[Stock Item Key],[Order Date Key],[Picked Date Key],[Salesperson Key],[Picker Key] on WWI Key */
--Then UPDATE Integration.Order_Staging from above tables.
--THEN MERGE Fact.Order
MERGE [Fact].[Order] AS TARGET
USING Integration.Order_Staging AS SOURCE 
ON (TARGET.[WWI Stock Item ID] = SOURCE.[WWI Stock Item ID]) 
--When records are matched, update the records if there is any change
WHEN MATCHED 
THEN UPDATE SET 
TARGET.[City Key] = SOURCE.[City Key],
TARGET.[Customer Key] = SOURCE. [Customer Key],
TARGET.[Stock Item Key] = SOURCE. [Stock Item Key],
TARGET.[Order Date Key] = SOURCE. [Order Date Key],
TARGET.[Picked Date Key] = SOURCE. [Picked Date Key],
TARGET.[Salesperson Key] = SOURCE. [Salesperson Key],
TARGET.[Picker Key] = SOURCE. [Picker Key],
TARGET.[WWI Order ID] = SOURCE. [WWI Order ID],
TARGET.[WWI Backorder ID] = SOURCE. [WWI Backorder ID],
TARGET.[Description] = SOURCE. [Description],
TARGET.[Package] = SOURCE. [Package],
TARGET.[Quantity] = SOURCE. [Quantity],
TARGET.[Unit Price] = SOURCE. [Unit Price],
TARGET.[Tax Rate] = SOURCE. [Tax Rate],
TARGET.[Total Excluding Tax] = SOURCE. [Total Excluding Tax],
TARGET.[Tax Amount] = SOURCE. [Tax Amount],
TARGET.[Total Including Tax] = SOURCE. [Total Including Tax],
TARGET.[Lineage Key] = SOURCE. [Lineage Key],
--When no records are matched, insert the incoming records from source table to target table
WHEN NOT MATCHED  
THEN INSERT ([City Key],[Customer Key],[Stock Item Key],[Order Date Key],[Picked Date Key],[Salesperson Key],[Picker Key]
      ,[WWI Order ID],[WWI Backorder ID],[Description],[Package],[Quantity],[Unit Price],[Tax Rate],[Total Excluding Tax]
      ,[Tax Amount],[Total Including Tax],[Lineage Key])
	  VALUES (SOURCE.[City Key],SOURCE.[Customer Key],SOURCE.[Stock Item Key],SOURCE.[Order Date Key],SOURCE.[Picked Date Key],SOURCE.[Salesperson Key],
	  SOURCE.[Picker Key],SOURCE.[WWI Order ID],SOURCE.[WWI Backorder ID],SOURCE.[Description],SOURCE.[Package],SOURCE.[Quantity],SOURCE.[Unit Price],SOURCE.[Tax Rate],
	  SOURCE.[Total Excluding Tax],SOURCE.[Tax Amount],SOURCE.[Total Including Tax],SOURCE.[Lineage Key])
 END

