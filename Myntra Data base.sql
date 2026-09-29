create database Myntra;
use Myntra;
select top 2 *from orders;
select * from Returns;
select*from Customers;
select * from orders;
/*Q1. How many new customers joined each month this year?
Hint:
Use YEAR() and MONTH() on signup_date.
Filter current year with WHERE YEAR(signup_date)=2025.
Group by both year & month.*/
 with Customertableexpression as (select year(signup_date) as year,
count(*) as no_of_customers
from Customers
group by YEAR(Signup_date))
select *,lag(no_of_customers) over (order by year) as previous_year,
100*(no_of_customers-lag(no_of_customers) over (order by year))/lag(no_of_customers) over (order by year) as percentage
from Customertableexpression;

/*Q2. Average time between signup and first order.
 Hint:
	• Join Customers and Orders.
	• Use MIN(order_date) per customer as their first purchase.
	• Use DATEDIFF(day, signup_date, first_order_date) to get gap.
	• Take AVG() of those gaps.*/
with cte1 as (
select o.customer_id,min(o.order_date) as firstpurchase,c.signup_date 
from  orders o join customers c  on o.customer_id=c.customer_id
group by o.customer_id,c.signup_date
)
select avg(DATEDIFF(DAY,signup_date,firstpurchase)) as avgdays
from cte1
----
with cte1 as (
select o.customer_id,min(o.order_date) as firstpurchase,c.signup_date 
from  orders o join customers c  on o.customer_id=c.customer_id
group by o.customer_id,c.signup_date
)
select *,DATEDIFF(DAY,signup_date,firstpurchase)as differnce
from cte1
order by customer_id asc;


/*Q3. % of customers with more than 10 order.
 Hint:
	• Count total customers.
	• Count customers with HAVING COUNT(order_id)>10.
	• Divide and multiply by 100 for percentage.*/
	with cte1 as (
	select o.customer_id,count(order_id) as total from orders o join Customers c on o.customer_id=c.customer_id
	group by o.customer_id),
    cte2 as (select * ,case when total >10 then 1 else 0 end as orderabove10
	from cte1)
	select 100*sum(orderabove10)/count(*)
	from cte2;
	---
	with cte1 as (
	select o.customer_id,count(order_id) as total from orders o join Customers c on o.customer_id=c.customer_id
	group by o.customer_id)
    select 100*sum(case when total >10 then 1 else 0 end )/count(*) as percentage
	from cte1
	

	order by customer_id asc;

/*Q4. Churn rate — customers inactive for 90+ days.
 Hint:
	• Find each customer’s MAX(order_date).
	• Compare with GETDATE().
	• Customers where difference > 90 are churned.(case where where>90 =1) else 
	• Divide by total customers.*/
	with cte1 as (select o.customer_id,max(order_date)as maxdate,cast(getdate() as date)as today from orders o
	join Customers c on o.customer_id=c.customer_id
	group by o.customer_id)
	select  100*sum(case when DATEDIFF(DAY,maxdate,today)>90 then 1 else 0 end)/COUNT(*) as churn_rate
	from cte1



/*Q5. Repeat purchase rate by city.
 Hint:
	• Join Customers → Orders.
	• Group by city.
	• Count distinct customers with more than one order in each city. 
	(1st cte count orders, group by city, customerid), 2nd cte.. Distinct customerId total Customer, 
	count(distintct case when ordercount>1 then custid end) as repeat customers*/
WITH cte1 AS (
SELECT 
    c.city,
    o.customer_id,
    COUNT(o.order_id) AS order_count
FROM Customers c JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.city, o.customer_id),
cte2 AS (
SELECT 
    city,
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT CASE 
        WHEN order_count > 1 THEN customer_id 
    END) AS repeat_customers
FROM cte1
GROUP BY city
)

SELECT 
    city,
    total_customers,
    repeat_customers,
    (repeat_customers * 100.0 / total_customers) AS repeat_purchase_rate
FROM cte2;
	• Compare to total customers in that city.
