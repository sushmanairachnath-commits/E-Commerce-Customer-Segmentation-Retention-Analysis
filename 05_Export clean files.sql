SELECT * FROM vw_customer_rfm;

USE olist_ecommerce;

SELECT 
    r.customer_segment,
    COALESCE(p.product_category_name, 'Unknown') AS category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS category_revenue
FROM vw_customer_rfm r
JOIN customers c ON r.customer_unique_id = c.customer_unique_id
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY r.customer_segment, category
ORDER BY r.customer_segment, category_revenue DESC;

USE olist_ecommerce;

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
