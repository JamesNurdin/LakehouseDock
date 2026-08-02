SELECT
    sm.sm_carrier,
    sm.sm_type,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_profit) AS total_net_profit
FROM catalog_sales cs
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_carrier = 'FEDEX'
  AND cs.cs_ext_ship_cost < 500
GROUP BY sm.sm_carrier, sm.sm_type
ORDER BY total_net_profit DESC
LIMIT 5
