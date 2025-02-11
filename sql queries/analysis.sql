USE RetailSupplyChainDB;
GO

-- Analysis 
-- FIRST OF ALL, WE NEED TO SEE THE OVERALL SALES TREND FOR OUR COMPANY.
SELECT
	year,
	quarter_q AS quarter,
	month_name,
	month,
	SUM(sales) AS total_sales,
	SUM(profit) AS total_profits
FROM retail.sales s
JOIN retail.calender c
	ON s.order_date = c.date
GROUP BY
	year,
	quarter_q,
	month_name,
	month
ORDER BY total_sales DESC;

WITH latest_order_date_cte AS (
	SELECT MAX(order_date) AS latest_order_date FROM retail.sales
)
SELECT
	day_name,
	day_of_week,
	SUM(CASE WHEN order_date BETWEEN DATEADD(DAY, -90, l.latest_order_date) AND DATEADD(DAY, -1, l.latest_order_date) THEN sales END) AS previous_90_sales,
	SUM(CASE WHEN order_date BETWEEN DATEADD(DAY, -180, l.latest_order_date) AND DATEADD(DAY, -91, l.latest_order_date) THEN sales END) AS previous_180_sales
FROM retail.sales s
JOIN retail.calender c
	ON s.order_date = c.date
CROSS JOIN latest_order_date_cte l
GROUP BY 
	day_name,
	day_of_week
ORDER BY previous_90_sales DESC;

SELECT
	day_name,
	SUM(sales) AS total_sales
FROM retail.sales s
JOIN retail.calender c
	ON s.order_date = c.date
WHERE year =  2017 AND month = 1
GROUP BY day_name
ORDER BY total_sales DESC;

SELECT TOP 10
	CONVERT(VARCHAR(MAX), product_name) AS product_name,
	s.product_id,
	SUM(sales) AS total_sales
FROM retail.sales s
JOIN retail.products p
	ON s.product_id = p.product_id
WHERE order_date BETWEEN DATEADD(DAY, -90, '2017-12-30') AND DATEADD(DAY, -1, '2017-12-30')
	AND discount = 0.00
GROUP BY 
	CONVERT(VARCHAR(MAX), product_name),
	s.product_id
ORDER BY total_sales DESC;

WITH unsold_products_cte AS (
	SELECT p.product_id
	FROM retail.products p
	LEFT JOIN retail.sales s
		ON p.product_id = s.product_id
	AND order_date BETWEEN DATEADD(DAY, -90, '2017-12-30') AND DATEADD(DAY, -1, '2017-12-30')
WHERE s.product_id IS NULL
)
SELECT TOP 30 
	product_id,
	COUNT(*) AS count
FROM retail.sales s
WHERE product_id IN (SELECT product_id FROM unsold_products_cte)
GROUP BY s.product_id
ORDER BY count DESC;

SELECT *
FROM retail.products p
WHERE NOT EXISTS (
    SELECT 1 
    FROM retail.sales s
    WHERE s.product_id = p.product_id
    AND order_date BETWEEN DATEADD(DAY, -90, '2017-12-30') AND DATEADD(DAY, -1, '2017-12-30')  -- Only checking sales in December
);

WITH product_name_cte AS (
	SELECT
		order_id,
		s.product_id,
		product_name
	FROM retail.sales s
	JOIN retail.products p
		ON s.product_id = p.product_id
),
product_combiantion_cte AS (
	SELECT 
		c1.order_id,
		c1.product_id AS p1_id,
		c1.product_name AS p1_name,
		c2.product_id AS p2_id,
		c2.product_name AS p2_name
	FROM product_name_cte c1
	JOIN product_name_cte c2 
		ON c1.order_id = c2.order_id
			AND c1.product_id < c2.product_id
	WHERE c1.product_id <> c2.product_id
)

SELECT	 
	CONVERT(VARCHAR(MAX), p1_name) AS p1_name,
	p1_id,
	CONVERT(VARCHAR(MAX), p2_name) AS p2_name,
	p2_id,
	COUNT(*) AS count INTO #product_combination_temp
FROM product_combiantion_cte
GROUP BY CONVERT(VARCHAR(MAX), p1_name), p1_id, CONVERT(VARCHAR(MAX), p2_name), p2_id
HAVING count(*) > 1;

WITH test_cte AS (
	SELECT TOP 10
		CONVERT(VARCHAR(MAX), product_name) AS product_name,
		s.product_id,
		SUM(sales) AS total_sales
	FROM retail.sales s
	JOIN retail.products p
		ON s.product_id = p.product_id
	--WHERE order_date BETWEEN DATEADD(DAY, -90, '2017-12-30') AND DATEADD(DAY, -1, '2017-12-30')
		--AND discount = 0.00
	GROUP BY 
		CONVERT(VARCHAR(MAX), product_name),
		s.product_id
)
SELECT *
FROM test_cte t
LEFT JOIN #product_combination_temp p
	ON t.product_id = p.p1_id OR t.product_id = p.p2_id


WITH unsold_products_cte AS (
	SELECT p.product_id
	FROM retail.products p
	LEFT JOIN retail.sales s
		ON p.product_id = s.product_id
	AND order_date BETWEEN DATEADD(DAY, -90, '2017-12-30') AND DATEADD(DAY, -1, '2017-12-30')
WHERE s.product_id IS NULL
),
top_30_unsold_products_cte AS (
	SELECT TOP 30 
		product_id,
		COUNT(*) AS count
	FROM retail.sales s
	WHERE product_id IN (SELECT product_id FROM unsold_products_cte)
	GROUP BY s.product_id
)
SELECT *
FROM top_30_unsold_products_cte t
LEFT JOIN #product_combination_temp p
	ON t.product_id = p.p1_id OR t.product_id = p.p2_id


-- needs work for production combination with top 30 or top 10

-- optins
SELECT 
	state,
	SUM(sales) AS total_sales
FROM retail.sales s
JOIN retail.geographic_locations g
	ON s.location_id = g.location_id
GROUP BY state
ORDER BY total_sales;

--history main focus on jan
SELECT TOP 10
	CONVERT(VARCHAR(MAX), product_name) AS product_name,
	s.product_id,
	SUM(sales) AS total_sales
FROM retail.sales s
JOIN retail.products p
	ON s.product_id = p.product_id
JOIN retail.calender c
	ON s.order_date = c.date
WHERE year = 2017 
	AND month = 1
	AND discount = 0.00
GROUP BY 
	CONVERT(VARCHAR(MAX), product_name),
	s.product_id
ORDER BY total_sales DESC; 

SELECT 
	SUM(CASE WHEN discount = 0.0 THEN sales END) AS total_sales_without_dis,
	SUM(CASE WHEN discount <> 0.0 THEN sales END) AS total_sals_with_dis
FROM retail.sales
WHERE YEAR(order_date) = 2017 
	AND MONTH(order_date) = 1;

SELECT 
	discount,
	COUNT(*) AS count,
	SUM(sales) AS total_sales,
	SUM(profit) AS total_profits,
	SUM(profit) / SUM(sales) AS profit_ratio
FROM retail.sales
WHERE discount <> 0.00
	AND YEAR(order_date) = 2017 
	AND MONTH(order_date) = 1
GROUP BY discount
ORDER BY total_sales DESC;

SELECT
	returned,
	SUM(sales) AS total_sales,
	ROUND(SUM(sales) * 100.0 / SUM(SUM(sales)) OVER(), 2) AS percent_sales
FROM retail.sales
GROUP BY returned;
