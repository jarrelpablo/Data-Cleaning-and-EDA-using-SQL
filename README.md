# E-Commerce Analysis: SQL Data Cleaning, EDA and Power BI Dashboard

> A 1,000,000-transaction retail dataset (star schema, 6 tables) validated, cleaned and explored in MySQL, then turned into an interactive Power BI dashboard. Raw tables are never modified: every fix is applied to copies in a separate `data_cleaning` schema, and the dashboard is built on the cleaned tables.

![Dashboard](images/dashboard.png)

## 1. Project Overview

- **Goal:** Make the data reliable, then answer business questions about revenue, growth, products, customers, regions and payment methods, and present the answers in a dashboard.
- **Dataset:** [add source / link]. One fact table and five dimension tables, January 2014 to January 2021.
- **Tools:** MySQL (MySQL Workbench), Power BI Desktop, DAX.
- **Workflow:** Validate, Clean, Explore, Visualize.

**At a glance**

| Revenue | Transactions | Customers | Products | Store keys | Period |
|---|---|---|---|---|---|
| 105.4M | 1,000,000 | 9,191 | 264 | 726 (556 distinct locations) | Jan 2014 to Jan 2021 |

## 2. Repository Structure

```
Data-Cleaning-and-EDA-using-SQL/
├── README.md
├── Data Quality Assessment.sql      # read-only audit of the raw tables
├── Data Cleaning E-Commerce.sql     # cleaning on copies in the data_cleaning schema
├── EDA E-Commerce.sql               # analysis on the cleaned tables
├── powerbi/
│   ├── E-Commerce_Visualization.pbix   # report built on the cleaned tables
│   └── measures.dax                    # DAX measures used in the report
└── images/                          # dashboard, data model and result screenshots
```

## 3. Data Model

| Table | Role | Rows | Key columns |
|---|---|---|---|
| `fact_table` | Fact (transactions) | 1,000,000 | `payment_key`, `customer_key`, `item_key`, `time_key`, `store_key`, `quantity`, `unit`, `unit_price`, `total_price` |
| `customer_dim` | Dimension | 9,191 | `customer_key`, `name`, `contact_no`, `nid` |
| `item_dim` | Dimension | 264 | `item_key`, `item_name`, `desc`, `unit_price`, `man_country`, `supplier`, `unit` |
| `store_dim` | Dimension | 726 | `store_key`, `division`, `district`, `upazila` |
| `time_dim` | Dimension | 99,999 | `time_key`, `date`, `hour`, `day`, `week`, `month`, `quarter`, `year` |
| `trans_dim` | Dimension | 39 | `payment_key`, `trans_type`, `bank_name` |

*Data model: `images/data-model.png` (Power BI model view)*

> **Privacy:** `customer_dim` contains names, contact numbers and national IDs. These columns are not published in this repository. The Power BI report in `powerbi/` excludes them, and customers are identified by `customer_key` only.

## 4. Data Quality Assessment

Script: [`Data Quality Assessment.sql`](Data%20Quality%20Assessment.sql). Run on the raw tables before any change.

### 4.1 Structure and row counts

```sql
DESCRIBE customer_dim;
DESCRIBE fact_table;
DESCRIBE item_dim;
DESCRIBE store_dim;
DESCRIBE time_dim;
DESCRIBE trans_dim;

SELECT COUNT(*) FROM customer_dim;   -- 9,191
SELECT COUNT(*) FROM fact_table;     -- 1,000,000
SELECT COUNT(*) FROM item_dim;       -- 264
SELECT COUNT(*) FROM store_dim;      -- 726
SELECT COUNT(*) FROM time_dim;       -- 99,999
SELECT COUNT(*) FROM trans_dim;      -- 39
```

### 4.2 NULL and blank values

Every column is tested with `IS NULL`, and text columns also with `TRIM(col) = ''` to catch whitespace-only values.

```sql
-- customers
SELECT *
FROM customer_dim
WHERE coustomer_key IS NULL
   OR name IS NULL
   OR contact_no IS NULL
   OR nid IS NULL
   OR TRIM(coustomer_key) = ''
   OR TRIM(name) = '';
```

```sql
-- transactions
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
```

