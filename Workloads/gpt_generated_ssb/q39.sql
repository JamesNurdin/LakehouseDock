SELECT
    od.d_year AS order_year,
    od.d_month AS order_month,
    s.s_region AS supplier_region,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM lineorder lo
JOIN dim_date od
  ON CAST(lo.lo_orderdate AS varchar) = od.d_datekey
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
WHERE od.d_year = '1995'
  AND c.c_mktsegment = 'AUTOMOBILE'
GROUP BY od.d_year, od.d_month, s.s_region
ORDER BY od.d_year, od.d_month, s.s_region
