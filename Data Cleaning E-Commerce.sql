-- Data Cleaning E-Commerce
-- Create 2nd schema for data cleaning
CREATE SCHEMA data_cleaning;

CREATE TABLE data_cleaning.customer_dim_clean AS
SELECT * FROM customer_dim;

CREATE TABLE data_cleaning.fact_table_clean AS
SELECT * FROM fact_table;

CREATE TABLE data_cleaning.item_dim_clean AS
SELECT * FROM item_dim;

CREATE TABLE data_cleaning.store_dim_clean AS
SELECT * FROM store_dim;

CREATE TABLE data_cleaning.time_dim_clean AS
SELECT * FROM time_dim;

CREATE TABLE data_cleaning.trans_dim_clean AS
SELECT * FROM trans_dim;

ALTER TABLE fact_table_clean RENAME COLUMN coustomer_key TO customer_key;
ALTER TABLE customer_dim_clean RENAME COLUMN coustomer_key TO customer_key;
-- rename columns


USE data_cleaning;

-- 1. remove duplicates
	-- check duplicates in primary key
SELECT customer_key, COUNT(*) as Count
FROM customer_dim_clean
GROUP BY customer_key
HAVING COUNT(*) > 1;

SELECT item_key, COUNT(*) as Count
FROM item_dim_clean
GROUP BY item_key
HAVING COUNT(*) > 1;

SELECT payment_key, COUNT(*) as Count
FROM trans_dim_clean
GROUP BY payment_key
HAVING COUNT(*) > 1;

SELECT store_key, COUNT(*) as Count
FROM store_dim_clean
GROUP BY store_key
HAVING COUNT(*) > 1;

SELECT time_key, COUNT(*) as Count
FROM time_dim_clean
GROUP BY time_key
HAVING COUNT(*) > 1;
	-- no duplicates in primary key

-- 2. Handling null values
-- There are 27 whitespace name from the customer table, those are valid customers with valid transactions. 
-- We leave them as is and use their customer_key if needed

	-- one unit with the item_key I00158 is null
	-- some sources say the unit is bags, so we update it to bags
    
UPDATE item_dim_clean
SET unit = "bags"
WHERE item_key = "I00158";
    
UPDATE fact_table_clean 
SET unit = "bags"
WHERE item_key = "I00158";

SELECT distinct unit
FROM item_dim_clean;
-- checked if it worked

-- 3. Standardizing data
SELECT DISTINCT unit
FROM fact_table_clean;
	-- ct and ct. is one unit
    -- bottles and botlltes is one unit
    -- we keep NULL as it is 
    -- pack is same as pk
    -- oz is same as oz.

UPDATE fact_table_clean
SET unit = CASE
    WHEN TRIM(LOWER(unit)) IN ('ct', 'ct.') THEN 'ct'
    WHEN TRIM(LOWER(unit)) IN ('bottles', 'botlltes') THEN 'bottle'
    WHEN TRIM(LOWER(unit)) IN ('pack', 'pk') THEN 'pack'
    WHEN TRIM(LOWER(unit)) IN ('oz', 'oz.') THEN 'oz'
    ELSE unit
END;

SELECT DISTINCT unit
FROM item_dim_clean;
-- same update as the unit column in fact table

UPDATE item_dim_clean
SET unit = CASE
    WHEN TRIM(LOWER(unit)) IN ('ct', 'ct.') THEN 'ct'
    WHEN TRIM(LOWER(unit)) IN ('bottles', 'botlltes') THEN 'bottle'
    WHEN TRIM(LOWER(unit)) IN ('pack', 'pk') THEN 'pack'
    WHEN TRIM(LOWER(unit)) IN ('oz', 'oz.') THEN 'oz'
    ELSE unit
END;


SELECT DISTINCT `desc`
FROM item_dim_clean;
	-- two result showing "Beverage - Energy/Protein"
     -- it seems that one of them have unnecessary white spaces
    -- there is a leading "a. " in some desc i want to remove it
    
SELECT 
    `desc`,
    LENGTH(`desc`) AS length_chars,
    CONCAT('[', `desc`, ']') AS visible_value
FROM item_dim
WHERE `desc` LIKE '%Beverage%Energy/Protein%';
	-- one of them is 26 characters long

UPDATE item_dim_clean
SET `desc` = TRIM(`desc`);
-- corrected the length 

UPDATE item_dim_clean
SET `desc` = REPLACE(`desc`, 'a. ', '')
WHERE `desc` LIKE 'a. %';
-- removed the leading "a. "

SELECT DISTINCT `desc`
FROM item_dim_clean;
-- check if updated;

SELECT DISTINCT man_country
FROM item_dim_clean;
-- poland is lowercase, i want to standardize it

UPDATE item_dim_clean
SET man_country = CONCAT(
    UPPER(LEFT(man_country, 1)),
    LOWER(SUBSTRING(man_country, 2))
);

SELECT DISTINCT man_country
FROM item_dim_clean;
-- check if worked

SELECT DISTINCT supplier
FROM item_dim_clean;
-- some are uppercase some are lowercase, i wanted to standardize that

UPDATE item_dim_clean
SET supplier = CONCAT(
    UPPER(LEFT(supplier, 1)),
    LOWER(SUBSTRING(supplier, 2))
);

SELECT DISTINCT supplier
FROM item_dim_clean;
-- check if worked

SELECT DISTINCT division
FROM store_dim_clean;

SELECT DISTINCT district
FROM store_dim_clean;

SELECT DISTINCT upazila
FROM store_dim_clean;
-- everything in the store_dim is uppercase, i want it to be proper

UPDATE store_dim_clean
SET division = CONCAT(
    UPPER(LEFT(division, 1)),
    LOWER(SUBSTRING(division, 2))
);

UPDATE store_dim_clean
SET district = CONCAT(
    UPPER(LEFT(district, 1)),
    LOWER(SUBSTRING(district, 2))
);

UPDATE store_dim_clean
SET upazila = CONCAT(
    UPPER(LEFT(upazila, 1)),
    LOWER(SUBSTRING(upazila, 2))
);

SELECT DISTINCT trans_type
FROM trans_dim_clean;
	
SELECT DISTINCT bank_name
FROM trans_dim_clean;
	-- one returned None inspect the None
    
SELECT *
FROM trans_dim_clean
WHERE bank_name = "None";    
-- its cash payment so having no bank is valid

UPDATE time_dim_clean
SET `date` = STR_TO_DATE(`date`, '%d-%m-%Y %H:%i');

ALTER TABLE time_dim_clean
MODIFY COLUMN `date` DATETIME;

SELECT MIN(`date`) AS first_date, MAX(`date`) AS last_date
FROM time_dim_clean;

-- Converting the date column to a real date type.
-- time_dim.date is stored as text (DD-MM-YYYY HH:MM).
-- MIN(date) returned '01-01-2015 00:15' because text sorts by characters, not chronologically.