```sql
-- items
SELECT *
FROM item_dim
WHERE item_key IS NULL
   OR item_name IS NULL
   OR `desc` IS NULL
   OR unit_price IS NULL
   OR man_country IS NULL
   OR supplier IS NULL
   OR unit IS NULL
   OR TRIM(item_name) = ''
   OR TRIM(`desc`) = ''
   OR TRIM(man_country) = ''
   OR TRIM(supplier) = ''
   OR TRIM(unit) = '';
```

The same pattern was applied to `store_dim`, `trans_dim` and `time_dim`.

| Table | Result |
|---|---|
| `customer_dim` | 27 blank or NULL names |
| `fact_table` | 1 NULL `unit` (item `I00158`) |
| `item_dim` | 1 NULL `unit` (item `I00158`) |
| `store_dim`, `trans_dim`, `time_dim` | No NULLs or blanks |

### 4.3 Value and consistency checks

```sql
-- negative unit prices in the item list
SELECT * FROM item_dim WHERE unit_price < 0;

-- zero or negative values in transactions
SELECT *
FROM fact_table
WHERE unit_price <= 0 OR total_price <= 0 OR quantity <= 0;

-- does unit_price x quantity equal total_price?
SELECT *
FROM fact_table
WHERE (unit_price * quantity) - total_price <> 0;
```

**Result:** no negative or zero values and no pricing inconsistencies.

### 4.4 Time dimension ranges

```sql
SELECT DISTINCT `hour`    FROM time_dim ORDER BY `hour`;
SELECT DISTINCT `day`     FROM time_dim ORDER BY `day`;
SELECT DISTINCT `week`    FROM time_dim ORDER BY `week`;
SELECT DISTINCT `month`   FROM time_dim ORDER BY `month`;
SELECT DISTINCT `quarter` FROM time_dim ORDER BY `quarter`;
SELECT DISTINCT `year`    FROM time_dim ORDER BY `year`;
```

**Result:** all values fall in valid ranges.

### 4.5 Referential integrity

Each query returns fact-table keys that are missing from the dimension. An empty result means no orphans.

```sql
SELECT f.coustomer_key
FROM fact_table f
LEFT JOIN customer_dim c ON f.coustomer_key = c.coustomer_key
WHERE c.coustomer_key IS NULL;

SELECT f.item_key
FROM fact_table f
LEFT JOIN item_dim i ON f.item_key = i.item_key
WHERE i.item_key IS NULL;

SELECT f.store_key
FROM fact_table f
LEFT JOIN store_dim s ON f.store_key = s.store_key
WHERE s.store_key IS NULL;

SELECT f.time_key
FROM fact_table f
LEFT JOIN time_dim t ON f.time_key = t.time_key
WHERE t.time_key IS NULL;

SELECT f.payment_key
FROM fact_table f
LEFT JOIN trans_dim t ON f.payment_key = t.payment_key
WHERE t.payment_key IS NULL;
```

**Result:** every foreign key in the fact table exists in its dimension.

### 4.6 Issues found

- Column name typo: `coustomer_key` in `fact_table` and `customer_dim`.
- 27 blank customer names.
- 1 NULL unit for item `I00158`.
- Inconsistent units, text casing and whitespace (found while profiling, fixed in Section 5).
- `time_dim.date` is stored as text in `DD-MM-YYYY HH:MM` format, so `MIN(date)` compares characters and returns `01-01-2015 00:15` (fixed in Section 5.7).
- Found later, while building the dashboard: five item names appear under two item keys each (see Section 7.5).

## 5. Data Cleaning

Script: [`Data Cleaning E-Commerce.sql`](Data%20Cleaning%20E-Commerce.sql).

### 5.1 Setup: copy tables into a separate schema

```sql
CREATE SCHEMA data_cleaning;

CREATE TABLE data_cleaning.customer_dim_clean AS SELECT * FROM customer_dim;
CREATE TABLE data_cleaning.fact_table_clean   AS SELECT * FROM fact_table;
CREATE TABLE data_cleaning.item_dim_clean     AS SELECT * FROM item_dim;
CREATE TABLE data_cleaning.store_dim_clean    AS SELECT * FROM store_dim;
CREATE TABLE data_cleaning.time_dim_clean     AS SELECT * FROM time_dim;
CREATE TABLE data_cleaning.trans_dim_clean    AS SELECT * FROM trans_dim;

USE data_cleaning;

ALTER TABLE fact_table_clean   RENAME COLUMN coustomer_key TO customer_key;
ALTER TABLE customer_dim_clean RENAME COLUMN coustomer_key TO customer_key;
```

