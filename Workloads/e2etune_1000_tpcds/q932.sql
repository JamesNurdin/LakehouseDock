SELECT
  s.s_store_name,
  s.s_city,
  d.d_year,
  d.d_month_seq,
  cp.cp_department,
  SUM(sr.sr_return_amt) AS total_return_amount,
  COUNT(*) AS return_cnt,
  AVG(i.inv_quantity_on_hand) AS avg_inventory_on_return_day,
  RANK() OVER (ORDER BY SUM(sr.sr_return_amt) DESC) AS store_rank
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
WHERE s.s_country = 'United States'
  AND d.d_year = 2022
  AND cc.cc_class = 'large'
GROUP BY s.s_store_name, s.s_city, d.d_year, d.d_month_seq, cp.cp_department
HAVING SUM(sr.sr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 10
