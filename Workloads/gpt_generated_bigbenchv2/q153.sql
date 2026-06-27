WITH rating_per_item AS (
    SELECT i.i_item_id AS i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_agg AS (
    SELECT ss.ss_store_id AS ss_store_id,
           ss.ss_item_id AS ss_item_id,
           SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
web_sales_agg AS (
    SELECT ws.ws_item_id AS ws_item_id,
           SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
store_item_stats AS (
    SELECT ssagg.ss_store_id,
           ssagg.ss_item_id,
           ssagg.store_qty,
           COALESCE(wsagg.web_qty, 0) AS web_qty,
           rpi.avg_rating
    FROM store_sales_agg ssagg
    LEFT JOIN web_sales_agg wsagg
        ON ssagg.ss_item_id = wsagg.ws_item_id
    LEFT JOIN rating_per_item rpi
        ON ssagg.ss_item_id = rpi.i_item_id
)
SELECT s.s_store_id,
       s.s_store_name,
       SUM(sis.store_qty) AS total_store_quantity,
       SUM(sis.web_qty) AS total_web_quantity,
       AVG(sis.avg_rating) AS avg_item_rating
FROM store_item_stats sis
JOIN stores s
    ON sis.ss_store_id = s.s_store_id
GROUP BY s.s_store_id, s.s_store_name
ORDER BY total_store_quantity DESC
LIMIT 10
