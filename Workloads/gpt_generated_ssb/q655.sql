SELECT
    od_order.d_year AS order_year,
    s.s_region AS supplier_region,
    AVG(CAST(od_commit.d_daynuminyear AS integer) - CAST(od_order.d_daynuminyear AS integer)) AS avg_days_to_commit,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
FROM lineorder lo
JOIN dim_date od_order
  ON lo.lo_orderdate = CAST(od_order.d_datekey AS integer)
JOIN dim_date od_commit
  ON lo.lo_commitdate = CAST(od_commit.d_datekey AS integer)
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
WHERE od_order.d_year = '1995'
  AND p.p_category = 'MFGR#14'
GROUP BY od_order.d_year, s.s_region
ORDER BY total_revenue DESC
LIMIT 10
