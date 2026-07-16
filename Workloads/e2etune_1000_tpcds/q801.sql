SELECT
    hd.hd_vehicle_count,
    hd.hd_buy_potential,
    cs.cs_ship_mode_sk,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
    SUM(cs.cs_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) AS net_profit_adj,
    AVG(cs.cs_wholesale_cost) AS avg_wholesale_cost,
    RANK() OVER (ORDER BY SUM(cs.cs_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) DESC) AS profit_rank
FROM catalog_sales cs
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store_returns sr
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
    AND sr.sr_item_sk = cs.cs_item_sk
    AND sr.sr_returned_date_sk = cs.cs_sold_date_sk
WHERE cs.cs_wholesale_cost > 30
  AND cs.cs_ship_mode_sk IN (1, 5)
  AND hd.hd_vehicle_count BETWEEN 1 AND 3
GROUP BY hd.hd_vehicle_count, hd.hd_buy_potential, cs.cs_ship_mode_sk
HAVING SUM(cs.cs_net_profit) > 1000
ORDER BY net_profit_adj DESC
LIMIT 100
