SELECT
    s.s_region,
    d.d_year,
    SUM(lo.lo_extendedprice * (100 - lo.lo_discount) / 100) AS total_sales,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN dim_date d
  ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
WHERE d.d_year = '1995'
  AND s.s_region = 'ASIA'
GROUP BY s.s_region, d.d_year
HAVING SUM(lo.lo_extendedprice * (100 - lo.lo_discount) / 100) > 1000000
ORDER BY total_sales DESC
