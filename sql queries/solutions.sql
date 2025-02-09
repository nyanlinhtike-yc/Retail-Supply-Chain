USE RetailSupplyChainDB;
GO

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
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sales) OVER() AS median_sales,
	MIN(sales) AS min_sales,
	MAX(sales) AS max_sales,
	AVG(discount) AS avg_discount,
	MIN(discount) AS min_discount,
	MAX(discount) AS max_dicount,
	AVG(profit) AS avg_profit,
	MIN(profit) AS min_profit,
	MAX(profit) AS max_profit
FROM retail.sales;

SELECT *
FROM retail.sales
WHERE sales < (SELECT DISTINCT PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY sales) OVER() FROM retail.sales)
	OR sales > (SELECT DISTINCT PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY sales) OVER() FROM retail.sales);

SELECT order_id, LOG(1 + profit) AS log_profit
FROM retail.sales;


select top 5 * from retail.sales;
select top 5 * from retail.calender;
select  * from retail.customers;
select * from retail.geographic_locations;
select top 5 * from retail.products;

select * from retail.geographic_locations where state = 'Washington' or state = 'District of Columbia'