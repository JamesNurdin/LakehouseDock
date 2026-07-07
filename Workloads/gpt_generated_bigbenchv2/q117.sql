WITH item_sentiment AS (
    SELECT i.i_item_id AS item_id,
           AVG(CAST(pr.pr_sentiment AS double)) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
sales AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           ss.ss_store_id AS store_id
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           NULL AS store_id
    FROM web_sales ws
),
sales_agg AS (
    SELECT s.item_id,
           SUM(s.quantity) AS total_quantity
    FROM sales s
    GROUP BY s.item_id
)
SELECT i.i_category,
       i.i_category_id,
       SUM(sa.total_quantity) AS total_quantity_sold,
       AVG(its.avg_sentiment) AS avg_item_sentiment,
       SUM(its.review_count) AS total_reviews
FROM sales_agg sa
JOIN items i ON sa.item_id = i.i_item_id
LEFT JOIN item_sentiment its ON sa.item_id = its.item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
