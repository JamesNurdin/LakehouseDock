WITH store_customer_sales AS (
    SELECT ss.ss_customer_id,
           SUM(ss.ss_quantity) AS store_quantity,
           COUNT(DISTINCT ss.ss_item_id) AS distinct_store_items,
           COUNT(DISTINCT ss.ss_store_id) AS distinct_stores
    FROM store_sales ss
    GROUP BY ss.ss_customer_id
),
web_customer_sales AS (
    SELECT ws.ws_customer_id,
           SUM(ws.ws_quantity) AS web_quantity,
           COUNT(DISTINCT ws.ws_item_id) AS distinct_web_items
    FROM web_sales ws
    GROUP BY ws.ws_customer_id
),
customer_reviews AS (
    SELECT c.c_customer_id,
           AVG(pr.pr_rating) AS avg_review_rating,
           COUNT(pr.pr_review_id) AS review_count
    FROM customers c
    JOIN store_sales ss ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY c.c_customer_id
)
SELECT c.c_customer_id,
       c.c_name,
       COALESCE(scs.store_quantity, 0) AS store_quantity,
       COALESCE(wcs.web_quantity, 0) AS web_quantity,
       (COALESCE(scs.store_quantity, 0) + COALESCE(wcs.web_quantity, 0)) AS total_quantity,
       COALESCE(scs.distinct_store_items, 0) + COALESCE(wcs.distinct_web_items, 0) AS total_distinct_items,
       COALESCE(scs.distinct_stores, 0) AS distinct_stores,
       COALESCE(cr.avg_review_rating, 0) AS avg_review_rating,
       COALESCE(cr.review_count, 0) AS review_count
FROM customers c
LEFT JOIN store_customer_sales scs ON scs.ss_customer_id = c.c_customer_id
LEFT JOIN web_customer_sales wcs ON wcs.ws_customer_id = c.c_customer_id
LEFT JOIN customer_reviews cr ON cr.c_customer_id = c.c_customer_id
ORDER BY total_quantity DESC
LIMIT 20
