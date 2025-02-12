USE RetailSupplyChainDB;
GO

SELECT
	year,
	quarter_q AS quarter,
	month_name,
	month,
	SUM(sales) AS total_sales,
	SUM(profit) AS total_profits
FROM retail.orders o
JOIN retail.calender c
	ON o.order_date = c.date
GROUP BY
	year,
	quarter_q,
	month_name,
	month
ORDER BY total_sales DESC;

WITH latest_order_date_cte AS (
	SELECT MAX(order_date) AS latest_order_date FROM retail.orders
)
SELECT
	day_name,
	day_of_week,
	SUM(CASE WHEN order_date BETWEEN DATEADD(DAY, -90, l.latest_order_date) AND DATEADD(DAY, -1, l.latest_order_date) THEN sales END) AS previous_90_sales,
	SUM(CASE WHEN order_date BETWEEN DATEADD(DAY, -180, l.latest_order_date) AND DATEADD(DAY, -91, l.latest_order_date) THEN sales END) AS previous_180_sales
FROM retail.orders o
JOIN retail.calender c
	ON o.order_date = c.date
CROSS JOIN latest_order_date_cte l
GROUP BY 
	day_name,
	day_of_week
ORDER BY previous_90_sales DESC;

SELECT
	day_name,
	day_of_week,
	SUM(sales) AS total_sales
FROM retail.orders o
JOIN retail.calender c
	ON o.order_date = c.date
WHERE year =  2017 AND month = 1
GROUP BY 
	day_name,
	day_of_week
ORDER BY total_sales DESC;

SELECT TOP 10
	CONVERT(VARCHAR(MAX), product_name) AS product_name,
	o.product_id,
	SUM(sales) AS total_sales INTO #top_10_products
FROM retail.orders o
JOIN retail.products p
	ON o.product_id = p.product_id
WHERE order_date BETWEEN DATEADD(DAY, -90, '2017-12-30') AND DATEADD(DAY, -1, '2017-12-30')
	AND discount = 0.00
GROUP BY 
	CONVERT(VARCHAR(MAX), product_name),
	o.product_id
ORDER BY total_sales DESC;

WITH unsold_products_cte AS (
	SELECT p.product_id
	FROM retail.products p
	LEFT JOIN retail.orders o
		ON p.product_id = o.product_id
			AND order_date BETWEEN DATEADD(DAY, -90, '2017-12-30') AND DATEADD(DAY, -1, '2017-12-30')
	WHERE o.product_id IS NULL
)
SELECT TOP 30 
	o.product_id,
	CONVERT(VARCHAR(MAX), p.product_name) AS product_name,
	COUNT(*) AS total_counts INTO #top_30_less_unsold_products
FROM retail.orders o
JOIN retail.products p
	ON o.product_id = p.product_id
WHERE o.product_id IN (
	SELECT product_id 
	FROM unsold_products_cte
	)
GROUP BY 
	o.product_id,
	CONVERT(VARCHAR(MAX), p.product_name)
ORDER BY total_counts DESC;

/*
SELECT *
FROM retail.products p
WHERE NOT EXISTS (
    SELECT 1 
    FROM retail.orders o
    WHERE o.product_id = p.product_id
    AND order_date BETWEEN DATEADD(DAY, -90, '2017-12-30') AND DATEADD(DAY, -1, '2017-12-30')  -- Only checking sales in December
);*/

