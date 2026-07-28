SELECT
  date_dim.d_year,
  warehouse.w_state,
  warehouse.w_county,
  SUM(catalog_returns.cr_return_amount) AS total_return_amount,
  AVG(catalog_returns.cr_fee) AS avg_fee,
  COUNT(*) AS return_cnt,
  MIN(catalog_returns.cr_return_quantity) AS min_qty,
  MAX(catalog_returns.cr_return_quantity) AS max_qty
FROM catalog_returns
JOIN date_dim
  ON catalog_returns.cr_returned_date_sk = date_dim.d_date_sk
JOIN warehouse
  ON catalog_returns.cr_warehouse_sk = warehouse.w_warehouse_sk
WHERE date_dim.d_year = 2001
  AND date_dim.d_fy_quarter_seq = 14
  AND date_dim.d_current_year = 'Y'
  AND warehouse.w_gmt_offset = -5.00
  AND warehouse.w_street_type = 'Road'
  AND warehouse.w_county = 'Fairfield County'
  AND catalog_returns.cr_fee > 20.00
  AND catalog_returns.cr_return_amount > 0
GROUP BY date_dim.d_year, warehouse.w_state, warehouse.w_county
ORDER BY total_return_amount DESC
LIMIT 100
