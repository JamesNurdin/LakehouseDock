WITH inv_agg AS (
    SELECT 
        i.inv_warehouse_sk,
        SUM(i.inv_quantity_on_hand) AS total_qty_on_hand,
        MAX(i.inv_quantity_on_hand) AS max_qty_on_hand
    FROM inventory i
    GROUP BY i.inv_warehouse_sk
),
high_sales AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        sm.sm_ship_mode_id,
        COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        inv_agg.total_qty_on_hand
    FROM web_sales ws
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inv_agg
        ON w.w_warehouse_sk = inv_agg.inv_warehouse_sk
    WHERE
        w.w_country = 'United States'
        AND sm.sm_type = 'AIR'
        AND ws.ws_coupon_amt >= 1000
        AND w.w_state = 'CA'
        AND EXISTS (
            SELECT 1
            FROM inventory i2
            WHERE i2.inv_warehouse_sk = w.w_warehouse_sk
              AND i2.inv_quantity_on_hand > 5000
        )
        AND NOT EXISTS (
            SELECT 1
            FROM inventory i3
            WHERE i3.inv_warehouse_sk = w.w_warehouse_sk
              AND i3.inv_quantity_on_hand = 0
        )
    GROUP BY
        w.w_warehouse_id,
        w.w_city,
        sm.sm_ship_mode_id,
        inv_agg.total_qty_on_hand
),
low_sales AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        sm.sm_ship_mode_id,
        COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        inv_agg.total_qty_on_hand
    FROM web_sales ws
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inv_agg
        ON w.w_warehouse_sk = inv_agg.inv_warehouse_sk
    WHERE
        w.w_country = 'United States'
        AND sm.sm_type = 'GROUND'
        AND ws.ws_coupon_amt < 1000
        AND w.w_state = 'TX'
        AND EXISTS (
            SELECT 1
            FROM inventory i2
            WHERE i2.inv_warehouse_sk = w.w_warehouse_sk
              AND i2.inv_quantity_on_hand > 1000
        )
        AND NOT EXISTS (
            SELECT 1
            FROM inventory i3
            WHERE i3.inv_warehouse_sk = w.w_warehouse_sk
              AND i3.inv_quantity_on_hand = 0
        )
    GROUP BY
        w.w_warehouse_id,
        w.w_city,
        sm.sm_ship_mode_id,
        inv_agg.total_qty_on_hand
)
SELECT * FROM high_sales
UNION ALL
SELECT * FROM low_sales
ORDER BY total_sales DESC
LIMIT 100
