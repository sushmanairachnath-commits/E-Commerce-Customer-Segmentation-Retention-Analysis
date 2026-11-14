USE olist_ecommerce;

CREATE TABLE IF NOT EXISTS category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/product_category_name_translation.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- Query 1: Top Revenue-Driving Product Categories for High-Value Segments
-- (Shows marketing WHICH categories to feature in win-back & onboarding campaigns)
SELECT 
    r.customer_segment,
    COALESCE(ct.product_category_name_english, p.product_category_name, 'Unknown') AS category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS category_revenue
FROM vw_customer_rfm r
JOIN customers c ON r.customer_unique_id = c.customer_unique_id
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation ct ON p.product_category_name = ct.product_category_name
WHERE o.order_status = 'delivered'
  AND r.customer_segment IN ('Big-Spending Newcomers', 'At Risk (High Spenders)', 'Champions')
GROUP BY r.customer_segment, category
ORDER BY r.customer_segment, category_revenue DESC;

-- Query 2: Delivery Delay Impact by Segment (Root-Cause Analysis for Churn)
-- (Tests whether late deliveries explain why high spenders fail to return)
SELECT 
    r.customer_segment,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_delivery_days,
    ROUND(SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS late_delivery_pct
FROM vw_customer_rfm r
JOIN customers c ON r.customer_unique_id = c.customer_unique_id
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY r.customer_segment
ORDER BY late_delivery_pct DESC;

-- Query 3: Geographic Revenue & Customer Concentration by State
-- (Powers your BI map visual and regional marketing budget allocation)
SELECT 
    customer_state,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN customer_segment IN ('Champions', 'Loyal Customers', 'Big-Spending Newcomers') THEN 1 ELSE 0 END) AS high_value_customers,
    ROUND(SUM(monetary), 2) AS total_revenue,
    ROUND(AVG(monetary), 2) AS avg_customer_ltv
FROM vw_customer_rfm
GROUP BY customer_state
ORDER BY total_revenue DESC
LIMIT 10;
