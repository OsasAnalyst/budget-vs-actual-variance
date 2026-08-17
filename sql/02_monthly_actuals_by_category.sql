
-- Only 'delivered' orders counted as actuals: 'shipped' confirms dispatch only,

CREATE TABLE monthly_actuals_by_category AS 
SELECT 
	DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    COALESCE(t.product_category_name_english, p.product_category_name, 'uncategorized') AS category,
    SUM(oi.price) AS revenue,
    COUNT(*) AS units,
    SUM(oi.price) / COUNT(*) AS avg_price
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
LEFT JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
WHERE o.order_status IN ("delivered")
GROUP BY month, category
ORDER BY month, category;
