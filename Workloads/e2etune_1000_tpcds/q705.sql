SELECT
  cd.cd_education_status,
  cd.cd_gender,
  SUM(ss.ss_ext_sales_price) AS total_sales_amount,
  SUM(ss.ss_quantity) AS total_sales_quantity,
  SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
  SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_return_quantity,
  SUM(ss.ss_net_profit) AS total_net_profit,
  SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
  AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
  CASE WHEN SUM(ss.ss_quantity) > 0 THEN
    SUM(COALESCE(sr.sr_return_quantity, 0)) / SUM(ss.ss_quantity)
  ELSE NULL END AS return_rate,
  RANK() OVER (ORDER BY SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) DESC) AS profit_rank
FROM store_sales ss
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN customer_demographics cd_ret ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
WHERE cd.cd_gender = 'F'
  AND cd.cd_education_status IN ('College', '4 yr Degree')
  AND cd.cd_purchase_estimate >= 1500
GROUP BY cd.cd_education_status, cd.cd_gender
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales_amount DESC
LIMIT 50
