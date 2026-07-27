WITH cc_agg AS (
  SELECT
    cc.cc_closed_date_sk,
    COUNT(*) AS cc_cnt,
    SUM(cc.cc_employees) AS total_employees,
    AVG(cc.cc_employees) AS avg_employees
  FROM tpcds.call_center cc
  WHERE cc.cc_employees > 500000
    AND cc.cc_mkt_class LIKE '%Particular%'
    AND cc.cc_rec_end_date = DATE '2000-12-31'
  GROUP BY cc.cc_closed_date_sk
),
store_agg AS (
  SELECT
    s.s_closed_date_sk,
    COUNT(*) AS store_cnt,
    MAX(s.s_floor_space) AS max_floor_space,
    AVG(s.s_tax_percentage) AS avg_tax
  FROM tpcds.store s
  WHERE s.s_tax_percentage >= 0.07
    AND s.s_suite_number LIKE 'Suite %'
  GROUP BY s.s_closed_date_sk
)
SELECT
  d.d_year,
  d.d_month_seq,
  cc_agg.cc_cnt,
  store_agg.store_cnt,
  cc_agg.total_employees,
  cc_agg.avg_employees,
  store_agg.max_floor_space,
  store_agg.avg_tax,
  (SELECT COUNT(*) FROM tpcds.call_center WHERE cc_employees > 1000000) AS high_emp_cc_total
FROM tpcds.date_dim d
JOIN cc_agg ON cc_agg.cc_closed_date_sk = d.d_date_sk
JOIN store_agg ON store_agg.s_closed_date_sk = d.d_date_sk
WHERE d.d_day_name = 'Monday'
  AND d.d_current_year = 'Y'
ORDER BY d.d_year DESC, d.d_month_seq ASC
LIMIT 100
