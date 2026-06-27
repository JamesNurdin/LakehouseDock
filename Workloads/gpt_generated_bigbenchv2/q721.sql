WITH
store_agg AS (
    SELECT
        s.s_store_name,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY s.s_store_name, i.i_category_name
),
web_agg AS (
    SELECT
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_qty,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_name
)
SELECT
    sa.s_store_name,
    sa.i_category_name,
    sa.store_qty,
    sa.store_revenue,
    COALESCE(wa.web_qty, 0) AS web_qty,
    COALESCE(wa.web_revenue, 0) AS web_revenue
FROM store_agg sa
LEFT JOIN web_agg wa
    ON sa.i_category_name = wa.i_category_name
ORDER BY sa.s_store_name, sa.i_category_name
