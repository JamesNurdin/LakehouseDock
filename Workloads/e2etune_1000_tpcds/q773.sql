SELECT
  cc.cc_country AS country,
  cc.cc_class AS call_center_class,
  td.t_meal_time AS meal_time,
  cd_ref.cd_gender AS refunded_gender,
  cd_ret.cd_gender AS returning_gender,
  COUNT(DISTINCT cr.cr_order_number) AS num_orders,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(cr.cr_net_loss) AS total_net_loss,
  AVG(cr.cr_return_tax) AS avg_return_tax,
  SUM(cr.cr_return_quantity) AS total_return_quantity
FROM catalog_returns cr
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN time_dim td
  ON cr.cr_returned_time_sk = td.t_time_sk
JOIN customer_demographics cd_ref
  ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
  ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
WHERE cc.cc_class = 'large'
  AND cc.cc_rec_end_date >= DATE '2000-01-01'
  AND td.t_hour BETWEEN 9 AND 17
  AND cd_ref.cd_gender = 'F'
GROUP BY
  cc.cc_country,
  cc.cc_class,
  td.t_meal_time,
  cd_ref.cd_gender,
  cd_ret.cd_gender
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
