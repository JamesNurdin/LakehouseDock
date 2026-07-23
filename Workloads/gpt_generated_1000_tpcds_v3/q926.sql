SELECT
  cc.cc_city,
  cc.cc_state,
  ds.d_year,
  ds.d_month_seq,
  CASE WHEN cd.cd_purchase_estimate >= 8000 THEN 'High' ELSE 'Medium' END AS purchase_segment,
  COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
  SUM(ss.ss_net_profit) AS total_net_profit,
  REGEXP_EXTRACT(cp.cp_description, '(?i)\\b([A-Za-z]{6,})\\b', 1) AS extracted_word,
  CONCAT(cc.cc_city, ', ', cc.cc_state) AS location,
  MIN(SUBSTRING(cc.cc_name, 1, 10)) AS short_cc_name,
  (SELECT AVG(ib2.ib_lower_bound) FROM income_band ib2) AS avg_income_lower_bound
FROM store_sales ss
JOIN date_dim ds
  ON ss.ss_sold_date_sk = ds.d_date_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN call_center cc
  ON cc.cc_open_date_sk = ds.d_date_sk
JOIN catalog_page cp
  ON cp.cp_start_date_sk = ds.d_date_sk
WHERE
  REGEXP_LIKE(cp.cp_description, '(?i)service')
  AND cp.cp_description LIKE '%economic%'
  AND ds.d_year = 2002
  AND EXISTS (
    SELECT 1
    FROM income_band ib2
    WHERE ib2.ib_income_band_sk = hd.hd_income_band_sk
      AND ib2.ib_upper_bound > 150000
  )
GROUP BY
  cc.cc_city,
  cc.cc_state,
  ds.d_year,
  ds.d_month_seq,
  CASE WHEN cd.cd_purchase_estimate >= 8000 THEN 'High' ELSE 'Medium' END,
  REGEXP_EXTRACT(cp.cp_description, '(?i)\\b([A-Za-z]{6,})\\b', 1)
ORDER BY
  total_net_profit DESC,
  ds.d_year,
  ds.d_month_seq
LIMIT 100
