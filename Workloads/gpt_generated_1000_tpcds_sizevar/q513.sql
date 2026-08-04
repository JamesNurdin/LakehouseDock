SELECT ws_ship_hdemo_sk,
       SUM(ws_net_paid) AS total_net_paid,
       AVG(ws_net_profit) AS avg_net_profit
FROM tpcds.web_sales
WHERE ws_sold_time_sk = 61516
  AND ws_coupon_amt > 0
GROUP BY ws_ship_hdemo_sk
HAVING SUM(ws_net_paid) > 1000
ORDER BY total_net_paid DESC
