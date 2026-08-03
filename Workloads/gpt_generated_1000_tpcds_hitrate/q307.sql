WITH ws_keys AS (
        SELECT DISTINCT ws_warehouse_sk
        FROM web_sales
    ),
    wh_keys AS (
        SELECT w_warehouse_sk
        FROM warehouse
    ),
    missing_wh AS (
        SELECT ws_warehouse_sk
        FROM ws_keys
        EXCEPT
        SELECT w_warehouse_sk
        FROM wh_keys
    ),
    base AS (
        SELECT
            ws.ws_order_number,
            ws.ws_warehouse_sk,
            wh.w_warehouse_name,
            hd.hd_vehicle_count,
            hd.hd_buy_potential,
            ws.ws_coupon_amt,
            ws.ws_net_profit,
            CASE WHEN ws.ws_net_profit > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
        FROM web_sales ws
        JOIN household_demographics hd
          ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN warehouse wh
          ON ws.ws_warehouse_sk = wh.w_warehouse_sk
        WHERE hd.hd_vehicle_count > 0
          AND hd.hd_buy_potential = '1001-5000'
          AND ws.ws_coupon_amt > 50
          AND wh.w_city = 'San Francisco'
    ),
    ranked AS (
        SELECT
            b.*, 
            ROW_NUMBER() OVER (PARTITION BY b.ws_warehouse_sk ORDER BY b.ws_net_profit DESC) AS rn,
            RANK() OVER (ORDER BY b.ws_net_profit DESC) AS global_rank
        FROM base b
    )
SELECT
    r.ws_order_number,
    r.ws_warehouse_sk,
    r.w_warehouse_name,
    r.hd_vehicle_count,
    r.hd_buy_potential,
    r.ws_coupon_amt,
    r.ws_net_profit,
    r.profit_category,
    r.rn,
    r.global_rank,
    dv.dim_val
FROM ranked r
CROSS JOIN (VALUES (1), (2), (3)) AS dv(dim_val)
WHERE r.rn <= 5
  AND NOT EXISTS (
        SELECT 1 FROM missing_wh m WHERE m.ws_warehouse_sk = r.ws_warehouse_sk
    )
ORDER BY r.global_rank ASC, r.ws_warehouse_sk
LIMIT 100
