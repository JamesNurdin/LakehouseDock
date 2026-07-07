WITH item_sentiment AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY pr.pr_item_id
)
SELECT
    s.s_store_name,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    AVG(isent.avg_sentiment) AS avg_item_sentiment
FROM store_sales ss
JOIN stores s ON ss.ss_store_id = s.s_store_id
JOIN items i ON ss.ss_item_id = i.i_item_id
LEFT JOIN item_sentiment isent ON i.i_item_id = isent.i_item_id
GROUP BY s.s_store_name
ORDER BY total_quantity_sold DESC
LIMIT 10
