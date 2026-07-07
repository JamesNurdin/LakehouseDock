WITH category_sentiment AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
store_category_sales AS (
    SELECT s.s_store_id,
           s.s_store_name,
           i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category
)
SELECT scs.s_store_name,
       scs.i_category,
       scs.total_quantity,
       cs.avg_sentiment
FROM store_category_sales scs
LEFT JOIN category_sentiment cs
    ON scs.i_category_id = cs.i_category_id
ORDER BY scs.total_quantity DESC
LIMIT 100