### 5.2 Duplicate check on primary keys

```sql
SELECT customer_key, COUNT(*) AS Count FROM customer_dim_clean GROUP BY customer_key HAVING COUNT(*) > 1;
SELECT item_key,     COUNT(*) AS Count FROM item_dim_clean     GROUP BY item_key     HAVING COUNT(*) > 1;
SELECT payment_key,  COUNT(*) AS Count FROM trans_dim_clean    GROUP BY payment_key  HAVING COUNT(*) > 1;
SELECT store_key,    COUNT(*) AS Count FROM store_dim_clean    GROUP BY store_key    HAVING COUNT(*) > 1;
SELECT time_key,     COUNT(*) AS Count FROM time_dim_clean     GROUP BY time_key     HAVING COUNT(*) > 1;
```

**Result:** no duplicate keys, so no rows were removed.

### 5.3 NULL and blank values

| Issue | Decision | Reason |
|---|---|---|
| 27 blank customer names | Kept | Valid customers with valid transactions; `customer_key` identifies them |
| NULL `unit` for `I00158` | Set to `bags` | Based on outside sources (an assumption, see Limitations) |
| `bank_name = 'None'` | Kept | These are cash payments, so no bank is valid |

```sql
UPDATE item_dim_clean
SET unit = 'bags'
WHERE item_key = 'I00158';

UPDATE fact_table_clean
SET unit = 'bags'
WHERE item_key = 'I00158';

-- confirm the cash rows
SELECT * FROM trans_dim_clean WHERE bank_name = 'None';
```

### 5.4 Standardizing units

Variants found: `ct` / `ct.`, `bottles` / `botlltes`, `pack` / `pk`, `oz` / `oz.`. The same update was run on `fact_table_clean` and `item_dim_clean`.

```sql
UPDATE fact_table_clean
SET unit = CASE
    WHEN TRIM(LOWER(unit)) IN ('ct', 'ct.')           THEN 'ct'
    WHEN TRIM(LOWER(unit)) IN ('bottles', 'botlltes') THEN 'bottle'
    WHEN TRIM(LOWER(unit)) IN ('pack', 'pk')          THEN 'pack'
    WHEN TRIM(LOWER(unit)) IN ('oz', 'oz.')           THEN 'oz'
    ELSE unit
END;
```

### 5.5 Cleaning item descriptions

Two "Beverage - Energy/Protein" values looked identical in `SELECT DISTINCT`. Measuring length and wrapping the value in brackets exposed trailing whitespace:

```sql
SELECT
    `desc`,
    LENGTH(`desc`)           AS length_chars,
    CONCAT('[', `desc`, ']') AS visible_value
FROM item_dim
WHERE `desc` LIKE '%Beverage%Energy/Protein%';
-- one value was 26 characters long
```

```sql
UPDATE item_dim_clean
SET `desc` = TRIM(`desc`);

-- remove the leading "a. " prefix
UPDATE item_dim_clean
SET `desc` = REPLACE(`desc`, 'a. ', '')
WHERE `desc` LIKE 'a. %';
```

### 5.6 Standardizing text casing

`man_country` had a lowercase "poland", `supplier` had mixed casing, and every `store_dim` location column was uppercase. All were converted to first letter upper, rest lower:

```sql
UPDATE item_dim_clean
SET man_country = CONCAT(UPPER(LEFT(man_country, 1)), LOWER(SUBSTRING(man_country, 2)));

UPDATE item_dim_clean
SET supplier = CONCAT(UPPER(LEFT(supplier, 1)), LOWER(SUBSTRING(supplier, 2)));

UPDATE store_dim_clean
SET division = CONCAT(UPPER(LEFT(division, 1)), LOWER(SUBSTRING(division, 2)));

UPDATE store_dim_clean
SET district = CONCAT(UPPER(LEFT(district, 1)), LOWER(SUBSTRING(district, 2)));

UPDATE store_dim_clean
SET upazila = CONCAT(UPPER(LEFT(upazila, 1)), LOWER(SUBSTRING(upazila, 2)));
```

