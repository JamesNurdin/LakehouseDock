WITH item_avg_sentiment AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    s.s_store_name,
    i.i_category,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    AVG(ias.avg_sentiment) AS avg_item_sentiment
FROM store_sales ss
JOIN stores s ON ss.ss_store_id = s.s_store_id
JOIN items i ON ss.ss_item_id = i.i_item_id
LEFT JOIN item_avg_sentiment ias ON ias.i_item_id = i.i_item_id
GROUP BY s.s_store_name, i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 100
