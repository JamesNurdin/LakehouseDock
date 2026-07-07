WITH store_sales_by_category AS (
    SELECT i.i_category_id AS category_id,
           i.i_category AS category,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_by_category AS (
    SELECT i.i_category_id AS category_id,
           i.i_category AS category,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_by_category AS (
    SELECT i.i_category_id AS category_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT COALESCE(ss.category_id, ws.category_id, r.category_id) AS category_id,
       COALESCE(ss.category, ws.category) AS category,
       COALESCE(ss.store_quantity, 0) AS total_store_quantity,
       COALESCE(ws.web_quantity, 0) AS total_web_quantity,
       COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
       r.avg_sentiment,
       r.review_count
FROM store_sales_by_category ss
FULL OUTER JOIN web_sales_by_category ws ON ss.category_id = ws.category_id
LEFT JOIN reviews_by_category r ON COALESCE(ss.category_id, ws.category_id) = r.category_id
ORDER BY total_quantity DESC
LIMIT 5
