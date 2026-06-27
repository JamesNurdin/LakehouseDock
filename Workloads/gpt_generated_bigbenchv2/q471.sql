WITH store_category_sales AS (
    SELECT ss.ss_store_id AS store_id,
           i.i_category_id AS category_id,
           i.i_category_name AS category_name,
           SUM(ss.ss_quantity) AS store_qty,
           SUM(ss.ss_quantity * i.i_price) AS store_sales_amount
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
),
web_category_sales AS (
    SELECT i.i_category_id AS category_id,
           i.i_category_name AS category_name,
           SUM(ws.ws_quantity) AS web_qty,
           SUM(ws.ws_quantity * i.i_price) AS web_sales_amount
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
category_ratings AS (
    SELECT i.i_category_id AS category_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT s.s_store_id,
       s.s_store_name,
       sc.category_id,
       sc.category_name,
       sc.store_qty,
       sc.store_sales_amount,
       wc.web_qty,
       wc.web_sales_amount,
       cr.avg_rating
FROM store_category_sales sc
JOIN stores s ON sc.store_id = s.s_store_id
LEFT JOIN web_category_sales wc ON sc.category_id = wc.category_id
LEFT JOIN category_ratings cr ON sc.category_id = cr.category_id
ORDER BY sc.store_sales_amount DESC
LIMIT 50
