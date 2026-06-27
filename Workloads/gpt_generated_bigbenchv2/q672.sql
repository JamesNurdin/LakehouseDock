WITH store_agg AS (
    SELECT
        ss_item_id AS i_item_id,
        SUM(ss_quantity) AS store_quantity,
        SUM(ss_quantity * i_price) AS store_revenue
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT
        ws_item_id AS i_item_id,
        SUM(ws_quantity) AS web_quantity,
        SUM(ws_quantity * i_price) AS web_revenue
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
    GROUP BY ws_item_id
)
SELECT
    i.i_category_name,
    COUNT(DISTINCT i.i_item_id) AS distinct_items_sold,
    COALESCE(SUM(sa.store_quantity), 0) AS total_store_quantity,
    COALESCE(SUM(wa.web_quantity), 0) AS total_web_quantity,
    COALESCE(SUM(sa.store_revenue), 0) AS total_store_revenue,
    COALESCE(SUM(wa.web_revenue), 0) AS total_web_revenue,
    CASE
        WHEN (COALESCE(SUM(sa.store_quantity), 0) + COALESCE(SUM(wa.web_quantity), 0)) = 0 THEN 0
        ELSE COALESCE(SUM(sa.store_quantity), 0) * 100.0 /
             (COALESCE(SUM(sa.store_quantity), 0) + COALESCE(SUM(wa.web_quantity), 0))
    END AS store_quantity_percent
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.i_item_id
WHERE sa.store_quantity IS NOT NULL OR wa.web_quantity IS NOT NULL
GROUP BY i.i_category_name
ORDER BY total_store_revenue DESC
LIMIT 10