Each update was followed by a `SELECT DISTINCT` to confirm it worked.

> **Limitation:** this pattern lowercases everything after the first letter, so multi-word values lose inner capitals (for example "Indo Count Industries Ltd" becomes "Indo count industries ltd"). A word-by-word proper-casing function would avoid that.

### 5.7 Converting the date column

`time_dim.date` is text, so the first attempt at `MIN(date)` returned `01-01-2015 00:15`: text sorts by characters, not chronologically. The column was converted to a real `DATETIME`:

```sql
UPDATE time_dim_clean
SET `date` = STR_TO_DATE(`date`, '%d-%m-%Y %H:%i');

ALTER TABLE time_dim_clean
MODIFY COLUMN `date` DATETIME;

SELECT MIN(`date`) AS first_date, MAX(`date`) AS last_date
FROM time_dim_clean;
```

### 5.8 Cleaning summary

| Table | Changes |
|---|---|
| `fact_table_clean` | Renamed `customer_key`; filled `unit` for `I00158`; standardized units |
| `customer_dim_clean` | Renamed `customer_key`; blank names kept |
| `item_dim_clean` | Filled and standardized `unit`; trimmed `desc` and removed prefix; fixed casing of `man_country` and `supplier` |
| `store_dim_clean` | Fixed casing of `division`, `district`, `upazila` |
| `time_dim_clean` | Converted `date` from text to `DATETIME` |
| `trans_dim_clean` | No changes needed |

## 6. Exploratory Data Analysis

Script: [`EDA E-Commerce.sql`](EDA%20E-Commerce.sql). All queries run on the cleaned tables.

```sql
USE data_cleaning;
```

### 6.1 Key performance indicators

**Question:** What does the business look like at a glance?

```sql
SELECT
    SUM(total_price)  AS Revenue,
    COUNT(*)          AS Total_Transactions,
    AVG(total_price)  AS Average_Transaction_Value,
    SUM(quantity)     AS Total_Quantity_Sold,
    MIN(total_price)  AS Minimum_Transaction_Value,
    MAX(total_price)  AS Maximum_Transaction_Value
FROM fact_table_clean;
```

| Revenue | Transactions | Avg. transaction | Units sold | Min | Max |
|---|---|---|---|---|---|
| 105,401,435.75 | 1,000,000 | 105.40 | 6,000,185 | 6 | 605 |

**Finding:** Each transaction holds about 6 units and is worth about 105. Transaction values range from 6 to 605.

### 6.2 Monthly revenue

**Question:** How do revenue, transaction count and basket value change month by month?

```sql
SELECT
    t.year  AS Year,
    t.month AS Month,
    SUM(f.total_price) AS Revenue,
    COUNT(*)           AS Total_Transactions,
    AVG(f.total_price) AS Average_Transaction_Value
FROM fact_table_clean f
JOIN time_dim_clean t ON t.time_key = f.time_key
GROUP BY t.year, t.month
ORDER BY t.year, t.month;
```

**Finding:** The data covers 85 months. January 2014 (496,549) and January 2021 (883,772) look incomplete, so they are treated as partial months. Across the 83 full months revenue averages 1.25M and stays between 1.12M (February 2014) and 1.35M (December 2020). February is the weakest calendar month, about 8% below the average month, but only about 1% below on a per-day basis, because it has fewer days. Revenue per day is steady at about 41K.

### 6.3 Month-over-month growth

**Question:** Which months grew or shrank the most compared with the month before?

```sql
WITH monthly AS (
    SELECT
        t.year  AS Year,
        t.month AS Month,
        SUM(f.total_price) AS Revenue
    FROM fact_table_clean f
    JOIN time_dim_clean t ON t.time_key = f.time_key
    GROUP BY t.year, t.month
)
SELECT
    Year,
    Month,
    Revenue,
    LAG(Revenue) OVER (ORDER BY Year, Month) AS Previous_Month_Revenue,
    ROUND(
        (Revenue - LAG(Revenue) OVER (ORDER BY Year, Month))
        / NULLIF(LAG(Revenue) OVER (ORDER BY Year, Month), 0) * 100,
        2
    ) AS MoM_Percentage
FROM monthly
ORDER BY Year, Month;
```

