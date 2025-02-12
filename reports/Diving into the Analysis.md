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
	SUM(sales) AS total_sales
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
	product_id,
	COUNT(*) AS count
FROM retail.orders
WHERE product_id IN (SELECT product_id FROM unsold_products_cte)
GROUP BY product_id
ORDER BY count DESC;
```

*Due to the length of the result, only a portion is displayed.*

<img alt="a5" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/a5.png">


