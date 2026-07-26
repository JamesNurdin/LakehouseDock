WITH demo_profit AS (
  SELECT
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    sca.ca_state AS ship_state,
    w.w_warehouse_name,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_cnt,
    SUM(ws.ws_net_profit) / NULLIF(COUNT(DISTINCT ws.ws_order_number), 0) AS profit_per_order
  FROM web_sales ws
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address sca ON ws.ws_ship_addr_sk = sca.ca_address_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  GROUP BY hd.hd_income_band_sk, hd.hd_buy_potential, sca.ca_state, w.w_warehouse_name
)
SELECT
  dp.hd_income_band_sk,
  dp.hd_buy_potential,
  dp.ship_state,
  dp.w_warehouse_name,
  dp.total_profit,
  dp.order_cnt,
  dp.avg_vehicle_cnt,
  dp.profit_per_order,
  CASE WHEN dp.total_profit > 200000 THEN 'High Profit' ELSE 'Standard Profit' END AS profit_category,
  RANK() OVER (PARTITION BY dp.w_warehouse_name ORDER BY dp.total_profit DESC) AS profit_rank_within_warehouse,
  SUM(dp.total_profit) OVER (PARTITION BY dp.w_warehouse_name ORDER BY dp.total_profit DESC ROWS UNBOUNDED PRECEDING) AS cumulative_profit_in_warehouse
FROM demo_profit dp
ORDER BY dp.w_warehouse_name, profit_rank_within_warehouse
LIMIT 20
