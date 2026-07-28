SELECT
  hd.hd_buy_potential,
  hd.hd_vehicle_count,
  SUM(ws.ws_net_profit) AS total_profit
FROM tpcds.web_sales AS ws
JOIN tpcds.household_demographics AS hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_vehicle_count >= 2
  AND hd.hd_buy_potential = '>10000'
  AND ws.ws_sold_time_sk BETWEEN 30000 AND 40000
GROUP BY
  hd.hd_buy_potential,
  hd.hd_vehicle_count
ORDER BY total_profit DESC
LIMIT 100
