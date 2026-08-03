WITH ws_agg AS (
    SELECT
        ws_ship_mode_sk,
        ws_warehouse_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM tpcds.web_sales
    WHERE ws_ext_tax > 20
      AND ws_wholesale_cost BETWEEN 20 AND 100
      AND ws_quantity >= 1
      AND ws_list_price > 0
      AND ws_ship_date_sk IS NOT NULL
    GROUP BY ws_ship_mode_sk, ws_warehouse_sk
),
joined AS (
    SELECT
        sm.sm_carrier,
        w.w_warehouse_name,
        sm.sm_code,
        w.w_state,
        ws_agg.total_sales,
        ws_agg.total_profit,
        CASE WHEN ws_agg.total_sales > 0 THEN ws_agg.total_profit / ws_agg.total_sales ELSE 0 END AS profit_margin
    FROM ws_agg
    JOIN tpcds.ship_mode sm
        ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
        ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
    WHERE sm.sm_carrier IN ('UPS', 'FEDEX', 'PRIVATECARRIER')
      AND sm.sm_code = 'AIR'
      AND sm.sm_contract LIKE 'U%'
      AND w.w_state = 'CA'
      AND w.w_gmt_offset BETWEEN -5.00 AND -4.00
      AND EXISTS (
            SELECT 1
            FROM tpcds.web_sales ws2
            WHERE ws2.ws_ship_mode_sk = sm.sm_ship_mode_sk
              AND ws2.ws_ext_tax > 30
        )
)
SELECT
    sm_carrier,
    AVG(profit_margin) AS avg_profit_margin,
    COUNT(*) AS warehouse_count
FROM joined
GROUP BY sm_carrier
HAVING AVG(profit_margin) > 0.05
ORDER BY avg_profit_margin DESC
LIMIT 100