`LAG()` brings the previous month's revenue onto the current row. `NULLIF(..., 0)` avoids division by zero.

**Finding:** The very large swings (+126% in February 2014 and -34% in January 2021) come from the partial months. Among full months, the biggest rise is +12.75% (May 2015) and the biggest fall is -14.34% (February 2019). Month-to-month changes are mostly seasonal (short months fall, long months recover), not a trend.

### 6.4 Year-over-year growth

**Question:** Is the business growing from year to year?

```sql
WITH yearly AS (
    SELECT
        t.year AS Year,
        SUM(f.total_price) AS Revenue
    FROM fact_table_clean f
    JOIN time_dim_clean t ON t.time_key = f.time_key
    GROUP BY t.year
)
SELECT
    Year,
    Revenue,
    LAG(Revenue) OVER (ORDER BY Year) AS Previous_Year_Revenue,
    ROUND(
        (Revenue - LAG(Revenue) OVER (ORDER BY Year))
        / NULLIF(LAG(Revenue) OVER (ORDER BY Year), 0) * 100,
        2
    ) AS YoY_Percentage
FROM yearly
ORDER BY Year;
```

| Year | Revenue | YoY |
|---|---|---|
| 2014 | 14,334,731 | n/a (January incomplete) |
| 2015 | 15,095,720 | +5.31% |
| 2016 | 14,976,508 | -0.79% |
| 2017 | 15,015,806 | +0.26% |
| 2018 | 15,108,197 | +0.62% |
| 2019 | 14,949,510 | -1.05% |
| 2020 | 15,037,190 | +0.59% |
| 2021 | 883,772 | January only |

**Finding:** Revenue is flat at about 15M a year. From 2015 to 2020 every year is within about 1% of the 15.03M average, and 2020 ended 0.39% below 2015. The +5.31% in 2015 is mostly a base effect from the incomplete January 2014, and 2021 contains January only.

### 6.5 Top 10 products by revenue

**Question:** Which items generate the most revenue?

```sql
SELECT
    f.item_key,
    i.item_name,
    SUM(f.quantity)    AS Total_Quantity,
    AVG(f.unit_price)  AS Average_Unit_Price,
    SUM(f.total_price) AS Total_Revenue
FROM fact_table_clean f
JOIN item_dim_clean i ON i.item_key = f.item_key
GROUP BY f.item_key, i.item_name
ORDER BY Total_Revenue DESC
LIMIT 10;
```

| Item key | Item | Units | Unit price | Revenue |
|---|---|---|---|---|
| I00061 | Red Bull 12oz | 23,740 | 55 | 1,305,700 |
| I00115 | K Cups Daily Chef Columbian Supremo | 23,498 | 53 | 1,245,394 |
| I00119 | K Cups Original Donut Shop Med. Roast | 22,431 | 53 | 1,188,843 |
| I00116 | K Cups Dunkin Donuts Medium Roast | 23,120 | 48 | 1,109,760 |
| I00117 | K Cups Folgers Lively Columbian | 22,661 | 46 | 1,042,406 |
| I00123 | Honey Packets | 22,511 | 45 | 1,012,995 |
| I00114 | K Cups - Starbuck's Pike Place | 22,624 | 44 | 995,456 |
| I00118 | K Cups - Organic Breakfast Blend | 22,798 | 42 | 957,516 |
| I00113 | K Cups - McCafe Premium Roast | 22,783 | 42 | 956,886 |
| I00064 | Red Bull Sugar Free 8.4 oz | 23,343 | 40 | 933,720 |

**Finding:** The top 10 products bring in 10.75M, 10.2% of revenue, so revenue is not concentrated. They each sell 22.4K to 23.7K units, close to the 22.7K average per product, so they rank by price, not by volume. All seven K-Cups items are in the top 10.

### 6.6 Top 10 customers by spend

**Question:** Who are the highest-value customers?

```sql
SELECT
    customer_key,
    COUNT(*)         AS Total_Transactions,
    SUM(total_price) AS Total_Revenue,
    AVG(total_price) AS Average_Transaction_Value
FROM fact_table_clean
GROUP BY customer_key
ORDER BY Total_Revenue DESC
LIMIT 10;
```

