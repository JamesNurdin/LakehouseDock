WITH item_ratings AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_agg AS (
    SELECT ss.ss_customer_id,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS store_spent,
           SUM(ss.ss_quantity * COALESCE(ir.avg_rating, 0)) AS store_rating_weighted
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
    GROUP BY ss.ss_customer_id
),
web_sales_agg AS (
    SELECT ws.ws_customer_id,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS web_spent,
           SUM(ws.ws_quantity * COALESCE(ir.avg_rating, 0)) AS web_rating_weighted
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    LEFT JOIN item_ratings ir ON i.i_item_id = ir.i_item_id
    GROUP BY ws.ws_customer_id
)
SELECT c.c_customer_id,
       c.c_name,
       COALESCE(ss.store_quantity, 0) AS store_quantity,
       COALESCE(ws.web_quantity, 0) AS web_quantity,
       COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity,
       COALESCE(ss.store_spent, 0) AS store_spent,
       COALESCE(ws.web_spent, 0) AS web_spent,
       COALESCE(ss.store_spent, 0) + COALESCE(ws.web_spent, 0) AS total_spent,
       CASE
           WHEN COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) > 0
           THEN (COALESCE(ss.store_rating_weighted, 0) + COALESCE(ws.web_rating_weighted, 0)) /
                (COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0))
           ELSE NULL
       END AS avg_item_rating
FROM customers c
LEFT JOIN store_sales_agg ss ON ss.ss_customer_id = c.c_customer_id
LEFT JOIN web_sales_agg ws ON ws.ws_customer_id = c.c_customer_id
ORDER BY total_spent DESC
LIMIT 10