/*Q6. Which month had the most new signups?
 Hint:
	• Group by MONTH(signup_date).
	• Use COUNT(*).
	• Order descending or use TOP 1.*/
	with cte1 as( select year(signup_date) as yr , eomonth(signup_date) as month,count(customer_id) as total_signups
	from Customers
	group by year(signup_date),eomonth(signup_date)
	),
	cte2 as (select *,rank() over(order by total_signups) as rnk	
	from cte1)
	select *from cte2
	where rnk<=2;


-----




 Sales & Revenue Performance Analytics
/*Q7. Monthly revenue trend 
 Hint:
	• Join Orders and Products.
	• SUM(quantity*price) → total revenue.
	• Group by YEAR(order_date), MONTH(order_date).*/
select * from Returns
select * from orders
select * from Customers
select * from Products
select* from Partners
	
select YEAR(order_date) as year,MONTH(order_date) as month,
format(sum(cast(o.quantity as int)*p.price),'N0','en-IN') as total_revenue
from orders o  join Products p on o.product_id=p.product_id
group by YEAR(order_date),MONTH(order_date)
order by year asc

 
/*Q9. Average order value (AOV) trend.
 Hint:
	• AOV = total revenue / number of orders.
	• Use CTE or subquery: one for revenue, one for order count.
	• Group by month for trend.*/
	with cte1 as (select YEAR(order_date) as yr,MONTH(order_date) as month,count(order_id) as total_orders from orders
	group by year(order_date),month(order_date)
	),
   cte2 as (select year(order_date) as yr,month(o.order_date) as month,sum(cast(o.quantity as int)*p.price) as total_revenue
from orders o  join Products p on o.product_id=p.product_id
group by year(order_date),month(o.order_date))
SELECT cte1.yr,cte1.month,total_orders,cte2.total_revenue,(cte2.total_revenue / cte1.total_orders) AS AOV
from  cte1 join cte2 on cte1.yr=cte2.yr and cte1.month=cte2.month 
order by cte1.yr,cte1.month asc;
/*Q10. Top 10 revenue-generating customers.
 Hint:
	• Join Orders, Products, Customers.
	• Aggregate by customer.
	• Use SUM(quantity*price).
	• Sort DESC and TOP 10.*/
	select top 10 c.customer_name ,sum(cast(o.quantity as int)*p.price) as total_revenue
from orders o  join Products p on o.product_id=p.product_id
join customers c on o.customer_id=c.customer_id
group by c.customer_name
order by total_revenue desc
/*Q11. Top revenue partners (brands).
 Hint:
	• Join Orders → Products → Partners.
	• SUM(quantity*price) grouped by partner_name.*/
	select pa.partner_name, sum(cast(o.quantity as int)*p.price) as total_revenue
from Products p  join orders o on p.product_id=o.product_id
join Partners pa on p.partner_id=pa.partner_id
group by pa.partner_name
order by total_revenue desc



/*Q12. Revenue per customer by city.
 Hint:
	• Join Orders → Products → Customers.
	• Group by city.
	• Divide SUM(revenue) by COUNT(DISTINCT customer_id).*/
	with cte1 as (select  c.city, count(DISTINCT(c.customer_id)) as c_id,
sum(cast(o.quantity as int)*p.price) as total_revenue,SUM(CAST(o.quantity AS INT) * p.price) * 1.0 / 
COUNT(DISTINCT c.customer_id) AS revenue_per_customer
from orders o  join Products p on o.product_id=p.product_id
join Customers c  on o.customer_id=c.customer_id
group by c.city)
select city,c_id,revenue_per_customer,lag(revenue_per_customer) over (order by city)
from cte1;

