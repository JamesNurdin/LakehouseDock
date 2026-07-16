WITH cust_stats AS (
  SELECT
    c_birth_country AS country,
    COUNT(*) AS cust_cnt,
    AVG(c_birth_year) AS avg_birth_year,
    MIN(c_birth_year) AS min_birth_year,
    MAX(c_birth_year) AS max_birth_year
  FROM customer
  WHERE c_birth_year BETWEEN 1940 AND 2000
    AND c_birth_country IN ('CHILE', 'MEXICO', 'FIJI')
  GROUP BY c_birth_country
),
wh_stats AS (
  SELECT
    w_country AS country,
    COUNT(*) AS wh_cnt,
    SUM(w_warehouse_sq_ft) AS total_sq_ft,
    AVG(w_warehouse_sq_ft) AS avg_sq_ft
  FROM warehouse
  WHERE w_country IN ('CHILE', 'MEXICO', 'FIJI')
  GROUP BY w_country
)
SELECT
  cs.country,
  cs.cust_cnt,
  cs.avg_birth_year,
  ws.wh_cnt,
  ws.total_sq_ft,
  cs.cust_cnt / ws.total_sq_ft AS cust_per_sqft,
  RANK() OVER (ORDER BY cs.cust_cnt DESC) AS cust_cnt_rank
FROM cust_stats cs
JOIN wh_stats ws ON cs.country = ws.country
WHERE cs.cust_cnt > 10
ORDER BY cs.cust_cnt DESC
LIMIT 10
