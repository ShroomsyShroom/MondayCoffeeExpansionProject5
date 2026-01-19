<h1>Monday Coffee Project: Sales & Market Analysis</h1>

<p>This project involves a comprehensive data analysis for <strong>Monday Coffee</strong>, a fictional coffee retail chain. Using PostgreSQL, we established a relational database to track cities, products, customers, and sales transactions. The goal is to derive actionable insights regarding consumer behavior, product performance, and city-level profitability to guide business expansion and marketing strategies.</p>

<h2>1. Database Schema & Data Infrastructure</h2> <p>The foundation of the project relies on four interconnected tables. We implemented strict primary and foreign key constraints to maintain referential integrity across the dataset.</p>

<pre> -- A. City Infrastructure CREATE TABLE city ( city_id INT PRIMARY KEY, city_name VARCHAR(15), population BIGINT, estimated_rent FLOAT, city_rank INT );

-- B. Customer Registry CREATE TABLE customers ( customer_id INT PRIMARY KEY, customer_name VARCHAR(25), city_id INT, CONSTRAINT fk_city FOREIGN KEY(city_id) REFERENCES city(city_id) );

-- C. Product Catalog CREATE TABLE products ( product_id INT PRIMARY KEY, product_name VARCHAR(35), price FLOAT );

-- D. Sales Transactions CREATE TABLE sales ( sale_id INT PRIMARY KEY, sale_date DATE, product_id INT, customer_id INT, total FLOAT, rating INT, CONSTRAINT fk_products FOREIGN KEY(product_id) REFERENCES products(product_id), CONSTRAINT fk_customers FOREIGN KEY(customer_id) REFERENCES customers(customer_id) ); </pre>

<h2>2. Order of Data Ingestion</h2> <p>To respect database constraints, data must be imported in a specific sequence. This ensures that parent records (like Cities and Products) exist before child records (like Customers and Sales) attempt to reference them:</p> <ol> <li><strong>Cities:</strong> Establishes the geographic locations.</li> <li><strong>Products:</strong> Populates the coffee menu and pricing.</li> <li><strong>Customers:</strong> Links individuals to their respective cities.</li> <li><strong>Sales:</strong> Records the final transactions linking all previous entities.</li> </ol>

<h2>3. Key Business Insights (EDA)</h2>

<h3>Q1. Coffee Consumer Potential</h3> <p>Based on market research stating that 25% of the population consumes coffee, we calculate the potential market size for each city.</p> <pre> SELECT city_name, (population * 0.25) AS coffee_consumers, city_rank FROM city ORDER BY 2 DESC; </pre>

<h3>Q2. Revenue Analysis (Q4 2023)</h3> <p>Total revenue generated across the entire network during the final quarter of 2023.</p> <pre> SELECT SUM(total) AS total_revenue FROM sales WHERE EXTRACT(YEAR FROM sale_date) = 2023 AND EXTRACT(QUARTER FROM sale_date) = 4; </pre>

<h3>Q3. Product Volume Tracking</h3> <p>Identifying which products are the "best-sellers" based on order frequency.</p> <pre> SELECT p.product_name, COUNT(s.sale_id) AS total_orders FROM products AS p JOIN sales AS s ON p.product_id = s.product_id GROUP BY 1 ORDER BY 2 DESC; </pre>

<h3>Q4. Sales Growth Monitoring</h3> <p>Using <code>LAG()</code> window functions to calculate the month-over-month growth ratio for each city. This helps identify seasonal trends or declining markets.</p> <pre> WITH monthly_sales AS ( SELECT ci.city_name, EXTRACT(MONTH FROM sale_date) as month, EXTRACT(YEAR FROM sale_date) as year, SUM(s.total) as total_sale FROM sales s JOIN customers c ON c.customer_id = s.customer_id JOIN city ci ON ci.city_id = c.city_id GROUP BY 1, 2, 3 ), growth_ratio AS ( SELECT city_name, month, year, total_sale as cr_month_sale, LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale FROM monthly_sales ) SELECT *, ROUND((cr_month_sale - last_month_sale)::numeric / last_month_sale::numeric * 100, 2) as growth_pct FROM growth_ratio WHERE last_month_sale IS NOT NULL; </pre>

<h2>4. Market Potential Analysis</h2> <p>We consolidated sales data with demographic and cost data (rent) to determine which cities offer the best ROI for future investment.</p>

<pre> -- Identifying top cities by revenue and coffee consumer density SELECT cr.city_name, total_revenue, cr.estimated_rent AS total_rent, ct.total_cx AS unique_customers, estimated_coffee_consumer_in_millions FROM city_rent AS cr JOIN city_table AS ct ON cr.city_name = ct.city_name ORDER BY 2 DESC; </pre>

<h2>5. Final Recommendations</h2> <p>Based on the Exploratory Data Analysis, we recommend focusing expansion and marketing efforts on the following three cities:</p>

<ul> <li><strong>Pune:</strong> Emerges as the most profitable location with the <strong>highest total revenue</strong> and a very low average rent per customer, indicating high margins.</li> <li><strong>Delhi:</strong> Represents the largest growth opportunity with <strong>7.7 million potential consumers</strong>. Despite higher costs, the sheer volume of unique customers (68) makes it a critical hub.</li> <li><strong>Jaipur:</strong> Offers the best operational efficiency with the <strong>highest customer count (69)</strong> and the lowest rent-to-customer ratio (156), making it a low-risk, high-engagement market.</li> </ul>
