-- List of manufacture countrys and count of types of stockitems of each country
-- List of StockGroups and number of stockitems of each group, using stockgroup name as columns
-- List of customers and their ordered stockitems totals (unit price * quantity) on 2014-12-31 (using the unit price of that day)
-- List of customers who are buying more stockitems (quantity only) each year from 2013 to 2016


-- List of manufacture countrys and count of types of stockitems of each country
select  json_value(SI.CustomFields,'$.CountryOfManufacture') as Country,COUNT(SI.StockItemID)
from [Warehouse].[StockItems] as SI
group by json_value(SI.CustomFields,'$.CountryOfManufacture');

-- List of StockGroups and number of stockitems of each group, using stockgroup name as columns
DECLARE 
    @columns NVARCHAR(MAX) = '', 
    @sql     NVARCHAR(MAX) = '';
 
-- select the category names
SELECT 
    @columns+=QUOTENAME(StockGroupName) + ','
FROM 
   [Warehouse].[StockGroups]
ORDER BY 
    StockGroupName;
 
-- remove the last comma
SET @columns = LEFT(@columns, LEN(@columns) - 1);
 print @columns
-- construct dynamic SQL
SET @sql ='
  SELECT * FROM (
  select SG.StockGroupName, COUNT(SIG.StockItemID) as aat
        from  [Warehouse].[StockGroups]as SG 		
		left join [Warehouse].[StockItemStockGroups] as SIG on SG.StockGroupID=SIG.StockGroupID
		group by sg.StockGroupName
) t 
PIVOT(
sum(t.aat) for  StockGroupName in ('+ @columns +')
) AS pivot_table;
';
EXECUTE sp_executesql @sql;

 SELECT 'numbers' as GroupName, [Airline Novelties],[Clothing],[Computing Novelties],[Furry Footwear],[Mugs],[Novelty Items],[Packaging Materials],[Toys],[T-Shirts],[USB Novelties]
 FROM (
  select SG.StockGroupName, SIG.StockItemID as aat
        from  [Warehouse].[StockGroups]as SG 		
		left join [Warehouse].[StockItemStockGroups] as SIG on SG.StockGroupID=SIG.StockGroupID
		--group by SG.StockGroupName
) t 
PIVOT(
COUNT(t.aat) for  StockGroupName in ([Airline Novelties],[Clothing],[Computing Novelties],[Furry Footwear],[Mugs],[Novelty Items],[Packaging Materials],[Toys],[T-Shirts],[USB Novelties]
)
) AS pivot_table;


-- List of customers and their ordered stockitems totals (unit price * quantity) on 2014-12-31 (using the unit price of that day)
select sc.CustomerName,ws.StockItemName, sum(sol.Quantity)*ws.UnitPrice as total
from sales.Customers FOR SYSTEM_TIME AS OF '2014-12-31' sc
     join Sales.Orders so 
	 on sc.CustomerID=so.CustomerID and so.OrderDate = cast('2014-12-31' as date)
	 join Sales.OrderLines sol 
	 on sol.OrderID=so.OrderID 
	 join Warehouse.StockItems FOR SYSTEM_TIME AS OF '2014-12-31' ws 
	 on sol.StockItemID=ws.StockItemID  
	 group by sc.CustomerName,ws.StockItemName,ws.UnitPrice;

-- List of customers who are buying more stockitems (quantity only) each year from 2013 to 2016
WITH cte AS(
select sc.CustomerID,sc.CustomerName,YEAR(so.OrderDate) as yr ,sum(sol.Quantity) amt
from Sales.Orders so 
join Sales.OrderLines sol on so.OrderID=sol.OrderID
join Sales.Customers sc on so.CustomerID=sc.CustomerID
group by sc.CustomerID,sc.CustomerName,YEAR(so.OrderDate)
)
select c1.CustomerID,c1.CustomerName, IIF(c1.amt<c2.amt , 1, 0) as increase, count(c1.yr) as ct
from cte c1 join cte c2 on c1.CustomerID= c2.CustomerID and c1.yr= (c2.yr-1)
group by c1.CustomerID,c1.CustomerName,IIF(c1.amt<c2.amt , 1, 0)
having  IIF(c1.amt<c2.amt , 1, 0) >0 and count(c1.yr) =2;






select * from 
(select sg.StockGroupName groupName, sih.QuantityOnHand groupQty 
from Warehouse.StockGroups sg 
join Warehouse.StockItemStockGroups sisg on sg.StockGroupID = sisg.StockGroupID
join Warehouse.StockItems si on si.StockItemID = sisg.StockItemID
join Warehouse.StockItemHoldings sih on sih.StockItemID = si.StockItemID) temp_table
pivot
(sum(groupQty)
for groupName in ([Airline Novelties],[Clothing], [Computing Novelties], [Furry Footwear], [Mugs], [Novelty Items], [Packaging Materials],[Toys], [T-Shirts], [USB Novelties])) pivot_table