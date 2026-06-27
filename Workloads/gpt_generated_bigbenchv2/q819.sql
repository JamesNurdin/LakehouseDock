WITH store_agg AS (
    SELECT
        ss.ss_item_id AS i_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT
        ws.ws_item_id AS i_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    i.i_price,
    i.i_comp_price,
    i.i_price - i.i_comp_price AS price_diff,
    CASE WHEN i.i_comp_price = 0 THEN NULL ELSE (i.i_price - i.i_comp_price) / i.i_comp_price * 100 END AS price_diff_pct,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(sa.store_revenue, 0) AS store_revenue,
    COALESCE(wa.web_revenue, 0) AS web_revenue,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) * i.i_price AS expected_revenue_at_list_price,
    CASE WHEN COALESCE(wa.web_quantity, 0) = 0 THEN NULL ELSE COALESCE(sa.store_quantity, 0) / COALESCE(wa.web_quantity, 0) END AS store_to_web_quantity_ratio,
    CASE WHEN COALESCE(wa.web_revenue, 0) = 0 THEN NULL ELSE COALESCE(sa.store_revenue, 0) / COALESCE(wa.web_revenue, 0) END AS store_to_web_revenue_ratio
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.i_item_id
ORDER BY total_revenue DESC
LIMIT 100
