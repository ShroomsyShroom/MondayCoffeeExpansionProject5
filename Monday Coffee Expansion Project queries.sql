CREATE TABLE city
	(
		city_id	INT PRIMARY KEY,
		city_name VARCHAR(15),	
		population BIGINT,
		estimated_rent FLOAT,
		city_rank INT
	);

CREATE TABLE customers
	(
		customer_id INT PRIMARY KEY,
		customer_name VARCHAR(25),
		city_id INT,
		CONSTRAINT fk_city FOREIGN KEY(city_id) REFERENCES city(city_id)
	);

CREATE TABLE products
	(
		product_id INT PRIMARY KEY,
		product_name VARCHAR(35),	
		price FLOAT
	);

CREATE TABLE sales
	(
		sale_id	INT PRIMARY KEY,
		sale_date DATE,
		product_id INT,
		customer_id	INT,
		total FLOAT,
		rating INT,
		CONSTRAINT fk_products FOREIGN KEY(product_id) REFERENCES products(product_id),
		CONSTRAINT fk_customers FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
	);


SELECT * FROM city;
SELECT * FROM customers;
SELECT * FROM sales;
SELECT * FROM products;

/*Coffee Consumers Count
How many people in each city are estimated to consume coffee, given that 25% of the population does?*/

SELECT * FROM city;
SELECT 
	city_name, 
	(population * 0.25) AS coffee_consumers, 
	city_rank
FROM city
ORDER BY 2 DESC;

/* Total Revenue from Coffee Sales
What is the total revenue generated from coffee sales across all cities in the last quarter of 2023? */

SELECT 
	SUM(total) AS total_revenue
FROM sales
WHERE 
	EXTRACT (YEAR FROM sale_date)=2023
	AND
	EXTRACT (QUARTER FROM sale_date)=4;


SELECT 
	ct.city_name,
	SUM(s.total) AS total_revenue
FROM sales AS s
INNER JOIN customers AS c
ON c.customer_id = s.customer_id
INNER JOIN city AS ct
ON ct.city_id = c.city_id
WHERE 
	EXTRACT (YEAR FROM sale_date)=2023
	AND
	EXTRACT (QUARTER FROM sale_date)=4
GROUP BY 1
ORDER BY 1 DESC	
	;

/* Sales Count for Each Product
How many units of each coffee product have been sold? */

SELECT * FROM products;
SELECT * FROM sales;

SELECT 
	p.product_name,
	COUNT(s.sale_id) AS total_orders
FROM products AS p
INNER JOIN sales AS s
ON p.product_id = s.product_id
GROUP BY 1
ORDER BY 1 DESC;

/* Average Sales Amount per City
What is the average sales amount per customer in each city? */

SELECT * FROM sales;
SELECT * FROM customers;
SELECT * FROM city;


SELECT 
	ct.city_name,
	SUM(s.total) AS total_revenue,
	COUNT(DISTINCT s.customer_id) AS total_cust,
	ROUND(
			SUM(s.total)::numeric/
				COUNT(DISTINCT s.customer_id)::numeric 
			,2) AS avg_sales_per_city_per_cust
FROM sales AS s
INNER JOIN customers AS c
ON c.customer_id = s.customer_id
INNER JOIN city AS ct
ON ct.city_id = c.city_id
GROUP BY 1;

/* City Population and Coffee Consumers (25%)
Provide a list of cities along with their populations and estimated coffee consumers. */

SELECT * FROM city;
SELECT * FROM sales;

WITH city_coffee_consumers AS
(
SELECT 
	city_name,
	population,
	(population * 0.25) AS coffee_consumers
FROM city
),
unique_cust_per_city 
AS
(
SELECT 
	ct.city_name,
	COUNT(DISTINCT c.customer_id) AS unique_cust
FROM sales AS s
INNER JOIN customers AS c
ON c.customer_id = s.customer_id
INNER JOIN city AS ct
ON ct.city_id = c.city_id
GROUP BY 1)
SELECT 
	ccc.city_name,
	ccc.coffee_consumers,
	ucpc.unique_cust
FROM city_coffee_consumers AS ccc
INNER JOIN unique_cust_per_city AS ucpc
ON ccc.city_name = ucpc.city_name

/*Top Selling Products by City
What are the top 3 selling products in each city based on sales volume?
*/

SELECT * FROM city;
SELECT * FROM sales;
SELECT * FROM products;
SELECT * FROM customers;

SELECT * FROM
(SELECT 
	ct.city_name,
	p.product_name,
	COUNT(s.sale_id) AS sales_vol,
	DENSE_RANK() OVER(PARTITION BY ct.city_name ORDER BY COUNT(s.sale_id) DESC) as Rankings
FROM sales AS s
INNER JOIN products AS p
ON s.product_id = p.product_id
INNER JOIN customers AS c
ON c.customer_id = s.customer_id
JOIN city AS ct
ON ct.city_id = c.city_id
GROUP BY 1, 2
ORDER BY 1, 3 DESC
) AS t1
WHERE Rankings >=3;


/*
Customer Segmentation by City
How many unique customers are there in each city who have purchased coffee products?
*/

SELECT * FROM city;
SELECT * FROM customers;
SELECT * FROM sales;

SELECT 
	ct.city_name,
	COUNT(DISTINCT c.customer_id) AS unique_cust
FROM city AS ct
JOIN Customers AS c
ON c.city_id = ct.city_id
JOIN sales AS s
ON s.customer_id = c.customer_id
JOIN products AS p
ON p.product_id = s.product_id
WHERE s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY 1;

/* Average Sale vs Rent
Find each city and their average sale per customer and avg rent per customer
*/

WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(SELECT 
	city_name, 
	estimated_rent
FROM city
)
SELECT 
	cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/
									ct.total_cx::numeric
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC


-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)::numeric/last_month_sale::numeric * 100
		, 2
		) as growth_ratio

FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL	


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer


WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/
									ct.total_cx::numeric
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC