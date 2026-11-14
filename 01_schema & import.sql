CREATE DATABASE IF NOT EXISTS olist_ecommerce;
USE olist_ecommerce;

-- 1. Customers Table
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(5)
);

-- 2. Orders Table
CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME NULL,
    order_delivered_carrier_date DATETIME NULL,
    order_delivered_customer_date DATETIME NULL,
    order_estimated_delivery_date DATETIME NULL,
    INDEX idx_customer_id (customer_id),
    INDEX idx_order_status (order_status)
);

-- 3. Order Payments Table
CREATE TABLE order_payments (
    order_id VARCHAR(50) NOT NULL,
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(10, 2),
    PRIMARY KEY (order_id, payment_sequential)
);

-- 4. Products Table
CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT NULL,
    product_description_lenght INT NULL,
    product_photos_qty INT NULL,
    product_weight_g INT NULL,
    product_length_cm INT NULL,
    product_height_cm INT NULL,
    product_width_cm INT NULL
);

-- 5. Order Items Table
CREATE TABLE order_items (
    order_id VARCHAR(50) NOT NULL,
    order_item_id INT NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10, 2),
    freight_value DECIMAL(10, 2),
    PRIMARY KEY (order_id, order_item_id),
    INDEX idx_product_id (product_id)
);

SET GLOBAL local_infile = 1;

USE olist_ecommerce;

SHOW VARIABLES LIKE 'secure_file_priv';


USE olist_ecommerce;

-- 1. Load Customers
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state);

-- 2. Load Orders
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status, @purchase_ts, @approved_at, @carrier_dt, @customer_dt, @estimated_dt)
SET
    order_purchase_timestamp = NULLIF(@purchase_ts, ''),
    order_approved_at = NULLIF(@approved_at, ''),
    order_delivered_carrier_date = NULLIF(@carrier_dt, ''),
    order_delivered_customer_date = NULLIF(@customer_dt, ''),
    order_estimated_delivery_date = NULLIF(@estimated_dt, '');

-- 3. Load Order Payments
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, payment_sequential, payment_type, payment_installments, payment_value);

-- 4. Load Products
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, @cat_name, @name_len, @desc_len, @photos_qty, @weight_g, @length_cm, @height_cm, @width_cm)
SET
    product_category_name = NULLIF(@cat_name, ''),
    product_name_lenght = NULLIF(@name_len, ''),
    product_description_lenght = NULLIF(@desc_len, ''),
    product_photos_qty = NULLIF(@photos_qty, ''),
    product_weight_g = NULLIF(@weight_g, ''),
    product_length_cm = NULLIF(@length_cm, ''),
    product_height_cm = NULLIF(@height_cm, ''),
    product_width_cm = NULLIF(@width_cm, '');

-- 5. Load Order Items
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value);


