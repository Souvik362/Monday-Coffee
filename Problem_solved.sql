#1 How many people in each city are estimated to consume coffee, given that 25% of the population does?

select city_name, population, round(0.25*population) as estimation
from city;

#2 What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

select c.city_name as city_names, sum(s.total) as sales
from sales s
join customers cx on s.customer_id= cx.customer_id
join city c on c.city_id=cx.city_id
where extract(year from s.sale_date)=2023 and extract(quarter from s.sale_date)=4
group by city_names;

#3 How many units of each coffee product have been sold?

select p.product_id, p.product_name, count(s.sale_id) as num
from products P
left join sales s on p.product_id = s.product_id
group by p.product_id, p.product_name
order by num desc;

#4 What is the average sales amount per customer in each city?

select cx.city_name as city_name, sum(s.total) as total_revenue, count( distinct c.customer_id) as total_cx,
round(sum(s.total)/count(distinct c.customer_id)) as average
from sales s
join customers c on s.customer_id= c.customer_id
join city cx on cx.city_id= c.city_id
group by city_name
order by average desc;

#5 City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

SELECT 
    c.city_name,
    COUNT(DISTINCT cu.customer_id) AS total_current_customers,
    ROUND((c.population * 0.25)) AS estimated_coffee_consumers
FROM city c
LEFT JOIN customers cu ON c.city_id = cu.city_id
GROUP BY c.city_name, c.population
ORDER BY total_current_customers DESC;

#6. What are the top 3 selling products in each city based on sales volume?

select * 
from
(select c.city_name, p.product_name, count(s.sale_id), dense_rank() over (partition by c.city_name order by count(s.sale_id) desc) as rnk
from sales s
join customers cx on s.customer_id=cx.customer_id
join city c on cx.city_id= c.city_id
join products p on s.product_id=p.product_id
group by c.city_name, p.product_name) as A
where rnk<=3;


#7How many unique customers are there in each city who have purchased coffee products?

select c.city_name, count(distinct cx.customer_id)
from sales s
left join customers cx on s.customer_id=cx.customer_id
join city c on c.city_id=cx.city_id
where s.product_id in (select product_id
from products
where product_name like "coffee%")
group by c.city_name;

#8 Find each city and their average sale per customer and avg rent per customer

select c.city_name, round(sum(s.total)/count(distinct cx.customer_id),2) as av,
round(c.estimated_rent/count(distinct cx.customer_id),2) as arpc
from sales s
join customers cx on s.customer_id=cx.customer_id
join city c on cx.city_id=c.city_id
group by c.city_name, c.estimated_rent
order by av desc;


# Q.9-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

with monthly_sales as 
(select c.city_name as city_name, extract(year from sale_date) as year,
 extract(month from sale_date) as month,
 sum(s.total) as total_sale
 from sales s
 join customers  cx on s.customer_id= cx.customer_id
 join city c on c.city_id=cx.city_id
 group by city_name, year, month),
 growth_ratio as(
 select city_name,month, year, total_sale as current_month_sale,
 lag(total_sale,1) over(partition by city_name order by year,month) as last_month_sale
 from monthly_sales)
 
 select city_name, month, year,current_month_sale, last_month_sale,
 (current_month_sale-last_month_sale)/ last_month_sale *100 as growth_ratio
 FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL	;

#Q.10-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
SELECT 
    c.city_name,
    ROUND(SUM(s.total), 2) AS total_sale,
    c.estimated_rent AS total_rent,
    COUNT(DISTINCT cx.customer_id) AS total_customers,
    ROUND(c.population * 0.25) AS estimated_coffee_consumers
FROM sales s
JOIN customers cx ON s.customer_id = cx.customer_id
JOIN city c ON cx.city_id = c.city_id
GROUP BY c.city_name, c.population, c.estimated_rent
ORDER BY total_sale DESC
LIMIT 3;



/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.