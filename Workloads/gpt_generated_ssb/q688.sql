SELECT
    c.c_region,
    od.d_year,
    od.d_month,
    lo.lo_shipmode,
    SUM(lo.lo_revenue) AS revenue_by_shipmode,
    SUM(SUM(lo.lo_revenue)) OVER (PARTITION BY c.c_region, od.d_year, od.d_month) AS total_revenue_region_month,
    (SUM(lo.lo_revenue) * 100.0) / SUM(SUM(lo.lo_revenue)) OVER (PARTITION BY c.c_region, od.d_year, od.d_month) AS revenue_pct
FROM lineorder lo
JOIN customer c ON lo.lo_custkey = c.c_custkey
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
JOIN dim_date od ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
JOIN dim_date cd ON CAST(lo.lo_commitdate AS VARCHAR) = cd.d_datekey
WHERE od.d_year BETWEEN '1993' AND '1995'
  AND cd.d_year = od.d_year
  AND p.p_category = 'MFGR#1'
GROUP BY
    c.c_region,
    od.d_year,
    od.d_month,
    lo.lo_shipmode
ORDER BY
    c.c_region,
    od.d_year,
    od.d_month,
    revenue_by_shipmode DESC
