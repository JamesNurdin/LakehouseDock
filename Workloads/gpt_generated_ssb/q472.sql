SELECT
    od.d_year,
    c.c_region,
    p.p_category,
    s.s_region,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost - lo.lo_tax) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(od.d_date AS DATE), CAST(cd.d_date AS DATE))) AS avg_commit_delay_days,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
FROM lineorder lo
JOIN dim_date od
  ON CAST(od.d_datekey AS INTEGER) = lo.lo_orderdate
JOIN dim_date cd
  ON CAST(cd.d_datekey AS INTEGER) = lo.lo_commitdate
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
WHERE od.d_year = '1995'
GROUP BY od.d_year, c.c_region, p.p_category, s.s_region
ORDER BY total_revenue DESC
LIMIT 20
