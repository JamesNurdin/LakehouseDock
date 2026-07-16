SELECT
    d_cr.d_year AS year,
    d_cr.d_month_seq AS month_seq,
    sm.sm_type,
    s.s_store_name,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
    SUM(cr.cr_return_amount) AS catalog_return_total,
    SUM(cr.cr_fee) AS catalog_fee_total,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_ticket_cnt,
    SUM(sr.sr_return_amt_inc_tax) AS store_return_total_inc_tax,
    SUM(sr.sr_fee) AS store_return_fee_total,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(sr.sr_return_quantity) AS avg_store_return_qty,
    (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss)) AS total_combined_net_loss
FROM date_dim d_cr
JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s
  ON s.s_closed_date_sk = d_cr.d_date_sk
JOIN store_returns sr
  ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_sr
  ON sr.sr_returned_date_sk = d_sr.d_date_sk
WHERE d_cr.d_year = 2001
  AND sm.sm_type = 'AIR'
GROUP BY
    d_cr.d_year,
    d_cr.d_month_seq,
    sm.sm_type,
    s.s_store_name
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY catalog_return_total DESC
LIMIT 100
