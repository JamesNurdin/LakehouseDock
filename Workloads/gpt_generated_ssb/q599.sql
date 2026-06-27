SELECT
    od.d_year AS year,
    c.c_region AS customer_region,
    s.s_region AS supplier_region,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM lineorder lo
JOIN dim_date od
    ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
WHERE p.p_category = 'MFGR#1'
  AND od.d_year = '1995'
GROUP BY od.d_year, c.c_region, s.s_region
ORDER BY total_revenue DESC