Grouping by `customer_key` instead of name keeps the 27 blank-name customers in the analysis.

| Customer | Transactions | Revenue | Avg. transaction |
|---|---|---|---|
| C004349 | 137 | 17,104.50 | 124.85 |
| C005316 | 149 | 16,853.25 | 113.11 |
| C000273 | 135 | 16,645.75 | 123.30 |
| C001438 | 138 | 16,381.50 | 118.71 |
| C007553 | 143 | 16,288.75 | 113.91 |
| C007415 | 123 | 16,282.50 | 132.38 |
| C008009 | 118 | 16,194.75 | 137.24 |
| C007205 | 129 | 16,154.50 | 125.23 |
| C002968 | 140 | 16,006.50 | 114.33 |
| C006902 | 128 | 15,977.25 | 124.82 |

**Finding:** The top 10 customers together produce 163,889 (0.16% of revenue). The best customer spends about 1.5 times the average customer (11,468). Each customer makes about 109 transactions on average, and the top 10 make 8% to 37% more than that.

### 6.7 Revenue by division

**Question:** Which regions generate the most revenue?

```sql
SELECT
    s.division,
    SUM(f.total_price) AS Total_Revenue,
    AVG(f.total_price) AS Average_Transaction_Value,
    COUNT(*)           AS Number_of_Orders
FROM fact_table_clean f
JOIN store_dim_clean s ON s.store_key = f.store_key
GROUP BY s.division
ORDER BY Total_Revenue DESC;
```

| Division | Revenue | Share | Orders | Avg. order |
|---|---|---|---|---|
| Dhaka | 40,764,620 | 38.7% | 386,888 | 105.37 |
| Chittagong | 19,763,595 | 18.8% | 187,340 | 105.50 |
| Rajshahi | 12,099,196 | 11.5% | 115,075 | 105.14 |
| Khulna | 11,311,611 | 10.7% | 107,164 | 105.55 |
| Rangpur | 8,429,837 | 8.0% | 79,926 | 105.47 |
| Barisal | 7,520,344 | 7.1% | 71,444 | 105.26 |
| Sylhet | 5,512,234 | 5.2% | 52,163 | 105.67 |

**Finding:** Dhaka leads with 38.7% of revenue and Sylhet trails with 5.2%. The order is explained by store count, not by customer behavior: each store key earns about 145K in every division (Dhaka has 280 of the 726 store keys), and the average order is about 105 everywhere.

### 6.8 Payment methods

**Question:** How do customers pay, and does payment type affect basket size?

```sql
SELECT
    t.trans_type,
    COUNT(*)           AS Total_Transactions,
    SUM(f.total_price) AS Total_Transaction_Value,
    AVG(f.total_price) AS Average_Transaction_Value
FROM fact_table_clean f
JOIN trans_dim_clean t ON f.payment_key = t.payment_key
GROUP BY t.trans_type
ORDER BY Total_Transactions DESC;
```

| Payment type | Transactions | Share | Value | Avg. transaction |
|---|---|---|---|---|
| Card | 897,319 | 89.7% | 94,583,039 | 105.41 |
| Mobile | 77,091 | 7.7% | 8,109,882 | 105.20 |
| Cash | 25,590 | 2.6% | 2,708,516 | 105.84 |

**Finding:** Card is 89.7% of transactions. That matches card's share of payment keys (35 of 39), and each payment key handles about 25,600 transactions. Average transaction value is within 1% across the three payment types.

## 7. Power BI Dashboard

File: [`powerbi/E-Commerce_Visualization.pbix`](powerbi/E-Commerce_Visualization.pbix). Open it with Power BI Desktop (free).

![Dashboard](images/dashboard.png)

### 7.1 Data model

The report is built on the cleaned tables (`*_clean`) from the `data_cleaning` schema, in the same star schema as the SQL project. Each dimension relates to `fact_table_clean` as one-to-many with single-direction filtering (dimension filters fact).

| Dimension | Key | Fact table column |
|---|---|---|
| `time_dim_clean` | `time_key` | `time_key` |
| `item_dim_clean` | `item_key` | `item_key` |
| `store_dim_clean` | `store_key` | `store_key` |
| `customer_dim_clean` | `customer_key` | `customer_key` |
| `trans_dim_clean` | `payment_key` | `payment_key` |

