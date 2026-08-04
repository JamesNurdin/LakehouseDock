WITH sales_enriched AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cc.cc_manager,
        cc.cc_name,
        sm.sm_ship_mode_id,
        td.t_hour
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cc.cc_name LIKE 'Mid %'
      AND regexp_like(cc.cc_manager, '^J')
),
aggregated AS (
    SELECT
        sm_ship_mode_id,
        t_hour,
        regexp_extract(cc_manager, '^([^ ]+)', 1) AS manager_first_name,
        COUNT(DISTINCT cs_order_number) AS orders,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_net_profit) AS avg_profit
    FROM sales_enriched
    GROUP BY sm_ship_mode_id, t_hour, cc_manager
)
SELECT
    sm_ship_mode_id,
    t_hour,
    manager_first_name,
    orders,
    total_sales,
    avg_profit,
    LAG(total_sales) OVER (PARTITION BY sm_ship_mode_id ORDER BY t_hour) AS prev_hour_sales,
    SUM(total_sales) OVER (PARTITION BY sm_ship_mode_id ORDER BY t_hour ROWS UNBOUNDED PRECEDING) AS cumulative_sales
FROM aggregated
WHERE total_sales > 10000
ORDER BY sm_ship_mode_id, t_hour
LIMIT 100
