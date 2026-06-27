WITH item_avg_rating AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    s.s_store_name,
    i.i_category_name,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_quantity * COALESCE(ar.avg_rating, 0)) / NULLIF(SUM(ss.ss_quantity), 0) AS weighted_avg_rating
FROM store_sales ss
JOIN stores s ON ss.ss_store_id = s.s_store_id
JOIN items i ON ss.ss_item_id = i.i_item_id
LEFT JOIN item_avg_rating ar ON i.i_item_id = ar.i_item_id
GROUP BY s.s_store_name, i.i_category_name
ORDER BY total_quantity_sold DESC
LIMIT 20
