WITH intersected_orders AS (
    SELECT cs.cs_order_number, cs.cs_net_profit
    FROM catalog_sales cs
    RIGHT OUTER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cc.cc_company = 2
      AND td.t_am_pm = 'PM'
    INTERSECT
    SELECT cs2.cs_order_number, cs2.cs_net_profit
    FROM catalog_sales cs2
    JOIN ship_mode sm
        ON cs2.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td2
        ON cs2.cs_sold_time_sk = td2.t_time_sk
    WHERE sm.sm_contract LIKE 'A%'
      AND td2.t_hour BETWEEN 12 AND 23
)
SELECT
    COUNT(DISTINCT cs_order_number) AS distinct_order_cnt,
    SUM(DISTINCT cs_net_profit) AS sum_distinct_profit,
    MIN(cs_net_profit) AS min_profit,
    MAX(cs_net_profit) AS max_profit
FROM intersected_orders
LIMIT 100
