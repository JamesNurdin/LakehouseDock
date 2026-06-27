WITH item_avg_rating AS (
    SELECT pr.pr_item_id AS i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_metrics AS (
    SELECT c.c_customer_id,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS store_spend,
           SUM(ss.ss_quantity * COALESCE(ir.avg_rating, 0)) AS store_rating_weighted,
           SUM(CASE WHEN ir.avg_rating IS NOT NULL THEN ss.ss_quantity ELSE 0 END) AS store_quantity_with_rating
    FROM customers c
    JOIN store_sales ss ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN item_avg_rating ir ON i.i_item_id = ir.i_item_id
    GROUP BY c.c_customer_id
),
web_metrics AS (
    SELECT c.c_customer_id,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS web_spend,
           SUM(ws.ws_quantity * COALESCE(ir.avg_rating, 0)) AS web_rating_weighted,
           SUM(CASE WHEN ir.avg_rating IS NOT NULL THEN ws.ws_quantity ELSE 0 END) AS web_quantity_with_rating
    FROM customers c
    JOIN web_sales ws ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    LEFT JOIN item_avg_rating ir ON i.i_item_id = ir.i_item_id
    GROUP BY c.c_customer_id
)
SELECT c.c_name,
       COALESCE(sm.store_quantity, 0) AS store_quantity,
       COALESCE(wm.web_quantity, 0) AS web_quantity,
       COALESCE(sm.store_quantity, 0) + COALESCE(wm.web_quantity, 0) AS total_quantity,
       COALESCE(sm.store_spend, 0) AS store_spend,
       COALESCE(wm.web_spend, 0) AS web_spend,
       COALESCE(sm.store_spend, 0) + COALESCE(wm.web_spend, 0) AS total_spend,
       CASE 
           WHEN (COALESCE(sm.store_quantity, 0) + COALESCE(wm.web_quantity, 0)) = 0 THEN NULL
           ELSE (COALESCE(sm.store_rating_weighted, 0) + COALESCE(wm.web_rating_weighted, 0))
                / (COALESCE(sm.store_quantity, 0) + COALESCE(wm.web_quantity, 0))
       END AS weighted_avg_rating
FROM customers c
LEFT JOIN store_metrics sm ON sm.c_customer_id = c.c_customer_id
LEFT JOIN web_metrics wm ON wm.c_customer_id = c.c_customer_id
ORDER BY total_spend DESC
LIMIT 10
