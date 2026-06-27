WITH store_agg AS (
    SELECT
        ss.ss_item_id AS item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
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
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    COALESCE(sa.store_revenue, 0) AS store_revenue,
    COALESCE(wa.web_revenue, 0) AS web_revenue,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    i.i_price,
    i.i_comp_price,
    (i.i_price - i.i_comp_price) AS price_diff,
    (i.i_price - i.i_comp_price) / i.i_comp_price * 100 AS price_diff_pct,
    CASE 
        WHEN COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) = 0 THEN 0
        ELSE COALESCE(sa.store_quantity, 0) * 100.0 / (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0))
    END AS store_quantity_pct,
    CASE 
        WHEN COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) = 0 THEN 0
        ELSE COALESCE(wa.web_quantity, 0) * 100.0 / (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0))
    END AS web_quantity_pct
FROM items i
LEFT JOIN store_agg sa ON sa.item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.item_id = i.i_item_id
WHERE COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) > 0
ORDER BY total_revenue DESC
LIMIT 100