select*from Customers
select* from orders
select* from Products
/*Q13. Compare revenue from new vs. returning customers.
 Hint:
	• Define “new” = customers ordering in signup year.
	• “Returning” = others.
	• Use CASE to label each and group by that label.*/
	with cte1 as (
select 
case when year(order_date) = year(signup_date) then 'New' else 'Returning' end as CustomerType,
sum(cast (o.quantity as bigint) * p.price) as Revenue
from orders o
join Customers c
on o.customer_id = c.customer_id
join Products p 
on o.product_id = p.product_id
group by case when year(order_date) = year(signup_date) then 'New' else 'Returning' end)
select *,sum(Revenue) over() as TotalRevenue, 100*Revenue/sum(Revenue) over() as '%Rev'
from cte1;
--nov1 class--
/* Returns & Customer Experience
Q14. Overall return rate.
 Hint:
	• Count returns ÷ total orders × 100.
	• Use subqueries or CTEs for clarity.*/
	select*from Returns
	select* from orders
	 with cte1 as (select count( distinct o.order_id) as total_orders,count(r.return_id) as returns
	from orders o left join returns r   on o.order_id=r.order_id)
	select total_orders,returns,concat((returns*100/total_orders),'%') as return_rate
	from cte1;

/*Q16. Category-wise return rate.
 Hint:
	• Join Orders → Products → Returns.
	• Count returns and total orders per category.
	• Compute percentage.*/
with cte1 as (select p.category,count(o.order_id)as total_orders ,count(r.order_id) as returns
from orders o  left join products p on o.product_id=p.product_id
left join returns r on o.order_id=r.order_id
group by p.category)
select*,concat((returns*100/total_orders),'%') as return_rate
	from cte1;
/*Q17. Partners with >10% return rate.
 Hint:
	• Same logic as above, but group by partner_name.
	• Add HAVING return_rate > 10.*/
with cte1 as (select pr.partner_name,count(o.order_id)as total_orders ,count(r.order_id) as returns
from orders o  left join products p on o.product_id=p.product_id
left join returns r on o.order_id=r.order_id
left join Partners pr on p.partner_id=pr.partner_id
group by pr.partner_name
HAVING COUNT(r.order_id) * 100 / COUNT(o.order_id)  >=3)
select*,(returns*100/total_orders) as return_rate
from cte1

select * from orders
select* from returns
select* from customers
select * from Products
select * from Partners
/*Q18. Cities with most returns.
Hint:
	• Join Returns → Orders → Customers.
	• Group by city, count returns.
	• Rank by count.*/
	select c.city,count(r.order_id) as returns,RANK() over( order by count(r.order_id) desc) as rnk from  Returns r  join orders o on r.order_id=o.order_id
	join Customers c on o.customer_id=c.customer_id
	group by c.city
	order by returns DESC;

/*Q19. Average return time (days between order and return).
Hint:
	• DATEDIFF(day, order_date, return_date) inside AVG().*/
select c.city, avg(datediff(day, order_date, return_date)) as Avg_returndays from orders o
join returns r on o.order_id = r.order_id
join customers c on o.customer_id = c.customer_id
group by c.city;

--Section 4 - Operational & Time Trends--
/*Q20. Which month has most orders?
 Hint:
	• Group by MONTH(order_date).
	• Use COUNT(*).
	• ORDER BY COUNT(*) DESC.*/
with cte1 as (select format(order_date,'MMM')as mnth_name,count(*) as total_order from orders
group by format(order_date,'MMM'))
Select * ,sum(total_order) over() as total_sum,100*total_order/sum(total_order) over() as '%of_GrandTotal'
from cte1
order by total_order desc
	

/*Q21. Weekend vs Weekday orders.
 Hint:
	• Use DATEPART(WEEKDAY, order_date).
	• Classify 6,7 → weekend else weekday.
	• Group by category.*/
	select 
case when datepart(WEEKDAY,order_date) =1 or datepart(WEEKDAY,order_date) =7 then 'Weekend' else 'weekday' end as daytype
,count(*) as Orders
from orders
group by case when datepart(WEEKDAY,order_date) =1 or datepart(WEEKDAY,order_date) =7 then 'Weekend' else 'weekday' end
---NOV 4 class--
/*Q22. Daily active customers (last 90 days).
 Hint:
	• Filter date using DATEADD(day, -90, GETDATE()).
	• Count distinct customer_id per day.*/
	select order_date,count(distinct customer_id) as customercount from orders 
	where order_date>=dateadd(day,-90,'2025-11-04')
	group by order_date
	order by order_date desc;
	select*from orders


