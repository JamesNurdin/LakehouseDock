WITH store_agg AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY c.c_customer_id, c.c_name, i.i_category_id, i.i_category_name
),
web_agg AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY c.c_customer_id, c.c_name, i.i_category_id, i.i_category_name
)
SELECT
    COALESCE(s.c_customer_id, w.c_customer_id) AS customer_id,
    COALESCE(s.c_name, w.c_name) AS customer_name,
    COALESCE(s.i_category_id, w.i_category_id) AS category_id,
    COALESCE(s.i_category_name, w.i_category_name) AS category_name,
    COALESCE(s.store_revenue, 0) AS store_revenue,
    COALESCE(s.store_quantity, 0) AS store_quantity,
    COALESCE(w.web_revenue, 0) AS web_revenue,
    COALESCE(w.web_quantity, 0) AS web_quantity,
    COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) AS total_revenue,
    COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.c_customer_id = w.c_customer_id
    AND s.i_category_id = w.i_category_id
ORDER BY total_revenue DESC
LIMIT 100
