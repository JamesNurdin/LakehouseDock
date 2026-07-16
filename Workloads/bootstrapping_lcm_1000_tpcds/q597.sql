SELECT
  cp.cp_department AS department,
  s.s_state AS state,
  cd_ret.cd_gender AS gender,
  cd_ret.cd_marital_status AS marital_status,
  d_return.d_year AS return_year,
  COUNT(DISTINCT cr.cr_order_number) AS total_orders,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(cr.cr_net_loss) AS total_net_loss,
  AVG(cr.cr_return_quantity) AS avg_return_qty,
  MAX(cr.cr_return_tax) AS max_return_tax,
  MIN(cr.cr_fee) AS min_fee,
  SUM(cr.cr_store_credit) AS total_store_credit,
  SUM(CASE WHEN cr.cr_return_amount > 100 THEN 1 ELSE 0 END) AS high_value_return_cnt,
  SUM(CASE WHEN d_return.d_date BETWEEN d_page_start.d_date AND d_page_end.d_date THEN cr.cr_return_amount ELSE 0 END) AS in_catalog_return_amount,
  COUNT(DISTINCT s.s_store_id) AS store_cnt
FROM catalog_returns cr
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_page_start
  ON cp.cp_start_date_sk = d_page_start.d_date_sk
JOIN date_dim d_page_end
  ON cp.cp_end_date_sk = d_page_end.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_return.d_date_sk
JOIN customer_demographics cd_ret
  ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_demographics cd_ref
  ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
WHERE cp.cp_type = 'WEB'
  AND d_return.d_year BETWEEN 2000 AND 2025
  AND s.s_state IS NOT NULL
GROUP BY
  cp.cp_department,
  s.s_state,
  cd_ret.cd_gender,
  cd_ret.cd_marital_status,
  d_return.d_year
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
