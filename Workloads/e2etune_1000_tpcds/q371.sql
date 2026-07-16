WITH cust_agg AS (
  SELECT
    c.c_birth_year,
    c.c_birth_month,
    COUNT(*) AS num_customers,
    AVG(date_diff('day', dss.d_date, ds.d_date)) AS avg_days_ship_to_sales,
    MAX(dr.d_year) AS latest_review_year
  FROM customer c
  JOIN date_dim ds ON c.c_first_shipto_date_sk = ds.d_date_sk
  JOIN date_dim dss ON c.c_first_sales_date_sk = dss.d_date_sk
  JOIN date_dim dr ON c.c_last_review_date = dr.d_date_sk
  WHERE c.c_preferred_cust_flag = 'Y'
    AND c.c_birth_year BETWEEN 1940 AND 2000
  GROUP BY c.c_birth_year, c.c_birth_month
)
SELECT
  ca.c_birth_year,
  ca.c_birth_month,
  ca.num_customers,
  ca.avg_days_ship_to_sales,
  ca.latest_review_year,
  RANK() OVER (ORDER BY ca.num_customers DESC) AS birth_year_month_rank,
  (SELECT AVG(i_wholesale_cost) FROM item WHERE i_category = 'Electronics') AS avg_electronics_wholesale_cost,
  (SELECT COUNT(*) FROM warehouse WHERE w_state = 'CA') AS ca_warehouse_count
FROM cust_agg ca
ORDER BY ca.num_customers DESC
LIMIT 100
