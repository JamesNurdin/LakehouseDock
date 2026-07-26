WITH cc_quarter AS (
  SELECT cc.cc_call_center_sk,
         cc.cc_name,
         cc.cc_employees,
         d.d_year,
         d.d_quarter_name,
         d.d_quarter_seq,
         ROW_NUMBER() OVER (PARTITION BY d.d_year, d.d_quarter_name ORDER BY cc.cc_employees DESC) AS rn
  FROM call_center cc
  JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
),
quarter_sums AS (
  SELECT d.d_year,
         d.d_quarter_name,
         d.d_quarter_seq,
         SUM(cc.cc_employees) AS total_employees
  FROM call_center cc
  JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
  GROUP BY d.d_year, d.d_quarter_name, d.d_quarter_seq
),
quarter_totals AS (
  SELECT *,
         LAG(total_employees) OVER (ORDER BY d_year, d_quarter_seq) AS prev_total_employees
  FROM quarter_sums
)
SELECT q.d_year,
       q.d_quarter_name,
       q.total_employees,
       q.prev_total_employees,
       (q.total_employees - COALESCE(q.prev_total_employees, 0)) AS employee_change,
       t.cc_call_center_sk,
       t.cc_name,
       t.cc_employees,
       CASE
         WHEN t.cc_employees >= 1000 THEN 'Very Large'
         WHEN t.cc_employees >= 500 THEN 'Large'
         WHEN t.cc_employees >= 200 THEN 'Medium'
         ELSE 'Small'
       END AS size_category
FROM quarter_totals q
JOIN cc_quarter t ON t.d_year = q.d_year AND t.d_quarter_name = q.d_quarter_name
WHERE t.rn <= 3
ORDER BY q.d_year, q.d_quarter_seq, t.rn
