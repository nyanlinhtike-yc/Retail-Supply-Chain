USE RetailSupplyChainDB;
GO

DROP TABLE IF EXISTS retail.sales;
DROP TABLE IF EXISTS retail.customers;
DROP TABLE IF EXISTS retail.products;
DROP TABLE IF EXISTS retail.geographic_locations;
DROP TABLE IF EXISTS retail.calender;
DROP PROCEDURE IF EXISTS retail.InsertData;
DROP SCHEMA IF EXISTS retail;
GO

CREATE SCHEMA retail;
GO


CREATE TABLE retail.customers (
	customer_id VARCHAR(8) PRIMARY KEY,
	customer_name VARCHAR(30),
	segment VARCHAR(15)
);

CREATE TABLE retail.products (
	product_id VARCHAR(15) PRIMARY KEY,
	category VARCHAR(15),
	sub_category VARCHAR(15),
	product_name TEXT
);

CREATE TABLE retail.geographic_locations (
	location_id VARCHAR(30) PRIMARY KEY,
	country VARCHAR(15),
	state VARCHAR(20),
	state_code VARCHAR(2),
	city VARCHAR(20),
	postal_code VARCHAR(5),
	region VARCHAR(10)
);

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

CREATE TABLE retail.sales (
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
GO

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
GO

EXEC retail.InsertData 'customers', 'customers';
EXEC retail.InsertData 'products', 'products';
EXEC retail.InsertData 'geographic_locations', 'geographic_locations';
EXEC retail.InsertData 'calender', 'calender';
EXEC retail.InsertData 'sales', 'sales';