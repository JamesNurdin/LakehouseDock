WITH item_avg_rating AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
customer_store_sales AS (
    SELECT c.c_customer_id,
           SUM(ss.ss_quantity * i.i_price) AS total_store_revenue,
           SUM(ss.ss_quantity) AS total_store_quantity,
           COUNT(DISTINCT ss.ss_item_id) AS distinct_store_items
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY c.c_customer_id
),
customer_web_sales AS (
    SELECT c.c_customer_id,
           SUM(ws.ws_quantity * i.i_price) AS total_web_revenue,
           SUM(ws.ws_quantity) AS total_web_quantity,
           COUNT(DISTINCT ws.ws_item_id) AS distinct_web_items
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY c.c_customer_id
),
customer_item_ratings AS (
    SELECT purchases.c_customer_id,
           AVG(ir.avg_rating) AS avg_item_rating
    FROM (
        SELECT ss.ss_customer_id AS c_customer_id,
               ss.ss_item_id AS i_item_id
        FROM store_sales ss
        UNION ALL
        SELECT ws.ws_customer_id AS c_customer_id,
               ws.ws_item_id AS i_item_id
        FROM web_sales ws
    ) purchases
    JOIN item_avg_rating ir ON purchases.i_item_id = ir.i_item_id
    GROUP BY purchases.c_customer_id
)
SELECT c.c_customer_id,
       c.c_name,
       cs.total_store_quantity,
       cs.total_store_revenue,
       cw.total_web_quantity,
       cw.total_web_revenue,
       ci.avg_item_rating
FROM customers c
LEFT JOIN customer_store_sales cs ON c.c_customer_id = cs.c_customer_id
LEFT JOIN customer_web_sales cw ON c.c_customer_id = cw.c_customer_id
LEFT JOIN customer_item_ratings ci ON c.c_customer_id = ci.c_customer_id
ORDER BY cs.total_store_revenue DESC NULLS LAST
LIMIT 100
