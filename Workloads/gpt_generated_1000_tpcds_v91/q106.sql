WITH cs_aggregated AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_count,
        AVG(cs.cs_quantity) AS avg_quantity
    FROM catalog_sales cs
    WHERE cs.cs_quantity >= 2
      AND cs.cs_net_paid > 500
      AND cs.cs_ext_sales_price > 0
      AND cs.cs_sold_date_sk IS NOT NULL
      AND cs.cs_ship_mode_sk IS NOT NULL
    GROUP BY cs.cs_call_center_sk, cs.cs_ship_mode_sk, cs.cs_warehouse_sk
)
SELECT DISTINCT
    cc.cc_name,
    cc.cc_state,
    sm.sm_code,
    w.w_city,
    agg.total_sales,
    agg.total_profit,
    agg.order_count,
    agg.avg_quantity
FROM cs_aggregated agg
JOIN call_center cc ON agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON agg.cs_warehouse_sk = w.w_warehouse_sk
WHERE cc.cc_employees >= 30
  AND cc.cc_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND w.w_city IN ('Pleasant Grove', 'Salem')
  AND agg.total_sales > (SELECT AVG(total_sales) FROM cs_aggregated)
ORDER BY agg.total_sales DESC
LIMIT 100
