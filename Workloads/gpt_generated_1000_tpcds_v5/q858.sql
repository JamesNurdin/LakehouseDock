WITH base AS (
    SELECT
        i.inv_warehouse_sk,
        i.inv_item_sk,
        i.inv_quantity_on_hand,
        w.w_warehouse_name,
        w.w_city,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        sm.sm_type,
        CASE WHEN ws.ws_ext_ship_cost > 500 THEN 'High' ELSE 'Low' END AS ship_cost_category
    FROM inventory i
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE i.inv_warehouse_sk IN (2, 5, 11, 12, 20)
      AND i.inv_item_sk BETWEEN 101410 AND 101440
      AND w.w_state = 'CA'
      AND w.w_city IN ('Los Angeles', 'San Francisco', 'San Diego')
      AND sm.sm_type = 'AIR'
      AND ws.ws_ext_ship_cost IS NOT NULL
),
agg1 AS (
    SELECT
        w_warehouse_name,
        ship_cost_category,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT inv_item_sk) AS distinct_items,
        AVG(ws_quantity) AS avg_quantity
    FROM base
    GROUP BY w_warehouse_name, ship_cost_category
)
SELECT
    ship_cost_category,
    AVG(total_profit) AS avg_profit_per_warehouse,
    SUM(total_sales) AS grand_total_sales,
    COUNT(*) AS num_warehouses
FROM agg1
WHERE total_sales > 5000
GROUP BY ship_cost_category
HAVING AVG(total_profit) > 0
ORDER BY avg_profit_per_warehouse DESC
