WITH unified_sales AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           i.i_price AS price,
           'store' AS channel
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           i.i_price AS price,
           'web' AS channel
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_by_item AS (
    SELECT us.item_id,
           SUM(CASE WHEN us.channel = 'store' THEN us.quantity ELSE 0 END) AS store_quantity,
           SUM(CASE WHEN us.channel = 'web' THEN us.quantity ELSE 0 END) AS web_quantity,
           SUM(us.quantity) AS total_quantity,
           SUM(us.quantity * us.price) AS total_sales_amount
    FROM unified_sales us
    GROUP BY us.item_id
),
review_by_item AS (
    SELECT pr.pr_item_id AS item_id,
           COUNT(pr.pr_review_id) AS review_count,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_category_id,
       i.i_category,
       SUM(COALESCE(s.store_quantity, 0)) AS total_store_quantity,
       SUM(COALESCE(s.web_quantity, 0)) AS total_web_quantity,
       SUM(COALESCE(s.total_quantity, 0)) AS total_quantity,
       SUM(COALESCE(s.total_sales_amount, 0)) AS total_sales_amount,
       SUM(COALESCE(r.review_count, 0)) AS total_review_count,
       AVG(r.avg_sentiment) AS avg_review_sentiment
FROM items i
LEFT JOIN sales_by_item s ON i.i_item_id = s.item_id
LEFT JOIN review_by_item r ON i.i_item_id = r.item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_sales_amount DESC
LIMIT 10
