/*
  Total revenue and profit by year, supplier region, customer market segment, and product category
  for orders placed in 1995.
*/
SELECT
    d.d_year,
    s.s_region,
    c.c_mktsegment,
    p.p_category,
    sum(lo.lo_revenue) AS total_revenue,
    sum(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM lineorder lo
JOIN dim_date d
  ON cast(lo.lo_orderdate AS varchar) = d.d_datekey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
WHERE d.d_year = '1995'
GROUP BY d.d_year, s.s_region, c.c_mktsegment, p.p_category
ORDER BY total_revenue DESC
