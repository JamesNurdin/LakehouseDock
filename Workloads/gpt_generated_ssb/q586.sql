WITH cust_year_rev AS (
  SELECT
    dim_date.d_year,
    customer.c_custkey,
    customer.c_name,
    customer.c_region,
    SUM(lineorder.lo_revenue) AS revenue
  FROM lineorder
  JOIN dim_date ON CAST(dim_date.d_datekey AS integer) = lineorder.lo_orderdate
  JOIN customer ON lineorder.lo_custkey = customer.c_custkey
  WHERE dim_date.d_date >= '1995-01-01' AND dim_date.d_date <= '1995-12-31'
  GROUP BY dim_date.d_year, customer.c_custkey, customer.c_name, customer.c_region
),
ranked_customers AS (
  SELECT
    d_year,
    c_region,
    c_custkey,
    c_name,
    revenue,
    ROW_NUMBER() OVER (PARTITION BY d_year, c_region ORDER BY revenue DESC) AS rn
  FROM cust_year_rev
)
SELECT
  d_year,
  c_region,
  c_custkey,
  c_name,
  revenue
FROM ranked_customers
WHERE rn <= 5
ORDER BY d_year, c_region, revenue DESC
