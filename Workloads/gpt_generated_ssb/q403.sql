SELECT
    od.d_year AS order_year,
    cu.c_region AS customer_region,
    su.s_region AS supplier_region,
    pa.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM lineorder lo
JOIN dim_date od
  ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
JOIN customer cu
  ON lo.lo_custkey = cu.c_custkey
JOIN supplier su
  ON lo.lo_suppkey = su.s_suppkey
JOIN part pa
  ON lo.lo_partkey = pa.p_partkey
WHERE od.d_date >= '1995-01-01'
  AND od.d_date <= '1995-12-31'
GROUP BY od.d_year, cu.c_region, su.s_region, pa.p_category
ORDER BY total_revenue DESC
LIMIT 10
