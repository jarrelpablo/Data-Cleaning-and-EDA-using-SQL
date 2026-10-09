-- Describing each table
DESCRIBE customer_dim;
DESCRIBE fact_table;
DESCRIBE item_dim;
DESCRIBE store_dim;
DESCRIBE time_dim;
DESCRIBE trans_dim;

-- Counting everything from each table
SELECT COUNT(*)
FROM customer_dim;
-- 9191 total rows

SELECT COUNT(*)
FROM fact_table;
-- 1000000 total rows

SELECT COUNT(*)
FROM item_dim;
-- 264 total rows

SELECT COUNT(*)
FROM store_dim;
-- 726 total rows

SELECT COUNT(*)
FROM time_dim;
-- 99999 total rows

SELECT COUNT(*)
FROM trans_dim;
-- 39 total rows

-- Checking for null values
SELECT *
FROM customer_dim
WHERE coustomer_key IS NULL
	OR name IS NULL
    OR contact_no IS NULL
    OR nid IS NULL
	OR TRIM(coustomer_key)=''
    OR TRIM(name)='';
    -- 27 whitespace or NULL names

SELECT *
FROM fact_table
WHERE payment_key IS NULL
	OR coustomer_key IS NULL
    OR time_key IS NULL
    OR store_key IS NULL
    OR quantity IS NULL
    OR unit IS NULL
    OR TRIM(unit) = ''
    OR unit_price IS NULL
    OR total_price IS NULL;
    -- one unit with the item_key I00158 is null

SELECT *
FROM store_dim
WHERE store_key IS NULL
	OR division IS NULL
    OR district IS NULL
    OR upazila IS NULL
    OR TRIM(division)=''
    OR TRIM(district)=''
    OR TRIM(upazila)='';
    -- no null values from store_dim

SELECT *
FROM item_dim
WHERE item_key IS NULL
	OR item_name IS NULL
    OR `desc` IS NULL
    OR unit_price IS NULL
    OR man_country IS NULL
    OR supplier IS NULL
    OR unit IS NULL
    OR TRIM(item_name)=''
	OR TRIM(`desc`)=''
    OR TRIM(man_country)=''
    OR TRIM(supplier)=''
    OR TRIM(unit)='';
	-- one unit with the item_key I00158 is null

SELECT * 
FROM trans_dim
WHERE payment_key IS NULL
	OR trans_type IS NULL
    OR bank_name IS NULL
    OR TRIM(payment_key)=''
    OR TRIM(bank_name)=''
    OR TRIM(trans_type)='';
    -- no nulls from trans_dim table

SELECT *
FROM time_dim
WHERE time_key IS NULL
	OR date IS NULL
    OR hour IS NULL
    OR day IS NULL
    OR week IS NULL
    OR month IS NULL
    OR quarter IS NULL
    OR year IS NULL;
    
SELECT *
FROM item_dim
WHERE unit_price < 0;
	-- no negative unit price for item_dim

SELECT *
FROM fact_table
WHERE unit_price <= 0 OR total_price <= 0 OR quantity <= 0;
-- no negative values for the price

SELECT * 
FROM fact_table
WHERE (unit_price * quantity) - total_price <> 0;
	-- no pricing irregularites
    
SELECT DISTINCT `hour`
FROM time_dim
ORDER BY `hour` ASC;

SELECT DISTINCT `day`
FROM time_dim
ORDER BY `day` ASC;

SELECT DISTINCT `week`
FROM time_dim
ORDER BY `week` ASC;

SELECT DISTINCT `month`
FROM time_dim
ORDER BY `month` ASC;

SELECT DISTINCT `quarter`
FROM time_dim
ORDER BY `quarter` ASC;

SELECT DISTINCT `year`
FROM time_dim
ORDER BY `year` ASC;
-- no irregularites in time_dim table
    
    -- Checking if every foriegn key in fact table exist in dimension tables
SELECT f.coustomer_key
FROM fact_table f
LEFT JOIN customer_dim c
    ON f.coustomer_key = c.coustomer_key
WHERE c.coustomer_key IS NULL;

SELECT f.item_key
FROM fact_table f
LEFT JOIN item_dim i
    ON f.item_key = i.item_key
WHERE i.item_key IS NULL;

SELECT f.store_key
FROM fact_table f
LEFT JOIN store_dim s
    ON f.store_key = s.store_key
WHERE s.store_key IS NULL;

SELECT f.time_key
FROM fact_table f
LEFT JOIN time_dim t
    ON f.time_key = t.time_key
WHERE t.time_key IS NULL;

SELECT f.payment_key
FROM fact_table f
LEFT JOIN trans_dim t
    ON f.payment_key = t.payment_key
WHERE t.payment_key IS NULL;
	-- All foreign key in fact table exist in their respective dimension table
    


    