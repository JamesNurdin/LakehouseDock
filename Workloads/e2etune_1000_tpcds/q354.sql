WITH warehouse_inventory AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        w.w_country,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_item_cnt
    FROM inventory i
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_quantity_on_hand > 0
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_city, w.w_state, w.w_country
),
store_stats AS (
    SELECT
        w.w_warehouse_sk,
        AVG(s.s_floor_space) AS avg_store_floor_space,
        AVG(s.s_tax_percentage) AS avg_store_tax_percentage
    FROM warehouse w
    JOIN store s
        ON w.w_city = s.s_city
        AND w.w_state = s.s_state
    WHERE s.s_closed_date_sk IS NULL
    GROUP BY w.w_warehouse_sk
),
web_site_stats AS (
    SELECT
        w.w_warehouse_sk,
        AVG(ws.web_tax_percentage) AS avg_web_tax_percentage
    FROM warehouse w
    JOIN web_site ws
        ON w.w_country = ws.web_country
    WHERE ws.web_rec_end_date IS NULL
    GROUP BY w.w_warehouse_sk
)
SELECT
    wi.w_warehouse_sk,
    wi.w_warehouse_name,
    wi.w_city,
    wi.w_state,
    wi.total_inventory_qty,
    wi.distinct_item_cnt,
    ss.avg_store_floor_space,
    ss.avg_store_tax_percentage,
    ws.avg_web_tax_percentage,
    RANK() OVER (ORDER BY wi.total_inventory_qty DESC) AS warehouse_rank
FROM warehouse_inventory wi
LEFT JOIN store_stats ss
    ON wi.w_warehouse_sk = ss.w_warehouse_sk
LEFT JOIN web_site_stats ws
    ON wi.w_warehouse_sk = ws.w_warehouse_sk
WHERE wi.total_inventory_qty > 1000
ORDER BY warehouse_rank
LIMIT 20
