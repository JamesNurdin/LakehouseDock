SELECT
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    d.d_year   AS order_year,
    SUM(lo.lo_revenue)      AS total_revenue,
    SUM(lo.lo_supplycost)   AS total_supply_cost,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
FROM lineorder lo
JOIN dim_date d
  ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
WHERE p.p_category = 'MFGR#12'
  AND d.d_year = '1995'
GROUP BY c.c_region, s.s_region, d.d_year
ORDER BY total_revenue DESC
