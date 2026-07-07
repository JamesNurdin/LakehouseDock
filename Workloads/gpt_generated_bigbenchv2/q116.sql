WITH combined_sales AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           'web' AS channel
    FROM web_sales ws
),
sales_agg AS (
    SELECT cs.item_id,
           SUM(cs.quantity) AS total_quantity,
           SUM(CASE WHEN cs.channel = 'store' THEN cs.quantity ELSE 0 END) AS store_quantity,
           SUM(CASE WHEN cs.channel = 'web' THEN cs.quantity ELSE 0 END) AS web_quantity
    FROM combined_sales cs
    GROUP BY cs.item_id
),
item_details AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category
    FROM items i
),
reviews_agg AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    id.i_item_id AS item_id,
    id.i_name AS item_name,
    id.i_category AS category,
    COALESCE(sa.total_quantity, 0) AS total_quantity,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(sa.web_quantity, 0) AS web_quantity,
    ra.avg_sentiment,
    ra.review_count
FROM item_details id
LEFT JOIN sales_agg sa ON id.i_item_id = sa.item_id
LEFT JOIN reviews_agg ra ON id.i_item_id = ra.i_item_id
ORDER BY total_quantity DESC
LIMIT 10
