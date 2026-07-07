WITH combined_sales AS (
    SELECT i_item_id,
           SUM(ss_quantity) AS store_quantity,
           SUM(ws_quantity) AS web_quantity
    FROM (
        SELECT ss_item_id AS i_item_id,
               ss_quantity,
               0 AS ws_quantity
        FROM store_sales
        UNION ALL
        SELECT ws_item_id AS i_item_id,
               0 AS ss_quantity,
               ws_quantity
        FROM web_sales
    ) AS sq
    GROUP BY i_item_id
), item_reviews AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(pr_review_id) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       COALESCE(cs.store_quantity, 0) AS store_quantity,
       COALESCE(cs.web_quantity, 0) AS web_quantity,
       COALESCE(ir.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(ir.review_count, 0) AS review_count,
       (COALESCE(cs.store_quantity, 0) + COALESCE(cs.web_quantity, 0)) AS total_quantity
FROM items i
LEFT JOIN combined_sales cs ON cs.i_item_id = i.i_item_id
LEFT JOIN item_reviews ir ON ir.pr_item_id = i.i_item_id
ORDER BY total_quantity DESC
LIMIT 10
