SELECT
  p.cp_department,
  d.d_year,
  ca.ca_state,
  ib.ib_lower_bound,
  SUM(r.cr_return_amount) AS total_return_amount,
  AVG(r.cr_return_tax) AS avg_return_tax,
  COUNT(*) AS return_count,
  MIN(r.cr_return_ship_cost) AS min_ship_cost,
  MAX(r.cr_return_ship_cost) AS max_ship_cost
FROM tpcds.catalog_returns r
JOIN tpcds.catalog_page p
  ON r.cr_catalog_page_sk = p.cp_catalog_page_sk
JOIN tpcds.date_dim d
  ON r.cr_returned_date_sk = d.d_date_sk
JOIN tpcds.household_demographics hd
  ON r.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.customer_address ca
  ON r.cr_refunded_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2001
  AND p.cp_department = 'Electronics'
  AND r.cr_return_amount > 100.00
  AND r.cr_return_quantity >= 2
  AND ca.ca_state = 'CA'
  AND ib.ib_lower_bound >= 20000
  AND hd.hd_buy_potential = '>10000'
GROUP BY p.cp_department, d.d_year, ca.ca_state, ib.ib_lower_bound
ORDER BY total_return_amount DESC
LIMIT 100
