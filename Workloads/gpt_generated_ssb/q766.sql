SELECT
    od.d_year AS order_year,
    c.c_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supplycost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS num_orders
FROM lineorder lo
JOIN dim_date od ON lo.lo_orderdate = CAST(od.d_datekey AS INTEGER)
JOIN dim_date cd ON lo.lo_commitdate = CAST(cd.d_datekey AS INTEGER)
JOIN customer c ON lo.lo_custkey = c.c_custkey
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
WHERE od.d_year = '1995'
  AND cd.d_year = '1995'
  AND lo.lo_discount > 5
GROUP BY od.d_year, c.c_region, p.p_category
ORDER BY od.d_year, c.c_region, total_revenue DESC
