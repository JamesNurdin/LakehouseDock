WITH store_agg AS (
    SELECT i.i_category AS category,
           SUM(ss.ss_quantity) AS total_store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_agg AS (
    SELECT i.i_category AS category,
           SUM(ws.ws_quantity) AS total_web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT COALESCE(s.category, w.category) AS category,
       COALESCE(s.total_store_quantity, 0) AS store_quantity,
       COALESCE(s.total_store_revenue, 0) AS store_revenue,
       COALESCE(w.total_web_quantity, 0) AS web_quantity,
       COALESCE(w.total_web_revenue, 0) AS web_revenue,
       COALESCE(s.total_store_quantity, 0) + COALESCE(w.total_web_quantity, 0) AS total_quantity,
       COALESCE(s.total_store_revenue, 0) + COALESCE(w.total_web_revenue, 0) AS total_revenue
FROM store_agg s
FULL OUTER JOIN web_agg w ON s.category = w.category
ORDER BY total_revenue DESC
