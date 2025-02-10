USE RetailSupplyChainDB;
GO

-- Product Segmentation and Discount Strategy for Seasonal Sales Optimization.
-- Check data indegrity.
SELECT *
FROM retail.sales
WHERE order_date IS NULL
	OR ship_date IS NULL
	OR ship_mode IS NULL
	OR customer_id IS NULL
	OR retail_sales_people IS NULL
	OR product_id IS NULL
	OR location_id IS NULL
	OR returned IS NULL
	OR sales IS NULL
	OR quantity IS NULL
	OR discount IS NULL
	OR profit IS NULL;

SELECT *
FROM retail.customers
WHERE customer_name IS NULL
	OR segment IS NULL;

SELECT *
FROM retail.geographic_locations
WHERE country IS NULL
	OR region IS NULL;

SELECT *
FROM retail.products
WHERE category IS NULL
	OR sub_category IS NULL
	OR product_name IS NULL;

-- Check duplicated values on all columns in sales table.
WITH check_duplicates_cte AS (
	SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY 
			row_id,
			order_id,
			order_date,
			ship_date,
			ship_mode,
			customer_id,
			retail_sales_people,
			product_id,
			location_id,
			returned,
			sales,
			quantity,
			discount,
			profit ORDER BY row_id) as row_num
	FROM retail.sales
)

SELECT * 
FROM check_duplicates_cte 
WHERE row_num > 1;

SELECT
	AVG(sales) AS avg_sales,
	MIN(sales) AS min_sales,
	MAX(sales) AS max_sales,
	AVG(quantity) AS avg_quantity,
	MIN(quantity) AS min_quantity,
	MAX(quantity) AS max_quantity,
	AVG(discount) AS avg_discount,
	MIN(discount) AS min_discount,
	MAX(discount) AS max_dicount,
	AVG(profit) AS avg_profit,
	MIN(profit) AS min_profit,
	MAX(profit) AS max_profit
FROM retail.sales;

SELECT DISTINCT
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sales) OVER() AS median_sales,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY discount) OVER() AS median_discount,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY profit) OVER() AS median_profit	
FROM retail.sales;

SELECT COUNT(*)
FROM retail.sales
WHERE sales < (SELECT DISTINCT PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY profit) OVER() FROM retail.sales)
	OR sales > (SELECT DISTINCT PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY profit) OVER() FROM retail.sales);

-- Data Exploration
SELECT
	MIN(order_date) AS min_order_date,
	MAX(order_date) AS max_order_date
FROM retail.sales;

SELECT
	COUNT(DISTINCT customer_id) AS unique_customers
FROM retail.customers;

SELECT
	COUNT(DISTINCT product_id) AS unique_products
FROM retail.products;

SELECT DISTINCT
	ship_mode 
FROM retail.sales;

SELECT DISTINCT	
	segment
FROM retail.customers;

SELECT DISTINCT
	category
FROM retail.products;

SELECT 
	SUM(sales) AS revenue,
	SUM(quantity) AS total_qty,
	SUM(profit) AS profit
FROM retail.sales;

SELECT
	segment,
	SUM(sales) AS total_sales
FROM retail.sales s
JOIN retail.customers c
	ON s.customer_id = c.customer_id
GROUP BY segment
ORDER BY total_sales DESC;

SELECT
	category,
	sub_category,
	SUM(sales) AS total_sales
FROM retail.sales s
JOIN retail.products p
	ON s.product_id = p.product_id
GROUP BY 
	category,
	sub_category
ORDER BY total_sales DESC;

SELECT
	state,
	SUM(sales) AS total_sales
FROM retail.sales s
JOIN retail.geographic_locations g
	ON s.location_id = g.location_id
GROUP BY state
ORDER BY total_sales DESC;

SELECT
	region,
	SUM(sales) AS total_sales
FROM retail.sales s
JOIN retail.geographic_locations g
	ON s.location_id = g.location_id
GROUP BY region
ORDER BY total_sales DESC;

SELECT
	ship_mode,
	SUM(sales) AS total_sales,
	SUM(profit) AS total_profits,
	SUM(profit) / SUM(sales) AS profit_ratio
FROM retail.sales
GROUP BY ship_mode
ORDER BY total_sales DESC;

SELECT
	quarter_q AS quarter,
	month_name,
	SUM(sales) AS total_sales
FROM retail.sales s
JOIN retail.calender c
	ON s.order_date = c.date
GROUP BY
	quarter_q,
	month_name
ORDER BY total_sales DESC;

SELECT
	day_name,
	SUM(sales) AS total_sales
FROM retail.sales s
JOIN retail.calender c
	ON s.order_date = c.date
GROUP BY day_name
ORDER BY total_sales DESC;

SELECT 
	discount,
	COUNT(*) AS count
FROM retail.sales
WHERE discount <> 0.00
GROUP BY discount
ORDER BY count DESC;

SELECT 
	discount,
	SUM(sales) AS total_sales,
	SUM(profit) AS total_profits,
	SUM(profit) / SUM(sales) AS profit_ratio
FROM retail.sales
WHERE discount <> 0.00
GROUP BY discount
ORDER BY total_sales DESC;