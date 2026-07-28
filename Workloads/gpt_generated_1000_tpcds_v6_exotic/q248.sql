SELECT
  cs_ship_hdemo_sk,
  COUNT(*) AS sales_cnt,
  SUM(cs_net_profit) AS total_profit
FROM catalog_sales
WHERE cs_net_paid_inc_ship > 1000
  AND cs_ship_hdemo_sk IN (4828, 5715)
GROUP BY cs_ship_hdemo_sk
LIMIT 100
