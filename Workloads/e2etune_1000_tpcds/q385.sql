WITH cc_closed_qtr AS (
  SELECT
    cc.cc_division_name AS division_name,
    cc.cc_state AS state,
    d.d_year AS year,
    d.d_quarter_seq AS quarter_seq,
    COUNT(DISTINCT cc.cc_call_center_sk) AS num_cc,
    SUM(cc.cc_employees) AS total_employees,
    AVG(cc.cc_tax_percentage) AS avg_tax_pct
  FROM call_center cc
  JOIN date_dim d
    ON cc.cc_closed_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
  GROUP BY cc.cc_division_name, cc.cc_state, d.d_year, d.d_quarter_seq
),
ws_closed_qtr AS (
  SELECT
    ws.web_state AS state,
    d.d_year AS year,
    d.d_quarter_seq AS quarter_seq,
    COUNT(DISTINCT ws.web_site_sk) AS num_ws
  FROM web_site ws
  JOIN date_dim d
    ON ws.web_close_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
  GROUP BY ws.web_state, d.d_year, d.d_quarter_seq
)
SELECT
  ccq.division_name,
  ccq.state,
  ccq.year,
  ccq.quarter_seq,
  ccq.num_cc,
  ccq.total_employees,
  ccq.avg_tax_pct,
  COALESCE(wsq.num_ws, 0) AS num_ws,
  CASE WHEN COALESCE(wsq.num_ws, 0) = 0 THEN NULL ELSE ccq.total_employees / wsq.num_ws END AS emp_per_ws,
  RANK() OVER (PARTITION BY ccq.year ORDER BY (ccq.total_employees / NULLIF(wsq.num_ws, 0)) DESC) AS rank_by_emp_per_ws
FROM cc_closed_qtr ccq
LEFT JOIN ws_closed_qtr wsq
  ON ccq.state = wsq.state
  AND ccq.year = wsq.year
  AND ccq.quarter_seq = wsq.quarter_seq
WHERE ccq.total_employees > 0
ORDER BY ccq.year, rank_by_emp_per_ws
LIMIT 50
