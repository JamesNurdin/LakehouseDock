SELECT
    od.d_year AS order_year,
    cd.d_year AS commit_year,
    s.s_region,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount
FROM lineorder lo
JOIN dim_date od ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
JOIN dim_date cd ON CAST(cd.d_datekey AS INTEGER) = lo.lo_commitdate
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
WHERE od.d_year = '1995'
  AND p.p_category = 'MFGR#12'
  AND s.s_region = 'AMERICA'
GROUP BY od.d_year, cd.d_year, s.s_region
ORDER BY total_revenue DESC
