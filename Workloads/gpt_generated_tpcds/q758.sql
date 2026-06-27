WITH open_dates AS (
  SELECT
    cc.cc_call_center_sk,
    cc.cc_state,
    cc.cc_country,
    cc.cc_employees,
    od.d_year AS open_year
  FROM call_center cc
  JOIN date_dim od
    ON cc.cc_open_date_sk = od.d_date_sk
),
customer_sales AS (
  SELECT
    c.c_customer_sk,
    sd.d_year AS sales_year
  FROM customer c
  JOIN date_dim sd
    ON c.c_first_sales_date_sk = sd.d_date_sk
)
SELECT
  o.cc_state,
  o.open_year,
  COUNT(DISTINCT o.cc_call_center_sk) AS num_call_centers,
  AVG(o.cc_employees) AS avg_employees,
  COUNT(DISTINCT cs.c_customer_sk) AS num_customers_first_sales_in_year,
  COUNT(DISTINCT CASE WHEN cs.sales_year = o.open_year THEN cs.c_customer_sk END) AS customers_same_year_as_open
FROM open_dates o
LEFT JOIN customer_sales cs
  ON cs.sales_year = o.open_year
WHERE o.open_year >= 2000
  AND o.cc_country = 'United States'
GROUP BY o.cc_state, o.open_year
ORDER BY o.cc_state, o.open_year
