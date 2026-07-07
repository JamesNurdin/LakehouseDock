WITH item_sentiment AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT s.s_store_name AS store_name,
       i.i_category AS category,
       SUM(ss.ss_quantity) AS total_quantity,
       AVG(isent.avg_sentiment) AS avg_sentiment
FROM store_sales ss
JOIN items i ON ss.ss_item_id = i.i_item_id
JOIN stores s ON ss.ss_store_id = s.s_store_id
LEFT JOIN item_sentiment isent ON i.i_item_id = isent.i_item_id
GROUP BY s.s_store_name, i.i_category
ORDER BY s.s_store_name, i.i_category
