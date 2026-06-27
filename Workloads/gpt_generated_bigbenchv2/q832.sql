WITH
    item_ratings AS (
        SELECT i.i_item_id,
               AVG(pr.pr_rating) AS avg_rating,
               COUNT(*) AS review_count
        FROM items i
        JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_item_id
    ),
    customer_store_sales AS (
        SELECT ss.ss_customer_id,
               SUM(ss.ss_quantity) AS store_quantity,
               SUM(ss.ss_quantity * i.i_price) AS store_revenue,
               COUNT(DISTINCT ss.ss_item_id) AS distinct_items_store
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_customer_id
    ),
    customer_web_sales AS (
        SELECT ws.ws_customer_id,
               SUM(ws.ws_quantity) AS web_quantity,
               SUM(ws.ws_quantity * i.i_price) AS web_revenue,
               COUNT(DISTINCT ws.ws_item_id) AS distinct_items_web
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY ws.ws_customer_id
    ),
    customer_item_ratings AS (
        SELECT cs.ss_customer_id AS c_id,
               AVG(ir.avg_rating) AS avg_item_rating
        FROM store_sales cs
        JOIN item_ratings ir ON cs.ss_item_id = ir.i_item_id
        GROUP BY cs.ss_customer_id
        UNION ALL
        SELECT cw.ws_customer_id AS c_id,
               AVG(ir.avg_rating) AS avg_item_rating
        FROM web_sales cw
        JOIN item_ratings ir ON cw.ws_item_id = ir.i_item_id
        GROUP BY cw.ws_customer_id
    ),
    customer_avg_rating AS (
        SELECT c_id,
               AVG(avg_item_rating) AS avg_item_rating
        FROM customer_item_ratings
        GROUP BY c_id
    )
SELECT c.c_customer_id,
       c.c_name,
       COALESCE(cs.store_quantity, 0) AS total_store_quantity,
       COALESCE(cs.store_revenue, 0) AS total_store_revenue,
       COALESCE(ws.web_quantity, 0) AS total_web_quantity,
       COALESCE(ws.web_revenue, 0) AS total_web_revenue,
       COALESCE(ar.avg_item_rating, 0) AS avg_item_rating
FROM customers c
LEFT JOIN customer_store_sales cs ON cs.ss_customer_id = c.c_customer_id
LEFT JOIN customer_web_sales ws ON ws.ws_customer_id = c.c_customer_id
LEFT JOIN customer_avg_rating ar ON ar.c_id = c.c_customer_id
ORDER BY total_store_revenue DESC
LIMIT 100
