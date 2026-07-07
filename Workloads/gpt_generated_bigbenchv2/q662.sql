WITH combined_sales AS (
    SELECT ss.ss_quantity AS quantity,
           ss.ss_item_id AS item_id,
           ss.ss_store_id AS store_id,
           'store' AS channel,
           ss.ss_customer_id AS customer_id
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_quantity AS quantity,
           ws.ws_item_id AS item_id,
           CAST(NULL AS BIGINT) AS store_id,
           'web' AS channel,
           ws.ws_customer_id AS customer_id
    FROM web_sales ws
)
SELECT cs.channel,
       s.s_store_name,
       i.i_category,
       SUM(cs.quantity) AS total_quantity,
       SUM(cs.quantity * i.i_price) AS total_revenue
FROM combined_sales cs
JOIN items i ON cs.item_id = i.i_item_id
LEFT JOIN stores s ON cs.store_id = s.s_store_id
GROUP BY cs.channel,
         s.s_store_name,
         i.i_category
ORDER BY cs.channel,
         i.i_category,
         total_revenue DESC
