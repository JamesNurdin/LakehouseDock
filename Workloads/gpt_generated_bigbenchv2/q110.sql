WITH store_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           'store' AS channel,
           SUM(ss.ss_quantity) AS total_quantity,
           SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           'web' AS channel,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_quantity * i.i_price) AS total_revenue
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT i_category_id,
       i_category,
       channel,
       total_quantity,
       total_revenue
FROM store_agg
UNION ALL
SELECT i_category_id,
       i_category,
       channel,
       total_quantity,
       total_revenue
FROM web_agg
ORDER BY i_category_id, channel
