WITH store_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.i_category_id,
    sa.i_category_name,
    sa.store_quantity,
    sa.store_revenue,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(wa.web_revenue, 0) AS web_revenue,
    CASE
        WHEN COALESCE(wa.web_quantity, 0) = 0 THEN NULL
        ELSE sa.store_quantity / COALESCE(wa.web_quantity, 1)
    END AS store_to_web_quantity_ratio,
    CASE
        WHEN COALESCE(wa.web_revenue, 0) = 0 THEN NULL
        ELSE sa.store_revenue / COALESCE(wa.web_revenue, 1)
    END AS store_to_web_revenue_ratio
FROM store_agg sa
LEFT JOIN web_agg wa
    ON sa.i_category_id = wa.i_category_id
ORDER BY
    sa.s_store_name,
    sa.i_category_name
