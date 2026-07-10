-- ============================================================
-- 03_rfm_segmentation.sql
-- RFM (Recency, Frequency, Monetary) customer segmentation in SQL
-- This mirrors the logic used in the Python RFM analysis (see
-- /retail_rfm_analysis) but implemented natively in SQL using
-- CTEs, window functions, and NTILE() for quartile scoring.
-- ============================================================

WITH reference_date AS (
    SELECT MAX(DATE(invoice_date)) AS max_date FROM transactions
),

customer_rfm_raw AS (
    SELECT
        t.customer_id,
        CAST(JULIANDAY((SELECT max_date FROM reference_date)) - JULIANDAY(MAX(DATE(t.invoice_date))) AS INTEGER) AS recency_days,
        COUNT(DISTINCT t.invoice_no) AS frequency,
        ROUND(SUM(t.quantity * t.unit_price), 2) AS monetary
    FROM transactions t
    WHERE t.invoice_no NOT LIKE 'C%'
      AND t.customer_id IS NOT NULL
    GROUP BY t.customer_id
),

-- Score each dimension into quartiles (1 = worst, 4 = best) using NTILE.
-- Recency is inverted: fewer days since last order = better = higher score.
rfm_scored AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        (5 - NTILE(4) OVER (ORDER BY recency_days ASC)) AS recency_score,
        NTILE(4) OVER (ORDER BY frequency ASC)            AS frequency_score,
        NTILE(4) OVER (ORDER BY monetary ASC)              AS monetary_score
    FROM customer_rfm_raw
),

rfm_final AS (
    SELECT
        *,
        (recency_score + frequency_score + monetary_score) AS rfm_total_score,
        CAST(recency_score AS TEXT) || CAST(frequency_score AS TEXT) || CAST(monetary_score AS TEXT) AS rfm_segment_code
    FROM rfm_scored
)

SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    recency_score,
    frequency_score,
    monetary_score,
    rfm_total_score,
    CASE
        WHEN recency_score >= 3 AND frequency_score >= 4 AND monetary_score >= 3 THEN 'Champions'
        WHEN recency_score >= 3 AND frequency_score >= 3                         THEN 'Loyal Customers'
        WHEN recency_score <= 2 AND frequency_score >= 3                         THEN 'At Risk'
        WHEN recency_score <= 2 AND frequency_score <= 2 AND monetary_score <= 2 THEN 'Lost'
        ELSE 'Regular'
    END AS customer_segment
FROM rfm_final
ORDER BY rfm_total_score DESC;


-- ------------------------------------------------------------
-- Summary: customer count and average monetary value per segment
-- (Run after the query above, or wrap the whole thing as a view)
-- ------------------------------------------------------------
WITH reference_date AS (
    SELECT MAX(DATE(invoice_date)) AS max_date FROM transactions
),
customer_rfm_raw AS (
    SELECT
        t.customer_id,
        CAST(JULIANDAY((SELECT max_date FROM reference_date)) - JULIANDAY(MAX(DATE(t.invoice_date))) AS INTEGER) AS recency_days,
        COUNT(DISTINCT t.invoice_no) AS frequency,
        ROUND(SUM(t.quantity * t.unit_price), 2) AS monetary
    FROM transactions t
    WHERE t.invoice_no NOT LIKE 'C%'
      AND t.customer_id IS NOT NULL
    GROUP BY t.customer_id
),
rfm_scored AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        (5 - NTILE(4) OVER (ORDER BY recency_days ASC)) AS recency_score,
        NTILE(4) OVER (ORDER BY frequency ASC)            AS frequency_score,
        NTILE(4) OVER (ORDER BY monetary ASC)              AS monetary_score
    FROM customer_rfm_raw
),
rfm_segmented AS (
    SELECT
        *,
        CASE
            WHEN recency_score >= 3 AND frequency_score >= 4 AND monetary_score >= 3 THEN 'Champions'
            WHEN recency_score >= 3 AND frequency_score >= 3                         THEN 'Loyal Customers'
            WHEN recency_score <= 2 AND frequency_score >= 3                         THEN 'At Risk'
            WHEN recency_score <= 2 AND frequency_score <= 2 AND monetary_score <= 2 THEN 'Lost'
            ELSE 'Regular'
        END AS customer_segment
    FROM rfm_scored
)
SELECT
    customer_segment,
    COUNT(*) AS num_customers,
    ROUND(AVG(recency_days), 1) AS avg_recency_days,
    ROUND(AVG(frequency), 1) AS avg_frequency,
    ROUND(AVG(monetary), 2) AS avg_monetary
FROM rfm_segmented
GROUP BY customer_segment
ORDER BY avg_monetary DESC;
