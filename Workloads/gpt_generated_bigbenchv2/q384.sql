WITH item_sentiment AS (
    SELECT i.i_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT s.s_store_name,
       SUM(ss.ss_quantity) AS total_quantity_sold,
       COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
       SUM(ss.ss_quantity * COALESCE(it_sent.avg_sentiment, 0)) / NULLIF(SUM(ss.ss_quantity), 0) AS weighted_avg_sentiment
FROM store_sales ss
JOIN stores s ON ss.ss_store_id = s.s_store_id
JOIN customers c ON ss.ss_customer_id = c.c_customer_id
JOIN items i ON ss.ss_item_id = i.i_item_id
LEFT JOIN item_sentiment it_sent ON i.i_item_id = it_sent.item_id
GROUP BY s.s_store_name
ORDER BY total_quantity_sold DESC
LIMIT 5
