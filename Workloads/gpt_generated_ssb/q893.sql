SELECT
    c.c_region,
    d.d_year,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS profit,
    COUNT(DISTINCT lo.lo_orderkey) AS order_count
FROM lineorder lo
JOIN dim_date d
  ON lo.lo_orderdate = CAST(d.d_datekey AS INTEGER)
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
WHERE d.d_year = '1998'
  AND p.p_category = 'MFGR#1'
  AND s.s_region = 'ASIA'
GROUP BY c.c_region, d.d_year
ORDER BY total_revenue DESC
