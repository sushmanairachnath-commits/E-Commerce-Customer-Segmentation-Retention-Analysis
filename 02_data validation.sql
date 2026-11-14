USE olist_ecommerce;

-- Query 1: Verify exact row counts across all 5 tables
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items;

-- Query 2: Inspect order status distribution (Crucial for filtering valid revenue)
SELECT 
    order_status,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Query 3: Check the date window and the customer_id vs. customer_unique_id quirk
SELECT 
    MIN(order_purchase_timestamp) AS first_order_date,
    MAX(order_purchase_timestamp) AS last_order_date,
    COUNT(DISTINCT c.customer_id) AS total_order_customer_ids,
    COUNT(DISTINCT c.customer_unique_id) AS actual_unique_humans
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id;

-- Query 4: Check for delivered orders missing payment records or having $0 spend
SELECT 
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(DISTINCT p.order_id) AS orders_with_payments,
    SUM(CASE WHEN p.payment_value <= 0 OR p.payment_value IS NULL THEN 1 ELSE 0 END) AS zero_or_null_payments
FROM orders o
LEFT JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered';
