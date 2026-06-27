SELECT
    d_order.d_year AS order_year,
    d_commit.d_year AS commit_year,
    c.c_region,
    s.s_region,
    p.p_category,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
    SUM(lo.lo_quantity) AS total_quantity,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
FROM lineorder lo
JOIN dim_date d_order
  ON CAST(lo.lo_orderdate AS VARCHAR) = d_order.d_datekey
JOIN dim_date d_commit
  ON CAST(lo.lo_commitdate AS VARCHAR) = d_commit.d_datekey
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
WHERE d_order.d_year = '1995'
  AND d_commit.d_year = '1995'
  AND c.c_region = 'AMERICA'
  AND s.s_region = 'ASIA'
  AND p.p_category = 'MFGR#12'
GROUP BY d_order.d_year, d_commit.d_year, c.c_region, s.s_region, p.p_category
ORDER BY total_revenue DESC
