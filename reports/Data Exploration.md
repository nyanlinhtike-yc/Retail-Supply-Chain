# Data Exploration

We are exploring the data before analyzing it. This is a good practice for data analysts.  

> *"Since this dataset was not explicitly provided by a data engineer or supervisor for a specific analysis, our first step is to check the time range of the data to make sure it matches what we need for our analysis."*

```SQL
SELECT
	MIN(order_date) AS min_order_date,
	MAX(order_date) AS max_order_date
FROM retail.orders;
```

<img alt="d1" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/d1.png">

#### How many unique customers are there in the `customers` table?

```SQL
SELECT
	COUNT(DISTINCT customer_id) AS unique_customers
FROM retail.customers;
```

<img alt="d2" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/d2.png">

How many unique products are there in the `products` table?

```SQL
SELECT
	COUNT(DISTINCT product_id) AS unique_products
FROM retail.products;
```

<img alt="d3" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/d3.png">

What shipping methods are used for nationwide product distribution?

```SQL
SELECT DISTINCT
	ship_mode 
FROM retail.orders;
```

<img alt="d4" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/d4.png">

What are the company's customer segments?

```SQL
SELECT DISTINCT	
	segment
FROM retail.customers;
```

<img alt="d5" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/d5.png">

What product categories do they offer?

```SQL
SELECT DISTINCT
	category
FROM retail.products;
```

<img alt="d6" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/d6.png">

How many product units were sold, and how much revenue was generated? How much profit was earned?

```SQL
SELECT 
	SUM(sales) AS revenue,
	SUM(quantity) AS total_qty,
	SUM(profit) AS profit
FROM retail.orders;
```

<img alt="d7" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/d7.png">

How many sales were generated for each customer segment?

```SQL
SELECT
	segment,
	SUM(sales) AS total_sales
FROM retail.orders o
JOIN retail.customers c
	ON o.customer_id = c.customer_id
GROUP BY segment
ORDER BY total_sales DESC;
```

<img alt="d8" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/d8.png">

What is the total sales volumn for each product category and sub-category?

```SQL
SELECT
	category,
	sub_category,
	SUM(sales) AS total_sales
FROM retail.orders o
JOIN retail.products p
	ON o.product_id = p.product_id
GROUP BY 
	category,
	sub_category
ORDER BY total_sales DESC;
```

<img alt="d9" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/d9.png">

How much sales were generated for each state?

```SQL
SELECT
	state,
	SUM(sales) AS total_sales
FROM retail.orders o
JOIN retail.geographic_locations g
	ON o.location_id = g.location_id
GROUP BY state
ORDER BY total_sales DESC;
```

<img alt="d10" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/d10.png">

What are the total sales, total profits and their profit ratio for each shipping methods? 

> *"We are only exploring shipping methods at a high level and will not conduct further analysis on this subject, as it deviates from our main objective."*

```SQL
SELECT
	ship_mode,
	SUM(sales) AS total_sales,
	SUM(profit) AS total_profits,
	SUM(profit) / SUM(sales) AS profit_ratio
FROM retail.orders
GROUP BY ship_mode
ORDER BY total_sales DESC;
```

<img alt="d11" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/d11.png">

#### What is the discount distribution for all products?

```SQL
SELECT 
	discount,
	COUNT(*) AS count
FROM retail.orders
WHERE discount <> 0.00
GROUP BY discount
ORDER BY count DESC;
```

<img alt="d12" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/d12.png">

> *"We are conducting a high-level exploration of discount values. Further analysis on this topic will be performed in the deep analysis phase."*

```SQL
SELECT 
	discount,
	SUM(sales) AS total_sales,
	SUM(profit) AS total_profits,
	SUM(profit) / SUM(sales) AS profit_ratio
FROM retail.orders
WHERE discount <> 0.00
GROUP BY discount
ORDER BY total_sales DESC;
```

[Here] we go to the next step.

[Here]: https://github.com/nyanlinhtike-yc/Retail-Supply-Chain/blob/main/reports/Diving%20into%20the%20Analysis.md