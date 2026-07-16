WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT inv_item_sk) AS distinct_items
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_warehouse_sk, inv_date_sk
),
warehouse_stats AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        w.w_country,
        SUM(ia.total_qty) AS warehouse_total_qty,
        SUM(ia.distinct_items) AS warehouse_distinct_items,
        COUNT(*) AS days_with_inventory
    FROM inv_agg ia
    JOIN warehouse w ON ia.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_country = 'United States'
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_city, w.w_state, w.w_country
)
SELECT
    ws.w_warehouse_name,
    ws.w_city,
    ws.w_state,
    ws.warehouse_total_qty,
    ws.warehouse_distinct_items,
    ws.days_with_inventory,
    (SELECT COUNT(*) FROM call_center cc WHERE cc.cc_state = ws.w_state AND cc.cc_class = 'large') AS large_call_center_cnt,
    (SELECT COUNT(*) FROM web_site ws2 WHERE ws2.web_state = ws.w_state AND ws2.web_class = 'large') AS large_web_site_cnt,
    RANK() OVER (PARTITION BY ws.w_state ORDER BY ws.warehouse_total_qty DESC) AS state_warehouse_rank
FROM warehouse_stats ws
WHERE ws.warehouse_total_qty > 10000
ORDER BY ws.warehouse_total_qty DESC, ws.w_state
LIMIT 100