![Data model](images/data-model.png)

### 7.2 Dashboard contents

| Visual | Shows |
|---|---|
| KPI cards | Total revenue (with YoY % and MoM %), units sold, customers, items, stores and distinct locations |
| Line chart | Revenue by month, one line per year, with the average monthly revenue as a reference line |
| Bar chart | Top 10 products by revenue |
| Table | Top 10 customers by revenue (customer key, revenue, transactions, average revenue per transaction) |
| Bar chart | Revenue by division |
| Pie chart | Transactions by payment type |
| Slicers | Year and month |

### 7.3 DAX measures

The time table stores a timestamp every 15 minutes and has no day-level calendar, so built-in time intelligence (`DATEADD`, `PREVIOUSMONTH`) cannot be used. Previous-period measures read the `year` and `month` columns instead.

```dax
Total Revenue = SUM ( fact_table_clean[total_price] )

Total Transactions = COUNTROWS ( fact_table_clean )

Avg Revenue per Transaction = DIVIDE ( [Total Revenue], [Total Transactions] )

Avg Units per Product =
DIVIDE ( SUM ( fact_table_clean[quantity] ), DISTINCTCOUNT ( fact_table_clean[item_key] ) )

Distinct Locations =
COUNTROWS (
    SUMMARIZE (
        store_dim_clean,
        store_dim_clean[division],
        store_dim_clean[district],
        store_dim_clean[upazila]
    )
)

Avg Revenue per Month =
AVERAGEX (
    SUMMARIZE ( time_dim_clean, time_dim_clean[year], time_dim_clean[month] ),
    [Total Revenue]
)
```

**Month over month.** With one year and one month selected, the previous month is found by shifting the month (January rolls back to December of the previous year):

```dax
Sales PM =
VAR CurrYear  = SELECTEDVALUE ( time_dim_clean[year] )
VAR CurrMonth = SELECTEDVALUE ( time_dim_clean[month] )
VAR PrevYear  = IF ( CurrMonth = 1, CurrYear - 1, CurrYear )
VAR PrevMonth = IF ( CurrMonth = 1, 12, CurrMonth - 1 )
RETURN
    IF (
        ISBLANK ( CurrYear ) || ISBLANK ( CurrMonth ),
        BLANK (),
        CALCULATE (
            [Total Revenue],
            REMOVEFILTERS ( time_dim_clean ),
            time_dim_clean[year]  = PrevYear,
            time_dim_clean[month] = PrevMonth
        )
    )

MoM % = DIVIDE ( [Total Revenue] - [Sales PM], [Sales PM] )
```

**Year over year.** Only the year filter is replaced, so the measure works with a year alone (year against the previous year) and with a year and month (month against the same month a year earlier):

```dax
Sales PY =
VAR CurrYear = SELECTEDVALUE ( time_dim_clean[year] )
RETURN
    IF (
        ISBLANK ( CurrYear ),
        BLANK (),
        CALCULATE (
            [Total Revenue],
            REMOVEFILTERS ( time_dim_clean[year] ),
            time_dim_clean[year] = CurrYear - 1
        )
    )

YoY % = DIVIDE ( [Total Revenue] - [Sales PY], [Sales PY] )
```

### 7.4 Dashboard checked against the SQL results

The dashboard figures were reconciled with the SQL EDA output.

| Metric | SQL | Dashboard |
|---|---|---|
| Total revenue | 105,401,435.75 | 105.40M |
| Transactions | 1,000,000 | 1M |
| Units sold | 6,000,185 | 6M |
| Customers | 9,191 | 9.191K |
| Items, store keys, distinct locations | 264, 726, 556 | 264, 726, 556 |
| Average units per product | 22,728 | 22.73K |
| Average monthly revenue | 1,240,017 | 1.24M |
| Top customer | C004349, 17,104.50 | C004349, 17,104.50 |
| Card share of transactions | 897,319 (89.7%) | 897.32K (89.73%) |

### 7.5 Item name versus item key

