# Setting Up SQL Database

First of all, We create a schema for better manage for tables and improve the structure of the database.

```SQL
CREATE SCHEMA retail;
GO
```

## Build Tables 𝄜

### Creating the `customers` Table

This table stores information about customers, including their unique identifiers, names, and market segments.

```SQL
CREATE TABLE retail.customers (
	customer_id VARCHAR(8) PRIMARY KEY,
	customer_name VARCHAR(30),
	segment VARCHAR(15)
);
```

## Creating the `products` Table

This table holds product details, including category, sub-category and their names.

```SQL
CREATE TABLE retail.products (
	product_id VARCHAR(15) PRIMARY KEY,
	category VARCHAR(15),
	sub_category VARCHAR(15),
	product_name TEXT
);
```

## Creating the `geographic_locations` Table

This table stores location-based data, enabling regional sales analysis and customer distribution insights.

```SQL
CREATE TABLE retail.geographic_locations (
	location_id VARCHAR(30) PRIMARY KEY,
	country VARCHAR(15),
	state VARCHAR(20),
	state_code VARCHAR(2),
	city VARCHAR(20),
	postal_code VARCHAR(5),
	region VARCHAR(10)
);
```

## Creating the `calender` Table

This table stores date-related information to support sales analysis and trend identification.

```SQL
CREATE TABLE retail.calender (
	date DATE PRIMARY KEY,
	year SMALLINT NOT NULL,
	quarter TINYINT NOT NULL CHECK(quarter BETWEEN 1 AND 4),
	quarter_q CHAR(2),
	quarter_year CHAR(9),
	month TINYINT NOT NULL CHECK(month BETWEEN 1 AND 12),
	month_name CHAR(3),
	month_year CHAR(8),
	week_of_year TINYINT NOT NULL CHECK(week_of_year BETWEEN 1 AND 53),
	week_of_year_w CHAR(7),
	day_of_week TINYINT NOT NULL CHECK(day_of_week BETWEEN 1 AND 7),
	day_name CHAR(9)
);
```

## Creating the `orders` Table

This table stores order details, tracking customer purchases, logistics and sales performance. It is essential for sales analysis and revenue tracking.

```SQL
CREATE TABLE retail.orders (
	row_id INT NOT NULL,
	order_id CHAR(14) NOT NULL,
	order_date DATE,
	ship_date DATE,
	ship_mode VARCHAR(20),
	customer_id VARCHAR(8),
	retail_sales_people VARCHAR(30),
	product_id VARCHAR(15),
	location_id VARCHAR(30),
	returned VARCHAR(3),
	sales DECIMAL(10, 2),
	quantity INT,
	discount DECIMAL(3, 2),
	profit DECIMAL(10, 2),
	FOREIGN KEY (customer_id) REFERENCES retail.customers(customer_id),
	FOREIGN KEY (product_id) REFERENCES retail.products(product_id),
	FOREIGN KEY (location_id) REFERENCES retail.geographic_locations(location_id),
	FOREIGN KEY (order_date) REFERENCES retail.calender(date)
);
```

## Creating a Stored Procedure

We are also creating a stored procedure to automate repeated tasks for importing CSV files.

```SQL
CREATE PROCEDURE retail.InsertData
	@TableName VARCHAR(255),
	@FileName VARCHAR(255)
AS
BEGIN
	DECLARE @SQL NVARCHAR(1000)
	SET @SQL = '
		BULK INSERT retail.' +  QUOTENAME(@TableName) + '
		FROM ''' + 'N:\SQL\Retail Supply Chain\datasets\' + @FileName + '.csv' + '''
		WITH (
			FORMAT = ''CSV'',
			FIRSTROW = 2,
			FIELDTERMINATOR = '','',
			ROWTERMINATOR = ''\n'',
			TABLOCK
		);';
	EXEC sp_executesql @SQL
END;
```

Now, we are importing all CSV files into the existing tables.

```SQL
EXEC retail.InsertData 'customers', 'customers';
EXEC retail.InsertData 'products', 'products';
EXEC retail.InsertData 'geographic_locations', 'geographic_locations';
EXEC retail.InsertData 'calender', 'calender';
EXEC retail.InsertData 'orders', 'orders';
```

<img alt="s1" src="https://raw.githubusercontent.com/nyanlinhtike-yc/Retail-Supply-Chain/refs/heads/main/images/s1.png">

[Here] we go to the next step.

[Here]: https://github.com/nyanlinhtike-yc/Retail-Supply-Chain/blob/main/reports/Checking%20Data%20Integrity.md
