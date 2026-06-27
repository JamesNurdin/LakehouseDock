SELECT
    od.d_year AS order_year,
    cd.d_year AS commit_year,
    c.c_region AS customer_region,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM lineorder lo
JOIN dim_date od
  ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
JOIN dim_date cd
  ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
WHERE od.d_year = '1995'
  AND cd.d_year = '1996'
  AND p.p_category = 'MFGR#12'
GROUP BY od.d_year, cd.d_year, c.c_region
ORDER BY total_revenue DESC
LIMIT 10
