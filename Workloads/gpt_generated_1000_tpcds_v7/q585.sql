SELECT
  cd.cd_gender AS gender,
  cd.cd_marital_status AS marital_status,
  SUM(sr.sr_net_loss) AS total_net_loss,
  COUNT(*) AS return_count,
  'store' AS return_channel
FROM store_returns sr
JOIN customer c
  ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
WHERE sr.sr_return_ship_cost > 10
  AND cd.cd_purchase_estimate > 4000
  AND hd.hd_buy_potential = '5001-10000'
GROUP BY cd.cd_gender, cd.cd_marital_status

UNION ALL

SELECT
  cd.cd_gender AS gender,
  cd.cd_marital_status AS marital_status,
  SUM(wr.wr_net_loss) AS total_net_loss,
  COUNT(*) AS return_count,
  'web' AS return_channel
FROM web_returns wr
JOIN customer c
  ON wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE wr.wr_return_ship_cost > 10
  AND cd.cd_purchase_estimate > 4000
  AND hd.hd_buy_potential = '5001-10000'
GROUP BY cd.cd_gender, cd.cd_marital_status

ORDER BY total_net_loss DESC
