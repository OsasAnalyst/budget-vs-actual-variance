CREATE DATABASE variance;
USE variance;

CREATE TABLE orders (
    order_id VARCHAR(40) PRIMARY KEY,
    customer_id VARCHAR(40),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME NULL,
    order_delivered_carrier_date DATETIME NULL,
    order_delivered_customer_date DATETIME NULL,
    order_estimated_delivery_date DATETIME
);

CREATE TABLE order_payments (
    order_id VARCHAR(40),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE products (
	product_id VARCHAR(40) PRIMARY KEY,
    product_category_name VARCHAR(64),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

CREATE TABLE order_items (
    order_id VARCHAR(40),
    order_item_id INT,
    product_id VARCHAR(40),
    seller_id VARCHAR(40),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);


CREATE TABLE product_category_name_translation (
	product_category_name VARCHAR(64) PRIMARY KEY,
    product_category_name_english VARCHAR(64)
);


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status, @order_purchase_timestamp, @order_approved_at,
 @order_delivered_carrier_date, @order_delivered_customer_date, @order_estimated_delivery_date)
SET
  order_purchase_timestamp = STR_TO_DATE(NULLIF(@order_purchase_timestamp, ''), '%Y-%m-%d %H:%i:%s'),
  order_approved_at = STR_TO_DATE(NULLIF(@order_approved_at, ''), '%Y-%m-%d %H:%i:%s'),
  order_delivered_carrier_date = STR_TO_DATE(NULLIF(@order_delivered_carrier_date, ''), '%Y-%m-%d %H:%i:%s'),
  order_delivered_customer_date = STR_TO_DATE(NULLIF(@order_delivered_customer_date, ''), '%Y-%m-%d %H:%i:%s'),
  order_estimated_delivery_date = STR_TO_DATE(NULLIF(@order_estimated_delivery_date, ''), '%Y-%m-%d %H:%i:%s');

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, @product_category_name, @product_name_lenght, @product_description_lenght,
@product_photos_qty, @product_weight_g, @product_length_cm, @product_height_cm, @product_width_cm)
SET
	product_category_name = NULLIF(@product_category_name, ''),
    product_name_lenght = NULLIF(@product_name_lenght, ''),
    product_description_lenght = NULLIF(@product_description_lenght, ''),
    product_photos_qty = NULLIF(@product_photos_qty, ''),
    product_weight_g = NULLIF(@product_weight_g, ''),
    product_length_cm = NULLIF(@product_length_cm, ''),
    product_height_cm = NULLIF(@product_height_cm, ''),
    product_width_cm = NULLIF(@product_width_cm, '');
    

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, order_item_id, product_id, seller_id, @shipping_limit_date, price, freight_value)
SET shipping_limit_date = STR_TO_DATE(@shipping_limit_date, '%Y-%m-%d %H:%i:%s');


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/product_category_name_translation.csv'
INTO TABLE product_category_name_translation
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;



SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_payments;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM product_category_name_translation;


UPDATE product_category_name_translation 
SET product_category_name_english = TRIM(TRAILING '\r' FROM product_category_name_english);

SELECT product_category_name_english, HEX(RIGHT(product_category_name_english, 2))
FROM product_category_name_translation LIMIT 5;