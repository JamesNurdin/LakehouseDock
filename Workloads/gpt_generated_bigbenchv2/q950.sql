WITH category_sales AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
category_web_sales AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
category_reviews AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
category_items AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(i.i_price) AS avg_price,
           COUNT(*) AS item_count
    FROM items i
    GROUP BY i.i_category_id, i.i_category
)
SELECT ci.i_category_id,
       ci.i_category,
       ci.item_count,
       ci.avg_price,
       COALESCE(cs.store_quantity, 0) + COALESCE(cws.web_quantity, 0) AS total_quantity,
       COALESCE(cs.store_revenue, 0) + COALESCE(cws.web_revenue, 0) AS total_revenue,
       cr.avg_sentiment,
       cr.review_count
FROM category_items ci
LEFT JOIN category_sales cs ON ci.i_category_id = cs.i_category_id
LEFT JOIN category_web_sales cws ON ci.i_category_id = cws.i_category_id
LEFT JOIN category_reviews cr ON ci.i_category_id = cr.i_category_id
ORDER BY total_quantity DESC
LIMIT 20
