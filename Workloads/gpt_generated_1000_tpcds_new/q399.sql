SELECT
  s_state,
  COUNT(*) AS store_count,
  AVG(s_tax_percentage) AS avg_tax_percentage
FROM tpcds.store
WHERE s_rec_start_date >= DATE '1999-01-01'
  AND s_rec_start_date <= DATE '2000-12-31'
  AND s_state = 'CA'
GROUP BY s_state
