WITH store_agg AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue,
        SUM(ss.ss_quantity * i.i_comp_price) AS store_comp_revenue
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
),
web_agg AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        SUM(ws.ws_quantity * i.i_comp_price) AS web_comp_revenue
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
)
SELECT
    COALESCE(s.i_item_id, w.i_item_id) AS item_id,
    COALESCE(s.i_category_id, w.i_category_id) AS category_id,
    COALESCE(s.i_category_name, w.i_category_name) AS category_name,
    COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
    COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0) AS total_revenue,
    COALESCE(s.store_comp_revenue, 0) + COALESCE(w.web_comp_revenue, 0) AS total_comp_revenue,
    (COALESCE(s.store_revenue, 0) + COALESCE(w.web_revenue, 0)) -
    (COALESCE(s.store_comp_revenue, 0) + COALESCE(w.web_comp_revenue, 0)) AS revenue_vs_comp_diff
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.i_item_id = w.i_item_id
ORDER BY total_revenue DESC
LIMIT 20