WITH product_name_cte AS (
	SELECT
		order_id,
		o.product_id,
		product_name
	FROM retail.orders o
	JOIN retail.products p
		ON o.product_id = p.product_id
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
	COUNT(*) AS counts INTO #product_combination_temp
FROM product_combiantion_cte
GROUP BY CONVERT(VARCHAR(MAX), p1_name), p1_id, CONVERT(VARCHAR(MAX), p2_name), p2_id
HAVING count(*) > 1;

SELECT	
	p1_name,
	p1_id,
	p2_name,
	p2_id,
	counts
FROM #top_10_products t
LEFT JOIN #product_combination_temp p
	ON t.product_id = p.p1_id OR t.product_id = p.p2_id
WHERE p1_id IS NOT NULL;

SELECT 
	p1_name,
	p1_id,
	p2_name,
	p2_id,
	counts
FROM #top_30_less_unsold_products t
LEFT JOIN #product_combination_temp p
	ON t.product_id = p.p1_id OR t.product_id = p.p2_id
WHERE p1_id IS NOT NULL;

SELECT TOP 10
	CONVERT(VARCHAR(MAX), product_name) AS product_name,
	o.product_id,
	SUM(sales) AS total_sales
FROM retail.orders o
JOIN retail.products p
	ON o.product_id = p.product_id
JOIN retail.calender c
	ON o.order_date = c.date
WHERE year = 2017 
	AND month = 1
	AND discount = 0.00
GROUP BY 
	CONVERT(VARCHAR(MAX), product_name),
	o.product_id
ORDER BY total_sales DESC;

DROP TABLE IF EXISTS #best_seller_products;
WITH sales_summary AS (
    SELECT 
        product_id, 
        SUM(sales) AS total_revenue, 
        SUM(quantity) AS total_quantity
    FROM retail.orders
    GROUP BY product_id
), thresholds AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY total_quantity DESC) OVER() AS quantity,
        PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY total_revenue DESC) OVER() AS revenue
    FROM sales_summary
), categorized_products AS (
    SELECT 
        ss.product_id, 
        ss.total_revenue, 
        ss.total_quantity,
        CASE 
            WHEN ss.total_quantity > t.quantity --(SELECT median_quantity FROM thresholds) 
                 AND ss.total_revenue > t.revenue
                 THEN 'Best Seller Product'
            ELSE 'Normal Product'
        END AS product_category
    FROM sales_summary ss
	CROSS JOIN thresholds t
)
SELECT DISTINCT product_id INTO #best_seller_products
FROM categorized_products 
WHERE product_category = 'Best Seller Product';

with top_10_best_selling_jan as (
	SELECT TOP 10
		CONVERT(VARCHAR(MAX), product_name) AS product_name,
		o.product_id,
		discount,
		SUM(sales) AS total_sales,
		SUM(quantity) AS total_qty,
		SUM(profit) AS total_profits
	FROM retail.orders o
	JOIN retail.products p
		ON o.product_id = p.product_id
	JOIN retail.calender c
		ON o.order_date = c.date
	WHERE year = 2017 
		AND month = 1
	GROUP BY 
		CONVERT(VARCHAR(MAX), product_name),
		o.product_id,
		discount
	ORDER BY total_sales DESC
)

SELECT 
	product_name,
	t.product_id, 
	discount, 
	total_sales, 
	total_qty,
	total_profits,
	s.product_id AS best_selling_product_id,
	CASE WHEN discount = 0.0 THEN total_profits ELSE ((total_sales / (1 - discount)) - total_profits) - total_sales END AS profit_without_discounts
FROM top_10_best_selling_jan t 
LEFT join #best_seller_products s 
	ON t.product_id = s.product_id
WHERE discount <> 0.0 
	AND s.product_id IS NOT NULL;

SELECT 
	discount,
	COUNT(*) AS dis_counts,
	SUM(sales) AS total_sales,
	SUM(profit) AS total_profits,
	ROUND(SUM(profit) * 100.0 / SUM(sales), 2) AS profit_ratio
FROM retail.orders
WHERE YEAR(order_date) = 2017 
	AND MONTH(order_date) = 1
GROUP BY discount
ORDER BY total_sales DESC;

SELECT 
	SUM(CASE WHEN discount = 0.0 THEN sales END) AS total_sales_without_dis,
	SUM(CASE WHEN discount <> 0.0 THEN sales END) AS total_sals_with_dis,
	ROUND(SUM(CASE WHEN discount <> 0.0 THEN sales END) * 100.0 / SUM(sales), 2) AS sales_with_dis_percent
FROM retail.orders
WHERE YEAR(order_date) = 2017 
	AND MONTH(order_date) = 1;