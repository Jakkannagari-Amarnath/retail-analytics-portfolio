# Retail Sales Analytics Portfolio

End-to-end analysis of 2 years of online retail transaction data (500K+ records).

## Contents
- **Power BI Dashboard**: KPIs, sales trends, top products, geographic distribution
- **Python (RFM Analysis)**: Customer segmentation using Recency, Frequency, Monetary scoring
- **SQL**: Revenue analysis, customer behavior queries, and RFM segmentation — see 'sql_analysis'

## Tools
Power BI, Python (pandas, matplotlib), SQL

## Key Insights
- Segmented 5,881 customers into Champions, Regular, At Risk and Lost categories
- Identified top revenue-generating products and sales trends across 2009-2011
- UK dominates sales geography with strong European presence

## SQL Analysis

'sql_analysis' — SQL queries analysing the same retail transaction dataset used in the Python RFM analysis, written and tested in SQLite (standard ANSI SQL, portable to PostgreSQL/MySQL/SQL Server).

**`01_revenue_analysis.sql' — Total revenue, monthly trends, top products, revenue by country, average order value, cancellation rate

 **`02_customer_behavior.sql'** — Customer lifetime value ranking, new vs. returning customers by month, days-between-orders (window functions), churn candidates, top product per country
  
 **`03_rfm_segmentation.sql'* — Full RFM (Recency, Frequency, Monetary) customer segmentation using 'NTILE()'window functions, replicating the same segmentation logic as the Python analysis, entirely in SQL

Includes a sample dataset (`online_retail_sample.csv, 25,000+ transactions) and the generator script used to build it, so every query can be run and verified independently.

**Skills demonstrated:** CTEs, window functions (`RANK()`, `ROW_NUMBER()`, `NTILE()`, `LAG()`), subqueries, joins, aggregate functions.
