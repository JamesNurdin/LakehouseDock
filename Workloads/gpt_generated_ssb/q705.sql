SELECT
    d.d_year,
    s.s_region,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS profit,
    COUNT(DISTINCT lo.lo_custkey) AS distinct_customers
FROM lineorder lo
JOIN dim_date d
    ON CAST(d.d_datekey AS integer) = lo.lo_orderdate
JOIN supplier s
    ON lo.lo_suppkey = s.s_suppkey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
WHERE d.d_year = '1995'
  AND lo.lo_shipmode = 'AIR'
  AND c.c_mktsegment = 'AUTOMOBILE'
  AND p.p_category = 'MFGR#12'
GROUP BY d.d_year, s.s_region
ORDER BY total_revenue DESC
