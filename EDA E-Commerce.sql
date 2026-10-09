-- Exploratory Data Analysis

USE data_cleaning;

-- Descriptive Statistics
-- Key Performance Indicators
SELECT 
	SUM(total_price) AS Revenue,
	COUNT(*) AS Total_Transactions,
	AVG(total_price) AS Average_Trasaction_Value,
    SUM(quantity) AS Total_Quantity_Sold,
	MIN(total_price) AS Minimum_Transaction_Value,
	MAX(total_price) AS Maximum_Transaction_Value
FROM fact_table_clean;
-- The dataset records about 105,401,435.75 in revenue across 1,000,000 transactions.
-- Total inventory moved is 6,000,185.
-- Transaction values range from 6 to 605, so there is a wide spread in basket size.

-- Time Based Analysis 
-- MoM%  Comparison
WITH monthly AS (
    SELECT 
        t.year AS Year,
        t.month AS Month,
        SUM(f.total_price) AS Revenue,
        SUM(f.total_price) / COUNT(DISTINCT DATE(t.`date`)) AS Revenue_per_Day
    FROM fact_table_clean f
    JOIN time_dim_clean t
        ON t.time_key = f.time_key
    GROUP BY t.year, t.month
)
SELECT
    Year,
    Month,
    Revenue,
    LAG(Revenue) OVER (
        ORDER BY Year, Month
    ) AS Previous_Month_Revenue,
    Revenue_Per_Day,

    ROUND(
        (Revenue - LAG(Revenue) OVER (
            ORDER BY Year, Month
        ))
        / NULLIF(
            LAG(Revenue) OVER (
                ORDER BY Year, Month
            ), 0
        ) * 100,
        2
    ) AS MoM_Percentage

FROM monthly
ORDER BY Year, Month;
-- The revenue averages about 1.25M and moves in a narrow band (1.12M to 1.35M) with no growth or decline over the period
-- Revenue is almost constant at 41,000 per day 
-- The extreme values (+126% in Feb 2014, −34% in Jan 2021) come from partial months at the start and end of the data


-- YoY% Comparison

WITH yearly AS (
    SELECT 
        t.year AS Year,
        SUM(f.total_price) AS Revenue
    FROM fact_table_clean f
    JOIN time_dim_clean t
        ON t.time_key = f.time_key
    GROUP BY t.year
)
SELECT
    Year,
    Revenue,
    LAG(Revenue) OVER (
        ORDER BY Year
    ) AS Previous_Year_Revenue,

    ROUND(
        (Revenue - LAG(Revenue) OVER (
            ORDER BY Year
        ))
        / NULLIF(
            LAG(Revenue) OVER (
                ORDER BY Year
            ), 0
        ) * 100,
        2
    ) AS YoY_Percentage

FROM yearly
ORDER BY Year;
-- Annual revenue is flat. The six full years (2015–2020) average about 15.03M and stay within 14.95M to 15.11M, a spread of roughly 1%.
-- The two extreme percentages come from partial years: the +5.31% for 2015 reflects an incomplete January 2014, and
-- the −94.12% for 2021 reflects a single month of data. 
-- The E-Commerce business is stable but not growing.

-- Product generated the most revenue
SELECT 
    item_name, 
    SUM(quantity),  
    SUM(total_price) AS Total_Revenue
FROM fact_table_clean f
JOIN item_dim_clean i
	ON i.item_key = f.item_key
GROUP BY item_name
ORDER BY Total_Revenue DESC
LIMIT 10;
-- The top 10 products generate about 10.75M, roughly 10.2% of total revenue.
-- Red Bull 12oz leads with 1,305,700 (23,740 units)
-- All seven K-Cups products rank in the top 10 and together contribute about 7.5M (7.1% of revenue).
-- Sales volumes are nearly identical across these items (22,783–23,740 units)
-- so revenue rank is driven almost entirely by unit price: 

-- Customer generated the most revenue
SELECT 
    customer_key,
    COUNT(*) AS Total_Transactions,
    SUM(total_price) AS Total_Revenue,
    AVG(total_price) AS Average_Transaction_Value
FROM fact_table_clean
GROUP BY customer_key
ORDER BY Total_Revenue DESC
LIMIT 10;
-- Customer spending is evenly distributed 
-- The top 10 customers together generate 163,889, only 0.16% of total revenue (compared with 0.11% of customers)
-- The top The top 10 differ from the average mainly in purchase frequency (118–149 transactions
-- versus about 109 on average) and, to a lesser degree, basket size (about 122 versus 105).
-- Revenue does not depend on a small group of customers.

-- Division which store who generated the most revenue
SELECT 
	division, 
    SUM(total_price) AS Total_Revenue,
    AVG(total_price) AS Average_Transactions_Value,
    COUNT(customer_key) AS Number_of_Orders,
    COUNT(DISTINCT s.store_key) AS Number_of_Stores
    
FROM fact_table_clean f
JOIN store_dim_clean s
ON s.store_key = f.store_key
GROUP BY division
ORDER BY Total_Revenue DESC;
-- Dhaka leads all division with 40.76M about 38.7% of total revenue while leading the number of stores with 280 and number of orders with 386888.
-- Average transaction value is almost identical in every division (105.14 to 105.67).
-- So the divisions differ in order volume, not in spending per order.

-- Most common payment method
SELECT
	trans_type,
    COUNT(customer_key) AS Total_Type_of_Transaction,
    SUM(total_price) AS Total_Transaction_Value,
    COUNT(DISTINCT t.payment_key) AS Number_of_Trans_Type,
    AVG(total_price) AS Average_Transaction_Value
FROM fact_table_clean f
JOIN trans_dim_clean t
	ON f.payment_key = t.payment_key
    GROUP BY trans_type
ORDER BY Total_Type_of_Transaction DESC;

-- Card is by far the most common payment method, with 897,319 transactions (89.7%) and 94.58M in value
-- Average transaction value is nearly identical across methods (105.20 to 105.84), so payment type does not affect basket size.
-- 

