WITH store_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT c.i_category_id,
       c.i_category,
       COALESCE(ssa.total_store_quantity, 0) AS total_store_quantity,
       COALESCE(wsa.total_web_quantity, 0) AS total_web_quantity,
       ra.avg_sentiment,
       COALESCE(ra.review_count, 0) AS review_count
FROM (
    SELECT DISTINCT i_category_id, i_category
    FROM items
) c
LEFT JOIN store_sales_agg ssa
    ON c.i_category_id = ssa.i_category_id
    AND c.i_category = ssa.i_category
LEFT JOIN web_sales_agg wsa
    ON c.i_category_id = wsa.i_category_id
    AND c.i_category = wsa.i_category
LEFT JOIN reviews_agg ra
    ON c.i_category_id = ra.i_category_id
    AND c.i_category = ra.i_category
ORDER BY c.i_category_id
