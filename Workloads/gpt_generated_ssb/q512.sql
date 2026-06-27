SELECT
    d.d_year,
    c.c_region,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM lineorder lo
JOIN dim_date d
    ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
JOIN customer c
    ON lo.lo_custkey = c.c_custkey
JOIN part p
    ON lo.lo_partkey = p.p_partkey
WHERE d.d_year = '1997'
  AND p.p_mfgr = 'MFGR#1'
  AND lo.lo_orderpriority IN ('1-URGENT', '2-HIGH')
GROUP BY d.d_year, c.c_region
ORDER BY d.d_year, c.c_region