/*Q23. Month-over-month revenue growth.
 Hint:
	• Use LAG() on monthly revenue.
	• Compute (revenue - prev_revenue)/prev_revenue * 100.*/
	with cte1 as (select eomonth(o.order_date) as month,sum(cast(o.quantity as int)*p.price) as total_revenue
	from orders o join products p on o.product_id=p.product_id
	group by eomonth(o.order_date)),
	cte2 as (select*,lag(total_revenue) over (order by month ) as previous_month
	from cte1
	)
	select*, 100.0*(total_revenue-previous_month)/previous_month as calculated_revenue
	from cte2;
	

	select * from orders
	select * from products
	sele3ct

/*Q24. Which category spiked in festive months (Oct–Dec)?
 Hint:
	• Filter MONTH(order_date) IN (10,11,12).
	• Compare revenue vs other months using CTEs or CASE.*/
with cte1 as (
select category, year(order_date) as Yr,
sum(cast(o.quantity as bigint) * p.price )as Frevenue
from orders o
join Products p
on o.product_id = p.product_id
where MONTH(order_date) in (10,11,12)
group by category ,year(order_date)),
cte2 as (
select category, year(order_date) as Yr,
sum(cast(o.quantity as bigint) * p.price )as Prev_revenue
from orders o
join Products p
on o.product_id = p.product_id
where MONTH(order_date) in (7,8,9)
group by category ,year(order_date))
select f.category, f.Yr, f.Frevenue as Frev , p.Prev_revenue  as prev,100.0*(f.Frevenue - p.Prev_revenue)/p.Prev_revenue as '%Changeinrevenue'
from cte1 f
join cte2 p on 
f.category = p.category and f.Yr = p.Yr

/*Storytelling & Decision Analytics
	Q25. What % of revenue comes from repeat buyers?
	 Hint:
		○ Identify customers with more than ten order.
		○ Compare their revenue vs total revenue.*/
		select * from orders
		select * from Customers
		with cte1 as(select  customer_id,count(order_id) as order_count,sum(cast(o.quantity as bigint) * p.price )as revenue
		from orders o join Products p on o.product_id=p.product_id
		group by customer_id)
		select sum(revenue),case when order_count >1 then 'repeat' else 'new' end as ctype
		from cte1
		group by case when order_count >1 then 'repeat' else 'new' end
	
	/*Q26. Products never ordered.
	 Hint:
		○ Use LEFT JOIN Products → Orders.
		○ WHERE order_id IS NULL.*/
SELECT *
FROM products p
LEFT JOIN orders o
ON p.product_id = o.product_id
WHERE o.order_id IS NULL;
	/*Q27. Customers from 2020 still active in 2025.
	 Hint:
		○ Filter customers with signup_date in 2020.
		○ Check if they have any order in 2025.*/
		 select * from  Customers c join orders o on c.customer_id=o.customer_id
		 where year(signup_date)=2020 and customer_name in (select customer_name from  Customers
		 where year(o.order_date)=2025)
		 select * from orders
----
SELECT *
FROM Customers c
JOIN Orders o
ON c.customer_id = o.customer_id
WHERE YEAR(c.signup_date) = 2020
AND YEAR(o.order_date) = 2025;
---		
	/*Q28. Customers growing their yearly spend.
	 Hint:
		○ Group by customer_id, YEAR(order_date).
		○ Use LAG() to compare current vs previous year’s spend.*/
		with cte1 as (select year(o.order_date) as yr, c.customer_id,sum(cast(o.quantity as bigint) * p.price )as revenue
		 from customers c join orders o on c.customer_id=o.customer_id
		 join Products p on p.product_id=o.product_id
		 group by year(o.order_date), c.customer_id)
		 select*,lag(revenue) over (PARTITION BY customer_id order by yr asc) as prvs_yr_revenue
		 from cte1
		 order by yr asc
	
	/*Q29. Year-over-year return rate trend.
	 Hint:
		○ Calculate return % per year using same logic as Q15.
		○ Use LAG() to find difference year-to-year.*/
	WITH cte1 AS (
SELECT 
    YEAR(o.order_date) AS yr,
    COUNT(o.order_id) AS total_orders,
    COUNT(r.order_id) AS returns
FROM orders o
LEFT JOIN returns r 
ON o.order_id = r.order_id
GROUP BY YEAR(o.order_date)
),

