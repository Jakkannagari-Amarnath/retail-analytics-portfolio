-- ============================================================
-- 01_revenue_analysis.sql
-- Basic revenue and sales trend queries
-- ============================================================

-- Q1: Total revenue, excluding cancelled orders (invoice numbers starting with 'C')
SELECT
    ROUND(SUM(quantity * unit_price), 2) AS total_revenue
FROM transactions
WHERE invoice_no NOT LIKE 'C%';


-- Q2: Monthly revenue trend
SELECT
    strftime('%Y-%m', invoice_date) AS year_month,
    ROUND(SUM(quantity * unit_price), 2) AS monthly_revenue,
    COUNT(DISTINCT invoice_no) AS num_orders
FROM transactions
WHERE invoice_no NOT LIKE 'C%'
GROUP BY year_month
ORDER BY year_month;


-- Q3: Top 10 products by total revenue
SELECT
    stock_code,
    description,
    ROUND(SUM(quantity * unit_price), 2) AS product_revenue,
    SUM(quantity) AS units_sold
FROM transactions
WHERE invoice_no NOT LIKE 'C%'
GROUP BY stock_code, description
ORDER BY product_revenue DESC
LIMIT 10;


-- Q4: Revenue by country, with percentage share of total revenue
SELECT
    country,
    ROUND(SUM(quantity * unit_price), 2) AS country_revenue,
    ROUND(
        100.0 * SUM(quantity * unit_price)
        / (SELECT SUM(quantity * unit_price) FROM transactions WHERE invoice_no NOT LIKE 'C%'),
        2
    ) AS pct_of_total_revenue
FROM transactions
WHERE invoice_no NOT LIKE 'C%'
GROUP BY country
ORDER BY country_revenue DESC;


-- Q5: Average order value (AOV) overall and by country
SELECT
    country,
    ROUND(AVG(order_value), 2) AS avg_order_value
FROM (
    SELECT
        invoice_no,
        country,
        SUM(quantity * unit_price) AS order_value
    FROM transactions
    WHERE invoice_no NOT LIKE 'C%'
    GROUP BY invoice_no, country
) AS order_totals
GROUP BY country
ORDER BY avg_order_value DESC;


-- Q6: Cancellation rate (share of invoices that were cancelled)
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN invoice_no LIKE 'C%' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS cancellation_rate_pct
FROM (
    SELECT DISTINCT invoice_no FROM transactions
);
