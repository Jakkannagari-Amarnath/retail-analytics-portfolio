-- ============================================================
-- 02_customer_behavior.sql
-- Customer-level behavior analysis: CTEs, window functions, joins
-- ============================================================

-- Q1: Customer lifetime value (CLV) — total spend per customer, ranked
WITH customer_spend AS (
    SELECT
        customer_id,
        country,
        ROUND(SUM(quantity * unit_price), 2) AS total_spend,
        COUNT(DISTINCT invoice_no) AS num_orders
    FROM transactions
    WHERE invoice_no NOT LIKE 'C%'
      AND customer_id IS NOT NULL
    GROUP BY customer_id, country
)
SELECT
    customer_id,
    country,
    total_spend,
    num_orders,
    ROUND(total_spend / num_orders, 2) AS avg_order_value,
    RANK() OVER (ORDER BY total_spend DESC) AS spend_rank
FROM customer_spend
ORDER BY spend_rank
LIMIT 20;


-- Q2: New vs. returning customers per month
-- A customer's "first order month" identifies them as new in that month
WITH first_orders AS (
    SELECT
        customer_id,
        MIN(strftime('%Y-%m', invoice_date)) AS first_order_month
    FROM transactions
    WHERE invoice_no NOT LIKE 'C%'
      AND customer_id IS NOT NULL
    GROUP BY customer_id
),
monthly_activity AS (
    SELECT DISTINCT
        customer_id,
        strftime('%Y-%m', invoice_date) AS activity_month
    FROM transactions
    WHERE invoice_no NOT LIKE 'C%'
      AND customer_id IS NOT NULL
)
SELECT
    ma.activity_month,
    SUM(CASE WHEN ma.activity_month = fo.first_order_month THEN 1 ELSE 0 END) AS new_customers,
    SUM(CASE WHEN ma.activity_month != fo.first_order_month THEN 1 ELSE 0 END) AS returning_customers
FROM monthly_activity ma
JOIN first_orders fo ON ma.customer_id = fo.customer_id
GROUP BY ma.activity_month
ORDER BY ma.activity_month;


-- Q3: Days between a customer's consecutive orders (using window functions)
WITH order_dates AS (
    SELECT DISTINCT
        customer_id,
        invoice_no,
        DATE(invoice_date) AS order_date
    FROM transactions
    WHERE invoice_no NOT LIKE 'C%'
      AND customer_id IS NOT NULL
)
SELECT
    customer_id,
    order_date,
    LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date,
    JULIANDAY(order_date) - JULIANDAY(
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)
    ) AS days_since_last_order
FROM order_dates
ORDER BY customer_id, order_date
LIMIT 30;


-- Q4: Customers who have not ordered in the last 180 days ("at risk" / churn candidates)
-- Reference date fixed to the dataset's last observed date for reproducibility
WITH last_order AS (
    SELECT
        customer_id,
        MAX(DATE(invoice_date)) AS last_order_date
    FROM transactions
    WHERE invoice_no NOT LIKE 'C%'
      AND customer_id IS NOT NULL
    GROUP BY customer_id
),
reference_date AS (
    SELECT MAX(DATE(invoice_date)) AS max_date FROM transactions
)
SELECT
    lo.customer_id,
    lo.last_order_date,
    CAST(JULIANDAY(rd.max_date) - JULIANDAY(lo.last_order_date) AS INTEGER) AS days_since_last_order
FROM last_order lo
CROSS JOIN reference_date rd
WHERE JULIANDAY(rd.max_date) - JULIANDAY(lo.last_order_date) > 180
ORDER BY days_since_last_order DESC
LIMIT 20;


-- Q5: Top product per country (using window function to rank within each group)
WITH country_product_sales AS (
    SELECT
        country,
        stock_code,
        description,
        SUM(quantity * unit_price) AS revenue,
        ROW_NUMBER() OVER (
            PARTITION BY country
            ORDER BY SUM(quantity * unit_price) DESC
        ) AS rn
    FROM transactions
    WHERE invoice_no NOT LIKE 'C%'
    GROUP BY country, stock_code, description
)
SELECT
    country,
    stock_code,
    description,
    ROUND(revenue, 2) AS revenue
FROM country_product_sales
WHERE rn = 1
ORDER BY revenue DESC;
