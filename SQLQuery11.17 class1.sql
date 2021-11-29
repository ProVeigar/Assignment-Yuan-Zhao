
-- top 10 customers who have most quantity of stockitems purchased (customerid, name, totalQuantity)

SELECT top (10) 
      c.CustomerName,c.[CustomerID],sum(o.Quantity) as quality
	  from Sales.Orders t 
		   join Sales.OrderLines o on o.OrderID= t.OrderID
		   join Sales.Customers c on c.CustomerID=t.CustomerID 
	  group by c.CustomerID, c.CustomerName
	  order by quality desc

-- top 10 customers who have most quantity of stockitems purchased, and the top 3 stockitems they purchased (customerid, name, item1, quantity1, item2, quantity 2, item3, quantity3)

with TP as(
	 SELECT top (10) 
      c.CustomerName,c.CustomerID,sum(o.Quantity) as quality
	  from Sales.Invoices t 
		   join Sales.InvoiceLines o on o.InvoiceID= t.InvoiceID
		   join Sales.Customers c on c.CustomerID=t.CustomerID 
	  group by c.CustomerID, c.CustomerName
	  order by quality desc
),
	 RK AS (
		   SELECT 
		 tmp.CustomerID,
		 tmp.StockItemID,
		 tmp.CustomerName,
		 tmp.ss as quantity,
		 row_number()over(partition by tmp.CustomerID order by tmp.ss desc) as rk
			from(
				select 
				t.CustomerID,
				tp.CustomerName,
				o.StockItemID, 
				 sum(o.Quantity)as ss
					from Sales.Invoices t 
						join Sales.InvoiceLines o on o.InvoiceID= t.InvoiceID
						join tp on tp.CustomerID = t.CustomerID
				group by t.CustomerID, tp.CustomerName, o.StockItemID
				)as tmp
				--where row_number()over(partition by tmp.CustomerID order by tmp.ss desc) <4
				--group by  tmp.CustomerID, tmp.StockItemID,tmp.CustomerName,tmp.ss					
			)
  
	  select r1.CustomerID,r1.CustomerName, 
	  r1.StockItemID as Item1, r1.quantity as quantity1,
	  r2.StockItemID as Item2, r2.quantity as quantity2,
	  r3.StockItemID as Item3, r3.quantity as quantity3
	  from RK r1 
	  join RK r2 on r1.CustomerID=r2.CustomerID and r1.rk = r2.rk-1
	  join RK r3 on r3.CustomerID=r1.CustomerID and r1.rk = r3.rk-2
	  where r1.rk=1
	  order by r1.CustomerID	  
	  
 -- all stockitems that we imported (purchase order) more than we sell (orders) in the year 2015
Select * from
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
-- All Cities in USA that we do not have a customer in

SELECT CityName
FROM Application.Cities AS a
JOIN Application.StateProvinces AS s on a.StateProvinceID=s.StateProvinceID
JOIN Application.Countries as u on s.CountryID=u.CountryID AND u.CountryName = 'United States'
where a.CityID Not in ( SELECT PostalCityID FROM Sales.Customers)
