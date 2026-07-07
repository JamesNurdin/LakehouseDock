WITH unified_sales AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_store_id AS store_id,
           ss.ss_quantity AS quantity,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           NULL AS store_id,
           ws.ws_quantity AS quantity,
           'web' AS channel
    FROM web_sales ws
)
SELECT COALESCE(st.s_store_name, 'Web') AS sales_location,
       i.i_category AS category,
       SUM(us.quantity) AS total_quantity,
       SUM(us.quantity * i.i_price) AS total_revenue
FROM unified_sales us
JOIN items i ON us.item_id = i.i_item_id
LEFT JOIN stores st ON us.store_id = st.s_store_id
GROUP BY COALESCE(st.s_store_name, 'Web'), i.i_category
ORDER BY i.i_category, sales_location