cte2 AS (
SELECT *,
100.0 * returns / total_orders AS return_rate
FROM cte1
)

SELECT *,
LAG(return_rate) OVER (ORDER BY yr) AS prev_year_return_rate,
return_rate - LAG(return_rate) OVER (ORDER BY yr) AS yoy_change
FROM cte2
ORDER BY yr;

	
	/*Q30. Which category has best revenue-to-return ratio?
	Hint:
		○ Join Orders, Products, Returns.
		○ For each category, compute total revenue ÷ total returns.
		○ The higher, the better performance.*/
	WITH cte1 AS (
SELECT 
    p.category,
    SUM(CAST(o.quantity AS BIGINT) * p.price) AS total_revenue,
    COUNT(r.order_id) AS total_returns
FROM orders o
JOIN products p 
ON o.product_id = p.product_id
LEFT JOIN returns r 
ON o.order_id = r.order_id
GROUP BY p.category
)

SELECT *,
total_revenue / NULLIF(total_returns,0) AS revenue_to_return_ratio
FROM cte1
ORDER BY revenue_to_return_ratio DESC;

--end
-----practice questions 

. /*Revenue trend over the last 24 months
 Business context:
Finance team wants to see how total sales evolved month by month.
 Hint:
	• Group orders by YEAR(order_date) and MONTH(order_date).
	• Calculate SUM(quantity*price) as revenue.
	• This becomes the base trend series for line charts.
 Skill focus: Date aggregation, trend analysis, Power BI line chart foundation.*/
 select year(o.order_date) as yr,eomonth(o.order_date) as month, SUM(CAST(o.quantity AS BIGINT) * p.price) AS total_revenue
 from orders o join products p on o.product_id=p.Product_id
 group by year(o.order_date),eomonth(o.order_date)
 order by yr asc
 select*from products
/*Q32. Month-over-month revenue growth (%)
 Business context:
Finance team tracks percentage change in revenue from previous month.
Hint:
	• Use LAG(SUM(revenue)) OVER(ORDER BY month) to get previous month revenue.
	• (current - previous)/previous * 100 → growth rate.
 Skill focus: Window functions, performance analysis.*/
 with cte1 as ( select year(o.order_date) as yr,eomonth(o.order_date) as month, SUM(CAST(o.quantity AS BIGINT) * p.price) AS total_revenue
 from orders o join products p on o.product_id=p.Product_id
 group by year(o.order_date),eomonth(o.order_date))
 select*,lag(total_revenue) over (order by month asc ) as prvs,((total_revenue-lag(total_revenue) over (order by month asc ))/lag(total_revenue) over (order by month asc ))*100. as rate
 from cte1
 order by yr asc


/*Q33. Rolling 3-month average revenue
 Business context:
CFO wants a smoothed revenue curve to reduce seasonality noise.
Hint:
	• Use SUM(revenue) OVER(ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)/3.
	• Compare rolling averages vs actuals.
Skill focus: Moving average, window frame control.*/
 with cte1 as ( select ,eomonth(o.order_date) as month, SUM(CAST(o.quantity AS BIGINT) * p.price) AS total_revenue
 from orders o join products p on o.product_id=p.Product_id
 group by eomonth(o.order_date))
 select*,sum(total_revenue) over(order by month  ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)/3 as comparison
 from cte1


/*Q34. Year-over-year (YoY) revenue growth
 Business context:
Finance team compares current year’s monthly revenue vs same month last year.
 Hint:
	• Compare SUM(revenue) of YEAR(order_date) and YEAR(order_date)-1.
	• Join or use LAG() partitioned by MONTH(order_date).
Skill focus: YoY analysis, same-period comparison.*/
with cte1 as(select year(o.order_date) as yr,year(o.order_date)-1 as previous_yr,  month(o.order_date)as months,
SUM(CAST(o.quantity AS BIGINT) * p.price) AS total_revenue
from orders o join Products p on o.product_id=p.product_id
group by year(o.order_Date),month(o.order_date))
select*,lag(total_revenue) over(partition by months order by previous_yr) as prvs_yr_rate
from cte1
order by yr asc


