WITH item_avg_rating AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM items i
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_category_sales AS (
    SELECT s.s_store_id,
           s.s_store_name,
           i.i_category_id,
           i.i_category_name,
           SUM(ss.ss_quantity) AS store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS store_revenue,
           COUNT(DISTINCT c.c_customer_id) AS store_distinct_customers,
           AVG(COALESCE(ir.avg_rating, 0)) AS store_avg_item_rating
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    LEFT JOIN item_avg_rating ir ON i.i_item_id = ir.i_item_id
    GROUP BY s.s_store_id,
             s.s_store_name,
             i.i_category_id,
             i.i_category_name
),
web_category_sales AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(ws.ws_quantity) AS web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS web_revenue,
           COUNT(DISTINCT c.c_customer_id) AS web_distinct_customers,
           AVG(COALESCE(ir.avg_rating, 0)) AS web_avg_item_rating
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    LEFT JOIN item_avg_rating ir ON i.i_item_id = ir.i_item_id
    GROUP BY i.i_category_id,
             i.i_category_name
)
SELECT scs.s_store_id,
       scs.s_store_name,
       scs.i_category_id,
       scs.i_category_name,
       scs.store_quantity,
       scs.store_revenue,
       scs.store_distinct_customers,
       scs.store_avg_item_rating,
       wcs.web_quantity,
       wcs.web_revenue,
       wcs.web_distinct_customers,
       wcs.web_avg_item_rating
FROM store_category_sales scs
JOIN web_category_sales wcs
  ON scs.i_category_id = wcs.i_category_id
  AND scs.i_category_name = wcs.i_category_name
ORDER BY scs.store_revenue DESC
LIMIT 20
