SELECT
    d_order.d_year AS order_year,
    d_commit.d_year AS commit_year,
    s.s_region AS supplier_region,
    c.c_region AS customer_region,
    p.p_category AS part_category,
    SUM(lo.lo_revenue) AS total_revenue,
    AVG(lo.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo.lo_orderkey) AS distinct_orders
FROM lineorder lo
JOIN dim_date d_order
  ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
JOIN dim_date d_commit
  ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
JOIN customer c
  ON lo.lo_custkey = c.c_custkey
JOIN part p
  ON lo.lo_partkey = p.p_partkey
JOIN supplier s
  ON lo.lo_suppkey = s.s_suppkey
WHERE CAST(d_order.d_date AS DATE) BETWEEN DATE '1995-01-01' AND DATE '1997-12-31'
  AND p.p_category = 'MFGR#12'
  AND s.s_region = 'ASIA'
GROUP BY d_order.d_year, d_commit.d_year, s.s_region, c.c_region, p.p_category
ORDER BY total_revenue DESC
LIMIT 15
