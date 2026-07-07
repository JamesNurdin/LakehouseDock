WITH combined_sales AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity
    FROM web_sales ws
),
category_sales AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(cs.quantity) AS total_quantity
    FROM combined_sales cs
    JOIN items i ON cs.item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
category_reviews AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT cs.i_category_id,
       cs.i_category,
       cs.total_quantity,
       cr.avg_sentiment,
       cr.review_count
FROM category_sales cs
JOIN category_reviews cr ON cs.i_category_id = cr.i_category_id
ORDER BY cs.total_quantity DESC
LIMIT 10
