SELECT
  cc.cc_division_name,
  sm.sm_type,
  ib.ib_income_band_sk AS employee_income_band,
  COUNT(*) AS return_cnt,
  SUM(wr.wr_return_amt) AS total_return_amt,
  SUM(wr.wr_return_tax) AS total_return_tax,
  AVG(wr.wr_return_quantity) AS avg_return_qty,
  SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
  SUM(wr.wr_net_loss) AS total_net_loss
FROM call_center cc
JOIN web_returns wr
  ON cc.cc_closed_date_sk = wr.wr_returned_date_sk
JOIN ship_mode sm
  ON sm.sm_ship_mode_sk = wr.wr_reason_sk
JOIN income_band ib
  ON cc.cc_employees >= ib.ib_lower_bound
     AND cc.cc_employees < ib.ib_upper_bound
WHERE cc.cc_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2002-01-01'
  AND cc.cc_employees > 3000000
GROUP BY
  cc.cc_division_name,
  sm.sm_type,
  ib.ib_income_band_sk
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amt DESC
LIMIT 100
