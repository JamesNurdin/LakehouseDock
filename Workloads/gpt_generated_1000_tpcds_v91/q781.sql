SELECT ws_ship_hdemo_sk,
       SUM(ws_net_paid) AS total_net_paid
FROM tpcds.web_sales
WHERE ws_ship_hdemo_sk = 702
  AND ws_ext_tax > 20.0
GROUP BY ws_ship_hdemo_sk
LIMIT 100
