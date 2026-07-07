WITH store_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category_id, i.i_category
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS web_qty,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    COALESCE(s.i_category_id, w.i_category_id) AS category_id,
    COALESCE(s.i_category, w.i_category) AS category_name,
    COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) AS total_quantity,
    COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) AS total_revenue
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.i_category_id = w.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