/*Q35. Weekday-wise revenue trend
 Business context:
Operations wants to check if weekends outperform weekdays.
 Hint:
	• Extract weekday name: DATENAME(WEEKDAY, order_date).
	• Aggregate revenue per day of week.
	• Sort by weekday number (DATEPART(WEEKDAY, order_date)).
 Skill focus: Weekday grouping, behavioral trend analysis.*/
 select year(o.order_date)as yr ,month(o.order_date) as mnth,DATENAME(weekday,o.order_date) as day_name,
 DATEPART(WEEKDAY,o.order_date) AS day_no,
 SUM(CAST(o.quantity AS BIGINT) * p.price) AS total_revenue
 from orders o join products p on o.product_id=p.product_id
 group by year(o.order_date),month(o.order_date),DATENAME(weekday,o.order_date),DATEPART(WEEKDAY,o.order_date)
 order by yr ,mnth asc


/*Q36. Daily order volume heatmap
 Business context:
CX wants to see which days have highest traffic (order counts).
Hint:
	• Group by YEAR(order_date) and DAY(order_date).
	• Could be used as base for Power BI heatmap.
 Skill focus: Fine-grained date aggregation, data for visualization.*/
 select year(order_date) as yr,month(order_date)as month,day(order_date) as day,count(order_id) as total_orders
 from orders
 group by year(order_date),month(order_date),day(order_date)
 order by total_orders desc

/*Q37. Revenue trend per category (multi-series)
 Business context:
Category managers want to compare trends of Fashion, Footwear, Accessories.
 Hint:
	• Group by category + MONTH(order_date).
	• Aggregate SUM(quantity*price) for each.
	• Pivot this in Power BI for multi-line view.
 Skill focus: Trend comparison across dimensions.*/
  select year(o.order_date) as yr,month(o.order_date)as month,category,
  SUM(CAST(o.quantity AS BIGINT) * p.price) AS total_revenue
 from orders o join products p on o.product_id=p.product_id
 group by year(order_date),month(order_date),category
 order by yr ,month asc;



/*Q38. Order trend for last 6 months vs previous 6 months
Business context:
Marketing wants to know if campaigns have improved order frequency.
 Hint:
	• Filter two time windows using DATEADD(month, -6, GETDATE()).
	• Compare total orders or revenue for each window.
 Skill focus: Dynamic time windowing, comparative analytics.*/
 SELECT 
CASE 
WHEN o.order_date >= DATEADD(month,-6,GETDATE()) 
THEN 'Last 6 months'

WHEN o.order_date >= DATEADD(month,-12,GETDATE()) 
AND o.order_date < DATEADD(month,-6,GETDATE())
THEN 'Previous 6 months'
END AS period,

SUM(CAST(o.quantity AS BIGINT) * p.price) AS total_revenue

FROM orders o
JOIN products p 
ON o.product_id = p.product_id

WHERE o.order_date >= DATEADD(month,-12,GETDATE())

GROUP BY 
CASE 
WHEN o.order_date >= DATEADD(month,-6,GETDATE()) 
THEN 'Last 6 months'

WHEN o.order_date >= DATEADD(month,-12,GETDATE()) 
AND o.order_date < DATEADD(month,-6,GETDATE())
THEN 'Previous 6 months'
END;

/*Q39. Identify peak revenue months historically
 Business context:
Business strategy team wants to identify high-performing months over years.
 Hint:
	• Group by MONTH(order_date) across all years.
	• Take AVG(revenue) per month → find top months.
 Skill focus: Seasonality pattern recognition.*/
 with cte1 as (
 select year(o.order_date) as yr , eomonth(o.order_date) as mnth,SUM(CAST(o.quantity AS BIGINT) * p.price) AS total_revenue
from orders o join Products p on o.product_id=p.product_id
group by year(o.order_date),eomonth(o.order_date))
select mnth,avg(total_revenue) as avg_revenue
from cte1
group by mnth
order by avg_revenue desc;
