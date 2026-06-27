WITH item_ratings AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    COUNT(DISTINCT ss.ss_transaction_id) AS num_transactions,
    COUNT(DISTINCT ss.ss_customer_id) AS num_customers,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_quantity * i.i_price) AS total_revenue,
    AVG(ir.avg_rating) AS avg_item_rating
FROM store_sales ss
JOIN items i ON ss.ss_item_id = i.i_item_id
JOIN stores s ON ss.ss_store_id = s.s_store_id
LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
WHERE i.i_price > 20
GROUP BY s.s_store_id, s.s_store_name
ORDER BY total_revenue DESC
LIMIT 10
