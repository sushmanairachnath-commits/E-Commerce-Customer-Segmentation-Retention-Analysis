USE olist_ecommerce;

CREATE OR REPLACE VIEW vw_customer_rfm AS
WITH 
-- 1. Pre-aggregate payments per order to prevent row duplication when joining
order_totals AS (
    SELECT 
        order_id,
        SUM(payment_value) AS total_order_value
    FROM order_payments
    GROUP BY order_id
),

-- 2. Join customers, delivered orders, and order totals at the unique human level
customer_metrics AS (
    SELECT 
        c.customer_unique_id,
        MAX(c.customer_state) AS customer_state,
        MAX(c.customer_city) AS customer_city,
        -- Recency: Days since last purchase relative to 1 day after dataset max date (2018-10-18)
        DATEDIFF('2018-10-18', MAX(o.order_purchase_timestamp)) AS recency_days,
        -- Frequency: Total count of distinct delivered orders
        COUNT(DISTINCT o.order_id) AS frequency,
        -- Monetary: Total valid spend across all delivered orders
        ROUND(SUM(ot.total_order_value), 2) AS monetary
    FROM customers c
    JOIN orders o 
        ON c.customer_id = o.customer_id
    JOIN order_totals ot 
        ON o.order_id = ot.order_id
    WHERE o.order_status = 'delivered'
      AND ot.total_order_value > 0
    GROUP BY c.customer_unique_id
),

-- 3. Calculate R, F, M scores (1 = worst, 5 = best)
rfm_scores AS (
    SELECT 
        customer_unique_id,
        customer_state,
        customer_city,
        recency_days,
        frequency,
        monetary,
        -- Lower recency_days means more recent, so ORDER BY DESC gives recent buyers a 5
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        -- Explicit business tiers for Frequency to avoid NTILE distortion on 1-time buyers
        CASE 
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 3
            WHEN frequency = 3 THEN 4
            ELSE 5 
        END AS f_score,
        -- Higher spend gets a higher score (1 to 5)
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM customer_metrics
)

-- 4. Map R, F, M scores into actionable business segments
SELECT 
    customer_unique_id,
    customer_state,
    customer_city,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_cell,
    CASE 
        WHEN r_score >= 4 AND f_score >= 3 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score = 1 AND m_score >= 4 THEN 'Big-Spending Newcomers'
        WHEN r_score >= 4 AND f_score = 1 THEN 'Recent One-Time Buyers'
        WHEN r_score = 3 AND f_score = 1 THEN 'Promising / Needs Nurturing'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk (Repeat Buyers)'
        WHEN r_score <= 2 AND m_score >= 4 THEN 'At Risk (High Spenders)'
        ELSE 'Hibernating / Lost'
    END AS customer_segment
FROM rfm_scores;

SELECT 
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_customers,
    ROUND(AVG(recency_days), 0) AS avg_recency_days,
    ROUND(AVG(frequency), 2) AS avg_frequency,
    ROUND(AVG(monetary), 2) AS avg_spend,
    ROUND(SUM(monetary), 2) AS total_revenue,
    ROUND(SUM(monetary) * 100.0 / SUM(SUM(monetary)) OVER(), 2) AS pct_revenue
FROM vw_customer_rfm
GROUP BY customer_segment
ORDER BY total_revenue DESC;
