WITH store_agg AS (
    SELECT
        i.i_category,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category
),
web_agg AS (
    SELECT
        i.i_category,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    COALESCE(sa.i_category, wa.i_category) AS category,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(sa.store_revenue, 0) AS store_revenue,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(wa.web_revenue, 0) AS web_revenue
FROM store_agg sa
FULL OUTER JOIN web_agg wa
    ON sa.i_category = wa.i_category
ORDER BY category
