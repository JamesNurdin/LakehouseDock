SELECT
  s.s_store_id,
  s.s_store_name,
  dr.d_date,
  i.i_item_id,
  i.i_product_name,
  i.i_current_price,
  c.c_customer_id,
  c.c_birth_month,
  hd.hd_income_band_sk,
  sr.sr_return_quantity,
  sr.sr_net_loss,
  cp.cp_department,
  wr.wr_return_amt,
  RANK() OVER (PARTITION BY s.s_store_id, dr.d_year ORDER BY sr.sr_net_loss DESC) AS net_loss_rank,
  CASE WHEN sr.sr_net_loss > 50 THEN 'HIGH' ELSE 'LOW' END AS net_loss_category
FROM store_returns sr
JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
JOIN time_dim tr ON sr.sr_return_time_sk = tr.t_time_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN catalog_page cp ON cp.cp_end_date_sk = dr.d_date_sk
LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = dr.d_date_sk
  AND wr.wr_returned_time_sk = tr.t_time_sk
  AND wr.wr_item_sk = i.i_item_sk
WHERE dr.d_year = 2001
  AND i.i_current_price > 100
  AND s.s_state = 'TX'
  AND hd.hd_income_band_sk BETWEEN 5 AND 15
  AND c.c_birth_month = 7
ORDER BY sr.sr_net_loss DESC
LIMIT 100