The SQL top-10 query groups by `item_key`. A Power BI visual grouped by `item_name` gives a slightly different top 10, because five item names appear under two item keys each, at different prices (probably different pack sizes): Coke Classic, Diet Coke, Pepsi and Sprite (12 oz cans, 6.75 and 16.25), and Muscle Milk Van. 11oz (22 and 24). Grouped by name, the two Muscle Milk keys add up to 1.05M and enter the top 10. Group by `item_key`, or add the pack size to the name, when you want results to match the SQL.

## 8. Key Insights

1. **Revenue is flat.** About 15M a year from 2015 to 2020, within a 1% band, and 2020 ended 0.39% below 2015.
2. **Calendar effects, not trends.** February is about 8% below the average month but only about 1% below per day, and revenue per day is steady at about 41K.
3. **Price decides the best sellers.** The top 10 products each sell 22K to 24K units, so they rank by price. They make up 10.2% of revenue, and all seven K-Cups items are among them.
4. **No customer matters much.** The top 10 customers produce 0.16% of revenue.
5. **Store count explains the regions.** Dhaka has 38.7% of revenue because it has 280 of 726 store keys. Every store key earns about 145K.
6. **Card is the main payment method.** 89.7% of transactions, in line with its share of payment keys, and basket value is about the same for every payment type.
7. **The data looks generated.** Products, stores, payment keys and customers behave very uniformly, so the findings describe this dataset, not real consumer behavior.

## 9. Challenges and Decisions

- Blank customer names were kept, because the keys are valid and transactions are real.
- The unit for item `I00158` was filled from outside sources rather than deleted.
- Cash payments with no bank were treated as valid.
- Raw tables were preserved by cleaning copies in a separate schema.
- The date column was stored as text. Converting it to `DATETIME` fixed `MIN` and `MAX`.
- The time table has no day-level calendar, so month and year comparisons in DAX use the `year` and `month` columns instead of built-in time intelligence.
- Customer names, contact numbers and national IDs were left out of the dashboard.

## 10. Limitations

- January 2014 and January 2021 look incomplete. Their month-over-month and year-over-year changes are not real growth rates.
- The `bags` unit for `I00158` is an assumption.
- 27 customers have no name, so name-based customer analysis is incomplete.
- 726 store keys map to 556 distinct locations, so some locations hold more than one store key.
- Five item names are shared by two item keys (Section 7.5).
- Text casing was standardized with a simple rule that lowercases inner capitals (Section 5.6).
- The patterns are unusually uniform, which suggests generated data.

## 11. Skills Demonstrated

**SQL:** data profiling and validation, `LEFT JOIN` orphan checks, `GROUP BY` / `HAVING`, CTEs, window functions (`LAG`) for MoM and YoY growth, multi-table joins on a star schema, `CASE` expressions, string functions (`TRIM`, `LOWER`, `UPPER`, `LEFT`, `SUBSTRING`, `REPLACE`, `CONCAT`), type conversion with `STR_TO_DATE`, `ALTER TABLE`, and a schema-separation workflow that preserves raw data.

**Power BI and DAX:** star-schema data modeling, measures with `CALCULATE`, `REMOVEFILTERS`, `SELECTEDVALUE`, `SUMMARIZE`, `AVERAGEX` and `DIVIDE`, MoM and YoY comparisons without a date table, KPI cards, slicers, and reconciling dashboard figures against SQL results.

## 12. How to Reproduce

1. Load the six CSVs into a schema as `customer_dim`, `fact_table`, `item_dim`, `store_dim`, `time_dim`, `trans_dim`.
2. Run `Data Quality Assessment.sql`.
3. Run `Data Cleaning E-Commerce.sql`.
4. Run `EDA E-Commerce.sql`.
5. Open `powerbi/E-Commerce_Visualization.pbix` in Power BI Desktop. To refresh it against your own MySQL server, choose Home, Transform data, Data source settings and point it at the `data_cleaning` schema.

## 13. Next Steps

- Add a customer analysis page: distribution of transactions and revenue per customer.
- Add a product analysis page: price against revenue, and revenue by supplier.
- Confirm the partial first and last months after the date conversion, and exclude them from growth measures.
- Resolve the duplicate item names, for example by adding pack size to the name.

---
**Author:** [jarrelpablo](https://github.com/jarrelpablo) | [LinkedIn] | [Portfolio]
