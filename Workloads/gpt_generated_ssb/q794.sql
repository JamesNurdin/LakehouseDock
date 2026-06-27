/*
  Revenue and profit analysis for the year 1995, broken down by customer region,
  supplier region, and part category. The query joins the lineorder fact table
  with the date, customer, part, and supplier dimensions using only the permitted
  join keys. Date filtering is performed in a CTE that selects only the rows
  for the target year.
*/
WITH date_1995 AS (
    SELECT d_datekey, d_year
    FROM dim_date
    WHERE d_year = '1995'
)
SELECT
    d.d_year,
    c.c_region,
    s.s_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM lineorder lo
JOIN date_1995 d
    ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
GROUP BY d.d_year, c.c_region, s.s_region, p.p_category
ORDER BY total_profit DESC
LIMIT 100
