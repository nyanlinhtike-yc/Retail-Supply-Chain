# Diving into the Analysis

We are now conducting an in-depth analysis to determine which products and product combinations should be prioritized for the upcoming seasons. Additionally, we are analyzing the optimal discount percentage needed to maximize sales and revenue especially on Q1 January.

## Sales Trend

First, we are analyzing the overall sales trend in Retail Sales to understand our current situation.

```SQL
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
```

*In this section, we present visual graphics\* instead of table results, as they provide clearer insights.*

> *Note: All visual grpahics are generated using **Power BI**.*

<img alt="a1" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/a1.png">

The sales trend appears to be upward, indicating a healthy growth pattern. However, there is a slight decline in Q2, which is noteworthy. However, a deeper analysis of this trend is beyond our primary objective.

Now, we focus on the day-of-week patterns for the current trend based on the past 90 and 180 days to support our upcoming discount event strategy.

```SQL
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
```

<img alt="a2" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/a2.png">

Friday and Sunday are the best days to start a discount event. Monday has its own steady sales, while Thursday acts as a booster for the weekend.

Since most retail businesses follow seasonal patterns, we are also analyzing day-of-week trends for January of the previous year.

```SQL
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
```

<img alt="a3" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/a3.png">

The trend appears similar to the previous analysis, except for Friday.

---

## Product Segmantation

To maximize sales during the discount event, we aim to combine two factors: currently trending products and less frequently sold products. By strategically pairing high-demand items with underperforming ones, we can optimize inventory movement and drive overall sales. 

Therefore, we are analyzing the top 10 trending products based on sales from the past 90 days.

```SQL
SELECT TOP 10
	CONVERT(VARCHAR(MAX), product_name) AS product_name,
	o.product_id,
	SUM(sales) AS total_sales --INTO #top_10_products -- For future use
FROM retail.orders o
JOIN retail.products p
	ON o.product_id = p.product_id
WHERE order_date BETWEEN DATEADD(DAY, -90, '2017-12-30') AND DATEADD(DAY, -1, '2017-12-30')
	AND discount = 0.00
GROUP BY 
	CONVERT(VARCHAR(MAX), product_name),
	o.product_id
ORDER BY total_sales DESC;
```

*We are only considering truly trending products without discounts.*

<img alt="a4" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/a4.png">

Next, we are analyzing the 30 least frequently sold products based on order volume over the past 90 days. While there are many products with low sales, we are intentionally selecting relatively more frequently sold items for this event. This decision is based on overall sales trends since January sales are lower compared to other months, **combining slow-selling items with a slow sales month could result in an unappearling discount event**.

```SQL
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
	COUNT(*) AS total_counts --INTO #top_30_less_unsold_products -- for future use.
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
```

*Due to the length of the result, only a portion is displayed.*

<img alt="a5" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/a5.png">

We are analyzing product combinations to understand purchasing patterns, such as which items are frequently bought together.

First, we need to create `product_combination_temp` temporary table to future calculations.

```SQL
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
```

Products from the top 10 bestsellers that were purchased together with other items.

```SQL
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
```

<img alt="a6" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/a6.png">

Products from the top 30 less frequently sold items that were purchased together with other items.

```SQL
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
```

<img alt="a7" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/a7.png">

We need to consider that some high-selling products are seasonal, such as summer and winter items. However, since there are no explicit seasonal categories assigned to each product, we are analyzing the best-selling products based on January sales. Our goal is to align trending products, seasonal products, and least frequently sold products for a balanced discount strategy.

*While a full seasonal analysis requires multi-year data and deeper segmentation, this project demonstrates a simplified approach that can be expanded further.*

```SQL
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
```

<img alt="a8" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/a8.png">

---

## Discount Optimization

First, We are going to create temporary table for best selling products.

> *"In this case, we defined the best-selling products based on the top 20th percentile of total sales and total quantity that are filtering out low-revenue, high-quantity items and high-revenue, low-quantity items. However, in a real-world scenario, the definition of best-selling products can vary depending on business objectives and priorities."*

```SQL
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
```

We are comparing the top 10 products for the January with best selling products of all times.

```SQL
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
	s.product_id AS best_selling_product_id
FROM top_10_best_selling_jan t 
LEFT join #best_seller_products s 
	ON t.product_id = s.product_id;
```

*This is a intermediate step to get better understand on the how our logic works.*

<img alt="a9" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/a9.png">

We are now optimizing discounts on high-demand products by reducing them to offer discounts strategically and maximize revenue.

> *"This is a simplified approach that can be further expanded using a real-world dataset."*

```SQL
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
```

We also want to know total sales and profit ratio based on each discount.

```SQL
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
```

<img alt="a10" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/a10.png">

Discounted sales contribute to 41% of the total revenue.

```SQL
SELECT 
	SUM(CASE WHEN discount = 0.0 THEN sales END) AS total_sales_without_dis,
	SUM(CASE WHEN discount <> 0.0 THEN sales END) AS total_sals_with_dis,
	ROUND(SUM(CASE WHEN discount <> 0.0 THEN sales END) * 100.0 / SUM(sales), 2) AS sales_with_dis_percent
FROM retail.orders
WHERE YEAR(order_date) = 2017 
	AND MONTH(order_date) = 1;
```

<img alt="a11" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/a11.png">


If you are looking for key insights and recommendations from this analysis, here are the main takeaways:

* [Key Insights]
* [Recommendations]

[Key Insights]: https://github.com/nyanlinhtike-yc/Retail-Supply-Chain/tree/main?tab=readme-ov-file#key-insights-
[Recommendations]: https://github.com/nyanlinhtike-yc/Retail-Supply-Chain/tree/main?tab=readme-ov-file#recomemdations-