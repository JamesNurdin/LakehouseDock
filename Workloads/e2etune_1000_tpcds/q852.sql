WITH profit_by_wh_sm AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    WHERE cs.cs_sales_price > 100.00
      AND cs.cs_ext_ship_cost < 300.00
    GROUP BY cs.cs_warehouse_sk, cs.cs_ship_mode_sk
    HAVING SUM(cs.cs_ext_sales_price) > 5000
)
SELECT
    w.w_warehouse_name,
    sm.sm_carrier,
    pbws.total_profit,
    pbws.total_sales,
    pbws.order_cnt,
    pbws.total_profit / NULLIF(pbws.total_sales, 0) AS profit_margin,
    RANK() OVER (ORDER BY pbws.total_profit DESC) AS profit_rank
FROM profit_by_wh_sm pbws
JOIN warehouse w ON pbws.cs_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON pbws.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE w.w_state = 'CA'
ORDER BY profit_rank
LIMIT 10
