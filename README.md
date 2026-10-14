# E-Commerce Analysis: SQL and Power BI

> An end-to-end analysis of 1,000,000 retail transactions: data gathering, quality checks and cleaning in MySQL, exploratory analysis, a Power BI dashboard, and recommendations.


## 1. Project Overview

**Goal:** find out how the business earns its revenue and what it should do next.

**Questions answered**

- How much revenue does the business make, and how does it change by month and year?
- Which products, customers, divisions and payment methods matter most?
- Is there any seasonality to plan around?

**Workflow**

| Step | What was done | File |
|---|---|---|
| 1. Gather | Loaded the six source tables into MySQL | [Data section](#2-data-gathering) |
| 2. Assess | Checked the raw tables for blanks, bad values and broken keys | [`Data_Quality_Assessment_E-Commerce.sql`](Data_Quality_Assessment_E-Commerce.sql) |
| 3. Clean | Fixed the issues on copies in a separate `data_cleaning` schema | [`Data_Cleaning_E-Commerce.sql`](Data_Cleaning_E-Commerce.sql) |
| 4. Explore | Calculated KPIs, trends, and top products, customers, divisions and payments | [`EDA_E-Commerce.sql`](EDA_E-Commerce.sql) |
| 5. Visualize | Built an interactive dashboard on the cleaned tables | [`powerbi/E-Commerce_Visualization.pbix`](powerbi/E-Commerce_Visualization.pbix) |
| 6. Recommend | Turned the findings into actions | [Sections 6 and 7](#6-key-insights) |

Each SQL script is commented step by step.

## 2. Data Gathering

Source: [add source / link]. The data is a star schema covering January 2014 to January 2021, loaded into MySQL as six tables.

| Table | Rows | Contents |
|---|---|---|
| `fact_table` | 1,000,000 | One row per transaction: keys, quantity, unit, unit price, total price |
| `customer_dim` | 9,191 | Customers |
| `item_dim` | 264 | Products: name, description, supplier, country, unit, price |
| `store_dim` | 726 | Store keys with division, district and upazila |
| `time_dim` | 99,999 | Date, hour, day, week, month, quarter, year |
| `trans_dim` | 39 | Payment type and bank |

Customer names, contact numbers and national IDs are not published. Customers appear by `customer_key` only.

## 3. Data Quality Assessment

The raw tables were checked for structure, row counts, nulls, impossible values and broken keys.

| Check | Result |
|---|---|
| Row counts | All six tables match the counts above |
| Nulls and blanks | 27 customers with blank names; one item (`I00158`) with no unit; nothing else |
| Prices | No negative or zero prices or quantities; `unit_price × quantity` equals `total_price` in every row |
| Time table | Hour, day, week, month, quarter and year values are all valid |
| Keys | Every foreign key in the fact table exists in its dimension table; no duplicate primary keys |

## 4. Data Cleaning

All cleaning was done on copies (`*_clean`) in a separate `data_cleaning` schema, so the raw tables stay untouched.

| Problem | Fix |
|---|---|
| Misspelled column `coustomer_key` | Renamed to `customer_key` |
| Missing unit for item `I00158` | Set to `bags` (an assumption, based on outside sources) |
| Inconsistent units (`ct` / `ct.`, `bottles` / `botlltes`, `pack` / `pk`, `oz` / `oz.`) | Standardized to one value each |
| Extra spaces and a leading `a. ` in item descriptions | Trimmed and removed |
| Mixed casing in country, supplier and store names | Converted to proper case |
| Date stored as text (`DD-MM-YYYY HH:MM`) | Converted to `DATETIME`, which fixed `MIN` and `MAX` |
| 27 blank customer names | Kept: the keys are valid and the transactions are real |
| Cash payments with bank `None` | Kept: a cash payment has no bank |

## 5. Exploratory Data Analysis

| Measure | Result |
|---|---|
| Total revenue | 105,401,435.75 |
| Transactions | 1,000,000 |
| Average transaction | 105.40 (range 6 to 605) |
| Units sold | 6,000,185 |
| Monthly revenue | About 1.25M, within 1.12M to 1.35M |
| Revenue per day | About 41K, almost constant |
| Annual revenue (2015-2020) | About 15.03M a year, within 14.95M to 15.11M |

The Power BI dashboard adds the Year and Month slicers, month-over-month and year-over-year comparisons, and the visuals below.

## 6. Key Insights

| # | Insight | Evidence |
|---|---|---|
| 1 | **Revenue is flat, not growing** | About 15M a year from 2015 to 2020, a spread of roughly 1% |
| 2 | **No real seasonality** | Revenue per day stays within ±1.7% of average in every month; February is 8% below on monthly totals only because it has fewer days |
| 3 | **Price decides which products rank highest** | The top 10 products each sell 22,783 to 23,740 units, so the order follows unit price. Red Bull 12oz leads with 1.31M. The top 10 are 10.2% of revenue, and all seven K-Cups items are among them |
| 4 | **Every Customer Matters** | The top 10 customers make 0.16% of revenue. They buy more often (118 to 149 transactions against about 109 on average), not in bigger baskets |
| 5 | **Store count explains the regions** | Dhaka brings in 40.76M (38.7%) with 280 of 726 store keys. Revenue per store is about 145K in every division |
| 6 | **Card is the main payment method** | 89.7% of transactions (897,319) and 94.58M in value. Basket size is the same for every payment type |

## 7. Recommendations

| Insight | Recommended action |
|---|---|
| Flat revenue | Set a growth target and test ways to reach it: a price review, promotions, or new stores. Don't plan around organic growth |
| No seasonality | Set targets per day (about 41K), not per month, so February isn't flagged as a problem. Don't plan seasonal stock or staffing from this data |
| Price drives product rank | Review prices on top-ranking items first, and look for room to raise prices on the cheapest items. Bundle low-priced items with high-priced ones |
| Every customer is important | Focus on the whole customer base, with loyalty offers that raise transactions per customer |
| Store count drives regions | To add revenue, add stores. Divisions with few stores (Sylhet 38, Barisal 52) have room to grow at the same per-store return |
| Card dominance | Keep card payments reliable and negotiate processing fees |

## 8. Limitations

- The patterns are unusually uniform, so the data looks generated. The findings describe this dataset, not real consumer behavior, and the recommendations assume it reflects real sales.
- January 2014 and January 2021 are partial months, so their growth rates are not real.
- The `bags` unit for item `I00158` is an assumption.
- 726 store keys map to 556 distinct locations.
- Five item names are shared by two item keys, which can shift product rankings slightly.

## 9. Tools

MySQL, MySQL Workbench, Power BI Desktop, DAX.

## 10. Repository Contents

```
├── README.md
├── Data_Quality_Assessment_E-Commerce.sql
├── Data_Cleaning_E-Commerce.sql
├── EDA_E-Commerce.sql
├── powerbi/
│   └── E-Commerce_Visualization.pbix
└── images/
    └── dashboard.png
```

## 11. How to Reproduce

1. Load the six source tables into MySQL as `customer_dim`, `fact_table`, `item_dim`, `store_dim`, `time_dim` and `trans_dim`.
2. Run the three SQL scripts in the order above.
3. Open the `.pbix` file in Power BI Desktop (free, Windows).

---
**Author:** Jarrel Christian M. Pablo | [GitHub](https://github.com/jarrelpablo) | [LinkedIn] | [Portfolio]
