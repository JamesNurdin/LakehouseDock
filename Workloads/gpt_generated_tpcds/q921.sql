WITH ws_agg AS (
    SELECT
        ws_ship_mode_sk,
        ws_warehouse_sk,
        COUNT(*) AS order_cnt,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_ext_discount_amt) AS avg_discount,
        SUM(ws_ext_ship_cost) AS total_ship_cost
    FROM web_sales
    GROUP BY ws_ship_mode_sk, ws_warehouse_sk
)
SELECT
    sm.sm_ship_mode_id,
    sm.sm_type,
    sm.sm_carrier,
    ws_agg.ws_warehouse_sk,
    ws_agg.order_cnt,
    ws_agg.total_quantity,
    ws_agg.total_sales,
    ws_agg.total_profit,
    ws_agg.avg_discount,
    ws_agg.total_ship_cost,
    ws_agg.total_ship_cost / NULLIF(ws_agg.total_quantity, 0) AS ship_cost_per_unit,
    RANK() OVER (PARTITION BY ws_agg.ws_warehouse_sk ORDER BY ws_agg.total_sales DESC) AS sales_rank_in_warehouse
FROM ws_agg
JOIN ship_mode sm
    ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY ws_agg.total_sales DESC
LIMIT 100
